import { common } from '@kit.AbilityKit';
import {
  BreakdownRow, DailyStat, LevelInfo, Quest, QuestItem, StatsRange, StatsSummary
} from '../model/Quest';
import { CATEGORIES, MONTH_SEED, QUEST_CATALOG, WEEK_SEED, XP_PER_LEVEL, categoryOf } from '../data/Data';
import { Prefs } from '../common/Prefs';

/** 某一天的完成记录（只记录步骤 id，XP 由任务目录反查）。 */
export interface DayLog {
  steps: string[];
}

/** 打卡日期 → 当日记录。 */
export type DayMap = Record<string, DayLog>;

const WEEK_LABELS: string[] = ['一', '二', '三', '四', '五', '六', '日'];
const MONTH_LABELS: string[] = ['第 1 周', '第 2 周', '第 3 周', '第 4 周'];

/** 等级换算：由累计 XP 反推等级与当前等级内的进度。 */
export class LevelMath {
  static levelOf(totalXp: number): number {
    const lv: number = Math.floor(totalXp / XP_PER_LEVEL);
    return lv < 1 ? 1 : lv;
  }

  static info(totalXp: number): LevelInfo {
    const level: number = LevelMath.levelOf(totalXp);
    const floorXp: number = (level - 1) * XP_PER_LEVEL;
    const inLevel: number = totalXp - floorXp;
    const pct: number = inLevel <= 0 ? 0 : Math.min(100, (inLevel / XP_PER_LEVEL) * 100);
    return {
      level: level,
      levelName: '等级 ' + level.toString(),
      xp: inLevel,
      nextXp: XP_PER_LEVEL,
      percent: pct
    };
  }
}

/**
 * 全局状态中心。
 *
 * 两个关键设计：
 *
 * 1. **AppStorage 里只放「字符串 / 数字 / 布尔」这类不可变值，不放嵌套对象。**
 *    打卡记录序列化成 JSON 字符串存 K_DAYS_JSON，改一次就是一个新字符串，
 *    订阅它的组件必定重新渲染。相反，如果放的是对象并在原地改字段，
 *    ArkUI 观察不到变化 —— 表现就是「勾选了没反应、退出重进才对」。
 *
 * 2. **只存原始数据，派生指标一律现算。**
 *    今日进度、等级进度、周/月统计、任务分布都由 days + 任务目录算出来，
 *    因此任何一处打卡都会让首页、详情页、数据页同时刷新。
 */
export class AppStore {
  static readonly K_READY: string = 'ready';
  static readonly K_UNLOCKED: string = 'unlocked';
  static readonly K_TOTAL_XP: string = 'totalXp';
  static readonly K_STREAK: string = 'streak';
  /** 打卡记录（JSON 字符串）。所有依赖打卡的界面都要 @StorageLink 它。 */
  static readonly K_DAYS_JSON: string = 'daysJson';
  static readonly K_TODAY: string = 'today';

  // ── 供界面订阅的「字符串镜像」 ──
  // 每个界面只会读几种状态，这里把它们都镜像成字符串：
  // 视图用 @StorageLink 读镜像字符串来渲染，
  // 业务方法仍然读写上面的数字/原始值。
  // 这么绕一层是因为数字型 @StorageLink 在部分版本上不触发重绘，
  // 而字符串只要值变了就一定会通知。
  /** 今日已完成的步骤 id，逗号分隔。 */
  static readonly K_DONE_STEPS: string = 'doneSteps';
  /** 今日已获 XP（字符串形式，供显示）。 */
  static readonly K_EARNED_XP: string = 'earnedXpStr';
  /** 今日还可获得的 XP（字符串形式，供显示）。 */
  static readonly K_READY_XP: string = 'readyXpStr';
  /** 累计 XP（字符串形式，供显示）。 */
  static readonly K_TOTAL_XP_TEXT: string = 'totalXpStr';
  /** 连续打卡天数（字符串形式，供显示）。 */
  static readonly K_STREAK_TEXT: string = 'streakStr';
  /** 有打卡记录的天数（字符串形式，供显示）。 */
  static readonly K_LOGGED_DAYS: string = 'loggedDays';
  /**
   * 数据修订号。每次可见状态变化就 +1。
   *
   * 为什么需要它：所有路由组件都挂在同一棵树上，
   * 但实测「隐藏的路由组件」不会可靠地收到 AppStorage 变更通知 ——
   * 表现就是清空数据后要切页再回来才看到新数值。
   * 所以由根组件订阅这个修订号，再把它作为 @Prop 下发给每个页面，
   * 用父组件的重绘把子组件一起带起来。
   */
  static readonly K_REV: string = 'dataRev';
  /**
   * 状态栏 / 摄像头挖孔的安全区高度（vp）。
   * 因为开了沉浸式布局（内容铺满全屏），各页顶部必须自己让出这段空间，
   * 否则问候语、标题会被时间、电量、信号、挖孔挡住。
   */
  static readonly K_INSET_TOP: string = 'insetTop';

  /**
   * 「今天」这一根柱子的基准值。
   * 取设计稿里最高的那根（周三 310 XP），本周累计因此与设计稿一致为 1,480。
   * 用户打卡得到的 XP 会叠加在它之上，柱高随进度条一起增长。
   */
  private static readonly TODAY_BASE_XP: number = 310;

  /** 首次启动时写入设计稿中的初始数值，保证首屏与设计稿完全一致。 */
  private static readonly SEED_TOTAL_XP: number = 14 * XP_PER_LEVEL + 1648; // 等级 14 + 1648/2480
  private static readonly SEED_STREAK: number = 3;
  private static readonly DATA_VERSION: number = 1;

  // ────────────────────────── 启动 ──────────────────────────

  /** 在 AppStorage 里建立全部键（EntryAbility 兜底用）。 */
  static bind(): void {
    AppStorage.setOrCreate<boolean>(AppStore.K_READY,
      AppStorage.get<boolean>(AppStore.K_READY) ?? false);
    AppStorage.setOrCreate<boolean>(AppStore.K_UNLOCKED,
      AppStorage.get<boolean>(AppStore.K_UNLOCKED) ?? false);
    AppStorage.setOrCreate<number>(AppStore.K_TOTAL_XP,
      AppStorage.get<number>(AppStore.K_TOTAL_XP) ?? 0);
    AppStorage.setOrCreate<number>(AppStore.K_STREAK,
      AppStorage.get<number>(AppStore.K_STREAK) ?? 0);
    AppStorage.setOrCreate<string>(AppStore.K_DAYS_JSON,
      AppStorage.get<string>(AppStore.K_DAYS_JSON) ?? '{}');
    AppStorage.setOrCreate<string>(AppStore.K_TODAY,
      AppStorage.get<string>(AppStore.K_TODAY) ?? AppStore.todayKey());
    AppStorage.setOrCreate<number>(AppStore.K_REV,
      AppStorage.get<number>(AppStore.K_REV) ?? 0);
    AppStorage.setOrCreate<number>(AppStore.K_INSET_TOP,
      AppStorage.get<number>(AppStore.K_INSET_TOP) ?? 38);
    AppStore.refreshMirrors();
  }

  /**
   * 刷新供界面订阅的字符串镜像。
   * 任何会改变可见状态的操作之后都必须调用它。
   */
  private static refreshMirrors(): void {
    const done: string[] = AppStore.stepsOfDay(AppStore.todayKey());
    let earned: number = 0;
    let ready: number = 0;
    for (const q of QUEST_CATALOG) {
      for (const s of q.steps) {
        if (done.includes(s.id)) {
          earned += s.xp;
        } else {
          ready += s.xp;
        }
      }
    }

    AppStorage.setOrCreate<string>(AppStore.K_DONE_STEPS, done.join(','));
    AppStorage.setOrCreate<string>(AppStore.K_EARNED_XP, earned.toString());
    AppStorage.setOrCreate<string>(AppStore.K_READY_XP, ready.toString());
    AppStorage.setOrCreate<string>(AppStore.K_TOTAL_XP_TEXT, AppStore.getNumber(AppStore.K_TOTAL_XP).toString());
    AppStorage.setOrCreate<string>(AppStore.K_STREAK_TEXT, AppStore.getNumber(AppStore.K_STREAK).toString());
    AppStorage.setOrCreate<string>(AppStore.K_LOGGED_DAYS, Object.keys(AppStore.days()).length.toString());
    // 最后自增修订号：根组件订阅它，从而把当前可见页面整棵重绘。
    const rev: number = AppStorage.get<number>(AppStore.K_REV) ?? 0;
    AppStorage.setOrCreate<number>(AppStore.K_REV, rev + 1);
  }

  /** 读取今日已完成步骤（界面用）。 */
  static doneSteps(): string {
    return AppStorage.get<string>(AppStore.K_DONE_STEPS) ?? '';
  }

  /** 连续打卡天数的字符串形式（界面用）。 */
  static streakText(): string {
    return AppStorage.get<string>(AppStore.K_STREAK_TEXT) ?? '0';
  }

  /** 在 EntryAbility.onCreate 中调用，从本地读回数据。 */
  static async init(context: common.UIAbilityContext): Promise<void> {
    try {
      await Prefs.init(context);
    } catch (e) {
      // 存储不可用时仍然让 App 能跑起来（纯内存模式）。
      AppStore.bind();
      return;
    }

    const seededDay: number = Prefs.getNumber('seedDay', 0);
    const version: number = Prefs.getNumber('version', 0);
    let daysJson: string = Prefs.getString('days', '{}');

    if (seededDay === 0) {
      // 首次安装：只在此处写入演示初始值，之后完全以本地数据为准。
      daysJson = '{}';
      Prefs.setNumber('seedDay', 1);
      Prefs.setNumber('totalXp', AppStore.SEED_TOTAL_XP);
      Prefs.setNumber('streak', AppStore.SEED_STREAK);
      Prefs.setBool('unlocked', false);
      Prefs.setString('days', '{}');
      // 演示数据的连续 3 天已包含今天，避免首日打卡又 +1。
      Prefs.setString('streakDate', AppStore.todayKey());
    } else if (version !== AppStore.DATA_VERSION) {
      // 迁移只重置打卡记录，绝不动用户已经攒下的经验值。
      daysJson = '{}';
      Prefs.setString('days', '{}');
    }
    if (version !== AppStore.DATA_VERSION) {
      Prefs.setNumber('version', AppStore.DATA_VERSION);
    }

    AppStorage.setOrCreate<boolean>(AppStore.K_READY, true);
    AppStorage.setOrCreate<boolean>(AppStore.K_UNLOCKED, Prefs.getBool('unlocked', false));
    AppStorage.setOrCreate<number>(AppStore.K_TOTAL_XP,
      Prefs.getNumber('totalXp', AppStore.SEED_TOTAL_XP));
    AppStorage.setOrCreate<number>(AppStore.K_STREAK,
      Prefs.getNumber('streak', AppStore.SEED_STREAK));
    AppStorage.setOrCreate<string>(AppStore.K_DAYS_JSON, daysJson);
    AppStorage.setOrCreate<string>(AppStore.K_TODAY, AppStore.todayKey());
    AppStore.refreshMirrors();
  }

  // ────────────────────────── 读写 ──────────────────────────

  private static getNumber(key: string): number {
    return AppStorage.get<number>(key) ?? 0;
  }

  private static daysJson(): string {
    return AppStorage.get<string>(AppStore.K_DAYS_JSON) ?? '{}';
  }

  /** 解析打卡记录。每次现解析，保证拿到的一定是最新值。 */
  private static days(): DayMap {
    try {
      return JSON.parse(AppStore.daysJson()) as DayMap;
    } catch (e) {
      return {};
    }
  }

  /**
   * 写回打卡记录。
   * 先序列化成新字符串再进 AppStorage —— 这是刷新能生效的关键。
   */
  private static commit(days: DayMap, gainedXp: number): void {
    AppStorage.setOrCreate<string>(AppStore.K_DAYS_JSON, JSON.stringify(days));
    if (gainedXp > 0) {
      AppStorage.setOrCreate<number>(AppStore.K_TOTAL_XP, AppStore.getNumber(AppStore.K_TOTAL_XP) + gainedXp);
      AppStore.bumpStreakOnce();
    }
    Prefs.setString('days', AppStore.daysJson());
    Prefs.setNumber('totalXp', AppStore.getNumber(AppStore.K_TOTAL_XP));
    Prefs.setNumber('streak', AppStore.getNumber(AppStore.K_STREAK));
    // 镜像刷新必须放在原始值写完之后。
    AppStore.refreshMirrors();
  }

  private static withSteps(days: DayMap, key: string, steps: string[]): DayMap {
    const next: DayMap = {};
    for (const k of Object.keys(days)) {
      next[k] = days[k];
    }
    next[key] = { steps: steps };
    return next;
  }

  // ────────────────────────── 日期 ──────────────────────────

  /** 本地日期键，形如 2026-02-18。 */
  static todayKey(): string {
    const d: Date = new Date();
    const m: string = (d.getMonth() + 1).toString().padStart(2, '0');
    const day: string = d.getDate().toString().padStart(2, '0');
    return d.getFullYear().toString() + '-' + m + '-' + day;
  }

  /** 今天是一周中的第几天：0 = 周一 … 6 = 周日。 */
  private static todayIndex(): number {
    const js: number = new Date().getDay(); // 0 = 周日
    return js === 0 ? 6 : js - 1;
  }

  /**
   * 从媒体查询结果里取出 vp 宽度。
   * 系统返回的字符串形如 "(width=390vp)"，这里只取数字部分。
   */
  static parseVp(media: string): number {
    const matched: RegExpMatchArray | null = media.match(/([0-9]+(?:\.[0-9]+)?)/);
    if (matched === null) {
      return 0;
    }
    const value: number = Number.parseFloat(matched[1]);
    return Number.isFinite(value) ? value : 0;
  }

  static greeting(): string {
    const h: number = new Date().getHours();
    if (h < 5) {
      return '夜深了，小北';
    }
    if (h < 11) {
      return '早上好，小北';
    }
    if (h < 14) {
      return '中午好，小北';
    }
    if (h < 18) {
      return '下午好，小北';
    }
    return '晚上好，小北';
  }

  // ────────────────────────── 打卡 ──────────────────────────

  static stepsOfDay(dateKey: string): string[] {
    const log: DayLog | undefined = AppStore.days()[dateKey];
    return log === undefined ? [] : log.steps;
  }

  static isStepDone(stepId: string): boolean {
    return AppStore.stepsOfDay(AppStore.todayKey()).includes(stepId);
  }

  static doneCount(quest: Quest): number {
    const done: string[] = AppStore.stepsOfDay(AppStore.todayKey());
    let n: number = 0;
    for (const s of quest.steps) {
      if (done.includes(s.id)) {
        n += 1;
      }
    }
    return n;
  }

  static isQuestDone(quest: Quest): boolean {
    return AppStore.doneCount(quest) === quest.steps.length;
  }

  static earnedXp(quest: Quest): number {
    const done: string[] = AppStore.stepsOfDay(AppStore.todayKey());
    let xp: number = 0;
    for (const s of quest.steps) {
      if (done.includes(s.id)) {
        xp += s.xp;
      }
    }
    return xp;
  }

  /** 勾选 / 取消勾选一个微任务，并把变更写入本地存储。 */
  static toggleStep(quest: Quest, stepId: string): void {
    const key: string = AppStore.todayKey();
    const days: DayMap = AppStore.days();
    const existing: DayLog | undefined = days[key];
    const steps: string[] = existing === undefined ? [] : existing.steps.slice();

    const at: number = steps.indexOf(stepId);
    const gained: number = at >= 0 ? 0 : AppStore.xpOfStep(stepId);
    if (at >= 0) {
      steps.splice(at, 1);
    } else {
      steps.push(stepId);
    }
    AppStore.commit(AppStore.withSteps(days, key, steps), gained);
  }

  /**
   * 连续打卡天数每天最多 +1。
   * 用独立的 streakDate 记录「最后一次计分是哪一天」，
   * 否则当天取消勾选后再勾选会把连续天数刷高。
   */
  private static bumpStreakOnce(): boolean {
    if (Prefs.getString('streakDate', '') === AppStore.todayKey()) {
      return false;
    }
    Prefs.setString('streakDate', AppStore.todayKey());
    AppStorage.setOrCreate<number>(AppStore.K_STREAK, AppStore.getNumber(AppStore.K_STREAK) + 1);
    return true;
  }

  /** 一键完成今日全部任务。 */
  static completeAllToday(): void {
    const ids: string[] = [];
    for (const q of QUEST_CATALOG) {
      for (const s of q.steps) {
        ids.push(s.id);
      }
    }
    AppStore.markDone(ids);
  }

  /** 完成某个任务下的全部微任务（详情页 CTA）。 */
  static completeQuest(quest: Quest): void {
    const ids: string[] = [];
    for (const s of quest.steps) {
      ids.push(s.id);
    }
    AppStore.markDone(ids);
  }

  /**
   * 把一批步骤标记为已完成。
   * XP 只在「首次从未完成变为完成」时累加，重复调用不会重复计分；
   * 取消勾选不回退 XP，避免出现负数余额或反复刷分。
   */
  static markDone(stepIds: string[]): void {
    const key: string = AppStore.todayKey();
    const days: DayMap = AppStore.days();
    const merged: string[] = AppStore.stepsOfDay(key).slice();

    let gained: number = 0;
    for (const id of stepIds) {
      if (!merged.includes(id)) {
        merged.push(id);
        gained += AppStore.xpOfStep(id);
      }
    }
    AppStore.commit(AppStore.withSteps(days, key, merged), gained);
  }

  /** 在全目录中反查某个步骤的 XP。 */
  static xpOfStep(stepId: string): number {
    for (const q of QUEST_CATALOG) {
      for (const s of q.steps) {
        if (s.id === stepId) {
          return s.xp;
        }
      }
    }
    return 0;
  }

  /** 重置今日进度（XP 不回退，避免出现负数余额）。 */
  static resetToday(): void {
    const days: DayMap = AppStore.days();
    AppStore.commit(AppStore.withSteps(days, AppStore.todayKey(), []), 0);
  }

  static setUnlocked(value: boolean): void {
    AppStorage.setOrCreate<boolean>(AppStore.K_UNLOCKED, value);
    Prefs.setBool('unlocked', value);
  }

  /** 清空全部本地数据：打卡记录归零、等级回到 1 级、重新锁定封面。 */
  static clearAll(): void {
    AppStorage.setOrCreate<string>(AppStore.K_DAYS_JSON, '{}');
    AppStorage.setOrCreate<number>(AppStore.K_TOTAL_XP, 0);
    AppStorage.setOrCreate<number>(AppStore.K_STREAK, 0);
    Prefs.setString('days', '{}');
    Prefs.setNumber('totalXp', 0);
    Prefs.setNumber('streak', 0);
    Prefs.setString('streakDate', '');
    AppStore.setUnlocked(false);
    AppStore.refreshMirrors();
  }

  /** 恢复设计稿的初始演示数据。 */
  static restoreSeed(): void {
    AppStorage.setOrCreate<string>(AppStore.K_DAYS_JSON, '{}');
    AppStorage.setOrCreate<number>(AppStore.K_TOTAL_XP, AppStore.SEED_TOTAL_XP);
    AppStorage.setOrCreate<number>(AppStore.K_STREAK, AppStore.SEED_STREAK);
    Prefs.setString('days', '{}');
    Prefs.setNumber('totalXp', AppStore.SEED_TOTAL_XP);
    Prefs.setNumber('streak', AppStore.SEED_STREAK);
    // 演示数据已经包含「今天」的连续打卡，避免当天再 +1。
    Prefs.setString('streakDate', AppStore.todayKey());
    AppStore.refreshMirrors();
  }

  // ────────────────────────── 派生指标 ──────────────────────────

  static todayEarnedXp(): number {
    const done: string[] = AppStore.stepsOfDay(AppStore.todayKey());
    let xp: number = 0;
    for (const q of QUEST_CATALOG) {
      for (const s of q.steps) {
        if (done.includes(s.id)) {
          xp += s.xp;
        }
      }
    }
    return xp;
  }

  static todayReadyXp(): number {
    const done: string[] = AppStore.stepsOfDay(AppStore.todayKey());
    let xp: number = 0;
    for (const q of QUEST_CATALOG) {
      for (const s of q.steps) {
        if (!done.includes(s.id)) {
          xp += s.xp;
        }
      }
    }
    return xp;
  }

  static completedQuestCount(): number {
    let n: number = 0;
    for (const q of QUEST_CATALOG) {
      if (AppStore.isQuestDone(q)) {
        n += 1;
      }
    }
    return n;
  }

  static level(): LevelInfo {
    return LevelMath.info(AppStore.persistedXp());
  }

  static streak(): number {
    return AppStore.persistedStreak();
  }

  static totalXp(): number {
    return AppStore.persistedXp();
  }

  /**
   * 直接读本地存储，绕开 AppStorage。
   * 用于「页面重建后必须拿到真值」的显示场景：
   * 读 AppStorage 有可能拿到本组件自己写过的过期镜像。
   */
  static persistedXp(): number {
    return Prefs.getNumber('totalXp', 0);
  }

  static persistedStreak(): number {
    return Prefs.getNumber('streak', 0);
  }

  /** 当前数据修订号（供组件把「数据变了」变成显式依赖）。 */
  static dataRev(): number {
    return AppStorage.get<number>(AppStore.K_REV) ?? 0;
  }

  // ────────────────────────── 统计页 ──────────────────────────

  /**
   * 周 / 月两套数据。
   * 周视图里「今天」那根柱子 = 设计稿基准值 + 今天真实打卡得到的 XP，
   * 这样首屏数值与设计稿一致，同时打卡会实时反映在图表上。
   * 月视图没有「今天」的精确归属（设计稿也没有），因此按月聚合的演示数据展示。
   */
  static rangeStats(range: StatsRange): DailyStat[] {
    if (range === StatsRange.MONTH) {
      return MONTH_SEED;
    }
    const out: DailyStat[] = [];
    for (let i = 0; i < WEEK_SEED.length; i++) {
      const day: DailyStat = WEEK_SEED[i];
      if (i === AppStore.todayIndex()) {
        out.push({
          label: day.label,
          xp: AppStore.TODAY_BASE_XP + AppStore.todayEarnedXp(),
          items: AppStore.todayItems()
        });
      } else {
        out.push({ label: day.label, xp: day.xp, items: day.items });
      }
    }
    return out;
  }

  /** 图表 X 轴标签：周视图是「一二三四五六日」，月视图是「第 1…4 周」。 */
  static rangeLabels(range: StatsRange): string[] {
    return range === StatsRange.WEEK ? WEEK_LABELS : MONTH_LABELS;
  }

  /** 今日已完成任务按分类聚合成图表 tooltip 的行。 */
  static todayItems(): QuestItem[] {
    const done: string[] = AppStore.stepsOfDay(AppStore.todayKey());
    const labels: string[] = [];
    const totals: number[] = [];
    for (const q of QUEST_CATALOG) {
      const meta = categoryOf(q.category);
      for (const s of q.steps) {
        if (!done.includes(s.id)) {
          continue;
        }
        const at: number = labels.indexOf(meta.label);
        if (at < 0) {
          labels.push(meta.label);
          totals.push(s.xp);
        } else {
          totals[at] = totals[at] + s.xp;
        }
      }
    }
    const items: QuestItem[] = [];
    for (let i = 0; i < labels.length; i++) {
      items.push({ label: labels[i], xp: totals[i] });
    }
    return items;
  }

  static summary(range: StatsRange): StatsSummary {
    const stats: DailyStat[] = AppStore.rangeStats(range);
    let total: number = 0;
    let doneCount: number = 0;
    for (const d of stats) {
      total += d.xp;
      doneCount += Math.round(d.xp / 65);
    }

    // 环比：以设计稿里同周期的原始数值作为「上一周期」基准。
    const prevSeed: DailyStat[] = range === StatsRange.WEEK ? WEEK_SEED : MONTH_SEED;
    let prev: number = 0;
    for (const d of prevSeed) {
      prev += d.xp;
    }
    const delta: number = prev === 0 ? 0 : Math.round(((total - prev) / prev) * 100);

    const goal: number = range === StatsRange.WEEK ? 2000 : 8000;
    const remain: number = Math.max(0, goal - total);

    return {
      rangeTotal: total,
      rangeDelta: delta,
      goalXp: goal,
      goalReached: total >= goal,
      goalRemain: remain,
      goalPercent: Math.min(100, Math.round((total / goal) * 100)),
      // 专注时长按「约 330 XP / 小时」折算（设计稿 1480 XP ≈ 4.5h）。
      focusHours: Math.round((total / 330) * 10) / 10,
      doneCount: doneCount,
      streakDays: AppStore.streak()
    };
  }

  /** 任务分布：按当前周期的真实 XP 构成计算，而不是写死百分比。 */
  static breakdown(range: StatsRange): BreakdownRow[] {
    const stats: DailyStat[] = AppStore.rangeStats(range);
    const labels: string[] = [];
    const totals: number[] = [];

    for (const d of stats) {
      for (const item of d.items) {
        const at: number = labels.indexOf(item.label);
        if (at < 0) {
          labels.push(item.label);
          totals.push(item.xp);
        } else {
          totals[at] = totals[at] + item.xp;
        }
      }
    }

    // 按 XP 降序。
    for (let i = 0; i < totals.length; i++) {
      for (let j = i + 1; j < totals.length; j++) {
        if (totals[j] > totals[i]) {
          const tv: number = totals[i];
          totals[i] = totals[j];
          totals[j] = tv;
          const tl: string = labels[i];
          labels[i] = labels[j];
          labels[j] = tl;
        }
      }
    }

    let sum: number = 0;
    for (const t of totals) {
      sum += t;
    }

    const rows: BreakdownRow[] = [];
    for (let i = 0; i < labels.length; i++) {
      rows.push({
        label: labels[i],
        percent: sum === 0 ? 0 : Math.round((totals[i] / sum) * 100),
        color: AppStore.colorOfLabel(labels[i])
      });
    }
    return rows.slice(0, 5);
  }

  static colorOfLabel(label: string): string {
    for (const c of CATEGORIES) {
      if (c.label === label) {
        return c.chart;
      }
    }
    return '#4A86E9';
  }

  /**
   * 各分类累计 XP（「我的」页展示用）。
   *
   * 刻意**不读 WEEK_SEED 演示数据**：那份数据是写死的，
   * 会导致「清空全部本地数据」之后这一块还显示旧数值。
   * 这里改为遍历真实打卡记录统计，清空后自然归零。
   */
  static categoryTotals(): QuestItem[] {
    const labels: string[] = [];
    const totals: number[] = [];
    const days: DayMap = AppStore.days();

    for (const dateKey of Object.keys(days)) {
      const done: string[] = days[dateKey].steps;
      for (const q of QUEST_CATALOG) {
        const label: string = categoryOf(q.category).label;
        let xp: number = 0;
        for (const s of q.steps) {
          if (done.includes(s.id)) {
            xp += s.xp;
          }
        }
        if (xp <= 0) {
          continue;
        }
        const at: number = labels.indexOf(label);
        if (at < 0) {
          labels.push(label);
          totals.push(xp);
        } else {
          totals[at] = totals[at] + xp;
        }
      }
    }

    // 按 XP 降序
    for (let i = 0; i < totals.length; i++) {
      for (let j = i + 1; j < totals.length; j++) {
        if (totals[j] > totals[i]) {
          const tv: number = totals[i];
          totals[i] = totals[j];
          totals[j] = tv;
          const tl: string = labels[i];
          labels[i] = labels[j];
          labels[j] = tl;
        }
      }
    }

    const out: QuestItem[] = [];
    for (let i = 0; i < labels.length; i++) {
      out.push({ label: labels[i], xp: totals[i] });
    }
    return out;
  }

  /** 已记录打卡的日期列表（「我的」页显示记录天数）。 */
  static loggedDates(): string[] {
    const keys: string[] = Object.keys(AppStore.days());
    keys.sort();
    return keys;
  }

  /** 判断一个步骤在详情页右侧该显示什么。 */
  static stepDoneText(quest: Quest, stepId: string): string {
    return AppStore.isStepDone(stepId) ? '已完成' : '+' + AppStore.stepXp(quest, stepId).toString() + ' XP';
  }

  static stepXp(quest: Quest, stepId: string): number {
    for (const s of quest.steps) {
      if (s.id === stepId) {
        return s.xp;
      }
    }
    return 0;
  }
}

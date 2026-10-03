/**
 * 领域模型 —— 「进阶 Level」每日任务。
 * 对应设计稿：屏 2 今日任务、屏 3 任务详情、屏 4 数据统计。
 */

/** 任务分类（设计稿 6 个分类：体能 / 阅读 / 收听 / 饮食 / 冥想 / 观看）。 */
export enum QuestCategory {
  BODY = 'BODY',
  READ = 'READ',
  LISTEN = 'LISTEN',
  NOURISH = 'NOURISH',
  MIND = 'MIND',
  WATCH = 'WATCH'
}

/** 分类元数据：中文名、浅色卡底、图标底色、图标资源、图表色。 */
export interface CategoryMeta {
  key: QuestCategory;
  label: string;
  tile: string;
  glyphBg: string;
  glyph: Resource;
  chart: string;
}

/** 任务内的一个微任务步骤。 */
export interface QuestStep {
  id: string;
  name: string;
  xp: number;
}

/** 一个每日任务。 */
export interface Quest {
  id: string;
  category: QuestCategory;
  /** 卡片标题，如「体能」。 */
  title: string;
  /** 卡片副文案，如「20 分钟力量训练：俯卧撑与平板支撑」。 */
  summary: string;
  /** 详情页 Hero 标题，如「20 分钟，改变这个周三。」 */
  heroTitle: string;
  /** 详情页 Hero 正文。 */
  heroDesc: string;
  /** 详情页 Hero 徽标，如「体能 · 力量」。 */
  badge: string;
  /** 任务基础经验值（等于各步骤之和）。 */
  xp: number;
  steps: QuestStep[];
}

/** 一周中某一天的统计。 */
export interface DailyStat {
  /** 星期标签：一 / 二 / … / 日。 */
  label: string;
  /** 当日累计 XP。 */
  xp: number;
  /** 当日完成的任务构成 [分类中文名, XP]。 */
  items: QuestItem[];
}

/** 图表 tooltip 中的一行：某分类贡献的 XP。 */
export interface QuestItem {
  label: string;
  xp: number;
}

/** 任务分布条（屏 4 .breakdown）。 */
export interface BreakdownRow {
  label: string;
  percent: number;
  color: string;
}

/** 等级丝带的展示数据。 */
export interface LevelInfo {
  level: number;
  levelName: string;
  /** 当前等级已获得 XP。 */
  xp: number;
  /** 升到下一级所需 XP。 */
  nextXp: number;
  /** 进度百分比 0–100。 */
  percent: number;
}

/** 统计页的聚合结果。 */
export interface StatsSummary {
  rangeTotal: number;
  rangeDelta: number;
  goalXp: number;
  goalReached: boolean;
  goalRemain: number;
  goalPercent: number;
  focusHours: number;
  doneCount: number;
  streakDays: number;
}

/** 数据统计页的周期切换：周 / 月。 */
export enum StatsRange {
  WEEK = 'WEEK',
  MONTH = 'MONTH'
}

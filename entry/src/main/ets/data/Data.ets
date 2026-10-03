import { CategoryMeta, DailyStat, Quest, QuestCategory } from '../model/Quest';

/**
 * 静态目录与初始演示数据。
 * 文案、数值、顺序全部照搬 daily-quests-app.html，不做改写。
 */

/** 6 个任务分类的元数据（浅色卡底 / 图标底色取自 .q.q1…q6 与 --tile-*）。 */
export const CATEGORIES: CategoryMeta[] = [
  {
    key: QuestCategory.BODY,
    label: '体能',
    tile: '#FFE1D9',
    glyphBg: '#FF7A52',
    glyph: $r('app.media.gl_body'),
    chart: '#FF7A52'
  },
  {
    key: QuestCategory.READ,
    label: '阅读',
    tile: '#FFE9BF',
    glyphBg: '#EAA233',
    glyph: $r('app.media.gl_read'),
    chart: '#EAA233'
  },
  {
    key: QuestCategory.LISTEN,
    label: '收听',
    tile: '#F3E6FF',
    glyphBg: '#B08BF2',
    glyph: $r('app.media.gl_listen'),
    chart: '#B08BF2'
  },
  {
    key: QuestCategory.NOURISH,
    label: '饮食',
    tile: '#D2EECB',
    glyphBg: '#63B352',
    glyph: $r('app.media.gl_nourish'),
    chart: '#63B352'
  },
  {
    key: QuestCategory.MIND,
    label: '冥想',
    tile: '#FFD6F1',
    glyphBg: '#E76AAE',
    glyph: $r('app.media.gl_mind'),
    chart: '#E76AAE'
  },
  {
    key: QuestCategory.WATCH,
    label: '观看',
    tile: '#D6E7FF',
    glyphBg: '#4A86E9',
    glyph: $r('app.media.gl_watch'),
    chart: '#4A86E9'
  }
];

export function categoryOf(key: QuestCategory): CategoryMeta {
  for (const c of CATEGORIES) {
    if (c.key === key) {
      return c;
    }
  }
  return {
    key: QuestCategory.BODY,
    label: '其他',
    tile: '#F5F1E9',
    glyphBg: '#8C857C',
    glyph: $r('app.media.gl_body'),
    chart: '#8C857C'
  };
}

/** 今日 6 个任务，XP 合计 430（与设计稿「今日 6 个任务 · 可获 430 XP」一致）。 */
export const QUEST_CATALOG: Quest[] = [
  {
    id: 'quest-body',
    category: QuestCategory.BODY,
    title: '体能',
    summary: '20 分钟力量训练：俯卧撑与平板支撑',
    heroTitle: '20 分钟，改变这个周三。',
    heroDesc: '一段简短、可重复的力量训练——俯卧撑、平板支撑，外加一个随机动作。无需器械。小北，你本月已完成 11 次。',
    badge: '体能 · 力量',
    xp: 90,
    steps: [
      { id: 'body-1', name: '铺好瑜伽垫', xp: 5 },
      { id: 'body-2', name: '3 × 12 个俯卧撑', xp: 30 },
      { id: 'body-3', name: '3 × 45 秒平板支撑', xp: 30 },
      { id: 'body-4', name: '随机动作：弓步蹲', xp: 25 }
    ]
  },
  {
    id: 'quest-read',
    category: QuestCategory.READ,
    title: '阅读',
    summary: '《四千周》· 30 页',
    heroTitle: '30 页，把注意力收回来。',
    heroDesc: '读《四千周》30 页。不求快，只求留下三条自己的批注——这本书讲的正是「时间有限」这件事。',
    badge: '阅读 · 深度',
    xp: 60,
    steps: [
      { id: 'read-1', name: '把手机放到另一个房间', xp: 5 },
      { id: 'read-2', name: '读完 30 页', xp: 40 },
      { id: 'read-3', name: '写下三条批注', xp: 15 }
    ]
  },
  {
    id: 'quest-listen',
    category: QuestCategory.LISTEN,
    title: '收听',
    summary: 'Huberman Lab · 睡眠结构',
    heroTitle: '听懂你的睡眠结构。',
    heroDesc: '听完 Huberman Lab 关于睡眠结构的一期，重点抓「深睡与 REM 的比例」。通勤或散步时听即可。',
    badge: '收听 · 播客',
    xp: 50,
    steps: [
      { id: 'listen-1', name: '戴上耳机开始播放', xp: 5 },
      { id: 'listen-2', name: '听完本期节目', xp: 30 },
      { id: 'listen-3', name: '记一条可执行结论', xp: 15 }
    ]
  },
  {
    id: 'quest-nourish',
    category: QuestCategory.NOURISH,
    title: '饮食',
    summary: '做一顿高蛋白午餐',
    heroTitle: '给自己做一顿高蛋白午餐。',
    heroDesc: '不看外卖软件，用冰箱里现有的食材做一顿高蛋白午餐。关键是动手，而不是完美。',
    badge: '饮食 · 备餐',
    xp: 70,
    steps: [
      { id: 'nourish-1', name: '确定蛋白质主料', xp: 10 },
      { id: 'nourish-2', name: '完成烹饪与装盘', xp: 45 },
      { id: 'nourish-3', name: '吃完并收拾台面', xp: 15 }
    ]
  },
  {
    id: 'quest-mind',
    category: QuestCategory.MIND,
    title: '冥想',
    summary: '10 分钟专注冥想',
    heroTitle: '10 分钟，只是呼吸。',
    heroDesc: '坐下，闭眼，把注意力放回呼吸。走神了就回来，这本身就是练习。',
    badge: '冥想 · 专注',
    xp: 40,
    steps: [
      { id: 'mind-1', name: '设定 10 分钟计时', xp: 5 },
      { id: 'mind-2', name: '完成专注冥想', xp: 35 }
    ]
  },
  {
    id: 'quest-watch',
    category: QuestCategory.WATCH,
    title: '观看',
    summary: '《熊家餐馆》· S3 E4',
    heroTitle: '一集剧，作为今天的奖励。',
    heroDesc: '完成其他任务之后再看《熊家餐馆》S3 E4。把它当作奖励，而不是逃避。',
    badge: '观看 · 放松',
    xp: 30,
    steps: [
      { id: 'watch-1', name: '确认其他任务已完成', xp: 5 },
      { id: 'watch-2', name: '看完这一集', xp: 25 }
    ]
  }
];

export function questById(id: string): Quest | undefined {
  for (const q of QUEST_CATALOG) {
    if (q.id === id) {
      return q;
    }
  }
  return undefined;
}

export function questXpTotal(): number {
  let total = 0;
  for (const q of QUEST_CATALOG) {
    total += q.xp;
  }
  return total;
}

/** 一周演示数据，与设计稿 .bars / .days 中的数值逐条对应。 */
export const WEEK_SEED: DailyStat[] = [
  { label: '一', xp: 180, items: [{ label: '体能', xp: 90 }, { label: '收听', xp: 50 }, { label: '冥想', xp: 40 }] },
  {
    label: '二',
    xp: 240,
    items: [{ label: '体能', xp: 90 }, { label: '阅读', xp: 60 }, { label: '收听', xp: 50 }, { label: '冥想', xp: 40 }]
  },
  {
    label: '三',
    xp: 310,
    items: [
      { label: '体能', xp: 90 }, { label: '饮食', xp: 70 }, { label: '阅读', xp: 60 },
      { label: '收听', xp: 50 }, { label: '冥想', xp: 40 }
    ]
  },
  { label: '四', xp: 160, items: [{ label: '体能', xp: 90 }, { label: '冥想', xp: 40 }, { label: '观看', xp: 30 }] },
  {
    label: '五',
    xp: 270,
    items: [{ label: '体能', xp: 90 }, { label: '饮食', xp: 70 }, { label: '阅读', xp: 60 }, { label: '收听', xp: 50 }]
  },
  {
    label: '六',
    xp: 200,
    items: [{ label: '饮食', xp: 70 }, { label: '阅读', xp: 60 }, { label: '冥想', xp: 40 }, { label: '观看', xp: 30 }]
  },
  { label: '日', xp: 120, items: [{ label: '体能', xp: 90 }, { label: '观看', xp: 30 }] }
];

/** 周 / 月两套演示数据（月视图按 4 周聚合，数值为设计稿周数据的等比放大）。 */
export const MONTH_SEED: DailyStat[] = [
  { label: '第 1 周', xp: 1180, items: [{ label: '体能', xp: 420 }, { label: '阅读', xp: 240 }, { label: '收听', xp: 200 }, { label: '饮食', xp: 180 }, { label: '冥想', xp: 140 }] },
  { label: '第 2 周', xp: 1480, items: [{ label: '体能', xp: 530 }, { label: '阅读', xp: 240 }, { label: '收听', xp: 200 }, { label: '饮食', xp: 140 }, { label: '冥想', xp: 160 }, { label: '观看', xp: 90 }] },
  { label: '第 3 周', xp: 1320, items: [{ label: '体能', xp: 480 }, { label: '阅读', xp: 180 }, { label: '收听', xp: 150 }, { label: '饮食', xp: 210 }, { label: '冥想', xp: 120 }, { label: '观看', xp: 60 }] },
  { label: '第 4 周', xp: 960, items: [{ label: '体能', xp: 360 }, { label: '阅读', xp: 120 }, { label: '收听', xp: 90 }, { label: '饮食', xp: 140 }, { label: '冥想', xp: 80 }, { label: '观看', xp: 60 }] }
];

/** 每级所需 XP（升级曲线）。设计稿停在等级 14、2480 XP。 */
export const XP_PER_LEVEL: number = 2480;

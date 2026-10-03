/**
 * 设计令牌（Design Tokens）
 * ------------------------------------------------------------------
 * 唯一来源：daily-quests-app.html 的 :root 变量与内联样式。
 * 任何组件都不得直接写死色值 / 字号，必须引用本文件，
 * 以避免框架默认主题色和默认字体渗入实现。
 *
 * 单位说明：设计稿是 360px 宽的 iPhone 画布，鸿蒙 1vp 在手机上约等于 1px，
 * 因此这里直接沿用设计稿数值作为 vp，保持像素级比例。
 */

/** 取色辅助：把 #RRGGBB 按 alpha 混合成 #AARRGGBB。 */
function tint(hex: string, alpha: number): string {
  const a: number = Math.round(alpha * 255);
  const v: string = a.toString(16).padStart(2, '0').toUpperCase();
  return '#' + v + hex.substring(1).toUpperCase();
}

export class Color {
  // ── 舞台 / 深色面 ──
  static readonly stage: string = '#0E0D0C';      // --stage 页面最外层深色
  static readonly stage2: string = '#1A1714';     // --stage-2 次层深色
  static readonly ink: string = '#1A1714';        // --ink 正文墨色 / 深色卡片
  static readonly inkCardEnd: string = '#2B251F'; // 深色渐变卡片终点 #2b251f
  static readonly inkDeep: string = '#050403';    // 机身/挖孔黑
  static readonly peek: string = '#211D18';       // next-peek 面板

  // ── 纸张 / 浅色面 ──
  static readonly paper: string = '#FFFFFF';      // --paper
  static readonly paperWarm: string = '#FDF8F0';  // chart-card 渐变终点
  static readonly tileBg: string = '#F5F1E9';     // .stile 底色

  // ── 文本 ──
  static readonly muted: string = '#6C6660';      // --muted
  static readonly onStage: string = '#F5EFE4';    // 深色面上的正文
  static readonly onCover: string = '#FEF9EE';    // cover 屏正文
  static readonly inkSoft: string = '#D8D2C6';    // 未完成勾选圈描边

  // ── 描边 / 分割 ──
  static readonly line: string = '#EBE6DD';       // --line

  // ── 强调色 ──
  static readonly accent: string = '#E98425';     // --accent
  static readonly accent2: string = '#FF6B3D';    // --accent-2
  static readonly success: string = '#2F8F3C';    // .delta 绿色

  // ── 深色面上的半透明文本（对应 rgba(245,239,228,x)） ──
  static readonly onDark72: string = tint(Color.onStage, 0.72);
  static readonly onDark60: string = tint(Color.onStage, 0.60);
  static readonly onDark52: string = tint(Color.onStage, 0.52);
  static readonly onDark16: string = tint(Color.onStage, 0.16);
  static readonly onDark12: string = tint(Color.onStage, 0.12);

  // ── cover 屏的半透明文本（对应 rgba(254,249,238,x)） ──
  static readonly onCover78: string = tint(Color.onCover, 0.78);
  static readonly onCover66: string = tint(Color.onCover, 0.66);
  static readonly onCover62: string = tint(Color.onCover, 0.62);
  static readonly onCover42: string = tint(Color.onCover, 0.42);
  static readonly onCover22: string = tint(Color.onCover, 0.22);
  static readonly onCover20: string = tint(Color.onCover, 0.20);

  // ── 任务分类浅色底（--tile-1 … --tile-6） ──
  static readonly tile1: string = '#FFE9BF'; // 阅读
  static readonly tile2: string = '#FFE1D9'; // 体能
  static readonly tile3: string = '#F3E6FF'; // 收听
  static readonly tile4: string = '#D2EECB'; // 饮食
  static readonly tile5: string = '#D6E7FF'; // 观看
  static readonly tile6: string = '#FFD6F1'; // 冥想
  static readonly tile0: string = '#F5F1E9'; // 兜底

  // ── 任务分类图标底色 ──
  static readonly gBody: string = '#FF7A52';
  static readonly gRead: string = '#EAA233';
  static readonly gListen: string = '#B08BF2';
  static readonly gNourish: string = '#63B352';
  static readonly gMind: string = '#E76AAE';
  static readonly gWatch: string = '#4A86E9';
  static readonly gIdle: string = '#8C857C';

  // ── 任务详情 Hero 渐变（linear-gradient(160deg,#ffd2bb,#ff7a52)） ──
  static readonly heroStart: string = '#FFD2BB';
  static readonly heroEnd: string = '#FF7A52';

  // ── 封面橙色光晕（radial-gradient ellipse 80% 50% rgba(233,132,37,.20)） ──
  static readonly glowTop: string = tint(Color.accent, 0.20);
  static readonly glowBottom: string = tint('#FFFFFF', 0.05);

  // ── 柱状图 ──
  static readonly barFrom: string = tint(Color.accent, 0.44);
  static readonly barTo: string = tint(Color.accent, 0.20);
  static readonly tipBg: string = tint(Color.ink, 0.97);
  static readonly tipLine: string = tint('#FFFFFF', 0.07);
}

export class Font {
  /**
   * 设计稿使用 Noto Serif SC / Noto Sans SC / IBM Plex Mono（Google Fonts）。
   * 鸿蒙设备不预装这些字体，且离线 App 不应依赖在线字体，
   * 因此映射到系统自带的「HarmonyOS Sans」族系并保留衬线回退。
   * 详细对照见工程根目录 README.md「字体替换说明」。
   */
  static readonly serif: string = 'HarmonyOS Sans SC, Noto Serif SC, serif';
  static readonly sans: string = 'HarmonyOS Sans SC, Noto Sans SC, sans-serif';
  static readonly mono: string = 'HarmonyOS Sans SC, IBM Plex Mono, monospace';
}

export class FontSize {
  static readonly h1: number = 54;         // .cover h1
  static readonly display: number = 42;    // .s-summary .big
  static readonly h1Tablet: number = 46;   // @media(max-width:1200px) 时的 46
  static readonly heroTitle: number = 30;  // .hero h2
  static readonly wordmark: number = 24;   // .stage-bar .word
  static readonly tileValue: number = 20;  // .stile .v
  static readonly title: number = 18;      // .head h2 / .s-head h2
  static readonly ribbonLv: number = 15;   // .level-ribbon .lv
  static readonly lede: number = 14.5;     // .cover p.lede / .start
  static readonly body: number = 14;       // body 基准
  static readonly bodySm: number = 13.5;   // .q .title / .hero p
  static readonly caption: number = 12.5;  // .home .sub
  static readonly label: number = 11;      // .q .meta / .tip
  static readonly eyebrow: number = 10.5;  // .eyebrow / .badge
  static readonly micro: number = 10;      // .seg span / .stile .k
  static readonly tab: number = 9.5;       // .tab
  static readonly tiny: number = 9.5;      // .col .bar .v
}

export class Weight {
  static readonly regular: number = 400;
  static readonly medium: number = 500;
  static readonly semibold: number = 600;
  static readonly bold: number = 700;
  static readonly black: number = 900;
}

export class Space {
  static readonly x0: number = 0;
  static readonly x2: number = 2;
  static readonly x4: number = 4;
  static readonly x6: number = 6;
  static readonly x7: number = 7;
  static readonly x8: number = 8;
  static readonly x9: number = 9;
  static readonly x10: number = 10;
  static readonly x11: number = 11;
  static readonly x12: number = 12;
  static readonly x13: number = 13;
  static readonly x14: number = 14;   // 卡片左右外边距
  static readonly x15: number = 15;
  static readonly x16: number = 16;
  static readonly x18: number = 18;
  static readonly x20: number = 20;
  static readonly x22: number = 22;   // 页面左右内边距
  static readonly x24: number = 24;
  static readonly x26: number = 26;
  static readonly x28: number = 28;
  static readonly x30: number = 30;
  static readonly x34: number = 34;
  static readonly x40: number = 40;
}

export class Radius {
  static readonly chip: number = 9;      // .q .glyph
  static readonly tip: number = 12;
  static readonly lv: number = 13;       // .level-ribbon .lv
  static readonly stile: number = 15;
  static readonly goal: number = 16;
  static readonly q: number = 18;        // .q / .chart-card / .level-ribbon
  static readonly hero: number = 24;     // .hero
  static readonly peek: number = 26;     // .next-peek 上圆角
  static readonly sheet: number = 28;
  static readonly full: number = 999;    // 胶囊
}

export class Motion {
  static readonly fast: number = 150;    // transition .15s
  static readonly tipFade: number = 160; // .xp-tip .16s
  static readonly grow: number = 600;    // @keyframes grow .6s
  static readonly fillBar: number = 700; // @keyframes fillbar .7s
}

/** 布局常量：设计画布与响应式断点。 */
export class Layout {
  /** 设计稿手机画布宽度（360px → 360vp）。 */
  static readonly canvas: number = 360;
  /** 内容最大宽度：平板 / 折叠屏展开后居中，避免卡片被拉得过宽。 */
  static readonly contentMax: number = 680;
  /** 任务卡网格列数断点（vp）。 */
  static readonly grid2: number = 0;
  static readonly grid3: number = 560;
  static readonly grid4: number = 900;
  /** 底部标签栏。 */
  static readonly tabBarHeight: number = 62;
  /** 状态栏预留高度（鸿蒙由系统统一绘制，这里只做视觉留白）。 */
  static readonly statusBar: number = 38;
}

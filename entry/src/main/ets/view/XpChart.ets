import { componentUtils } from '@kit.ArkUI';
import { DailyStat, QuestItem } from '../model/Quest';
import { Color, Font, FontSize, Radius, Space, Weight } from '../common/Theme';

const CHART_H: number = 140;
const BAR_W: number = 20;
/** 卡片自身的组件 id，用于把柱子坐标换算成卡片内的相对坐标。 */
const CARD_ID: string = 'xp-card';

/** 提示框位置（相对所属页面，单位 vp）。由 XpChart 算好后交给页面绘制。 */
export interface ChartTip {
  visible: boolean;
  x: number;
  y: number;
  /** 指向箭头相对提示框左边缘的偏移，被夹取后仍能对准柱子。 */
  tail: number;
  /** true = 画在柱子下方（箭头在顶部）。 */
  below: boolean;
  day: string;
  xp: number;
  rows: QuestItem[];
}

/** 测量用的矩形（vp）。 */
interface Rect {
  x: number;
  y: number;
  w: number;
  h: number;
}

export const EMPTY_TIP: ChartTip = {
  visible: false, x: 0, y: 0, tail: 0, below: false, day: '', xp: 0, rows: []
};

/**
 * 屏 4 · XP 趋势图（设计稿 .chart-card + .xp-tip）。
 *
 * 提示框本身**不在这里绘制** —— 它由页面（StatsView）画在图表卡片之外，
 * 否则会被卡片裁剪、也压不过下面的「本周目标」卡片。
 * 这里只负责：算好位置，通过 onTip 回调交给页面。
 */
@Component
export struct XpChart {
  @Prop stats: DailyStat[];
  @Prop labels: string[];
  @Prop rangeLabel: string;
  @Prop cardWidth: number;
  /** 回传提示框位置；位置相对图表卡片左上角（vp）。 */
  onTip: (tip: ChartTip, cardW: number, cardH: number) => void =
    (tip: ChartTip, cardW: number, cardH: number) => {};

  private tipW: number = 132;
  private tipH: number = 64;

  private maxXp(): number {
    let m: number = 1;
    for (const d of this.stats) {
      m = Math.max(m, d.xp);
    }
    return m;
  }

  private bestIndex(): number {
    let best: number = 0;
    for (let i = 0; i < this.stats.length; i++) {
      if (this.stats[i].xp > this.stats[best].xp) {
        best = i;
      }
    }
    return best;
  }

  /**
   * 读取组件在窗口中的位置与尺寸，并换算成 vp。
   * componentUtils 返回的 size / windowOffset 单位是 px，
   * 而布局用的是 vp，不换算高 DPI 设备上会整体偏移。
   */
  private measure(id: string): Rect {
    const fallback: Rect = { x: 0, y: 0, w: 0, h: 0 };
    try {
      const info: componentUtils.ComponentInfo =
        this.getUIContext().getComponentUtils().getRectangleById(id);
      return {
        x: this.getUIContext().px2vp(info.windowOffset.x),
        y: this.getUIContext().px2vp(info.windowOffset.y),
        w: this.getUIContext().px2vp(info.size.width),
        h: this.getUIContext().px2vp(info.size.height)
      };
    } catch (err) {
      return fallback;
    }
  }

  private show(index: number): void {
    const day: DailyStat = this.stats[index];
    if (day === undefined) {
      return;
    }
    const card: Rect = this.measure(CARD_ID);
    const bar: Rect = this.measure('xpbar-' + index.toString());

    // 卡片内的相对坐标：提示框由页面画在卡片之外，用同一套坐标即可对齐。
    const barLeft: number = bar.x - card.x;
    const barTop: number = bar.y - card.y;
    const barCenterX: number = barLeft + bar.w / 2;

    let left: number = barCenterX - this.tipW / 2;
    left = Math.max(6, Math.min(this.cardWidth - this.tipW - 6, left));

    let top: number = barTop - this.tipH - 9;
    let below: boolean = false;
    if (top < 6) {
      // 上方空间不足 → 画到柱子下方（设计稿 .xp-tip.below）
      top = barTop + bar.h + 9;
      below = true;
    }

    this.onTip({
      visible: true,
      x: left,
      y: top,
      tail: barCenterX - left,
      below: below,
      day: day.label,
      xp: day.xp,
      rows: day.items
    }, this.cardWidth, card.h);
  }

  private hide(): void {
    this.onTip(EMPTY_TIP, this.cardWidth, this.measure(CARD_ID).h);
  }

  @Builder
  bars() {
    Row({ space: 7 }) {
      ForEach(this.stats, (day: DailyStat, index: number) => {
        Column() {
          Blank()
          Column() {
            Text(day.xp.toString())
              .fontFamily(Font.mono)
              .fontSize(FontSize.tiny)
              .fontWeight(Weight.semibold)
              .fontColor(index === this.bestIndex() ? Color.accent : Color.muted)
              .margin({ bottom: 3 })
            Column()
              .width(BAR_W)
              .height(Math.max(4, Math.round(CHART_H * day.xp / this.maxXp())))
              .borderRadius({ topLeft: 7, topRight: 7, bottomLeft: 4, bottomRight: 4 })
              .linearGradient({
                angle: 180,
                colors: index === this.bestIndex()
                  ? [[Color.accent, 0.0], [Color.accent2, 1.0]]
                  : [[Color.barFrom, 0.0], [Color.barTo, 1.0]]
              })
              .id('xpbar-' + index.toString())
          }
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.End)
          .height(CHART_H)
        }
        .layoutWeight(1)
        .height(CHART_H)
        .justifyContent(FlexAlign.End)
        .alignItems(HorizontalAlign.Center)
        .id('xpcol-' + index.toString())
        .onHover((isHover: boolean) => {
          if (isHover) {
            this.show(index);
          } else {
            this.hide();
          }
        })
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.show(index);
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.hide();
          }
        })
        .accessibilityText(day.label + ' ' + day.xp.toString() + ' XP')
      }, (day: DailyStat, index: number) => day.label + '-' + index.toString())
    }
    .width('100%')
    .height(CHART_H)
    .padding({ top: 22 })
    .id('xpbars')
  }

  @Builder
  dayLabels() {
    Row({ space: 7 }) {
      ForEach(this.stats, (day: DailyStat, index: number) => {
        Text(this.labels[index])
          .fontFamily(Font.mono)
          .fontSize(FontSize.micro)
          .fontColor(index === this.bestIndex() ? Color.ink : Color.muted)
          .fontWeight(index === this.bestIndex() ? Weight.semibold : Weight.regular)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }, (day: DailyStat, index: number) => 'lb-' + index.toString())
    }
    .width('100%')
    .margin({ top: Space.x9 })
  }

  build() {
    Column() {
      Row() {
        Text('XP 趋势')
          .fontFamily(Font.sans)
          .fontSize(FontSize.bodySm)
          .fontWeight(Weight.bold)
          .fontColor(Color.ink)
        Blank()
        Text(this.rangeLabel)
          .fontFamily(Font.mono)
          .fontSize(FontSize.micro)
          .fontColor(Color.muted)
          .letterSpacing(1)
      }
      .width('100%')

      this.bars()
      this.dayLabels()
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: Space.x16, right: Space.x16, top: Space.x15, bottom: Space.x12 })
    .margin({ left: Space.x14, right: Space.x14, top: Space.x10 })
    .borderRadius(Radius.q)
    .backgroundColor(Color.paper)
    .linearGradient({ angle: 180, colors: [[Color.paper, 0.0], [Color.paperWarm, 1.0]] })
    .border({ width: 1, color: Color.line })
    .id(CARD_ID)
  }
}

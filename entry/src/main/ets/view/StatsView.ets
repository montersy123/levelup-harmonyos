import { componentUtils, display } from '@kit.ArkUI';
import { BreakdownRow, DailyStat, QuestItem, StatsRange, StatsSummary } from '../model/Quest';
import { AppStore } from '../store/AppStore';
import { ChartTip, EMPTY_TIP, XpChart } from '../view/XpChart';
import { TabBar, TabIndex } from '../view/TabBar';
import { Color, Font, FontSize, Motion, Radius, Space, Weight } from '../common/Theme';
import { grouped } from '../common/Format';

/** 提示框尺寸（vp），与 XpChart 中的估计一致。 */
const TIP_W: number = 132;
const TIP_H: number = 64;
/** 提示框层级：要压过「本周目标」卡片。 */
const TIP_Z: number = 99;
/** 最外层 Stack 的 id，用于把提示框坐标换算到根节点。 */
const ROOT_ID: string = 'stats-root';

/** 测量用的矩形（vp）。 */
interface Rect {
  x: number;
  y: number;
  w: number;
  h: number;
}

/**
 * 屏 4 · 数据统计（设计稿 .screen.stats）。
 * 周 / 月分段控件、XP 趋势柱状图（带明细 tooltip）、
 * 本周目标卡、三宫格指标、任务分布条。
 *
 * 提示框画在最外层 Stack 里（见图表下方的 chartTooltip）：
 * 画在图表卡片内部会被裁剪，也压不过后面声明的「本周目标」卡片。
 */
@Component
export struct StatsView {
  @Prop viewport: number;
  @Prop cardWidth: number;
  /** 顶部安全区（状态栏 / 挖孔）高度。 */
  @Prop insetTop: number = 38;
  @StorageLink(AppStore.K_TODAY) todayKey: string = '';
  /** 订阅字符串镜像，打卡后汇总与图表同步刷新。 */
  @StorageLink(AppStore.K_DONE_STEPS) doneSteps: string = '';
  @StorageLink(AppStore.K_TOTAL_XP_TEXT) totalXpText: string = '0';
  @State private range: StatsRange = StatsRange.WEEK;
  @State private goalWidth: number = 0;
  /** 柱子明细提示：内容 + 在根节点坐标系里的位置。 */
  @State private tip: ChartTip = EMPTY_TIP;
  @State private tipX: number = 0;
  @State private tipY: number = 0;
  onSelectTab: (index: number) => void = () => {};

  private stats(): DailyStat[] {
    return AppStore.rangeStats(this.range);
  }

  private labels(): string[] {
    return AppStore.rangeLabels(this.range);
  }

  private summary(): StatsSummary {
    return AppStore.summary(this.range);
  }

  private rangeLabel(): string {
    return this.range === StatsRange.WEEK ? '近 7 天' : '近 4 周';
  }

  aboutToAppear(): void {
    this.goalWidth = this.goalTrackWidth() * AppStore.summary(this.range).goalPercent / 100;
  }

  private goalTrackWidth(): number {
    return this.cardWidth - Space.x14 * 2 - Space.x16 * 2;
  }

  private goalText(): string {
    const s: StatsSummary = this.summary();
    if (s.goalReached) {
      return '已达成 ' + s.goalXp.toString() + ' XP 目标 · 保持势头';
    }
    return '还差 ' + s.goalRemain.toString() + ' XP 达成 · 保持势头';
  }

  private switchRange(range: StatsRange): void {
    if (this.range === range) {
      return;
    }
    this.range = range;
    const target: number = this.goalTrackWidth() * AppStore.summary(range).goalPercent / 100;
    this.getUIContext().animateTo({ duration: Motion.fillBar, curve: Curve.FastOutSlowIn }, () => {
      this.goalWidth = target;
    });
  }

  // ────────────────────── 提示框定位 ──────────────────────

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

  /** 屏幕高度（vp），用于把提示框夹在屏幕内。 */
  private viewportHeight(): number {
    try {
      const d: display.Display = display.getDefaultDisplaySync();
      return d.densityPixels > 0 ? d.height / d.densityPixels : 800;
    } catch (e) {
      return 800;
    }
  }

  /**
   * 接收图表算好的位置。
   * 图表给的是「相对图表卡片左上角」的坐标，这里换算到本页最外层 Stack：
   * 先量出卡片相对根节点的偏移再加上去，最后夹取到屏幕内。
   */
  private onChartTip(tip: ChartTip): void {
    if (!tip.visible) {
      this.tip = EMPTY_TIP;
      return;
    }
    const card: Rect = this.measure('xp-card');
    const root: Rect = this.measure(ROOT_ID);
    const originX: number = card.x - root.x;
    const originY: number = card.y - root.y;

    // 横向：卡片左右内边距 14，提示框不能超出内容区
    let x: number = originX + tip.x;
    x = Math.max(6, Math.min(this.cardWidth + Space.x14 - TIP_W - 6, x));

    // 纵向：夹在屏幕内，保证翻到下方时也完整可见
    let y: number = originY + tip.y;
    y = Math.max(Space.x10, Math.min(this.viewportHeight() - TIP_H - Space.x14, y));

    this.tipX = x;
    this.tipY = y;
    this.tip = tip;
  }

  // ────────────────────── 构建块 ──────────────────────

  @Builder
  rangeSwitch() {
    Row({ space: Space.x2 }) {
      Text('周')
        .fontFamily(Font.mono)
        .fontSize(FontSize.micro)
        .fontWeight(Weight.semibold)
        .fontColor(this.range === StatsRange.WEEK ? Color.onStage : Color.muted)
        .letterSpacing(1)
        .padding({ left: Space.x12, right: Space.x12, top: Space.x6, bottom: Space.x6 })
        .backgroundColor(this.range === StatsRange.WEEK ? Color.ink : Color.line)
        .borderRadius(Radius.full)
        .onClick(() => {
          this.switchRange(StatsRange.WEEK);
        })
      Text('月')
        .fontFamily(Font.mono)
        .fontSize(FontSize.micro)
        .fontWeight(Weight.semibold)
        .fontColor(this.range === StatsRange.MONTH ? Color.onStage : Color.muted)
        .letterSpacing(1)
        .padding({ left: Space.x12, right: Space.x12, top: Space.x6, bottom: Space.x6 })
        .backgroundColor(this.range === StatsRange.MONTH ? Color.ink : Color.line)
        .borderRadius(Radius.full)
        .onClick(() => {
          this.switchRange(StatsRange.MONTH);
        })
    }
    .padding(3)
    .backgroundColor(Color.line)
    .borderRadius(Radius.full)
  }

  @Builder
  pageHeader() {
    Row() {
      Text('数据')
        .fontFamily(Font.sans)
        .fontSize(FontSize.title)
        .fontWeight(Weight.bold)
        .fontColor(Color.ink)
        .letterSpacing(0.2)
      Blank()
      this.rangeSwitch()
    }
    .width('100%')
    .padding({ left: Space.x22, right: Space.x22, top: this.insetTop, bottom: Space.x2 })
  }

  @Builder
  summaryBlock() {
    Row({ space: Space.x14 }) {
      Text() {
        Span(grouped(this.summary().rangeTotal))
          .fontColor(Color.ink)
        Span(' XP')
          .fontColor(Color.muted)
          .fontSize(FontSize.caption)
      }
      .fontFamily(Font.serif)
      .fontSize(FontSize.display)
      .fontWeight(Weight.black)

      Column() {
        Text(this.range === StatsRange.WEEK ? '本周累计' : '本月累计')
          .fontFamily(Font.mono)
          .fontSize(FontSize.micro)
          .fontColor(Color.muted)
          .letterSpacing(2)
          .margin({ bottom: Space.x6 })
        Row({ space: Space.x4 }) {
          Image($r('app.media.ic_trend'))
            .width(12)
            .height(12)
            .draggable(false)
          Text(this.deltaText())
            .fontFamily(Font.mono)
            .fontSize(FontSize.caption)
            .fontWeight(Weight.semibold)
            .fontColor(Color.success)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ bottom: Space.x2 })

      Blank()
    }
    .width('100%')
    .alignItems(VerticalAlign.Bottom)
    .padding({ left: Space.x22, right: Space.x22, top: Space.x13 })
  }

  private deltaText(): string {
    const d: number = this.summary().rangeDelta;
    const sign: string = d > 0 ? '+' : '';
    return sign + d.toString() + '% 较上' + (this.range === StatsRange.WEEK ? '周' : '月');
  }

  @Builder
  goalCard() {
    Column() {
      Row() {
        Text(this.range === StatsRange.WEEK ? '本周目标' : '本月目标')
          .fontFamily(Font.mono)
          .fontSize(FontSize.micro)
          .fontColor(Color.onDark60)
          .letterSpacing(2)
        Blank()
        Text(grouped(this.summary().rangeTotal) + ' / ' + grouped(this.summary().goalXp) + ' XP')
          .fontFamily(Font.mono)
          .fontSize(FontSize.caption)
          .fontWeight(Weight.bold)
          .fontColor(Color.onStage)
      }
      .width('100%')

      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width('100%')
          .height(7)
          .backgroundColor(Color.onDark16)
          .borderRadius(Radius.full)
        Row()
          .width(this.goalWidth)
          .height(7)
          .borderRadius(Radius.full)
          .linearGradient({
            angle: 90,
            colors: [[Color.accent, 0.0], [Color.accent2, 1.0]]
          })
      }
      .width('100%')
      .height(7)
      .margin({ top: Space.x10, bottom: Space.x8 })

      Text(this.goalText())
        .fontFamily(Font.mono)
        .fontSize(FontSize.label)
        .fontColor(Color.onDark52)
        .width('100%')
    }
    .width('100%')
    .padding({ left: Space.x16, right: Space.x16, top: Space.x14, bottom: Space.x14 })
    .margin({ left: Space.x14, right: Space.x14, top: Space.x12 })
    .borderRadius(Radius.goal)
    .linearGradient({
      angle: 135,
      colors: [[Color.stage2, 0.0], [Color.inkCardEnd, 1.0]]
    })
  }

  @Builder
  statTile(value: string, unit: string, key: string) {
    Column() {
      Text() {
        Span(value)
          .fontFamily(Font.serif)
          .fontSize(FontSize.tileValue)
          .fontWeight(Weight.bold)
          .fontColor(Color.ink)
        Span(unit)
          .fontFamily(Font.mono)
          .fontSize(FontSize.micro)
          .fontWeight(Weight.semibold)
          .fontColor(Color.muted)
      }
      .margin({ bottom: Space.x7 })
      Text(key)
        .fontFamily(Font.mono)
        .fontSize(FontSize.micro)
        .fontColor(Color.muted)
        .letterSpacing(0.5)
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
    .padding({ left: Space.x11, right: Space.x11, top: Space.x12, bottom: Space.x12 })
    .backgroundColor(Color.tileBg)
    .borderRadius(Radius.stile)
  }

  @Builder
  tiles() {
    Row({ space: Space.x9 }) {
      this.statTile(this.summary().focusHours.toString(), 'h', '专注时长')
      this.statTile(this.summary().doneCount.toString(), '个', '完成任务')
      this.statTile(this.summary().streakDays.toString(), '天', '连续打卡')
    }
    .width('100%')
    .padding({ left: Space.x14, right: Space.x14, top: Space.x12 })
  }

  @Builder
  breakdown() {
    Column() {
      Text('任务分布')
        .fontFamily(Font.mono)
        .fontSize(FontSize.eyebrow)
        .fontWeight(Weight.bold)
        .fontColor(Color.muted)
        .letterSpacing(2)
        .margin({ bottom: Space.x11 })
        .width('100%')
        .textAlign(TextAlign.Start)

      ForEach(AppStore.breakdown(this.range), (row: BreakdownRow) => {
        Row({ space: Space.x10 }) {
          Text(row.label)
            .fontFamily(Font.sans)
            .fontSize(FontSize.caption)
            .fontColor(Color.ink)
            .width(38)
            .textAlign(TextAlign.Start)
          Stack({ alignContent: Alignment.Start }) {
            Row()
              .width('100%')
              .height(7)
              .backgroundColor(Color.line)
              .borderRadius(Radius.full)
            Row()
              .width(row.percent.toString() + '%')
              .height(7)
              .borderRadius(Radius.full)
              .backgroundColor(row.color)
          }
          .layoutWeight(1)
          .height(7)
          Text(row.percent.toString() + '%')
            .fontFamily(Font.mono)
            .fontSize(FontSize.label)
            .fontWeight(Weight.semibold)
            .fontColor(Color.muted)
            .width(34)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .margin({ bottom: Space.x9 })
      }, (row: BreakdownRow) => row.label)
    }
    .width('100%')
    .padding({ left: Space.x20, right: Space.x20, top: Space.x13, bottom: Space.x6 })
  }

  @Builder
  chartTooltip() {
    Column() {
      if (this.tip.below) {
        Row()
          .width(10)
          .height(10)
          .backgroundColor(Color.tipBg)
          .rotate({ angle: 45 })
          .margin({ left: this.tip.tail - 5, bottom: -5 })
          .alignSelf(ItemAlign.Start)
      }

      Column() {
        Row() {
          Text(this.tip.day)
            .fontFamily(Font.sans)
            .fontSize(FontSize.caption)
            .fontWeight(Weight.bold)
            .fontColor(Color.onStage)
          Blank()
          Text(this.tip.xp.toString() + ' XP')
            .fontFamily(Font.mono)
            .fontSize(FontSize.eyebrow)
            .fontWeight(Weight.semibold)
            .fontColor(Color.accent)
        }
        .width('100%')
        .padding({ bottom: Space.x7 })
        .margin({ bottom: Space.x7 })
        .border({ width: { bottom: 1 }, color: Color.onDark16 })

        ForEach(this.tip.rows, (row: QuestItem) => {
          Row({ space: Space.x7 }) {
            Row()
              .width(7)
              .height(7)
              .borderRadius(2)
              .backgroundColor(AppStore.colorOfLabel(row.label))
            Text(row.label)
              .fontFamily(Font.sans)
              .fontSize(FontSize.label)
              .fontWeight(Weight.medium)
              .fontColor('#EBF5EFE4')
            Blank()
            Text('+' + row.xp.toString())
              .fontFamily(Font.mono)
              .fontSize(FontSize.eyebrow)
              .fontWeight(Weight.semibold)
              .fontColor(Color.onDark60)
          }
          .width('100%')
        }, (row: QuestItem) => row.label)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ left: Space.x12, right: Space.x12, top: Space.x10, bottom: Space.x10 })
      .backgroundColor(Color.tipBg)
      .borderRadius(Radius.tip)
      .border({ width: 1, color: Color.tipLine })
      .shadow({ radius: 32, color: '#5C1A1714', offsetX: 0, offsetY: 16 })

      if (!this.tip.below) {
        Row()
          .width(10)
          .height(10)
          .backgroundColor(Color.tipBg)
          .rotate({ angle: 45 })
          .margin({ left: this.tip.tail - 5, top: -5 })
          .alignSelf(ItemAlign.Start)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width(TIP_W)
    .position({ x: this.tipX, y: this.tipY })
    .zIndex(TIP_Z)
    .visibility(this.tip.visible ? Visibility.Visible : Visibility.Hidden)
    .hitTestBehavior(HitTestMode.None)
    .accessibilityText(this.tip.day + ' ' + this.tip.xp.toString() + ' XP')
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        Scroll() {
          Column() {
            this.pageHeader()
            this.summaryBlock()
            XpChart({
              stats: this.stats(),
              labels: this.labels(),
              rangeLabel: this.rangeLabel(),
              cardWidth: this.cardWidth,
              onTip: (tip: ChartTip, cardW: number, cardH: number) => {
                this.onChartTip(tip);
              }
            })
            this.goalCard()
            this.tiles()
            this.breakdown()
            Blank().height(Space.x16)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
        .edgeEffect(EdgeEffect.Spring)

        TabBar({
          active: TabIndex.Stats,
          onSelect: (index: number) => {
            this.onSelectTab(index);
          }
        })
      }
      .width('100%')
      .height('100%')

      // 最外层：提示框要压过「本周目标」卡片，所以画在这里
      this.chartTooltip()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.paper)
    .id(ROOT_ID)
  }
}

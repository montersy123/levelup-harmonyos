import { LevelInfo } from '../model/Quest';
import { AppStore } from '../store/AppStore';
import { Color, Font, FontSize, Motion, Radius, Space, Weight } from '../common/Theme';

/**
 * 等级丝带（设计稿 .level-ribbon）。
 * 深色渐变底 + 橙色等级方块 + 等级内 XP 进度条。
 * 进度来自 AppStore.level()，打卡后自动刷新；
 * 进度条宽度按传入的卡片宽度换算，因此在平板 / 折叠屏下依然准确。
 */
@Component
export struct LevelRibbon {
  /** 本组件可用宽度（vp）。手机 = 视口宽；平板 = 内容限宽。 */
  @Prop cardWidth: number;
  /**
   * 外部刷新计数。父组件数据变化时改这个值，
   * 强制本组件重建并现读 AppStore（否则父组件重绘不会带动本组件）。
   */
  @Prop tick: number = 0;
  @State private barWidth: number = 0;

  /** 轨道宽度 = 卡片宽 - 左右外边距 14*2 - 内边距 15*2。 */
  private trackWidth(): number {
    const w: number = this.cardWidth - Space.x14 * 2 - Space.x15 * 2;
    return w > 0 ? w : 0;
  }

  /** 现读本地存储的等级信息，带上 tick 依赖。 */
  private level(): LevelInfo {
    const marker: number = this.tick;
    const info: LevelInfo = AppStore.level();
    return marker >= 0 ? info : info;
  }

  aboutToAppear(): void {
    this.syncBar();
  }

  private syncBar(): void {
    const target: number = this.trackWidth() * this.level().percent / 100;
    this.getUIContext().animateTo({ duration: Motion.fillBar, curve: Curve.FastOutSlowIn }, () => {
      this.barWidth = target;
    });
  }

  /** 视口宽度变化（折叠屏展开 / 旋转 / 分屏），或 tick 变化后重算进度条。 */
  private onResize(): void {
    const target: number = this.trackWidth() * this.level().percent / 100;
    if (Math.abs(target - this.barWidth) > 0.5) {
      this.barWidth = target;
    }
  }

  onDidBuild(): void {
    if (Math.abs(this.trackWidth() * this.level().percent / 100 - this.barWidth) > 0.5) {
      this.onResize();
    }
  }

  build() {
    Column() {
      Row() {
        Text(this.level().level.toString())
          .fontFamily(Font.mono)
          .fontSize(FontSize.ribbonLv)
          .fontWeight(Weight.bold)
          .fontColor(Color.ink)
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
          .backgroundColor(Color.accent)
          .borderRadius(Radius.lv)

        Column() {
          Text('LEVEL')
            .fontFamily(Font.mono)
            .fontSize(FontSize.micro)
            .fontColor(Color.onDark52)
            .letterSpacing(2)
          Text(this.level().levelName)
            .fontFamily(Font.sans)
            .fontSize(FontSize.ribbonLv - 0.5)
            .fontWeight(Weight.bold)
            .fontColor(Color.onStage)
            .margin({ top: Space.x4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: Space.x12 })

        Text(this.level().xp.toString() + ' / ' + this.level().nextXp.toString())
          .fontFamily(Font.mono)
          .fontSize(FontSize.caption)
          .fontWeight(Weight.semibold)
          .fontColor(Color.onDark72)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width('100%')
          .height(6)
          .backgroundColor(Color.onDark12)
          .borderRadius(Radius.full)
        Row()
          .width(this.barWidth)
          .height(6)
          .borderRadius(Radius.full)
          .linearGradient({
            angle: 90,
            colors: [[Color.accent, 0.0], [Color.accent2, 1.0]]
          })
      }
      .width('100%')
      .height(6)
      .margin({ top: Space.x9 })
    }
    .width('100%')
    .padding({ left: Space.x15, right: Space.x15, top: Space.x13, bottom: Space.x13 })
    .margin({ left: Space.x14, right: Space.x14, top: Space.x8, bottom: Space.x12 })
    .borderRadius(Radius.q)
    .linearGradient({
      angle: 135,
      colors: [[Color.stage2, 0.0], [Color.inkCardEnd, 1.0]]
    })
    .onAreaChange(() => {
      this.onResize();
    })
  }
}

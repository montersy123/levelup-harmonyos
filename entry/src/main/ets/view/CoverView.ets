import { Color, Font, FontSize, Radius, Space, Weight } from '../common/Theme';

/** 顶部光晕的过渡色：#e98425 按给定 alpha 混合。 */
function tintAccent(alpha: number): string {
  const a: number = Math.round(alpha * 255);
  return '#' + a.toString(16).padStart(2, '0').toUpperCase() + 'E98425';
}

/**
 * 屏 1 · 封面海报（设计稿 .screen.cover）。
 * 深色舞台底 + 顶部橙色光晕，标题「每日任务，成为更好的自己。」
 * 底部 next-peek 面板改造成进入今日任务的入口（真实 App 需要可点击的推进动作）。
 */
@Component
export struct CoverView {
  /** 页面宽度，大于画布宽度时按设计稿的 46px 缩放标题。 */
  @Prop viewport: number;
  /** 顶部安全区高度：封面是深色满屏，这里只保证文字不被状态栏压住。 */
  @Prop insetTop: number = 38;
  onEnter: () => void = () => {};

  private titleSize(): number {
    return this.viewport > 1200 ? FontSize.h1 : FontSize.h1Tablet;
  }

  build() {
    Column() {
      Column() {
        // 主视觉：eyebrow 徽标
        Row({ space: Space.x7 }) {
          Row()
            .width(6)
            .height(6)
            .borderRadius(Radius.full)
            .backgroundColor(Color.accent)
          Text('每日任务 · 本地数据')
            .fontFamily(Font.mono)
            .fontSize(FontSize.eyebrow)
            .fontColor(Color.onCover62)
            .letterSpacing(1)
        }
        .padding({ left: Space.x11, right: Space.x11, top: Space.x7, bottom: Space.x7 })
        .border({ width: 1, color: Color.onCover22 })
        .borderRadius(Radius.full)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: Space.x28 })

        // 主标题（fraction 保留白字，accent 段为橙色）
        Text() {
          Span('每日任务，成为')
            .fontColor(Color.onCover)
          Span('更好的自己')
            .fontColor(Color.accent)
          Span('。')
            .fontColor(Color.onCover)
        }
        .fontFamily(Font.serif)
        .fontSize(this.titleSize())
        .fontWeight(Weight.black)
        .lineHeight(this.titleSize() * 1.06)
        .letterSpacing(0.5)
        .margin({ bottom: Space.x18 })
        .width('100%')

        Text('进阶把你想做却总在拖延的事——运动、阅读、早睡、给朋友打个电话——变成一份每日任务清单。完成它们，赚取经验值，看着自己一点点升级。')
          .fontFamily(Font.sans)
          .fontSize(FontSize.lede)
          .lineHeight(23)
          .fontColor(Color.onCover66)
          .margin({ bottom: Space.x20 })
          .width('100%')

        Column() {
          Text('所有数据只保存在本机，不联网、不上传。')
            .fontFamily(Font.mono)
            .fontSize(FontSize.label)
            .lineHeight(18)
            .fontColor(Color.onCover42)
        }
        .width('100%')
        .padding({ top: Space.x13 })
        .border({ width: { top: 1 }, color: Color.onCover20, style: BorderStyle.Dashed })
        .alignItems(HorizontalAlign.Start)

        Blank()
      }
      .width('100%')
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: Space.x28, right: Space.x28, top: this.insetTop + Space.x20 })

      // next-peek：进入今日任务
      Row({ space: Space.x12 }) {
        Row()
          .width(38)
          .height(38)
          .borderRadius(Radius.chip)
          .backgroundColor(Color.accent)
        Text('进入今日任务')
          .fontFamily(Font.mono)
          .fontSize(FontSize.label)
          .fontColor(Color.onDark60)
          .letterSpacing(2)
        Blank()
        Text('→')
          .fontFamily(Font.mono)
          .fontSize(FontSize.title)
          .fontColor(Color.accent)
      }
      .width('100%')
      .height(96)
      .padding({ left: Space.x22, right: Space.x22 })
      .backgroundColor(Color.peek)
      .borderRadius({ topLeft: Radius.peek, topRight: Radius.peek })
      .onClick(() => {
        this.onEnter();
      })
      .accessibilityText('进入今日任务')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.ink)
    // 设计稿用的是 radial-gradient 顶部橙色光晕；ArkUI 的 linearGradient 在角度 180
    // 时自上而下渐变，这里用多色标近似原来的径向衰减。
    .linearGradient({
      angle: 180,
      colors: [
        [Color.glowTop, 0.0],
        [tintAccent(0.10), 0.28],
        [tintAccent(0.03), 0.52],
        [Color.ink, 0.78],
        [Color.ink, 1.0]
      ]
    })
  }
}

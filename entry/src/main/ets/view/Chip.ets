import { Color, Font, FontSize, Radius, Space, Weight } from '../common/Theme';

/**
 * 数字/内容徽标（XP 胶囊、连续打卡、分类标签…）。
 * 对应设计稿 .q .xp / .home .sub .pill / .hero .badge / .stile .k 等。
 */
@Component
export struct Chip {
  @Prop text: string;
  @Prop bg: string = Color.ink;
  @Prop fg: string = Color.onStage;
  @Prop fontSize: number = FontSize.label;
  @Prop paddingH: number = Space.x8;
  @Prop paddingV: number = Space.x6 - 1;
  /** true = 等宽字体 + 字距（设计稿里数字类胶囊都用 mono）。 */
  @Prop mono: boolean = true;
  @Prop borderColor: string = '';

  build() {
    Text(this.text)
      .fontFamily(this.mono ? Font.mono : Font.sans)
      .fontSize(this.fontSize)
      .fontWeight(Weight.semibold)
      .fontColor(this.fg)
      .letterSpacing(this.mono ? 1 : 0)
      .padding({ left: this.paddingH, right: this.paddingH, top: this.paddingV, bottom: this.paddingV })
      .backgroundColor(this.bg)
      .borderRadius(Radius.full)
      .border(this.borderColor === ''
        ? { width: 0 }
        : { width: 1, color: this.borderColor })
  }
}

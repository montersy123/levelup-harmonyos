import { Quest } from '../model/Quest';
import { categoryOf } from '../data/Data';
import { AppStore } from '../store/AppStore';
import { Color, Font, FontSize, Radius, Space, Weight } from '../common/Theme';

/**
 * 今日任务卡（设计稿 .q.q1…q6）。
 * 分类决定浅色卡底与图标底色；右下角胶囊显示剩余/已获 XP。
 *
 * 勾选进度从 K_DONE_STEPS 字符串镜像读取，打卡后卡片立刻刷新。
 */
@Component
export struct QuestCard {
  @Prop quest: Quest;
  @Prop cardWidth: number;
  @StorageLink(AppStore.K_TODAY) todayKey: string = '';
  @StorageLink(AppStore.K_DONE_STEPS) doneSteps: string = '';
  onOpen: (quest: Quest) => void = () => {};

  private stepDone(stepId: string): boolean {
    return this.doneSteps.split(',').includes(stepId);
  }

  private doneCount(): number {
    let n: number = 0;
    for (const s of this.quest.steps) {
      if (this.stepDone(s.id)) {
        n += 1;
      }
    }
    return n;
  }

  private isDone(): boolean {
    return this.doneCount() === this.quest.steps.length;
  }

  private earnedXp(): number {
    let xp: number = 0;
    for (const s of this.quest.steps) {
      if (this.stepDone(s.id)) {
        xp += s.xp;
      }
    }
    return xp;
  }

  build() {
    Column() {
      Row() {
        Stack() {
          Image(categoryOf(this.quest.category).glyph)
            .width(17)
            .height(17)
            .draggable(false)
        }
        .width(30)
        .height(30)
        .backgroundColor(categoryOf(this.quest.category).glyphBg)
        .borderRadius(Radius.chip)

        Blank()

        if (this.isDone()) {
          Image($r('app.media.ic_check'))
            .width(14)
            .height(14)
            .draggable(false)
        }
      }
      .width('100%')

      Text(this.quest.title)
        .fontFamily(Font.sans)
        .fontSize(FontSize.bodySm)
        .fontWeight(Weight.bold)
        .fontColor(Color.ink)
        .margin({ top: Space.x7 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(this.quest.summary)
        .fontFamily(Font.sans)
        .fontSize(FontSize.label)
        .fontColor(Color.ink)
        .opacity(0.72)
        .lineHeight(16)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: Space.x2 })
        .width('100%')
        .textAlign(TextAlign.Start)
        .flexShrink(1)

      Blank()

      Row() {
        if (this.doneCount() > 0 && !this.isDone()) {
          Text(this.doneCount().toString() + '/' + this.quest.steps.length.toString())
            .fontFamily(Font.mono)
            .fontSize(FontSize.micro)
            .fontWeight(Weight.semibold)
            .fontColor(Color.muted)
            .backgroundColor(Color.paper)
            .opacity(0.85)
            .padding({ left: Space.x6, right: Space.x6, top: Space.x2 + 1, bottom: Space.x2 + 1 })
            .borderRadius(Radius.full)
        }
        Blank()
        Text('+' + this.earnedXp().toString())
          .fontFamily(Font.mono)
          .fontSize(FontSize.label)
          .fontWeight(Weight.bold)
          .fontColor(Color.onStage)
          .letterSpacing(1)
          .padding({ left: Space.x8, right: Space.x8, top: Space.x6 - 1, bottom: Space.x6 - 1 })
          .backgroundColor(Color.ink)
          .borderRadius(Radius.full)
      }
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width(this.cardWidth)
    .height(108)
    .padding(Space.x12)
    .borderRadius(Radius.q)
    .backgroundColor(categoryOf(this.quest.category).tile)
    .hoverEffect(HoverEffect.Highlight)
    .onClick(() => {
      this.onOpen(this.quest);
    })
    .accessibilityText(this.quest.title + '，' + this.quest.summary +
      '，已获 ' + this.earnedXp().toString() + ' 经验')
  }
}

import { Quest } from '../model/Quest';
import { QUEST_CATALOG, categoryOf } from '../data/Data';
import { AppStore } from '../store/AppStore';
import { TabBar, TabIndex } from '../view/TabBar';
import { Color, Font, FontSize, Radius, Space, Weight } from '../common/Theme';

/**
 * 资料库。
 * 设计稿的 5 槽标签栏里有「资料库」入口但没有对应画面，
 * 这里按同一套 token 补一个同风格页面：
 * 上半部分是本地存档说明，下半部分是今日任务清单（作为「可回看的内容」）。
 */
@Component
export struct LibraryView {
  @Prop viewport: number;
  /** 顶部安全区（状态栏 / 挖孔）高度。 */
  @Prop insetTop: number = 38;
  @StorageLink(AppStore.K_TODAY) todayKey: string = '';
  /** 订阅打卡步骤，已完成状态才不会滞后。 */
  @StorageLink(AppStore.K_DONE_STEPS) doneSteps: string = '';
  onOpenQuest: (quest: Quest) => void = () => {};
  onSelectTab: (index: number) => void = () => {};

  @Builder
  countChip() {
    Text(QUEST_CATALOG.length.toString() + ' 个任务')
      .fontFamily(Font.mono)
      .fontSize(FontSize.micro)
      .fontColor(Color.muted)
      .letterSpacing(1)
  }

  private isQuestDone(quest: Quest): boolean {
    const done: string[] = this.doneSteps.split(',');
    for (const s of quest.steps) {
      if (!done.includes(s.id)) {
        return false;
      }
    }
    return true;
  }

  @Builder
  libraryRow(quest: Quest) {
    Row({ space: Space.x12 }) {
      Stack() {
        Image(categoryOf(quest.category).glyph)
          .width(18)
          .height(18)
          .draggable(false)
      }
      .width(34)
      .height(34)
      .backgroundColor(categoryOf(quest.category).glyphBg)
      .borderRadius(Radius.chip)

      Column() {
        Text(quest.title)
          .fontFamily(Font.sans)
          .fontSize(FontSize.body)
          .fontWeight(Weight.bold)
          .fontColor(Color.ink)
          .width('100%')
          .textAlign(TextAlign.Start)
        Text(quest.summary)
          .fontFamily(Font.sans)
          .fontSize(FontSize.label)
          .fontColor(Color.muted)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: Space.x2 + 1 })
          .width('100%')
          .textAlign(TextAlign.Start)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text(this.isQuestDone(quest) ? '已完成' : '+' + quest.xp.toString())
        .fontFamily(Font.mono)
        .fontSize(FontSize.label)
        .fontWeight(Weight.semibold)
        .fontColor(AppStore.isQuestDone(quest) ? Color.accent : Color.muted)
        .letterSpacing(1)
    }
    .width('100%')
    .padding({ left: Space.x14, right: Space.x14, top: Space.x13, bottom: Space.x13 })
    .backgroundColor(Color.paper)
    .borderRadius(Radius.q)
    .border({ width: 1, color: Color.line })
    .hoverEffect(HoverEffect.Highlight)
    .onClick(() => {
      this.onOpenQuest(quest);
    })
    .accessibilityText(quest.title + '，' + quest.summary)
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: Space.x10 }) {
          // 资料库是标签页，不需要返回按钮
          Column() {
            Row() {
              Text('资料库')
                .fontFamily(Font.sans)
                .fontSize(FontSize.title)
                .fontWeight(Weight.bold)
                .fontColor(Color.ink)
                .letterSpacing(0.2)
              Blank()
              this.countChip()
            }
            .width('100%')

            Text('全部内容都存在这台手机上，离线可用。')
              .fontFamily(Font.sans)
              .fontSize(FontSize.caption)
              .fontColor(Color.muted)
              .margin({ top: Space.x6 })
              .width('100%')
              .textAlign(TextAlign.Start)
          }
          .width('100%')
          .padding({ left: Space.x22, right: Space.x22, top: this.insetTop, bottom: Space.x4 })
          .alignItems(HorizontalAlign.Start)

          Column({ space: Space.x10 }) {
            ForEach(QUEST_CATALOG, (quest: Quest) => {
              this.libraryRow(quest)
            }, (quest: Quest) => quest.id)
          }
          .width('100%')
          .padding({ left: Space.x14, right: Space.x14 })

          this.localNote()
          Blank().height(Space.x20)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
      .edgeEffect(EdgeEffect.Spring)

      TabBar({
        active: TabIndex.Library,
        onSelect: (index: number) => {
          this.onSelectTab(index);
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.paper)
  }

  @Builder
  localNote() {
    Column() {
      Row({ space: Space.x6 }) {
        Row()
          .width(6)
          .height(6)
          .borderRadius(Radius.full)
          .backgroundColor(Color.accent)
        Text('本地存储')
          .fontFamily(Font.mono)
          .fontSize(FontSize.eyebrow)
          .fontColor(Color.muted)
          .letterSpacing(2)
      }
      .width('100%')

      Text('打卡记录、经验值与统计全部写入手机本地存储（Preferences），不联网、不上传、不需要账号。卸载 App 即随之删除。')
        .fontFamily(Font.sans)
        .fontSize(FontSize.label)
        .lineHeight(19)
        .fontColor(Color.muted)
        .margin({ top: Space.x8 })
        .width('100%')
        .textAlign(TextAlign.Start)
    }
    .width('100%')
    .padding({ left: Space.x16, right: Space.x16, top: Space.x14, bottom: Space.x14 })
    .margin({ left: Space.x14, right: Space.x14, top: Space.x12 })
    .backgroundColor(Color.tileBg)
    .borderRadius(Radius.goal)
  }
}

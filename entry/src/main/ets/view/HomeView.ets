import { Quest } from '../model/Quest';
import { QUEST_CATALOG } from '../data/Data';
import { AppStore } from '../store/AppStore';
import { LevelRibbon } from '../view/LevelRibbon';
import { QuestGrid } from '../view/QuestGrid';
import { TabBar, TabIndex } from '../view/TabBar';
import { Color, Font, FontSize, Layout, Radius, Space, Weight } from '../common/Theme';

/**
 * 屏 2 · 今日任务（设计稿 .screen.home）。
 * 问候语 + 连续打卡 + 等级丝带 + 「今天 N 个任务 · 可获 x XP」+ 任务卡网格。
 * 「今日」是主页面，因此不显示返回按钮。
 */
@Component
export struct HomeView {
  @Prop viewport: number;
  /** 顶部安全区（状态栏 / 挖孔）高度，避免内容被系统信息遮挡。 */
  @Prop insetTop: number = 38;
  @StorageLink(AppStore.K_TODAY) todayKey: string = '';
  /** 今日已获 / 还可获得的 XP（字符串镜像），打卡后副标题立刻刷新。 */
  @StorageLink(AppStore.K_EARNED_XP) earnedXp: string = '0';
  @StorageLink(AppStore.K_READY_XP) readyXp: string = '0';
  @StorageLink(AppStore.K_STREAK_TEXT) streakText: string = '0';
  onOpenQuest: (quest: Quest) => void = () => {};
  onSelectTab: (index: number) => void = () => {};

  /** 组件可用宽度：平板 / 折叠屏展开时内容限宽居中。 */
  private contentWidth(): number {
    return this.viewport > Layout.contentMax ? Layout.contentMax : this.viewport;
  }

  /** 副标题：今天 6 个任务 · 可获 430 XP（有打卡时补一句已获）。 */
  private subLine(): string {
    const base: string = '今天 ' + QUEST_CATALOG.length.toString() + ' 个任务 · 可获 '
      + this.readyXp + ' XP';
    return this.earnedXp === '0' ? base : base + ' · 已获 ' + this.earnedXp;
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          // 「今日」是主页面：没有返回按钮，标题与连续打卡角标内联在这里
          Row() {
            Column() {
              Text(AppStore.greeting())
                .fontFamily(Font.sans)
                .fontSize(FontSize.title)
                .fontWeight(Weight.bold)
                .fontColor(Color.ink)
                .letterSpacing(0.2)
                .width('100%')
                .textAlign(TextAlign.Start)
              Text(this.subLine())
                .fontFamily(Font.sans)
                .fontSize(FontSize.caption)
                .fontColor(Color.muted)
                .margin({ top: Space.x6 })
                .width('100%')
                .textAlign(TextAlign.Start)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Text('×' + this.streakText)
              .fontFamily(Font.mono)
              .fontSize(FontSize.label)
              .fontWeight(Weight.bold)
              .fontColor(Color.accent2)
              .width(34)
              .height(34)
              .textAlign(TextAlign.Center)
              .backgroundColor('#1AFF6B3D')
              .borderRadius(Radius.full)
              .margin({ left: Space.x12 })
              .accessibilityText('已连续打卡 ' + this.streakText + ' 天')
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          // top 用安全区高度：让出状态栏与摄像头挖孔
          .padding({ left: Space.x22, right: Space.x22, top: this.insetTop, bottom: Space.x12 })

          LevelRibbon({
            cardWidth: this.contentWidth(),
            tick: AppStore.dataRev()
          })
          QuestGrid({
            viewport: this.viewport,
            onOpen: (q: Quest) => {
              this.onOpenQuest(q);
            }
          })
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
        active: TabIndex.Today,
        onSelect: (index: number) => {
          this.onSelectTab(index);
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.paper)
  }
}

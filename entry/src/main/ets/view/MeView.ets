import { promptAction } from '@kit.ArkUI';
import { QuestItem } from '../model/Quest';
import { AppStore } from '../store/AppStore';
import { LevelRibbon } from '../view/LevelRibbon';
import { TabBar, TabIndex } from '../view/TabBar';
import { Color, Font, FontSize, Layout, Radius, Space, Weight } from '../common/Theme';
import { grouped } from '../common/Format';

/** 待确认的操作。 */
const ACTION_CLEAR: string = 'clear';
const ACTION_SEED: string = 'seed';

/** 对话框按钮索引（取消在 0，确认在 1）。 */
const BTN_CONFIRM: number = 1;


/**
 * 我的。
 * 同样是设计稿里有入口、没有画面的页面，按同一套 token 补齐：
 * 身份区 + 等级丝带 + 本地数据概况 + 分类累计 + 数据管理。
 */
@Component
export struct MeView {
  @Prop viewport: number;
  /** 顶部安全区（状态栏 / 挖孔）高度。 */
  @Prop insetTop: number = 38;
  @StorageLink(AppStore.K_TODAY) todayKey: string = '';
  /**
   * 刷新计数。
   * 数值一律从 AppStore 现读（AppStore 内部直接读本地存储），
   * 点一下这个 @State 就能强制整页重算 ——
   * 不再依赖 AppStorage 的变更通知（实测在隐藏/重建场景下不可靠）。
   */
  @State private refreshTick: number = 0;
  onSelectTab: (index: number) => void = () => {};

  /**
   * 弹出确认框。
   * 这两个操作都会改动本地数据，所以先问一次，避免误触。
   * 取消（含返回键关闭）时 showDialog 的 Promise 会 reject，忽略即可。
   */
  private askConfirm(action: string): void {
    const isClear: boolean = action === ACTION_CLEAR;
    const options: promptAction.ShowDialogOptions = {
      title: isClear ? '清空全部本地数据？' : '恢复演示数据？',
      message: isClear
        ? '将删除全部打卡记录与经验值，等级回到 1 级。此操作无法撤销。'
        : '将把等级与统计还原为设计稿中的初始状态，当前打卡记录会被清除。',
      buttons: [
        { text: '取消', color: Color.muted },
        { text: isClear ? '清空' : '恢复', color: isClear ? '#D9483B' : Color.accent }
      ]
    };

    this.getUIContext().getPromptAction().showDialog(options)
      .then((result: promptAction.ShowDialogSuccessResponse) => {
        if (result.index !== BTN_CONFIRM) {
          return;
        }
        if (isClear) {
          AppStore.clearAll();
          // 不跳页：就地刷新（点一下 @State 触发整页重算）
          this.refreshTick = this.refreshTick + 1;
          this.toast('已清空全部本地数据');
        } else {
          AppStore.restoreSeed();
          this.refreshTick = this.refreshTick + 1;
          this.toast('已恢复演示数据');
        }
      })
      .catch(() => {
        // 用户取消或按返回键关闭对话框，什么都不做
      });
  }

  /** 轻提示。 */
  private toast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message, duration: 1800 });
    } catch (e) {
      // 提示失败不影响主流程
    }
  }

  @Builder
  identity() {
    Row({ space: Space.x12 }) {
      Stack() {
        Text('北')
          .fontFamily(Font.serif)
          .fontSize(FontSize.title)
          .fontWeight(Weight.black)
          .fontColor(Color.ink)
      }
      .width(52)
      .height(52)
      .backgroundColor(Color.accent)
      .borderRadius(Radius.full)

      Column() {
        Text('小北')
          .fontFamily(Font.sans)
          .fontSize(FontSize.title)
          .fontWeight(Weight.bold)
          .fontColor(Color.ink)
          .width('100%')
          .textAlign(TextAlign.Start)
        Text('已连续打卡 ' + this.streakValue() + ' 天')
          .fontFamily(Font.mono)
          .fontSize(FontSize.label)
          .fontColor(Color.muted)
          .margin({ top: Space.x4 })
          .width('100%')
          .textAlign(TextAlign.Start)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: Space.x22, right: Space.x22, top: Space.x14, bottom: Space.x4 })
  }

  @Builder
  tile(value: string, unit: string, key: string) {
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
      .margin({ bottom: Space.x6 })
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
  authoredRow(row: QuestItem, maxXp: number) {
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
          .width(Math.round(row.xp / maxXp * 100).toString() + '%')
          .height(7)
          .borderRadius(Radius.full)
          .backgroundColor(AppStore.colorOfLabel(row.label))
      }
      .layoutWeight(1)
      .height(7)
      Text(row.xp.toString())
        .fontFamily(Font.mono)
        .fontSize(FontSize.label)
        .fontWeight(Weight.semibold)
        .fontColor(Color.muted)
        .width(38)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .margin({ bottom: Space.x9 })
  }

  /** 连续打卡天数（现读本地存储）。 */
  private streakValue(): string {
    return AppStore.persistedStreak().toString();
  }

  /** 累计经验（现读本地存储）。 */
  private totalXpValue(): string {
    return grouped(AppStore.persistedXp());
  }

  /** 有打卡记录的天数。 */
  private loggedDaysValue(): string {
    return AppStore.loggedDates().length.toString();
  }

  private maxCategoryXp(): number {
    let m: number = 1;
    for (const c of this.categories()) {
      m = Math.max(m, c.xp);
    }
    return m;
  }

  /**
   * 分类累计数据。
   * 带上 refreshTick 作为参数，把它纳入调用链的依赖：
   * tick 一变，本方法重算、列表重建。
   */
  private categories(): QuestItem[] {
    const tick: number = this.refreshTick;
    const rows: QuestItem[] = AppStore.categoryTotals();
    return tick >= 0 ? rows : rows;
  }

  /**
   * 数据管理的一行。
   * 注意：@Builder 的返回值是 void，不能在外面链式挂 .onClick，
   * 所以点击回调必须作为参数传进来，在 builder 内部挂载。
   */
  @Builder
  actionRow(title: string, desc: string, accent: boolean, onTap: () => void) {
    Row() {
      Column() {
        Text(title)
          .fontFamily(Font.sans)
          .fontSize(FontSize.body)
          .fontWeight(Weight.semibold)
          .fontColor(accent ? Color.accent : Color.ink)
          .width('100%')
          .textAlign(TextAlign.Start)
        Text(desc)
          .fontFamily(Font.sans)
          .fontSize(FontSize.label)
          .fontColor(Color.muted)
          .margin({ top: Space.x2 + 1 })
          .width('100%')
          .textAlign(TextAlign.Start)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text('›')
        .fontFamily(Font.sans)
        .fontSize(FontSize.title)
        .fontColor(Color.muted)
    }
    .width('100%')
    .padding({ left: Space.x16, right: Space.x16, top: Space.x14, bottom: Space.x14 })
    .backgroundColor(Color.paper)
    .borderRadius(Radius.goal)
    .border({ width: 1, color: Color.line })
    .onClick(() => {
      onTap();
    })
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: Space.x0 }) {
          Text('我的')
            .fontFamily(Font.sans)
            .fontSize(FontSize.title)
            .fontWeight(Weight.bold)
            .fontColor(Color.ink)
            .letterSpacing(0.2)
            .width('100%')
            .textAlign(TextAlign.Start)
            .padding({ left: Space.x22, right: Space.x22, top: this.insetTop, bottom: Space.x8 })
          this.identity()
          LevelRibbon({
            cardWidth: this.viewport > Layout.contentMax ? Layout.contentMax : this.viewport,
            tick: this.refreshTick
          })

          // refreshTick 直接参与条件判断：确保这个 @State 一定在 build 的依赖里，
          // 点它一下整页必然重算（这是清空/恢复后能立刻看到新数值的关键）。
          if (this.refreshTick >= 0) {
            Row({ space: Space.x9 }) {
              this.tile(this.totalXpValue(), '', '累计经验')
              this.tile(this.loggedDaysValue(), '天', '记录天数')
              this.tile(this.streakValue(), '天', '连续打卡')
            }
            .width('100%')
            .padding({ left: Space.x14, right: Space.x14, top: Space.x4 })

            Column() {
              Text('分类累计')
                .fontFamily(Font.mono)
                .fontSize(FontSize.eyebrow)
                .fontWeight(Weight.bold)
                .fontColor(Color.muted)
                .letterSpacing(2)
                .margin({ bottom: Space.x11 })
                .width('100%')
                .textAlign(TextAlign.Start)
              ForEach(this.categories(), (row: QuestItem) => {
                this.authoredRow(row, this.maxCategoryXp())
              }, (row: QuestItem) => row.label)
            }
            .width('100%')
            .padding({ left: Space.x20, right: Space.x20, top: Space.x16, bottom: Space.x6 })
          }

          Column({ space: Space.x10 }) {
            Text('数据管理')
              .fontFamily(Font.mono)
              .fontSize(FontSize.eyebrow)
              .fontWeight(Weight.bold)
              .fontColor(Color.muted)
              .letterSpacing(2)
              .width('100%')
              .textAlign(TextAlign.Start)

            this.actionRow(
              '清空全部本地数据',
              '删除打卡记录与经验值，等级回到 1 级',
              true,
              () => {
                this.askConfirm(ACTION_CLEAR);
              }
            )

            this.actionRow(
              '恢复演示数据',
              '把数值还原为设计稿中的初始状态',
              false,
              () => {
                this.askConfirm(ACTION_SEED);
              }
            )
          }
          .width('100%')
          .padding({ left: Space.x14, right: Space.x14, top: Space.x6 })

          Text('进阶 Level · 1.0.0 · 数据仅存本机')
            .fontFamily(Font.mono)
            .fontSize(FontSize.micro)
            .fontColor(Color.muted)
            .letterSpacing(1)
            .margin({ top: Space.x22, bottom: Space.x22 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
      .edgeEffect(EdgeEffect.Spring)

      TabBar({
        active: TabIndex.Me,
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

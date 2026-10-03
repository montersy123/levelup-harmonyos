import { Quest } from '../model/Quest';
import { QUEST_CATALOG } from '../data/Data';
import { AppStore } from '../store/AppStore';
import { CoverView } from '../view/CoverView';
import { HomeView } from '../view/HomeView';
import { DetailView } from '../view/DetailView';
import { StatsView } from '../view/StatsView';
import { LibraryView } from '../view/LibraryView';
import { MeView } from '../view/MeView';
import { TabIndex } from '../view/TabBar';
import { KEY_VIEWPORT } from '../entryability/EntryAbility';
import { mediaquery, MediaQuery } from '@kit.ArkUI';
import { Color, Font, FontSize, Layout, Radius, Space, Weight } from '../common/Theme';

/** 当前路由：一个入口页 + 4 个标签页 + 1 个详情页 + 1 个新建弹层。 */
enum Route {
  Cover = 'cover',
  Today = 'today',
  Detail = 'detail',
  Stats = 'stats',
  Library = 'library',
  Me = 'me'
}

@Entry
@Component
struct Index {
  @StorageLink(AppStore.K_READY) @Watch('onReadyChange') ready: boolean = false;
  @StorageLink(AppStore.K_UNLOCKED) unlocked: boolean = false;
  /** 视口宽度（vp），由 EntryAbility 写入，并随窗口变化同步。 */
  @StorageLink(KEY_VIEWPORT) @Watch('onWindowWidthChange') windowWidth: number = 0;
  /** 今日已完成微任务数（订阅镜像，弹层文案随之变化）。 */
  @StorageLink(AppStore.K_DONE_STEPS) doneSteps: string = '';
  /**
   * 数据修订号。任何可见状态变化都会让它 +1，
   * 于是整个路由子树重建 —— 解决「隐藏路由组件收不到刷新」的问题。
   */
  @StorageLink(AppStore.K_REV) dataRev: number = 0;
  /** 状态栏 / 摄像头挖孔的安全区高度（vp），由 EntryAbility 测出并写入。 */
  @StorageLink(AppStore.K_INSET_TOP) insetTop: number = 38;
  @State private route: Route = Route.Cover;
  @State private routeDecided: boolean = false;
  @State private activeQuestId: string = '';
  @State private showNewSheet: boolean = false;
  /** 布局用视口宽度：EntryAbility 尚未写回时退回到设计稿画布宽度。 */
  private viewport: number = Layout.canvas;
  private mqListener: mediaquery.MediaQueryListener | undefined = undefined;

  aboutToAppear(): void {
    this.viewport = this.windowWidth > 0 ? this.windowWidth : Layout.canvas;
    this.decideRoute();
    this.watchWindowWidth();
  }

  aboutToDisappear(): void {
    if (this.mqListener !== undefined) {
      this.mqListener.off('change');
      this.mqListener = undefined;
    }
  }

  /**
   * 监听窗口宽度变化（旋转 / 折叠屏展开 / 分屏）。
   * 用 UIContext 的 MediaQuery（全局 matchMediaSync 自 API 18 起已废弃）。
   */
  private watchWindowWidth(): void {
    try {
      const mediaQuery: MediaQuery | undefined = this.getUIContext().getMediaQuery();
      if (mediaQuery === undefined) {
        return;
      }
      const listener: mediaquery.MediaQueryListener = mediaQuery.matchMediaSync('(width>0vp)');
      listener.on('change', (result: mediaquery.MediaQueryResult) => {
        const width: number = AppStore.parseVp(result.media);
        if (width > 0) {
          AppStorage.setOrCreate<number>(KEY_VIEWPORT, width);
        }
      });
      this.mqListener = listener;
    } catch (e) {
      // 监听不可用时保持 EntryAbility 写入的初始宽度，不影响使用。
      this.mqListener = undefined;
    }
  }

  private onWindowWidthChange(): void {
    this.viewport = this.windowWidth > 0 ? this.windowWidth : Layout.canvas;
  }

  /**
   * 本地数据是异步读回的：ready 从 false 翻到 true 时才真正决定首页。
   * 不做这一步的话，老用户每次冷启动都会被重置回封面。
   */
  private onReadyChange(): void {
    this.decideRoute();
  }

  private decideRoute(): void {
    if (this.routeDecided || !this.ready) {
      return;
    }
    this.routeDecided = true;
    this.route = this.unlocked ? Route.Today : Route.Cover;
  }

  /** 内容宽度：手机等比铺满，平板 / 折叠屏展开时居中限宽。 */
  private contentWidth(): number {
    const vp: number = this.viewport;
    return vp > Layout.contentMax ? Layout.contentMax : vp;
  }

  private cardWidth(): number {
    return Math.floor(this.contentWidth() - Space.x14 * 2);
  }

  /** 任务库里微任务的总数。 */
  private static stepTotal(): number {
    let n: number = 0;
    for (const q of QUEST_CATALOG) {
      n += q.steps.length;
    }
    return n;
  }

  private doneStepCount(): number {
    const done: string[] = this.doneSteps.split(',');
    let n: number = 0;
    for (const q of QUEST_CATALOG) {
      for (const s of q.steps) {
        if (done.includes(s.id)) {
          n += 1;
        }
      }
    }
    return n;
  }

  private doneCountText(): string {
    return this.doneStepCount().toString();
  }

  /** 今日微任务是否已全部完成。 */
  private allDoneToday(): boolean {
    return this.doneSteps !== '' && this.doneStepCount() === Index.stepTotal();
  }

  private goTab(index: number): void {
    if (index === TabIndex.Center) {
      this.showNewSheet = true;
      return;
    }
    const target: Route = index === TabIndex.Today
      ? Route.Today
      : (index === TabIndex.Library
        ? Route.Library
        : (index === TabIndex.Stats ? Route.Stats : Route.Me));
    if (this.route === target) {
      return;
    }
    this.getUIContext().animateTo({ duration: 200, curve: Curve.Friction }, () => {
      this.route = target;
    });
  }

  private openQuest(quest: Quest): void {
    this.activeQuestId = quest.id;
    this.getUIContext().animateTo({ duration: 200, curve: Curve.Friction }, () => {
      this.route = Route.Detail;
    });
  }

  /** 回到今日页（各页返回按钮共用）。 */
  private goHome(): void {
    if (this.route === Route.Today) {
      return;
    }
    this.getUIContext().animateTo({ duration: 200, curve: Curve.Friction }, () => {
      this.route = Route.Today;
    });
  }

  /**
   * 系统返回（手势 / 返回键）。
   * 顺序：先关弹层 → 详情页回今日 → 其它标签页回今日 → 今日页则退出到封面。
   * 返回 true 表示事件已消费。
   */
  onBackPress(): boolean {
    if (this.showNewSheet) {
      this.showNewSheet = false;
      return true;
    }
    if (this.route === Route.Today) {
      if (this.unlocked) {
        this.route = Route.Cover;
        return true;
      }
      return false;
    }
    this.goHome();
    return true;
  }

  /**
   * 「新建任务」底部弹层。
   *
   * 之前用「Blank() + justifyContent(End)」把面板推到底部，
   * 但 Blank 在 Column 里会吃掉全部剩余高度，
   * 结果点击区域和面板都不可靠（表现就是中间按钮按了没反应）。
   * 现在改成 Stack：遮罩铺满整屏、面板用 Column + justifyContent(End) 靠底，
   * 不再依赖 Blank 的伸缩行为。
   *
   * 文案会根据今日完成情况变化：全部完成时说清楚「已完成 N 项」，
   * 免得用户以为还有任务没做完、却在弹层里找不到新建入口。
   */
  @Builder
  newQuestSheet() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 点遮罩关闭
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#8C1A1714')
        .onClick(() => {
          this.showNewSheet = false;
        })

      // 底部面板
      Column() {
        Column({ space: Space.x12 }) {
          Row()
            .width(38)
            .height(4)
            .backgroundColor(Color.line)
            .borderRadius(Radius.full)

          Text('新建任务')
            .fontFamily(Font.sans)
            .fontSize(FontSize.title)
            .fontWeight(Weight.bold)
            .fontColor(Color.ink)

          Text('自定义任务功能还没有做。')
            .fontFamily(Font.sans)
            .fontSize(FontSize.body)
            .fontColor(Color.muted)

          // 状态行：让用户清楚现在到底完成了几项
          Row({ space: Space.x8 }) {
            Text(this.allDoneToday() ? '今日已全部完成' : '今日已完成')
              .fontFamily(Font.sans)
              .fontSize(FontSize.label)
              .fontColor(Color.muted)
            Text(this.doneCountText() + ' / ' + Index.stepTotal().toString())
              .fontFamily(Font.mono)
              .fontSize(FontSize.label)
              .fontWeight(Weight.bold)
              .fontColor(this.allDoneToday() ? Color.accent : Color.ink)
              .letterSpacing(1)
          }
          .margin({ top: Space.x2 })

          Text(this.allDoneToday()
            ? '任务库里的 ' + Index.stepTotal().toString() + ' 项已全部打卡完成。\n现在可以回「今日」查看等级与数据统计。'
            : '现在可以先用「今日」的 ' + Index.stepTotal().toString() + ' 项微任务打卡，\n全部记录都会保存在这台手机上。')
            .fontFamily(Font.sans)
            .fontSize(FontSize.bodySm)
            .lineHeight(23)
            .fontColor(Color.muted)
            .textAlign(TextAlign.Center)
            .margin({ top: Space.x4, bottom: Space.x8 })

          Button('知道了')
            .type(ButtonType.Capsule)
            .width('100%')
            .height(46)
            .backgroundColor(Color.ink)
            .fontColor(Color.onStage)
            .fontFamily(Font.sans)
            .fontSize(FontSize.body)
            .fontWeight(Weight.semibold)
            .onClick(() => {
              this.showNewSheet = false;
            })
        }
        .width('100%')
        .padding({ left: Space.x22, right: Space.x22, top: Space.x16, bottom: Space.x34 })
        .backgroundColor(Color.paper)
        .borderRadius({ topLeft: Radius.sheet, topRight: Radius.sheet })
      }
      .width('100%')
      // 面板本身也吃掉点击，避免点面板时穿透到遮罩
      .onClick(() => {
      })
    }
    .width('100%')
    .height('100%')
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        // 每个分支都以 dataRev 为条件之一。
        // 这样数据一变，整个路由子树会被**重建**（而不是指望隐藏组件收到通知），
        // 新挂载的页面必然读到最新数据 —— 这是「清空后不刷新」的根治办法。
        if (this.dataRev >= 0 && this.route === Route.Cover) {
          CoverView({
            viewport: this.viewport,
            insetTop: this.insetTop,
            onEnter: () => {
              AppStore.setUnlocked(true);
              this.route = Route.Today;
            }
          })
        } else if (this.dataRev >= 0 && this.route === Route.Today) {
          HomeView({
            viewport: this.viewport,
            insetTop: this.insetTop,
            onOpenQuest: (q: Quest) => {
              this.openQuest(q);
            },
            onSelectTab: (index: number) => {
              this.goTab(index);
            }
          })
        } else if (this.dataRev >= 0 && this.route === Route.Detail) {
          DetailView({
            questId: this.activeQuestId,
            viewport: this.viewport,
            insetTop: this.insetTop,
            onBack: () => {
              this.route = Route.Today;
            },
            onSelectTab: (index: number) => {
              this.goTab(index);
            }
          })
        } else if (this.dataRev >= 0 && this.route === Route.Stats) {
          StatsView({
            viewport: this.viewport,
            cardWidth: this.cardWidth(),
            insetTop: this.insetTop,
            onSelectTab: (index: number) => {
              this.goTab(index);
            }
          })
        } else if (this.dataRev >= 0 && this.route === Route.Library) {
          LibraryView({
            viewport: this.viewport,
            insetTop: this.insetTop,
            onOpenQuest: (q: Quest) => {
              this.openQuest(q);
            },
            onSelectTab: (index: number) => {
              this.goTab(index);
            }
          })
        } else {
          MeView({
            viewport: this.viewport,
            insetTop: this.insetTop,
            onSelectTab: (index: number) => {
              this.goTab(index);
            }
          })
        }
      }
      .width('100%')
      .height('100%')

      if (this.showNewSheet) {
        this.newQuestSheet()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.ink)
    .constraintSize({ maxWidth: Layout.contentMax })
  }
}

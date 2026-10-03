import { Quest, QuestStep } from '../model/Quest';
import { QUEST_CATALOG } from '../data/Data';
import { AppStore } from '../store/AppStore';
import { TabBar, TabIndex } from '../view/TabBar';
import { Color, Font, FontSize, Radius, Space, Weight } from '../common/Theme';

/**
 * 屏 3 · 任务详情（设计稿 .screen.detail）。
 * 渐变 Hero + 「今日微任务」步骤清单 + 开始任务 CTA。
 *
 * 勾选状态一律从 K_DONE_STEPS 这个字符串镜像读取，
 * 它一变组件就重绘 —— 保证点了立刻有反馈。
 */
@Component
export struct DetailView {
  @Prop questId: string;
  @Prop viewport: number;
  /** 顶部安全区（状态栏 / 挖孔）高度。 */
  @Prop insetTop: number = 38;
  @StorageLink(AppStore.K_TODAY) todayKey: string = '';
  /** 今日已完成步骤（逗号分隔）。勾选后立刻变，驱动本页重绘。 */
  @StorageLink(AppStore.K_DONE_STEPS) doneSteps: string = '';
  /** 今日已获 / 还可获得的 XP（字符串，供显示）。 */
  @StorageLink(AppStore.K_EARNED_XP) earnedXp: string = '0';
  @StorageLink(AppStore.K_READY_XP) readyXp: string = '0';
  onBack: () => void = () => {};
  onSelectTab: (index: number) => void = () => {};

  private quest(): Quest {
    for (const q of QUEST_CATALOG) {
      if (q.id === this.questId) {
        return q;
      }
    }
    return QUEST_CATALOG[0];
  }

  /** 该步骤是否已勾选 —— 只读镜像，因此必然是最新状态。 */
  private stepDone(stepId: string): boolean {
    return this.doneSteps.split(',').includes(stepId);
  }

  /** 本任务完成了几步。 */
  private questDoneCount(): number {
    let n: number = 0;
    for (const s of this.quest().steps) {
      if (this.stepDone(s.id)) {
        n += 1;
      }
    }
    return n;
  }

  private isQuestDone(): boolean {
    return this.questDoneCount() === this.quest().steps.length;
  }

  /** 本任务今天已获得的 XP。 */
  private questEarnedXp(): number {
    let xp: number = 0;
    for (const s of this.quest().steps) {
      if (this.stepDone(s.id)) {
        xp += s.xp;
      }
    }
    return xp;
  }

  private questOrdinal(): string {
    let index: number = 0;
    for (let i = 0; i < QUEST_CATALOG.length; i++) {
      if (QUEST_CATALOG[i].id === this.questId) {
        index = i;
      }
    }
    const no: string = (index + 1).toString().padStart(2, '0');
    const total: string = QUEST_CATALOG.length.toString().padStart(2, '0');
    return '任务 · ' + no + ' / ' + total;
  }

  @Builder
  hero() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column() {
        Row({ space: Space.x6 }) {
          Text(this.quest().badge)
            .fontFamily(Font.mono)
            .fontSize(FontSize.eyebrow)
            .fontColor(Color.ink)
            .letterSpacing(1)
        }
        .padding({ left: Space.x9, right: Space.x9, top: Space.x6, bottom: Space.x6 })
        .backgroundColor('#1A000000')
        .borderRadius(Radius.full)
        .alignSelf(ItemAlign.Start)

        Text(this.quest().heroTitle)
          .fontFamily(Font.serif)
          .fontSize(FontSize.heroTitle)
          .fontWeight(Weight.bold)
          .lineHeight(FontSize.heroTitle * 1.1)
          .fontColor(Color.ink)
          .margin({ top: Space.x14, bottom: Space.x8 })
          .width('100%')

        Text(this.quest().heroDesc)
          .fontFamily(Font.sans)
          .fontSize(FontSize.bodySm)
          .lineHeight(22)
          .fontColor('#C71A1714')
          .width('100%')
          .textAlign(TextAlign.Start)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      // 顶部 22 + 18：为右上角绝对定位的 XP 印章让出空间（设计稿 .hero .stamp）
      .padding({ left: Space.x20, right: Space.x20, top: Space.x22 + Space.x18, bottom: Space.x24 })

      Text('+' + this.quest().xp.toString() + ' XP')
        .fontFamily(Font.mono)
        .fontSize(FontSize.label)
        .fontWeight(Weight.bold)
        .fontColor(Color.ink)
        .letterSpacing(1)
        .padding({ left: Space.x10, right: Space.x10, top: Space.x7, bottom: Space.x7 })
        .backgroundColor('#C7FFFFFF')
        .borderRadius(Radius.full)
        .margin({ top: Space.x18, right: Space.x18 })
    }
    .width('100%')
    .margin({ left: Space.x14, right: Space.x14, top: Space.x8, bottom: Space.x16 })
    .borderRadius(Radius.hero)
    .linearGradient({
      angle: 160,
      colors: [[Color.heroStart, 0.0], [Color.heroEnd, 1.0]]
    })
    .clip(true)
  }

  /** 「今日微任务」小标题，右侧带本任务进度。 */
  @Builder
  stepsTitle() {
    Row() {
      Text('今日微任务')
        .fontFamily(Font.mono)
        .fontSize(FontSize.label)
        .fontWeight(Weight.bold)
        .fontColor(Color.muted)
        .letterSpacing(2)
      Blank()
      Text(this.questDoneCount().toString() + ' / ' + this.quest().steps.length.toString())
        .fontFamily(Font.mono)
        .fontSize(FontSize.label)
        .fontWeight(Weight.semibold)
        .fontColor(this.isQuestDone() ? Color.accent : Color.muted)
        .letterSpacing(1)
    }
    .width('100%')
    .margin({ top: Space.x10, bottom: Space.x6 })
  }

  @Builder
  stepRow(step: QuestStep) {
    Row({ space: Space.x11 }) {
      Stack() {
        if (this.stepDone(step.id)) {
          Image($r('app.media.ic_check'))
            .width(12)
            .height(12)
            .draggable(false)
        }
      }
      .width(22)
      .height(22)
      .borderRadius(Radius.full)
      .backgroundColor(this.stepDone(step.id) ? Color.accent : Color.paper)
      .border({
        width: 1.5,
        color: this.stepDone(step.id) ? Color.accent : Color.inkSoft
      })

      Text(step.name)
        .fontFamily(Font.sans)
        .fontSize(FontSize.body)
        .fontColor(this.stepDone(step.id) ? Color.muted : Color.ink)
        .decoration({
          type: this.stepDone(step.id) ? TextDecorationType.LineThrough : TextDecorationType.None,
          color: Color.muted
        })
        .layoutWeight(1)

      Text(this.stepDone(step.id) ? '已完成' : '+' + step.xp.toString() + ' XP')
        .fontFamily(Font.mono)
        .fontSize(FontSize.label)
        .fontColor(this.stepDone(step.id) ? Color.accent : Color.muted)
        .letterSpacing(1)
    }
    .width('100%')
    .padding({ top: Space.x13, bottom: Space.x13 })
    .border({ width: { top: 1 }, color: Color.line })
    .onClick(() => {
      AppStore.toggleStep(this.quest(), step.id);
    })
    .accessibilityText(step.name + '，' + (this.stepDone(step.id) ? '已完成' : '未完成'))
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          // 返回按钮与「任务 · 03 / 06」同一行（设计稿 .detail .topbar）。
          // 顶部只留少量空隙，让按钮落在状态栏正下方，不要顶到屏幕最上边。
          Row({ space: Space.x11 }) {
            Stack() {
              Image($r('app.media.ic_back'))
                .width(16)
                .height(16)
                .draggable(false)
            }
            .width(32)
            .height(32)
            .backgroundColor(Color.line)
            .borderRadius(Radius.full)
            .onClick(() => {
              this.onBack();
            })
            .accessibilityText('返回今日')

            Text(this.questOrdinal())
              .fontFamily(Font.sans)
              .fontSize(FontSize.bodySm)
              .fontColor(Color.muted)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          // 底部留白压到 0：让这一行紧贴下面的 Hero 卡片
          .padding({ left: Space.x22, right: Space.x22, top: this.insetTop, bottom: Space.x0 })

          this.hero()

          Column() {
            this.stepsTitle()
            ForEach(this.quest().steps, (step: QuestStep) => {
              this.stepRow(step)
            }, (step: QuestStep) => step.id)
          }
          .width('100%')
          .padding({ left: Space.x22, right: Space.x22, bottom: Space.x12 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
      .edgeEffect(EdgeEffect.Spring)

      Button(this.isQuestDone() ? '今日已完成 · 查看数据' : '一键完成这个任务')
        .type(ButtonType.Capsule)
        .width('100%')
        .height(48)
        .backgroundColor(Color.ink)
        .fontColor(Color.onStage)
        .fontFamily(Font.sans)
        .fontSize(FontSize.lede)
        .fontWeight(Weight.semibold)
        .margin({ left: Space.x18, right: Space.x18, top: Space.x8, bottom: Space.x12 })
        .onClick(() => {
          if (this.isQuestDone()) {
            this.onSelectTab(TabIndex.Stats);
          } else {
            AppStore.completeQuest(this.quest());
          }
        })

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

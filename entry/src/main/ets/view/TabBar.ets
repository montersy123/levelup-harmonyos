import { Color, Font, FontSize, Layout, Space, Weight } from '../common/Theme';

/** 底部标签栏的 5 个槽位（对应设计稿 .tabbar）。 */
export enum TabIndex {
  Today = 0,
  Library = 1,
  Center = 2,
  Stats = 3,
  Me = 4
}

interface TabDef {
  /** 未选中图标（灰）。 */
  icon: Resource;
  /** 选中图标（橙）。颜色已烘进 PNG —— 不能用 fillColor 着色，
   *  那样会把描边图形整体填满（鸿蒙 Image.fillColor 只作用于填充）。 */
  iconOn: Resource;
  label: string;
  center: boolean;
}

const TABS: TabDef[] = [
  {
    icon: $r('app.media.ic_today'), iconOn: $r('app.media.ic_today_on'),
    label: '今日', center: false
  },
  {
    icon: $r('app.media.ic_library'), iconOn: $r('app.media.ic_library_on'),
    label: '资料库', center: false
  },
  {
    icon: $r('app.media.ic_add'), iconOn: $r('app.media.ic_add_on'),
    label: '', center: true
  },
  {
    icon: $r('app.media.ic_stats'), iconOn: $r('app.media.ic_stats_on'),
    label: '数据', center: false
  },
  {
    icon: $r('app.media.ic_me'), iconOn: $r('app.media.ic_me_on'),
    label: '我的', center: false
  }
];

/**
 * 共用底部标签栏。
 * 设计稿里标签栏内嵌在 .screen 内（不是系统级 Tab），因此这里保持同一结构，
 * 由各页面在内容底部复用。
 */
@Component
export struct TabBar {
  @Prop active: number;
  onSelect: (index: number) => void = () => {};

  /**
   * 中间按钮固定用未选中那套（灰色描边「＋」）。
   * 设计稿里中间按钮是纯图标、不带状态色，它只是一个入口；
   * 其余槽位按选中状态切换灰 / 橙两套 PNG。
   */
  private iconRes(index: number, def: TabDef): Resource {
    if (index === TabIndex.Center) {
      return def.icon;
    }
    return this.active === index ? def.iconOn : def.icon;
  }

  private iconSize(index: number): number {
    return index === TabIndex.Center ? 26 : 21;
  }

  @Builder
  tabItem(index: number, def: TabDef) {
    Column({ space: Space.x6 - 1 }) {
      Image(this.iconRes(index, def))
        .width(this.iconSize(index))
        .height(this.iconSize(index))
        .draggable(false)
      if (!def.center) {
        Text(def.label)
          .fontFamily(Font.mono)
          .fontSize(FontSize.tab)
          .fontWeight(Weight.regular)
          .fontColor(this.active === index ? Color.accent : Color.muted)
      }
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.onSelect(index);
    })
    .accessibilityText(def.center ? '新建任务' : def.label)
  }

  build() {
    Row() {
      ForEach(TABS, (def: TabDef, index: number) => {
        this.tabItem(index, def);
      }, (def: TabDef) => def.label + (def.center ? '-c' : ''))
    }
    .width('100%')
    .height(Layout.tabBarHeight)
    .padding({ left: Space.x14, right: Space.x14, bottom: Space.x20 })
    .backgroundColor(Color.paper)
    .border({ width: { top: 1 }, color: { top: Color.line } })
  }
}

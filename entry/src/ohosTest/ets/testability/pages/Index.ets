/**
 * 测试模块的宿主页面。
 * 注意：ohosTest 与 main 是两个独立模块，不能 import 主模块的 .ets 源码，
 * 因此这里只做最小实现，真实用例请通过 Hypium 用例 + 主模块的入口进行。
 */
@Entry
@Component
struct Index {
  private readonly title: string = '进阶 Level';
  private readonly subtitle: string = '测试宿主页面 · 数据仅存本机';

  build() {
    Column({ space: 12 }) {
      Text(this.title)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1714')
      Text(this.subtitle)
        .fontSize(16)
        .fontColor('#6C6660')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
  }
}

import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window, display } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppStore } from '../store/AppStore';
const TAG: string = 'EntryAbility';
const DOMAIN: number = 0x0001;

/**
 * 视口宽度（vp）在 AppStorage 中的键。
 * 初始值由 EntryAbility 写入；旋转 / 折叠屏展开等变化由页面用
 * UIContext 的 MediaQuery 监听后更新（见 pages/Index.ets）。
 */
export const KEY_VIEWPORT: string = 'viewportW';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 先把本地数据读进 AppStorage，再加载页面，避免首屏闪一下空状态。
    AppStore.init(this.context).then(() => {
      hilog.info(DOMAIN, TAG, 'local store ready');
    }).catch((err: Error) => {
      hilog.error(DOMAIN, TAG, 'local store init failed: %{public}s', err.message);
    });
  }

  /** px → vp 换算，用于把窗口像素宽度转成布局宽度。 */
  private px2Vp(px: number): number {
    try {
      const density: number = display.getDefaultDisplaySync().densityPixels;
      return density > 0 ? px / density : px;
    } catch (e) {
      // 取不到屏幕信息时按 1:1 处理，布局仍可退回设计稿画布宽度。
      return px;
    }
  }

  /** 写入初始窗口宽度；异常时保持 0，页面会退回到设计稿画布宽度。 */
  private seedViewport(windowStage: window.WindowStage): void {
    try {
      const win: window.Window = windowStage.getMainWindowSync();
      const rect: window.Rect = win.getWindowProperties().windowRect;
      AppStorage.setOrCreate<number>(KEY_VIEWPORT, this.px2Vp(rect.width));
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'read window width failed: %{public}s', JSON.stringify(e));
    }
  }

  /**
   * 量出顶部要避让的高度（vp）：状态栏 / 摄像头挖孔。
   *
   * 因为调用了 setWindowLayoutFullScreen(true)，内容会铺到屏幕最顶端，
   * 所以每个页面的顶部必须自己让出这段空间，
   * 否则会被时间、电量、信号和挖孔挡住。
   * 取「系统状态栏」和「挖孔区域」两者的较大值。
   */
  private seedInsetTop(windowStage: window.WindowStage): void {
    let vp: number = 0;
    let win: window.Window | undefined = undefined;
    try {
      win = windowStage.getMainWindowSync();

      const sys: window.AvoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      if (sys !== undefined && sys.topRect !== undefined) {
        vp = Math.max(vp, this.px2Vp(sys.topRect.height));
      }

      const cut: window.AvoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT);
      if (cut !== undefined && cut.topRect !== undefined) {
        // 挖孔区域给的是它自身的矩形，用「上边 + 高度」当作需要避让的底部
        vp = Math.max(vp, this.px2Vp(cut.topRect.top + cut.topRect.height));
      }
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'read inset failed: %{public}s', JSON.stringify(e));
    }

    // 状态栏再矮也不会低于 24vp，避免内容真的贴到屏幕上沿
    AppStorage.setOrCreate<number>(AppStore.K_INSET_TOP, vp > 24 ? vp : 24);
    hilog.info(DOMAIN, TAG, 'inset top = %{public}s vp', (vp > 24 ? vp : 24).toString());
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'loadContent failed: %{public}s', JSON.stringify(err));
        return;
      }
      this.seedViewport(windowStage);
      // 沉浸式：内容延伸到系统状态栏 / 导航栏之下。
      try {
        const win: window.Window = windowStage.getMainWindowSync();
        win.setWindowLayoutFullScreen(true).catch((e: Error) => {
          hilog.warn(DOMAIN, TAG, 'full screen layout skipped: %{public}s', e.message);
        });
      } catch (e) {
        hilog.warn(DOMAIN, TAG, 'full screen layout unavailable: %{public}s', JSON.stringify(e));
      }
      // setWindowLayoutFullScreen 之后再量安全区，拿到的才准
      this.seedInsetTop(windowStage);
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'window stage destroyed');
  }

  onForeground(): void {
    // 跨天后（App 在后台过夜）刷新「今天」的日期键。
    AppStore.bind();
    AppStorage.setOrCreate<string>(AppStore.K_TODAY, AppStore.todayKey());
  }

  onBackground(): void {
  }

  onDestroy(): void {
  }
}

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'Prefs';
const DOMAIN: number = 0x0001;
const STORE_NAME: string = 'levelup_store';

/**
 * 本地存储封装 —— 全部数据只落在手机本地，不联网、不上传。
 * 基于 @ohos.data.preferences（轻量键值存储）。
 */
export class Prefs {
  private static store: preferences.Preferences | undefined = undefined;

  /** 在 EntryAbility.onCreate 中调用一次。 */
  static async init(context: common.UIAbilityContext): Promise<void> {
    if (Prefs.store !== undefined) {
      return;
    }
    const options: preferences.Options = { name: STORE_NAME };
    // getPreferences 可能因存储不可用而抛错，交给 AppStore.init 的 catch 处理。
    Prefs.store = await preferences.getPreferences(context, options);
    hilog.info(DOMAIN, TAG, 'preferences ready');
  }

  private static ready(): preferences.Preferences {
    const s: preferences.Preferences | undefined = Prefs.store;
    if (s === undefined) {
      throw new Error('Prefs 未初始化：请先在 EntryAbility.onCreate 中调用 Prefs.init(context)');
    }
    return s;
  }

  static getString(key: string, def: string): string {
    try {
      const v: preferences.ValueType = Prefs.ready().getSync(key, def);
      return typeof v === 'string' ? v : def;
    } catch (err) {
      // 首次安装或键不存在时回退默认值，不影响启动。
      return def;
    }
  }

  static getNumber(key: string, def: number): number {
    try {
      const v: preferences.ValueType = Prefs.ready().getSync(key, def);
      return typeof v === 'number' ? v : def;
    } catch (err) {
      return def;
    }
  }

  static getBool(key: string, def: boolean): boolean {
    try {
      const v: preferences.ValueType = Prefs.ready().getSync(key, def);
      return typeof v === 'boolean' ? v : def;
    } catch (err) {
      return def;
    }
  }

  /**
   * 写入一个键。
   * putSync 会在存储不可用或值类型非法时抛错；
   * 这里统一兜住，避免一次写失败带崩整个交互链路（内存里的状态仍然是对的）。
   */
  private static put(key: string, value: preferences.ValueType): void {
    try {
      Prefs.ready().putSync(key, value);
      Prefs.flush();
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'put %{public}s failed: %{public}s', key, JSON.stringify(err));
    }
  }

  static setString(key: string, value: string): void {
    Prefs.put(key, value);
  }

  static setNumber(key: string, value: number): void {
    Prefs.put(key, value);
  }

  static setBool(key: string, value: boolean): void {
    Prefs.put(key, value);
  }

  /** 异步落盘。失败只记录日志，不打断交互。 */
  static flush(): void {
    Prefs.ready().flush().catch((err: BusinessError) => {
      hilog.error(DOMAIN, TAG, 'flush failed: %{public}s', JSON.stringify(err));
    });
  }
}

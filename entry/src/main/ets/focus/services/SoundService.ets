import { media } from '@kit.MediaKit';
import { common } from '@kit.AbilityKit';
import { resourceManager } from '@kit.LocalizationKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { LOG_DOMAIN, LOG_TAG } from '../../common/constants/FocusConstants';

/**
 * 提示音服务（M3）。
 * 使用 AVPlayer 播放 rawfile/sounds 下的内置短音效；受设置页「提示音」开关控制。
 * 播放失败只记录日志，不影响提醒流程。
 */
export class SoundService {
  /** 当前播放器，播放完成后释放；null 表示无 */
  private static player: media.AVPlayer | null = null;

  /** 应用上下文（用于读取 rawfile） */
  private static context: common.UIAbilityContext | null = null;

  /**
   * 初始化（在 EntryAbility.onCreate 调用一次）。
   * @param context 应用上下文
   */
  static init(context: common.Context): void {
    SoundService.context = context as common.UIAbilityContext;
  }

  /**
   * 播放指定音效。
   * @param name rawfile/sounds 下的文件名（不含扩展名），如 ding / dong / chime
   */
  static play(name: string): void {
    SoundService.playInner(name).catch((err: Error): void => {
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'play sound failed: %{public}s', JSON.stringify(err));
    });
  }

  /** 实际播放逻辑 */
  private static async playInner(name: string): Promise<void> {
    const context: common.UIAbilityContext | null = SoundService.context;
    if (context === null) {
      return;
    }
    await SoundService.release();
    const player: media.AVPlayer = await media.createAVPlayer();
    SoundService.player = player;
    player.on('stateChange', (state: media.AVPlayerState): void => {
      if (state === 'initialized') {
        player.prepare();
      } else if (state === 'prepared') {
        player.play();
      } else if (state === 'completed') {
        if (SoundService.player === player) {
          SoundService.player = null;
        }
        player.release();
      }
    });
    player.on('error', (err: Error): void => {
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'player error: %{public}s', JSON.stringify(err));
      if (SoundService.player === player) {
        SoundService.player = null;
      }
      player.release();
    });
    const fd: resourceManager.RawFileDescriptor = await context.resourceManager.getRawFd(`sounds/${name}.wav`);
    player.fdSrc = { fd: fd.fd, offset: fd.offset, length: fd.length };
  }

  /** 释放当前播放器 */
  private static async release(): Promise<void> {
    const player: media.AVPlayer | null = SoundService.player;
    if (player === null) {
      return;
    }
    SoundService.player = null;
    try {
      await player.release();
    } catch (err) {
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'release player failed: %{public}s', JSON.stringify(err));
    }
  }
}
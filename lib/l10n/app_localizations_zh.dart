// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Nano Dash';

  @override
  String get dashboardEmpty => '未启用任何组件';

  @override
  String get dashboardEmptyHint => '在下方启用一个组件即可显示。';

  @override
  String get moduleVisibilityOff => '关闭';

  @override
  String get moduleVisibilityAssistant => '仅助手';

  @override
  String get moduleVisibilityCarousel => '轮播显示';

  @override
  String get moduleVisibilityTooltip =>
      '关闭：隐藏。仅助手：不参与左右滑动，但助手可主动显示。轮播显示：可滑动切换的常规页面。';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsDone => '完成';

  @override
  String get moduleClockTitle => '时钟';

  @override
  String get moduleTimerTitle => '计时器';

  @override
  String get moduleStopwatchTitle => '秒表';

  @override
  String get moduleLive2dTitle => 'Live2D';

  @override
  String get moduleSystemTitle => '系统监控';

  @override
  String get moduleWeatherTitle => '天气';

  @override
  String get moduleCalendarTitle => '日历';

  @override
  String get moduleMarketsTitle => '行情';

  @override
  String get moduleUsageMonitorTitle => '用量监控';

  @override
  String get moduleNowPlayingTitle => '正在播放';

  @override
  String get moduleVoiceTitle => '语音';

  @override
  String get moduleVideoTitle => '视频';

  @override
  String get moduleSettingsTitle => '设置';

  @override
  String get nowPlayingIdle => '暂无播放';

  @override
  String get videoIdle => '暂无视频';

  @override
  String get videoPickHint => '点按选择文件';

  @override
  String get videoError => '播放错误';

  @override
  String get videoPlaying => '正在面板播放';

  @override
  String get videoStopHint => '点按停止';

  @override
  String get videoPause => '暂停';

  @override
  String get videoResume => '继续';

  @override
  String get videoStop => '停止';

  @override
  String get videoRewind => '后退 10 秒';

  @override
  String get videoForward => '前进 10 秒';

  @override
  String get videoErrorFfmpeg => '未找到 FFmpeg — 请在设置中指定路径';

  @override
  String get videoErrorPanel => '未知面板尺寸';

  @override
  String get videoErrorDecode => '播放已停止';

  @override
  String get clear => '清除';

  @override
  String get settingsBackground => '背景';

  @override
  String get settingsBackgroundDefault => '默认';

  @override
  String get settingsBackgroundHint => '图片、GIF 或动态 WebP';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String get settingsThemeColor => '主题色';

  @override
  String get settingsThemeMode => '外观';

  @override
  String get settingsThemeModeSystem => '跟随系统';

  @override
  String get settingsThemeModeLight => '浅色';

  @override
  String get settingsThemeModeDark => '深色';

  @override
  String get settingsBrightness => '亮度';

  @override
  String get settingsAlertEffect => '提醒效果';

  @override
  String get settingsFfmpeg => 'FFmpeg';

  @override
  String get settingsFfmpegAuto => '自动检测';

  @override
  String get settingsFfmpegHint => '视频模块用它解码文件';

  @override
  String get settingsFfmpegNotFound => 'PATH 中未找到 — 点按选择';

  @override
  String get alertEffectNone => '关闭';

  @override
  String get alertEffectBump => '轻撞';

  @override
  String get alertEffectPulse => '脉动';

  @override
  String get alertEffectMediumBuzz => '中等振动';

  @override
  String get alertEffectBuzz => '振动';

  @override
  String get alertEffectStrongBuzz => '强振动';

  @override
  String get alertEffectAlert750 => '提醒 750 毫秒';

  @override
  String get alertEffectAlert1000 => '提醒 1000 毫秒';

  @override
  String get alertEffectPulsing => '脉冲';

  @override
  String get settingsReset => '恢复默认设置';

  @override
  String get settingsResetConfirmTitle => '恢复所有默认设置？';

  @override
  String get settingsResetConfirmBody => '这会将每一项设置恢复为默认值，并移除已选择的背景图片。';

  @override
  String get settingsAdvanced => '高级';

  @override
  String get settingsFirmwareUpdate => '固件更新';

  @override
  String get settingsFirmwareUpdateHint => '通过 USB 向面板刷入 .bin 固件';

  @override
  String get settingsFirmwareUpdateNotConnected => '请连接面板后再更新';

  @override
  String firmwareCurrentVersion(String version) {
    return '已安装：$version';
  }

  @override
  String get firmwareInvalidImage => '该文件不是有效的 ESP32 固件镜像。';

  @override
  String get firmwareConfirmTitle => '更新面板固件？';

  @override
  String get firmwareConfirmBody => '面板将重启进入新固件。更新完成前请保持连接。';

  @override
  String get firmwareUpdate => '更新';

  @override
  String get firmwareReceiving => '正在发送固件…';

  @override
  String get firmwareVerifying => '正在校验…';

  @override
  String get firmwareDone => '固件已更新，面板正在重启。';

  @override
  String firmwareFailed(int code) {
    return '更新失败（错误 $code）。';
  }

  @override
  String get cancel => '取消';

  @override
  String get systemCpu => '处理器';

  @override
  String get systemMemory => '内存';

  @override
  String get systemNetwork => '网络';

  @override
  String get systemTemperature => '温度';

  @override
  String get systemUnavailable => '无法获取系统信息';

  @override
  String get live2dChooseModel => '模型文件夹';

  @override
  String get live2dNoModel => '未选择模型';

  @override
  String get live2dClear => '清除';

  @override
  String get live2dPickHint => '请在设置中选择 Live2D 模型文件夹。';

  @override
  String get live2dNoModelJson => '该文件夹中未找到 .model3.json。';

  @override
  String get live2dLoadFailed => '无法加载模型。';

  @override
  String get live2dUnavailable => '此设备不支持 Live2D。';

  @override
  String get live2dZoom => '缩放';

  @override
  String get live2dVerticalOffset => '垂直偏移';

  @override
  String get voiceModelsDir => '模型文件夹';

  @override
  String get voiceNoModelsDir => '未选择文件夹';

  @override
  String get voiceWakeWord => '唤醒词';

  @override
  String get voiceWakeWordHint => '先听到唤醒词再开始识别。关闭后麦克风将持续识别。';

  @override
  String get voiceAec => '回声消除';

  @override
  String get voiceAecHint => '从麦克风中消除正在播放的回复，使其说话时也能被打断。';

  @override
  String get voiceLanguage => '识别语言';

  @override
  String get voiceLanguageAuto => '自动';

  @override
  String get voiceTtsBackend => '语音合成后端';

  @override
  String get voiceTtsNone => '无（仅文字）';

  @override
  String get voiceTtsApiKey => 'API 密钥';

  @override
  String get voiceTtsBaseUrl => '服务地址';

  @override
  String get voiceTtsResourceId => '资源 ID';

  @override
  String get voiceTtsSpeaker => '音色';

  @override
  String get voiceTtsModel => '模型';

  @override
  String get voiceTtsLanguage => '合成语言';

  @override
  String get voiceTtsInstructions => '音色指令';

  @override
  String get voiceTtsProxy => '代理';

  @override
  String get voiceSpeakerId => '说话人 ID';

  @override
  String get voiceSpeed => '语速';

  @override
  String get voiceRestartToApply => '关闭并重新打开麦克风以应用这些设置。';

  @override
  String get voiceSpeakerYou => '我';

  @override
  String get voiceSpeakerIdent => '声纹识别';

  @override
  String get voiceSpeakerIdentHint => '加载声纹模型，仅回应你录入的声音。';

  @override
  String get voiceVoiceprint => '声纹';

  @override
  String get voiceEnrollRecord => '录制';

  @override
  String get voiceEnrollStop => '停止';

  @override
  String get voiceEnrollForget => '清除';

  @override
  String get voiceEnrollStarting => '启动中……';

  @override
  String get voiceEnrollRecording => '录制中……请说话，然后点击停止。';

  @override
  String get voiceEnrollPrompt => '录制你的声纹，让助手认识你的声音。';

  @override
  String voiceEnrollCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已录入 $count 段声纹',
      zero: '尚未录制声纹',
    );
    return '$_temp0';
  }

  @override
  String voiceEnrollFailed(String reason) {
    return '录入失败：$reason';
  }

  @override
  String get moduleAgentTitle => '智能助手';

  @override
  String get agentEnable => '启用助手';

  @override
  String get agentEnableHint => '用 AI 模型回答麦克风听到的问题。';

  @override
  String get agentApiKey => 'API 密钥';

  @override
  String get agentBaseUrl => '接口地址';

  @override
  String get agentProxy => '代理';

  @override
  String get agentLightModel => '快速模型';

  @override
  String get agentLightModelHint => '先听到每个问题，简单的直接回答。';

  @override
  String get agentProModel => '增强模型';

  @override
  String get agentProModelHint => '接手复杂问题，可调用数据工具。';

  @override
  String get agentPersona => '角色设定';

  @override
  String get agentPersonaHint => '可选的助手角色描述。';

  @override
  String get agentNeedsApiKey => '填写 API 密钥后助手才能回答。';

  @override
  String get agentErrorLine => '抱歉，我这边出了点问题。';

  @override
  String agentReminderLine(String text) {
    return '提醒：$text';
  }

  @override
  String agentReminderMissedLine(String text) {
    return '你之前设的提醒已经过时了：$text';
  }

  @override
  String get reminderNotificationTitle => '提醒';

  @override
  String get reminderNotificationMissedTitle => '错过的提醒';

  @override
  String get agentSpeakerName => '助手';

  @override
  String get agentStop => '停止';

  @override
  String get timerHours => '小时';

  @override
  String get timerMinutes => '分钟';

  @override
  String get timerSeconds => '秒';

  @override
  String get timerDone => '完成';

  @override
  String get timerName => '名称';

  @override
  String get timerSound => '声音';

  @override
  String get timerVibrate => '振动';

  @override
  String get timerAdd => '添加计时器';

  @override
  String get timerDelete => '删除';

  @override
  String get timerNewName => '计时器';

  @override
  String get timerEmpty => '暂无计时器';

  @override
  String get timerDefaultCountdown => '倒计时';

  @override
  String get timerDefaultPomodoro => '番茄钟';

  @override
  String get timerDefaultFocus => '专注';

  @override
  String get timerDefaultShortBreak => '短休息';

  @override
  String get timerDefaultLongBreak => '长休息';

  @override
  String get timerPomodoro => '番茄钟';

  @override
  String get timerShortBreak => '短休息时长';

  @override
  String get timerLongBreak => '长休息时长';

  @override
  String get timerLongBreakEvery => '长休息间隔';

  @override
  String get timerStats => '统计';

  @override
  String get timerStatsEmpty => '暂无专注记录';

  @override
  String timerStatsSessions(int count) {
    return '$count 次';
  }

  @override
  String get timerNotificationFinished => '计时结束';

  @override
  String get timerNotificationFocusDone => '专注完成 — 该休息一下了';

  @override
  String get timerNotificationBreakDone => '休息结束 — 回到专注';

  @override
  String get moduleControlsTitle => '控制';

  @override
  String get moduleWidgetsTitle => '组件';

  @override
  String get controlsPower => '电源';

  @override
  String get controlsOn => '开';

  @override
  String get controlsOff => '关';

  @override
  String get clockUse24Hour => '24 小时制';

  @override
  String get clockShowSeconds => '显示秒';

  @override
  String get clockShowDate => '显示日期';

  @override
  String get clockShowWeather => '显示天气';

  @override
  String get weatherCity => '城市';

  @override
  String get weatherCityHint => '例如：上海';

  @override
  String get weatherUseMyLocation => '使用我的位置';

  @override
  String get weatherLocationFailed => '无法获取你的位置';

  @override
  String get weatherUnitsCelsius => '摄氏度 (°C)';

  @override
  String get weatherUnitsFahrenheit => '华氏度 (°F)';

  @override
  String get weatherError => '天气不可用';

  @override
  String weatherFetchFailed(Object city) {
    return '无法获取 \"$city\" 的天气';
  }

  @override
  String weatherFeelsLike(Object temp) {
    return '体感 $temp';
  }

  @override
  String get weatherAirQuality => '空气质量';

  @override
  String get weatherAqiGood => '优';

  @override
  String get weatherAqiFair => '良';

  @override
  String get weatherAqiModerate => '中等';

  @override
  String get weatherAqiPoor => '较差';

  @override
  String get weatherAqiVeryPoor => '差';

  @override
  String get weatherAqiExtremelyPoor => '极差';

  @override
  String get weatherConditionClearDay => '晴';

  @override
  String get weatherConditionClearNight => '晴夜';

  @override
  String get weatherConditionPartlyCloudy => '局部多云';

  @override
  String get weatherConditionCloudy => '多云';

  @override
  String get weatherConditionFog => '雾';

  @override
  String get weatherConditionDrizzle => '毛毛雨';

  @override
  String get weatherConditionRain => '雨';

  @override
  String get weatherConditionSnow => '雪';

  @override
  String get weatherConditionThunderstorm => '雷暴';

  @override
  String get weatherNow => '现在';

  @override
  String get weatherToday => '今天';

  @override
  String get weatherDaily => '7 天预报';

  @override
  String get marketsError => '行情数据不可用';

  @override
  String get marketsEmpty => '自选列表为空';

  @override
  String get marketsFetchFailed => '无法刷新行情数据';

  @override
  String get marketsWatchlist => '自选列表';

  @override
  String get marketsWatchlistHint => 'AAPL\n^GSPC\nBTC-USD';

  @override
  String get marketsWatchlistHelp =>
      '每行一个代码，使用 Yahoo Finance 格式：指数用 ^（^GSPC），加密货币用 -USD（BTC-USD），外汇用 =X（EURUSD=X）。';

  @override
  String get marketsProxyYahoo => 'Yahoo Finance 代理（可选）';

  @override
  String get marketsProxyHint => 'host:port 或 socks5://host:port';

  @override
  String get usageMonitorEmpty => '未启用任何服务';

  @override
  String get usageMonitorNoData => '暂无用量数据';

  @override
  String get usageMonitorNotSignedIn => '未登录';

  @override
  String get usageMonitorAuthExpired => '登录已过期';

  @override
  String get usageMonitorRateLimited => '请求频率受限';

  @override
  String get usageMonitorNetworkError => '网络错误';

  @override
  String get usageMonitorUpstreamError => '服务不可用';

  @override
  String get usageMonitorUnknownError => '不可用';

  @override
  String get usageMonitorResetsSoon => '即将重置';

  @override
  String usageMonitorResetsIn(String time) {
    return '$time后重置';
  }

  @override
  String get usageMonitorProxy => '代理（可选）';

  @override
  String get usageMonitorProxyHint => 'host:port 或 socks5://host:port';

  @override
  String get calendarEmpty => '暂无日程';

  @override
  String get calendarError => '日历不可用';

  @override
  String get calendarToday => '今天';

  @override
  String get calendarTomorrow => '明天';

  @override
  String get calendarAllDay => '全天';

  @override
  String get calendarNoFeeds => '尚未添加日历。';

  @override
  String get calendarAddFeed => '添加日历';

  @override
  String get calendarRemoveFeed => '移除';

  @override
  String get calendarFeedUrl => '日历地址';

  @override
  String get calendarFeedUrlHint => 'https://…/calendar.ics';

  @override
  String get calendarFeedOptions => '选项';

  @override
  String get calendarFeedLabel => '名称（可选）';

  @override
  String get calendarFeedUsername => '用户名';

  @override
  String get calendarFeedPassword => '密码';

  @override
  String get calendarFeedProxy => '代理（可选）';

  @override
  String get calendarFeedProxyHint => 'host:port 或 socks5://host:port';

  @override
  String get calendarRangeTitle => '显示';

  @override
  String get calendarRangeToday => '今天';

  @override
  String get calendarRangeTodayTomorrow => '今明两天';

  @override
  String get calendarRangeAll => '全部';

  @override
  String get picoViewOpenFailed => '无法打开 LCD 显示屏。';

  @override
  String get picoViewUnauthorized => '该显示屏不是正品设备（或固件版本过旧），无法使用。';

  @override
  String get retry => '重试';

  @override
  String get settings => '设置';

  @override
  String get trayShow => '显示 NanoDash';

  @override
  String get trayHide => '隐藏到托盘';

  @override
  String get trayQuit => '退出';

  @override
  String get trayTooltip => 'NanoDash';
}

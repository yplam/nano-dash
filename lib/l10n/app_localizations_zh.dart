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
  String get moduleSettingsTitle => '设置';

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

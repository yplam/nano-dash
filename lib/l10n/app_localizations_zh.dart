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
  String get picoViewOpenFailed => '无法打开 LCD 显示屏。';

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

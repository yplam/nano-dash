// This is a generated file - do not edit.
//
// Generated from pv_wire.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'pv_wire.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'pv_wire.pbenum.dart';

enum HostToDevice_Msg {
  hello,
  config,
  otaBegin,
  otaData,
  otaEnd,
  otaAbort,
  enterRecovery,
  authChallenge,
  getDeviceInfo,
  setParam,
  i2cRequest,
  notSet
}

/// One CTRL frame on the OUT (host -> device) endpoint.
class HostToDevice extends $pb.GeneratedMessage {
  factory HostToDevice({
    Hello? hello,
    Config? config,
    OtaBegin? otaBegin,
    OtaData? otaData,
    OtaEnd? otaEnd,
    OtaAbort? otaAbort,
    EnterRecovery? enterRecovery,
    AuthChallenge? authChallenge,
    GetDeviceInfo? getDeviceInfo,
    SetParam? setParam,
    I2cRequest? i2cRequest,
  }) {
    final result = create();
    if (hello != null) result.hello = hello;
    if (config != null) result.config = config;
    if (otaBegin != null) result.otaBegin = otaBegin;
    if (otaData != null) result.otaData = otaData;
    if (otaEnd != null) result.otaEnd = otaEnd;
    if (otaAbort != null) result.otaAbort = otaAbort;
    if (enterRecovery != null) result.enterRecovery = enterRecovery;
    if (authChallenge != null) result.authChallenge = authChallenge;
    if (getDeviceInfo != null) result.getDeviceInfo = getDeviceInfo;
    if (setParam != null) result.setParam = setParam;
    if (i2cRequest != null) result.i2cRequest = i2cRequest;
    return result;
  }

  HostToDevice._();

  factory HostToDevice.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HostToDevice.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, HostToDevice_Msg> _HostToDevice_MsgByTag = {
    1: HostToDevice_Msg.hello,
    2: HostToDevice_Msg.config,
    3: HostToDevice_Msg.otaBegin,
    4: HostToDevice_Msg.otaData,
    5: HostToDevice_Msg.otaEnd,
    6: HostToDevice_Msg.otaAbort,
    7: HostToDevice_Msg.enterRecovery,
    8: HostToDevice_Msg.authChallenge,
    16: HostToDevice_Msg.getDeviceInfo,
    17: HostToDevice_Msg.setParam,
    18: HostToDevice_Msg.i2cRequest,
    0: HostToDevice_Msg.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HostToDevice',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.wire'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 7, 8, 16, 17, 18])
    ..aOM<Hello>(1, _omitFieldNames ? '' : 'hello', subBuilder: Hello.create)
    ..aOM<Config>(2, _omitFieldNames ? '' : 'config', subBuilder: Config.create)
    ..aOM<OtaBegin>(3, _omitFieldNames ? '' : 'otaBegin',
        subBuilder: OtaBegin.create)
    ..aOM<OtaData>(4, _omitFieldNames ? '' : 'otaData',
        subBuilder: OtaData.create)
    ..aOM<OtaEnd>(5, _omitFieldNames ? '' : 'otaEnd', subBuilder: OtaEnd.create)
    ..aOM<OtaAbort>(6, _omitFieldNames ? '' : 'otaAbort',
        subBuilder: OtaAbort.create)
    ..aOM<EnterRecovery>(7, _omitFieldNames ? '' : 'enterRecovery',
        subBuilder: EnterRecovery.create)
    ..aOM<AuthChallenge>(8, _omitFieldNames ? '' : 'authChallenge',
        subBuilder: AuthChallenge.create)
    ..aOM<GetDeviceInfo>(16, _omitFieldNames ? '' : 'getDeviceInfo',
        subBuilder: GetDeviceInfo.create)
    ..aOM<SetParam>(17, _omitFieldNames ? '' : 'setParam',
        subBuilder: SetParam.create)
    ..aOM<I2cRequest>(18, _omitFieldNames ? '' : 'i2cRequest',
        subBuilder: I2cRequest.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HostToDevice clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HostToDevice copyWith(void Function(HostToDevice) updates) =>
      super.copyWith((message) => updates(message as HostToDevice))
          as HostToDevice;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HostToDevice create() => HostToDevice._();
  @$core.override
  HostToDevice createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HostToDevice getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HostToDevice>(create);
  static HostToDevice? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  @$pb.TagNumber(18)
  HostToDevice_Msg whichMsg() => _HostToDevice_MsgByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  @$pb.TagNumber(18)
  void clearMsg() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  Hello get hello => $_getN(0);
  @$pb.TagNumber(1)
  set hello(Hello value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHello() => $_has(0);
  @$pb.TagNumber(1)
  void clearHello() => $_clearField(1);
  @$pb.TagNumber(1)
  Hello ensureHello() => $_ensure(0);

  @$pb.TagNumber(2)
  Config get config => $_getN(1);
  @$pb.TagNumber(2)
  set config(Config value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasConfig() => $_has(1);
  @$pb.TagNumber(2)
  void clearConfig() => $_clearField(2);
  @$pb.TagNumber(2)
  Config ensureConfig() => $_ensure(1);

  @$pb.TagNumber(3)
  OtaBegin get otaBegin => $_getN(2);
  @$pb.TagNumber(3)
  set otaBegin(OtaBegin value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasOtaBegin() => $_has(2);
  @$pb.TagNumber(3)
  void clearOtaBegin() => $_clearField(3);
  @$pb.TagNumber(3)
  OtaBegin ensureOtaBegin() => $_ensure(2);

  @$pb.TagNumber(4)
  OtaData get otaData => $_getN(3);
  @$pb.TagNumber(4)
  set otaData(OtaData value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasOtaData() => $_has(3);
  @$pb.TagNumber(4)
  void clearOtaData() => $_clearField(4);
  @$pb.TagNumber(4)
  OtaData ensureOtaData() => $_ensure(3);

  @$pb.TagNumber(5)
  OtaEnd get otaEnd => $_getN(4);
  @$pb.TagNumber(5)
  set otaEnd(OtaEnd value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasOtaEnd() => $_has(4);
  @$pb.TagNumber(5)
  void clearOtaEnd() => $_clearField(5);
  @$pb.TagNumber(5)
  OtaEnd ensureOtaEnd() => $_ensure(4);

  @$pb.TagNumber(6)
  OtaAbort get otaAbort => $_getN(5);
  @$pb.TagNumber(6)
  set otaAbort(OtaAbort value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasOtaAbort() => $_has(5);
  @$pb.TagNumber(6)
  void clearOtaAbort() => $_clearField(6);
  @$pb.TagNumber(6)
  OtaAbort ensureOtaAbort() => $_ensure(5);

  @$pb.TagNumber(7)
  EnterRecovery get enterRecovery => $_getN(6);
  @$pb.TagNumber(7)
  set enterRecovery(EnterRecovery value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasEnterRecovery() => $_has(6);
  @$pb.TagNumber(7)
  void clearEnterRecovery() => $_clearField(7);
  @$pb.TagNumber(7)
  EnterRecovery ensureEnterRecovery() => $_ensure(6);

  @$pb.TagNumber(8)
  AuthChallenge get authChallenge => $_getN(7);
  @$pb.TagNumber(8)
  set authChallenge(AuthChallenge value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasAuthChallenge() => $_has(7);
  @$pb.TagNumber(8)
  void clearAuthChallenge() => $_clearField(8);
  @$pb.TagNumber(8)
  AuthChallenge ensureAuthChallenge() => $_ensure(7);

  /// Phase 2.
  @$pb.TagNumber(16)
  GetDeviceInfo get getDeviceInfo => $_getN(8);
  @$pb.TagNumber(16)
  set getDeviceInfo(GetDeviceInfo value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasGetDeviceInfo() => $_has(8);
  @$pb.TagNumber(16)
  void clearGetDeviceInfo() => $_clearField(16);
  @$pb.TagNumber(16)
  GetDeviceInfo ensureGetDeviceInfo() => $_ensure(8);

  @$pb.TagNumber(17)
  SetParam get setParam => $_getN(9);
  @$pb.TagNumber(17)
  set setParam(SetParam value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasSetParam() => $_has(9);
  @$pb.TagNumber(17)
  void clearSetParam() => $_clearField(17);
  @$pb.TagNumber(17)
  SetParam ensureSetParam() => $_ensure(9);

  @$pb.TagNumber(18)
  I2cRequest get i2cRequest => $_getN(10);
  @$pb.TagNumber(18)
  set i2cRequest(I2cRequest value) => $_setField(18, value);
  @$pb.TagNumber(18)
  $core.bool hasI2cRequest() => $_has(10);
  @$pb.TagNumber(18)
  void clearI2cRequest() => $_clearField(18);
  @$pb.TagNumber(18)
  I2cRequest ensureI2cRequest() => $_ensure(10);
}

enum DeviceToHost_Msg {
  helloAck,
  touch,
  otaStatus,
  authResponse,
  configAck,
  deviceInfo,
  paramAck,
  i2cResponse,
  notSet
}

/// One CTRL frame on the IN (device -> host) endpoint.
class DeviceToHost extends $pb.GeneratedMessage {
  factory DeviceToHost({
    HelloAck? helloAck,
    Touch? touch,
    OtaStatus? otaStatus,
    AuthResponse? authResponse,
    ConfigAck? configAck,
    DeviceInfo? deviceInfo,
    ParamAck? paramAck,
    I2cResponse? i2cResponse,
  }) {
    final result = create();
    if (helloAck != null) result.helloAck = helloAck;
    if (touch != null) result.touch = touch;
    if (otaStatus != null) result.otaStatus = otaStatus;
    if (authResponse != null) result.authResponse = authResponse;
    if (configAck != null) result.configAck = configAck;
    if (deviceInfo != null) result.deviceInfo = deviceInfo;
    if (paramAck != null) result.paramAck = paramAck;
    if (i2cResponse != null) result.i2cResponse = i2cResponse;
    return result;
  }

  DeviceToHost._();

  factory DeviceToHost.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeviceToHost.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, DeviceToHost_Msg> _DeviceToHost_MsgByTag = {
    1: DeviceToHost_Msg.helloAck,
    2: DeviceToHost_Msg.touch,
    3: DeviceToHost_Msg.otaStatus,
    4: DeviceToHost_Msg.authResponse,
    5: DeviceToHost_Msg.configAck,
    16: DeviceToHost_Msg.deviceInfo,
    17: DeviceToHost_Msg.paramAck,
    18: DeviceToHost_Msg.i2cResponse,
    0: DeviceToHost_Msg.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeviceToHost',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.wire'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 16, 17, 18])
    ..aOM<HelloAck>(1, _omitFieldNames ? '' : 'helloAck',
        subBuilder: HelloAck.create)
    ..aOM<Touch>(2, _omitFieldNames ? '' : 'touch', subBuilder: Touch.create)
    ..aOM<OtaStatus>(3, _omitFieldNames ? '' : 'otaStatus',
        subBuilder: OtaStatus.create)
    ..aOM<AuthResponse>(4, _omitFieldNames ? '' : 'authResponse',
        subBuilder: AuthResponse.create)
    ..aOM<ConfigAck>(5, _omitFieldNames ? '' : 'configAck',
        subBuilder: ConfigAck.create)
    ..aOM<DeviceInfo>(16, _omitFieldNames ? '' : 'deviceInfo',
        subBuilder: DeviceInfo.create)
    ..aOM<ParamAck>(17, _omitFieldNames ? '' : 'paramAck',
        subBuilder: ParamAck.create)
    ..aOM<I2cResponse>(18, _omitFieldNames ? '' : 'i2cResponse',
        subBuilder: I2cResponse.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceToHost clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceToHost copyWith(void Function(DeviceToHost) updates) =>
      super.copyWith((message) => updates(message as DeviceToHost))
          as DeviceToHost;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeviceToHost create() => DeviceToHost._();
  @$core.override
  DeviceToHost createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeviceToHost getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeviceToHost>(create);
  static DeviceToHost? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  @$pb.TagNumber(18)
  DeviceToHost_Msg whichMsg() => _DeviceToHost_MsgByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  @$pb.TagNumber(18)
  void clearMsg() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  HelloAck get helloAck => $_getN(0);
  @$pb.TagNumber(1)
  set helloAck(HelloAck value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHelloAck() => $_has(0);
  @$pb.TagNumber(1)
  void clearHelloAck() => $_clearField(1);
  @$pb.TagNumber(1)
  HelloAck ensureHelloAck() => $_ensure(0);

  @$pb.TagNumber(2)
  Touch get touch => $_getN(1);
  @$pb.TagNumber(2)
  set touch(Touch value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTouch() => $_has(1);
  @$pb.TagNumber(2)
  void clearTouch() => $_clearField(2);
  @$pb.TagNumber(2)
  Touch ensureTouch() => $_ensure(1);

  @$pb.TagNumber(3)
  OtaStatus get otaStatus => $_getN(2);
  @$pb.TagNumber(3)
  set otaStatus(OtaStatus value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasOtaStatus() => $_has(2);
  @$pb.TagNumber(3)
  void clearOtaStatus() => $_clearField(3);
  @$pb.TagNumber(3)
  OtaStatus ensureOtaStatus() => $_ensure(2);

  @$pb.TagNumber(4)
  AuthResponse get authResponse => $_getN(3);
  @$pb.TagNumber(4)
  set authResponse(AuthResponse value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasAuthResponse() => $_has(3);
  @$pb.TagNumber(4)
  void clearAuthResponse() => $_clearField(4);
  @$pb.TagNumber(4)
  AuthResponse ensureAuthResponse() => $_ensure(3);

  /// v2: CONFIG is acknowledged (v1 fired it blind).
  @$pb.TagNumber(5)
  ConfigAck get configAck => $_getN(4);
  @$pb.TagNumber(5)
  set configAck(ConfigAck value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasConfigAck() => $_has(4);
  @$pb.TagNumber(5)
  void clearConfigAck() => $_clearField(5);
  @$pb.TagNumber(5)
  ConfigAck ensureConfigAck() => $_ensure(4);

  /// Phase 2.
  @$pb.TagNumber(16)
  DeviceInfo get deviceInfo => $_getN(5);
  @$pb.TagNumber(16)
  set deviceInfo(DeviceInfo value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasDeviceInfo() => $_has(5);
  @$pb.TagNumber(16)
  void clearDeviceInfo() => $_clearField(16);
  @$pb.TagNumber(16)
  DeviceInfo ensureDeviceInfo() => $_ensure(5);

  @$pb.TagNumber(17)
  ParamAck get paramAck => $_getN(6);
  @$pb.TagNumber(17)
  set paramAck(ParamAck value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasParamAck() => $_has(6);
  @$pb.TagNumber(17)
  void clearParamAck() => $_clearField(17);
  @$pb.TagNumber(17)
  ParamAck ensureParamAck() => $_ensure(6);

  @$pb.TagNumber(18)
  I2cResponse get i2cResponse => $_getN(7);
  @$pb.TagNumber(18)
  set i2cResponse(I2cResponse value) => $_setField(18, value);
  @$pb.TagNumber(18)
  $core.bool hasI2cResponse() => $_has(7);
  @$pb.TagNumber(18)
  void clearI2cResponse() => $_clearField(18);
  @$pb.TagNumber(18)
  I2cResponse ensureI2cResponse() => $_ensure(7);
}

class Hello extends $pb.GeneratedMessage {
  factory Hello({
    $core.int? protoVersion,
  }) {
    final result = create();
    if (protoVersion != null) result.protoVersion = protoVersion;
    return result;
  }

  Hello._();

  factory Hello.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Hello.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Hello',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.wire'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'protoVersion',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Hello clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Hello copyWith(void Function(Hello) updates) =>
      super.copyWith((message) => updates(message as Hello)) as Hello;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Hello create() => Hello._();
  @$core.override
  Hello createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Hello getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Hello>(create);
  static Hello? _defaultInstance;

  /// PV_PROTO_VERSION of the host (2 for this schema).
  @$pb.TagNumber(1)
  $core.int get protoVersion => $_getIZ(0);
  @$pb.TagNumber(1)
  set protoVersion($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProtoVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearProtoVersion() => $_clearField(1);
}

/// Replaces the v1 packed caps bitfield (CAP_AUTH = 1<<3) with named flags.
class Capabilities extends $pb.GeneratedMessage {
  factory Capabilities({
    $core.bool? auth,
    $core.bool? setParam,
    $core.bool? i2c,
    $core.bool? audio,
  }) {
    final result = create();
    if (auth != null) result.auth = auth;
    if (setParam != null) result.setParam = setParam;
    if (i2c != null) result.i2c = i2c;
    if (audio != null) result.audio = audio;
    return result;
  }

  Capabilities._();

  factory Capabilities.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Capabilities.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Capabilities',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.wire'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'auth')
    ..aOB(2, _omitFieldNames ? '' : 'setParam')
    ..aOB(3, _omitFieldNames ? '' : 'i2c')
    ..aOB(4, _omitFieldNames ? '' : 'audio')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Capabilities clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Capabilities copyWith(void Function(Capabilities) updates) =>
      super.copyWith((message) => updates(message as Capabilities))
          as Capabilities;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Capabilities create() => Capabilities._();
  @$core.override
  Capabilities createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Capabilities getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Capabilities>(create);
  static Capabilities? _defaultInstance;

  /// Device is provisioned and answers AuthChallenge.
  @$pb.TagNumber(1)
  $core.bool get auth => $_getBF(0);
  @$pb.TagNumber(1)
  set auth($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAuth() => $_has(0);
  @$pb.TagNumber(1)
  void clearAuth() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get setParam => $_getBF(1);
  @$pb.TagNumber(2)
  set setParam($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSetParam() => $_has(1);
  @$pb.TagNumber(2)
  void clearSetParam() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get i2c => $_getBF(2);
  @$pb.TagNumber(3)
  set i2c($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasI2c() => $_has(2);
  @$pb.TagNumber(3)
  void clearI2c() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get audio => $_getBF(3);
  @$pb.TagNumber(4)
  set audio($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAudio() => $_has(3);
  @$pb.TagNumber(4)
  void clearAudio() => $_clearField(4);
}

class HelloAck extends $pb.GeneratedMessage {
  factory HelloAck({
    $core.int? protoVersion,
    Capabilities? caps,
    $core.String? fwVersion,
  }) {
    final result = create();
    if (protoVersion != null) result.protoVersion = protoVersion;
    if (caps != null) result.caps = caps;
    if (fwVersion != null) result.fwVersion = fwVersion;
    return result;
  }

  HelloAck._();

  factory HelloAck.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HelloAck.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HelloAck',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.wire'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'protoVersion',
        fieldType: $pb.PbFieldType.OU3)
    ..aOM<Capabilities>(2, _omitFieldNames ? '' : 'caps',
        subBuilder: Capabilities.create)
    ..aOS(3, _omitFieldNames ? '' : 'fwVersion')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HelloAck clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HelloAck copyWith(void Function(HelloAck) updates) =>
      super.copyWith((message) => updates(message as HelloAck)) as HelloAck;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HelloAck create() => HelloAck._();
  @$core.override
  HelloAck createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HelloAck getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HelloAck>(create);
  static HelloAck? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get protoVersion => $_getIZ(0);
  @$pb.TagNumber(1)
  set protoVersion($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProtoVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearProtoVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  Capabilities get caps => $_getN(1);
  @$pb.TagNumber(2)
  set caps(Capabilities value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasCaps() => $_has(1);
  @$pb.TagNumber(2)
  void clearCaps() => $_clearField(2);
  @$pb.TagNumber(2)
  Capabilities ensureCaps() => $_ensure(1);

  /// ESP-IDF app version string, e.g. "1.4.0".
  @$pb.TagNumber(3)
  $core.String get fwVersion => $_getSZ(2);
  @$pb.TagNumber(3)
  set fwVersion($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFwVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearFwVersion() => $_clearField(3);
}

/// Resolved from the host's panel preset registry (crates/pico-view panels.rs);
/// the device (re)initialises panel + touch controller from this.
class Config extends $pb.GeneratedMessage {
  factory Config({
    PanelModel? model,
    $core.int? width,
    $core.int? height,
    $core.int? xOffset,
    $core.int? yOffset,
    $core.int? rotationDeg,
    $core.bool? invert,
    $core.int? touchAddr,
    $core.bool? touchSwapXy,
    $core.bool? touchFlipX,
    $core.bool? touchFlipY,
  }) {
    final result = create();
    if (model != null) result.model = model;
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    if (xOffset != null) result.xOffset = xOffset;
    if (yOffset != null) result.yOffset = yOffset;
    if (rotationDeg != null) result.rotationDeg = rotationDeg;
    if (invert != null) result.invert = invert;
    if (touchAddr != null) result.touchAddr = touchAddr;
    if (touchSwapXy != null) result.touchSwapXy = touchSwapXy;
    if (touchFlipX != null) result.touchFlipX = touchFlipX;
    if (touchFlipY != null) result.touchFlipY = touchFlipY;
    return result;
  }

  Config._();

  factory Config.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Config.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Config',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.wire'),
      createEmptyInstance: create)
    ..aE<PanelModel>(1, _omitFieldNames ? '' : 'model',
        enumValues: PanelModel.values)
    ..aI(2, _omitFieldNames ? '' : 'width', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'height', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'xOffset', fieldType: $pb.PbFieldType.OU3)
    ..aI(5, _omitFieldNames ? '' : 'yOffset', fieldType: $pb.PbFieldType.OU3)
    ..aI(6, _omitFieldNames ? '' : 'rotationDeg',
        fieldType: $pb.PbFieldType.OU3)
    ..aOB(7, _omitFieldNames ? '' : 'invert')
    ..aI(8, _omitFieldNames ? '' : 'touchAddr', fieldType: $pb.PbFieldType.OU3)
    ..aOB(9, _omitFieldNames ? '' : 'touchSwapXy')
    ..aOB(10, _omitFieldNames ? '' : 'touchFlipX')
    ..aOB(11, _omitFieldNames ? '' : 'touchFlipY')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Config copyWith(void Function(Config) updates) =>
      super.copyWith((message) => updates(message as Config)) as Config;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Config create() => Config._();
  @$core.override
  Config createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Config getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Config>(create);
  static Config? _defaultInstance;

  @$pb.TagNumber(1)
  PanelModel get model => $_getN(0);
  @$pb.TagNumber(1)
  set model(PanelModel value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasModel() => $_has(0);
  @$pb.TagNumber(1)
  void clearModel() => $_clearField(1);

  /// Visible size in pixels, in the panel's wired orientation.
  @$pb.TagNumber(2)
  $core.int get width => $_getIZ(1);
  @$pb.TagNumber(2)
  set width($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasWidth() => $_has(1);
  @$pb.TagNumber(2)
  void clearWidth() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get height => $_getIZ(2);
  @$pb.TagNumber(3)
  set height($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHeight() => $_has(2);
  @$pb.TagNumber(3)
  void clearHeight() => $_clearField(3);

  /// Glass insets into controller RAM.
  @$pb.TagNumber(4)
  $core.int get xOffset => $_getIZ(3);
  @$pb.TagNumber(4)
  set xOffset($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasXOffset() => $_has(3);
  @$pb.TagNumber(4)
  void clearXOffset() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get yOffset => $_getIZ(4);
  @$pb.TagNumber(5)
  set yOffset($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasYOffset() => $_has(4);
  @$pb.TagNumber(5)
  void clearYOffset() => $_clearField(5);

  /// 0 / 90 / 180 / 270; drives MADCTL.
  @$pb.TagNumber(6)
  $core.int get rotationDeg => $_getIZ(5);
  @$pb.TagNumber(6)
  set rotationDeg($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasRotationDeg() => $_has(5);
  @$pb.TagNumber(6)
  void clearRotationDeg() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get invert => $_getBF(6);
  @$pb.TagNumber(7)
  set invert($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasInvert() => $_has(6);
  @$pb.TagNumber(7)
  void clearInvert() => $_clearField(7);

  /// 7-bit I2C address of the touch controller; 0 disables touch.
  @$pb.TagNumber(8)
  $core.int get touchAddr => $_getIZ(7);
  @$pb.TagNumber(8)
  set touchAddr($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasTouchAddr() => $_has(7);
  @$pb.TagNumber(8)
  void clearTouchAddr() => $_clearField(8);

  /// Axis transforms the device applies before reporting touches.
  @$pb.TagNumber(9)
  $core.bool get touchSwapXy => $_getBF(8);
  @$pb.TagNumber(9)
  set touchSwapXy($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasTouchSwapXy() => $_has(8);
  @$pb.TagNumber(9)
  void clearTouchSwapXy() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get touchFlipX => $_getBF(9);
  @$pb.TagNumber(10)
  set touchFlipX($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasTouchFlipX() => $_has(9);
  @$pb.TagNumber(10)
  void clearTouchFlipX() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.bool get touchFlipY => $_getBF(10);
  @$pb.TagNumber(11)
  set touchFlipY($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasTouchFlipY() => $_has(10);
  @$pb.TagNumber(11)
  void clearTouchFlipY() => $_clearField(11);
}

class ConfigAck extends $pb.GeneratedMessage {
  factory ConfigAck({
    Status? status,
    $core.String? detail,
  }) {
    final result = create();
    if (status != null) result.status = status;
    if (detail != null) result.detail = detail;
    return result;
  }

  ConfigAck._();

  factory ConfigAck.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ConfigAck.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConfigAck',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.wire'),
      createEmptyInstance: create)
    ..aE<Status>(1, _omitFieldNames ? '' : 'status', enumValues: Status.values)
    ..aOS(2, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConfigAck clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConfigAck copyWith(void Function(ConfigAck) updates) =>
      super.copyWith((message) => updates(message as ConfigAck)) as ConfigAck;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConfigAck create() => ConfigAck._();
  @$core.override
  ConfigAck createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ConfigAck getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConfigAck>(create);
  static ConfigAck? _defaultInstance;

  @$pb.TagNumber(1)
  Status get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(Status value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);

  /// Human-readable reason when status != OK (host logs it verbatim).
  @$pb.TagNumber(2)
  $core.String get detail => $_getSZ(1);
  @$pb.TagNumber(2)
  set detail($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDetail() => $_has(1);
  @$pb.TagNumber(2)
  void clearDetail() => $_clearField(2);
}

/// The firmware runs the down/move/up state machine and axis transforms; the
/// host forwards this to Dart untouched. (0,0) on UP, as in v1.
class Touch extends $pb.GeneratedMessage {
  factory Touch({
    TouchPhase? phase,
    $core.int? x,
    $core.int? y,
  }) {
    final result = create();
    if (phase != null) result.phase = phase;
    if (x != null) result.x = x;
    if (y != null) result.y = y;
    return result;
  }

  Touch._();

  factory Touch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Touch.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Touch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.wire'),
      createEmptyInstance: create)
    ..aE<TouchPhase>(1, _omitFieldNames ? '' : 'phase',
        enumValues: TouchPhase.values)
    ..aI(2, _omitFieldNames ? '' : 'x', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'y', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Touch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Touch copyWith(void Function(Touch) updates) =>
      super.copyWith((message) => updates(message as Touch)) as Touch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Touch create() => Touch._();
  @$core.override
  Touch createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Touch getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Touch>(create);
  static Touch? _defaultInstance;

  @$pb.TagNumber(1)
  TouchPhase get phase => $_getN(0);
  @$pb.TagNumber(1)
  set phase(TouchPhase value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPhase() => $_has(0);
  @$pb.TagNumber(1)
  void clearPhase() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get x => $_getIZ(1);
  @$pb.TagNumber(2)
  set x($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasX() => $_has(1);
  @$pb.TagNumber(2)
  void clearX() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get y => $_getIZ(2);
  @$pb.TagNumber(3)
  set y($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasY() => $_has(2);
  @$pb.TagNumber(3)
  void clearY() => $_clearField(3);
}

class OtaBegin extends $pb.GeneratedMessage {
  factory OtaBegin({
    $core.int? imageSize,
    $core.List<$core.int>? sha256,
    $core.String? version,
  }) {
    final result = create();
    if (imageSize != null) result.imageSize = imageSize;
    if (sha256 != null) result.sha256 = sha256;
    if (version != null) result.version = version;
    return result;
  }

  OtaBegin._();

  factory OtaBegin.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OtaBegin.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OtaBegin',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.wire'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'imageSize', fieldType: $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'sha256', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'version')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OtaBegin clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OtaBegin copyWith(void Function(OtaBegin) updates) =>
      super.copyWith((message) => updates(message as OtaBegin)) as OtaBegin;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OtaBegin create() => OtaBegin._();
  @$core.override
  OtaBegin createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OtaBegin getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OtaBegin>(create);
  static OtaBegin? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get imageSize => $_getIZ(0);
  @$pb.TagNumber(1)
  set imageSize($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasImageSize() => $_has(0);
  @$pb.TagNumber(1)
  void clearImageSize() => $_clearField(1);

  /// SHA-256 of the full image; the device verifies before committing.
  @$pb.TagNumber(2)
  $core.List<$core.int> get sha256 => $_getN(1);
  @$pb.TagNumber(2)
  set sha256($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSha256() => $_has(1);
  @$pb.TagNumber(2)
  void clearSha256() => $_clearField(2);

  /// esp_app_desc_t version extracted from the image (log-only on device).
  @$pb.TagNumber(3)
  $core.String get version => $_getSZ(2);
  @$pb.TagNumber(3)
  set version($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersion() => $_clearField(3);
}

class OtaData extends $pb.GeneratedMessage {
  factory OtaData({
    $core.int? seq,
    $core.List<$core.int>? data,
  }) {
    final result = create();
    if (seq != null) result.seq = seq;
    if (data != null) result.data = data;
    return result;
  }

  OtaData._();

  factory OtaData.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OtaData.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OtaData',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.wire'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'seq', fieldType: $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OtaData clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OtaData copyWith(void Function(OtaData) updates) =>
      super.copyWith((message) => updates(message as OtaData)) as OtaData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OtaData create() => OtaData._();
  @$core.override
  OtaData createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OtaData getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OtaData>(create);
  static OtaData? _defaultInstance;

  /// Chunk index, starting at 0 (detects drops on a desynced stream).
  @$pb.TagNumber(1)
  $core.int get seq => $_getIZ(0);
  @$pb.TagNumber(1)
  set seq($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSeq() => $_has(0);
  @$pb.TagNumber(1)
  void clearSeq() => $_clearField(1);

  /// Image bytes, at most 8192 per chunk (PV_OTA_CHUNK_MAX).
  @$pb.TagNumber(2)
  $core.List<$core.int> get data => $_getN(1);
  @$pb.TagNumber(2)
  set data($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => $_clearField(2);
}

class OtaEnd extends $pb.GeneratedMessage {
  factory OtaEnd() => create();

  OtaEnd._();

  factory OtaEnd.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OtaEnd.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OtaEnd',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.wire'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OtaEnd clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OtaEnd copyWith(void Function(OtaEnd) updates) =>
      super.copyWith((message) => updates(message as OtaEnd)) as OtaEnd;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OtaEnd create() => OtaEnd._();
  @$core.override
  OtaEnd createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OtaEnd getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OtaEnd>(create);
  static OtaEnd? _defaultInstance;
}

/// Discard a partial transfer (host-side cancel).
class OtaAbort extends $pb.GeneratedMessage {
  factory OtaAbort() => create();

  OtaAbort._();

  factory OtaAbort.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OtaAbort.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OtaAbort',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.wire'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OtaAbort clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OtaAbort copyWith(void Function(OtaAbort) updates) =>
      super.copyWith((message) => updates(message as OtaAbort)) as OtaAbort;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OtaAbort create() => OtaAbort._();
  @$core.override
  OtaAbort createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OtaAbort getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OtaAbort>(create);
  static OtaAbort? _defaultInstance;
}

class OtaStatus extends $pb.GeneratedMessage {
  factory OtaStatus({
    OtaState? state,
    $core.int? pct,
    $core.int? err,
  }) {
    final result = create();
    if (state != null) result.state = state;
    if (pct != null) result.pct = pct;
    if (err != null) result.err = err;
    return result;
  }

  OtaStatus._();

  factory OtaStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OtaStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OtaStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.wire'),
      createEmptyInstance: create)
    ..aE<OtaState>(1, _omitFieldNames ? '' : 'state',
        enumValues: OtaState.values)
    ..aI(2, _omitFieldNames ? '' : 'pct', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'err', fieldType: $pb.PbFieldType.OS3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OtaStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OtaStatus copyWith(void Function(OtaStatus) updates) =>
      super.copyWith((message) => updates(message as OtaStatus)) as OtaStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OtaStatus create() => OtaStatus._();
  @$core.override
  OtaStatus createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OtaStatus getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OtaStatus>(create);
  static OtaStatus? _defaultInstance;

  @$pb.TagNumber(1)
  OtaState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(OtaState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);

  /// Receive progress, 0–100.
  @$pb.TagNumber(2)
  $core.int get pct => $_getIZ(1);
  @$pb.TagNumber(2)
  set pct($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPct() => $_has(1);
  @$pb.TagNumber(2)
  void clearPct() => $_clearField(2);

  /// Device-side pv_ota_err code; 0 when state != FAILED.
  @$pb.TagNumber(3)
  $core.int get err => $_getIZ(2);
  @$pb.TagNumber(3)
  set err($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasErr() => $_has(2);
  @$pb.TagNumber(3)
  void clearErr() => $_clearField(3);
}

class EnterRecovery extends $pb.GeneratedMessage {
  factory EnterRecovery() => create();

  EnterRecovery._();

  factory EnterRecovery.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EnterRecovery.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EnterRecovery',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.wire'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnterRecovery clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnterRecovery copyWith(void Function(EnterRecovery) updates) =>
      super.copyWith((message) => updates(message as EnterRecovery))
          as EnterRecovery;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EnterRecovery create() => EnterRecovery._();
  @$core.override
  EnterRecovery createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EnterRecovery getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EnterRecovery>(create);
  static EnterRecovery? _defaultInstance;
}

class AuthChallenge extends $pb.GeneratedMessage {
  factory AuthChallenge({
    $core.List<$core.int>? nonce,
  }) {
    final result = create();
    if (nonce != null) result.nonce = nonce;
    return result;
  }

  AuthChallenge._();

  factory AuthChallenge.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AuthChallenge.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AuthChallenge',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.wire'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'nonce', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AuthChallenge clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AuthChallenge copyWith(void Function(AuthChallenge) updates) =>
      super.copyWith((message) => updates(message as AuthChallenge))
          as AuthChallenge;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AuthChallenge create() => AuthChallenge._();
  @$core.override
  AuthChallenge createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AuthChallenge getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AuthChallenge>(create);
  static AuthChallenge? _defaultInstance;

  /// Fresh random nonce, exactly 32 bytes.
  @$pb.TagNumber(1)
  $core.List<$core.int> get nonce => $_getN(0);
  @$pb.TagNumber(1)
  set nonce($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNonce() => $_has(0);
  @$pb.TagNumber(1)
  void clearNonce() => $_clearField(1);
}

class AuthResponse extends $pb.GeneratedMessage {
  factory AuthResponse({
    AuthStatus? status,
    $core.List<$core.int>? certificate,
    $core.List<$core.int>? signature,
  }) {
    final result = create();
    if (status != null) result.status = status;
    if (certificate != null) result.certificate = certificate;
    if (signature != null) result.signature = signature;
    return result;
  }

  AuthResponse._();

  factory AuthResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AuthResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AuthResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.wire'),
      createEmptyInstance: create)
    ..aE<AuthStatus>(1, _omitFieldNames ? '' : 'status',
        enumValues: AuthStatus.values)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'certificate', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'signature', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AuthResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AuthResponse copyWith(void Function(AuthResponse) updates) =>
      super.copyWith((message) => updates(message as AuthResponse))
          as AuthResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AuthResponse create() => AuthResponse._();
  @$core.override
  AuthResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AuthResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AuthResponse>(create);
  static AuthResponse? _defaultInstance;

  @$pb.TagNumber(1)
  AuthStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(AuthStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);

  /// Opaque pv_device_cert_t (152 bytes): version/key-type/device-id/pubkey/
  /// not-before + CA signature. Parsed at fixed offsets by the host's auth.rs;
  /// the cert layout is its own versioned format (cert[0]) independent of this
  /// schema. Empty when status != OK.
  @$pb.TagNumber(2)
  $core.List<$core.int> get certificate => $_getN(1);
  @$pb.TagNumber(2)
  set certificate($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCertificate() => $_has(1);
  @$pb.TagNumber(2)
  void clearCertificate() => $_clearField(2);

  /// ECDSA P-256 signature (64 bytes, r||s) over
  /// sha256("PVUS-ATTEST-V1" || nonce || device_pubkey). Empty when status != OK.
  @$pb.TagNumber(3)
  $core.List<$core.int> get signature => $_getN(2);
  @$pb.TagNumber(3)
  set signature($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSignature() => $_has(2);
  @$pb.TagNumber(3)
  void clearSignature() => $_clearField(3);
}

class GetDeviceInfo extends $pb.GeneratedMessage {
  factory GetDeviceInfo() => create();

  GetDeviceInfo._();

  factory GetDeviceInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetDeviceInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetDeviceInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.wire'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDeviceInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDeviceInfo copyWith(void Function(GetDeviceInfo) updates) =>
      super.copyWith((message) => updates(message as GetDeviceInfo))
          as GetDeviceInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetDeviceInfo create() => GetDeviceInfo._();
  @$core.override
  GetDeviceInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetDeviceInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetDeviceInfo>(create);
  static GetDeviceInfo? _defaultInstance;
}

class PanelGeometry extends $pb.GeneratedMessage {
  factory PanelGeometry({
    $core.int? width,
    $core.int? height,
    PanelShape? shape,
  }) {
    final result = create();
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    if (shape != null) result.shape = shape;
    return result;
  }

  PanelGeometry._();

  factory PanelGeometry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PanelGeometry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PanelGeometry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.wire'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'width', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'height', fieldType: $pb.PbFieldType.OU3)
    ..aE<PanelShape>(3, _omitFieldNames ? '' : 'shape',
        enumValues: PanelShape.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PanelGeometry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PanelGeometry copyWith(void Function(PanelGeometry) updates) =>
      super.copyWith((message) => updates(message as PanelGeometry))
          as PanelGeometry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PanelGeometry create() => PanelGeometry._();
  @$core.override
  PanelGeometry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PanelGeometry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PanelGeometry>(create);
  static PanelGeometry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get width => $_getIZ(0);
  @$pb.TagNumber(1)
  set width($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWidth() => $_has(0);
  @$pb.TagNumber(1)
  void clearWidth() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get height => $_getIZ(1);
  @$pb.TagNumber(2)
  set height($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHeight() => $_has(1);
  @$pb.TagNumber(2)
  void clearHeight() => $_clearField(2);

  @$pb.TagNumber(3)
  PanelShape get shape => $_getN(2);
  @$pb.TagNumber(3)
  set shape(PanelShape value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasShape() => $_has(2);
  @$pb.TagNumber(3)
  void clearShape() => $_clearField(3);
}

/// Lets the app select devices by serial and size its capture surface from the
/// device instead of the Dart-side kPicoViewModels table.
class DeviceInfo extends $pb.GeneratedMessage {
  factory DeviceInfo({
    $core.String? deviceId,
    $core.String? serial,
    $core.String? fwVersion,
    $core.int? protoVersion,
    PanelGeometry? panel,
    Capabilities? caps,
  }) {
    final result = create();
    if (deviceId != null) result.deviceId = deviceId;
    if (serial != null) result.serial = serial;
    if (fwVersion != null) result.fwVersion = fwVersion;
    if (protoVersion != null) result.protoVersion = protoVersion;
    if (panel != null) result.panel = panel;
    if (caps != null) result.caps = caps;
    return result;
  }

  DeviceInfo._();

  factory DeviceInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeviceInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeviceInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.wire'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'deviceId')
    ..aOS(2, _omitFieldNames ? '' : 'serial')
    ..aOS(3, _omitFieldNames ? '' : 'fwVersion')
    ..aI(4, _omitFieldNames ? '' : 'protoVersion',
        fieldType: $pb.PbFieldType.OU3)
    ..aOM<PanelGeometry>(5, _omitFieldNames ? '' : 'panel',
        subBuilder: PanelGeometry.create)
    ..aOM<Capabilities>(6, _omitFieldNames ? '' : 'caps',
        subBuilder: Capabilities.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceInfo copyWith(void Function(DeviceInfo) updates) =>
      super.copyWith((message) => updates(message as DeviceInfo)) as DeviceInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeviceInfo create() => DeviceInfo._();
  @$core.override
  DeviceInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeviceInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeviceInfo>(create);
  static DeviceInfo? _defaultInstance;

  /// Factory device id from the attestation cert (e.g. "PV4-A00123").
  @$pb.TagNumber(1)
  $core.String get deviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);

  /// USB serial string.
  @$pb.TagNumber(2)
  $core.String get serial => $_getSZ(1);
  @$pb.TagNumber(2)
  set serial($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSerial() => $_has(1);
  @$pb.TagNumber(2)
  void clearSerial() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get fwVersion => $_getSZ(2);
  @$pb.TagNumber(3)
  set fwVersion($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFwVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearFwVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get protoVersion => $_getIZ(3);
  @$pb.TagNumber(4)
  set protoVersion($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasProtoVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearProtoVersion() => $_clearField(4);

  @$pb.TagNumber(5)
  PanelGeometry get panel => $_getN(4);
  @$pb.TagNumber(5)
  set panel(PanelGeometry value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasPanel() => $_has(4);
  @$pb.TagNumber(5)
  void clearPanel() => $_clearField(5);
  @$pb.TagNumber(5)
  PanelGeometry ensurePanel() => $_ensure(4);

  @$pb.TagNumber(6)
  Capabilities get caps => $_getN(5);
  @$pb.TagNumber(6)
  set caps(Capabilities value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasCaps() => $_has(5);
  @$pb.TagNumber(6)
  void clearCaps() => $_clearField(6);
  @$pb.TagNumber(6)
  Capabilities ensureCaps() => $_ensure(5);
}

enum SetParam_Param { brightness, notSet }

class SetParam extends $pb.GeneratedMessage {
  factory SetParam({
    $core.int? brightness,
  }) {
    final result = create();
    if (brightness != null) result.brightness = brightness;
    return result;
  }

  SetParam._();

  factory SetParam.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetParam.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, SetParam_Param> _SetParam_ParamByTag = {
    1: SetParam_Param.brightness,
    0: SetParam_Param.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetParam',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.wire'),
      createEmptyInstance: create)
    ..oo(0, [1])
    ..aI(1, _omitFieldNames ? '' : 'brightness', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetParam clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetParam copyWith(void Function(SetParam) updates) =>
      super.copyWith((message) => updates(message as SetParam)) as SetParam;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetParam create() => SetParam._();
  @$core.override
  SetParam createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetParam getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetParam>(create);
  static SetParam? _defaultInstance;

  @$pb.TagNumber(1)
  SetParam_Param whichParam() => _SetParam_ParamByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  void clearParam() => $_clearField($_whichOneof(0));

  /// Backlight, 0 (off) – 255 (full).
  @$pb.TagNumber(1)
  $core.int get brightness => $_getIZ(0);
  @$pb.TagNumber(1)
  set brightness($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBrightness() => $_has(0);
  @$pb.TagNumber(1)
  void clearBrightness() => $_clearField(1);
}

class ParamAck extends $pb.GeneratedMessage {
  factory ParamAck({
    Status? status,
    $core.String? detail,
  }) {
    final result = create();
    if (status != null) result.status = status;
    if (detail != null) result.detail = detail;
    return result;
  }

  ParamAck._();

  factory ParamAck.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ParamAck.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ParamAck',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.wire'),
      createEmptyInstance: create)
    ..aE<Status>(1, _omitFieldNames ? '' : 'status', enumValues: Status.values)
    ..aOS(2, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ParamAck clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ParamAck copyWith(void Function(ParamAck) updates) =>
      super.copyWith((message) => updates(message as ParamAck)) as ParamAck;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ParamAck create() => ParamAck._();
  @$core.override
  ParamAck createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ParamAck getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ParamAck>(create);
  static ParamAck? _defaultInstance;

  @$pb.TagNumber(1)
  Status get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(Status value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get detail => $_getSZ(1);
  @$pb.TagNumber(2)
  set detail($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDetail() => $_has(1);
  @$pb.TagNumber(2)
  void clearDetail() => $_clearField(2);
}

/// One write / read / write-then-read transaction on the device's expansion I2C
/// bus. `id` is chosen by the caller and echoed in I2cResponse so concurrent
/// callers can match results; the firmware executes transactions in order.
class I2cRequest extends $pb.GeneratedMessage {
  factory I2cRequest({
    $core.int? id,
    $core.int? addr,
    $core.List<$core.int>? write,
    $core.int? readLen,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (addr != null) result.addr = addr;
    if (write != null) result.write = write;
    if (readLen != null) result.readLen = readLen;
    return result;
  }

  I2cRequest._();

  factory I2cRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory I2cRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'I2cRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.wire'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'id', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'addr', fieldType: $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'write', $pb.PbFieldType.OY)
    ..aI(4, _omitFieldNames ? '' : 'readLen', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  I2cRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  I2cRequest copyWith(void Function(I2cRequest) updates) =>
      super.copyWith((message) => updates(message as I2cRequest)) as I2cRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static I2cRequest create() => I2cRequest._();
  @$core.override
  I2cRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static I2cRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<I2cRequest>(create);
  static I2cRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// 7-bit target address.
  @$pb.TagNumber(2)
  $core.int get addr => $_getIZ(1);
  @$pb.TagNumber(2)
  set addr($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAddr() => $_has(1);
  @$pb.TagNumber(2)
  void clearAddr() => $_clearField(2);

  /// Bytes to write first; empty for a pure read.
  @$pb.TagNumber(3)
  $core.List<$core.int> get write => $_getN(2);
  @$pb.TagNumber(3)
  set write($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWrite() => $_has(2);
  @$pb.TagNumber(3)
  void clearWrite() => $_clearField(3);

  /// Bytes to read after the write; 0 for a pure write.
  @$pb.TagNumber(4)
  $core.int get readLen => $_getIZ(3);
  @$pb.TagNumber(4)
  set readLen($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReadLen() => $_has(3);
  @$pb.TagNumber(4)
  void clearReadLen() => $_clearField(4);
}

class I2cResponse extends $pb.GeneratedMessage {
  factory I2cResponse({
    $core.int? id,
    I2cStatus? status,
    $core.List<$core.int>? data,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (status != null) result.status = status;
    if (data != null) result.data = data;
    return result;
  }

  I2cResponse._();

  factory I2cResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory I2cResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'I2cResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.wire'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'id', fieldType: $pb.PbFieldType.OU3)
    ..aE<I2cStatus>(2, _omitFieldNames ? '' : 'status',
        enumValues: I2cStatus.values)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  I2cResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  I2cResponse copyWith(void Function(I2cResponse) updates) =>
      super.copyWith((message) => updates(message as I2cResponse))
          as I2cResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static I2cResponse create() => I2cResponse._();
  @$core.override
  I2cResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static I2cResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<I2cResponse>(create);
  static I2cResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  I2cStatus get status => $_getN(1);
  @$pb.TagNumber(2)
  set status(I2cStatus value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);

  /// Read bytes; empty on error or pure write.
  @$pb.TagNumber(3)
  $core.List<$core.int> get data => $_getN(2);
  @$pb.TagNumber(3)
  set data($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasData() => $_has(2);
  @$pb.TagNumber(3)
  void clearData() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');

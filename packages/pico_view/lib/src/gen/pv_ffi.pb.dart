// This is a generated file - do not edit.
//
// Generated from pv_ffi.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'pv_ffi.pbenum.dart';
import 'pv_wire.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'pv_ffi.pbenum.dart';

enum PvRequest_Req {
  openDevice,
  closeDevice,
  otaStart,
  enterRecovery,
  sysSample,
  sysClose,
  getDeviceInfo,
  setParam,
  i2cRequest,
  haptics,
  notSet
}

class PvRequest extends $pb.GeneratedMessage {
  factory PvRequest({
    OpenDevice? openDevice,
    CloseDevice? closeDevice,
    OtaStart? otaStart,
    $0.EnterRecovery? enterRecovery,
    SysSample? sysSample,
    SysClose? sysClose,
    $0.GetDeviceInfo? getDeviceInfo,
    $0.SetParam? setParam,
    $0.I2cRequest? i2cRequest,
    $0.Haptics? haptics,
  }) {
    final result = create();
    if (openDevice != null) result.openDevice = openDevice;
    if (closeDevice != null) result.closeDevice = closeDevice;
    if (otaStart != null) result.otaStart = otaStart;
    if (enterRecovery != null) result.enterRecovery = enterRecovery;
    if (sysSample != null) result.sysSample = sysSample;
    if (sysClose != null) result.sysClose = sysClose;
    if (getDeviceInfo != null) result.getDeviceInfo = getDeviceInfo;
    if (setParam != null) result.setParam = setParam;
    if (i2cRequest != null) result.i2cRequest = i2cRequest;
    if (haptics != null) result.haptics = haptics;
    return result;
  }

  PvRequest._();

  factory PvRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PvRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, PvRequest_Req> _PvRequest_ReqByTag = {
    1: PvRequest_Req.openDevice,
    2: PvRequest_Req.closeDevice,
    3: PvRequest_Req.otaStart,
    4: PvRequest_Req.enterRecovery,
    8: PvRequest_Req.sysSample,
    9: PvRequest_Req.sysClose,
    16: PvRequest_Req.getDeviceInfo,
    17: PvRequest_Req.setParam,
    18: PvRequest_Req.i2cRequest,
    19: PvRequest_Req.haptics,
    0: PvRequest_Req.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PvRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.ffi'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 8, 9, 16, 17, 18, 19])
    ..aOM<OpenDevice>(1, _omitFieldNames ? '' : 'openDevice',
        subBuilder: OpenDevice.create)
    ..aOM<CloseDevice>(2, _omitFieldNames ? '' : 'closeDevice',
        subBuilder: CloseDevice.create)
    ..aOM<OtaStart>(3, _omitFieldNames ? '' : 'otaStart',
        subBuilder: OtaStart.create)
    ..aOM<$0.EnterRecovery>(4, _omitFieldNames ? '' : 'enterRecovery',
        subBuilder: $0.EnterRecovery.create)
    ..aOM<SysSample>(8, _omitFieldNames ? '' : 'sysSample',
        subBuilder: SysSample.create)
    ..aOM<SysClose>(9, _omitFieldNames ? '' : 'sysClose',
        subBuilder: SysClose.create)
    ..aOM<$0.GetDeviceInfo>(16, _omitFieldNames ? '' : 'getDeviceInfo',
        subBuilder: $0.GetDeviceInfo.create)
    ..aOM<$0.SetParam>(17, _omitFieldNames ? '' : 'setParam',
        subBuilder: $0.SetParam.create)
    ..aOM<$0.I2cRequest>(18, _omitFieldNames ? '' : 'i2cRequest',
        subBuilder: $0.I2cRequest.create)
    ..aOM<$0.Haptics>(19, _omitFieldNames ? '' : 'haptics',
        subBuilder: $0.Haptics.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PvRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PvRequest copyWith(void Function(PvRequest) updates) =>
      super.copyWith((message) => updates(message as PvRequest)) as PvRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PvRequest create() => PvRequest._();
  @$core.override
  PvRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PvRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PvRequest>(create);
  static PvRequest? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  @$pb.TagNumber(18)
  @$pb.TagNumber(19)
  PvRequest_Req whichReq() => _PvRequest_ReqByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  @$pb.TagNumber(18)
  @$pb.TagNumber(19)
  void clearReq() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  OpenDevice get openDevice => $_getN(0);
  @$pb.TagNumber(1)
  set openDevice(OpenDevice value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasOpenDevice() => $_has(0);
  @$pb.TagNumber(1)
  void clearOpenDevice() => $_clearField(1);
  @$pb.TagNumber(1)
  OpenDevice ensureOpenDevice() => $_ensure(0);

  @$pb.TagNumber(2)
  CloseDevice get closeDevice => $_getN(1);
  @$pb.TagNumber(2)
  set closeDevice(CloseDevice value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasCloseDevice() => $_has(1);
  @$pb.TagNumber(2)
  void clearCloseDevice() => $_clearField(2);
  @$pb.TagNumber(2)
  CloseDevice ensureCloseDevice() => $_ensure(1);

  @$pb.TagNumber(3)
  OtaStart get otaStart => $_getN(2);
  @$pb.TagNumber(3)
  set otaStart(OtaStart value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasOtaStart() => $_has(2);
  @$pb.TagNumber(3)
  void clearOtaStart() => $_clearField(3);
  @$pb.TagNumber(3)
  OtaStart ensureOtaStart() => $_ensure(2);

  @$pb.TagNumber(4)
  $0.EnterRecovery get enterRecovery => $_getN(3);
  @$pb.TagNumber(4)
  set enterRecovery($0.EnterRecovery value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasEnterRecovery() => $_has(3);
  @$pb.TagNumber(4)
  void clearEnterRecovery() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.EnterRecovery ensureEnterRecovery() => $_ensure(3);

  /// Host telemetry (independent of any open device).
  @$pb.TagNumber(8)
  SysSample get sysSample => $_getN(4);
  @$pb.TagNumber(8)
  set sysSample(SysSample value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasSysSample() => $_has(4);
  @$pb.TagNumber(8)
  void clearSysSample() => $_clearField(8);
  @$pb.TagNumber(8)
  SysSample ensureSysSample() => $_ensure(4);

  @$pb.TagNumber(9)
  SysClose get sysClose => $_getN(5);
  @$pb.TagNumber(9)
  set sysClose(SysClose value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasSysClose() => $_has(5);
  @$pb.TagNumber(9)
  void clearSysClose() => $_clearField(9);
  @$pb.TagNumber(9)
  SysClose ensureSysClose() => $_ensure(5);

  /// Phase 2 — forwarded to the device.
  @$pb.TagNumber(16)
  $0.GetDeviceInfo get getDeviceInfo => $_getN(6);
  @$pb.TagNumber(16)
  set getDeviceInfo($0.GetDeviceInfo value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasGetDeviceInfo() => $_has(6);
  @$pb.TagNumber(16)
  void clearGetDeviceInfo() => $_clearField(16);
  @$pb.TagNumber(16)
  $0.GetDeviceInfo ensureGetDeviceInfo() => $_ensure(6);

  @$pb.TagNumber(17)
  $0.SetParam get setParam => $_getN(7);
  @$pb.TagNumber(17)
  set setParam($0.SetParam value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasSetParam() => $_has(7);
  @$pb.TagNumber(17)
  void clearSetParam() => $_clearField(17);
  @$pb.TagNumber(17)
  $0.SetParam ensureSetParam() => $_ensure(7);

  @$pb.TagNumber(18)
  $0.I2cRequest get i2cRequest => $_getN(8);
  @$pb.TagNumber(18)
  set i2cRequest($0.I2cRequest value) => $_setField(18, value);
  @$pb.TagNumber(18)
  $core.bool hasI2cRequest() => $_has(8);
  @$pb.TagNumber(18)
  void clearI2cRequest() => $_clearField(18);
  @$pb.TagNumber(18)
  $0.I2cRequest ensureI2cRequest() => $_ensure(8);

  @$pb.TagNumber(19)
  $0.Haptics get haptics => $_getN(9);
  @$pb.TagNumber(19)
  set haptics($0.Haptics value) => $_setField(19, value);
  @$pb.TagNumber(19)
  $core.bool hasHaptics() => $_has(9);
  @$pb.TagNumber(19)
  void clearHaptics() => $_clearField(19);
  @$pb.TagNumber(19)
  $0.Haptics ensureHaptics() => $_ensure(9);
}

/// Open the panel device and start the worker. Responds `ack` when the open was
/// accepted; the outcome arrives as LinkEvent(CONNECTED / UNAUTHORIZED /
/// DISCONNECTED) — replaces v1's blocking pv_open.
class OpenDevice extends $pb.GeneratedMessage {
  factory OpenDevice({
    $core.int? index,
    $core.String? model,
    $core.String? serial,
  }) {
    final result = create();
    if (index != null) result.index = index;
    if (model != null) result.model = model;
    if (serial != null) result.serial = serial;
    return result;
  }

  OpenDevice._();

  factory OpenDevice.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OpenDevice.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OpenDevice',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.ffi'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'index', fieldType: $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'model')
    ..aOS(3, _omitFieldNames ? '' : 'serial')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenDevice clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OpenDevice copyWith(void Function(OpenDevice) updates) =>
      super.copyWith((message) => updates(message as OpenDevice)) as OpenDevice;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OpenDevice create() => OpenDevice._();
  @$core.override
  OpenDevice createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OpenDevice getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OpenDevice>(create);
  static OpenDevice? _defaultInstance;

  /// Nth enumerated device matching the pico-view VID/PID (ignored when
  /// `serial` is set).
  @$pb.TagNumber(1)
  $core.int get index => $_getIZ(0);
  @$pb.TagNumber(1)
  set index($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearIndex() => $_clearField(1);

  /// Panel model preset name, e.g. "st77916-round-360"; empty = default.
  @$pb.TagNumber(2)
  $core.String get model => $_getSZ(1);
  @$pb.TagNumber(2)
  set model($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModel() => $_has(1);
  @$pb.TagNumber(2)
  void clearModel() => $_clearField(2);

  /// Select by USB serial instead of index; empty = use index.
  @$pb.TagNumber(3)
  $core.String get serial => $_getSZ(2);
  @$pb.TagNumber(3)
  set serial($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSerial() => $_has(2);
  @$pb.TagNumber(3)
  void clearSerial() => $_clearField(3);
}

/// Stop the worker and close the device. Responds `ack` after teardown
/// completes (idempotent; `ack` even when nothing was open).
class CloseDevice extends $pb.GeneratedMessage {
  factory CloseDevice() => create();

  CloseDevice._();

  factory CloseDevice.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CloseDevice.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CloseDevice',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.ffi'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloseDevice clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloseDevice copyWith(void Function(CloseDevice) updates) =>
      super.copyWith((message) => updates(message as CloseDevice))
          as CloseDevice;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CloseDevice create() => CloseDevice._();
  @$core.override
  CloseDevice createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CloseDevice getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CloseDevice>(create);
  static CloseDevice? _defaultInstance;
}

/// Stream a signed ESP-IDF app image to the device and commit it. Responds
/// `ack` once enqueued; progress/result arrive as wire.OtaStatus events.
class OtaStart extends $pb.GeneratedMessage {
  factory OtaStart({
    $core.List<$core.int>? image,
  }) {
    final result = create();
    if (image != null) result.image = image;
    return result;
  }

  OtaStart._();

  factory OtaStart.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OtaStart.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OtaStart',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.ffi'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'image', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OtaStart clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OtaStart copyWith(void Function(OtaStart) updates) =>
      super.copyWith((message) => updates(message as OtaStart)) as OtaStart;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OtaStart create() => OtaStart._();
  @$core.override
  OtaStart createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OtaStart getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OtaStart>(create);
  static OtaStart? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get image => $_getN(0);
  @$pb.TagNumber(1)
  set image($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasImage() => $_has(0);
  @$pb.TagNumber(1)
  void clearImage() => $_clearField(1);
}

/// Sample host telemetry once (CPU/RAM/network/temperatures). Synchronous:
/// responds `system`. Opens the sampler on first use.
class SysSample extends $pb.GeneratedMessage {
  factory SysSample() => create();

  SysSample._();

  factory SysSample.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SysSample.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SysSample',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.ffi'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SysSample clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SysSample copyWith(void Function(SysSample) updates) =>
      super.copyWith((message) => updates(message as SysSample)) as SysSample;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SysSample create() => SysSample._();
  @$core.override
  SysSample createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SysSample getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SysSample>(create);
  static SysSample? _defaultInstance;
}

/// Free the host sampler's state. Responds `ack`. Idempotent.
class SysClose extends $pb.GeneratedMessage {
  factory SysClose() => create();

  SysClose._();

  factory SysClose.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SysClose.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SysClose',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.ffi'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SysClose clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SysClose copyWith(void Function(SysClose) updates) =>
      super.copyWith((message) => updates(message as SysClose)) as SysClose;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SysClose create() => SysClose._();
  @$core.override
  SysClose createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SysClose getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SysClose>(create);
  static SysClose? _defaultInstance;
}

enum PvResponse_Resp { ack, error, system, deviceInfo, notSet }

class PvResponse extends $pb.GeneratedMessage {
  factory PvResponse({
    Ack? ack,
    Error? error,
    SystemSnapshot? system,
    $0.DeviceInfo? deviceInfo,
  }) {
    final result = create();
    if (ack != null) result.ack = ack;
    if (error != null) result.error = error;
    if (system != null) result.system = system;
    if (deviceInfo != null) result.deviceInfo = deviceInfo;
    return result;
  }

  PvResponse._();

  factory PvResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PvResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, PvResponse_Resp> _PvResponse_RespByTag = {
    1: PvResponse_Resp.ack,
    2: PvResponse_Resp.error,
    3: PvResponse_Resp.system,
    4: PvResponse_Resp.deviceInfo,
    0: PvResponse_Resp.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PvResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.ffi'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4])
    ..aOM<Ack>(1, _omitFieldNames ? '' : 'ack', subBuilder: Ack.create)
    ..aOM<Error>(2, _omitFieldNames ? '' : 'error', subBuilder: Error.create)
    ..aOM<SystemSnapshot>(3, _omitFieldNames ? '' : 'system',
        subBuilder: SystemSnapshot.create)
    ..aOM<$0.DeviceInfo>(4, _omitFieldNames ? '' : 'deviceInfo',
        subBuilder: $0.DeviceInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PvResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PvResponse copyWith(void Function(PvResponse) updates) =>
      super.copyWith((message) => updates(message as PvResponse)) as PvResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PvResponse create() => PvResponse._();
  @$core.override
  PvResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PvResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PvResponse>(create);
  static PvResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  PvResponse_Resp whichResp() => _PvResponse_RespByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  void clearResp() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  Ack get ack => $_getN(0);
  @$pb.TagNumber(1)
  set ack(Ack value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAck() => $_has(0);
  @$pb.TagNumber(1)
  void clearAck() => $_clearField(1);
  @$pb.TagNumber(1)
  Ack ensureAck() => $_ensure(0);

  @$pb.TagNumber(2)
  Error get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(Error value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  Error ensureError() => $_ensure(1);

  @$pb.TagNumber(3)
  SystemSnapshot get system => $_getN(2);
  @$pb.TagNumber(3)
  set system(SystemSnapshot value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSystem() => $_has(2);
  @$pb.TagNumber(3)
  void clearSystem() => $_clearField(3);
  @$pb.TagNumber(3)
  SystemSnapshot ensureSystem() => $_ensure(2);

  @$pb.TagNumber(4)
  $0.DeviceInfo get deviceInfo => $_getN(3);
  @$pb.TagNumber(4)
  set deviceInfo($0.DeviceInfo value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasDeviceInfo() => $_has(3);
  @$pb.TagNumber(4)
  void clearDeviceInfo() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.DeviceInfo ensureDeviceInfo() => $_ensure(3);
}

class Ack extends $pb.GeneratedMessage {
  factory Ack() => create();

  Ack._();

  factory Ack.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Ack.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Ack',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.ffi'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ack clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ack copyWith(void Function(Ack) updates) =>
      super.copyWith((message) => updates(message as Ack)) as Ack;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Ack create() => Ack._();
  @$core.override
  Ack createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Ack getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Ack>(create);
  static Ack? _defaultInstance;
}

class Error extends $pb.GeneratedMessage {
  factory Error({
    ErrorCode? code,
    $core.String? message,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (message != null) result.message = message;
    return result;
  }

  Error._();

  factory Error.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Error.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Error',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.ffi'),
      createEmptyInstance: create)
    ..aE<ErrorCode>(1, _omitFieldNames ? '' : 'code',
        enumValues: ErrorCode.values)
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Error clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Error copyWith(void Function(Error) updates) =>
      super.copyWith((message) => updates(message as Error)) as Error;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Error create() => Error._();
  @$core.override
  Error createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Error getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Error>(create);
  static Error? _defaultInstance;

  @$pb.TagNumber(1)
  ErrorCode get code => $_getN(0);
  @$pb.TagNumber(1)
  set code(ErrorCode value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);

  /// Human-readable context for logs; not for programmatic dispatch.
  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

/// Posted on transitions only (the worker de-duplicates).
class LinkEvent extends $pb.GeneratedMessage {
  factory LinkEvent({
    LinkState? state,
    $core.String? detail,
  }) {
    final result = create();
    if (state != null) result.state = state;
    if (detail != null) result.detail = detail;
    return result;
  }

  LinkEvent._();

  factory LinkEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LinkEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LinkEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.ffi'),
      createEmptyInstance: create)
    ..aE<LinkState>(1, _omitFieldNames ? '' : 'state',
        enumValues: LinkState.values)
    ..aOS(2, _omitFieldNames ? '' : 'detail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LinkEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LinkEvent copyWith(void Function(LinkEvent) updates) =>
      super.copyWith((message) => updates(message as LinkEvent)) as LinkEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LinkEvent create() => LinkEvent._();
  @$core.override
  LinkEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LinkEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LinkEvent>(create);
  static LinkEvent? _defaultInstance;

  @$pb.TagNumber(1)
  LinkState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(LinkState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);

  /// Reason for DISCONNECTED / UNAUTHORIZED, for logs and the settings UI.
  @$pb.TagNumber(2)
  $core.String get detail => $_getSZ(1);
  @$pb.TagNumber(2)
  set detail($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDetail() => $_has(1);
  @$pb.TagNumber(2)
  void clearDetail() => $_clearField(2);
}

enum PvEvent_Event { touch, link, ota, i2c, notSet }

class PvEvent extends $pb.GeneratedMessage {
  factory PvEvent({
    $0.Touch? touch,
    LinkEvent? link,
    $0.OtaStatus? ota,
    $0.I2cResponse? i2c,
  }) {
    final result = create();
    if (touch != null) result.touch = touch;
    if (link != null) result.link = link;
    if (ota != null) result.ota = ota;
    if (i2c != null) result.i2c = i2c;
    return result;
  }

  PvEvent._();

  factory PvEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PvEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, PvEvent_Event> _PvEvent_EventByTag = {
    1: PvEvent_Event.touch,
    2: PvEvent_Event.link,
    3: PvEvent_Event.ota,
    16: PvEvent_Event.i2c,
    0: PvEvent_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PvEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.ffi'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 16])
    ..aOM<$0.Touch>(1, _omitFieldNames ? '' : 'touch',
        subBuilder: $0.Touch.create)
    ..aOM<LinkEvent>(2, _omitFieldNames ? '' : 'link',
        subBuilder: LinkEvent.create)
    ..aOM<$0.OtaStatus>(3, _omitFieldNames ? '' : 'ota',
        subBuilder: $0.OtaStatus.create)
    ..aOM<$0.I2cResponse>(16, _omitFieldNames ? '' : 'i2c',
        subBuilder: $0.I2cResponse.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PvEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PvEvent copyWith(void Function(PvEvent) updates) =>
      super.copyWith((message) => updates(message as PvEvent)) as PvEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PvEvent create() => PvEvent._();
  @$core.override
  PvEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PvEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PvEvent>(create);
  static PvEvent? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(16)
  PvEvent_Event whichEvent() => _PvEvent_EventByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(16)
  void clearEvent() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $0.Touch get touch => $_getN(0);
  @$pb.TagNumber(1)
  set touch($0.Touch value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTouch() => $_has(0);
  @$pb.TagNumber(1)
  void clearTouch() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Touch ensureTouch() => $_ensure(0);

  @$pb.TagNumber(2)
  LinkEvent get link => $_getN(1);
  @$pb.TagNumber(2)
  set link(LinkEvent value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasLink() => $_has(1);
  @$pb.TagNumber(2)
  void clearLink() => $_clearField(2);
  @$pb.TagNumber(2)
  LinkEvent ensureLink() => $_ensure(1);

  @$pb.TagNumber(3)
  $0.OtaStatus get ota => $_getN(2);
  @$pb.TagNumber(3)
  set ota($0.OtaStatus value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasOta() => $_has(2);
  @$pb.TagNumber(3)
  void clearOta() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.OtaStatus ensureOta() => $_ensure(2);

  /// Phase 2.
  @$pb.TagNumber(16)
  $0.I2cResponse get i2c => $_getN(3);
  @$pb.TagNumber(16)
  set i2c($0.I2cResponse value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasI2c() => $_has(3);
  @$pb.TagNumber(16)
  void clearI2c() => $_clearField(16);
  @$pb.TagNumber(16)
  $0.I2cResponse ensureI2c() => $_ensure(3);
}

/// Replaces the v1 hand-built JSON from sysmon.rs; field-for-field the same data.
class SystemSnapshot extends $pb.GeneratedMessage {
  factory SystemSnapshot({
    CpuStats? cpu,
    MemStats? mem,
    NetStats? net,
    $core.Iterable<Temperature>? temps,
    LoadAverage? load,
  }) {
    final result = create();
    if (cpu != null) result.cpu = cpu;
    if (mem != null) result.mem = mem;
    if (net != null) result.net = net;
    if (temps != null) result.temps.addAll(temps);
    if (load != null) result.load = load;
    return result;
  }

  SystemSnapshot._();

  factory SystemSnapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SystemSnapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SystemSnapshot',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.ffi'),
      createEmptyInstance: create)
    ..aOM<CpuStats>(1, _omitFieldNames ? '' : 'cpu',
        subBuilder: CpuStats.create)
    ..aOM<MemStats>(2, _omitFieldNames ? '' : 'mem',
        subBuilder: MemStats.create)
    ..aOM<NetStats>(3, _omitFieldNames ? '' : 'net',
        subBuilder: NetStats.create)
    ..pPM<Temperature>(4, _omitFieldNames ? '' : 'temps',
        subBuilder: Temperature.create)
    ..aOM<LoadAverage>(5, _omitFieldNames ? '' : 'load',
        subBuilder: LoadAverage.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SystemSnapshot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SystemSnapshot copyWith(void Function(SystemSnapshot) updates) =>
      super.copyWith((message) => updates(message as SystemSnapshot))
          as SystemSnapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SystemSnapshot create() => SystemSnapshot._();
  @$core.override
  SystemSnapshot createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SystemSnapshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SystemSnapshot>(create);
  static SystemSnapshot? _defaultInstance;

  @$pb.TagNumber(1)
  CpuStats get cpu => $_getN(0);
  @$pb.TagNumber(1)
  set cpu(CpuStats value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCpu() => $_has(0);
  @$pb.TagNumber(1)
  void clearCpu() => $_clearField(1);
  @$pb.TagNumber(1)
  CpuStats ensureCpu() => $_ensure(0);

  @$pb.TagNumber(2)
  MemStats get mem => $_getN(1);
  @$pb.TagNumber(2)
  set mem(MemStats value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasMem() => $_has(1);
  @$pb.TagNumber(2)
  void clearMem() => $_clearField(2);
  @$pb.TagNumber(2)
  MemStats ensureMem() => $_ensure(1);

  @$pb.TagNumber(3)
  NetStats get net => $_getN(2);
  @$pb.TagNumber(3)
  set net(NetStats value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasNet() => $_has(2);
  @$pb.TagNumber(3)
  void clearNet() => $_clearField(3);
  @$pb.TagNumber(3)
  NetStats ensureNet() => $_ensure(2);

  @$pb.TagNumber(4)
  $pb.PbList<Temperature> get temps => $_getList(3);

  @$pb.TagNumber(5)
  LoadAverage get load => $_getN(4);
  @$pb.TagNumber(5)
  set load(LoadAverage value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasLoad() => $_has(4);
  @$pb.TagNumber(5)
  void clearLoad() => $_clearField(5);
  @$pb.TagNumber(5)
  LoadAverage ensureLoad() => $_ensure(4);
}

class CpuStats extends $pb.GeneratedMessage {
  factory CpuStats({
    $core.double? usage,
    $core.Iterable<$core.double>? cores,
    $fixnum.Int64? freqMhz,
  }) {
    final result = create();
    if (usage != null) result.usage = usage;
    if (cores != null) result.cores.addAll(cores);
    if (freqMhz != null) result.freqMhz = freqMhz;
    return result;
  }

  CpuStats._();

  factory CpuStats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CpuStats.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CpuStats',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.ffi'),
      createEmptyInstance: create)
    ..aD(1, _omitFieldNames ? '' : 'usage', fieldType: $pb.PbFieldType.OF)
    ..p<$core.double>(2, _omitFieldNames ? '' : 'cores', $pb.PbFieldType.KF)
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'freqMhz', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CpuStats clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CpuStats copyWith(void Function(CpuStats) updates) =>
      super.copyWith((message) => updates(message as CpuStats)) as CpuStats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CpuStats create() => CpuStats._();
  @$core.override
  CpuStats createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CpuStats getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CpuStats>(create);
  static CpuStats? _defaultInstance;

  /// Overall utilization, 0–100.
  @$pb.TagNumber(1)
  $core.double get usage => $_getN(0);
  @$pb.TagNumber(1)
  set usage($core.double value) => $_setFloat(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUsage() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsage() => $_clearField(1);

  /// Per-core utilization (0–100), in the CPUs' listed order.
  @$pb.TagNumber(2)
  $pb.PbList<$core.double> get cores => $_getList(1);

  /// Max reported core frequency in MHz; 0 if unknown.
  @$pb.TagNumber(3)
  $fixnum.Int64 get freqMhz => $_getI64(2);
  @$pb.TagNumber(3)
  set freqMhz($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFreqMhz() => $_has(2);
  @$pb.TagNumber(3)
  void clearFreqMhz() => $_clearField(3);
}

class MemStats extends $pb.GeneratedMessage {
  factory MemStats({
    $fixnum.Int64? total,
    $fixnum.Int64? used,
    $fixnum.Int64? swapTotal,
    $fixnum.Int64? swapUsed,
  }) {
    final result = create();
    if (total != null) result.total = total;
    if (used != null) result.used = used;
    if (swapTotal != null) result.swapTotal = swapTotal;
    if (swapUsed != null) result.swapUsed = swapUsed;
    return result;
  }

  MemStats._();

  factory MemStats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MemStats.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MemStats',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.ffi'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'total', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'used', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'swapTotal', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'swapUsed', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MemStats clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MemStats copyWith(void Function(MemStats) updates) =>
      super.copyWith((message) => updates(message as MemStats)) as MemStats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MemStats create() => MemStats._();
  @$core.override
  MemStats createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MemStats getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MemStats>(create);
  static MemStats? _defaultInstance;

  /// Bytes.
  @$pb.TagNumber(1)
  $fixnum.Int64 get total => $_getI64(0);
  @$pb.TagNumber(1)
  set total($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTotal() => $_has(0);
  @$pb.TagNumber(1)
  void clearTotal() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get used => $_getI64(1);
  @$pb.TagNumber(2)
  set used($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsed() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsed() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get swapTotal => $_getI64(2);
  @$pb.TagNumber(3)
  set swapTotal($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSwapTotal() => $_has(2);
  @$pb.TagNumber(3)
  void clearSwapTotal() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get swapUsed => $_getI64(3);
  @$pb.TagNumber(4)
  set swapUsed($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSwapUsed() => $_has(3);
  @$pb.TagNumber(4)
  void clearSwapUsed() => $_clearField(4);
}

class NetStats extends $pb.GeneratedMessage {
  factory NetStats({
    $fixnum.Int64? rxBps,
    $fixnum.Int64? txBps,
    $fixnum.Int64? rxTotal,
    $fixnum.Int64? txTotal,
  }) {
    final result = create();
    if (rxBps != null) result.rxBps = rxBps;
    if (txBps != null) result.txBps = txBps;
    if (rxTotal != null) result.rxTotal = rxTotal;
    if (txTotal != null) result.txTotal = txTotal;
    return result;
  }

  NetStats._();

  factory NetStats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NetStats.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NetStats',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.ffi'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'rxBps', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'txBps', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'rxTotal', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'txTotal', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NetStats clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NetStats copyWith(void Function(NetStats) updates) =>
      super.copyWith((message) => updates(message as NetStats)) as NetStats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NetStats create() => NetStats._();
  @$core.override
  NetStats createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NetStats getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NetStats>(create);
  static NetStats? _defaultInstance;

  /// Bytes/second over the last sampling interval, summed over all interfaces.
  @$pb.TagNumber(1)
  $fixnum.Int64 get rxBps => $_getI64(0);
  @$pb.TagNumber(1)
  set rxBps($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRxBps() => $_has(0);
  @$pb.TagNumber(1)
  void clearRxBps() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get txBps => $_getI64(1);
  @$pb.TagNumber(2)
  set txBps($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTxBps() => $_has(1);
  @$pb.TagNumber(2)
  void clearTxBps() => $_clearField(2);

  /// Cumulative bytes since the sampler opened.
  @$pb.TagNumber(3)
  $fixnum.Int64 get rxTotal => $_getI64(2);
  @$pb.TagNumber(3)
  set rxTotal($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRxTotal() => $_has(2);
  @$pb.TagNumber(3)
  void clearRxTotal() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get txTotal => $_getI64(3);
  @$pb.TagNumber(4)
  set txTotal($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTxTotal() => $_has(3);
  @$pb.TagNumber(4)
  void clearTxTotal() => $_clearField(4);
}

class Temperature extends $pb.GeneratedMessage {
  factory Temperature({
    $core.String? label,
    $core.double? celsius,
  }) {
    final result = create();
    if (label != null) result.label = label;
    if (celsius != null) result.celsius = celsius;
    return result;
  }

  Temperature._();

  factory Temperature.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Temperature.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Temperature',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.ffi'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'label')
    ..aD(2, _omitFieldNames ? '' : 'celsius', fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Temperature clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Temperature copyWith(void Function(Temperature) updates) =>
      super.copyWith((message) => updates(message as Temperature))
          as Temperature;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Temperature create() => Temperature._();
  @$core.override
  Temperature createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Temperature getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Temperature>(create);
  static Temperature? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get label => $_getSZ(0);
  @$pb.TagNumber(1)
  set label($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get celsius => $_getN(1);
  @$pb.TagNumber(2)
  set celsius($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCelsius() => $_has(1);
  @$pb.TagNumber(2)
  void clearCelsius() => $_clearField(2);
}

/// Unix load average; all zero on Windows.
class LoadAverage extends $pb.GeneratedMessage {
  factory LoadAverage({
    $core.double? one,
    $core.double? five,
    $core.double? fifteen,
  }) {
    final result = create();
    if (one != null) result.one = one;
    if (five != null) result.five = five;
    if (fifteen != null) result.fifteen = fifteen;
    return result;
  }

  LoadAverage._();

  factory LoadAverage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LoadAverage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoadAverage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'picoview.ffi'),
      createEmptyInstance: create)
    ..aD(1, _omitFieldNames ? '' : 'one')
    ..aD(2, _omitFieldNames ? '' : 'five')
    ..aD(3, _omitFieldNames ? '' : 'fifteen')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoadAverage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoadAverage copyWith(void Function(LoadAverage) updates) =>
      super.copyWith((message) => updates(message as LoadAverage))
          as LoadAverage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LoadAverage create() => LoadAverage._();
  @$core.override
  LoadAverage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LoadAverage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LoadAverage>(create);
  static LoadAverage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get one => $_getN(0);
  @$pb.TagNumber(1)
  set one($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOne() => $_has(0);
  @$pb.TagNumber(1)
  void clearOne() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get five => $_getN(1);
  @$pb.TagNumber(2)
  set five($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFive() => $_has(1);
  @$pb.TagNumber(2)
  void clearFive() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get fifteen => $_getN(2);
  @$pb.TagNumber(3)
  set fifteen($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFifteen() => $_has(2);
  @$pb.TagNumber(3)
  void clearFifteen() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');

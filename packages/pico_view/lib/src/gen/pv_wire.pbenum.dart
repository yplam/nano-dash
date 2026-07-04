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

class Status extends $pb.ProtobufEnum {
  static const Status STATUS_UNSPECIFIED =
      Status._(0, _omitEnumNames ? '' : 'STATUS_UNSPECIFIED');
  static const Status STATUS_OK =
      Status._(1, _omitEnumNames ? '' : 'STATUS_OK');
  static const Status STATUS_ERROR =
      Status._(2, _omitEnumNames ? '' : 'STATUS_ERROR');

  /// The firmware understood the request but this build/hardware can't do it.
  static const Status STATUS_UNSUPPORTED =
      Status._(3, _omitEnumNames ? '' : 'STATUS_UNSUPPORTED');

  static const $core.List<Status> values = <Status>[
    STATUS_UNSPECIFIED,
    STATUS_OK,
    STATUS_ERROR,
    STATUS_UNSUPPORTED,
  ];

  static final $core.List<Status?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static Status? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Status._(super.value, super.name);
}

/// Firmware-side display driver profile (v1 pv_panel_model).
class PanelModel extends $pb.ProtobufEnum {
  static const PanelModel PANEL_MODEL_UNSPECIFIED =
      PanelModel._(0, _omitEnumNames ? '' : 'PANEL_MODEL_UNSPECIFIED');
  static const PanelModel PANEL_MODEL_ST77916 =
      PanelModel._(1, _omitEnumNames ? '' : 'PANEL_MODEL_ST77916');
  static const PanelModel PANEL_MODEL_ST7789 =
      PanelModel._(2, _omitEnumNames ? '' : 'PANEL_MODEL_ST7789');

  static const $core.List<PanelModel> values = <PanelModel>[
    PANEL_MODEL_UNSPECIFIED,
    PANEL_MODEL_ST77916,
    PANEL_MODEL_ST7789,
  ];

  static final $core.List<PanelModel?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static PanelModel? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PanelModel._(super.value, super.name);
}

class PanelShape extends $pb.ProtobufEnum {
  static const PanelShape PANEL_SHAPE_UNSPECIFIED =
      PanelShape._(0, _omitEnumNames ? '' : 'PANEL_SHAPE_UNSPECIFIED');
  static const PanelShape PANEL_SHAPE_RECT =
      PanelShape._(1, _omitEnumNames ? '' : 'PANEL_SHAPE_RECT');

  /// Visible glass is the inscribed circle; corners are dead.
  static const PanelShape PANEL_SHAPE_ROUND =
      PanelShape._(2, _omitEnumNames ? '' : 'PANEL_SHAPE_ROUND');

  static const $core.List<PanelShape> values = <PanelShape>[
    PANEL_SHAPE_UNSPECIFIED,
    PANEL_SHAPE_RECT,
    PANEL_SHAPE_ROUND,
  ];

  static final $core.List<PanelShape?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static PanelShape? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PanelShape._(super.value, super.name);
}

class TouchPhase extends $pb.ProtobufEnum {
  static const TouchPhase TOUCH_PHASE_UNSPECIFIED =
      TouchPhase._(0, _omitEnumNames ? '' : 'TOUCH_PHASE_UNSPECIFIED');
  static const TouchPhase TOUCH_PHASE_DOWN =
      TouchPhase._(1, _omitEnumNames ? '' : 'TOUCH_PHASE_DOWN');
  static const TouchPhase TOUCH_PHASE_MOVE =
      TouchPhase._(2, _omitEnumNames ? '' : 'TOUCH_PHASE_MOVE');
  static const TouchPhase TOUCH_PHASE_UP =
      TouchPhase._(3, _omitEnumNames ? '' : 'TOUCH_PHASE_UP');

  static const $core.List<TouchPhase> values = <TouchPhase>[
    TOUCH_PHASE_UNSPECIFIED,
    TOUCH_PHASE_DOWN,
    TOUCH_PHASE_MOVE,
    TOUCH_PHASE_UP,
  ];

  static final $core.List<TouchPhase?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static TouchPhase? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const TouchPhase._(super.value, super.name);
}

class OtaState extends $pb.ProtobufEnum {
  static const OtaState OTA_STATE_UNSPECIFIED =
      OtaState._(0, _omitEnumNames ? '' : 'OTA_STATE_UNSPECIFIED');
  static const OtaState OTA_STATE_RECEIVING =
      OtaState._(1, _omitEnumNames ? '' : 'OTA_STATE_RECEIVING');
  static const OtaState OTA_STATE_VERIFYING =
      OtaState._(2, _omitEnumNames ? '' : 'OTA_STATE_VERIFYING');
  static const OtaState OTA_STATE_DONE =
      OtaState._(3, _omitEnumNames ? '' : 'OTA_STATE_DONE');
  static const OtaState OTA_STATE_FAILED =
      OtaState._(4, _omitEnumNames ? '' : 'OTA_STATE_FAILED');

  static const $core.List<OtaState> values = <OtaState>[
    OTA_STATE_UNSPECIFIED,
    OTA_STATE_RECEIVING,
    OTA_STATE_VERIFYING,
    OTA_STATE_DONE,
    OTA_STATE_FAILED,
  ];

  static final $core.List<OtaState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static OtaState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const OtaState._(super.value, super.name);
}

class AuthStatus extends $pb.ProtobufEnum {
  static const AuthStatus AUTH_STATUS_UNSPECIFIED =
      AuthStatus._(0, _omitEnumNames ? '' : 'AUTH_STATUS_UNSPECIFIED');
  static const AuthStatus AUTH_STATUS_OK =
      AuthStatus._(1, _omitEnumNames ? '' : 'AUTH_STATUS_OK');

  /// Dev board without a provisioned identity (host policy decides).
  static const AuthStatus AUTH_STATUS_UNPROVISIONED =
      AuthStatus._(2, _omitEnumNames ? '' : 'AUTH_STATUS_UNPROVISIONED');
  static const AuthStatus AUTH_STATUS_SIGNING_ERROR =
      AuthStatus._(3, _omitEnumNames ? '' : 'AUTH_STATUS_SIGNING_ERROR');
  static const AuthStatus AUTH_STATUS_MALFORMED_CHALLENGE =
      AuthStatus._(4, _omitEnumNames ? '' : 'AUTH_STATUS_MALFORMED_CHALLENGE');

  static const $core.List<AuthStatus> values = <AuthStatus>[
    AUTH_STATUS_UNSPECIFIED,
    AUTH_STATUS_OK,
    AUTH_STATUS_UNPROVISIONED,
    AUTH_STATUS_SIGNING_ERROR,
    AUTH_STATUS_MALFORMED_CHALLENGE,
  ];

  static final $core.List<AuthStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static AuthStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AuthStatus._(super.value, super.name);
}

class I2cStatus extends $pb.ProtobufEnum {
  static const I2cStatus I2C_STATUS_UNSPECIFIED =
      I2cStatus._(0, _omitEnumNames ? '' : 'I2C_STATUS_UNSPECIFIED');
  static const I2cStatus I2C_STATUS_OK =
      I2cStatus._(1, _omitEnumNames ? '' : 'I2C_STATUS_OK');

  /// Address or data byte not acknowledged.
  static const I2cStatus I2C_STATUS_NACK =
      I2cStatus._(2, _omitEnumNames ? '' : 'I2C_STATUS_NACK');
  static const I2cStatus I2C_STATUS_BUS_ERROR =
      I2cStatus._(3, _omitEnumNames ? '' : 'I2C_STATUS_BUS_ERROR');
  static const I2cStatus I2C_STATUS_TIMEOUT =
      I2cStatus._(4, _omitEnumNames ? '' : 'I2C_STATUS_TIMEOUT');
  static const I2cStatus I2C_STATUS_UNSUPPORTED =
      I2cStatus._(5, _omitEnumNames ? '' : 'I2C_STATUS_UNSUPPORTED');

  static const $core.List<I2cStatus> values = <I2cStatus>[
    I2C_STATUS_UNSPECIFIED,
    I2C_STATUS_OK,
    I2C_STATUS_NACK,
    I2C_STATUS_BUS_ERROR,
    I2C_STATUS_TIMEOUT,
    I2C_STATUS_UNSUPPORTED,
  ];

  static final $core.List<I2cStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static I2cStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const I2cStatus._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');

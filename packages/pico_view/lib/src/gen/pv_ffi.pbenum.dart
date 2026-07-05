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

import 'package:protobuf/protobuf.dart' as $pb;

class MediaCommand extends $pb.ProtobufEnum {
  static const MediaCommand MEDIA_COMMAND_UNSPECIFIED =
      MediaCommand._(0, _omitEnumNames ? '' : 'MEDIA_COMMAND_UNSPECIFIED');
  static const MediaCommand MEDIA_COMMAND_PLAY_PAUSE =
      MediaCommand._(1, _omitEnumNames ? '' : 'MEDIA_COMMAND_PLAY_PAUSE');
  static const MediaCommand MEDIA_COMMAND_NEXT =
      MediaCommand._(2, _omitEnumNames ? '' : 'MEDIA_COMMAND_NEXT');
  static const MediaCommand MEDIA_COMMAND_PREVIOUS =
      MediaCommand._(3, _omitEnumNames ? '' : 'MEDIA_COMMAND_PREVIOUS');

  static const $core.List<MediaCommand> values = <MediaCommand>[
    MEDIA_COMMAND_UNSPECIFIED,
    MEDIA_COMMAND_PLAY_PAUSE,
    MEDIA_COMMAND_NEXT,
    MEDIA_COMMAND_PREVIOUS,
  ];

  static final $core.List<MediaCommand?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static MediaCommand? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MediaCommand._(super.value, super.name);
}

class ErrorCode extends $pb.ProtobufEnum {
  static const ErrorCode ERROR_CODE_UNSPECIFIED =
      ErrorCode._(0, _omitEnumNames ? '' : 'ERROR_CODE_UNSPECIFIED');

  /// Request decoded but is invalid (bad model name, empty image, ...).
  static const ErrorCode ERROR_CODE_BAD_REQUEST =
      ErrorCode._(1, _omitEnumNames ? '' : 'ERROR_CODE_BAD_REQUEST');

  /// open_device while a worker is running. Dart's hot-restart recovery relies
  /// on this being distinct: close_device, then retry the open once.
  static const ErrorCode ERROR_CODE_ALREADY_OPEN =
      ErrorCode._(2, _omitEnumNames ? '' : 'ERROR_CODE_ALREADY_OPEN');

  /// Device-dependent request with no device open.
  static const ErrorCode ERROR_CODE_NOT_OPEN =
      ErrorCode._(3, _omitEnumNames ? '' : 'ERROR_CODE_NOT_OPEN');

  /// USB / device-setup failure.
  static const ErrorCode ERROR_CODE_DEVICE =
      ErrorCode._(4, _omitEnumNames ? '' : 'ERROR_CODE_DEVICE');

  /// Hardware attestation failed (only in LinkEvent detail after the async
  /// open; kept here for requests refused up front).
  static const ErrorCode ERROR_CODE_UNAUTHORIZED =
      ErrorCode._(5, _omitEnumNames ? '' : 'ERROR_CODE_UNAUTHORIZED');

  /// Worker queue gone (engine shutting down).
  static const ErrorCode ERROR_CODE_ENQUEUE =
      ErrorCode._(6, _omitEnumNames ? '' : 'ERROR_CODE_ENQUEUE');

  /// This engine build doesn't know the request variant (older native lib than
  /// Dart package — the caller should degrade gracefully).
  static const ErrorCode ERROR_CODE_UNSUPPORTED =
      ErrorCode._(7, _omitEnumNames ? '' : 'ERROR_CODE_UNSUPPORTED');
  static const ErrorCode ERROR_CODE_INTERNAL =
      ErrorCode._(8, _omitEnumNames ? '' : 'ERROR_CODE_INTERNAL');

  static const $core.List<ErrorCode> values = <ErrorCode>[
    ERROR_CODE_UNSPECIFIED,
    ERROR_CODE_BAD_REQUEST,
    ERROR_CODE_ALREADY_OPEN,
    ERROR_CODE_NOT_OPEN,
    ERROR_CODE_DEVICE,
    ERROR_CODE_UNAUTHORIZED,
    ERROR_CODE_ENQUEUE,
    ERROR_CODE_UNSUPPORTED,
    ERROR_CODE_INTERNAL,
  ];

  static final $core.List<ErrorCode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 8);
  static ErrorCode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ErrorCode._(super.value, super.name);
}

class LinkState extends $pb.ProtobufEnum {
  static const LinkState LINK_STATE_UNSPECIFIED =
      LinkState._(0, _omitEnumNames ? '' : 'LINK_STATE_UNSPECIFIED');

  /// Attached and configured. `verified` / `device_id` say whether this is a
  /// genuine vendor-provisioned unit; a self-built / forked / unprovisioned
  /// board still reaches CONNECTED, just with verified = false.
  static const LinkState LINK_STATE_CONNECTED =
      LinkState._(1, _omitEnumNames ? '' : 'LINK_STATE_CONNECTED');

  /// Lost (unplug / OTA reboot); the engine reconnects on its own.
  static const LinkState LINK_STATE_DISCONNECTED =
      LinkState._(2, _omitEnumNames ? '' : 'LINK_STATE_DISCONNECTED');

  /// Attached, claimed a vendor identity, but failed certificate/challenge
  /// verification (a tamper/clone signal) -- retried, so swapping in a genuine
  /// unit recovers automatically. NOTE: unprovisioned / self-built boards are
  /// NOT unauthorized; they connect as CONNECTED with verified = false. This
  /// state is only reached when PV_REQUIRE_GENUINE is set, or when a device
  /// that presents a cert fails to verify.
  static const LinkState LINK_STATE_UNAUTHORIZED =
      LinkState._(3, _omitEnumNames ? '' : 'LINK_STATE_UNAUTHORIZED');

  static const $core.List<LinkState> values = <LinkState>[
    LINK_STATE_UNSPECIFIED,
    LINK_STATE_CONNECTED,
    LINK_STATE_DISCONNECTED,
    LINK_STATE_UNAUTHORIZED,
  ];

  static final $core.List<LinkState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static LinkState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const LinkState._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');

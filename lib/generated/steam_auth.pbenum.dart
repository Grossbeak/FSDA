// This is a generated file - do not edit.
//
// Generated from steam_auth.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class EAuthTokenPlatformType extends $pb.ProtobufEnum {
  static const EAuthTokenPlatformType k_EAuthTokenPlatformType_Unknown =
      EAuthTokenPlatformType._(
          0, _omitEnumNames ? '' : 'k_EAuthTokenPlatformType_Unknown');
  static const EAuthTokenPlatformType k_EAuthTokenPlatformType_SteamClient =
      EAuthTokenPlatformType._(
          1, _omitEnumNames ? '' : 'k_EAuthTokenPlatformType_SteamClient');
  static const EAuthTokenPlatformType k_EAuthTokenPlatformType_WebBrowser =
      EAuthTokenPlatformType._(
          2, _omitEnumNames ? '' : 'k_EAuthTokenPlatformType_WebBrowser');
  static const EAuthTokenPlatformType k_EAuthTokenPlatformType_MobileApp =
      EAuthTokenPlatformType._(
          3, _omitEnumNames ? '' : 'k_EAuthTokenPlatformType_MobileApp');

  static const $core.List<EAuthTokenPlatformType> values =
      <EAuthTokenPlatformType>[
    k_EAuthTokenPlatformType_Unknown,
    k_EAuthTokenPlatformType_SteamClient,
    k_EAuthTokenPlatformType_WebBrowser,
    k_EAuthTokenPlatformType_MobileApp,
  ];

  static final $core.List<EAuthTokenPlatformType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static EAuthTokenPlatformType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const EAuthTokenPlatformType._(super.value, super.name);
}

class ESessionPersistence extends $pb.ProtobufEnum {
  static const ESessionPersistence k_ESessionPersistence_Invalid =
      ESessionPersistence._(
          -1, _omitEnumNames ? '' : 'k_ESessionPersistence_Invalid');
  static const ESessionPersistence k_ESessionPersistence_Ephemeral =
      ESessionPersistence._(
          0, _omitEnumNames ? '' : 'k_ESessionPersistence_Ephemeral');
  static const ESessionPersistence k_ESessionPersistence_Persistent =
      ESessionPersistence._(
          1, _omitEnumNames ? '' : 'k_ESessionPersistence_Persistent');

  static const $core.List<ESessionPersistence> values = <ESessionPersistence>[
    k_ESessionPersistence_Invalid,
    k_ESessionPersistence_Ephemeral,
    k_ESessionPersistence_Persistent,
  ];

  static final $core.Map<$core.int, ESessionPersistence> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static ESessionPersistence? valueOf($core.int value) => _byValue[value];

  const ESessionPersistence._(super.value, super.name);
}

class EAuthSessionGuardType extends $pb.ProtobufEnum {
  static const EAuthSessionGuardType k_EAuthSessionGuardType_Unknown =
      EAuthSessionGuardType._(
          0, _omitEnumNames ? '' : 'k_EAuthSessionGuardType_Unknown');
  static const EAuthSessionGuardType k_EAuthSessionGuardType_None =
      EAuthSessionGuardType._(
          1, _omitEnumNames ? '' : 'k_EAuthSessionGuardType_None');
  static const EAuthSessionGuardType k_EAuthSessionGuardType_EmailCode =
      EAuthSessionGuardType._(
          2, _omitEnumNames ? '' : 'k_EAuthSessionGuardType_EmailCode');
  static const EAuthSessionGuardType k_EAuthSessionGuardType_DeviceCode =
      EAuthSessionGuardType._(
          3, _omitEnumNames ? '' : 'k_EAuthSessionGuardType_DeviceCode');
  static const EAuthSessionGuardType
      k_EAuthSessionGuardType_DeviceConfirmation = EAuthSessionGuardType._(4,
          _omitEnumNames ? '' : 'k_EAuthSessionGuardType_DeviceConfirmation');
  static const EAuthSessionGuardType k_EAuthSessionGuardType_EmailConfirmation =
      EAuthSessionGuardType._(
          5, _omitEnumNames ? '' : 'k_EAuthSessionGuardType_EmailConfirmation');
  static const EAuthSessionGuardType k_EAuthSessionGuardType_MachineToken =
      EAuthSessionGuardType._(
          6, _omitEnumNames ? '' : 'k_EAuthSessionGuardType_MachineToken');

  static const $core.List<EAuthSessionGuardType> values =
      <EAuthSessionGuardType>[
    k_EAuthSessionGuardType_Unknown,
    k_EAuthSessionGuardType_None,
    k_EAuthSessionGuardType_EmailCode,
    k_EAuthSessionGuardType_DeviceCode,
    k_EAuthSessionGuardType_DeviceConfirmation,
    k_EAuthSessionGuardType_EmailConfirmation,
    k_EAuthSessionGuardType_MachineToken,
  ];

  static final $core.List<EAuthSessionGuardType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static EAuthSessionGuardType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const EAuthSessionGuardType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');

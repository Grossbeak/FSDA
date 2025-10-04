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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'steam_auth.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'steam_auth.pbenum.dart';

class CAuthentication_DeviceDetails extends $pb.GeneratedMessage {
  factory CAuthentication_DeviceDetails({
    $core.String? deviceFriendlyName,
    EAuthTokenPlatformType? platformType,
    $core.int? osType,
    $core.int? gamingDeviceType,
  }) {
    final result = create();
    if (deviceFriendlyName != null)
      result.deviceFriendlyName = deviceFriendlyName;
    if (platformType != null) result.platformType = platformType;
    if (osType != null) result.osType = osType;
    if (gamingDeviceType != null) result.gamingDeviceType = gamingDeviceType;
    return result;
  }

  CAuthentication_DeviceDetails._();

  factory CAuthentication_DeviceDetails.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CAuthentication_DeviceDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CAuthentication_DeviceDetails',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'steam'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'deviceFriendlyName')
    ..aE<EAuthTokenPlatformType>(2, _omitFieldNames ? '' : 'platformType',
        defaultOrMaker: EAuthTokenPlatformType.k_EAuthTokenPlatformType_Unknown,
        enumValues: EAuthTokenPlatformType.values)
    ..aI(3, _omitFieldNames ? '' : 'osType')
    ..aI(4, _omitFieldNames ? '' : 'gamingDeviceType',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CAuthentication_DeviceDetails clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CAuthentication_DeviceDetails copyWith(
          void Function(CAuthentication_DeviceDetails) updates) =>
      super.copyWith(
              (message) => updates(message as CAuthentication_DeviceDetails))
          as CAuthentication_DeviceDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CAuthentication_DeviceDetails create() =>
      CAuthentication_DeviceDetails._();
  @$core.override
  CAuthentication_DeviceDetails createEmptyInstance() => create();
  static $pb.PbList<CAuthentication_DeviceDetails> createRepeated() =>
      $pb.PbList<CAuthentication_DeviceDetails>();
  @$core.pragma('dart2js:noInline')
  static CAuthentication_DeviceDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CAuthentication_DeviceDetails>(create);
  static CAuthentication_DeviceDetails? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get deviceFriendlyName => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceFriendlyName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceFriendlyName() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceFriendlyName() => $_clearField(1);

  @$pb.TagNumber(2)
  EAuthTokenPlatformType get platformType => $_getN(1);
  @$pb.TagNumber(2)
  set platformType(EAuthTokenPlatformType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPlatformType() => $_has(1);
  @$pb.TagNumber(2)
  void clearPlatformType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get osType => $_getIZ(2);
  @$pb.TagNumber(3)
  set osType($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOsType() => $_has(2);
  @$pb.TagNumber(3)
  void clearOsType() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get gamingDeviceType => $_getIZ(3);
  @$pb.TagNumber(4)
  set gamingDeviceType($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasGamingDeviceType() => $_has(3);
  @$pb.TagNumber(4)
  void clearGamingDeviceType() => $_clearField(4);
}

class CAuthentication_AllowedConfirmation extends $pb.GeneratedMessage {
  factory CAuthentication_AllowedConfirmation({
    EAuthSessionGuardType? confirmationType,
    $core.String? associatedMessage,
  }) {
    final result = create();
    if (confirmationType != null) result.confirmationType = confirmationType;
    if (associatedMessage != null) result.associatedMessage = associatedMessage;
    return result;
  }

  CAuthentication_AllowedConfirmation._();

  factory CAuthentication_AllowedConfirmation.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CAuthentication_AllowedConfirmation.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CAuthentication_AllowedConfirmation',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'steam'),
      createEmptyInstance: create)
    ..aE<EAuthSessionGuardType>(1, _omitFieldNames ? '' : 'confirmationType',
        defaultOrMaker: EAuthSessionGuardType.k_EAuthSessionGuardType_Unknown,
        enumValues: EAuthSessionGuardType.values)
    ..aOS(2, _omitFieldNames ? '' : 'associatedMessage')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CAuthentication_AllowedConfirmation clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CAuthentication_AllowedConfirmation copyWith(
          void Function(CAuthentication_AllowedConfirmation) updates) =>
      super.copyWith((message) =>
              updates(message as CAuthentication_AllowedConfirmation))
          as CAuthentication_AllowedConfirmation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CAuthentication_AllowedConfirmation create() =>
      CAuthentication_AllowedConfirmation._();
  @$core.override
  CAuthentication_AllowedConfirmation createEmptyInstance() => create();
  static $pb.PbList<CAuthentication_AllowedConfirmation> createRepeated() =>
      $pb.PbList<CAuthentication_AllowedConfirmation>();
  @$core.pragma('dart2js:noInline')
  static CAuthentication_AllowedConfirmation getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          CAuthentication_AllowedConfirmation>(create);
  static CAuthentication_AllowedConfirmation? _defaultInstance;

  @$pb.TagNumber(1)
  EAuthSessionGuardType get confirmationType => $_getN(0);
  @$pb.TagNumber(1)
  set confirmationType(EAuthSessionGuardType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasConfirmationType() => $_has(0);
  @$pb.TagNumber(1)
  void clearConfirmationType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get associatedMessage => $_getSZ(1);
  @$pb.TagNumber(2)
  set associatedMessage($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAssociatedMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearAssociatedMessage() => $_clearField(2);
}

class CAuthentication_BeginAuthSessionViaCredentials_Request
    extends $pb.GeneratedMessage {
  factory CAuthentication_BeginAuthSessionViaCredentials_Request({
    $core.String? deviceFriendlyName,
    $core.String? accountName,
    $core.String? encryptedPassword,
    $fixnum.Int64? encryptionTimestamp,
    $core.bool? rememberLogin,
    EAuthTokenPlatformType? platformType,
    ESessionPersistence? persistence,
    $core.String? websiteId,
    CAuthentication_DeviceDetails? deviceDetails,
    $core.String? guardData,
    $core.int? language,
    $core.int? qosLevel,
  }) {
    final result = create();
    if (deviceFriendlyName != null)
      result.deviceFriendlyName = deviceFriendlyName;
    if (accountName != null) result.accountName = accountName;
    if (encryptedPassword != null) result.encryptedPassword = encryptedPassword;
    if (encryptionTimestamp != null)
      result.encryptionTimestamp = encryptionTimestamp;
    if (rememberLogin != null) result.rememberLogin = rememberLogin;
    if (platformType != null) result.platformType = platformType;
    if (persistence != null) result.persistence = persistence;
    if (websiteId != null) result.websiteId = websiteId;
    if (deviceDetails != null) result.deviceDetails = deviceDetails;
    if (guardData != null) result.guardData = guardData;
    if (language != null) result.language = language;
    if (qosLevel != null) result.qosLevel = qosLevel;
    return result;
  }

  CAuthentication_BeginAuthSessionViaCredentials_Request._();

  factory CAuthentication_BeginAuthSessionViaCredentials_Request.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CAuthentication_BeginAuthSessionViaCredentials_Request.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'CAuthentication_BeginAuthSessionViaCredentials_Request',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'steam'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'deviceFriendlyName')
    ..aOS(2, _omitFieldNames ? '' : 'accountName')
    ..aOS(3, _omitFieldNames ? '' : 'encryptedPassword')
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'encryptionTimestamp', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOB(5, _omitFieldNames ? '' : 'rememberLogin')
    ..aE<EAuthTokenPlatformType>(6, _omitFieldNames ? '' : 'platformType',
        defaultOrMaker: EAuthTokenPlatformType.k_EAuthTokenPlatformType_Unknown,
        enumValues: EAuthTokenPlatformType.values)
    ..aE<ESessionPersistence>(7, _omitFieldNames ? '' : 'persistence',
        defaultOrMaker: ESessionPersistence.k_ESessionPersistence_Persistent,
        enumValues: ESessionPersistence.values)
    ..a<$core.String>(8, _omitFieldNames ? '' : 'websiteId', $pb.PbFieldType.OS,
        defaultOrMaker: 'Unknown')
    ..aOM<CAuthentication_DeviceDetails>(
        9, _omitFieldNames ? '' : 'deviceDetails',
        subBuilder: CAuthentication_DeviceDetails.create)
    ..aOS(10, _omitFieldNames ? '' : 'guardData')
    ..aI(11, _omitFieldNames ? '' : 'language', fieldType: $pb.PbFieldType.OU3)
    ..aI(12, _omitFieldNames ? '' : 'qosLevel', defaultOrMaker: 2)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CAuthentication_BeginAuthSessionViaCredentials_Request clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CAuthentication_BeginAuthSessionViaCredentials_Request copyWith(
          void Function(CAuthentication_BeginAuthSessionViaCredentials_Request)
              updates) =>
      super.copyWith((message) => updates(message
              as CAuthentication_BeginAuthSessionViaCredentials_Request))
          as CAuthentication_BeginAuthSessionViaCredentials_Request;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CAuthentication_BeginAuthSessionViaCredentials_Request create() =>
      CAuthentication_BeginAuthSessionViaCredentials_Request._();
  @$core.override
  CAuthentication_BeginAuthSessionViaCredentials_Request
      createEmptyInstance() => create();
  static $pb.PbList<CAuthentication_BeginAuthSessionViaCredentials_Request>
      createRepeated() =>
          $pb.PbList<CAuthentication_BeginAuthSessionViaCredentials_Request>();
  @$core.pragma('dart2js:noInline')
  static CAuthentication_BeginAuthSessionViaCredentials_Request getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          CAuthentication_BeginAuthSessionViaCredentials_Request>(create);
  static CAuthentication_BeginAuthSessionViaCredentials_Request?
      _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get deviceFriendlyName => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceFriendlyName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceFriendlyName() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceFriendlyName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get accountName => $_getSZ(1);
  @$pb.TagNumber(2)
  set accountName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAccountName() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccountName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get encryptedPassword => $_getSZ(2);
  @$pb.TagNumber(3)
  set encryptedPassword($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEncryptedPassword() => $_has(2);
  @$pb.TagNumber(3)
  void clearEncryptedPassword() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get encryptionTimestamp => $_getI64(3);
  @$pb.TagNumber(4)
  set encryptionTimestamp($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEncryptionTimestamp() => $_has(3);
  @$pb.TagNumber(4)
  void clearEncryptionTimestamp() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get rememberLogin => $_getBF(4);
  @$pb.TagNumber(5)
  set rememberLogin($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRememberLogin() => $_has(4);
  @$pb.TagNumber(5)
  void clearRememberLogin() => $_clearField(5);

  @$pb.TagNumber(6)
  EAuthTokenPlatformType get platformType => $_getN(5);
  @$pb.TagNumber(6)
  set platformType(EAuthTokenPlatformType value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasPlatformType() => $_has(5);
  @$pb.TagNumber(6)
  void clearPlatformType() => $_clearField(6);

  @$pb.TagNumber(7)
  ESessionPersistence get persistence => $_getN(6);
  @$pb.TagNumber(7)
  set persistence(ESessionPersistence value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasPersistence() => $_has(6);
  @$pb.TagNumber(7)
  void clearPersistence() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get websiteId => $_getS(7, 'Unknown');
  @$pb.TagNumber(8)
  set websiteId($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasWebsiteId() => $_has(7);
  @$pb.TagNumber(8)
  void clearWebsiteId() => $_clearField(8);

  @$pb.TagNumber(9)
  CAuthentication_DeviceDetails get deviceDetails => $_getN(8);
  @$pb.TagNumber(9)
  set deviceDetails(CAuthentication_DeviceDetails value) =>
      $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasDeviceDetails() => $_has(8);
  @$pb.TagNumber(9)
  void clearDeviceDetails() => $_clearField(9);
  @$pb.TagNumber(9)
  CAuthentication_DeviceDetails ensureDeviceDetails() => $_ensure(8);

  @$pb.TagNumber(10)
  $core.String get guardData => $_getSZ(9);
  @$pb.TagNumber(10)
  set guardData($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasGuardData() => $_has(9);
  @$pb.TagNumber(10)
  void clearGuardData() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get language => $_getIZ(10);
  @$pb.TagNumber(11)
  set language($core.int value) => $_setUnsignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasLanguage() => $_has(10);
  @$pb.TagNumber(11)
  void clearLanguage() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get qosLevel => $_getI(11, 2);
  @$pb.TagNumber(12)
  set qosLevel($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasQosLevel() => $_has(11);
  @$pb.TagNumber(12)
  void clearQosLevel() => $_clearField(12);
}

class CAuthentication_BeginAuthSessionViaCredentials_Response
    extends $pb.GeneratedMessage {
  factory CAuthentication_BeginAuthSessionViaCredentials_Response({
    $fixnum.Int64? clientId,
    $core.String? requestId,
    $core.double? interval,
    $core.Iterable<CAuthentication_AllowedConfirmation>? allowedConfirmations,
    $fixnum.Int64? steamid,
    $core.String? weakToken,
  }) {
    final result = create();
    if (clientId != null) result.clientId = clientId;
    if (requestId != null) result.requestId = requestId;
    if (interval != null) result.interval = interval;
    if (allowedConfirmations != null)
      result.allowedConfirmations.addAll(allowedConfirmations);
    if (steamid != null) result.steamid = steamid;
    if (weakToken != null) result.weakToken = weakToken;
    return result;
  }

  CAuthentication_BeginAuthSessionViaCredentials_Response._();

  factory CAuthentication_BeginAuthSessionViaCredentials_Response.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CAuthentication_BeginAuthSessionViaCredentials_Response.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'CAuthentication_BeginAuthSessionViaCredentials_Response',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'steam'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'clientId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..aD(3, _omitFieldNames ? '' : 'interval', fieldType: $pb.PbFieldType.OF)
    ..pPM<CAuthentication_AllowedConfirmation>(
        4, _omitFieldNames ? '' : 'allowedConfirmations',
        subBuilder: CAuthentication_AllowedConfirmation.create)
    ..a<$fixnum.Int64>(5, _omitFieldNames ? '' : 'steamid', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(6, _omitFieldNames ? '' : 'weakToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CAuthentication_BeginAuthSessionViaCredentials_Response clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CAuthentication_BeginAuthSessionViaCredentials_Response copyWith(
          void Function(CAuthentication_BeginAuthSessionViaCredentials_Response)
              updates) =>
      super.copyWith((message) => updates(message
              as CAuthentication_BeginAuthSessionViaCredentials_Response))
          as CAuthentication_BeginAuthSessionViaCredentials_Response;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CAuthentication_BeginAuthSessionViaCredentials_Response create() =>
      CAuthentication_BeginAuthSessionViaCredentials_Response._();
  @$core.override
  CAuthentication_BeginAuthSessionViaCredentials_Response
      createEmptyInstance() => create();
  static $pb.PbList<CAuthentication_BeginAuthSessionViaCredentials_Response>
      createRepeated() =>
          $pb.PbList<CAuthentication_BeginAuthSessionViaCredentials_Response>();
  @$core.pragma('dart2js:noInline')
  static CAuthentication_BeginAuthSessionViaCredentials_Response getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          CAuthentication_BeginAuthSessionViaCredentials_Response>(create);
  static CAuthentication_BeginAuthSessionViaCredentials_Response?
      _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get clientId => $_getI64(0);
  @$pb.TagNumber(1)
  set clientId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasClientId() => $_has(0);
  @$pb.TagNumber(1)
  void clearClientId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get interval => $_getN(2);
  @$pb.TagNumber(3)
  set interval($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasInterval() => $_has(2);
  @$pb.TagNumber(3)
  void clearInterval() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<CAuthentication_AllowedConfirmation> get allowedConfirmations =>
      $_getList(3);

  @$pb.TagNumber(5)
  $fixnum.Int64 get steamid => $_getI64(4);
  @$pb.TagNumber(5)
  set steamid($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSteamid() => $_has(4);
  @$pb.TagNumber(5)
  void clearSteamid() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get weakToken => $_getSZ(5);
  @$pb.TagNumber(6)
  set weakToken($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasWeakToken() => $_has(5);
  @$pb.TagNumber(6)
  void clearWeakToken() => $_clearField(6);
}

class CAuthentication_UpdateAuthSessionWithSteamGuardCode_Request
    extends $pb.GeneratedMessage {
  factory CAuthentication_UpdateAuthSessionWithSteamGuardCode_Request({
    $fixnum.Int64? clientId,
    $core.String? code,
    $core.int? codeType,
  }) {
    final result = create();
    if (clientId != null) result.clientId = clientId;
    if (code != null) result.code = code;
    if (codeType != null) result.codeType = codeType;
    return result;
  }

  CAuthentication_UpdateAuthSessionWithSteamGuardCode_Request._();

  factory CAuthentication_UpdateAuthSessionWithSteamGuardCode_Request.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CAuthentication_UpdateAuthSessionWithSteamGuardCode_Request.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'CAuthentication_UpdateAuthSessionWithSteamGuardCode_Request',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'steam'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'clientId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(2, _omitFieldNames ? '' : 'code')
    ..aI(3, _omitFieldNames ? '' : 'codeType')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CAuthentication_UpdateAuthSessionWithSteamGuardCode_Request clone() =>
      deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CAuthentication_UpdateAuthSessionWithSteamGuardCode_Request copyWith(
          void Function(
                  CAuthentication_UpdateAuthSessionWithSteamGuardCode_Request)
              updates) =>
      super.copyWith((message) => updates(message
              as CAuthentication_UpdateAuthSessionWithSteamGuardCode_Request))
          as CAuthentication_UpdateAuthSessionWithSteamGuardCode_Request;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CAuthentication_UpdateAuthSessionWithSteamGuardCode_Request create() =>
      CAuthentication_UpdateAuthSessionWithSteamGuardCode_Request._();
  @$core.override
  CAuthentication_UpdateAuthSessionWithSteamGuardCode_Request
      createEmptyInstance() => create();
  static $pb.PbList<CAuthentication_UpdateAuthSessionWithSteamGuardCode_Request>
      createRepeated() => $pb.PbList<
          CAuthentication_UpdateAuthSessionWithSteamGuardCode_Request>();
  @$core.pragma('dart2js:noInline')
  static CAuthentication_UpdateAuthSessionWithSteamGuardCode_Request
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          CAuthentication_UpdateAuthSessionWithSteamGuardCode_Request>(create);
  static CAuthentication_UpdateAuthSessionWithSteamGuardCode_Request?
      _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get clientId => $_getI64(0);
  @$pb.TagNumber(1)
  set clientId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasClientId() => $_has(0);
  @$pb.TagNumber(1)
  void clearClientId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get code => $_getSZ(1);
  @$pb.TagNumber(2)
  set code($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearCode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get codeType => $_getIZ(2);
  @$pb.TagNumber(3)
  set codeType($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCodeType() => $_has(2);
  @$pb.TagNumber(3)
  void clearCodeType() => $_clearField(3);
}

class CAuthentication_UpdateAuthSessionWithSteamGuardCode_Response
    extends $pb.GeneratedMessage {
  factory CAuthentication_UpdateAuthSessionWithSteamGuardCode_Response({
    $core.String? agreementSessionUrl,
  }) {
    final result = create();
    if (agreementSessionUrl != null)
      result.agreementSessionUrl = agreementSessionUrl;
    return result;
  }

  CAuthentication_UpdateAuthSessionWithSteamGuardCode_Response._();

  factory CAuthentication_UpdateAuthSessionWithSteamGuardCode_Response.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CAuthentication_UpdateAuthSessionWithSteamGuardCode_Response.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'CAuthentication_UpdateAuthSessionWithSteamGuardCode_Response',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'steam'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'agreementSessionUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CAuthentication_UpdateAuthSessionWithSteamGuardCode_Response clone() =>
      deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CAuthentication_UpdateAuthSessionWithSteamGuardCode_Response copyWith(
          void Function(
                  CAuthentication_UpdateAuthSessionWithSteamGuardCode_Response)
              updates) =>
      super.copyWith((message) => updates(message
              as CAuthentication_UpdateAuthSessionWithSteamGuardCode_Response))
          as CAuthentication_UpdateAuthSessionWithSteamGuardCode_Response;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CAuthentication_UpdateAuthSessionWithSteamGuardCode_Response
      create() =>
          CAuthentication_UpdateAuthSessionWithSteamGuardCode_Response._();
  @$core.override
  CAuthentication_UpdateAuthSessionWithSteamGuardCode_Response
      createEmptyInstance() => create();
  static $pb
      .PbList<CAuthentication_UpdateAuthSessionWithSteamGuardCode_Response>
      createRepeated() => $pb.PbList<
          CAuthentication_UpdateAuthSessionWithSteamGuardCode_Response>();
  @$core.pragma('dart2js:noInline')
  static CAuthentication_UpdateAuthSessionWithSteamGuardCode_Response
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          CAuthentication_UpdateAuthSessionWithSteamGuardCode_Response>(create);
  static CAuthentication_UpdateAuthSessionWithSteamGuardCode_Response?
      _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get agreementSessionUrl => $_getSZ(0);
  @$pb.TagNumber(1)
  set agreementSessionUrl($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAgreementSessionUrl() => $_has(0);
  @$pb.TagNumber(1)
  void clearAgreementSessionUrl() => $_clearField(1);
}

class CAuthentication_PollAuthSessionStatus_Request
    extends $pb.GeneratedMessage {
  factory CAuthentication_PollAuthSessionStatus_Request({
    $fixnum.Int64? clientId,
    $core.String? requestId,
  }) {
    final result = create();
    if (clientId != null) result.clientId = clientId;
    if (requestId != null) result.requestId = requestId;
    return result;
  }

  CAuthentication_PollAuthSessionStatus_Request._();

  factory CAuthentication_PollAuthSessionStatus_Request.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CAuthentication_PollAuthSessionStatus_Request.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CAuthentication_PollAuthSessionStatus_Request',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'steam'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'clientId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CAuthentication_PollAuthSessionStatus_Request clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CAuthentication_PollAuthSessionStatus_Request copyWith(
          void Function(CAuthentication_PollAuthSessionStatus_Request)
              updates) =>
      super.copyWith((message) =>
              updates(message as CAuthentication_PollAuthSessionStatus_Request))
          as CAuthentication_PollAuthSessionStatus_Request;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CAuthentication_PollAuthSessionStatus_Request create() =>
      CAuthentication_PollAuthSessionStatus_Request._();
  @$core.override
  CAuthentication_PollAuthSessionStatus_Request createEmptyInstance() =>
      create();
  static $pb.PbList<CAuthentication_PollAuthSessionStatus_Request>
      createRepeated() =>
          $pb.PbList<CAuthentication_PollAuthSessionStatus_Request>();
  @$core.pragma('dart2js:noInline')
  static CAuthentication_PollAuthSessionStatus_Request getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          CAuthentication_PollAuthSessionStatus_Request>(create);
  static CAuthentication_PollAuthSessionStatus_Request? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get clientId => $_getI64(0);
  @$pb.TagNumber(1)
  set clientId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasClientId() => $_has(0);
  @$pb.TagNumber(1)
  void clearClientId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => $_clearField(2);
}

class CAuthentication_PollAuthSessionStatus_Response
    extends $pb.GeneratedMessage {
  factory CAuthentication_PollAuthSessionStatus_Response({
    $fixnum.Int64? newClientId,
    $core.String? newChallengeUrl,
    $core.String? refreshToken,
    $core.String? accessToken,
    $core.bool? hadRemoteInteraction,
    $core.String? accountName,
    $core.String? newGuardData,
    $core.String? agreementSessionUrl,
  }) {
    final result = create();
    if (newClientId != null) result.newClientId = newClientId;
    if (newChallengeUrl != null) result.newChallengeUrl = newChallengeUrl;
    if (refreshToken != null) result.refreshToken = refreshToken;
    if (accessToken != null) result.accessToken = accessToken;
    if (hadRemoteInteraction != null)
      result.hadRemoteInteraction = hadRemoteInteraction;
    if (accountName != null) result.accountName = accountName;
    if (newGuardData != null) result.newGuardData = newGuardData;
    if (agreementSessionUrl != null)
      result.agreementSessionUrl = agreementSessionUrl;
    return result;
  }

  CAuthentication_PollAuthSessionStatus_Response._();

  factory CAuthentication_PollAuthSessionStatus_Response.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CAuthentication_PollAuthSessionStatus_Response.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CAuthentication_PollAuthSessionStatus_Response',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'steam'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'newClientId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(2, _omitFieldNames ? '' : 'newChallengeUrl')
    ..aOS(3, _omitFieldNames ? '' : 'refreshToken')
    ..aOS(4, _omitFieldNames ? '' : 'accessToken')
    ..aOB(5, _omitFieldNames ? '' : 'hadRemoteInteraction')
    ..aOS(6, _omitFieldNames ? '' : 'accountName')
    ..aOS(7, _omitFieldNames ? '' : 'newGuardData')
    ..aOS(8, _omitFieldNames ? '' : 'agreementSessionUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CAuthentication_PollAuthSessionStatus_Response clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CAuthentication_PollAuthSessionStatus_Response copyWith(
          void Function(CAuthentication_PollAuthSessionStatus_Response)
              updates) =>
      super.copyWith((message) => updates(
              message as CAuthentication_PollAuthSessionStatus_Response))
          as CAuthentication_PollAuthSessionStatus_Response;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CAuthentication_PollAuthSessionStatus_Response create() =>
      CAuthentication_PollAuthSessionStatus_Response._();
  @$core.override
  CAuthentication_PollAuthSessionStatus_Response createEmptyInstance() =>
      create();
  static $pb.PbList<CAuthentication_PollAuthSessionStatus_Response>
      createRepeated() =>
          $pb.PbList<CAuthentication_PollAuthSessionStatus_Response>();
  @$core.pragma('dart2js:noInline')
  static CAuthentication_PollAuthSessionStatus_Response getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          CAuthentication_PollAuthSessionStatus_Response>(create);
  static CAuthentication_PollAuthSessionStatus_Response? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get newClientId => $_getI64(0);
  @$pb.TagNumber(1)
  set newClientId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNewClientId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNewClientId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get newChallengeUrl => $_getSZ(1);
  @$pb.TagNumber(2)
  set newChallengeUrl($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNewChallengeUrl() => $_has(1);
  @$pb.TagNumber(2)
  void clearNewChallengeUrl() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get refreshToken => $_getSZ(2);
  @$pb.TagNumber(3)
  set refreshToken($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRefreshToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearRefreshToken() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get accessToken => $_getSZ(3);
  @$pb.TagNumber(4)
  set accessToken($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAccessToken() => $_has(3);
  @$pb.TagNumber(4)
  void clearAccessToken() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get hadRemoteInteraction => $_getBF(4);
  @$pb.TagNumber(5)
  set hadRemoteInteraction($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasHadRemoteInteraction() => $_has(4);
  @$pb.TagNumber(5)
  void clearHadRemoteInteraction() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get accountName => $_getSZ(5);
  @$pb.TagNumber(6)
  set accountName($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAccountName() => $_has(5);
  @$pb.TagNumber(6)
  void clearAccountName() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get newGuardData => $_getSZ(6);
  @$pb.TagNumber(7)
  set newGuardData($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasNewGuardData() => $_has(6);
  @$pb.TagNumber(7)
  void clearNewGuardData() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get agreementSessionUrl => $_getSZ(7);
  @$pb.TagNumber(8)
  set agreementSessionUrl($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasAgreementSessionUrl() => $_has(7);
  @$pb.TagNumber(8)
  void clearAgreementSessionUrl() => $_clearField(8);
}

class CAuthentication_GetPasswordRSAPublicKey_Request
    extends $pb.GeneratedMessage {
  factory CAuthentication_GetPasswordRSAPublicKey_Request({
    $core.String? accountName,
  }) {
    final result = create();
    if (accountName != null) result.accountName = accountName;
    return result;
  }

  CAuthentication_GetPasswordRSAPublicKey_Request._();

  factory CAuthentication_GetPasswordRSAPublicKey_Request.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CAuthentication_GetPasswordRSAPublicKey_Request.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'CAuthentication_GetPasswordRSAPublicKey_Request',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'steam'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'accountName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CAuthentication_GetPasswordRSAPublicKey_Request clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CAuthentication_GetPasswordRSAPublicKey_Request copyWith(
          void Function(CAuthentication_GetPasswordRSAPublicKey_Request)
              updates) =>
      super.copyWith((message) => updates(
              message as CAuthentication_GetPasswordRSAPublicKey_Request))
          as CAuthentication_GetPasswordRSAPublicKey_Request;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CAuthentication_GetPasswordRSAPublicKey_Request create() =>
      CAuthentication_GetPasswordRSAPublicKey_Request._();
  @$core.override
  CAuthentication_GetPasswordRSAPublicKey_Request createEmptyInstance() =>
      create();
  static $pb.PbList<CAuthentication_GetPasswordRSAPublicKey_Request>
      createRepeated() =>
          $pb.PbList<CAuthentication_GetPasswordRSAPublicKey_Request>();
  @$core.pragma('dart2js:noInline')
  static CAuthentication_GetPasswordRSAPublicKey_Request getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          CAuthentication_GetPasswordRSAPublicKey_Request>(create);
  static CAuthentication_GetPasswordRSAPublicKey_Request? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get accountName => $_getSZ(0);
  @$pb.TagNumber(1)
  set accountName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAccountName() => $_has(0);
  @$pb.TagNumber(1)
  void clearAccountName() => $_clearField(1);
}

class CAuthentication_GetPasswordRSAPublicKey_Response
    extends $pb.GeneratedMessage {
  factory CAuthentication_GetPasswordRSAPublicKey_Response({
    $core.String? publickeyMod,
    $core.String? publickeyExp,
    $fixnum.Int64? timestamp,
  }) {
    final result = create();
    if (publickeyMod != null) result.publickeyMod = publickeyMod;
    if (publickeyExp != null) result.publickeyExp = publickeyExp;
    if (timestamp != null) result.timestamp = timestamp;
    return result;
  }

  CAuthentication_GetPasswordRSAPublicKey_Response._();

  factory CAuthentication_GetPasswordRSAPublicKey_Response.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CAuthentication_GetPasswordRSAPublicKey_Response.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'CAuthentication_GetPasswordRSAPublicKey_Response',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'steam'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'publickeyMod')
    ..aOS(2, _omitFieldNames ? '' : 'publickeyExp')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'timestamp', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CAuthentication_GetPasswordRSAPublicKey_Response clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CAuthentication_GetPasswordRSAPublicKey_Response copyWith(
          void Function(CAuthentication_GetPasswordRSAPublicKey_Response)
              updates) =>
      super.copyWith((message) => updates(
              message as CAuthentication_GetPasswordRSAPublicKey_Response))
          as CAuthentication_GetPasswordRSAPublicKey_Response;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CAuthentication_GetPasswordRSAPublicKey_Response create() =>
      CAuthentication_GetPasswordRSAPublicKey_Response._();
  @$core.override
  CAuthentication_GetPasswordRSAPublicKey_Response createEmptyInstance() =>
      create();
  static $pb.PbList<CAuthentication_GetPasswordRSAPublicKey_Response>
      createRepeated() =>
          $pb.PbList<CAuthentication_GetPasswordRSAPublicKey_Response>();
  @$core.pragma('dart2js:noInline')
  static CAuthentication_GetPasswordRSAPublicKey_Response getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          CAuthentication_GetPasswordRSAPublicKey_Response>(create);
  static CAuthentication_GetPasswordRSAPublicKey_Response? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get publickeyMod => $_getSZ(0);
  @$pb.TagNumber(1)
  set publickeyMod($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPublickeyMod() => $_has(0);
  @$pb.TagNumber(1)
  void clearPublickeyMod() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get publickeyExp => $_getSZ(1);
  @$pb.TagNumber(2)
  set publickeyExp($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPublickeyExp() => $_has(1);
  @$pb.TagNumber(2)
  void clearPublickeyExp() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get timestamp => $_getI64(2);
  @$pb.TagNumber(3)
  set timestamp($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearTimestamp() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');

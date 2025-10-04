import 'dart:convert';

class MaFile {
  final String accountName;
  final String sharedSecret;
  final String identitySecret;
  final String? deviceId;
  final String? steamId;
  final String? oauthToken;
  final String? sessionId;
  final String? webCookie;

  MaFile({
    required this.accountName,
    required this.sharedSecret,
    required this.identitySecret,
    this.deviceId,
    this.steamId,
    this.oauthToken,
    this.sessionId,
    this.webCookie,
  });

  factory MaFile.fromJson(Map<String, dynamic> json) {
    return MaFile(
      accountName: json['account_name'] ?? json['accountName'] ?? '',
      sharedSecret: json['shared_secret'] ?? json['sharedSecret'] ?? '',
      identitySecret: json['identity_secret'] ?? json['identitySecret'] ?? '',
      deviceId: json['device_id'] ?? json['deviceId'],
      steamId: (json['steamid'] ?? json['steamId'])?.toString(),
      oauthToken: json['oauth_token'] ?? json['oauthToken'],
      sessionId: json['session_id'] ?? json['sessionId'],
      webCookie: json['webcookie'] ?? json['webCookie'],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'account_name': accountName,
        'shared_secret': sharedSecret,
        'identity_secret': identitySecret,
        if (deviceId != null) 'device_id': deviceId,
        if (steamId != null) 'steamid': steamId,
        if (oauthToken != null) 'oauth_token': oauthToken,
        if (sessionId != null) 'session_id': sessionId,
        if (webCookie != null) 'webcookie': webCookie,
      };

  static MaFile parse(String content) => MaFile.fromJson(json.decode(content) as Map<String, dynamic>);

  String serialize() => json.encode(toJson());
}

class AccountEntry {
  final String? filePath; // Теперь опциональный, для обратной совместимости
  final MaFile maFile;
  final String? maFileContent; // Добавляем поле для хранения содержимого

  AccountEntry({this.filePath, required this.maFile, this.maFileContent});
}

class ConfirmationItem {
  final String id;
  final String nonce; // confirmation key (ck)
  final String creatorId; // Trade offer ID or market transaction ID
  final String typeName;
  final String headline;
  final List<String> summary;
  final int creationTime;
  final String icon;
  final bool multi;
  final ConfirmationType type;

  ConfirmationItem({
    required this.id,
    required this.nonce,
    required this.creatorId,
    required this.typeName,
    required this.headline,
    required this.summary,
    required this.creationTime,
    required this.icon,
    required this.multi,
    required this.type,
  });

  factory ConfirmationItem.fromJson(Map<String, dynamic> json) {
    return ConfirmationItem(
      id: json['id'] ?? '',
      nonce: json['nonce'] ?? '',
      creatorId: json['creator_id'] ?? '',
      typeName: json['type_name'] ?? '',
      headline: json['headline'] ?? '',
      summary: List<String>.from(json['summary'] ?? []),
      creationTime: json['creation_time'] ?? 0,
      icon: json['icon'] ?? '',
      multi: json['multi'] ?? false,
      type: ConfirmationType.fromInt(json['type'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nonce': nonce,
    'creator_id': creatorId,
    'type_name': typeName,
    'headline': headline,
    'summary': summary,
    'creation_time': creationTime,
    'icon': icon,
    'multi': multi,
    'type': type.value,
  };

  String get description {
    return '$typeName - $headline - ${summary.join(', ')}';
  }
}

enum ConfirmationType {
  test(1),
  trade(2),
  marketSell(3),
  featureOptOut(4),
  phoneNumberChange(5),
  accountRecovery(6),
  apiKeyCreation(9),
  joinSteamFamily(11),
  unknown(0);

  const ConfirmationType(this.value);
  final int value;

  static ConfirmationType fromInt(int value) {
    switch (value) {
      case 1: return ConfirmationType.test;
      case 2: return ConfirmationType.trade;
      case 3: return ConfirmationType.marketSell;
      case 4: return ConfirmationType.featureOptOut;
      case 5: return ConfirmationType.phoneNumberChange;
      case 6: return ConfirmationType.accountRecovery;
      case 9: return ConfirmationType.apiKeyCreation;
      case 11: return ConfirmationType.joinSteamFamily;
      default: return ConfirmationType.unknown;
    }
  }
}



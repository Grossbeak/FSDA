import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'debug_logger.dart';
import 'secure_token_manager.dart';
import '../models/mafile.dart';

class SteamQrAuth {
  static const String _baseUrl = 'https://api.steampowered.com';
  
  /// Подтверждает QR вход используя существующий аккаунт Steam Guard
  static Future<Map<String, dynamic>?> approveQrLogin(String qrUrl, MaFile maFile) async {
    try {
      DebugLogger.logWithTag('SteamQrAuth', 'Подтверждаем QR вход: $qrUrl');
      
      // Парсим QR URL для получения client_id и version
      final challenge = _parseQrUrl(qrUrl);
      if (challenge == null) {
        throw Exception('Неверный формат QR URL');
      }
      
      DebugLogger.logWithTag('SteamQrAuth', 'Parsed challenge: version=${challenge['version']}, client_id=${challenge['client_id']}');
      
      // Получаем токены доступа
      final accessToken = await SecureTokenManager.getAccessToken();
      if (accessToken == null) {
        throw Exception('Токен доступа не найден. Требуется авторизация.');
      }
      
      // Получаем steamId из maFile или из сохраненных токенов
      String? steamIdToUse = maFile.steamId;
      
      if (steamIdToUse == null || steamIdToUse.isEmpty) {
        DebugLogger.logWithTag('SteamQrAuth', 'Steam ID отсутствует в maFile, проверяем сохраненные токены');
        try {
          final tokens = await SecureTokenManager.loadTokens();
          if (tokens != null && tokens['steamid'] != null) {
            steamIdToUse = tokens['steamid'];
            DebugLogger.logWithTag('SteamQrAuth', 'Найден Steam ID в токенах: $steamIdToUse');
          }
        } catch (e) {
          DebugLogger.logWithTag('SteamQrAuth', 'Ошибка загрузки токенов: $e');
        }
      }
      
      if (steamIdToUse == null || steamIdToUse.isEmpty) {
        throw Exception('У аккаунта отсутствует steamId. Сначала выполните авторизацию Steam.');
      }
      
      final steamIdInt = int.parse(steamIdToUse);
      
      // Создаем подпись для подтверждения
      final signature = _buildSignature(
        maFile.sharedSecret,
        steamIdInt,
        challenge['version'] as int,
        challenge['client_id'] as BigInt,
      );
      
      DebugLogger.logWithTag('SteamQrAuth', 'Generated signature: ${signature.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}');
      
      // Отправляем подтверждение
      final success = await _sendMobileConfirmation(
        accessToken,
        steamIdInt,
        challenge['version'] as int,
        challenge['client_id'] as BigInt,
        signature,
        true, // confirm = true
      );
      
      if (success) {
        DebugLogger.logWithTag('SteamQrAuth', 'QR вход успешно подтвержден');
        return {
          'success': true,
          'steamid': maFile.steamId,
          'account_name': maFile.accountName,
        };
      } else {
        throw Exception('Не удалось подтвердить QR вход');
      }
      
    } catch (e) {
      DebugLogger.logWithTag('SteamQrAuth', 'Ошибка подтверждения QR входа: $e');
      rethrow;
    }
  }

  /// Выполняет авторизацию по QR коду Steam (старый метод)
  static Future<Map<String, dynamic>?> performQrAuth(String challengeId) async {
    try {
      DebugLogger.logWithTag('SteamQrAuth', 'Начинаем QR авторизацию для challenge: $challengeId');
      
      // Шаг 1: Начинаем QR авторизацию
      final pollResponse = await _startQrAuth(challengeId);
      if (pollResponse == null) {
        throw Exception('Не удалось начать QR авторизацию');
      }
      
      final clientId = pollResponse['client_id'] as String;
      final requestId = pollResponse['request_id'] as String;
      
      DebugLogger.logWithTag('SteamQrAuth', 'Получены client_id: $clientId, request_id: $requestId');
      
      // Шаг 2: Ожидаем подтверждения пользователя
      Map<String, dynamic>? authResult;
      int attempts = 0;
      const maxAttempts = 60; // 2 минуты ожидания
      
      while (attempts < maxAttempts && authResult == null) {
        await Future.delayed(const Duration(seconds: 2));
        attempts++;
        
        DebugLogger.logWithTag('SteamQrAuth', 'Проверяем статус авторизации (попытка $attempts)');
        
        authResult = await _pollQrAuthStatus(clientId, requestId);
        
        if (authResult != null) {
          DebugLogger.logWithTag('SteamQrAuth', 'Авторизация завершена успешно');
          break;
        }
      }
      
      if (authResult == null) {
        throw Exception('Время ожидания авторизации истекло');
      }
      
      return authResult;
      
    } catch (e) {
      DebugLogger.logWithTag('SteamQrAuth', 'Ошибка QR авторизации: $e');
      rethrow;
    }
  }
  
  /// Начинает процесс QR авторизации
  static Future<Map<String, dynamic>?> _startQrAuth(String challengeId) async {
    try {
      final url = '$_baseUrl/IAuthenticationService/BeginAuthSessionViaQR/v1/';
      
      final body = {
        'qr_challenge_url': 'https://s.team/q/1/$challengeId',
        'persistence': '1', // Запомнить устройство
      };
      
      DebugLogger.logWithTag('SteamQrAuth', 'Отправляем запрос на начало QR авторизации');
      DebugLogger.logWithTag('SteamQrAuth', 'URL: $url');
      DebugLogger.logWithTag('SteamQrAuth', 'Body: $body');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'okhttp/3.12.12',
        },
        body: body,
      );
      
      DebugLogger.logWithTag('SteamQrAuth', 'Ответ сервера: ${response.statusCode}');
      DebugLogger.logWithTag('SteamQrAuth', 'Тело ответа: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final responseData = data['response'] as Map<String, dynamic>?;
        
        if (responseData != null && 
            responseData['client_id'] != null && 
            responseData['request_id'] != null) {
          return responseData;
        }
      }
      
      return null;
    } catch (e) {
      DebugLogger.logWithTag('SteamQrAuth', 'Ошибка начала QR авторизации: $e');
      return null;
    }
  }
  
  /// Проверяет статус QR авторизации
  static Future<Map<String, dynamic>?> _pollQrAuthStatus(String clientId, String requestId) async {
    try {
      final url = '$_baseUrl/IAuthenticationService/PollAuthSessionStatus/v1/';
      
      final body = {
        'client_id': clientId,
        'request_id': requestId,
      };
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'okhttp/3.12.12',
        },
        body: body,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final responseData = data['response'] as Map<String, dynamic>?;
        
        if (responseData != null) {
          // Проверяем, есть ли токены авторизации
          if (responseData['access_token'] != null && 
              responseData['refresh_token'] != null) {
            
            DebugLogger.logWithTag('SteamQrAuth', 'Получены токены авторизации');
            
            // Извлекаем данные из JWT токена
            final accessToken = responseData['access_token'] as String;
            final steamId = _extractSteamIdFromJwt(accessToken);
            
            final authResult = {
              'access_token': accessToken,
              'refresh_token': responseData['refresh_token'] as String,
              'steamid': steamId,
              'account_name': responseData['account_name'] as String? ?? 'Unknown',
              'weak_token': responseData['weak_token'] as String? ?? '',
              'expiry_time': _extractExpiryFromJwt(accessToken),
            };
            
            // Сохраняем токены
            await SecureTokenManager.saveTokens(
              accessToken: authResult['access_token']! as String,
              refreshToken: authResult['refresh_token']! as String,
              steamId: authResult['steamid']! as String,
              accountName: authResult['account_name']! as String,
              weakToken: authResult['weak_token']! as String,
              expiryTime: authResult['expiry_time']! as int,
            );
            
            return authResult;
          }
          
          // Проверяем на ошибки
          if (responseData['had_remote_interaction'] == true) {
            throw Exception('Авторизация отклонена пользователем');
          }
        }
      }
      
      return null; // Продолжаем ожидание
    } catch (e) {
      DebugLogger.logWithTag('SteamQrAuth', 'Ошибка проверки статуса: $e');
      rethrow;
    }
  }
  
  /// Извлекает Steam ID из JWT токена
  static String _extractSteamIdFromJwt(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return '';
      
      // Декодируем payload (вторая часть)
      String payload = parts[1];
      
      // Добавляем padding если нужно
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      
      final decoded = utf8.decode(base64Decode(payload));
      final data = jsonDecode(decoded) as Map<String, dynamic>;
      
      return data['sub'] as String? ?? '';
    } catch (e) {
      DebugLogger.logWithTag('SteamQrAuth', 'Ошибка извлечения Steam ID: $e');
      return '';
    }
  }
  
  /// Извлекает время истечения из JWT токена
  static int _extractExpiryFromJwt(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return 0;
      
      // Декодируем payload (вторая часть)
      String payload = parts[1];
      
      // Добавляем padding если нужно
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      
      final decoded = utf8.decode(base64Decode(payload));
      final data = jsonDecode(decoded) as Map<String, dynamic>;
      
      return data['exp'] as int? ?? 0;
    } catch (e) {
      DebugLogger.logWithTag('SteamQrAuth', 'Ошибка извлечения времени истечения: $e');
      return DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600; // +1 час по умолчанию
    }
  }

  /// Парсит QR URL для извлечения client_id и version
  static Map<String, dynamic>? _parseQrUrl(String qrUrl) {
    try {
      // Формат: https://s.team/q/{version}/{client_id}
      final uri = Uri.parse(qrUrl);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length >= 3 && pathSegments[0] == 'q') {
        final version = int.parse(pathSegments[1]);
        final clientId = BigInt.parse(pathSegments[2]);
        
        return {
          'version': version,
          'client_id': clientId,
        };
      }
      
      return null;
    } catch (e) {
      DebugLogger.logWithTag('SteamQrAuth', 'Ошибка парсинга QR URL: $e');
      return null;
    }
  }

  /// Создает подпись для подтверждения QR входа
  static Uint8List _buildSignature(String sharedSecret, int steamId, int version, BigInt clientId) {
    try {
      // Декодируем shared_secret из base64
      final secretBytes = base64Decode(sharedSecret);
      
      // Создаем данные для подписи
      final data = BytesBuilder();
      
      // Добавляем version (2 байта, little endian)
      data.add(Uint8List.fromList([
        version & 0xFF,
        (version >> 8) & 0xFF,
      ]));
      
      // Добавляем client_id (8 байт, little endian)
      final clientIdBytes = Uint8List(8);
      var clientIdValue = clientId;
      for (int i = 0; i < 8; i++) {
        clientIdBytes[i] = (clientIdValue & BigInt.from(0xFF)).toInt();
        clientIdValue = clientIdValue >> 8;
      }
      data.add(clientIdBytes);
      
      // Добавляем steam_id (8 байт, little endian)
      final steamIdBytes = Uint8List(8);
      for (int i = 0; i < 8; i++) {
        steamIdBytes[i] = (steamId >> (i * 8)) & 0xFF;
      }
      data.add(steamIdBytes);
      
      // Создаем HMAC-SHA256 подпись
      final hmac = Hmac(sha256, secretBytes);
      final digest = hmac.convert(data.toBytes());
      
      return Uint8List.fromList(digest.bytes);
    } catch (e) {
      DebugLogger.logWithTag('SteamQrAuth', 'Ошибка создания подписи: $e');
      rethrow;
    }
  }

  /// Отправляет подтверждение мобильной авторизации
  static Future<bool> _sendMobileConfirmation(
    String accessToken,
    int steamId,
    int version,
    BigInt clientId,
    Uint8List signature,
    bool confirm,
  ) async {
    try {
      final url = '$_baseUrl/IAuthenticationService/UpdateAuthSessionWithMobileConfirmation/v1/';
      
      // Создаем protobuf сообщение вручную
      // message CAuthentication_UpdateAuthSessionWithMobileConfirmation_Request {
      //   optional int32 version = 1;
      //   optional uint64 client_id = 2;
      //   optional fixed64 steamid = 3;
      //   optional bytes signature = 4;
      //   optional bool confirm = 5;
      //   optional ESessionPersistence persistence = 6;
      // }
      
      final protobufData = BytesBuilder();
      
      // Field 1: version (int32)
      _writeProtobufField(protobufData, 1, 0, _encodeVarint(version));
      
      // Field 2: client_id (uint64)
      _writeProtobufField(protobufData, 2, 0, _encodeVarintBigInt(clientId));
      
      // Field 3: steamid (fixed64)
      _writeProtobufField(protobufData, 3, 1, _encodeFixed64(steamId));
      
      // Field 4: signature (bytes)
      _writeProtobufField(protobufData, 4, 2, signature);
      
      // Field 5: confirm (bool)
      _writeProtobufField(protobufData, 5, 0, Uint8List.fromList([confirm ? 1 : 0]));
      
      // Field 6: persistence (int32) - 1 = k_ESessionPersistence_Persistent
      _writeProtobufField(protobufData, 6, 0, _encodeVarint(1));
      
      final protobufBytes = protobufData.toBytes();
      final protobufBase64 = base64Encode(protobufBytes);
      
      DebugLogger.logWithTag('SteamQrAuth', 'Отправляем protobuf подтверждение:');
      DebugLogger.logWithTag('SteamQrAuth', '  version: $version');
      DebugLogger.logWithTag('SteamQrAuth', '  client_id: $clientId');
      DebugLogger.logWithTag('SteamQrAuth', '  steamid: $steamId');
      DebugLogger.logWithTag('SteamQrAuth', '  signature: ${base64Encode(signature)}');
      DebugLogger.logWithTag('SteamQrAuth', '  confirm: $confirm');
      DebugLogger.logWithTag('SteamQrAuth', '  persistence: 1');
      DebugLogger.logWithTag('SteamQrAuth', '  protobuf_bytes: ${protobufBytes.length} bytes');
      
      // Отправляем запрос с protobuf данными
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Steam/3.0 (Linux; Ubuntu 20.04)',
        },
        body: 'access_token=${Uri.encodeComponent(accessToken)}&input_protobuf_encoded=${Uri.encodeComponent(protobufBase64)}',
      );
      
      DebugLogger.logWithTag('SteamQrAuth', 'Ответ сервера: ${response.statusCode}');
      DebugLogger.logWithTag('SteamQrAuth', 'Тело ответа: ${response.body}');
      
      if (response.statusCode == 200) {
        // Успешный ответ
        return true;
      }
      
      return false;
    } catch (e) {
      DebugLogger.logWithTag('SteamQrAuth', 'Ошибка отправки подтверждения: $e');
      return false;
    }
  }

  /// Пишет protobuf поле в BytesBuilder
  static void _writeProtobufField(BytesBuilder builder, int fieldNumber, int wireType, Uint8List data) {
    // Wire type: 0 = Varint, 1 = 64-bit, 2 = Length-delimited, 5 = 32-bit
    final tag = (fieldNumber << 3) | wireType;
    builder.add(_encodeVarint(tag));
    
    if (wireType == 2) {
      // Length-delimited: добавляем длину перед данными
      builder.add(_encodeVarint(data.length));
    }
    
    builder.add(data);
  }

  /// Кодирует число в формат varint
  static Uint8List _encodeVarint(int value) {
    final bytes = <int>[];
    var n = value;
    
    while (n > 0x7F) {
      bytes.add((n & 0x7F) | 0x80);
      n >>= 7;
    }
    bytes.add(n & 0x7F);
    
    return Uint8List.fromList(bytes);
  }

  /// Кодирует BigInt в формат varint
  static Uint8List _encodeVarintBigInt(BigInt value) {
    final bytes = <int>[];
    var n = value;
    
    while (n > BigInt.from(0x7F)) {
      bytes.add(((n & BigInt.from(0x7F)) | BigInt.from(0x80)).toInt());
      n = n >> 7;
    }
    bytes.add((n & BigInt.from(0x7F)).toInt());
    
    return Uint8List.fromList(bytes);
  }

  /// Кодирует 64-битное число в формат fixed64 (little endian)
  static Uint8List _encodeFixed64(int value) {
    final bytes = Uint8List(8);
    for (int i = 0; i < 8; i++) {
      bytes[i] = (value >> (i * 8)) & 0xFF;
    }
    return bytes;
  }
}

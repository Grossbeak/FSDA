import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/pointycastle.dart';
import 'package:fixnum/fixnum.dart';
import '../generated/steam_auth.pb.dart';
import 'debug_logger.dart';

/// Protobuf-совместимая версия Steam аутентификации
class ProtobufSteamAuthService {
  static const String _baseUrl = 'https://api.steampowered.com';

  /// RSA шифрование пароля
  static String _encryptPassword(String password, String publicKeyMod, String publicKeyExp) {
    try {
      // Конвертируем hex строки в BigInt
      final modulus = BigInt.parse(publicKeyMod, radix: 16);
      final exponent = BigInt.parse(publicKeyExp, radix: 16);
      
      // Создаем RSA публичный ключ
      final rsaPublicKey = RSAPublicKey(modulus, exponent);
      
      // Создаем шифратор - используем PKCS1 как в Rust коде
      final cipher = AsymmetricBlockCipher('RSA/PKCS1');
      cipher.init(true, PublicKeyParameter<RSAPublicKey>(rsaPublicKey));
      
      // Шифруем пароль
      final passwordBytes = utf8.encode(password);
      final encrypted = cipher.process(Uint8List.fromList(passwordBytes));
      
      return base64Encode(encrypted);
    } catch (e) {
      DebugLogger.logWithTag('ProtobufSteamAuth', 'Ошибка RSA шифрования: $e');
      // Fallback к простому base64
      return base64Encode(utf8.encode(password));
    }
  }

  /// Генерирует код Steam Guard
  static String generateSteamGuardCode(String sharedSecret, int timestamp) {
    try {
      final key = base64Decode(sharedSecret);
      final timeBytes = _int64ToBigEndian(timestamp ~/ 30);
      
      final hmac = Hmac(sha1, key);
      final digest = hmac.convert(timeBytes);
      
      final bytes = digest.bytes;
      final offset = bytes.last & 0x0f;
      final truncatedHash = ((bytes[offset] & 0x7f) << 24) |
                          ((bytes[offset + 1] & 0xff) << 16) |
                          ((bytes[offset + 2] & 0xff) << 8) |
                          (bytes[offset + 3] & 0xff);
      
      const charset = '23456789BCDFGHJKMNPQRTVWXY';
      String code = '';
      int hash = truncatedHash;
      
      for (int i = 0; i < 5; i++) {
        code += charset[hash % charset.length];
        hash ~/= charset.length;
      }
      
      return code;
    } catch (e) {
      DebugLogger.logWithTag('ProtobufSteamAuth', 'Ошибка генерации кода: $e');
      return 'ERROR';
    }
  }

  static Uint8List _int64ToBigEndian(int value) {
    final bytes = ByteData(8);
    bytes.setUint64(0, value, Endian.big);
    return bytes.buffer.asUint8List();
  }

  /// Полная авторизация в Steam с использованием protobuf
  static Future<Map<String, dynamic>> authenticateWithSteam({
    required String username,
    required String password,
    required String sharedSecret,
  }) async {
    try {
      DebugLogger.logWithTag('ProtobufSteamAuth', 'Начинаем protobuf авторизацию для: $username');

      // 1. Получаем RSA ключ
      final rsaUrl = '$_baseUrl/IAuthenticationService/GetPasswordRSAPublicKey/v1/?account_name=$username';
      final rsaResponse = await http.get(Uri.parse(rsaUrl));
      
      if (rsaResponse.statusCode != 200) {
        throw Exception('Ошибка получения RSA ключа: ${rsaResponse.statusCode}');
      }
      
      final rsaData = jsonDecode(rsaResponse.body);
      final publicKeyMod = rsaData['response']['publickey_mod'];
      final publicKeyExp = rsaData['response']['publickey_exp'];
      final timestamp = int.parse(rsaData['response']['timestamp'].toString()); // Парсим как int для protobuf
      
      DebugLogger.logWithTag('ProtobufSteamAuth', 'RSA ключ получен, timestamp: $timestamp');

      // 2. Шифруем пароль с помощью RSA
      final encryptedPassword = _encryptPassword(password, publicKeyMod, publicKeyExp);
      DebugLogger.logWithTag('ProtobufSteamAuth', 'Пароль зашифрован');

      // 3. Создаем protobuf запрос
      final request = CAuthentication_BeginAuthSessionViaCredentials_Request();
      request.accountName = username;
      request.encryptedPassword = encryptedPassword;
      request.encryptionTimestamp = Int64(timestamp);
      request.persistence = ESessionPersistence.k_ESessionPersistence_Persistent;
      request.websiteId = 'Mobile';
      request.deviceFriendlyName = '${Platform.localHostname} (fsda-protobuf)';
      request.platformType = EAuthTokenPlatformType.k_EAuthTokenPlatformType_MobileApp;
      request.language = 0;
      request.qosLevel = 2;

      // Создаем device details
      final deviceDetails = CAuthentication_DeviceDetails();
      deviceDetails.deviceFriendlyName = '${Platform.localHostname} (fsda-protobuf)';
      deviceDetails.platformType = EAuthTokenPlatformType.k_EAuthTokenPlatformType_MobileApp;
      deviceDetails.osType = -500; // Linux
      deviceDetails.gamingDeviceType = 528;
      request.deviceDetails = deviceDetails;

      // 4. Отправляем запрос как в Rust коде
      final authUrl = '$_baseUrl/IAuthenticationService/BeginAuthSessionViaCredentials/v1';
      
      final jsonRequest = {
        'account_name': username,
        'encrypted_password': encryptedPassword,
        'encryption_timestamp': timestamp,
        'persistence': 1,
        'platform_type': 3,
        'device_friendly_name': 'FSDA',
        'os_type': 1,
        'gaming_device_type': 0,
        'language': 0,
        'qos_level': 2,
        'website_id': 'Unknown',
        'remember_login': false,
      };
      
          DebugLogger.logWithTag('ProtobufSteamAuth', 'Отправляем запрос как в Rust: $jsonRequest');
      
      final authResponse = await http.post(
        Uri.parse(authUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Steam/3.0 (Linux; Ubuntu 20.04)',
        },
        body: 'input_json=${Uri.encodeComponent(jsonEncode(jsonRequest))}',
      );
      
      DebugLogger.logWithTag('ProtobufSteamAuth', 'Ответ авторизации: ${authResponse.statusCode} (${authResponse.bodyBytes.length} байт)');
      DebugLogger.logWithTag('ProtobufSteamAuth', 'Сырой ответ: ${authResponse.body}');
      
      if (authResponse.statusCode != 200) {
        throw Exception('Ошибка авторизации: ${authResponse.statusCode} - ${authResponse.body}');
      }

      // 5. Парсим JSON ответ как в Rust коде
      final jsonResponse = jsonDecode(authResponse.body);
      DebugLogger.logWithTag('ProtobufSteamAuth', 'JSON ответ: $jsonResponse');
      
      if (jsonResponse['response'] == null || jsonResponse['response'].isEmpty) {
        throw Exception('Авторизация не удалась: пустой ответ');
      }
      
      final response = jsonResponse['response'];
      
      // Проверяем, есть ли allowed_confirmations (2FA требуется) как в Rust
      if (response['allowed_confirmations'] != null && 
          response['allowed_confirmations'] is List && 
          (response['allowed_confirmations'] as List).isNotEmpty) {
        
        DebugLogger.logWithTag('ProtobufSteamAuth', '2FA требуется, обрабатываем...');
        
        final clientId = response['client_id'] ?? '';
        final requestId = response['request_id'] ?? '';
        final steamid = response['steamid'] ?? '';
        
        if (clientId.isEmpty) {
          throw Exception('Авторизация не удалась: отсутствует client_id');
        }
        
        DebugLogger.logWithTag('ProtobufSteamAuth', 'Авторизация успешна, client_id: $clientId');
        DebugLogger.logWithTag('ProtobufSteamAuth', 'SteamID: $steamid');

        // 6. Генерируем и отправляем 2FA код
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final twofactorCode = generateSteamGuardCode(sharedSecret, currentTime);
      
      DebugLogger.logWithTag('ProtobufSteamAuth', 'Сгенерирован 2FA код: $twofactorCode');
      
      final updateRequest = {
        'client_id': clientId,
        'steamid': steamid,
        'code': twofactorCode,
        'code_type': 3, // EAuthSessionGuardType_DeviceCode
      };
      
      final updateResponse = await http.post(
        Uri.parse('$_baseUrl/IAuthenticationService/UpdateAuthSessionWithSteamGuardCode/v1'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Steam/3.0 (Linux; Ubuntu 20.04)',
        },
        body: 'input_json=${Uri.encodeComponent(jsonEncode(updateRequest))}',
      );
      
      DebugLogger.logWithTag('ProtobufSteamAuth', 'Ответ 2FA: ${updateResponse.statusCode} - ${updateResponse.body}');
      
      if (updateResponse.statusCode != 200) {
        throw Exception('Ошибка отправки 2FA: ${updateResponse.statusCode}');
      }
      
            final updateResult = jsonDecode(updateResponse.body);
            
            // Проверяем успешность 2FA - если есть agreement_session_url (даже пустая), значит принято
            if (updateResult['response']['agreement_session_url'] == null) {
              throw Exception('2FA не принят: ${updateResult['response']}');
            }

      // 7. Получаем токены
      final pollRequest = {
        'client_id': clientId,
        'request_id': requestId,
      };
      
      final pollResponse = await http.post(
        Uri.parse('$_baseUrl/IAuthenticationService/PollAuthSessionStatus/v1'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Steam/3.0 (Linux; Ubuntu 20.04)',
        },
        body: 'input_json=${Uri.encodeComponent(jsonEncode(pollRequest))}',
      );
      
      DebugLogger.logWithTag('ProtobufSteamAuth', 'Ответ polling: ${pollResponse.statusCode} - ${pollResponse.body}');
      
      if (pollResponse.statusCode != 200) {
        throw Exception('Ошибка получения токенов: ${pollResponse.statusCode}');
      }

      final pollResult = jsonDecode(pollResponse.body);
      
      if (pollResult['response']['access_token'] == null || pollResult['response']['access_token'].isEmpty) {
        throw Exception('Получение токенов не удалось: пустой access_token');
      }
      
      final accessToken = pollResult['response']['access_token'];
      final refreshToken = pollResult['response']['refresh_token'] ?? '';
      final accountName = pollResult['response']['account_name'] ?? username;
      final weakToken = pollResult['response']['weak_token'] ?? '';
      // steamid уже определен выше из BeginAuthSessionViaCredentials ответа
      
      DebugLogger.logWithTag('ProtobufSteamAuth', 'Токены получены успешно');
      
      // Создаем webCookie как в SDA-CLI
      final webCookie = 'steamLoginSecure=$steamid||$accessToken';
      DebugLogger.logWithTag('ProtobufSteamAuth', 'Создан webCookie: $webCookie');
      
        return {
          'success': true,
          'access_token': accessToken,
          'refresh_token': refreshToken,
          'steamid': steamid.toString(),
          'account_name': accountName,
          'weak_token': weakToken,
          'webCookie': webCookie,
          'message': 'Авторизация успешна'
        };
        
            } else {
              // Проверяем на rate limiting если нет 2FA
              if (response['interval'] != null) {
                final interval = response['interval'];
                final errorMessage = response['extended_error_message'] ?? '';
                throw Exception('Steam ограничивает попытки входа. Интервал: ${interval} секунд. Сообщение: $errorMessage');
              }
              
              // Если нет 2FA, проверяем есть ли токены как в Rust коде
              if (response['access_token'] != null) {
          DebugLogger.logWithTag('ProtobufSteamAuth', 'Токены получены без 2FA');
          
          final accessToken = response['access_token'];
          final refreshToken = response['refresh_token'] ?? '';
          final steamid = response['steamid'] ?? '';
          final accountName = response['account_name'] ?? username;
          final weakToken = response['weak_token'] ?? '';
          
          final webCookie = 'steamLoginSecure=$steamid||$accessToken';
          
          return {
            'success': true,
            'access_token': accessToken,
            'refresh_token': refreshToken,
            'steamid': steamid.toString(),
            'account_name': accountName,
            'weak_token': weakToken,
            'webCookie': webCookie,
            'message': 'Авторизация успешна без 2FA'
          };
        }
      }
      
      // Если дошли сюда, что-то пошло не так
      throw Exception('Неожиданный формат ответа: $jsonResponse');
      
    } catch (e) {
      DebugLogger.logWithTag('ProtobufSteamAuth', 'Ошибка авторизации: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart';
import 'debug_logger.dart';

class SteamProtobufAuth {
  static const String _baseUrl = 'https://api.steampowered.com';
  static const String _serviceName = 'IAuthenticationService';

  /// Начинает сессию авторизации через учетные данные (как в SDA-CLI)
  static Future<Map<String, dynamic>> beginAuthSessionViaCredentials(
    String username,
    String password,
  ) async {
    try {
      DebugLogger.logWithTag('Protobuf', 'Начинаем protobuf авторизацию для: $username');

      // 1. Получаем RSA ключ
      final rsaKey = await _getRSAKey(username);
      if (rsaKey == null) {
        return {'success': false, 'error': 'Не удалось получить RSA ключ'};
      }

      DebugLogger.logWithTag('Protobuf', 'RSA ключ получен');

      // 2. Шифруем пароль
      final encryptedPassword = _encryptPasswordRSA(
        password,
        rsaKey['modulus'],
        rsaKey['exponent'],
      );

      DebugLogger.logWithTag('Protobuf', 'Пароль зашифрован');

      // 3. Создаем protobuf запрос BeginAuthSessionViaCredentials
      final requestData = {
        'account_name': username,
        'encrypted_password': encryptedPassword,
        'encryption_timestamp': rsaKey['timestamp'],
        'persistence': 1, // k_ESessionPersistence_Persistent
        'platform_type': 3, // k_EAuthTokenPlatformType_MobileApp
        'device_details': {
          'device_friendly_name': 'FSDA',
          'platform_type': 3,
          'os_type': 1, // Linux
          'gaming_device_type': 0,
        },
        'language': 0, // English
        'qos_level': 2,
      };

      // 4. Отправляем запрос через POST с input_json
      final response = await http.post(
        Uri.parse('$_baseUrl/$_serviceName/BeginAuthSessionViaCredentials/v1'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Steam/3.0 (Linux; Ubuntu 20.04)',
        },
        body: {
          'input_json': json.encode(requestData),
        },
      );

      DebugLogger.logWithTag('Protobuf', 'BeginAuthSession ответ: ${response.statusCode}');
      DebugLogger.logWithTag('Protobuf', 'BeginAuthSession тело: ${response.body}');

      if (response.statusCode != 200) {
        return {'success': false, 'error': 'Ошибка BeginAuthSession: ${response.statusCode}'};
      }

      // 5. Парсим ответ
      final responseData = json.decode(response.body);
      
      if (responseData['response'] == null) {
        return {'success': false, 'error': 'Некорректный ответ от Steam'};
      }

      final authResponse = responseData['response'];
      
      // Проверяем, требует ли Steam 2FA
      if (authResponse['allowed_confirmations'] != null) {
        final confirmations = authResponse['allowed_confirmations'] as List;
        final hasDeviceCode = confirmations.any((c) => c['confirmation_type'] == 1); // k_EAuthSessionGuardType_DeviceCode
        
        if (hasDeviceCode) {
          DebugLogger.logWithTag('Protobuf', 'Steam требует 2FA через устройство');
          return {
            'success': false,
            'requires_twofactor': true,
            'client_id': authResponse['client_id'],
            'steamid': authResponse['steamid'],
            'request_id': authResponse['request_id'],
          };
        }
      }

      // Если Steam вернул client_id и steamid, но есть allowed_confirmations, это означает 2FA
      if (authResponse['client_id'] != null && authResponse['steamid'] != null) {
        if (authResponse['allowed_confirmations'] != null && authResponse['allowed_confirmations'].isNotEmpty) {
          DebugLogger.logWithTag('Protobuf', 'Steam требует 2FA через устройство');
          return {
            'success': false,
            'requires_twofactor': true,
            'client_id': authResponse['client_id'],
            'steamid': authResponse['steamid'],
            'request_id': authResponse['request_id'],
          };
        } else {
          // Нет 2FA, но есть interval - нужно опросить статус
          DebugLogger.logWithTag('Protobuf', 'Нет 2FA, опрашиваем статус для получения токенов');
          return await pollAuthSessionStatus(authResponse['client_id'], authResponse['steamid']);
        }
      }

      // Если нет client_id и steamid, возвращаем ошибку
      return {
        'success': false,
        'error': 'Steam не вернул client_id и steamid',
      };

    } catch (e, stackTrace) {
      DebugLogger.logWithTag('Error', 'Исключение в protobuf авторизации: $e');
      DebugLogger.logWithTag('Error', 'Stack trace: $stackTrace');
      return {'success': false, 'error': 'Исключение: $e'};
    }
  }

  /// Опрашивает статус авторизации для получения токенов
  static Future<Map<String, dynamic>> pollAuthSessionStatus(dynamic clientId, dynamic steamId) async {
    try {
      DebugLogger.logWithTag('Protobuf', 'Опрашиваем статус авторизации: clientId=$clientId, steamId=$steamId');

      final requestData = {
        'client_id': int.tryParse(clientId.toString()) ?? clientId,
        'steamid': int.tryParse(steamId.toString()) ?? steamId,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/$_serviceName/PollAuthSessionStatus/v1'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Steam/3.0 (Linux; Ubuntu 20.04)',
        },
        body: {
          'input_json': json.encode(requestData),
        },
      );

      DebugLogger.logWithTag('Protobuf', 'PollAuthSessionStatus ответ: ${response.statusCode}');
      DebugLogger.logWithTag('Protobuf', 'PollAuthSessionStatus тело: ${response.body}');

      if (response.statusCode != 200) {
        return {'success': false, 'error': 'Ошибка PollAuthSessionStatus: ${response.statusCode}'};
      }

      final responseData = json.decode(response.body);
      final authResponse = responseData['response'];

      if (authResponse == null) {
        return {'success': false, 'error': 'Неверный ответ PollAuthSessionStatus'};
      }

      if (authResponse['access_token'] != null) {
        // Успешная авторизация
        return {
          'success': true,
          'access_token': authResponse['access_token'],
          'refresh_token': authResponse['refresh_token'],
          'steamid': authResponse['steamid'],
          'account_name': authResponse['account_name'],
        };
      } else if (authResponse['allowed_confirmations'] != null && authResponse['allowed_confirmations'].isNotEmpty) {
        // Требуется 2FA
        return {
          'success': false,
          'requires_twofactor': true,
          'client_id': clientId,
          'steamid': steamId,
          'request_id': authResponse['request_id'],
        };
      } else {
        return {'success': false, 'error': authResponse['extended_error_message'] ?? 'Неизвестная ошибка PollAuthSessionStatus'};
      }
    } catch (e, stackTrace) {
      DebugLogger.logWithTag('Error', 'Исключение в PollAuthSessionStatus: $e');
      DebugLogger.logWithTag('Error', 'Stack trace: $stackTrace');
      return {'success': false, 'error': 'Исключение: $e'};
    }
  }

  /// Отправляет код 2FA через protobuf API (как в SDA-CLI)
  static Future<Map<String, dynamic>> submitSteamGuardCode(
    String code,
    dynamic clientId,
    dynamic steamId,
  ) async {
    try {
      DebugLogger.logWithTag('Protobuf', 'Отправляем код 2FA через protobuf: $code');
      DebugLogger.logWithTag('Protobuf', 'Client ID: $clientId, Steam ID: $steamId');

      final requestData = {
        'client_id': int.tryParse(clientId.toString()) ?? clientId,
        'steamid': int.tryParse(steamId.toString()) ?? steamId,
        'code': code,
        'code_type': 1, // k_EAuthSessionGuardType_DeviceCode
      };

      // Используем JSON API как альтернативу protobuf
      final response = await http.post(
        Uri.parse('$_baseUrl/$_serviceName/UpdateAuthSessionWithSteamGuardCode/v1'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Steam/3.0 (Linux; Ubuntu 20.04)',
        },
        body: {
          'input_json': json.encode(requestData),
        },
      );

      DebugLogger.logWithTag('Protobuf', '2FA Response Status: ${response.statusCode}');
      DebugLogger.logWithTag('Protobuf', '2FA Response Body: ${response.body}');

      if (response.statusCode != 200) {
        return {'success': false, 'error': 'Ошибка отправки 2FA: ${response.statusCode}'};
      }

      final responseData = json.decode(response.body);
      
      if (responseData['response'] != null) {
        return {'success': true, 'response': responseData['response']};
      } else {
        return {'success': false, 'error': 'Steam отклонил код 2FA'};
      }

    } catch (e, stackTrace) {
      DebugLogger.logWithTag('Error', 'Исключение при отправке 2FA: $e');
      DebugLogger.logWithTag('Error', 'Stack trace: $stackTrace');
      return {'success': false, 'error': 'Исключение: $e'};
    }
  }

  /// Получает RSA ключ через protobuf API
  static Future<Map<String, dynamic>?> _getRSAKey(String username) async {
    try {
      DebugLogger.logWithTag('Protobuf', 'Получаем RSA ключ для: $username');

      final requestData = {
        'account_name': username,
      };

      final response = await http.get(
        Uri.parse('$_baseUrl/$_serviceName/GetPasswordRSAPublicKey/v1?input_json=${Uri.encodeComponent(json.encode(requestData))}'),
        headers: {
          'User-Agent': 'Steam/3.0 (Linux; Ubuntu 20.04)',
        },
      );

      DebugLogger.logWithTag('Protobuf', 'RSA Response Status: ${response.statusCode}');
      DebugLogger.logWithTag('Protobuf', 'RSA Response Body: ${response.body}');

      if (response.statusCode != 200) {
        return null;
      }

      final responseData = json.decode(response.body);
      
      if (responseData['response'] != null) {
        final rsaResponse = responseData['response'];
        return {
          'modulus': rsaResponse['publickey_mod'],
          'exponent': rsaResponse['publickey_exp'],
          'timestamp': rsaResponse['timestamp'],
        };
      }

      return null;
    } catch (e) {
      DebugLogger.logWithTag('Error', 'Ошибка получения RSA ключа: $e');
      return null;
    }
  }

  static String _encryptPasswordRSA(String password, String modulus, String exponent) {
    try {
      DebugLogger.logWithTag('ProtobufRSA', 'PointyCastle RSA Encryption Debug:');
      DebugLogger.logWithTag('ProtobufRSA', 'Password: $password');
      DebugLogger.logWithTag('ProtobufRSA', 'Password length: ${password.length}');
      DebugLogger.logWithTag('ProtobufRSA', 'Modulus length: ${modulus.length}');
      DebugLogger.logWithTag('ProtobufRSA', 'Exponent: $exponent');
      
      // Конвертируем hex строки в BigInt
      final modulusBigInt = BigInt.parse(modulus, radix: 16);
      final exponentBigInt = BigInt.parse(exponent, radix: 16);
      
      // Создаем RSA публичный ключ
      final rsaPublicKey = RSAPublicKey(modulusBigInt, exponentBigInt);
      
      // Создаем RSA engine
      final rsaEngine = RSAEngine();
      rsaEngine.init(true, PublicKeyParameter<RSAPublicKey>(rsaPublicKey));
      
      // Шифруем пароль
      final passwordBytes = utf8.encode(password);
      final encryptedBytes = rsaEngine.process(passwordBytes);
      
      // Конвертируем в hex строку
      final result = encryptedBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
      
      DebugLogger.logWithTag('ProtobufRSA', 'PointyCastle RSA result length: ${result.length}');
      DebugLogger.logWithTag('ProtobufRSA', 'PointyCastle RSA result: ${result.substring(0, 50)}...');
      
      return result;
    } catch (e) {
      DebugLogger.logWithTag('Error', 'PointyCastle RSA Encryption Error: $e');
      return '';
    }
  }
}

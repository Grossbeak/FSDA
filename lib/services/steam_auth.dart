import 'dart:convert';
import 'package:http/http.dart' as http;
import 'debug_logger.dart';
import 'steam_protobuf_auth.dart';
import 'secure_token_manager.dart';
import 'protobuf_steam_auth.dart';

class SteamAuthService {
  static Future<Map<String, dynamic>> submit2FACode(String username, String code, Map<String, String> cookies) async {
    try {
      DebugLogger.logWithTag('Steam', 'Отправляем код 2FA: $code');
      DebugLogger.logWithTag('Steam', 'Username: $username');
      DebugLogger.logWithTag('Steam', 'Cookies: $cookies');
      
      DebugLogger.logWithTag('HTTP', 'Отправляем HTTP POST запрос...');
          final response = await http.post(
            Uri.parse('https://steamcommunity.com/login/dologin/'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Accept': 'application/json, text/javascript, */*; q=0.01',
              'Accept-Language': 'en-US,en;q=0.9',
              'Accept-Encoding': 'gzip, deflate, br',
              'DNT': '1',
              'Connection': 'keep-alive',
              'Origin': 'https://steamcommunity.com',
              'Referer': 'https://steamcommunity.com/login/',
              'Cookie': cookies.entries.map((e) => '${e.key}=${e.value}').join('; '),
              'X-Requested-With': 'XMLHttpRequest',
            },
            body: {
              'username': username,
              'twofactorcode': code,
              'donotcache': DateTime.now().millisecondsSinceEpoch.toString(),
              'loginfriendlyname': 'FSDA',
              'captchagid': '',
              'captcha_text': '',
              'emailauth': '',
              'emailsteamid': '',
              'rsatimestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            },
          );

      DebugLogger.logWithTag('HTTP', 'HTTP POST запрос отправлен');
      DebugLogger.logWithTag('HTTP', '2FA Response Status: ${response.statusCode}');
      DebugLogger.logWithTag('HTTP', '2FA Response Body: ${response.body}');

      if (response.statusCode != 200) {
        return {'success': false, 'error': 'Ошибка отправки кода 2FA: ${response.statusCode}'};
      }

      final responseData = json.decode(response.body);
      DebugLogger.logWithTag('Steam', '2FA Response Data: $responseData');

      if (responseData['success'] == true) {
        // Успешная авторизация
        return {
          'success': true,
          'sessionId': responseData['sessionid'],
          'steamLoginSecure': responseData['steamLoginSecure'],
          'cookies': responseData,
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? 'Неизвестная ошибка 2FA',
        };
      }
    } catch (e, stackTrace) {
      DebugLogger.logWithTag('Error', 'Исключение при отправке 2FA: $e');
      DebugLogger.logWithTag('Error', 'Stack trace: $stackTrace');
      return {'success': false, 'error': 'Исключение: $e'};
    }
  }

  /// Новая функция для отправки 2FA кода через protobuf API
  static Future<Map<String, dynamic>> submit2FACodeProtobuf(
    String code,
    int clientId,
    int steamId,
  ) async {
    try {
      DebugLogger.logWithTag('Protobuf', 'Отправляем код 2FA через protobuf: $code');
      return await SteamProtobufAuth.submitSteamGuardCode(code, clientId, steamId);
    } catch (e) {
      DebugLogger.logWithTag('Error', 'Исключение при отправке 2FA через protobuf: $e');
      return {'success': false, 'error': 'Исключение: $e'};
    }
  }

  /// Попытка авторизации с сохраненными токенами
  static Future<Map<String, dynamic>?> loginWithSavedTokens() async {
    try {
      DebugLogger.logWithTag('Steam', 'Попытка авторизации с сохраненными токенами');
      
      // Проверяем, есть ли сохраненные токены
          final tokens = await SecureTokenManager.loadTokens();
      if (tokens == null) {
        DebugLogger.logWithTag('Steam', 'Сохраненные токены не найдены');
        return null;
      }
      
      // Проверяем валидность токенов
          final isValid = await SecureTokenManager.areTokensValid();
      if (!isValid) {
        DebugLogger.logWithTag('Steam', 'Сохраненные токены недействительны (истекли)');
        await SecureTokenManager.clearTokens();
        return null;
      }
      
      DebugLogger.logWithTag('Steam', 'Сохраненные токены действительны');
      
      DebugLogger.logWithTag('Steam', 'Используем сохраненные токены для аккаунта: ${tokens['account_name']}');
      
      // Создаем webCookie из сохраненных токенов
      final steamId = tokens['steamid']!;
      final accessToken = tokens['access_token']!;
      final webCookie = 'steamLoginSecure=$steamId||$accessToken';
      
      return {
        'success': true,
        'access_token': tokens['access_token'],
        'refresh_token': tokens['refresh_token'],
        'steamid': tokens['steamid'],
        'account_name': tokens['account_name'],
        'weak_token': tokens['weak_token'],
        'webCookie': webCookie,
        'from_cache': true, // Помечаем, что данные из кеша
      };
    } catch (e) {
      DebugLogger.logWithTag('Error', 'Ошибка при использовании сохраненных токенов: $e');
      return null;
    }
  }

  /// Полная авторизация с паролем (как раньше)
  static Future<Map<String, dynamic>?> login({
    required String username,
    required String password,
    required String sharedSecret,
  }) async {
    try {
      DebugLogger.logWithTag('Steam', 'Начинаем полную авторизацию для пользователя: $username');

      // Используем protobuf авторизацию как в SDA-CLI
      DebugLogger.logWithTag('Steam', 'Используем protobuf авторизацию');
      final result = await ProtobufSteamAuthService.authenticateWithSteam(
        username: username,
        password: password,
        sharedSecret: sharedSecret,
      );
      
      DebugLogger.logWithTag('Steam', 'Dart авторизация результат: $result');
      
      if (result['success'] == true) {
        // Сохраняем токены для будущего использования
        final expiryTime = _extractExpiryTime(result['access_token']);
        DebugLogger.logWithTag('Steam', 'Сохраняем токены: expiryTime=$expiryTime');
        await SecureTokenManager.saveTokens(
          accessToken: result['access_token'],
          refreshToken: result['refresh_token'],
          steamId: result['steamid'],
          accountName: result['account_name'],
          weakToken: result['weak_token'] ?? '',
          expiryTime: expiryTime,
        );
        DebugLogger.logWithTag('Steam', 'Токены успешно сохранены');
        
        return {
          'success': true,
          'access_token': result['access_token'],
          'refresh_token': result['refresh_token'],
          'steamid': result['steamid'],
          'account_name': result['account_name'],
          'weak_token': result['weak_token'],
          'webCookie': result['webCookie'],
          'from_cache': false, // Помечаем, что данные свежие
        };
      } else {
        // Ошибка авторизации
        return result;
      }
    } catch (e) {
      DebugLogger.logWithTag('Error', 'Исключение в процессе авторизации: $e');
      return {'success': false, 'error': 'Исключение: $e'};
    }
  }

  /// Извлекает время истечения токена из JWT
  static int _extractExpiryTime(String accessToken) {
    try {
      // JWT токен состоит из трех частей, разделенных точками
      final parts = accessToken.split('.');
      if (parts.length != 3) {
        DebugLogger.logWithTag('Steam', 'Неверный формат JWT токена');
        return DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600; // По умолчанию 1 час
      }
      
      // Декодируем payload (вторая часть)
      final payload = parts[1];
      // Добавляем padding если нужно
      final paddedPayload = payload.padRight((payload.length + 3) & ~3, '=');
      final decodedPayload = utf8.decode(base64.decode(paddedPayload));
      final payloadJson = json.decode(decodedPayload);
      
      final expiry = payloadJson['exp'] as int?;
      if (expiry != null) {
        DebugLogger.logWithTag('Steam', 'Токен истекает: ${DateTime.fromMillisecondsSinceEpoch(expiry * 1000)}');
        return expiry;
      }
      
      DebugLogger.logWithTag('Steam', 'Не удалось извлечь время истечения из токена');
      return DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600; // По умолчанию 1 час
    } catch (e) {
      DebugLogger.logWithTag('Error', 'Ошибка извлечения времени истечения: $e');
      return DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600; // По умолчанию 1 час
    }
  }

  static Future<Map<String, dynamic>?> loginMobile({
    required String username,
    required String password,
    required String sharedSecret,
  }) async {
    try {
      // Используем protobuf API для мобильной авторизации
      return await login(username: username, password: password, sharedSecret: sharedSecret);
    } catch (e) {
      return {'success': false, 'error': 'Исключение в мобильной авторизации: $e'};
    }
  }

  static Future<Map<String, dynamic>?> checkLoginStatus({
    required String sessionId,
    required String steamLoginSecure,
  }) async {
    try {
      // Проверяем статус логина через cookies
      final response = await http.get(
        Uri.parse('https://steamcommunity.com/my/'),
        headers: {
          'Cookie': 'sessionid=$sessionId; steamLoginSecure=$steamLoginSecure',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200 && response.body.contains('steamid')) {
        return {'success': true, 'status': 'logged_in'};
      } else {
        return {'success': false, 'status': 'not_logged_in'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Исключение: $e'};
    }
  }

  static Future<Map<String, dynamic>?> getSessionData({
    required String sessionId,
    required String steamLoginSecure,
  }) async {
    try {
      // Получаем данные сессии
      return {
        'success': true,
        'sessionId': sessionId,
        'steamLoginSecure': steamLoginSecure,
        'deviceId': _generateDeviceId(),
      };
    } catch (e) {
      return {'success': false, 'error': 'Исключение: $e'};
    }
  }

  static String _generateDeviceId() {
    // Генерируем уникальный device ID
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 1000000).toString().padLeft(6, '0');
    return 'android:$random';
  }
}

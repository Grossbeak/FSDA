import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;
import '../models/mafile.dart';
import 'debug_logger.dart';

class SteamConfirmationsService {
  /// Получает серверное время Steam (как в SDA-CLI)
  static Future<int> _getSteamServerTime() async {
    try {
      // Используем правильный формат запроса как в SDA-CLI
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final requestData = json.encode({
        'sender_time': currentTime,
      });
      
      final response = await http.post(
        Uri.parse('https://api.steampowered.com/ITwoFactorService/QueryTime/v1'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'steamguard-cli',
        },
        body: 'input_json=$requestData',
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final serverTime = data['response']?['server_time'];
        if (serverTime != null) {
          DebugLogger.logWithTag('Confirmations', 'Steam server time: $serverTime');
          return int.parse(serverTime.toString());
        }
      }
      
      DebugLogger.logWithTag('Confirmations', 'Failed to get Steam server time, using local time');
      return DateTime.now().millisecondsSinceEpoch ~/ 1000;
    } catch (e) {
      DebugLogger.logWithTag('Confirmations', 'Error getting Steam server time: $e, using local time');
      return DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }
  }

  static String _generateConfirmationHash({
    required String identitySecretBase64,
    required int timestamp,
    required String tag,
  }) {
    try {
      final secret = base64.decode(identitySecretBase64);
      
      // Создаем массив из 8 байт времени в big-endian формате
      final timeBytes = Uint8List(8);
      for (int i = 0; i < 8; i++) {
        timeBytes[7 - i] = (timestamp >> (i * 8)) & 0xFF;
      }
      
      // Создаем HMAC с временем и тегом
      final hmac = crypto.Hmac(crypto.sha1, secret);
      final data = Uint8List.fromList([...timeBytes, ...utf8.encode(tag)]);
      final digest = hmac.convert(data);
      
      final hash = base64.encode(digest.bytes);
      DebugLogger.logWithTag('Confirmations', 'Сгенерирован хеш: $hash (timestamp: $timestamp, tag: $tag)');
      return hash;
    } catch (e) {
      DebugLogger.logWithTag('Confirmations', 'Ошибка генерации хеша: $e');
      return '';
    }
  }

  static Future<List<ConfirmationItem>> getConfirmations({
    required String deviceId,
    required String steamId,
    required String identitySecret,
    required Map<String, String> cookies,
  }) async {
    try {
      DebugLogger.logWithTag('Confirmations', 'Начинаем загрузку подтверждений');
      DebugLogger.logWithTag('Confirmations', 'deviceId: $deviceId');
      DebugLogger.logWithTag('Confirmations', 'steamId: $steamId');
      DebugLogger.logWithTag('Confirmations', 'identitySecret: ${identitySecret.substring(0, 10)}...');
      DebugLogger.logWithTag('Confirmations', 'cookies: $cookies');
      
          // Получаем серверное время Steam (как в SDA-CLI)
          final int time = await _getSteamServerTime();
          final String tag = 'conf'; // Как в SDA-CLI
          final String k = _generateConfirmationHash(
            identitySecretBase64: identitySecret,
            timestamp: time,
            tag: tag,
          );
      
      DebugLogger.logWithTag('Confirmations', 'timestamp: $time');
      DebugLogger.logWithTag('Confirmations', 'hash: $k');
      
          final uri = Uri.https('steamcommunity.com', '/mobileconf/getlist', {
            'p': deviceId,
            'a': steamId,
            'k': k,
            't': time.toString(),
            'm': 'react', // Изменено с 'android' на 'react' как в SDA-CLI
            'tag': tag,
          });
      
      DebugLogger.logWithTag('Confirmations', 'URL: $uri');
      
      final cookieHeader = _cookieHeader(cookies);
      DebugLogger.logWithTag('Confirmations', 'Cookie header: $cookieHeader');
      
          final response = await http.get(uri, headers: {
            'Cookie': cookieHeader,
            'User-Agent': 'steamguard-cli', // Только User-Agent как в SDA-CLI
          });
      
      DebugLogger.logWithTag('Confirmations', 'Response status: ${response.statusCode}');
      DebugLogger.logWithTag('Confirmations', 'Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        DebugLogger.logWithTag('Confirmations', 'Parsed data: $data');
        
        // Проверяем needauth как в SDA-CLI
        final needAuth = data['needauth'] == true;
        DebugLogger.logWithTag('Confirmations', 'needauth: $needAuth');
        
        if (needAuth) {
          DebugLogger.logWithTag('Confirmations', 'Steam API error: Invalid tokens, login required');
          throw Exception('Steam API error: Invalid tokens, login required');
        }
        
        if (data['success'] == true) {
          final confirmations = List<Map<String, dynamic>>.from(data['conf'] ?? []);
          DebugLogger.logWithTag('Confirmations', 'Found ${confirmations.length} confirmations');
          return confirmations.map((conf) => ConfirmationItem.fromJson(conf)).toList();
        } else {
          final errorMsg = data['message'] ?? 'Unknown error';
          DebugLogger.logWithTag('Confirmations', 'Steam API error: $errorMsg');
          throw Exception('Steam API error: $errorMsg');
        }
      } else {
        DebugLogger.logWithTag('Confirmations', 'HTTP error: ${response.statusCode}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      DebugLogger.logWithTag('Confirmations', 'Exception: $e');
      throw Exception('Failed to fetch confirmations: $e');
    }
  }

  static Future<bool> acceptConfirmation({
    required String deviceId,
    required String steamId,
    required String identitySecret,
    required Map<String, String> cookies,
    required ConfirmationItem confirmation,
  }) async {
    return await _operateConfirmation(
      deviceId: deviceId,
      steamId: steamId,
      identitySecret: identitySecret,
      cookies: cookies,
      confirmation: confirmation,
      op: 'allow',
    );
  }

      static Future<bool> denyConfirmation({
        required String deviceId,
        required String steamId,
        required String identitySecret,
        required Map<String, String> cookies,
        required ConfirmationItem confirmation,
      }) async {
        return await _operateConfirmation(
          deviceId: deviceId,
          steamId: steamId,
          identitySecret: identitySecret,
          cookies: cookies,
          confirmation: confirmation,
          op: 'cancel', // Исправлено: SDA-CLI использует 'cancel' вместо 'deny'
        );
      }

  static Future<bool> _operateConfirmation({
    required String deviceId,
    required String steamId,
    required String identitySecret,
    required Map<String, String> cookies,
    required ConfirmationItem confirmation,
    required String op, // 'allow' | 'deny'
  }) async {
    try {
      DebugLogger.logWithTag('Confirmations', '=== ОПЕРАЦИЯ $op ===');
      DebugLogger.logWithTag('Confirmations', 'confirmation.id: ${confirmation.id}');
      DebugLogger.logWithTag('Confirmations', 'confirmation.nonce: ${confirmation.nonce}');
      DebugLogger.logWithTag('Confirmations', 'deviceId: $deviceId');
      DebugLogger.logWithTag('Confirmations', 'steamId: $steamId');
      DebugLogger.logWithTag('Confirmations', 'cookies: $cookies');
      
      // Получаем серверное время Steam (как в SDA-CLI)
      final int time = await _getSteamServerTime();
      final String tag = 'conf'; // Всегда используем 'conf' как в SDA-CLI
      final String k = _generateConfirmationHash(
        identitySecretBase64: identitySecret,
        timestamp: time,
        tag: tag,
      );
      
      DebugLogger.logWithTag('Confirmations', 'timestamp: $time');
      DebugLogger.logWithTag('Confirmations', 'tag: $tag');
      DebugLogger.logWithTag('Confirmations', 'hash: $k');
      
      final uri = Uri.https('steamcommunity.com', '/mobileconf/ajaxop', {
        'p': deviceId,        // 1. device_id
        'a': steamId,         // 2. steam_id
        'k': k,               // 3. hash
        't': time.toString(), // 4. time
        'm': 'react',         // 5. react
        'tag': tag,           // 6. conf
        'op': op,             // 7. operation
        'cid': confirmation.id,    // 8. confirmation id
        'ck': confirmation.nonce,  // 9. confirmation nonce
      });
      
      DebugLogger.logWithTag('Confirmations', 'URL: $uri');
      
      final cookieHeader = _cookieHeader(cookies);
      DebugLogger.logWithTag('Confirmations', 'Cookie header: $cookieHeader');
      
      final response = await http.get(uri, headers: {
        'Cookie': cookieHeader,
        'User-Agent': 'steamguard-cli', // Как в SDA-CLI
        'Origin': 'https://steamcommunity.com', // Как в SDA-CLI
      });
      
      DebugLogger.logWithTag('Confirmations', 'Response status: ${response.statusCode}');
      DebugLogger.logWithTag('Confirmations', 'Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        DebugLogger.logWithTag('Confirmations', 'Parsed response: $data');
        
        // Проверяем needsauth как в SDA-CLI
        final needsAuth = data['needsauth'] == true;
        DebugLogger.logWithTag('Confirmations', 'needsauth: $needsAuth');
        
        if (needsAuth) {
          DebugLogger.logWithTag('Confirmations', 'Steam API error: Invalid tokens, login required');
          throw Exception('Steam API error: Invalid tokens, login required');
        }
        
        final success = data['success'] == true;
        DebugLogger.logWithTag('Confirmations', 'Operation $op success: $success');
        
        if (!success) {
          final errorMsg = data['message'] ?? 'Unknown error';
          DebugLogger.logWithTag('Confirmations', 'Steam API error: $errorMsg');
          throw Exception('Steam API error: $errorMsg');
        }
        
        return success;
      } else {
        DebugLogger.logWithTag('Confirmations', 'HTTP error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      DebugLogger.logWithTag('Confirmations', 'Exception in $op: $e');
      return false;
    }
  }

  static String _cookieHeader(Map<String, String> cookies) {
    // Добавляем дополнительные cookies как в SDA-CLI
    final additionalCookies = <String>[];
    
    // Добавляем dob= (пустой, как в SDA-CLI)
    additionalCookies.add('dob=');
    
    // Добавляем steamid если есть
    if (cookies.containsKey('steamLoginSecure')) {
      final steamLoginSecure = cookies['steamLoginSecure']!;
      if (steamLoginSecure.contains('||')) {
        final steamId = steamLoginSecure.split('||')[0];
        additionalCookies.add('steamid=$steamId');
      }
    }
    
    // Добавляем все остальные cookies
    additionalCookies.addAll(cookies.entries.map((e) => '${e.key}=${e.value}'));
    
    return additionalCookies.join('; ');
  }
}




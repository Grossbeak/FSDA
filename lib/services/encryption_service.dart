import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'debug_logger.dart';

class EncryptionService {
  static const String _keyPrefix = 'fsda_encrypted_';
  static String? _cachedKey; // Кешируем ключ
  
  /// Генерирует ключ шифрования на основе уникального идентификатора устройства
  static Future<String> _generateEncryptionKey() async {
    try {
      // Используем детерминированные данные для генерации ключа
      // Это обеспечит одинаковый ключ при каждом запуске
      final deviceInfo = Platform.operatingSystem;
      final hostname = Platform.localHostname;
      final username = Platform.environment['USER'] ?? Platform.environment['USERNAME'] ?? 'default';
      
      // Создаем базовую строку для хеширования (детерминированную)
      final baseString = 'fsda_$deviceInfo$hostname$username';
      
      // Генерируем SHA-256 хеш
      final bytes = utf8.encode(baseString);
      final digest = sha256.convert(bytes);
      
      // Берем первые 32 символа для AES ключа
      final key = digest.toString().substring(0, 32);
      
      DebugLogger.logWithTag('Encryption', 'Сгенерирован детерминированный ключ: ${key.substring(0, 8)}...');
      DebugLogger.logWithTag('Encryption', 'На основе: $deviceInfo, $hostname, $username');
      return key;
    } catch (e) {
      DebugLogger.logWithTag('Encryption', 'Ошибка генерации ключа: $e');
      // Fallback ключ (детерминированный)
      return 'fsda_default_key_32_chars_long!';
    }
  }

  /// Получает или создает ключ шифрования
  static Future<String> _getEncryptionKey() async {
    // Возвращаем кешированный ключ, если он есть
    if (_cachedKey != null) {
      return _cachedKey!;
    }
    
    // Генерируем новый ключ и кешируем его
    _cachedKey = await _generateEncryptionKey();
    return _cachedKey!;
  }

  /// Шифрует строку
  static Future<String> encryptString(String plaintext) async {
    try {
      if (plaintext.isEmpty) return plaintext;
      
      final key = await _getEncryptionKey();
      final encrypter = Encrypter(AES(Key.fromBase64(base64.encode(utf8.encode(key)))));
      final iv = IV.fromLength(16);
      
      final encrypted = encrypter.encrypt(plaintext, iv: iv);
      final result = '${iv.base64}:${encrypted.base64}';
      
      DebugLogger.logWithTag('Encryption', 'Строка зашифрована (${plaintext.length} -> ${result.length} символов)');
      return result;
    } catch (e) {
      DebugLogger.logWithTag('Encryption', 'Ошибка шифрования: $e');
      return plaintext; // Возвращаем исходную строку при ошибке
    }
  }

  /// Расшифровывает строку
  static Future<String> decryptString(String encryptedText) async {
    try {
      if (encryptedText.isEmpty || !encryptedText.contains(':')) {
        return encryptedText; // Возможно, это незашифрованная строка
      }
      
      final key = await _getEncryptionKey();
      final encrypter = Encrypter(AES(Key.fromBase64(base64.encode(utf8.encode(key)))));
      
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        DebugLogger.logWithTag('Encryption', 'Неверный формат зашифрованной строки');
        return encryptedText;
      }
      
      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);
      
      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      
      DebugLogger.logWithTag('Encryption', 'Строка расшифрована (${encryptedText.length} -> ${decrypted.length} символов)');
      return decrypted;
    } catch (e) {
      DebugLogger.logWithTag('Encryption', 'Ошибка расшифровки: $e');
      return encryptedText; // Возвращаем исходную строку при ошибке
    }
  }

  /// Проверяет, является ли строка зашифрованной
  static bool isEncrypted(String text) {
    return text.startsWith(_keyPrefix) || text.contains(':') && text.split(':').length == 2;
  }

  /// Шифрует данные для сохранения
  static Future<Map<String, String>> encryptData(Map<String, String> data) async {
    final encryptedData = <String, String>{};
    
    for (final entry in data.entries) {
      // Шифруем все значения, включая пустые строки
      final encrypted = await encryptString(entry.value);
      encryptedData['$_keyPrefix${entry.key}'] = encrypted;
      DebugLogger.logWithTag('Encryption', 'Зашифровано поле ${entry.key}: ${entry.value.isNotEmpty ? '${entry.value.length} символов' : 'пустая строка'}');
    }
    
    DebugLogger.logWithTag('Encryption', 'Зашифровано ${encryptedData.length} полей');
    return encryptedData;
  }

  /// Расшифровывает данные при чтении
  static Future<Map<String, String>> decryptData(Map<String, dynamic> rawData) async {
    final decryptedData = <String, String>{};
    
    for (final entry in rawData.entries) {
      if (entry.key.startsWith(_keyPrefix)) {
        final originalKey = entry.key.substring(_keyPrefix.length);
        final encryptedValue = entry.value?.toString() ?? '';
        
        // Расшифровываем все значения, включая пустые строки
        final decrypted = await decryptString(encryptedValue);
        decryptedData[originalKey] = decrypted;
        DebugLogger.logWithTag('Encryption', 'Расшифровано поле $originalKey: ${decrypted.isNotEmpty ? '${decrypted.length} символов' : 'пустая строка'}');
      }
    }
    
    DebugLogger.logWithTag('Encryption', 'Расшифровано ${decryptedData.length} полей');
    return decryptedData;
  }

  /// Очищает кеш ключа (для тестирования)
  static void clearKeyCache() {
    _cachedKey = null;
    DebugLogger.logWithTag('Encryption', 'Кеш ключа очищен');
  }
}

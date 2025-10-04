import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'debug_logger.dart';
import 'encryption_service.dart';

class SecureTokenManager {
  static SharedPreferences? _prefs;
  
  static const String _keyAccessToken = 'steam_access_token';
  static const String _keyRefreshToken = 'steam_refresh_token';
  static const String _keySteamId = 'steam_id';
  static const String _keyAccountName = 'account_name';
  static const String _keyWeakToken = 'weak_token';
  static const String _keyTokenExpiry = 'token_expiry';

  /// Инициализация хранилища
  static Future<void> _initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      DebugLogger.logWithTag('SecureTokenManager', 'Используем SharedPreferences для ${Platform.operatingSystem}');
    } catch (e) {
      DebugLogger.logWithTag('SecureTokenManager', 'Ошибка инициализации хранилища: $e');
    }
  }

  /// Сохраняет токены авторизации в безопасном хранилище
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String steamId,
    required String accountName,
    required String weakToken,
    required int expiryTime,
  }) async {
    try {
      await _initialize();
      
      if (_prefs != null) {
        // Подготавливаем данные для шифрования
        final dataToEncrypt = {
          _keyAccessToken: accessToken,
          _keyRefreshToken: refreshToken,
          _keySteamId: steamId,
          _keyAccountName: accountName,
          _keyWeakToken: weakToken,
        };
        
        DebugLogger.logWithTag('SecureTokenManager', 'Сохраняем данные: weakToken=${weakToken.isNotEmpty ? 'найден (${weakToken.length} символов)' : 'пустой'}');
        
        // Шифруем чувствительные данные
        final encryptedData = await EncryptionService.encryptData(dataToEncrypt);
        
        // Сохраняем зашифрованные данные
        for (final entry in encryptedData.entries) {
          await _prefs!.setString(entry.key, entry.value);
        }
        
        // Сохраняем время истечения в открытом виде (не критично)
        await _prefs!.setInt(_keyTokenExpiry, expiryTime);
      }
      
      DebugLogger.logWithTag('SecureTokenManager', 'Токены зашифрованы и сохранены для аккаунта: $accountName');
      DebugLogger.logWithTag('SecureTokenManager', 'Истекают: ${DateTime.fromMillisecondsSinceEpoch(expiryTime * 1000)}');
    } catch (e) {
      DebugLogger.logWithTag('SecureTokenManager', 'Ошибка сохранения токенов: $e');
    }
  }

  /// Загружает сохраненные токены из безопасного хранилища
  static Future<Map<String, dynamic>?> loadTokens() async {
    try {
      await _initialize();
      
      if (_prefs == null) {
        DebugLogger.logWithTag('SecureTokenManager', 'SharedPreferences не инициализирован');
        return null;
      }
      
      // Получаем все ключи из SharedPreferences
      final allKeys = _prefs!.getKeys();
      final encryptedKeys = allKeys.where((key) => key.startsWith('fsda_encrypted_')).toList();
      
      DebugLogger.logWithTag('SecureTokenManager', 'Всего ключей в SharedPreferences: ${allKeys.length}');
      DebugLogger.logWithTag('SecureTokenManager', 'Зашифрованных ключей: ${encryptedKeys.length}');
      DebugLogger.logWithTag('SecureTokenManager', 'Зашифрованные ключи: $encryptedKeys');
      
      if (encryptedKeys.isEmpty) {
        DebugLogger.logWithTag('SecureTokenManager', 'Зашифрованные токены не найдены');
        return null;
      }
      
      // Собираем зашифрованные данные
      final encryptedData = <String, dynamic>{};
      for (final key in encryptedKeys) {
        final value = _prefs!.getString(key);
        if (value != null) {
          encryptedData[key] = value;
          DebugLogger.logWithTag('SecureTokenManager', 'Найден зашифрованный ключ: $key (${value.length} символов)');
        }
      }
      
      DebugLogger.logWithTag('SecureTokenManager', 'Собрано ${encryptedData.length} зашифрованных значений');
      
      // Расшифровываем данные
      final decryptedData = await EncryptionService.decryptData(encryptedData);
      
      // Проверяем наличие всех необходимых полей
      DebugLogger.logWithTag('SecureTokenManager', 'Проверка расшифрованных полей:');
      DebugLogger.logWithTag('SecureTokenManager', 'access_token: ${decryptedData[_keyAccessToken] != null ? 'найден' : 'отсутствует'}');
      DebugLogger.logWithTag('SecureTokenManager', 'refresh_token: ${decryptedData[_keyRefreshToken] != null ? 'найден' : 'отсутствует'}');
      DebugLogger.logWithTag('SecureTokenManager', 'steam_id: ${decryptedData[_keySteamId] != null ? 'найден' : 'отсутствует'}');
      DebugLogger.logWithTag('SecureTokenManager', 'account_name: ${decryptedData[_keyAccountName] != null ? 'найден' : 'отсутствует'}');
      DebugLogger.logWithTag('SecureTokenManager', 'weak_token: ${decryptedData[_keyWeakToken] != null ? 'найден' : 'отсутствует'}');
      
      if (decryptedData[_keyAccessToken] == null || 
          decryptedData[_keyRefreshToken] == null || 
          decryptedData[_keySteamId] == null || 
          decryptedData[_keyAccountName] == null || 
          decryptedData[_keyWeakToken] == null) {
        DebugLogger.logWithTag('SecureTokenManager', 'Не все токены найдены после расшифровки');
        return null;
      }
      
      // Получаем время истечения
      final expiryTime = _prefs!.getInt(_keyTokenExpiry);
      if (expiryTime == null) {
        DebugLogger.logWithTag('SecureTokenManager', 'Время истечения токена не найдено');
        return null;
      }
      
      DebugLogger.logWithTag('SecureTokenManager', 'Токены расшифрованы для аккаунта: ${decryptedData[_keyAccountName]}');
      DebugLogger.logWithTag('SecureTokenManager', 'Истекают: ${DateTime.fromMillisecondsSinceEpoch(expiryTime * 1000)}');
      
      return {
        'access_token': decryptedData[_keyAccessToken]!,
        'refresh_token': decryptedData[_keyRefreshToken]!,
        'steamid': decryptedData[_keySteamId]!,
        'account_name': decryptedData[_keyAccountName]!,
        'weak_token': decryptedData[_keyWeakToken]!,
        'expiry_time': expiryTime.toString(),
      };
    } catch (e) {
      DebugLogger.logWithTag('SecureTokenManager', 'Ошибка загрузки токенов: $e');
      return null;
    }
  }

  /// Проверяет, действительны ли токены
  static Future<bool> areTokensValid() async {
    try {
      final tokens = await loadTokens();
      if (tokens == null) {
        DebugLogger.logWithTag('SecureTokenManager', 'Токены не найдены');
        return false;
      }
      
      final expiryTime = int.parse(tokens['expiry_time']!);
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Проверяем, что токены не истекли (с запасом в 5 минут)
      final isValid = expiryTime > (now + 300);
      
      DebugLogger.logWithTag('SecureTokenManager', 'Проверка токенов:');
      DebugLogger.logWithTag('SecureTokenManager', '  Текущее время: $now (${DateTime.fromMillisecondsSinceEpoch(now * 1000)})');
      DebugLogger.logWithTag('SecureTokenManager', '  Время истечения: $expiryTime (${DateTime.fromMillisecondsSinceEpoch(expiryTime * 1000)})');
      DebugLogger.logWithTag('SecureTokenManager', '  Токены действительны: $isValid');
      DebugLogger.logWithTag('SecureTokenManager', '  Истекают через: ${expiryTime - now} секунд');
      
      return isValid;
    } catch (e) {
      DebugLogger.logWithTag('SecureTokenManager', 'Ошибка проверки токенов: $e');
      return false;
    }
  }

  /// Очищает сохраненные токены
  static Future<void> clearTokens() async {
    try {
      await _initialize();
      
      if (_prefs != null) {
        // Получаем все ключи и удаляем зашифрованные
        final allKeys = _prefs!.getKeys();
        final encryptedKeys = allKeys.where((key) => key.startsWith('fsda_encrypted_')).toList();
        
        for (final key in encryptedKeys) {
          await _prefs!.remove(key);
        }
        
        // Также удаляем время истечения
        await _prefs!.remove(_keyTokenExpiry);
      }
      
      DebugLogger.logWithTag('SecureTokenManager', 'Зашифрованные токены очищены из хранилища');
    } catch (e) {
      DebugLogger.logWithTag('SecureTokenManager', 'Ошибка очистки токенов: $e');
    }
  }

  /// Получает время истечения токена
  static Future<int?> getTokenExpiry() async {
    try {
      await _initialize();
      
      if (_prefs == null) return null;
      return _prefs!.getInt(_keyTokenExpiry);
    } catch (e) {
      DebugLogger.logWithTag('SecureTokenManager', 'Ошибка получения времени истечения: $e');
      return null;
    }
  }

  /// Получает токен доступа
  static Future<String?> getAccessToken() async {
    try {
      await _initialize();
      
      if (_prefs != null) {
        final encryptedToken = _prefs!.getString('fsda_encrypted_$_keyAccessToken');
        if (encryptedToken != null) {
          return await EncryptionService.decryptString(encryptedToken);
        }
      }
      
      return null;
    } catch (e) {
      DebugLogger.logWithTag('SecureTokenManager', 'Ошибка получения токена доступа: $e');
      return null;
    }
  }


  /// Проверяет, нужно ли обновить токены (истекают в течение часа)
  static Future<bool> shouldRefreshTokens() async {
    try {
      final expiryTime = await getTokenExpiry();
      if (expiryTime == null) return true;
      
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final shouldRefresh = expiryTime < (now + 3600); // Обновляем за час до истечения
      
      return shouldRefresh;
    } catch (e) {
      DebugLogger.logWithTag('SecureTokenManager', 'Ошибка проверки необходимости обновления: $e');
      return true;
    }
  }

  /// Получает все токены для экспорта (включая истекшие)
  static Future<Map<String, dynamic>?> getAllTokensForExport() async {
    try {
      await _initialize();
      
      if (_prefs == null) {
        DebugLogger.logWithTag('SecureTokenManager', 'SharedPreferences не инициализированы');
        return null;
      }

      // Получаем все зашифрованные ключи
      final allKeys = _prefs!.getKeys();
      
      final encryptedKeys = allKeys.where((key) => key.startsWith('fsda_encrypted_')).toList();

      if (encryptedKeys.isEmpty) {
        DebugLogger.logWithTag('SecureTokenManager', 'Зашифрованные токены не найдены');
        return null;
      }

      // Расшифровываем все данные
      final decryptedData = <String, dynamic>{};
      
      for (final encryptedKey in encryptedKeys) {
        final encryptedValue = _prefs!.getString(encryptedKey);
        if (encryptedValue != null) {
          try {
            final decryptedValue = await EncryptionService.decryptString(encryptedValue);
            final originalKey = encryptedKey.replaceFirst('fsda_encrypted_', '');
            decryptedData[originalKey] = decryptedValue;
          } catch (e) {
            DebugLogger.logWithTag('SecureTokenManager', 'Ошибка расшифровки ключа $encryptedKey: $e');
          }
        }
      }

      // Получаем время истечения (не зашифровано)
      final expiryTime = _prefs!.getInt(_keyTokenExpiry);
      if (expiryTime != null) {
        decryptedData['expiry_time'] = expiryTime;
      }

      if (decryptedData.isEmpty) {
        DebugLogger.logWithTag('SecureTokenManager', 'Нет данных для экспорта');
        return null;
      }

      DebugLogger.logWithTag('SecureTokenManager', 'Экспортируем ${decryptedData.length} токенов');
      return decryptedData;
    } catch (e) {
      DebugLogger.logWithTag('SecureTokenManager', 'Ошибка получения токенов для экспорта: $e');
      return null;
    }
  }

  /// Восстанавливает токены из экспорта
  static Future<void> restoreTokensFromExport(Map<String, dynamic> tokens) async {
    try {
      await _initialize();
      
      if (_prefs == null) {
        DebugLogger.logWithTag('SecureTokenManager', 'SharedPreferences не инициализированы для восстановления');
        return;
      }

      // Подготавливаем данные для шифрования
      final dataToEncrypt = <String, String>{};
      
      // Проверяем все возможные ключи
      if (tokens['steam_access_token'] != null) {
        dataToEncrypt[_keyAccessToken] = tokens['steam_access_token'];
      } else if (tokens['access_token'] != null) {
        dataToEncrypt[_keyAccessToken] = tokens['access_token'];
      }
      
      if (tokens['steam_refresh_token'] != null) {
        dataToEncrypt[_keyRefreshToken] = tokens['steam_refresh_token'];
      } else if (tokens['refresh_token'] != null) {
        dataToEncrypt[_keyRefreshToken] = tokens['refresh_token'];
      }
      
      if (tokens['steam_id'] != null) {
        dataToEncrypt[_keySteamId] = tokens['steam_id'];
      } else if (tokens['steamid'] != null) {
        dataToEncrypt[_keySteamId] = tokens['steamid'];
      }
      
      if (tokens['account_name'] != null) {
        dataToEncrypt[_keyAccountName] = tokens['account_name'];
      }
      
      if (tokens['weak_token'] != null) {
        dataToEncrypt[_keyWeakToken] = tokens['weak_token'];
      }

      // Шифруем и сохраняем данные
      for (final entry in dataToEncrypt.entries) {
        final encryptedValue = await EncryptionService.encryptString(entry.value);
        await _prefs!.setString('fsda_encrypted_${entry.key}', encryptedValue);
      }

      // Сохраняем время истечения (не шифруем)
      if (tokens['expiry_time'] != null) {
        final expiryTime = tokens['expiry_time'];
        if (expiryTime is int) {
          await _prefs!.setInt(_keyTokenExpiry, expiryTime);
        } else if (expiryTime is String) {
          await _prefs!.setInt(_keyTokenExpiry, int.parse(expiryTime));
        }
      }

      DebugLogger.logWithTag('SecureTokenManager', 'Токены восстановлены из экспорта в зашифрованном виде');
    } catch (e) {
      DebugLogger.logWithTag('SecureTokenManager', 'Ошибка восстановления токенов: $e');
    }
  }

  /// Проверяет доступность хранилища
  static Future<bool> isSecureStorageAvailable() async {
    try {
      await _initialize();
      final isAvailable = _prefs != null;
      DebugLogger.logWithTag('SecureTokenManager', 'Хранилище доступно: $isAvailable');
      return isAvailable;
    } catch (e) {
      DebugLogger.logWithTag('SecureTokenManager', 'Хранилище недоступно: $e');
      return false;
    }
  }
}

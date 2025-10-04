import 'package:http/http.dart' as http;
import 'debug_logger.dart';

class SteamProfileService {
  static const String _baseUrl = 'https://steamcommunity.com';
  
  /// Получает информацию о профиле Steam по Steam ID
  static Future<SteamProfile?> getProfile(String steamId) async {
    try {
      DebugLogger.logWithTag('SteamProfile', 'Получаем профиль для Steam ID: $steamId');
      
      // Получаем информацию о профиле через Steam Web API
      final profileUrl = '$_baseUrl/profiles/$steamId/?xml=1';
      
      final response = await http.get(
        Uri.parse(profileUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      );
      
      if (response.statusCode != 200) {
        DebugLogger.logWithTag('SteamProfile', 'Ошибка получения профиля: ${response.statusCode}');
        return null;
      }
      
      DebugLogger.logWithTag('SteamProfile', 'Профиль получен: ${response.body.length} байт');
      
      // Парсим XML ответ
      final profile = _parseProfileXml(response.body);
      if (profile != null) {
        DebugLogger.logWithTag('SteamProfile', 'Профиль распарсен: ${profile.personaName}');
      }
      
      return profile;
    } catch (e) {
      DebugLogger.logWithTag('SteamProfile', 'Ошибка получения профиля: $e');
      return null;
    }
  }
  
  /// Получает информацию о профиле через Steam Web API (JSON) - публичный API
  static Future<SteamProfile?> getProfileJson(String steamId) async {
    try {
      DebugLogger.logWithTag('SteamProfile', 'Получаем профиль через JSON API для Steam ID: $steamId');
      
      // Используем публичный Steam API без ключа
      final apiUrl = 'https://steamcommunity.com/profiles/$steamId/ajaxGetPlayerSummary/';
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'application/json, text/javascript, */*; q=0.01',
          'X-Requested-With': 'XMLHttpRequest',
        },
      );
      
      DebugLogger.logWithTag('SteamProfile', 'JSON API ответ: ${response.statusCode} (${response.body.length} байт)');
      
      if (response.statusCode != 200) {
        DebugLogger.logWithTag('SteamProfile', 'Ошибка JSON API: ${response.statusCode}');
        return null;
      }
      
      // Steam теперь возвращает HTML вместо JSON, поэтому используем HTML парсинг
      DebugLogger.logWithTag('SteamProfile', 'Steam возвращает HTML вместо JSON, используем HTML парсинг');
      return await getProfileHtml(steamId);
    } catch (e) {
      DebugLogger.logWithTag('SteamProfile', 'Ошибка JSON API: $e');
      return null;
    }
  }
  
  /// Получает информацию о профиле через HTML страницу Steam Community
  static Future<SteamProfile?> getProfileHtml(String steamId) async {
    try {
      DebugLogger.logWithTag('SteamProfile', 'Получаем профиль через HTML для Steam ID: $steamId');
      
      final profileUrl = 'https://steamcommunity.com/profiles/$steamId/';
      final response = await http.get(
        Uri.parse(profileUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      );
      
      DebugLogger.logWithTag('SteamProfile', 'HTML ответ: ${response.statusCode} (${response.body.length} байт)');
      
      if (response.statusCode != 200) {
        DebugLogger.logWithTag('SteamProfile', 'Ошибка HTML API: ${response.statusCode}');
        return null;
      }
      
      // Парсим HTML для извлечения данных профиля
      final htmlContent = response.body;
      
      // Ищем никнейм в title страницы
      final titleMatch = RegExp(r'<title>(.*?)</title>').firstMatch(htmlContent);
      String personaName = 'Unknown';
      if (titleMatch != null) {
        final title = titleMatch.group(1)!;
        // Убираем "Steam Community :: " из начала
        if (title.startsWith('Steam Community :: ')) {
          personaName = title.substring(20);
        } else {
          personaName = title;
        }
      }
      
      // Ищем аватар
      final avatarMatch = RegExp(r'<img[^>]*src="([^"]*avatar[^"]*)"[^>]*>').firstMatch(htmlContent);
      String avatarUrl = '';
      if (avatarMatch != null) {
        avatarUrl = avatarMatch.group(1)!;
      }
      
      DebugLogger.logWithTag('SteamProfile', 'HTML парсинг: personaName=$personaName, avatar=$avatarUrl');
      
      return SteamProfile(
        steamId: steamId,
        personaName: personaName,
        avatarUrl: avatarUrl,
        avatarMediumUrl: avatarUrl,
        avatarFullUrl: avatarUrl,
        profileUrl: profileUrl,
        realName: '',
        countryCode: '',
        stateCode: '',
        cityId: '',
        lastLogoff: '',
        profileState: '',
        commentPermission: '',
      );
    } catch (e) {
      DebugLogger.logWithTag('SteamProfile', 'Ошибка HTML API: $e');
      return null;
    }
  }
  
  /// Парсит XML ответ от Steam
  static SteamProfile? _parseProfileXml(String xmlContent) {
    try {
      DebugLogger.logWithTag('SteamProfile', 'Парсим XML: ${xmlContent.length} байт');
      
      // Простой парсинг XML (можно улучшить с помощью xml пакета)
      final steamIdMatch = RegExp(r'<steamID64>(\d+)</steamID64>').firstMatch(xmlContent);
      final personaNameMatch = RegExp(r'<steamID><!\[CDATA\[(.*?)\]\]></steamID>').firstMatch(xmlContent);
      final avatarMatch = RegExp(r'<avatarMedium><!\[CDATA\[(.*?)\]\]></avatarMedium>').firstMatch(xmlContent);
      final avatarFullMatch = RegExp(r'<avatarFull><!\[CDATA\[(.*?)\]\]></avatarFull>').firstMatch(xmlContent);
      final realNameMatch = RegExp(r'<realname><!\[CDATA\[(.*?)\]\]></realname>').firstMatch(xmlContent);
      
      DebugLogger.logWithTag('SteamProfile', 'XML парсинг: steamId=${steamIdMatch?.group(1)}, personaName=${personaNameMatch?.group(1)}, avatar=${avatarMatch?.group(1)}');
      
      if (steamIdMatch == null) {
        DebugLogger.logWithTag('SteamProfile', 'Steam ID не найден в XML');
        return null;
      }
      
      return SteamProfile(
        steamId: steamIdMatch.group(1)!,
        personaName: personaNameMatch?.group(1) ?? 'Unknown',
        avatarUrl: avatarMatch?.group(1) ?? '',
        avatarMediumUrl: avatarMatch?.group(1) ?? '',
        avatarFullUrl: avatarFullMatch?.group(1) ?? '',
        profileUrl: 'https://steamcommunity.com/profiles/${steamIdMatch.group(1)}',
        realName: realNameMatch?.group(1) ?? '',
        countryCode: '',
        stateCode: '',
        cityId: '',
        lastLogoff: '',
        profileState: '',
        commentPermission: '',
      );
    } catch (e) {
      DebugLogger.logWithTag('SteamProfile', 'Ошибка парсинга XML: $e');
      return null;
    }
  }
}

/// Модель данных профиля Steam
class SteamProfile {
  final String steamId;
  final String personaName;
  final String avatarUrl;
  final String avatarMediumUrl;
  final String avatarFullUrl;
  final String profileUrl;
  final String realName;
  final String countryCode;
  final String stateCode;
  final String cityId;
  final String lastLogoff;
  final String profileState;
  final String commentPermission;
  
  SteamProfile({
    required this.steamId,
    required this.personaName,
    required this.avatarUrl,
    required this.avatarMediumUrl,
    required this.avatarFullUrl,
    required this.profileUrl,
    required this.realName,
    required this.countryCode,
    required this.stateCode,
    required this.cityId,
    required this.lastLogoff,
    required this.profileState,
    required this.commentPermission,
  });
  
  /// Получает URL аватара среднего размера или полного
  String get bestAvatarUrl {
    if (avatarMediumUrl.isNotEmpty) return avatarMediumUrl;
    if (avatarFullUrl.isNotEmpty) return avatarFullUrl;
    if (avatarUrl.isNotEmpty) return avatarUrl;
    return '';
  }
  
  /// Получает отображаемое имя (реальное имя или никнейм)
  String get displayName {
    if (realName.isNotEmpty) return realName;
    return personaName;
  }
}

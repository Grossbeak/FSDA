import 'dart:developer' as developer;

/// Сервис для сбора и отображения логов отладки
class DebugLogger {
  static final List<String> _logs = [];
  static const int _maxLogs = 1000; // Максимальное количество логов
  
  /// Добавляет лог в коллекцию
  static void log(String message, {String? tag}) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] ${tag != null ? '[$tag] ' : ''}$message';
    
    _logs.add(logEntry);
    
    // Ограничиваем количество логов
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
    
    // Также выводим в консоль для отладки
    developer.log(logEntry);
    print(logEntry);
  }
  
  /// Добавляет лог с тегом
  static void logWithTag(String tag, String message) {
    log(message, tag: tag);
  }
  
  /// Получает все логи
  static List<String> getAllLogs() {
    return List.from(_logs);
  }
  
  /// Очищает все логи
  static void clearLogs() {
    _logs.clear();
  }
  
  /// Получает логи с определенным тегом
  static List<String> getLogsByTag(String tag) {
    return _logs.where((log) => log.contains('[$tag]')).toList();
  }
}

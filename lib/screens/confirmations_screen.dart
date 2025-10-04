import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/mafile.dart';
import '../services/steam_confirmations.dart';
import '../services/debug_logger.dart';
import '../services/secure_token_manager.dart';
import '../services/steam_auth.dart';
import 'login_screen.dart';

class ConfirmationsScreen extends StatefulWidget {
  final AccountEntry account;
  final bool showAppBar;
  
  const ConfirmationsScreen({
    super.key, 
    required this.account,
    this.showAppBar = true,
  });

  @override
  State<ConfirmationsScreen> createState() => _ConfirmationsScreenState();
}

class _ConfirmationsScreenState extends State<ConfirmationsScreen> {
  List<ConfirmationItem> _confirmations = [];
  bool _isLoading = false;
  String? _error;
  Map<String, String> _cookies = {};
  bool _needsAuth = false;
  bool _isAuthenticating = false;
  late MaFile _currentMaFile;

  @override
  void initState() {
    super.initState();
    _currentMaFile = widget.account.maFile;
    _checkDataAndLoad();
  }

  Future<void> _checkDataAndLoad() async {
    // Сначала проверяем сохраненные токены
    try {
      final savedTokens = await SteamAuthService.loginWithSavedTokens();
      if (savedTokens != null && savedTokens['success'] == true) {
        DebugLogger.logWithTag('Confirmations', '✅ Используем сохраненные токены для автоматической авторизации');
        
        // Обновляем maFile с сохраненными данными
        _currentMaFile = MaFile(
          accountName: _currentMaFile.accountName,
          sharedSecret: _currentMaFile.sharedSecret,
          identitySecret: _currentMaFile.identitySecret,
          deviceId: _currentMaFile.deviceId ?? 'android:71b6b888-50fb-41d3-8d15-0b479af53997',
          steamId: savedTokens['steamid']?.toString() ?? _currentMaFile.steamId,
          sessionId: _currentMaFile.sessionId,
          webCookie: savedTokens['webCookie']?.toString() ?? _currentMaFile.webCookie,
        );
        
        DebugLogger.logWithTag('Confirmations', 'Обновленный maFile: steamId=${_currentMaFile.steamId}, webCookie=${_currentMaFile.webCookie}');
        
        // Загружаем подтверждения с сохраненными данными
        _loadCookies();
        _loadConfirmations();
        return;
      }
    } catch (e) {
      DebugLogger.logWithTag('Confirmations', 'Ошибка при использовании сохраненных токенов: $e');
    }
    
    // Если сохраненных токенов нет или они недействительны, проверяем данные из maFile
    final missingData = <String>[];
    if (_currentMaFile.deviceId?.isEmpty ?? true) missingData.add('deviceId');
    if (_currentMaFile.steamId?.isEmpty ?? true) missingData.add('steamId');
    if (_currentMaFile.webCookie?.isEmpty ?? true) missingData.add('webCookie');
    
    if (missingData.isNotEmpty) {
      setState(() {
        _needsAuth = true;
        _error = 'Отсутствуют данные подтверждений: ${missingData.join(', ')}. Требуется авторизация.';
      });
      return;
    }
    
    // Если все данные есть в maFile, загружаем подтверждения
    _loadCookies();
    _loadConfirmations();
  }

  Future<void> _performAuthentication() async {
    setState(() {
      _isAuthenticating = true;
      _error = null;
    });

    try {
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (_) => LoginScreen(account: widget.account),
        ),
      );

      if (result != null && result['success'] == true) {
        // Обновляем maFile с данными сессии
        DebugLogger.logWithTag('Confirmations', 'Обновляем maFile с результатом: $result');
        
        final fromCache = result['from_cache'] == true;
        if (fromCache) {
          DebugLogger.logWithTag('Confirmations', '✅ Используем сохраненные данные авторизации');
        } else {
          DebugLogger.logWithTag('Confirmations', '🔄 Используем свежие данные авторизации');
        }
        
        _currentMaFile = MaFile(
          accountName: _currentMaFile.accountName,
          sharedSecret: _currentMaFile.sharedSecret,
          identitySecret: _currentMaFile.identitySecret,
          deviceId: result['deviceId'] ?? _currentMaFile.deviceId,
          steamId: result['steamId'] ?? _currentMaFile.steamId,
          sessionId: result['sessionId'] ?? _currentMaFile.sessionId,
          webCookie: result['webCookie'] ?? result['cookies'] ?? result['steamLoginSecure'] ?? _currentMaFile.webCookie,
        );
        DebugLogger.logWithTag('Confirmations', 'Обновленный maFile: steamId=${_currentMaFile.steamId}, webCookie=${_currentMaFile.webCookie}');
        
        setState(() {
          _needsAuth = false;
          _isAuthenticating = false;
        });
        
        // Загружаем подтверждения
        _loadCookies();
        _loadConfirmations();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Авторизация успешна. ${result['message'] ?? ''}',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.grey[800],
            ),
          );
        }
      } else {
        setState(() {
          _isAuthenticating = false;
          _error = 'Авторизация не удалась. Попробуйте еще раз.';
        });
      }
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _error = 'Ошибка авторизации: $e';
      });
    }
  }

  void _loadCookies() {
    // Парсим cookies из maFile
    final webCookie = _currentMaFile.webCookie;
    DebugLogger.logWithTag('Confirmations', 'Загружаем cookies из webCookie: $webCookie');
    
    if (webCookie != null) {
      // Если это steamLoginSecure cookie (формат: steamLoginSecure=steamid||token)
      if (webCookie.startsWith('steamLoginSecure=')) {
        _cookies['steamLoginSecure'] = webCookie.substring('steamLoginSecure='.length);
        DebugLogger.logWithTag('Confirmations', 'Добавлен steamLoginSecure cookie: ${_cookies['steamLoginSecure']}');
      } else {
        // Старый формат с ; разделителями
        final cookieParts = webCookie.split(';');
        for (final part in cookieParts) {
          final trimmed = part.trim();
          if (trimmed.contains('=')) {
            final keyValue = trimmed.split('=');
            if (keyValue.length == 2) {
              _cookies[keyValue[0]] = keyValue[1];
              DebugLogger.logWithTag('Confirmations', 'Добавлен cookie: ${keyValue[0]}=${keyValue[1]}');
            }
          }
        }
      }
    }
    
    DebugLogger.logWithTag('Confirmations', 'Итоговые cookies: $_cookies');
  }

  Future<void> _loadConfirmations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final confirmations = await SteamConfirmationsService.getConfirmations(
        deviceId: _currentMaFile.deviceId!,
        steamId: _currentMaFile.steamId!,
        identitySecret: _currentMaFile.identitySecret,
        cookies: _cookies,
      );

      setState(() {
        _confirmations = confirmations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки подтверждений: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptConfirmation(ConfirmationItem confirmation) async {
    try {
      DebugLogger.logWithTag('Confirmations', 'Принимаем подтверждение: ${confirmation.id}');
      DebugLogger.logWithTag('Confirmations', 'Используем cookies: $_cookies');
      
      final success = await SteamConfirmationsService.acceptConfirmation(
        deviceId: _currentMaFile.deviceId!,
        steamId: _currentMaFile.steamId!,
        identitySecret: _currentMaFile.identitySecret,
        cookies: _cookies,
        confirmation: confirmation,
      );

      if (success) {
        DebugLogger.logWithTag('Confirmations', 'Подтверждение успешно принято');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Подтверждение принято',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.grey[800],
            ),
          );
        }
        _loadConfirmations(); // Обновляем список
      } else {
        DebugLogger.logWithTag('Confirmations', 'ОШИБКА: Подтверждение НЕ принято');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Ошибка при принятии подтверждения',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.grey[800],
            ),
          );
        }
      }
    } catch (e) {
      DebugLogger.logWithTag('Confirmations', 'ИСКЛЮЧЕНИЕ при принятии: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.grey[800],
          ),
        );
      }
    }
  }

  Future<void> _denyConfirmation(ConfirmationItem confirmation) async {
    try {
      DebugLogger.logWithTag('Confirmations', 'Отклоняем подтверждение: ${confirmation.id}');
      DebugLogger.logWithTag('Confirmations', 'Используем cookies: $_cookies');
      
      final success = await SteamConfirmationsService.denyConfirmation(
        deviceId: _currentMaFile.deviceId!,
        steamId: _currentMaFile.steamId!,
        identitySecret: _currentMaFile.identitySecret,
        cookies: _cookies,
        confirmation: confirmation,
      );

      if (success) {
        DebugLogger.logWithTag('Confirmations', 'Подтверждение успешно отклонено');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Подтверждение отклонено',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.grey[800],
            ),
          );
        }
        _loadConfirmations(); // Обновляем список
      } else {
        DebugLogger.logWithTag('Confirmations', 'ОШИБКА: Подтверждение НЕ отклонено');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Ошибка при отклонении подтверждения',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.grey[800],
            ),
          );
        }
      }
    } catch (e) {
      DebugLogger.logWithTag('Confirmations', 'ИСКЛЮЧЕНИЕ при отклонении: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.grey[800],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
        title: const Text('Подтверждения Steam'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadConfirmations,
            tooltip: 'Обновить список',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _clearSavedTokens,
            tooltip: 'Очистить сохраненные данные',
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _deleteAccount,
            tooltip: 'Удалить аккаунт',
          ),
        ],
      ) : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading || _isAuthenticating) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_needsAuth) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _performAuthentication,
              icon: const Icon(Icons.login),
              label: const Text('Авторизоваться'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadConfirmations,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_confirmations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Нет ожидающих подтверждений',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _confirmations.length,
      itemBuilder: (context, index) {
        final confirmation = _confirmations[index];
        return _buildConfirmationCard(confirmation);
      },
    );
  }

  Widget _buildConfirmationCard(ConfirmationItem confirmation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildConfirmationIcon(confirmation),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        confirmation.headline,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        confirmation.typeName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _formatCreationTime(confirmation.creationTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (confirmation.summary.isNotEmpty) ...[
              Text(
                'Детали:',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ...confirmation.summary.map((item) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: _buildSummaryItem(item),
              )),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptConfirmation(confirmation),
                    icon: const Icon(Icons.check),
                    label: const Text('Принять'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _denyConfirmation(confirmation),
                    icon: const Icon(Icons.close),
                    label: const Text('Отклонить'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationIcon(ConfirmationItem confirmation) {
    // Для трейдов показываем аватар пользователя, если есть URL иконки
    if (confirmation.type == ConfirmationType.trade && confirmation.icon.isNotEmpty) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _getConfirmationColor(confirmation.type),
            width: 2,
          ),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: confirmation.icon,
            width: 32,
            height: 32,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: Icon(
                Icons.person,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
            errorWidget: (context, url, error) => Icon(
              _getConfirmationIcon(confirmation.type),
              size: 32,
              color: _getConfirmationColor(confirmation.type),
            ),
          ),
        ),
      );
    }
    
    // Для остальных типов показываем обычные иконки
    return Icon(
      _getConfirmationIcon(confirmation.type),
      size: 32,
      color: _getConfirmationColor(confirmation.type),
    );
  }

  IconData _getConfirmationIcon(ConfirmationType type) {
    switch (type) {
      case ConfirmationType.trade:
        return Icons.swap_horiz;
      case ConfirmationType.marketSell:
        return Icons.sell;
      case ConfirmationType.phoneNumberChange:
        return Icons.phone;
      case ConfirmationType.accountRecovery:
        return Icons.security;
      case ConfirmationType.apiKeyCreation:
        return Icons.key;
      case ConfirmationType.joinSteamFamily:
        return Icons.family_restroom;
      default:
        return Icons.notification_important;
    }
  }

  Color _getConfirmationColor(ConfirmationType type) {
    switch (type) {
      case ConfirmationType.trade:
        return Colors.blue;
      case ConfirmationType.marketSell:
        return Colors.orange;
      case ConfirmationType.phoneNumberChange:
        return Colors.purple;
      case ConfirmationType.accountRecovery:
        return Colors.red;
      case ConfirmationType.apiKeyCreation:
        return Colors.green;
      case ConfirmationType.joinSteamFamily:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  /// Создает виджет для элемента summary с соответствующей стрелкой
  Widget _buildSummaryItem(String item) {
    IconData icon;
    Color color;
    
    if (item.toLowerCase().contains('you will give up') || 
        item.toLowerCase().contains('you will lose') ||
        item.toLowerCase().contains('отдаете') ||
        item.toLowerCase().contains('потеряете')) {
      // Красная стрелка вверх для того, что отдаем
      icon = Icons.arrow_upward;
      color = Colors.red;
    } else if (item.toLowerCase().contains('you will receive') || 
               item.toLowerCase().contains('you will get') ||
               item.toLowerCase().contains('получаете') ||
               item.toLowerCase().contains('получите')) {
      // Зеленая стрелка вниз для того, что получаем
      icon = Icons.arrow_downward;
      color = Colors.green;
    } else {
      // Обычная точка для остальных случаев
      icon = Icons.circle;
      color = Colors.grey;
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  /// Форматирует время создания подтверждения
  String _formatCreationTime(int creationTime) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(creationTime * 1000);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }

  /// Очищает сохраненные токены авторизации
  Future<void> _clearSavedTokens() async {
    try {
      await SecureTokenManager.clearTokens();
      DebugLogger.logWithTag('Confirmations', 'Сохраненные токены очищены');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Сохраненные данные авторизации очищены',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.grey[800],
          ),
        );
        
        // Сбрасываем состояние авторизации
        setState(() {
          _needsAuth = true;
          _currentMaFile = widget.account.maFile;
          _cookies = {};
          _error = 'Отсутствуют данные подтверждений: steamid, webCookie. Требуется авторизация.';
        });
      }
    } catch (e) {
      DebugLogger.logWithTag('Confirmations', 'Ошибка очистки токенов: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка очистки данных: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.grey[800],
          ),
        );
      }
    }
  }

  /// Удаляет аккаунт из приложения
  Future<void> _deleteAccount() async {
    // Показываем диалог подтверждения
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить аккаунт'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Вы уверены, что хотите удалить аккаунт "${widget.account.maFile.accountName}"?'),
            const SizedBox(height: 16),
            const Text(
              'Это действие удалит:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Все сохраненные токены авторизации'),
            const Text('• Данные сессии Steam'),
            const Text('• Настройки аккаунта'),
            const SizedBox(height: 16),
            const Text(
              'Это действие нельзя отменить!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      DebugLogger.logWithTag('Confirmations', 'Удаляем аккаунт: ${widget.account.maFile.accountName}');
      
      // Очищаем все сохраненные токены
      await SecureTokenManager.clearTokens();
      
      // Очищаем состояние
      setState(() {
        _confirmations.clear();
        _cookies.clear();
        _needsAuth = true;
        _error = 'Аккаунт удален. Требуется повторная авторизация.';
      });
      
      DebugLogger.logWithTag('Confirmations', 'Аккаунт успешно удален');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Аккаунт "${widget.account.maFile.accountName}" удален',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
        
        // Возвращаемся к предыдущему экрану
        Navigator.of(context).pop();
      }
    } catch (e) {
      DebugLogger.logWithTag('Confirmations', 'Ошибка удаления аккаунта: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка удаления аккаунта: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

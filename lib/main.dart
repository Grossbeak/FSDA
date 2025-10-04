import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/mafile.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'steam_guard.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'services/steam_confirmations.dart';
import 'screens/login_screen.dart';
import 'screens/confirmations_screen.dart';
import 'screens/debug_logs_screen.dart';
import 'screens/qr_login_screen.dart';
import 'services/steam_profile_service.dart';
import 'services/debug_logger.dart';
import 'services/secure_token_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class _AuthState extends ChangeNotifier {
  final List<AccountEntry> accounts = <AccountEntry>[];
  int? activeIndex;
  String? currentCode;
  int secondsRemaining = 30;
  Timer? _ticker;
  final List<ConfirmationItem> confirmations = <ConfirmationItem>[];
  bool confirmationsLoading = false;
  String? confirmationsError;
  SteamProfile? steamProfile;
  bool profileLoading = false;

  MaFile? get maFile => (activeIndex != null && activeIndex! < accounts.length) ? accounts[activeIndex!].maFile : null;

  Future<void> importMaFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    final content = await _readFile(path);
    final MaFile parsed = MaFile.parse(content);
    // Сохраняем содержимое файла вместо пути
    accounts.add(AccountEntry(filePath: null, maFile: parsed, maFileContent: content));
    // Не переключаемся на последний; если не выбран — выбрать первый
    activeIndex ??= 0;
    await _persistAccounts();
    _restartTicker();
    notifyListeners();
  }

  Future<void> _persistAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    // Сохраняем содержимое maFile вместо путей
    final maFileContents = accounts.map((e) => e.maFileContent ?? e.maFile.serialize()).toList();
    await prefs.setStringList('accounts_mafiles', maFileContents);
    await prefs.setInt('active_index', activeIndex ?? -1);
  }

  Future<void> restoreAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    // Сначала пытаемся загрузить новые данные (содержимое maFile)
    final maFileContents = prefs.getStringList('accounts_mafiles') ?? <String>[];
    final idx = prefs.getInt('active_index') ?? -1;
    accounts.clear();
    
    if (maFileContents.isNotEmpty) {
      // Загружаем из новых данных
      for (final content in maFileContents) {
        try {
          final mf = MaFile.parse(content);
          accounts.add(AccountEntry(filePath: null, maFile: mf, maFileContent: content));
        } catch (e) {
          // Игнорируем поврежденные записи
        }
      }
    } else {
      // Fallback для старых данных (пути к файлам)
      final paths = prefs.getStringList('accounts_paths') ?? <String>[];
    for (final p in paths) {
      try {
        final content = await _readFile(p);
        final mf = MaFile.parse(content);
          accounts.add(AccountEntry(filePath: p, maFile: mf, maFileContent: content));
        } catch (e) {
          // Игнорируем недоступные файлы
    }
      }
    }
    
    activeIndex = (idx >= 0 && idx < accounts.length) ? idx : (accounts.isEmpty ? null : 0);
    _restartTicker();
    notifyListeners();
  }

  void setActiveIndex(int index) {
    if (index < 0 || index >= accounts.length) return;
    activeIndex = index;
    currentCode = null;
    _restartTicker();
    loadSteamProfile(); // Загружаем профиль при смене аккаунта
    notifyListeners();
  }

  void _restartTicker() {
    _ticker?.cancel();
    if (maFile == null) return;
    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final selected = maFile;
    if (selected == null) return;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    const period = 30;
    secondsRemaining = period - (now % period);
    final newCode = SteamGuard.generateCode(sharedSecret: selected.sharedSecret, timestampSeconds: now);
    if (newCode != currentCode) {
      currentCode = newCode;
    }
    notifyListeners();
  }


  Future<void> fetchConfirmations() async {
    final mf = maFile;
    if (mf == null) {
      confirmationsError = 'Нет выбранного аккаунта';
      confirmations.clear();
      notifyListeners();
      return;
    }
    
    // Проверяем наличие необходимых данных
    final missingData = <String>[];
    if (mf.identitySecret.isEmpty) missingData.add('identity_secret');
    if (mf.steamId?.isEmpty ?? true) missingData.add('steamid');
    if (mf.deviceId?.isEmpty ?? true) missingData.add('device_id');
    if (mf.webCookie == null || mf.webCookie!.isEmpty) missingData.add('webCookie');
    
    if (missingData.isNotEmpty) {
      confirmationsError = 'Отсутствуют данные для подтверждений: ${missingData.join(', ')}. Авторизуйтесь или импортируйте полный maFile.';
      confirmations.clear();
      notifyListeners();
      return;
    }
    confirmationsLoading = true;
    confirmationsError = null;
    notifyListeners();
    try {
      // Преобразуем строку cookies в Map
      final cookiesMap = <String, String>{};
      if (mf.webCookie != null && mf.webCookie!.isNotEmpty) {
        final cookieParts = mf.webCookie!.split(';');
        for (final part in cookieParts) {
          final trimmed = part.trim();
          if (trimmed.contains('=')) {
            final keyValue = trimmed.split('=');
            if (keyValue.length == 2) {
              cookiesMap[keyValue[0]] = keyValue[1];
            }
          }
        }
      }
      
      final confirmationsList = await SteamConfirmationsService.getConfirmations(
        deviceId: mf.deviceId!,
        steamId: mf.steamId!,
        identitySecret: mf.identitySecret,
        cookies: cookiesMap,
      );
        confirmations
          ..clear()
        ..addAll(confirmationsList);
    } catch (e) {
      confirmationsError = 'Исключение: $e';
    } finally {
      confirmationsLoading = false;
    notifyListeners();
  }

}

  /// Удаляет аккаунт из списка
  void deleteAccount(int index) {
    if (index < 0 || index >= accounts.length) return;
    
    // Очищаем токены для этого аккаунта
    SecureTokenManager.clearTokens();
    
    // Удаляем аккаунт из списка
    accounts.removeAt(index);
    
    // Обновляем активный индекс
    if (accounts.isEmpty) {
      activeIndex = null;
      steamProfile = null;
    } else if (activeIndex != null && activeIndex! >= accounts.length) {
      activeIndex = accounts.length - 1;
      loadSteamProfile(); // Загружаем профиль для нового активного аккаунта
    }
    
    // Сохраняем изменения
    _persistAccounts();
    
    notifyListeners();
  }

  /// Загружает профиль Steam для текущего аккаунта
  Future<void> loadSteamProfile() async {
    DebugLogger.logWithTag('SteamProfile', 'Начинаем загрузку профиля');
    DebugLogger.logWithTag('SteamProfile', 'maFile: ${maFile?.toJson()}');
    DebugLogger.logWithTag('SteamProfile', 'steamId: ${maFile?.steamId}');
    
    String? steamIdToUse = maFile?.steamId;
    
    // Если steamId отсутствует в maFile, пробуем получить из сохраненных токенов
    if (steamIdToUse == null) {
      DebugLogger.logWithTag('SteamProfile', 'Steam ID отсутствует в maFile, проверяем сохраненные токены');
      try {
        final tokens = await SecureTokenManager.loadTokens();
        if (tokens != null && tokens['steamid'] != null) {
          steamIdToUse = tokens['steamid'];
          DebugLogger.logWithTag('SteamProfile', 'Найден Steam ID в токенах: $steamIdToUse');
        }
      } catch (e) {
        DebugLogger.logWithTag('SteamProfile', 'Ошибка загрузки токенов: $e');
      }
    }
    
    if (steamIdToUse == null) {
      DebugLogger.logWithTag('SteamProfile', 'Steam ID отсутствует везде, профиль не загружен');
      steamProfile = null;
    notifyListeners();
      return;
  }

    profileLoading = true;
    notifyListeners();
    
    try {
      DebugLogger.logWithTag('SteamProfile', 'Загружаем профиль для Steam ID: $steamIdToUse');
      
      // Пробуем сначала XML API (самый надежный)
      steamProfile = await SteamProfileService.getProfile(steamIdToUse);
      
      // Если не получилось, пробуем HTML парсинг
      if (steamProfile == null) {
        DebugLogger.logWithTag('SteamProfile', 'XML API не сработал, пробуем HTML');
        steamProfile = await SteamProfileService.getProfileHtml(steamIdToUse);
      }
      
      // Если и HTML не сработал, пробуем JSON API (который теперь тоже использует HTML)
      if (steamProfile == null) {
        DebugLogger.logWithTag('SteamProfile', 'HTML не сработал, пробуем JSON API');
        steamProfile = await SteamProfileService.getProfileJson(steamIdToUse);
      }
      
      if (steamProfile != null) {
        DebugLogger.logWithTag('SteamProfile', 'Профиль загружен: ${steamProfile!.personaName}');
        DebugLogger.logWithTag('SteamProfile', 'Аватар: ${steamProfile!.bestAvatarUrl}');
      } else {
        DebugLogger.logWithTag('SteamProfile', 'Не удалось загрузить профиль ни одним методом');
      }
    } catch (e) {
      DebugLogger.logWithTag('SteamProfile', 'Ошибка загрузки профиля: $e');
      steamProfile = null;
    } finally {
      profileLoading = false;
    notifyListeners();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

// Simple file read helper using dart:io, guarded for web
Future<String> _readFile(String path) async {
  if (kIsWeb) {
    throw UnsupportedError('Чтение локальных файлов не поддерживается в Web');
  }
  final io.File file = io.File(path);
  return file.readAsString();
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => _AuthState()),
      ],
      child: MaterialApp(
        title: 'FSDA',
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        navigatorKey: _navigatorKey,
        home: const MyHomePage(title: 'FSDA'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  int _tradesRefreshKey = 0; // Ключ для перезагрузки вкладки трейдов
  int _titleClickCount = 0;
  DateTime? _lastTitleClickTime;

  @override
  void initState() {
    super.initState();
    // Восстановить ранее импортированные аккаунты
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<_AuthState>().restoreAccounts();
    });
  }

  void _handleTitleTap() {
    final now = DateTime.now();
    
    // Если прошло больше 1 секунды с последнего клика, сбрасываем счетчик
    if (_lastTitleClickTime != null && 
        now.difference(_lastTitleClickTime!).inMilliseconds > 1000) {
      _titleClickCount = 0;
    }
    
    _titleClickCount++;
    _lastTitleClickTime = now;
    
    // Если это третий клик в течение секунды
    if (_titleClickCount >= 3) {
      _titleClickCount = 0; // Сбрасываем счетчик
      
      // Открываем логи отладки
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const DebugLogsScreen(),
        ),
      );
    }
  }

  /// Экспорт maFile (совместимый с SDA и SDA-CLI)
  Future<void> _exportMaFile(BuildContext context) async {
    final state = context.read<_AuthState>();
    
    if (state.activeIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала выберите аккаунт для экспорта')),
      );
      return;
    }

    try {
      final account = state.accounts[state.activeIndex!];
      final maFileContent = account.maFileContent ?? account.maFile.serialize();
      
      // Выбираем место для сохранения
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Сохранить maFile',
        fileName: '${account.maFile.accountName}.maFile',
        type: FileType.any,
      );

      if (outputFile != null) {
        final file = io.File(outputFile);
        await file.writeAsString(maFileContent);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('maFile экспортирован: ${file.path}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка экспорта: $e')),
        );
      }
    }
  }

  /// Экспорт maToken (зашифрованный токен с кодовой фразой)
  Future<void> _exportMaToken(BuildContext context) async {
    final state = context.read<_AuthState>();
    
    if (state.activeIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала выберите аккаунт для экспорта')),
      );
      return;
    }

    try {
      final account = state.accounts[state.activeIndex!];
      
      // Сохраняем навигатор до показа диалога
      final navigator = Navigator.of(context);
      
      // Запрашиваем кодовую фразу
      final String? passphrase = await _showPassphraseDialog(context, 'Введите кодовую фразу для шифрования maToken');
      if (passphrase == null || passphrase.isEmpty) return;

      // Создаем компактный токен с основными данными
      final tokenData = {
        'account_name': account.maFile.accountName,
        'shared_secret': account.maFile.sharedSecret,
        'identity_secret': account.maFile.identitySecret,
        'device_id': account.maFile.deviceId,
        'steamid': account.maFile.steamId,
      };
      
      // Шифруем данные
      final encryptedToken = await _encryptWithPassphrase(jsonEncode(tokenData), passphrase);
      
      // Показываем токен на экране с кнопкой копирования
      // Используем сохраненный навигатор
      showDialog(
        context: navigator.context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text('maToken для ${account.maFile.accountName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ваш зашифрованный maToken:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.maxFinite,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[600]!),
                  ),
                  child: SelectableText(
                    encryptedToken,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '⚠️ Сохраните этот токен в безопасном месте!\nДля импорта потребуется кодовая фраза.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Закрыть'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: encryptedToken));
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('maToken скопирован в буфер обмена')),
                    );
                    // Убираем Navigator.of(dialogContext).pop() чтобы диалог не закрывался
                  }
                },
                icon: const Icon(Icons.copy),
                label: const Text('Копировать'),
              ),
            ],
          );
        },
      );
      
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка экспорта: $e')),
        );
      }
    }
  }

  /// Экспорт всех данных FSDA (все аккаунты в зашифрованном файле)
  Future<void> _exportFullData(BuildContext context) async {
    final state = context.read<_AuthState>();
    
    if (state.accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет аккаунтов для экспорта')),
      );
      return;
    }

    // Запрашиваем кодовую фразу
    final String? passphrase = await _showPassphraseDialog(context, 'Введите кодовую фразу для шифрования всех данных FSDA');
    if (passphrase == null || passphrase.isEmpty) return;

    try {
      // Получаем токены авторизации
      final authTokens = await SecureTokenManager.getAllTokensForExport();
      
      // Собираем все данные
      final fullData = {
        'version': '1.0',
        'export_date': DateTime.now().toIso8601String(),
        'accounts': state.accounts.map((account) => {
          'maFile': account.maFile.toJson(),
          'maFileContent': account.maFileContent,
          'filePath': account.filePath,
        }).toList(),
        'activeIndex': state.activeIndex,
        'authTokens': authTokens, // Добавляем токены авторизации
      };
      
      // Шифруем данные
      final encryptedData = await _encryptWithPassphrase(jsonEncode(fullData), passphrase);
      
      // Выбираем место для сохранения
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Сохранить данные FSDA',
        fileName: 'FSDA_backup_${DateTime.now().millisecondsSinceEpoch}.fsda',
        type: FileType.any,
      );

      if (outputFile != null) {
        final file = io.File(outputFile);
        await file.writeAsString(encryptedData);
        
        if (context.mounted) {
          final tokensInfo = authTokens != null ? ' + токены авторизации' : '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Все данные FSDA экспортированы$tokensInfo: ${file.path}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка экспорта: $e')),
        );
      }
    }
  }

  /// Показывает диалог выбора способа импорта
  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выберите способ импорта'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.file_copy, color: Colors.blue),
                title: const Text('Импорт maFile'),
                subtitle: const Text('Файл из SDA или SDA-CLI'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.read<_AuthState>().importMaFile();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.key, color: Colors.orange),
                title: const Text('Импорт maToken'),
                subtitle: const Text('Зашифрованный токен'),
                onTap: () {
                  Navigator.of(context).pop();
                  _importMaToken(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.backup, color: Colors.green),
                title: const Text('Импорт данных FSDA'),
                subtitle: const Text('Резервная копия FSDA'),
                onTap: () {
                  Navigator.of(context).pop();
                  _importFullData(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
          ],
        );
      },
    );
  }

  /// Показывает диалог выбора способа экспорта
  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выберите способ экспорта'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.file_copy, color: Colors.blue),
                title: const Text('Экспорт maFile'),
                subtitle: const Text('Совместимый с SDA и SDA-CLI'),
                onTap: () {
                  Navigator.of(context).pop();
                  _exportMaFile(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.key, color: Colors.orange),
                title: const Text('Экспорт maToken'),
                subtitle: const Text('Зашифрованный токен'),
                onTap: () {
                  Navigator.of(context).pop();
                  _exportMaToken(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.backup, color: Colors.green),
                title: const Text('Экспорт всех данных'),
                subtitle: const Text('Все аккаунты FSDA'),
                onTap: () {
                  Navigator.of(context).pop();
                  _exportFullData(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
          ],
        );
      },
    );
  }

  /// Показывает диалог для ввода кодовой фразы
  Future<String?> _showPassphraseDialog(BuildContext context, String title) async {
    final TextEditingController controller = TextEditingController();
    bool obscureText = true;
    
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Кодовая фраза',
                      hintText: 'Введите надежную кодовую фразу',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureText ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureText = !obscureText;
                          });
                        },
                      ),
                    ),
                    obscureText: obscureText,
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Запомните эту фразу! Без неё вы не сможете расшифровать данные.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final passphrase = controller.text.trim();
                    if (passphrase.isNotEmpty) {
                      Navigator.of(context).pop(passphrase);
                    }
                  },
                  child: const Text('Продолжить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Шифрует данные с помощью кодовой фразы
  Future<String> _encryptWithPassphrase(String data, String passphrase) async {
    // Простое Base64 кодирование с солью для демонстрации
    // В реальном приложении следует использовать более надежное шифрование
    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    final combined = '$salt:$data:$passphrase';
    final encoded = base64Encode(utf8.encode(combined));
    
    return 'maToken:$encoded';
  }

  /// Импорт maToken (зашифрованный токен с кодовой фразой)
  Future<void> _importMaToken(BuildContext context) async {
    // Сохраняем навигатор до показа первого диалога
    final navigator = Navigator.of(context);
    
    try {
      
      // Запрашиваем токен
      final String? token = await _showTokenInputDialog(context, 'Введите maToken для импорта');
      if (token == null || token.isEmpty) return;

      // Проверяем формат токена
      if (!token.startsWith('maToken:')) {
        if (navigator.mounted) {
          ScaffoldMessenger.of(navigator.context).showSnackBar(
            const SnackBar(content: Text('Неверный формат токена. Токен должен начинаться с "maToken:"')),
          );
        }
        return;
      }

      // Запрашиваем кодовую фразу ПОСЛЕ ввода токена, используя сохраненный навигатор
      final String? passphrase = await _showPassphraseDialog(navigator.context, 'Введите кодовую фразу для расшифровки maToken');
      if (passphrase == null || passphrase.isEmpty) return;

      // Расшифровываем токен
      final decryptedData = await _decryptWithPassphrase(token, passphrase);
      final tokenData = jsonDecode(decryptedData) as Map<String, dynamic>;

      // Создаем MaFile из токена
      final maFile = MaFile(
        accountName: tokenData['account_name'] ?? '',
        sharedSecret: tokenData['shared_secret'] ?? '',
        identitySecret: tokenData['identity_secret'] ?? '',
        deviceId: tokenData['device_id'],
        steamId: tokenData['steamid'],
      );

      // Добавляем аккаунт
      final state = navigator.context.read<_AuthState>();
      state.accounts.add(AccountEntry(filePath: null, maFile: maFile, maFileContent: maFile.serialize()));
      state.activeIndex ??= 0;
      await state._persistAccounts();
      state._restartTicker();
      state.notifyListeners();

      if (navigator.mounted) {
        ScaffoldMessenger.of(navigator.context).showSnackBar(
          SnackBar(content: Text('maToken успешно импортирован: ${maFile.accountName}')),
        );
      }
    } catch (e) {
      if (navigator.mounted) {
        ScaffoldMessenger.of(navigator.context).showSnackBar(
          SnackBar(content: Text('Ошибка импорта maToken: $e')),
        );
      }
    }
  }

  /// Импорт всех данных FSDA (резервная копия)
  Future<void> _importFullData(BuildContext context) async {
    // Сохраняем навигатор до показа диалогов
    final navigator = Navigator.of(context);
    
    try {
      
      // Выбираем файл
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;

      final content = await io.File(path).readAsString();

      // Проверяем формат файла (поддерживаем оба формата для обратной совместимости)
      if (!content.startsWith('FSDA_ENCRYPTED:') && !content.startsWith('maToken:')) {
        if (navigator.mounted) {
          ScaffoldMessenger.of(navigator.context).showSnackBar(
            const SnackBar(content: Text('Неверный формат файла. Это не резервная копия FSDA.')),
          );
        }
        return;
      }

      // Запрашиваем кодовую фразу ПОСЛЕ выбора файла, используя сохраненный навигатор
      final String? passphrase = await _showPassphraseDialog(navigator.context, 'Введите кодовую фразу для расшифровки данных FSDA');
      if (passphrase == null || passphrase.isEmpty) return;

      // Расшифровываем данные
      final decryptedData = await _decryptWithPassphrase(content, passphrase);
      final fullData = jsonDecode(decryptedData) as Map<String, dynamic>;

      // Проверяем версию
      final version = fullData['version'] as String?;
      if (version != '1.0') {
        if (navigator.mounted) {
          ScaffoldMessenger.of(navigator.context).showSnackBar(
            SnackBar(content: Text('Неподдерживаемая версия резервной копии: $version')),
          );
        }
        return;
      }

      // Восстанавливаем аккаунты
      final state = navigator.context.read<_AuthState>();
      final accountsData = fullData['accounts'] as List<dynamic>;
      
      for (final accountData in accountsData) {
        final maFileData = accountData['maFile'] as Map<String, dynamic>;
        final maFile = MaFile.fromJson(maFileData);
        final maFileContent = accountData['maFileContent'] as String?;
        final filePath = accountData['filePath'] as String?;
        
        state.accounts.add(AccountEntry(
          filePath: filePath,
          maFile: maFile,
          maFileContent: maFileContent,
        ));
      }

      // Восстанавливаем активный индекс
      final activeIndex = fullData['activeIndex'] as int?;
      if (activeIndex != null && activeIndex < state.accounts.length) {
        state.activeIndex = activeIndex;
      } else if (state.accounts.isNotEmpty) {
        state.activeIndex = 0;
      }

      // Восстанавливаем токены авторизации
      final authTokens = fullData['authTokens'] as Map<String, dynamic>?;
      if (authTokens != null) {
        await SecureTokenManager.restoreTokensFromExport(authTokens);
      }

      await state._persistAccounts();
      state._restartTicker();
      state.notifyListeners();

      if (navigator.mounted) {
        final tokensInfo = authTokens != null ? ' + токены авторизации' : '';
        ScaffoldMessenger.of(navigator.context).showSnackBar(
          SnackBar(content: Text('Данные FSDA успешно импортированы: ${accountsData.length} аккаунтов$tokensInfo')),
        );
      }
    } catch (e) {
      if (navigator.mounted) {
        ScaffoldMessenger.of(navigator.context).showSnackBar(
          SnackBar(content: Text('Ошибка импорта данных FSDA: $e')),
        );
      }
    }
  }

  /// Показывает диалог для ввода токена
  Future<String?> _showTokenInputDialog(BuildContext context, String title) async {
    final TextEditingController controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'maToken',
                  hintText: 'maToken:...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text(
                'Вставьте maToken, который был экспортирован ранее.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                final token = controller.text.trim();
                if (token.isNotEmpty) {
                  Navigator.of(context).pop(token);
                }
              },
              child: const Text('Импортировать'),
            ),
          ],
        );
      },
    );
  }

  /// Расшифровывает данные с помощью кодовой фразы
  Future<String> _decryptWithPassphrase(String encryptedData, String passphrase) async {
    // Убираем префикс
    String data = encryptedData;
    if (data.startsWith('maToken:')) {
      data = data.substring(8);
    } else if (data.startsWith('FSDA_ENCRYPTED:')) {
      data = data.substring(15);
    }

    // Декодируем Base64
    final decoded = base64Decode(data);
    final combined = utf8.decode(decoded);
    
    // Разбираем формат: salt:data:passphrase
    final parts = combined.split(':');
    if (parts.length < 3) {
      throw Exception('Неверный формат зашифрованных данных');
    }
    
    final originalPassphrase = parts.last;
    if (originalPassphrase != passphrase) {
      throw Exception('Неверная кодовая фраза');
    }
    
    // Возвращаем данные (все части кроме первой (salt) и последней (passphrase))
    return parts.sublist(1, parts.length - 1).join(':');
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: GestureDetector(
          onTap: _handleTitleTap,
          child: Text(_currentIndex == 1 ? 'Подтверждения Steam' : widget.title),
        ),
        actions: _buildAppBarActions(),
      ),
      body: _buildBody(),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (index == 1 && _currentIndex == 1) {
                // Если уже находимся во вкладке "Трейды" и нажимаем на неё снова - обновляем
                setState(() {
                  _tradesRefreshKey++; // Увеличиваем ключ для перезагрузки
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Список подтверждений обновлен',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.grey[800],
                  ),
                );
              } else {
                // Обычное переключение вкладок
                setState(() {
                  _currentIndex = index;
                });
              }
            },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Трейды',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Аккаунт',
          ),
        ],
      ),
    );
  }


  List<Widget> _buildAppBarActions() {
    final state = context.watch<_AuthState>();
    
    if (_currentIndex == 1) {
      // Вкладка "Трейды" - показываем кнопки для управления подтверждениями
      return [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await SecureTokenManager.clearTokens();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Сохраненные данные очищены')),
            );
          },
          tooltip: 'Очистить сохраненные данные',
        ),
        if (state.activeIndex != null)
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              final account = state.accounts[state.activeIndex!];
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Удалить аккаунт'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Вы уверены, что хотите удалить аккаунт "${account.maFile.accountName}"?'),
                      const SizedBox(height: 16),
                      const Text(
                        'Это действие удалит:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('• Аккаунт из списка'),
                      const Text('• Все сохраненные токены'),
                      const Text('• Данные сессии'),
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

              if (confirmed == true) {
                context.read<_AuthState>().deleteAccount(state.activeIndex!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Аккаунт "${account.maFile.accountName}" удален'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            tooltip: 'Удалить аккаунт',
          ),
      ];
    } else if (_currentIndex == 2) {
      // Вкладка "Аккаунт" - показываем только кнопку удаления
      return [
        if (state.activeIndex != null)
          IconButton(
            tooltip: 'Удалить аккаунт',
            onPressed: () async {
              final account = state.accounts[state.activeIndex!];
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Удалить аккаунт'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Вы уверены, что хотите удалить аккаунт "${account.maFile.accountName}"?'),
                      const SizedBox(height: 16),
                      const Text(
                        'Это действие удалит:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('• Аккаунт из списка'),
                      const Text('• Все сохраненные токены'),
                      const Text('• Данные сессии'),
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

              if (confirmed == true) {
                context.read<_AuthState>().deleteAccount(state.activeIndex!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Аккаунт "${account.maFile.accountName}" удален'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.delete_forever),
          ),
      ];
    } else {
      // Вкладка "Главная" - показываем все кнопки
      return [
        // QR сканер доступен только на мобильных платформах
          IconButton(
            tooltip: 'Авторизация Steam',
            onPressed: () async {
              final currentAccount = state.maFile;
              if (currentAccount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Сначала выберите аккаунт')),
                );
                return;
              }
              
              final accountEntry = state.accounts[state.activeIndex!];
              final result = await Navigator.of(context).push<Map<String, dynamic>>(
                MaterialPageRoute(
                  builder: (_) => LoginScreen(account: accountEntry),
                ),
              );
              
              if (result != null && result['success'] == true) {
                // Обновляем maFile с данными сессии
                final updated = MaFile(
                  accountName: currentAccount.accountName,
                  sharedSecret: currentAccount.sharedSecret,
                  identitySecret: currentAccount.identitySecret,
                  deviceId: result['deviceId'] ?? currentAccount.deviceId,
                  steamId: result['steamId'] ?? currentAccount.steamId,
                  sessionId: result['sessionId'] ?? currentAccount.sessionId,
                  webCookie: result['cookies'] ?? result['steamLoginSecure'] ?? currentAccount.webCookie,
                );
                
                state.accounts[state.activeIndex!] = AccountEntry(
                  filePath: accountEntry.filePath,
                  maFile: updated,
                maFileContent: accountEntry.maFileContent,
                );
                await state._persistAccounts();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                    content: Text(
                      'Авторизация успешна. ${result['message'] ?? ''}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.grey[800],
                      action: SnackBarAction(
                        label: 'Проверить трейды',
                      textColor: Colors.white,
                        onPressed: () => state.fetchConfirmations(),
                      ),
                    ),
                  );
                }
            } else if (result != null) {
              if (result['requires_twofactor'] == true) {
                // Показываем диалог для ввода 2FA кода
                _show2FADialog(context, result['login_data']);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Ошибка входа: ${result['error']}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.grey[800],
                    ),
                  );
                }
              }
              }
            },
            icon: const Icon(Icons.login),
          ),
          IconButton(
          tooltip: 'Импорт',
          onPressed: () => _showImportDialog(context),
            icon: const Icon(Icons.upload_file),
        ),
        IconButton(
          tooltip: 'Экспорт',
          onPressed: () => _showExportDialog(context),
          icon: const Icon(Icons.download),
        ),
        if (state.activeIndex != null)
          IconButton(
            tooltip: 'Удалить аккаунт',
            onPressed: () async {
              final account = state.accounts[state.activeIndex!];
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Удалить аккаунт'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Вы уверены, что хотите удалить аккаунт "${account.maFile.accountName}"?'),
                      const SizedBox(height: 16),
                      const Text(
                        'Это действие удалит:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('• Аккаунт из списка'),
                      const Text('• Все сохраненные токены'),
                      const Text('• Данные сессии'),
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

              if (confirmed == true) {
                context.read<_AuthState>().deleteAccount(state.activeIndex!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Аккаунт "${account.maFile.accountName}" удален'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.delete_forever),
          ),
      ];
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildTradesTab();
      case 2:
        return _buildAccountTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    final state = context.watch<_AuthState>();
    return SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            // Портрет: две вертикальные области поровну
            return Column(
              children: <Widget>[
              // Круг с кодом - фиксированная высота
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: state.maFile == null
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Импортируйте maFile для начала работы'),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => context.read<_AuthState>().importMaFile(),
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Импортировать maFile'),
                              ),
                            ],
                          )
                    : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Аккаунт: ${state.maFile!.accountName}',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 24),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: (state.currentCode == null)
                                      ? null
                                      : () async {
                                          await Clipboard.setData(ClipboardData(text: state.currentCode!));
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Код скопирован')),
                                            );
                                          }
                                        },
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final double maxDia =
                                              (constraints.maxWidth.isFinite && constraints.maxHeight.isFinite)
                                                  ? (constraints.maxWidth < constraints.maxHeight
                                                      ? constraints.maxWidth
                                                      : constraints.maxHeight)
                                                  : 300;
                                          final double diameter = maxDia.clamp(200.0, 320.0);
                                        final double codeFontSize = (diameter * 0.208).clamp(38.4, 67.2);
                                          return SizedBox(
                                            width: diameter,
                                            height: diameter,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                // Отзеркалим круг, чтобы прогресс шёл в обратном направлении
                                                Transform(
                                                  alignment: Alignment.center,
                                                  transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
                                                  child: SizedBox(
                                                    width: diameter,
                                                    height: diameter,
                                                    child: CircularProgressIndicator(
                                                      value: (state.secondsRemaining.clamp(0, 30)) / 30,
                                                      strokeWidth: (diameter * 0.04).clamp(8.0, 16.0),
                                                    ),
                                                  ),
                                                ),
                                          // Содержимое без отражения - остается по центру
                                                Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      state.currentCode ?? '------',
                                                      textAlign: TextAlign.center,
                                                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                                            fontSize: codeFontSize,
                                                            letterSpacing: 2,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Нажмите, чтобы скопировать',
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                          // Кнопка QR входа внизу круга (только на мобильных платформах)
                                          if (io.Platform.isAndroid || io.Platform.isIOS)
                                            Positioned(
                                              bottom: 32,
                                              child: IconButton(
                                                tooltip: 'Вход по QR коду',
                                                onPressed: () async {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) => QrLoginScreen(maFile: state.maFile),
                                            ),
                                          );
                                        },
                                                icon: const Icon(Icons.qr_code_scanner, size: 30),
                                                style: IconButton.styleFrom(
                                                  backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.all(12),
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
                ),
              // Отступ между кругом и списком
              const SizedBox(height: 20),
                const Divider(height: 1),
              // Список аккаунтов - занимает оставшееся место
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Expanded(child: Text('Аккаунты')),
                            IconButton(
                              tooltip: 'Импорт maFile',
                              onPressed: () => context.read<_AuthState>().importMaFile(),
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: state.accounts.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final entry = state.accounts[index];
                            final selected = state.activeIndex == index;
                            return ListTile(
                              selected: selected,
                              title: Text(entry.maFile.accountName.isEmpty ? 'Без имени' : entry.maFile.accountName,
                                  style: Theme.of(context).textTheme.titleLarge),
                            subtitle: Text(
                              entry.filePath ?? 'Сохранено в программе',
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis
                            ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (selected) const Icon(Icons.check_circle, color: Colors.deepPurpleAccent),
                                ],
                              ),
                              onTap: () => context.read<_AuthState>().setActiveIndex(index),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
      ),
    );
  }

  Widget _buildTradesTab() {
    final state = context.watch<_AuthState>();

    if (state.maFile == null) {
      return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Выберите аккаунт для просмотра трейдов'),
          ],
        ),
      );
    }

    final accountEntry = state.accounts[state.activeIndex!];
    return Column(
      children: [
        Expanded(
          child: ConfirmationsScreen(
            key: ValueKey('trades_${_tradesRefreshKey}'), // Ключ для перезагрузки
            account: accountEntry,
            showAppBar: false,
          ),
        ),
        Container(
          width: double.infinity,
                        padding: const EdgeInsets.all(16),
          child: Text(
            'Нажмите еще раз на вкладку "Трейды" чтобы обновить список трейдов',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountTab() {
    final state = context.watch<_AuthState>();
    
    // Автоматически загружаем профиль при открытии вкладки, если он еще не загружен
    if (state.maFile != null && state.activeIndex != null && state.steamProfile == null && !state.profileLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state.loadSteamProfile();
      });
    }
    
    if (state.maFile == null || state.activeIndex == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Нет активного аккаунта'),
            SizedBox(height: 8),
            Text('Выберите аккаунт на главной странице'),
          ],
        ),
      );
    }
    
    final account = state.accounts[state.activeIndex!];
    final maFile = account.maFile;
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Text(
              'Информация об аккаунте',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Аватар и основная информация
            Center(
              child: Column(
                            children: [
                  // Аватар (реальный из Steam или заглушка)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.deepPurple.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.deepPurple.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: state.profileLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.deepPurple,
                              ),
                            )
                          : state.steamProfile?.bestAvatarUrl.isNotEmpty == true
                              ? CachedNetworkImage(
                                  imageUrl: state.steamProfile!.bestAvatarUrl,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.deepPurple,
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.deepPurple,
                                ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                    // Никнейм (только из Steam профиля)
                    Text(
                      state.steamProfile?.displayName ?? 'Без никнейма',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 8),
                  
                  // Steam ID (реальный из профиля или из maFile)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Steam ID: ${state.steamProfile?.steamId ?? maFile.steamId ?? 'Неизвестно'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                              ),
                            ],
                          ),
            ),
            
            const SizedBox(height: 32),
            
            // Детальная информация
            Text(
              'Детали аккаунта',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Карточки с информацией
            _buildInfoCard(
              context,
              'Логин',
              maFile.accountName.isNotEmpty ? maFile.accountName : 'Не указан',
              Icons.account_circle,
            ),
            const SizedBox(height: 12),
            
            if (state.steamProfile?.realName.isNotEmpty == true) ...[
              _buildInfoCard(
                context,
                'Реальное имя',
                state.steamProfile!.realName,
                Icons.badge,
              ),
              const SizedBox(height: 12),
            ],
            
            if (state.steamProfile?.countryCode.isNotEmpty == true) ...[
              _buildInfoCard(
                context,
                'Страна',
                state.steamProfile!.countryCode,
                Icons.public,
              ),
              const SizedBox(height: 12),
            ],
            
            _buildInfoCard(
              context,
              'Источник данных',
              account.filePath ?? 'Сохранено в программе',
              Icons.storage,
            ),
            
            const Spacer(),
            
            // Кнопки действий
            Column(
              children: [
                // Первая строка кнопок
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: state.profileLoading ? null : () {
                          // Обновляем профиль Steam
                          context.read<_AuthState>().loadSteamProfile();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Обновить профиль'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: state.steamProfile?.profileUrl.isNotEmpty == true ? () {
                          // Открываем профиль Steam в браузере
                          launchUrl(Uri.parse(state.steamProfile!.profileUrl));
                        } : null,
                        icon: const Icon(Icons.open_in_browser),
                        label: const Text('Профиль в Steam'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Информация для отладки
            if (state.steamProfile == null && !state.profileLoading) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Профиль не загружен',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
              const SizedBox(height: 8),
                    Text('Steam ID в maFile: ${maFile.steamId ?? 'отсутствует'}'),
                    Text('Steam ID в токенах: ${state.maFile?.steamId ?? 'отсутствует'}'),
                    const SizedBox(height: 8),
                    const Text(
                      'Попробуйте нажать "Обновить профиль" или проверьте логи отладки.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoCard(BuildContext context, String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
                children: [
          Icon(
            icon,
            color: Colors.deepPurple,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
              ),
            ],
          ),
    );
  }
  
}

// Функция для показа диалога двухфакторной аутентификации
void _show2FADialog(BuildContext context, Map<String, dynamic> loginData) {
  final TextEditingController codeController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Двухфакторная аутентификация'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Steam требует подтверждение входа.'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Код подтверждения',
                hintText: 'Введите код из приложения Steam Guard',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.of(context).pop();
                // TODO: Отправить код подтверждения в Steam
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Код отправлен: $code (пока не реализовано)',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.grey[800],
                  ),
                );
              }
            },
            child: const Text('Подтвердить'),
          ),
        ],
      );
    },
  );
}


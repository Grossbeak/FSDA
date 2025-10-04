import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/debug_logger.dart';
import '../services/steam_qr_auth.dart';
import '../models/mafile.dart';
import '../services/secure_token_manager.dart';
import 'login_screen.dart';

class QrLoginScreen extends StatefulWidget {
  final MaFile? maFile;
  
  const QrLoginScreen({super.key, this.maFile});

  @override
  State<QrLoginScreen> createState() => _QrLoginScreenState();
}

class _QrLoginScreenState extends State<QrLoginScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  String? _statusMessage;
  bool _needsAuth = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkTokensAndLoad();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _checkTokensAndLoad() async {
    try {
      // Проверяем, нужно ли обновить токены
      final needsRefresh = await SecureTokenManager.shouldRefreshTokens();
      
      if (needsRefresh) {
        DebugLogger.logWithTag('QrLogin', 'Токены истекли или скоро истекут, требуется авторизация');
        setState(() {
          _needsAuth = true;
          _error = 'Токены авторизации истекли. Требуется повторная авторизация.';
        });
        return;
      }
      
      // Проверяем наличие токенов
      final accessToken = await SecureTokenManager.getAccessToken();
      if (accessToken == null) {
        DebugLogger.logWithTag('QrLogin', 'Токены не найдены, требуется авторизация');
        setState(() {
          _needsAuth = true;
          _error = 'Токены авторизации не найдены. Требуется авторизация.';
        });
        return;
      }
      
      DebugLogger.logWithTag('QrLogin', '✅ Токены действительны, можно сканировать QR код');
      
    } catch (e) {
      DebugLogger.logWithTag('QrLogin', 'Ошибка проверки токенов: $e');
      setState(() {
        _needsAuth = true;
        _error = 'Ошибка проверки токенов: $e';
      });
    }
  }

  Future<void> _performAuthentication() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });
    
    try {
      // Создаем AccountEntry из MaFile для LoginScreen
      if (widget.maFile == null) {
        throw Exception('MaFile не найден');
      }
      
      final accountEntry = AccountEntry(
        maFile: widget.maFile!,
      );
      
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (_) => LoginScreen(account: accountEntry),
        ),
      );

      if (result != null && result['success'] == true) {
        DebugLogger.logWithTag('QrLogin', '✅ Авторизация успешна, можно сканировать QR код');
        
        setState(() {
          _needsAuth = false;
          _error = null;
          _isProcessing = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Авторизация успешна! Теперь можно сканировать QR код.',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Авторизация не удалась');
      }
      
    } catch (e) {
      DebugLogger.logWithTag('QrLogin', 'Ошибка авторизации: $e');
      setState(() {
        _error = 'Ошибка авторизации: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Проверяем поддержку платформы
    if (!Platform.isAndroid && !Platform.isIOS) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Вход по QR коду'),
          backgroundColor: Colors.blue[900],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.orange,
              ),
              SizedBox(height: 16),
              Text(
                'QR сканер недоступен',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'QR сканер поддерживается только на Android и iOS',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Показываем экран авторизации если нужно
    if (_needsAuth) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Вход по QR коду'),
          backgroundColor: Colors.blue[900],
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Требуется авторизация',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? 'Токены авторизации истекли',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                if (_isProcessing)
                  const CircularProgressIndicator()
                else
                  ElevatedButton.icon(
                    onPressed: _performAuthentication,
                    icon: const Icon(Icons.login),
                    label: const Text('Авторизоваться'),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Вход по QR коду'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          if (_statusMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: _isProcessing ? Colors.blue[100] : Colors.red[100],
              child: Text(
                _statusMessage!,
                style: TextStyle(
                  color: _isProcessing ? Colors.blue[800] : Colors.red[800],
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            flex: 4,
            child: MobileScanner(
              controller: controller,
              onDetect: _onQRDetected,
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Отсканируйте QR код для входа в Steam',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'QR код должен быть полностью виден в кадре,\nне обязательно по центру',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (_isProcessing)
                    const CircularProgressIndicator()
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => controller.toggleTorch(),
                          icon: const Icon(Icons.flash_on),
                          label: const Text('Вспышка'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => controller.switchCamera(),
                          icon: const Icon(Icons.flip_camera_android),
                          label: const Text('Камера'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final qrText = barcodes.first.rawValue;
    if (qrText != null && qrText.contains('s.team/q/')) {
      setState(() {
        _isProcessing = true;
        _statusMessage = 'Обрабатываем QR код...';
      });
      
      try {
        await _processQrCode(qrText);
      } catch (e) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Ошибка: $e';
        });
        
        // Возобновляем сканирование через 3 секунды
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _statusMessage = null;
            });
          }
        });
      }
    }
  }

  Future<void> _processQrCode(String qrUrl) async {
    try {
      DebugLogger.logWithTag('QrLogin', 'Обрабатываем QR URL: $qrUrl');
      
      setState(() {
        _statusMessage = 'Подтверждаем вход через Steam Guard...';
      });
      
      // Получаем текущий активный аккаунт
      final currentAccount = widget.maFile;
      
      if (currentAccount == null) {
        throw Exception('Нет активного аккаунта Steam Guard. Сначала импортируйте maFile.');
      }
      
      if (currentAccount.sharedSecret.isEmpty) {
        throw Exception('У аккаунта отсутствует shared_secret. QR вход невозможен.');
      }
      
      DebugLogger.logWithTag('QrLogin', 'Используем аккаунт: ${currentAccount.accountName}');
      
      // Подтверждаем QR вход используя Steam Guard данные
      final result = await SteamQrAuth.approveQrLogin(qrUrl, currentAccount);
      
      if (result != null && result['success'] == true) {
        setState(() {
          _statusMessage = 'QR вход успешно подтвержден!';
        });
        
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'QR вход подтвержден для аккаунта ${currentAccount.accountName}',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Не удалось подтвердить QR вход');
      }
      
    } catch (e) {
      DebugLogger.logWithTag('QrLogin', 'Ошибка QR авторизации: $e');
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Ошибка: $e';
      });
      
      // Возобновляем сканирование через 3 секунды
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _statusMessage = null;
          });
        }
      });
    }
  }
}
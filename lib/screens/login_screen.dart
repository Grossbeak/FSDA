import 'package:flutter/material.dart';
import '../services/steam_auth.dart';
import '../models/mafile.dart';
import '../services/debug_logger.dart';

class LoginScreen extends StatefulWidget {
  final AccountEntry account;
  
  const LoginScreen({super.key, required this.account});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;
  bool _tryingSavedTokens = true; // Флаг для попытки использования сохраненных токенов

  @override
  void initState() {
    super.initState();
    _trySavedTokens();
  }

  /// Попытка авторизации с сохраненными токенами
  Future<void> _trySavedTokens() async {
    try {
      DebugLogger.logWithTag('LoginScreen', 'Попытка авторизации с сохраненными токенами');
      
      final result = await SteamAuthService.loginWithSavedTokens();
      
      if (result != null && result['success'] == true) {
        DebugLogger.logWithTag('LoginScreen', 'Успешная авторизация с сохраненными токенами');
        
        if (mounted) {
          Navigator.of(context).pop({
            'success': true,
            'steamId': result['steamid'] ?? '',
            'webCookie': result['webCookie'] ?? '',
            'from_cache': true,
          });
        }
        return;
      }
      
      DebugLogger.logWithTag('LoginScreen', 'Сохраненные токены недействительны, требуется ввод пароля');
    } catch (e) {
      DebugLogger.logWithTag('LoginScreen', 'Ошибка при использовании сохраненных токенов: $e');
    } finally {
      if (mounted) {
        setState(() {
          _tryingSavedTokens = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() {
        _error = 'Введите пароль';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await SteamAuthService.login(
        username: widget.account.maFile.accountName,
        password: password,
        sharedSecret: widget.account.maFile.sharedSecret,
      );

      if (result?['success'] == true) {
        if (mounted) {
          // Добавляем steamid и webCookie в результат для обновления maFile
          final resultWithData = Map<String, dynamic>.from(result!);
          resultWithData['steamId'] = result['steamid'];
          resultWithData['webCookie'] = result['webCookie'];
          DebugLogger.logWithTag('Steam', 'Передаем в результат: steamId=${result['steamid']}, webCookie=${result['webCookie']}');
          Navigator.of(context).pop(resultWithData); // Возвращаем данные сессии
        }
      } else if (result?['requires_twofactor'] == true) {
        // Rust уже обрабатывает 2FA автоматически, эта ветка не должна выполняться
        DebugLogger.logWithTag('Steam', 'ОШИБКА: Rust должен обрабатывать 2FA автоматически!');
        final error = result?['error'] ?? 'Неизвестная ошибка';
        DebugLogger.logWithTag('Error', 'Ошибка входа (красная табличка): $error');
        setState(() {
          _error = error;
        });
      } else {
        final error = result?['error'] ?? 'Неизвестная ошибка';
        DebugLogger.logWithTag('Error', 'Ошибка входа (красная табличка): $error');
        setState(() {
          _error = error;
        });
      }
    } catch (e) {
      final errorMessage = 'Ошибка входа: $e';
      DebugLogger.logWithTag('Error', 'Ошибка входа (красная табличка): $errorMessage');
      setState(() {
        _error = errorMessage;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Авторизация Steam'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 64),
            const SizedBox(height: 24),
            Text(
              _tryingSavedTokens 
                ? 'Проверка сохраненных данных...'
                : 'Введите пароль Steam',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Логин: ${widget.account.maFile.accountName}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            
            // Показываем индикатор загрузки при проверке сохраненных токенов
            if (_tryingSavedTokens) ...[
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Проверяем сохраненные данные авторизации...'),
                ],
              ),
            ] else ...[
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Пароль',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              onSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Войти'),
              ),
            ),
            ], // Закрываем блок else
          ],
        ),
      ),
    );
  }


}

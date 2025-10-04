# FSDA - Flutter Steam Desktop Authenticator

Кроссплатформенное приложение Steam Desktop Authenticator на Flutter для Windows, Linux и Android.

## 🚀 Возможности

- 🔐 **Генерация Steam Guard кодов** - Полная совместимость с официальным алгоритмом Steam
- 📱 **Кроссплатформенность** - Работает на Windows, Linux и Android
- 👥 **Множественные аккаунты** - Поддержка неограниченного количества аккаунтов Steam
- 🔄 **Автоматическое обновление** - Коды обновляются каждые 30 секунд
- 📋 **Быстрое копирование** - Копирование кодов одним кликом
- 🛡️ **Подтверждение торгов** - Управление торговыми операциями Steam
- 🔑 **Безопасная авторизация** - RSA шифрование паролей
- 📱 **QR-код авторизация** - Быстрый вход через QR-код
- 🔒 **Шифрованное хранение** - Безопасное хранение токенов и ключей
- 📤 **Экспорт/Импорт** - Резервное копирование аккаунтов

## 🖥️ Поддерживаемые платформы

| Платформа | Статус | Размер | Установка |
|-----------|--------|--------|-----------|
| **Windows** | ✅ Готов | ~25 MB | GitHub Releases |
| **Linux** | ✅ Готов | ~19 MB | AppImage или pacman |
| **Android** | ✅ Готов | ~66 MB | APK или Google Play |

## 📦 Установка

### Windows
1. Скачайте последний релиз с [GitHub Releases](https://github.com/Grossbeak/FSDA/releases)
2. Распакуйте архив
3. Запустите `fsda.exe`

### Linux (AppImage)
```bash
# Скачайте AppImage
wget https://github.com/Grossbeak/FSDA/releases/download/v1.0.0/FSDA-x86_64.AppImage

# Сделайте исполняемым
chmod +x FSDA-x86_64.AppImage

# Запустите
./FSDA-x86_64.AppImage
```

### Linux (Arch Linux)
```bash
# Установка локального пакета
sudo pacman -U fsda-bin-1.0.0-1-x86_64.pkg.tar.zst
```

### Android
1. Скачайте APK с [GitHub Releases](https://github.com/Grossbeak/FSDA/releases)
2. Включите "Неизвестные источники" в настройках
3. Установите APK

## 🎯 Использование

### 1. **Импорт аккаунта**
- Нажмите кнопку "Импорт" 
- Выберите файл `maFile` из Steam Desktop Authenticator

### 2. **Генерация кодов**
- Код отображается в верхней части экрана
- Автоматически обновляется каждые 30 секунд
- Нажмите на код для копирования в буфер обмена

### 3. **Управление торговыми операциями**
- Нажмите иконку корзины рядом с аккаунтом
- Просматривайте ожидающие подтверждения
- Принимайте или отклоняйте операции

### 4. **Экспорт/Импорт аккаунтов**
- Создавайте резервные копии всех аккаунтов
- Восстанавливайте аккаунты на других устройствах
- Безопасное шифрование данных

## 🏗️ Архитектура

```
lib/
├── main.dart                    # Главный экран и состояние приложения
├── models/
│   └── mafile.dart            # Модель данных maFile и подтверждений
├── services/
│   ├── steam_auth.dart        # Авторизация Steam (логин/пароль)
│   ├── steam_protobuf_auth.dart # Protobuf API авторизация
│   ├── steam_qr_auth.dart     # QR-код авторизация
│   ├── steam_confirmations.dart # API подтверждений торгов
│   ├── secure_token_manager.dart # Безопасное хранение токенов
│   └── encryption_service.dart # Шифрование данных
└── screens/
    ├── login_screen.dart       # Экран авторизации
    ├── qr_login_screen.dart    # QR-код авторизация
    └── confirmations_screen.dart # Управление подтверждениями
```

### Основные компоненты

1. **SteamGuard** - Генерация кодов по алгоритму Steam:
   - HMAC-SHA1 с shared_secret
   - Кастомный алфавит Steam
   - 30-секундные интервалы

2. **MaFile** - Парсинг и хранение данных аутентификатора:
   - account_name, shared_secret, identity_secret
   - device_id, steamid, sessionid, webCookie
   - Поддержка множественных аккаунтов

3. **SteamConfirmationsService** - Работа с подтверждениями:
   - Получение списка подтверждений
   - Принятие/отклонение торгов
   - HMAC подпись запросов

4. **SecureTokenManager** - Безопасное хранение:
   - Шифрование токенов и ключей
   - Экспорт/импорт аккаунтов
   - Защита от несанкционированного доступа

## 🔧 Разработка

### Требования
- Flutter SDK 3.0+
- Dart 3.0+
- Android SDK (для Android сборки)
- GTK+3 (для Linux сборки)

### Сборка из исходников
```bash
# Клонирование репозитория
git clone https://github.com/pavelroot/FSDA.git
cd FSDA

# Установка зависимостей
flutter pub get

# Запуск в режиме разработки
flutter run

# Сборка релиза
flutter build apk --release          # Android
flutter build windows --release      # Windows
flutter build linux --release        # Linux
flutter build macos --release        # macOS
```

### Создание релизов
```bash
# Linux AppImage
./create_appimage.sh

# Arch Linux пакет
./build_package_auto.sh

# Android APK
flutter build apk --release
```

## 📚 Зависимости

- `crypto` - Криптографические функции
- `provider` - Управление состоянием
- `file_picker` - Выбор файлов
- `shared_preferences` - Локальное хранение
- `http` - HTTP запросы
- `qr_flutter` - сканирование QR кодов
- `url_launcher` - Открытие ссылок
- `pointycastle` - RSA шифрование
- `protobuf` - Steam Protobuf API

## 🔐 Безопасность

- **RSA шифрование** паролей перед отправкой
- **AES шифрование** локального хранения токенов
- **HMAC подпись** всех запросов к Steam API
- **Изоляция данных** между аккаунтами
- **Никаких данных** не передается третьим лицам
- **Открытый исходный код** для полной прозрачности

## 🎨 Особенности интерфейса

- **Адаптивный дизайн** для всех размеров экранов
- **Темная тема** по умолчанию
- **Быстрый доступ** к основным функциям
- **Интуитивная навигация** между аккаунтами
- **Визуальные индикаторы** состояния

## 📋 Совместимость

- **Windows** 10/11 (x64)
- **Linux** Ubuntu 20.04+, Arch Linux, и другие дистрибутивы
- **Android** 5.0+ (API 21+)

## 📄 Лицензия

GPL 3.0 - см. файл [LICENSE](LICENSE)

## 🙏 Основано на

- [Steam Desktop Authenticator](https://github.com/Jessecar96/SteamDesktopAuthenticator) (.NET)
- [steamguard-cli](https://github.com/dyc3/steamguard-cli) (Rust)

## 📞 Поддержка

- **Issues**: [GitHub Issues](https://github.com/Grossbeak/FSDA/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Grossbeak/FSDA/discussions)

---

**⭐ Если проект полезен, поставьте звезду на GitHub!**

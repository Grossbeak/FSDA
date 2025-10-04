# 📱 FSDA - Android Release

## ✅ Успешно собраны релизные файлы для Android!

### 📦 Созданные файлы:

1. **APK (для прямого распространения):**
   - `build/app/outputs/flutter-apk/app-release.apk` (66.4 MB)
   - Подписан собственным ключом
   - Готов для установки на устройства

2. **AAB (для Google Play Store):**
   - `build/app/outputs/bundle/release/app-release.aab` (51.1 MB)
   - Оптимизирован для Google Play
   - Готов для загрузки в Google Play Console

### 🔐 Информация о подписи:

- **Keystore:** `android/app/fsda-release-key.keystore`
- **Alias:** fsda
- **Пароли:** fsda123 (для разработки)
- **Срок действия:** 10,000 дней

### 🚀 Установка APK:

#### **На Android устройстве:**
1. Скопируйте `app-release.apk` на устройство
2. Включите "Неизвестные источники" в настройках
3. Откройте APK файл и установите

#### **Через ADB:**
```bash
adb install app-release.apk
```

### 📱 Загрузка в Google Play Store:

1. **Войдите в Google Play Console**
2. **Создайте новое приложение** или обновите существующее
3. **Загрузите AAB файл** `app-release.aab`
4. **Заполните информацию о приложении:**
   - Название: FSDA - Steam Guard Desktop
   - Описание: Desktop application for Steam Guard management
   - Категория: Утилиты
   - Скриншоты и иконки

### 🔄 Повторная сборка:

```bash
# APK для прямого распространения
flutter build apk --release

# AAB для Google Play Store
flutter build appbundle --release
```

### 📋 Информация о приложении:

- **Package Name:** com.example.fsda
- **Version:** 1.0.0
- **Min SDK:** Зависит от Flutter конфигурации
- **Target SDK:** Зависит от Flutter конфигурации
- **Архитектуры:** ARM64, ARM32, x86_64

### ⚠️ Важные замечания:

1. **Безопасность:** Смените пароли keystore перед продакшеном
2. **Package Name:** Измените `com.example.fsda` на уникальное имя
3. **Версия:** Обновляйте versionCode при каждом релизе
4. **Тестирование:** Протестируйте на реальных устройствах

### 🛠️ Дополнительные команды:

```bash
# Сборка для отладки
flutter build apk --debug

# Сборка для профилирования
flutter build apk --profile

# Проверка подписи APK
jarsigner -verify -verbose -certs app-release.apk

# Анализ размера APK
flutter build apk --analyze-size
```

---

**🎉 Android релиз готов к распространению!**

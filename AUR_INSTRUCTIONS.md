# Загрузка FSDA в AUR (Arch User Repository)

## Подготовка

1. **Создайте аккаунт на AUR:**
   - Перейдите на https://aur.archlinux.org/
   - Зарегистрируйтесь с тем же именем пользователя, что и на GitHub

2. **Установите необходимые инструменты:**
   ```bash
   sudo pacman -S base-devel git
   ```

3. **Настройте SSH ключи для AUR:**
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   # Добавьте публичный ключ в настройки AUR
   ```

## Создание релиза на GitHub

1. **Создайте тег для релиза:**
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```

2. **Создайте релиз на GitHub:**
   - Перейдите в раздел Releases
   - Создайте новый релиз с тегом v1.0.0
   - Загрузите FSDA-x86_64.AppImage как asset

3. **Получите SHA256 хеш:**
   ```bash
   sha256sum FSDA-x86_64.AppImage
   ```

4. **Обновите PKGBUILD:**
   - Замените 'SKIP' на реальный SHA256 хеш
   - Убедитесь, что версия соответствует релизу

## Загрузка в AUR

1. **Клонируйте репозиторий AUR:**
   ```bash
   git clone ssh://aur@aur.archlinux.org/fsda.git
   cd fsda
   ```

2. **Скопируйте файлы:**
   ```bash
   cp /path/to/FSDA/PKGBUILD .
   cp /path/to/FSDA/.SRCINFO .  # Создайте этот файл
   ```

3. **Создайте .SRCINFO:**
   ```bash
   makepkg --printsrcinfo > .SRCINFO
   ```

4. **Загрузите в AUR:**
   ```bash
   git add PKGBUILD .SRCINFO
   git commit -m "Initial release of fsda"
   git push origin master
   ```

## Обновление пакета

1. **Обновите PKGBUILD:**
   - Измените pkgver на новую версию
   - Обновите SHA256 хеш
   - Обновите .SRCINFO

2. **Загрузите обновление:**
   ```bash
   git add PKGBUILD .SRCINFO
   git commit -m "Update to version X.X.X"
   git push origin master
   ```

## Проверка пакета

```bash
# Проверьте PKGBUILD на ошибки
namcap PKGBUILD

# Соберите пакет локально
makepkg -s

# Установите пакет для тестирования
sudo pacman -U fsda-1.0.0-1-x86_64.pkg.tar.zst
```

## Полезные ссылки

- [AUR User Guidelines](https://wiki.archlinux.org/title/AUR_user_guidelines)
- [PKGBUILD Reference](https://wiki.archlinux.org/title/PKGBUILD)
- [Creating packages](https://wiki.archlinux.org/title/Creating_packages)


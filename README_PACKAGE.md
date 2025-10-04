# Создание пакета Arch Linux для FSDA

## Быстрый старт

### 1. Сборка пакета
```bash
chmod +x build_package.sh
./build_package.sh
```

### 2. Установка пакета
```bash
sudo pacman -U fsda-bin-*.pkg.tar.zst
```

## Что нужно

```bash
sudo pacman -S base-devel
```

## Как это работает

1. **Скрипт скачивает AppImage** с GitHub Releases
2. **Извлекает содержимое** AppImage
3. **Создает пакет** .pkg.tar.zst
4. **Готово!** Можно устанавливать через pacman

## Результат

- Файл: `fsda-bin-1.0.0-1-x86_64.pkg.tar.zst`
- Установка: `sudo pacman -U fsda-bin-*.pkg.tar.zst`
- Запуск: `fsda`

## Обновление

1. Измените версию в `PKGBUILD-bin`
2. Запустите `./build_package.sh`
3. Установите новый пакет


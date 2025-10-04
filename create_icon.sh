#!/bin/bash

# Скрипт для создания иконок для всех платформ из icon.png
# Создает иконки для Windows, Android и Linux

echo "Создание иконок для всех платформ из icon.png..."

# Проверяем наличие ImageMagick
if ! command -v magick &> /dev/null && ! command -v convert &> /dev/null; then
    echo "ImageMagick не найден. Устанавливаем..."
    sudo pacman -S imagemagick --noconfirm
fi

# Определяем команду для ImageMagick
if command -v magick &> /dev/null; then
    IMAGEMAGICK_CMD="magick"
else
    IMAGEMAGICK_CMD="convert"
fi

# Создаем временные папки
mkdir -p temp_icons
mkdir -p android_icons

echo "=== Создание Windows иконки ==="
# Создаем иконки разных размеров для Windows
$IMAGEMAGICK_CMD icon.png -resize 16x16 temp_icons/icon_16.png
$IMAGEMAGICK_CMD icon.png -resize 32x32 temp_icons/icon_32.png
$IMAGEMAGICK_CMD icon.png -resize 48x48 temp_icons/icon_48.png
$IMAGEMAGICK_CMD icon.png -resize 64x64 temp_icons/icon_64.png
$IMAGEMAGICK_CMD icon.png -resize 128x128 temp_icons/icon_128.png
$IMAGEMAGICK_CMD icon.png -resize 256x256 temp_icons/icon_256.png

# Создаем ICO файл для Windows
$IMAGEMAGICK_CMD temp_icons/icon_16.png temp_icons/icon_32.png temp_icons/icon_48.png temp_icons/icon_64.png temp_icons/icon_128.png temp_icons/icon_256.png windows/runner/resources/app_icon.ico

echo "=== Создание Android иконок ==="
# Создаем иконки для Android разных плотностей
$IMAGEMAGICK_CMD icon.png -resize 48x48 android_icons/ic_launcher_48.png
$IMAGEMAGICK_CMD icon.png -resize 72x72 android_icons/ic_launcher_72.png
$IMAGEMAGICK_CMD icon.png -resize 96x96 android_icons/ic_launcher_96.png
$IMAGEMAGICK_CMD icon.png -resize 144x144 android_icons/ic_launcher_144.png
$IMAGEMAGICK_CMD icon.png -resize 192x192 android_icons/ic_launcher_192.png

# Копируем в папки Android
cp android_icons/ic_launcher_48.png android/app/src/main/res/mipmap-mdpi/ic_launcher.png
cp android_icons/ic_launcher_72.png android/app/src/main/res/mipmap-hdpi/ic_launcher.png
cp android_icons/ic_launcher_96.png android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
cp android_icons/ic_launcher_144.png android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
cp android_icons/ic_launcher_192.png android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png

echo "=== Создание Linux иконки ==="
# Создаем иконку для Linux
$IMAGEMAGICK_CMD icon.png -resize 256x256 linux/fsda.png

# Очищаем временные файлы
rm -rf temp_icons
rm -rf android_icons

echo "✅ Все иконки созданы:"
echo "  - Windows: windows/runner/resources/app_icon.ico"
echo "  - Android: android/app/src/main/res/mipmap-*/ic_launcher.png"
echo "  - Linux: linux/fsda.png"

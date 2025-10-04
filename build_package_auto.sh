#!/bin/bash

# Скрипт для автоматической сборки пакета FSDA из существующего AppImage
echo "📦 Автоматическая сборка пакета FSDA для Arch Linux..."

# Проверяем наличие необходимых инструментов
if ! command -v makepkg &> /dev/null; then
    echo "❌ makepkg не найден. Установите base-devel:"
    echo "   sudo pacman -S base-devel"
    exit 1
fi

# Проверяем наличие AppImage
if [ ! -f "FSDA-x86_64.AppImage" ]; then
    echo "❌ FSDA-x86_64.AppImage не найден в текущей директории."
    echo "   Убедитесь, что AppImage находится в папке FSDA."
    exit 1
fi

# Проверяем наличие PKGBUILD-local
if [ ! -f "PKGBUILD-local" ]; then
    echo "❌ PKGBUILD-local не найден. Запустите скрипт из директории с PKGBUILD-local."
    exit 1
fi

echo "🔍 Получаем SHA256 хеш AppImage..."
APPIMAGE_HASH=$(sha256sum FSDA-x86_64.AppImage | cut -d' ' -f1)
echo "   Хеш: $APPIMAGE_HASH"

echo "📝 Обновляем PKGBUILD-bin с реальным хешем..."
# Создаем временный файл с обновленным хешем
sed "s/sha256sums=('SKIP')/sha256sums=('$APPIMAGE_HASH')/" PKGBUILD-bin > PKGBUILD-bin.tmp
mv PKGBUILD-bin.tmp PKGBUILD-bin

# Создаем временную директорию для сборки
BUILD_DIR="fsda-build"
echo "📁 Создаем директорию сборки: $BUILD_DIR"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "📋 Копируем PKGBUILD-local как PKGBUILD..."
cp ../PKGBUILD-local PKGBUILD

echo "📋 Копируем AppImage в директорию сборки..."
cp ../FSDA-x86_64.AppImage .

echo "📦 Запускаем makepkg..."
if makepkg -s; then
    echo "✅ Пакет успешно собран!"
    echo ""
    echo "📄 Созданные файлы:"
    ls -la *.pkg.tar.zst
    echo ""
    echo "🚀 Для установки выполните:"
    echo "   sudo pacman -U fsda-bin-*.pkg.tar.zst"
    echo ""
    echo "📋 Для удаления выполните:"
    echo "   sudo pacman -R fsda-bin"
else
    echo "❌ Ошибка при сборке пакета!"
    exit 1
fi

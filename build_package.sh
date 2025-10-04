#!/bin/bash

# Скрипт для сборки пакета FSDA для Arch Linux
echo "📦 Сборка пакета FSDA для Arch Linux..."

# Проверяем наличие необходимых инструментов
if ! command -v makepkg &> /dev/null; then
    echo "❌ makepkg не найден. Установите base-devel:"
    echo "   sudo pacman -S base-devel"
    exit 1
fi

# Проверяем, что мы в правильной директории
if [ ! -f "PKGBUILD-bin" ]; then
    echo "❌ PKGBUILD-bin не найден. Запустите скрипт из директории с PKGBUILD-bin."
    exit 1
fi

# Создаем временную директорию для сборки
BUILD_DIR="fsda-build"
if [ -d "$BUILD_DIR" ]; then
    echo "🗑️  Удаляем существующую директорию $BUILD_DIR"
    rm -rf "$BUILD_DIR"
fi

mkdir "$BUILD_DIR"
cd "$BUILD_DIR"

# Копируем PKGBUILD
cp ../PKGBUILD-bin PKGBUILD

echo "🔨 Сборка пакета..."
makepkg -s

if [ $? -eq 0 ]; then
    echo "✅ Пакет успешно собран!"
    echo ""
    echo "📋 Собранные файлы:"
    ls -la *.pkg.tar.zst
    
    echo ""
    echo "🚀 Для установки пакета выполните:"
    echo "   sudo pacman -U fsda-bin-*.pkg.tar.zst"
else
    echo "❌ Ошибка при сборке пакета"
    exit 1
fi

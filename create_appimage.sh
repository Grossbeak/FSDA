#!/bin/bash

# Скрипт для создания AppImage локально
echo "🐧 Создание AppImage для Linux..."

# Проверяем наличие Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter не найден. Установите Flutter и добавьте в PATH."
    exit 1
fi

# Проверяем наличие необходимых зависимостей для Linux
echo "🔍 Проверка зависимостей для Linux..."
if ! pkg-config --exists gtk+-3.0; then
    echo "❌ GTK+3 не найден. Установите зависимости:"
    echo "   Arch Linux: sudo pacman -S gtk3 cmake ninja clang pkg-config"
    echo "   Ubuntu/Debian: sudo apt-get install gtk+-3.0-dev cmake ninja-build clang pkg-config"
    exit 1
fi

echo "📦 Получение зависимостей..."
flutter pub get

echo "🎨 Создание иконки..."
# Определяем команду для ImageMagick
if command -v magick &> /dev/null; then
    IMAGEMAGICK_CMD="magick"
else
    IMAGEMAGICK_CMD="convert"
fi

$IMAGEMAGICK_CMD icon.png -resize 256x256 linux/fsda.png

echo "🔨 Сборка Linux приложения..."
flutter build linux --release

echo "📥 Скачивание appimagetool..."
if [ ! -f "appimagetool-x86_64.AppImage" ]; then
    wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x appimagetool-x86_64.AppImage
fi

echo "📁 Создание структуры AppImage..."
mkdir -p AppDir/usr/bin
mkdir -p AppDir/usr/share/applications
mkdir -p AppDir/usr/share/icons/hicolor/256x256/apps

# Копируем исполняемый файл и все зависимости
cp -r build/linux/x64/release/bundle/* AppDir/usr/bin/

# Копируем иконку в несколько мест
cp linux/fsda.png AppDir/usr/share/icons/hicolor/256x256/apps/fsda.png
cp linux/fsda.png AppDir/fsda.png
cp linux/fsda.png AppDir/.DirIcon

# Создаем символическую ссылку на иконку в корне AppImage
ln -sf fsda.png AppDir/icon.png

echo "🚀 Создание AppRun (точка входа)..."
cat > AppDir/AppRun << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"

# Устанавливаем переменные окружения для иконки
export APPIMAGE_ICON_PATH="$PWD/fsda.png"
export XDG_DATA_DIRS="$PWD/usr/share:$XDG_DATA_DIRS"

exec ./usr/bin/fsda "$@"
EOF
chmod +x AppDir/AppRun

echo "📄 Создание .desktop файла..."
cat > AppDir/fsda.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=FSDA - Steam Guard Desktop
Comment=Steam Guard Desktop App
Exec=fsda
Icon=fsda
Terminal=false
Categories=Utility;
StartupWMClass=fsda
EOF

echo "🔧 Создание AppImage..."
./appimagetool-x86_64.AppImage AppDir FSDA-x86_64.AppImage

echo "🧹 Очистка временных файлов..."
rm -rf AppDir

echo "✅ AppImage создан: FSDA-x86_64.AppImage"
echo "🚀 Для запуска: ./FSDA-x86_64.AppImage"
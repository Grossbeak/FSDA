# Maintainer: Pavel <pavelroot@example.com>
pkgname=fsda
pkgver=1.0.0
pkgrel=1
pkgdesc="FSDA - Steam Guard Desktop App - Desktop application for Steam Guard management"
arch=('x86_64')
url="https://github.com/pavelroot/FSDA"
license=('MIT')
depends=('gtk3' 'glib2' 'flutter')
makedepends=('flutter' 'cmake' 'ninja' 'clang' 'pkg-config' 'imagemagick')
source=("https://github.com/pavelroot/FSDA/releases/download/v${pkgver}/FSDA-x86_64.AppImage")
sha256sums=('SKIP')  # Замените на реальный SHA256 после создания релиза

package() {
    cd "$srcdir"
    
    # Создаем директории
    install -dm755 "$pkgdir/usr/bin"
    install -dm755 "$pkgdir/usr/share/applications"
    install -dm755 "$pkgdir/usr/share/icons/hicolor/256x256/apps"
    install -dm755 "$pkgdir/usr/share/licenses/$pkgname"
    
    # Извлекаем AppImage
    chmod +x FSDA-x86_64.AppImage
    ./FSDA-x86_64.AppImage --appimage-extract
    
    # Копируем исполняемый файл
    install -Dm755 squashfs-root/usr/bin/fsda "$pkgdir/usr/bin/fsda"
    
    # Копируем библиотеки
    cp -r squashfs-root/usr/bin/lib "$pkgdir/usr/bin/"
    
    # Копируем данные приложения
    cp -r squashfs-root/usr/bin/data "$pkgdir/usr/bin/"
    
    # Копируем иконку
    install -Dm644 squashfs-root/fsda.png "$pkgdir/usr/share/icons/hicolor/256x256/apps/fsda.png"
    
    # Создаем desktop файл
    cat > "$pkgdir/usr/share/applications/fsda.desktop" << EOF
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
    
    # Копируем лицензию (если есть)
    if [ -f "squashfs-root/usr/share/licenses/fsda/LICENSE" ]; then
        install -Dm644 squashfs-root/usr/share/licenses/fsda/LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
    fi
    
    # Очищаем временные файлы
    rm -rf squashfs-root
}


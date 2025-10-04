#!/bin/bash

# Скрипт для загрузки FSDA в AUR
echo "🚀 Загрузка FSDA в AUR..."

# Проверяем наличие необходимых инструментов
if ! command -v git &> /dev/null; then
    echo "❌ Git не найден. Установите git."
    exit 1
fi

if ! command -v makepkg &> /dev/null; then
    echo "❌ makepkg не найден. Установите base-devel."
    exit 1
fi

# Проверяем, что мы в правильной директории
if [ ! -f "PKGBUILD" ]; then
    echo "❌ PKGBUILD не найден. Запустите скрипт из директории с PKGBUILD."
    exit 1
fi

# Проверяем PKGBUILD на ошибки
echo "🔍 Проверка PKGBUILD..."
if ! namcap PKGBUILD 2>/dev/null; then
    echo "⚠️  namcap не найден, пропускаем проверку"
fi

# Обновляем .SRCINFO
echo "📝 Обновление .SRCINFO..."
makepkg --printsrcinfo > .SRCINFO

# Проверяем, что есть релиз на GitHub
echo "🔍 Проверка релиза на GitHub..."
VERSION=$(grep "pkgver=" PKGBUILD | cut -d'=' -f2)
echo "Версия: $VERSION"

# Клонируем AUR репозиторий
echo "📥 Клонирование AUR репозитория..."
if [ -d "aur-fsda" ]; then
    echo "🗑️  Удаляем существующую директорию aur-fsda"
    rm -rf aur-fsda
fi

git clone ssh://aur@aur.archlinux.org/fsda.git aur-fsda
cd aur-fsda

# Копируем файлы
echo "📋 Копирование файлов..."
cp ../PKGBUILD .
cp ../.SRCINFO .

# Проверяем изменения
echo "🔍 Проверка изменений..."
if git diff --quiet; then
    echo "ℹ️  Нет изменений для загрузки"
    cd ..
    rm -rf aur-fsda
    exit 0
fi

# Показываем изменения
echo "📝 Изменения:"
git diff

# Подтверждение
echo ""
echo "❓ Загрузить изменения в AUR? (y/N)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "❌ Отменено пользователем"
    cd ..
    rm -rf aur-fsda
    exit 0
fi

# Загружаем в AUR
echo "🚀 Загрузка в AUR..."
git add PKGBUILD .SRCINFO
git commit -m "Update to version $VERSION"
git push origin master

echo "✅ Успешно загружено в AUR!"
echo "🔗 Ссылка: https://aur.archlinux.org/packages/fsda"

# Очищаем
cd ..
rm -rf aur-fsda

echo "🎉 Готово! Пользователи смогут установить пакет командой:"
echo "   yay -S fsda"
echo "   или"
echo "   paru -S fsda"


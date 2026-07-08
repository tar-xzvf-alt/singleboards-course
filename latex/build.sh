#!/bin/bash
# Сборка методического пособия PDF из лабораторных работ
# Требования: pandoc, xelatex

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT="${REPO_ROOT}/labs_pdf/metodichka.pdf"
TMP_MD="/tmp/rv_course_all_labs.md"
BUILD_TEMP="${REPO_ROOT}/_build_temp.md"

cleanup() {
    rm -f "$BUILD_TEMP" "$TMP_MD"
}
trap cleanup EXIT

echo "=== Сборка методического пособия ==="

# Проверка зависимостей
for cmd in pandoc xelatex; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ОШИБКА: $cmd не найден. Установите: apt-get install pandoc texlive-xetex texlive-latex-extra" >&2
        exit 1
    fi
done

# Склеиваем лабораторные из labs/metodichka.md в один файл
# с YAML-заголовком для pandoc. Файл labs/metodichka.md является источником порядка лабораторных.
echo "1. Склеивание лабораторных работ..."
cat >"$TMP_MD" <<'YAML'
---
title: "Linux на встраиваемых устройствах"
subtitle: "Лабораторный практикум"
author: "Лаборатория «СГУ — Базальт СПО»"
date: "2026"
lang: ru-RU
toc: true
toc-depth: 0
documentclass: scrreprt
papersize: a4
fontsize: 12pt
mainfont: "DejaVu Serif"
monofont: "DejaVu Sans Mono"
---

YAML

while IFS= read -r line; do
    if [[ ! "$line" =~ @import[[:space:]]+\"(lab[0-9]+\.md)\" ]]; then
        continue
    fi

    LAB_NAME="${BASH_REMATCH[1]}"
    LAB_FILE="${REPO_ROOT}/labs/${LAB_NAME}"
    if [ ! -f "$LAB_FILE" ]; then
        echo "ОШИБКА: не найден $LAB_FILE" >&2
        exit 1
    fi
    echo "   + ${LAB_NAME}"
    cat "$LAB_FILE" >>"$TMP_MD"
    echo "" >>"$TMP_MD"
done < "${REPO_ROOT}/labs/metodichka.md"

# Сборка PDF через pandoc + xelatex
echo "2. Генерация PDF (pandoc → xelatex)..."
mkdir -p "$(dirname "$OUTPUT")"

# Обработка изображений: в .md они ссылаются как ../pictures/имя.jpg
# При сборке из каталога labs/ путь должен быть корректным.
# Запускаем pandoc из REPO_ROOT, а склеенный .md лежит в /tmp — пути ../pictures/ не сработают.
# Решение: скопировать склеенный .md в REPO_ROOT, собрать оттуда, потом удалить.
cp "$TMP_MD" "$BUILD_TEMP"

# Исправляем пути к картинкам: ../pictures/ → pictures/ (т.к. pandoc запускается из корня репозитория)
sed -i 's|\.\./pictures/|pictures/|g' "$BUILD_TEMP"

cd "$REPO_ROOT"
pandoc "_build_temp.md" \
    -o "labs_pdf/metodichka.pdf" \
    --pdf-engine=xelatex \
    --include-in-header="latex/header.tex" \
    --lua-filter="latex/style-code.lua" \
    --toc \
    --number-sections \
    --standalone \
    --metadata date="$(date '+%d.%m.%Y')"

echo "=== Готово: ${OUTPUT} ==="

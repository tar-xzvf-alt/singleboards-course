#!/bin/bash
# Сборка отдельных лабораторных и полной методички через Pandoc/XeLaTeX.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="${REPO_ROOT}/labs_pdf"
TARGET="${1:-manual}"
TEMP_FILES=()

if [ -z "${SOURCE_DATE_EPOCH:-}" ]; then
    SOURCE_DATE_EPOCH="$(git -C "$REPO_ROOT" log -1 --format=%ct 2>/dev/null || true)"
    SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-0}"
    export SOURCE_DATE_EPOCH
fi
export FORCE_SOURCE_DATE=1
export TZ=UTC

cleanup() {
    if [ "${#TEMP_FILES[@]}" -gt 0 ]; then
        rm -f "${TEMP_FILES[@]}"
    fi
}
trap cleanup EXIT

for cmd in pandoc xelatex; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ОШИБКА: $cmd не найден. Установите pandoc, texlive-xetex и texlive-latex-extra." >&2
        exit 1
    fi
done

mkdir -p "$OUTPUT_DIR"

PANDOC_COMMON=(
    --from=markdown
    --pdf-engine=xelatex
    --include-in-header="${REPO_ROOT}/latex/header.tex"
    --lua-filter="${REPO_ROOT}/latex/style-code.lua"
    --resource-path="${REPO_ROOT}/labs:${REPO_ROOT}"
    --standalone
    --metadata=lang:ru-RU
    --metadata=documentclass:scrreprt
    --metadata=papersize:a4
    --metadata=fontsize:12pt
    "--variable=mainfont:DejaVu Serif"
    "--variable=monofont:DejaVu Sans Mono"
)

build_lab() {
    local number="$1"
    local input="${REPO_ROOT}/labs/lab${number}.md"
    local output="${OUTPUT_DIR}/lab${number}.pdf"

    if [ ! -f "$input" ]; then
        echo "ОШИБКА: не найден $input" >&2
        exit 1
    fi

    echo "Сборка лабораторной №${number}..."
    pandoc "$input" -o "$output" "${PANDOC_COMMON[@]}"
    echo "Готово: $output"
}

build_manual() {
    local manifest="${REPO_ROOT}/labs/metodichka.md"
    local combined
    combined="$(mktemp "${TMPDIR:-/tmp}/singleboards-course.XXXXXX")"
    TEMP_FILES+=("$combined")

    cat >"$combined" <<'YAML'
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

    echo "Сборка методического пособия..."
    while IFS= read -r line; do
        if [[ ! "$line" =~ @import[[:space:]]+\"(lab[0-9]+\.md)\" ]]; then
            continue
        fi

        local lab_name="${BASH_REMATCH[1]}"
        local lab_file="${REPO_ROOT}/labs/${lab_name}"
        if [ ! -f "$lab_file" ]; then
            echo "ОШИБКА: не найден $lab_file" >&2
            exit 1
        fi
        echo "  + ${lab_name}"
        cat "$lab_file" >>"$combined"
        printf '\n' >>"$combined"
    done <"$manifest"

    pandoc "$combined" \
        -o "${OUTPUT_DIR}/metodichka.pdf" \
        "${PANDOC_COMMON[@]}" \
        --toc \
        --number-sections \
        --top-level-division=chapter
    echo "Готово: ${OUTPUT_DIR}/metodichka.pdf"
}

build_answers() {
    local input="${REPO_ROOT}/labs/control_questions.md"
    local output="${OUTPUT_DIR}/control_questions.pdf"

    echo "Сборка ответов на контрольные вопросы..."
    pandoc "$input" -o "$output" "${PANDOC_COMMON[@]}" --toc
    echo "Готово: $output"
}

case "$TARGET" in
    manual)
        build_manual
        ;;
    lab[1-9]|lab1[0-3])
        build_lab "${TARGET#lab}"
        ;;
    labs)
        for number in {1..13}; do
            build_lab "$number"
        done
        ;;
    answers)
        build_answers
        ;;
    all)
        for number in {1..13}; do
            build_lab "$number"
        done
        build_manual
        build_answers
        ;;
    *)
        echo "Использование: $0 [manual|lab1..lab13|labs|answers|all]" >&2
        exit 2
        ;;
esac

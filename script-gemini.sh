#!/usr/bin/bash

# --- ПРОВЕРКА АРГУМЕНТОВ ---
if [ "$#" -lt 2 ]; then
    echo "Использование: $0 <имя_выходного_файла> <расширение1> [расширение2] ..."
    exit 1
fi

OUTPUT_FILE="$1"
shift

# Очистка файла (создание или обнуление)
> "$OUTPUT_FILE"

# --- ПОДГОТОВКА FIND ---
# Формируем аргументы. Используем -iname для поиска без учета регистра (Yml = yml)
FIND_ARGS=()
FIRST=true

for ext in "$@"; do
    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        FIND_ARGS+=("-o")
    fi
    # Добавляем поиск, соответствующий расширению
    FIND_ARGS+=("-iname" "*.$ext")
done

echo "--- СТАРТ РАБОТЫ ---"
echo "Путь в: $(pwd)"
echo "Расширения: $@"

# --- ПОИСК ---
# Логика:
# 1. find . -type f        -> Найти все файлы
# 2. -not -path '*/.*'     -> Исключить пути, в которых есть точка (скрытые папки, такие как .git, .ansible и т.д.)
# 3. \( ... \)             -> Группируем логику ИЛИ, соответствующую расширениям

find . -type f -not -path '*/.*' \( "${FIND_ARGS[@]}" \) -print0 | 
while IFS= read -r -d '' file; do

    # Пропускаем сам выходной файл
    clean_name="${file#./}"
    if [ "$clean_name" == "$OUTPUT_FILE" ]; then
        continue
    fi

    echo "Копирую файл: $file"

    # Записываем в выходной файл
    echo "--------------------------------------------------" >> "$OUTPUT_FILE"
    echo "Файл: $file"                                      >> "$OUTPUT_FILE"
    echo "--------------------------------------------------" >> "$OUTPUT_FILE"
    
    cat "$file" >> "$OUTPUT_FILE"
    echo -e "\n\n" >> "$OUTPUT_FILE"

done

# --- ЗАВЕРШЕНИЕ РАБОТЫ ---
if [ -s "$OUTPUT_FILE" ]; then
    echo "---"
    echo "Готово! Содержимое записано в $OUTPUT_FILE"
    echo "Размер файла: $(du -h "$OUTPUT_FILE" | cut -f1)"
else
    echo "---"
    echo "Предупреждение: Файл $OUTPUT_FILE пуст!" 
    echo "Поиск завершен, но ничего не найдено."
    echo "Совет: проверьте расширения. Возможно нужно .yml и .yaml"
fi
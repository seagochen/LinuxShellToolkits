#!/bin/bash

usage() {
    echo "Usage: $0 -d <directory>"
    exit 1
}

DIRECTORY=""

while getopts "d:" opt; do
    case $opt in
        d) DIRECTORY=$OPTARG ;;
        *) usage ;;
    esac
done

if [ -z "$DIRECTORY" ]; then
    usage
fi

if [ ! -d "$DIRECTORY" ]; then
    echo "Error: Directory '$DIRECTORY' does not exist."
    exit 1
fi

FILES=("$DIRECTORY"/*)
TOTAL_FILES=${#FILES[@]}
if [ $TOTAL_FILES -eq 0 ]; then
    echo "Error: No files found in directory '$DIRECTORY'."
    exit 1
fi

# 固定使用6位数的格式
PAD_WIDTH=6

pad_number() {
    printf "%0${PAD_WIDTH}d" "$1"
}

COUNT=1
for FILE in "${FILES[@]}"; do
    BASENAME=$(basename "$FILE")
    EXT=""
    # 如果文件名中包含 . 且不是以 . 开头，提取扩展名
    if [[ "$BASENAME" == *.* && "$BASENAME" != .* ]]; then
        EXT=".${BASENAME##*.}"
    fi
    NEWNAME="$(pad_number $COUNT)${EXT}"
    mv "$FILE" "$DIRECTORY/$NEWNAME"
    COUNT=$((COUNT+1))
done

echo "Files have been renamed successfully."

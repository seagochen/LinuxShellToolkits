#!/bin/bash

usage() {
    echo "Usage: $0 -d <directory> -o <operation> -p <pattern> [-r <replacement>] [-t <type>]"
    echo "  -d  指定目标目录"
    echo "  -o  操作类型：prefix、suffix、replace"
    echo "  -p  用于重命名的模式字符串"
    echo "  -r  替换字符串（仅当操作为 replace 时需要）"
    echo "  -t  类型选项：increment 或 hash（可选）"
    exit 1
}

# 默认值
DIRECTORY=""
OPERATION=""
PATTERN=""
REPLACEMENT=""
TYPE=""

while getopts "d:o:p:r:t:" opt; do
    case $opt in
        d) DIRECTORY=$OPTARG ;;
        o) OPERATION=$OPTARG ;;
        p) PATTERN=$OPTARG ;;
        r) REPLACEMENT=$OPTARG ;;
        t) TYPE=$OPTARG ;;
        *) usage ;;
    esac
done

if [ -z "$DIRECTORY" ] || [ -z "$OPERATION" ] || [ -z "$PATTERN" ]; then
    usage
fi

if [ ! -d "$DIRECTORY" ]; then
    echo "Error: Directory '$DIRECTORY' does not exist."
    exit 1
fi

# 获取文件列表并检查数量
FILES=("$DIRECTORY"/*)
TOTAL_FILES=${#FILES[@]}
if [ $TOTAL_FILES -eq 0 ]; then
    echo "Error: No files found in directory '$DIRECTORY'."
    exit 1
fi

# 动态计算编号宽度，最小为4位
PAD_WIDTH=${#TOTAL_FILES}
if [ "$PAD_WIDTH" -lt 4 ]; then
    PAD_WIDTH=4
fi

pad_number() {
    printf "%0${PAD_WIDTH}d" "$1"
}

generate_hash() {
    echo -n "$1" | md5sum | cut -c1-8
}

# 初始化计数器
COUNT=1

for FILE in "${FILES[@]}"; do
    BASENAME=$(basename "$FILE")
    EXT="${BASENAME##*.}"
    FILENAME="${BASENAME%.*}"

    case $OPERATION in
        prefix)
            if [ "$TYPE" == "increment" ]; then
                PADDED=$(pad_number $COUNT)
                NEWNAME="${PATTERN}${PADDED}.${EXT}"
            elif [ "$TYPE" == "hash" ]; then
                HASH=$(generate_hash "$BASENAME")
                NEWNAME="${PATTERN}${HASH}.${EXT}"
            else
                NEWNAME="${PATTERN}${BASENAME}"
            fi
            ;;
        suffix)
            if [ "$TYPE" == "increment" ]; then
                PADDED=$(pad_number $COUNT)
                NEWNAME="${FILENAME}${PATTERN}${PADDED}.${EXT}"
            elif [ "$TYPE" == "hash" ]; then
                HASH=$(generate_hash "$BASENAME")
                NEWNAME="${FILENAME}${PATTERN}${HASH}.${EXT}"
            else
                NEWNAME="${FILENAME}${PATTERN}.${EXT}"
            fi
            ;;
        replace)
            if [ -z "$REPLACEMENT" ]; then
                echo "Error: Replacement string is required for 'replace' operation."
                exit 1
            fi
            if [ "$TYPE" == "increment" ]; then
                PADDED=$(pad_number $COUNT)
                NEWNAME=$(echo "$BASENAME" | sed "s/$PATTERN/${REPLACEMENT}${PADDED}/g")
            elif [ "$TYPE" == "hash" ]; then
                HASH=$(generate_hash "$BASENAME")
                NEWNAME=$(echo "$BASENAME" | sed "s/$PATTERN/${REPLACEMENT}${HASH}/g")
            else
                NEWNAME=$(echo "$BASENAME" | sed "s/$PATTERN/$REPLACEMENT/g")
            fi
            ;;
        *)
            echo "Error: Invalid operation '$OPERATION'."
            exit 1
            ;;
    esac

    mv "$FILE" "$DIRECTORY/$NEWNAME"
    COUNT=$((COUNT+1))
done

echo "Batch rename operation '$OPERATION' with type '$TYPE' completed successfully."

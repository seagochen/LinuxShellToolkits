import os
import chardet
import re


def count_files(folder_path):
    return sum([len(files) for r, d, files in os.walk(folder_path)])


def is_binary(file_path):
    with open(file_path, 'rb') as f:
        initial_bytes = f.read(1024)
    return b'\0' in initial_bytes


def detect_non_english_files(folder_path):
    non_english_files = []
    total_files = count_files(folder_path)
    processed_files = 0
    for root, dirs, files in os.walk(folder_path):
        for file in files:
            file_path = os.path.join(root, file)
            if is_binary(file_path):
                continue
            with open(file_path, 'rb') as f:
                raw_data = f.read()
                encoding = chardet.detect(raw_data)['encoding']
                if encoding:
                    try:
                        content = raw_data.decode(encoding)
                        if re.search(r'[\u4e00-\u9fff\u3040-\u30ff]', content):
                            non_english_files.append(file_path)
                    except UnicodeDecodeError:
                        pass
            processed_files += 1
            print(f"Processed {processed_files}/{total_files} files")
    return non_english_files


if __name__ == "__main__":
    import sys

    if len(sys.argv) != 2:
        print("Usage: python find_utf8_chars.py <folder_path>")
        sys.exit(1)

    folder_path = sys.argv[1]
    non_english_files = detect_non_english_files(folder_path)
    if non_english_files:
        print("Files contain Chinese or Japanese:")
        for file_path in non_english_files:
            print(file_path)
    else:
        print("No non-English files found.")
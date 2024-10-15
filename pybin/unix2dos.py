import os
import sys

def unix2dos(file_path):
    """Convert LF to CRLF in the given file."""
    try:
        with open(file_path, 'rb') as f:
            content = f.read()

        new_content = content.replace(b'\n', b'\r\n')

        # Only write if content has changed
        if content != new_content:
            with open(file_path, 'wb') as f:
                f.write(new_content)
            print(f"{file_path} 已转换为 DOS 格式")
        else:
            print(f"{file_path} 已是 DOS 格式，无需转换")

    except Exception as e:
        print(f"处理文件 {file_path} 时出错: {e}")

def process_path(path):
    """Process a file or folder for unix2dos conversion."""
    if os.path.isfile(path):
        unix2dos(path)
    elif os.path.isdir(path):
        for root, _, files in os.walk(path):
            for file in files:
                file_path = os.path.join(root, file)
                unix2dos(file_path)
    else:
        print(f"路径 {path} 无效")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python unix2dos.py <文件/文件夹路径>")
        sys.exit(1)

    path = sys.argv[1].strip()
    process_path(path)

import os

def batch_chmod(path, file_mode=0o644, dir_mode=0o755):
    for root, dirs, files in os.walk(path):
        for dir_name in dirs:
            dir_path = os.path.join(root, dir_name)
            os.chmod(dir_path, dir_mode)
            print(f"Directory permissions changed: {dir_path}")
        for file_name in files:
            file_path = os.path.join(root, file_name)
            os.chmod(file_path, file_mode)
            print(f"File permissions changed: {file_path}")

if __name__ == "__main__":
    import sys

    if len(sys.argv) != 2:
        print("Usage: python batch_chmod.py <path>")
        sys.exit(1)

    path = sys.argv[1]
    batch_chmod(path)
import os
import sys

def dos2unix(filepath):
    """
    将指定文件的换行符从 DOS (CRLF) 转换为 Unix (LF)。

    Args:
        filepath (str): 要转换的文件的路径。
    """
    if not os.path.exists(filepath):
        print(f"错误: 文件不存在 -> {filepath}")
        return

    print(f"正在处理文件: {filepath}...")
    try:
        # 以二进制模式读取文件内容，这样可以准确识别 \r\n
        with open(filepath, 'rb') as f:
            content = f.read()

        # 将所有的 CRLF (\r\n) 替换为 LF (\n)
        # 注意：这里是字节串的替换
        new_content = content.replace(b'\r\n', b'\n')

        # 如果文件内容没有改变 (即原本就是 Unix 格式或没有 CRLF)，则不写入
        if new_content == content:
            print(f"文件已经是 Unix 格式，无需转换 -> {filepath}")
            return

        # 以二进制模式写入文件内容
        # 'wb' 会截断文件（清空内容）然后写入新内容
        with open(filepath, 'wb') as f:
            f.write(new_content)

        print(f"成功将文件转换为 Unix 格式 -> {filepath}")

    except Exception as e:
        print(f"处理文件时发生错误 {filepath}: {e}")

if __name__ == "__main__":
    # 检查命令行参数
    if len(sys.argv) < 2:
        print("用法: python3 dos2unix_converter.py <文件1> [文件2] ...")
        print("示例: python3 dos2unix_converter.py install_cmake.sh my_script.py")
        sys.exit(1)

    # 遍历所有命令行参数（文件路径）并进行转换
    for arg_filepath in sys.argv[1:]:
        dos2unix(arg_filepath)

    print("\n所有指定文件处理完毕。")


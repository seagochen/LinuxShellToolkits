import os
from PIL import Image

def convert_images(input_dir, output_dir, from_format, to_format):
    """
    批量转换图像格式
    :param input_dir: 输入目录
    :param output_dir: 输出目录
    :param from_format: 源文件格式 (例如 'jpg', 'png')
    :param to_format: 目标文件格式 (例如 'png', 'jpg')
    """
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    for filename in os.listdir(input_dir):
        if filename.lower().endswith(f".{from_format.lower()}"):
            img_path = os.path.join(input_dir, filename)
            img = Image.open(img_path)
            base_name = os.path.splitext(filename)[0]
            output_path = os.path.join(output_dir, f"{base_name}.{to_format.lower()}")
            img.save(output_path)
            print(f"Converted {filename} to {to_format.upper()}")
    print(f"All {from_format.upper()} images converted to {to_format.upper()} in '{output_dir}'")

if __name__ == "__main__":
    # 获取用户输入
    input_dir = input("请输入图像的输入目录: ").strip()
    output_dir = input("请输入图像的输出目录: ").strip()
    from_format = input("请输入源文件格式 (例如 'jpg', 'png'): ").strip().lower()
    to_format = input("请输入目标文件格式 (例如 'png', 'jpg'): ").strip().lower()

    # 验证输入格式
    valid_formats = ['jpg', 'png']
    if from_format not in valid_formats or to_format not in valid_formats:
        print("格式不支持！请使用 'jpg' 或 'png' 作为格式。")
    else:
        convert_images(input_dir, output_dir, from_format, to_format)


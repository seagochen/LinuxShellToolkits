import os
import sys
from PIL import Image

def png_to_jpg(folder_path):
    for filename in os.listdir(folder_path):
        if filename.lower().endswith('.png'):
            png_file = os.path.join(folder_path, filename)
            jpg_file = os.path.splitext(png_file)[0] + '.jpg'
            try:
                with Image.open(png_file) as img:
                    # 检查是否有透明通道
                    if img.mode in ('RGBA', 'LA'):
                        background = Image.new('RGB', img.size, (255, 255, 255))
                        background.paste(img, mask=img.split()[3])  # 3是alpha通道
                        background.save(jpg_file, 'JPEG', quality=95)
                    else:
                        img.convert('RGB').save(jpg_file, 'JPEG', quality=95)
                print(f"已转换：{jpg_file}")
            except Exception as e:
                print(f"转换文件 {png_file} 时出错：{e}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("用法: python png_to_jpg.py <文件夹路径>")
        sys.exit(1)
    folder_path = sys.argv[1]
    if not os.path.isdir(folder_path):
        print(f"文件夹 {folder_path} 不存在。")
        sys.exit(1)
    png_to_jpg(folder_path)


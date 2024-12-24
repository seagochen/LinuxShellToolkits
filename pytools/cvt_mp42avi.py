from moviepy.editor import VideoFileClip
import sys
import os

def convert_mp4_to_avi(input_file, output_file):
    clip = VideoFileClip(input_file)
    clip.write_videofile(output_file, codec="png")  # 使用 "png" 编解码器来写入 AVI 格式

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("用法: python convert_mp4_to_avi.py 输入文件.mp4")
        sys.exit(1)

    input_file = sys.argv[1]
    if not os.path.isfile(input_file):
        print(f"文件 {input_file} 不存在。")
        sys.exit(1)

    output_file = os.path.splitext(input_file)[0] + ".avi"
    convert_mp4_to_avi(input_file, output_file)
    print(f"转换完成：{output_file}")


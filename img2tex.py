"""
读取 single image 转换为单行的 rgba8 字符串文件
"""

from PIL import Image
import argparse
import os
import sys

def convert_image_to_hex(input_path, output_path, target_size=512, alpha=0, crop=False):
	try:
		img = Image.open(input_path)
		orig_width, orig_height = img.size

		original_has_alpha = img.mode in ('RGBA', 'LA') or (
			img.mode == 'P' and 'transparency' in img.info
		)
		img = img.convert("RGBA")

		if crop:
			crop_size = min(orig_width, orig_height)
			left = (orig_width - crop_size) // 2
			top = (orig_height - crop_size) // 2
			img = img.crop((left, top, left + crop_size, top + crop_size))

		target_size = (target_size, target_size)

		if not crop:
			ratio = min(target_size[0] / img.width, target_size[1] / img.height)
			new_size = (int(img.width * ratio), int(img.height * ratio))
			resized_img = img.resize(new_size, Image.LANCZOS)
			resized_width, resized_height = resized_img.size

			canvas = Image.new("RGBA", target_size, (0, 0, 0, alpha))

			offset = ((target_size[0] - resized_width) // 2, 
						 (target_size[1] - resized_height) // 2)
			canvas.paste(resized_img, offset, resized_img)
		else:
			canvas = img.resize(target_size, Image.LANCZOS)

		if not original_has_alpha:
			data = canvas.getdata()
			new_data = []
			for item in data:
				# 保留原始RGB，替换Alpha
				new_data.append((item[0], item[1], item[2], alpha))
			canvas.putdata(new_data)

		hex_str = ""
		for pixel in canvas.getdata():
			hex_str += f"{pixel[0]:02X}{pixel[1]:02X}{pixel[2]:02X}{pixel[3]:02X}"

		if output_path:
			with open(output_path, "w") as f:
				f.write(hex_str)
			print(f"转换成功! 输出已保存至: {output_path}")
		else:
			print(hex_str)

	except Exception as e:
		print(f"处理错误: {str(e)}", file=sys.stderr)
		sys.exit(1)

if __name__ == "__main__":
	parser = argparse.ArgumentParser(description="图像转十六进制字符串转换器")
	parser.add_argument("input", help="输入图像路径 (jpg/png/webp)")
	parser.add_argument("-o", "--output", default="output.hex",
						help="输出文件路径 (可选)")
	parser.add_argument("-s", "--size", type=int, choices=[256, 512], default=512,
						help="目标尺寸: 256 或 512 (默认: 512)")
	parser.add_argument("-a", "--alpha", type=int, default=0,
						help="透明度值: 0(透明)~255(不透明) (默认: 0)")
	parser.add_argument("-c", "--crop", action="store_true",
						help="裁剪模式: 取居中最大化的正方形后再缩放")

	args = parser.parse_args()

	if not (0 <= args.alpha <= 255):
		print("错误: 透明度值必须在0~255之间", file=sys.stderr)
		sys.exit(1)

	if not os.path.isfile(args.input):
		print(f"错误: 输入文件不存在 - {args.input}", file=sys.stderr)
		sys.exit(1)

	convert_image_to_hex(args.input, args.output, args.size, args.alpha, args.crop)


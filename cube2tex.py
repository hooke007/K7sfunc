"""
读取 cube 3dlut 转换为单行的 rgba16hf 字符串文件
"""

import argparse
import os
import numpy as np

def convert(input_filepath, output_filepath, alpha_float=1.0):

	hex_parts = []

	print(f"目标格式: rgba16hf (16位半精度浮点)")
	print(f"使用的 Alpha 值: {alpha_float:.4f}")

	try:
		print(f"正在读取输入文件: '{input_filepath}'...")
		with open(input_filepath, 'r') as f_in:
			for i, line in enumerate(f_in):
				line = line.strip()
				if not line or line.startswith('#'):
					continue

				try:
					r_str, g_str, b_str = line.split()
					r_float, g_float, b_float = float(r_str), float(g_str), float(b_str)
					rgba_floats = [r_float, g_float, b_float, alpha_float]
					float16_array = np.array(rgba_floats, dtype=np.float16)
					raw_bytes = float16_array.tobytes()
					hex_color = raw_bytes.hex().upper()
					hex_parts.append(hex_color)

				except (ValueError, IndexError) as e:
					print(f"警告：跳过文件第 {i+1} 行的格式错误数据: '{line}' -> {e}")
					continue

		final_hex_string = "".join(hex_parts)

		print(f"正在写入输出文件: '{output_filepath}'...")
		with open(output_filepath, 'w') as f_out:
			f_out.write(final_hex_string)

		print("\n转换成功！")
		print(f"总共处理了 {len(hex_parts)} 条颜色数据。")

	except FileNotFoundError:
		print(f"错误：找不到输入文件 '{input_filepath}'。请检查路径是否正确。")
	except Exception as e:
		print(f"发生未知错误: {e}")

if __name__ == "__main__":
	parser = argparse.ArgumentParser(
		description="将包含RGB浮点数据的文件转换为用于 mpv 的 rgba16hf 十六进制字符串文件。",
		formatter_class=argparse.RawTextHelpFormatter
	)

	parser.add_argument("input_file", help="输入文件的路径 (例如: data.txt)。")

	parser.add_argument(
		"output_file",
		nargs='?',
		help="输出文件的路径 (例如: output.txt)。\n如果未提供，将根据输入文件名自动生成。"
	)

	parser.add_argument(
		"-a", "--alpha",
		type=float,
		default=1.0, # 对于浮点格式，alpha 默认是 1.0 (完全不透明)
		help="指定 Alpha 透明度值 (0.0 到 1.0 之间的浮点数)。\n默认值: 1.0。"
	)

	args = parser.parse_args()

	output_file = args.output_file
	if not output_file:
		base_name = os.path.splitext(args.input_file)[0]
		output_file = f"{base_name}_output.txt"

	convert(args.input_file, output_file, args.alpha)

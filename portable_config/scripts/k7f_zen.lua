--[[
文档_ https://github.com/hooke007/mpv_PlayKit/discussions/574

免手写vs脚本，一键启用k7f的（部分）功能
当前匹配的 k7sfunc 版本 —— 0.9.0

可用的命令示例（在 input.conf 中写入或在控制台中输入）：

 <KEY>   script-binding k7f_zen/vpy_review               # 检查vpy内容
 <KEY>   script-message-to k7f_zen vpy_update preset 1   # 一键超分
 <KEY>   script-message vpy_update display_h 2160        # 修改最终输出高度

]]

local mp = require("mp")
mp.utils = require("mp.utils")
mp.options = require("mp.options")
local msg = require("mp.msg")

local opt = {
	cache_dir = "~~/",
	debug = false,
	vpy_view = "log",
	preset = 0,
	append = true,

	display_h = -1,
	prescale_h = 720,
	fps_max = 32,
	model_uai = "_test.onnx",
	model_rife = 46,
	inference = "dml",
	gpu = 0,
	gpu_t = 2,
}
local opt_types = {
	cache_dir = "string",
	debug = "boolean",
	vpy_view = "string",
	preset = "number",
	append = "boolean",

	display_h = "number",
	prescale_h = "number",
	fps_max = "number",
	model_uai = "string",
	model_rife = "number",
	inference = "string",
	gpu = "number",
	gpu_t = "number",
}

mp.options.read_options(opt)

local first_run = true
local preset_des = ""
local vpy_full = ""
local vpy_review_content = ""
local output_filename = "k7f_zen.vpy"
local output_directory = (mp.command_native({"expand-path", opt.cache_dir}))
local output_path = (mp.command_native({"expand-path", opt.cache_dir .. output_filename}))

local function parse_opt_val(key, val)
	local target_type = opt_types[key]
	if not target_type then return val end

	if target_type == "number" then
		return tonumber(val) or val
	elseif target_type == "boolean" then
		if val == "true" or val == "yes" or val == "1" then return true
		elseif val == "false" or val == "no" or val == "0" then return false
		else return val end
	else
		return val
	end
end

local function print_table(t, indent)
	indent = indent or 0
	for k, v in pairs(t) do
		local formatting = string.rep("  ", indent) .. tostring(k) .. ": "
		if type(v) == "table" then
			print(formatting)
			print_table(v, indent + 1)
		else
			print(formatting .. tostring(v))
		end
	end
end

local function in_table(val, table)
	for key, _ in pairs(table) do
		if key == val then
			return true
		end
	end
	return false
end

local function filter_state(label, key, value)
	local filters = mp.get_property_native("vf")
	for _, filter in pairs(filters) do
		if filter["label"] == label and (not key or key and filter[key] == value) then return true end
	end
	return false
end

local function display_h()
	local dh = 0
	if opt.display_h < 0 then
		dh = mp.get_property_number("display-height", 0)
		if dh == 0 then
			dh = 1080
			msg.warn("无法获取当前显示设备的高度，假定为 1080")
		end
	elseif opt.display_h == 0 then
		dh = 1000000
	else
		dh = math.floor(opt.display_h)
	end
	return dh
end

local vpy_part_start = [[

import vapoursynth as vs
from vapoursynth import core
import k7sfunc as k7f
clip = video_in
]]

local vpy_part_end = [[
if not (clip == video_in) :
    clip.set_output()
]]

-- 如果低于dh的0.85，执行逻辑
local function vpy_part_uai()
	local vpy_part_uai = [[
if clip.height < var_height * 0.85 :
    clip = k7f.FMT_CTRL(clip, h_max=0)
]]
	local vpy_part_uai_dml = [[
    clip = k7f.UAI_DML(clip, model_pth="var_model_pth", gpu=var_gpu, gpu_t=var_gpu_t)
]]
	local vpy_part_uai_migx = [[
    clip = k7f.UAI_MIGX(clip, model_pth="var_model_pth", fp16_qnt=True, gpu=var_gpu, gpu_t=var_gpu_t)
]]
	local vpy_part_uai_trt = [[
    clip = k7f.UAI_NV_TRT(clip, model_pth="var_model_pth", fp16_qnt=True, gpu=var_gpu, gpu_t=var_gpu_t, st_eng=True)
]]
	local inference_port1 = {
		dml = vpy_part_uai .. vpy_part_uai_dml,
		migx = vpy_part_uai .. vpy_part_uai_migx,
		trt = vpy_part_uai .. vpy_part_uai_trt,
	}
	local vpy_part_fmt = [[
    clip = k7f.FMT_CTRL(clip, h_max=var_h_max)
]]
	vpy_part_uai = inference_port1[opt.inference]:gsub("var_height", display_h()):gsub("var_model_pth", opt.model_uai):gsub("var_gpu", opt.gpu, 1):gsub("var_gpu_t", opt.gpu_t)
	if opt.prescale_h > 0 then
		vpy_part_uai = vpy_part_uai:gsub("h_max=0", "h_max=" .. opt.prescale_h, 1)
	end
	vpy_part_uai = (vpy_part_uai .. vpy_part_fmt):gsub("var_h_max", display_h())
	return vpy_part_uai
end

local function vpy_part_rife()
	local vpy_part_rife = [[
if container_fps <= var_clip_fps :
    clip = k7f.FMT_CTRL(clip, h_max=var_h_max)
]]
	local vpy_part_rife_dml = [[
    clip = k7f.RIFE_DML(clip, model=var_model, fps_in=container_fps, gpu=var_gpu, gpu_t=var_gpu_t)
]]
	local vpy_part_rife_trt = [[
    clip = k7f.RIFE_NV(clip, model=var_model, fps_in=container_fps, gpu=var_gpu, gpu_t=var_gpu_t)
]]
	local inference_port2 = {
	dml = vpy_part_rife .. vpy_part_rife_dml,
	migx = vpy_part_rife .. vpy_part_rife_dml,  -- 尚未支持
	trt = vpy_part_rife .. vpy_part_rife_trt,
}
	vpy_part_rife = inference_port2[opt.inference]:gsub("var_clip_fps", opt.fps_max):gsub("var_h_max", display_h()):gsub("var_model", opt.model_rife):gsub("var_gpu", opt.gpu, 1):gsub("var_gpu_t", opt.gpu_t)
	return vpy_part_rife
end

local function vpy_part_qtgmc()
	local vpy_part_qtgmc = [[
clip = k7f.DEINT_EX(clip, fps_in=container_fps, deint_lv=3, cpu=False, gpu=var_gpu)
]]
	vpy_part_qtgmc = vpy_part_qtgmc:gsub("var_gpu", opt.gpu)
	return vpy_part_qtgmc
end

local function gen_vpy()
	local vpy_cfg = {
		[0] = "",
		[1] = vpy_part_start .. vpy_part_uai() .. vpy_part_end,
		[2] = vpy_part_start .. vpy_part_rife() .. vpy_part_end,
		[12] = vpy_part_start .. vpy_part_uai() .. vpy_part_rife() .. vpy_part_end,
		[21] = vpy_part_start .. vpy_part_rife() .. vpy_part_uai() .. vpy_part_end,
		[3] = vpy_part_start .. vpy_part_qtgmc() .. vpy_part_end,
	}
	local cfg_des = {
		[0] = "无",
		[1] = "自定义超分",
		[2] = "RIFE运动补偿",
		[12] = "自定义超分 + RIFE运动补偿",
		[21] = "RIFE运动补偿 + 自定义超分",
		[3] = "终极去隔行",
	}
	vpy_full = vpy_cfg[opt.preset]
	preset_des = cfg_des[opt.preset]
end

local function update_filter()
	local val_list = {[0] = true, [1] = true, [2] = true, [12] = true, [21] = true, [3] = true,}
	if not val_list[opt.preset] then
		return
	end

	if first_run then
		first_run = false
		if opt.preset == 0 then
			return
		end
	end

	if opt.preset == 0 and filter_state("K7Z") then
		mp.commandv("vf", "remove", "@K7Z")
		msg.info("滤镜已移除")
		return
	elseif opt.preset == 0 and not filter_state("K7Z") then
		return
	end

	gen_vpy()
	vpy_review_content = "vs脚本内容预览：\n####################" .. vpy_full .. "####################"
	if opt.vpy_view == "console" then
		msg.info(vpy_review_content)
	elseif opt.vpy_view == "osd" then
		mp.osd_message(vpy_review_content, 8)
	elseif opt.vpy_view == "log" then
		msg.verbose(vpy_review_content)
	end

	local file, error_message = io.open(output_path, "w")
	if file then
		local success, write_error = file:write(vpy_full)
		file:close()
		if success then
			if opt.append then
				if filter_state("K7Z") then
					mp.commandv("vf", "remove", "@K7Z")
				end
				mp.commandv("vf", "append", "@K7Z:vapoursynth=\"" .. output_path .. "\"")
			else
				if filter_state("K7Z") then
					mp.commandv("vf", "remove", "@K7Z")
				end
				mp.commandv("vf", "pre", "@K7Z:vapoursynth=\"" .. output_path .. "\"")
			end
			msg.info("尝试运行预设：" .. preset_des)
		else
			msg.warn("错误：无法写入文件内容到 '" .. output_path .. "': " .. (write_error or "未知写入错误"))
		end
	else
		msg.warn("错误：无法打开或创建文件 '" .. output_path .. "' 进行写入。")
		msg.warn("原因: " .. (error_message or "未知错误"))
	end
end

update_filter()

mp.add_key_binding(nil, "vpy_review", function()
	if vpy_review_content == "" then
		mp.osd_message("vpy_review 内容为空", 4)
	else
		mp.osd_message(vpy_review_content, 4)
	end
end)
mp.register_script_message("vpy_update", function(usr_opt, opt_val)
	if usr_opt == nil or opt_val == nil then
		mp.osd_message("vpy_update 未传递选项或值", 2)
		return
	end

	if in_table(usr_opt, opt) then
		mp.osd_message("vpy_update 更新选项 <" .. usr_opt .. "> 为值 <" .. opt_val .. ">", 4)
		opt[usr_opt] = parse_opt_val(usr_opt, opt_val)
	else
		mp.osd_message("vpy_update 未知的选项", 2)
		return
	end
	update_filter()
	if opt.debug then
		msg.info("vpy_update 当前所有选项的值：\n####################")
		print_table(opt)
		msg.info("####################")
	end
end)

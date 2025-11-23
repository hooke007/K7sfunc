# K7sfunc

个人 VapourSynth 常用功能合集

[![Python Version](https://img.shields.io/pypi/pyversions/k7sfunc)](https://pypi.org/project/k7sfunc/)
[![License](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](LICENSE)

## 简介

K7sfunc 是一个为mpv实时播放优化的 VapourSynth 视频处理函数库，提供多种视频增强功能。

## 安装

### 基础安装

```bash
pip install k7sfunc
```

### 安装可选依赖

```bash
# 安装 AI 推理支持
pip install k7sfunc[ai]

# 安装所有可选依赖
pip install k7sfunc[all]
```

## 使用示例

编写一个 vpy 脚本以供mpv的 `vf=vapoursynth` 接口调用：

```python
import vapoursynth as vs
from vapoursynth import core
import k7sfunc as k7f

# 链接mpv当前的视频轨
clip = video_in

# 使用DirectML后端加载超分模型并应用
clip = k7f.UAI_DML(input=clip, model_pth="test.onnx")

clip.set_output()
```

## 许可证

GPLv3 License

## 链接

- 完整文档：https://github.com/hooke007/mpv_PlayKit/wiki/3_K7sfunc
- 提问与反馈：https://github.com/hooke007/mpv_PlayKit/discussions

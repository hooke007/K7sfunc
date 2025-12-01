_与 mpv-lazy 预捆绑的版本说明发布在[此处](https://github.com/hooke007/mpv_PlayKit/discussions/635)_

# K7sfunc的Mac专用模块

> 碎念：
> 当初设计 [K7SFUNC](https://github.com/hooke007/mpv_PlayKit/wiki/3_K7sfunc) 的时候完全没有考虑Windows以外的平台，但实际上大多数模块都通用；
> Mac配VS环境和Linux类似，因此不提供一条龙速装服务，仅提供参数和依赖说明；
> 仅考虑Apple silicon芯片的可用性，[M2pro的测试结果参考](https://github.com/hooke007/mpv_PlayKit/pull/632)

当前文档匹配的版本 **1.0.5**

<br>

## 运动补偿

### RIFE_COREML

>[!Important]
>该实现的性能较差，建议切换到 [**RIFE_STD**](https://github.com/hooke007/mpv_PlayKit/wiki/3_K7sfunc#rife_std)

> 所需依赖：  
> pip3: `onnx`  
> plugins: [Miscellaneous_Filters](https://vsdb.top/plugins/misc) + [MVTools](https://vsdb.top/plugins/mv) + [vsmlrt](https://github.com/AmusementClub/vs-mlrt)

```python
RIFE_COREML(input=?, model=46, turbo=True, fps_in=23.976, fps_num=2, fps_den=1, sc_mode=1, be=0, gpu_t=2)
```

用 rife v4+ 补帧整数倍。

||||
|:---|:---|:---|
| <kbd>fps_den</kbd> || 内部锁值始终为1 |
| <kbd>be</kbd> | `0`\|`1` | 优先使用ANE还是GPU |

其它和 [**RIFE_DML**](https://github.com/hooke007/mpv_PlayKit/wiki/3_K7sfunc#rife_dml) 的同名参数完全一致，不再赘述。

## 去块降噪

### BM3D_METAL

> 所需依赖：[BM3DMETAL](https://github.com/Sunflower-Dolls/Vapoursynth-BM3DMETAL)

```python
BM3D_METAL(input=?, nr_lv=[5,0,0], bs_ref=8, bs_out=7, gpu=0)
```

用bm3d算法降噪。

和 [**BM3D_NV**](https://github.com/hooke007/mpv_PlayKit/wiki/3_K7sfunc#bm3d_nv) 的同名参数完全一致，不再赘述。

## 其它

### UAI_COREML

> 所需依赖：  
> pip3: `onnx`  
> plugins: [vsmlrt](https://github.com/AmusementClub/vs-mlrt) + [vszip](https://github.com/dnjulek/vapoursynth-zip)

```python
UAI_COREML(input=?, crc=False, model_pth="", fp16_qnt=False, be=0, gpu_t=2)
```

使用自定义的ONNX模型（仅支持放大类）

||||
|:---|:---|:---|
| <kbd>fp16_qnt</kbd> | `True`\|`False` | fp16量化存在未知性能问题，不要使用 |
| <kbd>be</kbd> | `0`\|`1` | 优先使用ANE还是GPU |

其它和 [**UAI_DML**](https://github.com/hooke007/mpv_PlayKit/wiki/3_K7sfunc#uai_dml) 的同名参数完全一致，不再赘述。

>[!Important]
>也不要使用fp16模型，理由同参数 `fp16_qnt` 。

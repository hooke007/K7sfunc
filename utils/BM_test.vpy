"""PowerShell
./vspipe -p BM_test.vpy . 
"""

import vapoursynth as vs
from vapoursynth import core
import k7sfunc as k7f


D4K = False
D10B = True
#xxx = ...


clip = core.std.BlankClip(width=3840 if D4K else 1920,
						  height=2160 if D4K else 1080, length=1000,
						  format=vs.YUV420P10 if D10B else vs.YUV420P8,
						  color=[128]*3)

#clip = k7f.XXX(input=clip, ...)

clip = core.std.Expr(clip, "x 1 +")
clip = core.std.Expr(clip, "x 1 -")
clip.set_output()

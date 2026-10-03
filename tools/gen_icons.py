"""生成 进阶 Level 的鸿蒙图标资源（与设计稿 token 一致的墨黑 + 橙）。"""
import math
import os
from PIL import Image, ImageDraw

OUT = r"D:\DshProjects\app\LevelUp\entry\src\main\resources\base\media"
os.makedirs(OUT, exist_ok=True)

INK = (26, 23, 20, 255)        # --ink  #1a1714
STAGE = (14, 13, 12, 255)      # --stage #0e0d0c
ACCENT = (233, 132, 37, 255)   # --accent #e98425
ACCENT2 = (255, 107, 61, 255)  # --accent-2 #ff6b3d
PAPER = (255, 255, 255, 255)


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(4))


def radial_glow(size, inner, outer, center=(0.5, 0.30), radius=0.72):
    """径向渐变底色（模拟设计稿的 radial-gradient 橙色光晕）。"""
    img = Image.new("RGBA", (size, size), outer)
    px = img.load()
    cx, cy = center[0] * size, center[1] * size
    r = radius * size
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - cx, y - cy) / r
            if d >= 1.0:
                continue
            # 平滑衰减
            t = (1.0 - d) ** 2.2
            px[x, y] = lerp(outer, inner, t)
    return img


def chevron(draw, cx, cy, width, height, thickness, fill, rounded=True):
    """画一个向上的人字形箭头。"""
    pts = [
        (cx - width / 2, cy + height / 2),
        (cx, cy - height / 2),
        (cx + width / 2, cy + height / 2),
    ]
    draw.line(pts, fill=fill, width=thickness, joint="curve")
    if rounded:
        r = thickness / 2
        for p in pts:
            draw.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=fill)


# ── 1. app_icon.png  216×216 通用图标（深底 + 橙色双箭头）──
S = 216
icon = radial_glow(S, lerp(STAGE, ACCENT, 0.30), STAGE, center=(0.5, 0.34), radius=0.70)
d = ImageDraw.Draw(icon)
# 圆角遮罩
mask = Image.new("L", (S, S), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=int(S * 0.22), fill=255)
icon.putalpha(mask)

d = ImageDraw.Draw(icon)
chevron(d, S * 0.5, S * 0.44, S * 0.46, S * 0.26, int(S * 0.105), ACCENT)
chevron(d, S * 0.5, S * 0.66, S * 0.46, S * 0.26, int(S * 0.105), lerp(ACCENT, ACCENT2, 0.6))
icon.save(os.path.join(OUT, "app_icon.png"))

# ── 2. background.png  288×288 分层图标背景（纯墨黑）──
B = 288
bg = radial_glow(B, lerp(STAGE, ACCENT, 0.16), STAGE, center=(0.5, 0.42), radius=0.75)
bg.save(os.path.join(OUT, "background.png"))

# ── 3. foreground.png  288×288 分层图标前景（安全区内的橙色箭头）──
fg = Image.new("RGBA", (B, B), (0, 0, 0, 0))
d = ImageDraw.Draw(fg)
# 分层图标前景安全区约为画布中央 50%，把图形控制在中央 0.42 内
chevron(d, B * 0.5, B * 0.475, B * 0.30, B * 0.17, int(B * 0.072), ACCENT)
chevron(d, B * 0.5, B * 0.615, B * 0.30, B * 0.17, int(B * 0.072), lerp(ACCENT, ACCENT2, 0.6))
fg.save(os.path.join(OUT, "foreground.png"))

# ── 4. startIcon.png  216×216 启动窗口图标（白底橙色箭头）──
st = Image.new("RGBA", (S, S), PAPER)
d = ImageDraw.Draw(st)
chevron(d, S * 0.5, S * 0.455, S * 0.42, S * 0.24, int(S * 0.10), ACCENT)
chevron(d, S * 0.5, S * 0.655, S * 0.42, S * 0.24, int(S * 0.10), lerp(ACCENT, ACCENT2, 0.6))
st.save(os.path.join(OUT, "startIcon.png"))

for name in ("app_icon.png", "background.png", "foreground.png", "startIcon.png"):
    p = os.path.join(OUT, name)
    with Image.open(p) as im:
        print(f"{name:18s} {im.size[0]}x{im.size[1]} {im.mode}")

"""
把整页设计稿截图裁成单台手机，输出到 docs/screenshots/。

与 gen_screenshots_placeholder.py 的区别：
本脚本产出的是**真实渲染的设计稿**（用无头 Chrome 跑 daily-quests-app.html），
不是占位图。坐标由 design_shot_geom.py 按 CSS 规则推导，不是目测。

注意：这是**设计稿的 iPhone 原型**截图，不是鸿蒙 App 在真机上的运行效果。
覆盖范围也有限 —— 设计稿只有 4 屏，所以只能提供 4 张；
「资料库」「我的」在设计稿里没有画面，仍需 App 实机截图。
"""

import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from design_shot_geom import NAMES, PHONES_PAD_X, PHONE_PAD, PHONE_W, phone_rect

RAW = r"D:\DshProjects\app\LevelUp\docs\_raw\design-full.png"
OUT = r"D:\DshProjects\app\LevelUp\docs\screenshots"
SCALE = 2          # 截图时的 --force-device-scale-factor
WIDTH = 720        # 输出宽度（2x 裁剪后缩到 720，Retina 下清晰）

os.makedirs(OUT, exist_ok=True)


def crop_full(i):
    """整机（含机身与挖孔）。"""
    l, t, r, b = phone_rect(i)
    return (l * SCALE, t * SCALE, r * SCALE, b * SCALE)


def crop_screen(i):
    """只裁屏幕内容，去掉机身外框。"""
    l, t, r, b = phone_rect(i)
    return ((l + PHONE_PAD) * SCALE, (t + PHONE_PAD) * SCALE,
            (r - PHONE_PAD) * SCALE, (b - PHONE_PAD) * SCALE)


if __name__ == "__main__":
    src = Image.open(RAW)
    print("源图:", src.size)

    for i, name in enumerate(NAMES):
        for suffix, box in (("", crop_full(i)), ("-screen", crop_screen(i))):
            part = src.crop(box)
            ratio = WIDTH / part.width
            part = part.resize((WIDTH, round(part.height * ratio)), Image.LANCZOS)
            path = os.path.join(OUT, name + suffix + ".png")
            part.save(path)
            print(f"  {name + suffix:20s} {part.size[0]}x{part.size[1]}  <- {box}")

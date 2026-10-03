"""
生成 README 里截图位置的占位图。

**只在设计稿没有对应画面时才用** —— 目前是「资料库」和「我的」两页：
设计稿的标签栏有这两个入口，但没有画对应屏幕，
所以只能等 HarmonyOS App 的实机截图来补。

另外 4 屏（封面 / 今日 / 详情 / 数据）是 design 稿里真实存在的，
用 tools/crop_design_shots.py 从设计稿渲染图裁出来，不是占位图。

用法：
    python tools/gen_screenshots_placeholder.py            # 生成全部 6 张占位
    python tools/gen_screenshots_placeholder.py 05-library 06-me   # 只补缺的

文件名：
    docs/screenshots/01-cover.png    封面海报   ← 设计稿截图
    docs/screenshots/02-today.png    今日任务   ← 设计稿截图
    docs/screenshots/03-detail.png   任务详情   ← 设计稿截图
    docs/screenshots/04-stats.png    数据统计   ← 设计稿截图
    docs/screenshots/05-library.png  资料库     ← 待实机截图（占位）
    docs/screenshots/06-me.png       我的       ← 待实机截图（占位）

占位图沿用设计令牌（墨黑 #1a1714 / 橙 #e98425 / 暖白 #fdf8f0），
并在图上写明「待实机截图」，避免被误认为真实界面。
"""

import os
import sys

from PIL import Image, ImageDraw, ImageFont

OUT = r"D:\DshProjects\app\LevelUp\docs\screenshots"
os.makedirs(OUT, exist_ok=True)

W, H = 390, 844          # 设计稿 mobile-standard 视口
INK = (26, 23, 20)
ACCENT = (233, 132, 37)
PAPER = (253, 248, 240)
LINE = (235, 230, 221)
MUTED = (108, 102, 96)

# 标题 + 顺序 + 说明
SHOTS = [
    ("01-cover", "封面海报"),
    ("02-today", "今日任务"),
    ("03-detail", "任务详情"),
    ("04-stats", "数据统计"),
    ("05-library", "资料库"),
    ("06-me", "我的"),
]


def font(size):
    """尽量找一个能显示中文的字体，找不到就退回默认位图字体。"""
    for name in ("msyh.ttc", "msyhbd.ttc", "simhei.ttf", "simsun.ttc"):
        p = os.path.join(r"C:\Windows\Fonts", name)
        if os.path.exists(p):
            try:
                return ImageFont.truetype(p, size)
            except Exception:
                pass
    return ImageFont.load_default()


def rounded(draw, box, radius, fill=None, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def make(name, label, index, total):
    img = Image.new("RGB", (W, H), PAPER)
    d = ImageDraw.Draw(img)

    # 顶部：模拟状态栏占位（提示这里会被系统信息占用）
    d.rectangle([0, 0, W, 38], fill=(245, 241, 233))
    d.text((W // 2, 19), "状态栏（时间 / 电量 / 信号）", font=font(13),
           fill=MUTED, anchor="mm")

    # 中部：手机外框示意 + 「截图待补充」
    cx, cy = W // 2, H // 2 - 40
    rounded(d, [cx - 92, cy - 62, cx + 92, cy + 62], 18,
            fill=(255, 255, 255), outline=LINE, width=2)
    d.text((cx, cy - 18), "待实机截图", font=font(20), fill=INK, anchor="mm")
    d.text((cx, cy + 12), "DevEco Studio Previewer", font=font(12),
           fill=MUTED, anchor="mm")
    d.text((cx, cy + 32), f"{index} / {total}", font=font(12), fill=ACCENT, anchor="mm")

    # 底部：页面名
    d.text((cx, H - 96), label, font=font(26), fill=INK, anchor="mm")
    d.text((cx, H - 62), "进阶 Level · HarmonyOS", font=font(13),
           fill=MUTED, anchor="mm")
    # 底部标签栏示意
    d.rectangle([0, H - 40, W, H], fill=(255, 255, 255))
    d.line([0, H - 40, W, H - 40], fill=LINE, width=1)
    d.text((cx, H - 20), "标签栏", font=font(12), fill=MUTED, anchor="mm")

    img.save(os.path.join(OUT, name + ".png"))
    print("wrote", name + ".png")


if __name__ == "__main__":
    # 支持只补部分：python gen_screenshots_placeholder.py 05-library 06-me
    wanted = set(sys.argv[1:])
    for i, (name, label) in enumerate(SHOTS, start=1):
        if wanted and name not in wanted:
            continue
        make(name, label, i, len(SHOTS))
    print("done ->", OUT)

"""
直接绘制并输出 UI 图标 PNG（超采样抗锯齿）。

为什么用 PNG 而不是 SVG
----------------------
HarmonyOS 的 Image.fillColor 只改「填充色」，对 fill="none" + stroke 的
描边式 SVG 无效 —— 它会把形状整体填满（圆环变实心圆盘、加号糊成一团）。
把描边 SVG 转成等价填充路径需要自己做描边求交，容易出错且无法目视验证。

这些图标只有 24px、需要的外观也只有固定几种颜色，因此直接按需要的颜色
输出 PNG 最可靠：所见即所得，并且能用 tools/icon_check/contact-sheet.png
人工核对。每个图标在 4 倍尺寸上绘制再缩小，得到平滑边缘。

注意：应用图标（app_icon / background / foreground / startIcon）由
tools/gen_icons.py 生成，两者互不影响。
"""

import math
import os
from PIL import Image, ImageDraw

MEDIA = r"D:\DshProjects\app\LevelUp\entry\src\main\resources\base\media"
CHECK = r"D:\DshProjects\app\LevelUp\tools\icon_check"
os.makedirs(CHECK, exist_ok=True)

S = 4                      # 超采样倍率
BASE = 24                  # 设计尺寸
INK = (26, 23, 20)
MUTED = (108, 102, 96)
ACCENT = (233, 132, 37)
SUCCESS = (47, 143, 60)
WHITE = (255, 255, 255)


def canvas():
    img = Image.new("RGBA", (BASE * S, BASE * S), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def P(v):
    return v * S


def w(v):
    return max(1, int(round(v * S)))


def save(img, name):
    out = img.resize((BASE, BASE), Image.LANCZOS)
    out.save(os.path.join(MEDIA, name + ".png"))
    return out


def line(d, pts, width, color):
    d.line([(P(x), P(y)) for x, y in pts], fill=color, width=w(width), joint="curve")
    r = width / 2
    for x, y in (pts[0], pts[-1]):
        d.ellipse([P(x - r), P(y - r), P(x + r), P(y + r)], fill=color)


def ring(d, cx, cy, r, width, color):
    d.ellipse([P(cx - r), P(cy - r), P(cx + r), P(cy + r)],
              outline=color, width=w(width))


def poly(d, pts, color):
    d.polygon([(P(x), P(y)) for x, y in pts], fill=color)


# ─────────────────────── 图标 ───────────────────────

def draw_add(color):
    """圆 + 加号（底部标签栏中间的「＋」）。"""
    img, d = canvas()
    ring(d, 12, 12, 9.2, 2.0, color)
    line(d, [(12, 8), (12, 16)], 2.0, color)
    line(d, [(8, 12), (16, 12)], 2.0, color)
    return img


def draw_back(color):
    img, d = canvas()
    line(d, [(15, 5), (8, 12), (15, 19)], 2.2, color)
    return img


def draw_today(color):
    """今日：太阳（圆 + 8 道光芒）。"""
    img, d = canvas()
    ring(d, 12, 12, 4.2, 2.0, color)
    for x0, y0, x1, y1 in ((12, 2.5, 12, 4.7), (12, 19.3, 12, 21.5),
                           (2.5, 12, 4.7, 12), (19.3, 12, 21.5, 12),
                           (4.9, 4.9, 6.5, 6.5), (17.5, 17.5, 19.1, 19.1),
                           (4.9, 19.1, 6.5, 17.5), (17.5, 6.5, 19.1, 4.9)):
        line(d, [(x0, y0), (x1, y1)], 2.0, color)
    return img


def draw_library(color):
    """资料库：四宫格。"""
    img, d = canvas()
    for x0, y0 in ((3, 3), (13.5, 3), (3, 13.5), (13.5, 13.5)):
        d.rounded_rectangle([P(x0), P(y0), P(x0 + 7.5), P(y0 + 7.5)],
                            radius=P(2), outline=color, width=w(2.0))
    return img


def draw_stats(color):
    """数据：柱状图。"""
    img, d = canvas()
    line(d, [(4, 20), (22, 20)], 2.0, color)
    line(d, [(4, 20), (4, 10)], 2.0, color)
    line(d, [(10, 20), (10, 4)], 2.0, color)
    line(d, [(16, 20), (16, 13)], 2.0, color)
    return img


def draw_me(color):
    """我的：头 + 肩。"""
    img, d = canvas()
    ring(d, 12, 8, 3.8, 2.0, color)
    d.arc([P(4.5), P(12.5), P(19.5), P(27.5)], start=180, end=360,
          fill=color, width=w(2.0))
    return img


def draw_check(color):
    img, d = canvas()
    line(d, [(5, 12.5), (9.5, 17), (19, 7)], 3.0, color)
    return img


def draw_trend(color):
    img, d = canvas()
    line(d, [(5, 15), (11, 9), (15, 13), (20, 7)], 2.4, color)
    return img


def draw_body(color):
    """体能：杠铃。"""
    img, d = canvas()
    line(d, [(4, 9), (4, 15)], 2.4, color)
    line(d, [(20, 9), (20, 15)], 2.4, color)
    line(d, [(7, 6.5), (7, 17.5)], 2.4, color)
    line(d, [(17, 6.5), (17, 17.5)], 2.4, color)
    line(d, [(7, 12), (17, 12)], 2.4, color)
    return img


def draw_read(color):
    """阅读：摊开的书。"""
    img, d = canvas()
    line(d, [(4, 5.5), (4, 20.5)], 2.4, color)
    line(d, [(4, 5.5), (12, 4), (20, 5.5)], 2.4, color)
    line(d, [(4, 20.5), (12, 19), (20, 20.5)], 2.4, color)
    line(d, [(12, 4), (12, 19)], 2.4, color)
    line(d, [(20, 5.5), (20, 20.5)], 2.4, color)
    return img


def draw_listen(color):
    """收听：耳机。"""
    img, d = canvas()
    d.arc([P(4), P(4), P(20), P(20)], start=180, end=360, fill=color, width=w(2.4))
    d.rounded_rectangle([P(2.5), P(13.5), P(6.5), P(20)], radius=P(1.7), fill=color)
    d.rounded_rectangle([P(17.5), P(13.5), P(21.5), P(20)], radius=P(1.7), fill=color)
    return img


def draw_nourish(color):
    """饮食：碗 + 热气。"""
    img, d = canvas()
    line(d, [(3, 12), (21, 12)], 2.4, color)
    d.arc([P(5), P(5), P(19), P(19)], start=0, end=180, fill=color, width=w(2.4))
    line(d, [(9, 6.5), (9, 5)], 1.8, color)
    line(d, [(13, 6), (13, 4.5)], 1.8, color)
    return img


def draw_mind(color):
    """冥想：主星芒 + 小星芒。"""
    img, d = canvas()
    poly(d, [(12, 3), (13.6, 10.4), (18, 12), (13.6, 13.6), (12, 21),
             (10.4, 13.6), (6, 12), (10.4, 10.4)], color)
    poly(d, [(18.5, 15.5), (19.6, 17.7), (21.5, 18), (19.7, 19.2),
             (19.4, 21), (18.2, 19.5), (16, 19.4), (17.5, 18)], color)
    return img


def draw_watch(color):
    """观看：播放。"""
    img, d = canvas()
    d.rounded_rectangle([P(3), P(5), P(21), P(19)], radius=P(2.5),
                        outline=color, width=w(2.4))
    poly(d, [(10, 9.5), (14.5, 12), (10, 14.5)], color)
    return img


def sheet(entries, path):
    """把全部图标拼成一张对照图，供人工核对。

    背景用中性灰：白色描边的分类图标在纯白底上看不见。
    """
    cell, cols = 96, 6
    rows = math.ceil(len(entries) / cols)
    img = Image.new("RGB", (cols * cell, rows * cell), (190, 190, 190))
    drw = ImageDraw.Draw(img)
    for idx, (label, icon) in enumerate(entries):
        cx = (idx % cols) * cell
        cy = (idx // cols) * cell
        big = icon.resize((72, 72), Image.LANCZOS)
        img.paste(big, (cx + 12, cy + 10), big)
        drw.text((cx + 6, cy + cell - 14), label, fill=(60, 60, 60))
    img.save(path)
    print("contact sheet:", path, img.size)


if __name__ == "__main__":
    checks = []
    # 标签栏：未选中用 muted，选中用 accent
    for fn, name in ((draw_today, "ic_today"), (draw_library, "ic_library"),
                     (draw_add, "ic_add"), (draw_stats, "ic_stats"),
                     (draw_me, "ic_me")):
        checks.append((name + "_on", save(fn(ACCENT), name + "_on")))
        checks.append((name, save(fn(MUTED), name)))

    checks.append(("ic_back", save(draw_back(INK), "ic_back")))
    checks.append(("ic_check", save(draw_check(INK), "ic_check")))
    checks.append(("ic_trend", save(draw_trend(SUCCESS), "ic_trend")))

    for fn, name in ((draw_body, "gl_body"), (draw_read, "gl_read"),
                     (draw_listen, "gl_listen"), (draw_nourish, "gl_nourish"),
                     (draw_mind, "gl_mind"), (draw_watch, "gl_watch")):
        checks.append((name, save(fn(WHITE), name)))

    sheet(checks, os.path.join(CHECK, "contact-sheet.png"))
    print("icons written:", len(checks))

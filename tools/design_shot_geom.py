"""
按设计稿的 CSS 规则算出 4 台手机在页面里的精确像素坐标。

这不是猜的：坐标完全由 daily-quests-app.html 里的规则推导
（.stage-bar 内边距 26px、.phones 内边距 8px 32px 64px、gap 30px、
 .phone 宽 360 高 780、.phone 内边距 12px）。

算准坐标之后，对整页做一次高倍率截图，再按这些坐标裁出每台手机，
比在页面里注入 CSS 更不容易出错。
"""

# 来自 daily-quests-app.html
STAGE_BAR_PAD_Y = 26          # .stage-bar padding: 26px 40px
STAGE_BAR_LINE = 11           # font: 11px/1  → 行高 11px
PHONES_PAD_TOP = 8            # .phones padding: 8px 32px 64px
PHONES_PAD_X = 32
GAP = 30                      # .phones gap: 30px
PHONE_W = 360
PHONE_H = 780
PHONE_PAD = 12                # .phone padding: 12px
SCREEN_RADIUS = 44            # .screen border-radius: 44px

COUNT = 4
NAMES = ["01-cover", "02-today", "03-detail", "04-stats"]

stage_bar_h = STAGE_BAR_PAD_Y * 2 + STAGE_BAR_LINE
phones_top = stage_bar_h + PHONES_PAD_TOP
phones_w = COUNT * PHONE_W + (COUNT - 1) * GAP
page_w = phones_w + PHONES_PAD_X * 2
page_h = phones_top + PHONE_H + 64      # padding-bottom: 64px


def phone_rect(i):
    left = PHONES_PAD_X + i * (PHONE_W + GAP)
    return left, phones_top, left + PHONE_W, phones_top + PHONE_H


def screen_rect(i):
    l, t, r, b = phone_rect(i)
    return l + PHONE_PAD, t + PHONE_PAD, r - PHONE_PAD, b - PHONE_PAD


if __name__ == "__main__":
    print(f"页面尺寸: {page_w} x {page_h}")
    print(f"stage bar 高: {stage_bar_h}")
    print()
    for i, name in enumerate(NAMES):
        pl, pt, pr, pb = phone_rect(i)
        sl, st, sr, sb = screen_rect(i)
        print(f"{name}")
        print(f"  .phone   整机 : ({pl}, {pt}) - ({pr}, {pb})   {pr-pl} x {pb-pt}")
        print(f"  .screen  屏幕 : ({sl}, {st}) - ({sr}, {sb})   {sr-sl} x {sb-st}")

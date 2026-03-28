#!/usr/bin/env python3
"""Build app icon + Play assets from the reference PNG (see docs/store_assets/source_app_icon_reference.png)."""
from __future__ import annotations

import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE_ICON = os.path.join(ROOT, "docs", "store_assets", "source_app_icon_reference.png")


def _lerp(a: float, b: float, t: float) -> int:
    return int(a + (b - a) * t)


def _horizontal_gradient_rgb(
    size: tuple[int, int], left: tuple[int, int, int], right: tuple[int, int, int]
) -> Image.Image:
    w, h = size
    img = Image.new("RGB", size)
    px = img.load()
    for x in range(w):
        t = x / max(1, w - 1)
        r = _lerp(left[0], right[0], t)
        g = _lerp(left[1], right[1], t)
        b = _lerp(left[2], right[2], t)
        for y in range(h):
            px[x, y] = (r, g, b)
    return img


def _find_font(size: int, bold: bool) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    names = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
    ]
    for path in names:
        if os.path.isfile(path):
            try:
                return ImageFont.truetype(path, size=size)
            except OSError:
                continue
    return ImageFont.load_default()


def _content_bbox_rgb(im: Image.Image, border_threshold: int = 38) -> tuple[int, int, int, int]:
    """Drop near-black frame (screenshot border) by bounding bright-ish pixels."""
    g = im.convert("RGB").convert("L")
    w, h = g.size
    px = g.load()
    minx, miny = w, h
    maxx, maxy = 0, 0
    for y in range(h):
        for x in range(w):
            if px[x, y] > border_threshold:
                minx = min(minx, x)
                miny = min(miny, y)
                maxx = max(maxx, x)
                maxy = max(maxy, y)
    if maxx < minx:
        return 0, 0, w, h
    return minx, miny, maxx + 1, maxy + 1


def _trim_border_square_center(im: Image.Image) -> Image.Image:
    """Crop off dark border, then center-crop to a square."""
    box = _content_bbox_rgb(im)
    im = im.crop(box)
    w, h = im.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    return im.crop((left, top, left + side, top + side))


def _sample_lr_colors(square_rgb: Image.Image) -> tuple[tuple[int, int, int], tuple[int, int, int]]:
    """Left / right mid-row colours for banner gradient (matches reference horizontal bg)."""
    w, h = square_rgb.size
    mid = h // 2
    px = square_rgb.convert("RGB").load()
    return px[0, mid], px[w - 1, mid]


def _smoothstep(t: float) -> float:
    t = max(0.0, min(1.0, t))
    return t * t * (3.0 - 2.0 * t)


def _extract_cap_rgba(square: Image.Image) -> Image.Image:
    """Graduation cap + check only (transparent elsewhere). One banner gradient underneath — no second background tile."""
    rgb = square.convert("RGB")
    w, h = rgb.size
    px = rgb.load()
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    opx = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            mx, mn = max(r, g, b), min(r, g, b)
            spread = mx - mn
            lum = (r + g + b) / 3.0
            if spread > 78:
                strength = 0.0
            else:
                t_lin = (lum - 102.0) / 132.0
                strength = _smoothstep(max(0.0, min(1.0, t_lin)))
                if spread > 28:
                    strength *= max(0.0, 1.0 - (spread - 28) / 52.0)
            a = int(round(strength * 255.0))
            if a > 0:
                opx[x, y] = (r, g, b, a)
    return out


def _resize_rgba_premultiplied(im: Image.Image, size: tuple[int, int]) -> Image.Image:
    """LANCZOS resize with premultiplied alpha (cleaner edges than naive RGBA resize)."""
    im = im.convert("RGBA")
    if im.size == size:
        return im
    w, h = im.size
    raw = im.tobytes()
    pm = bytearray()
    for i in range(0, len(raw), 4):
        r, g, b, a = raw[i], raw[i + 1], raw[i + 2], raw[i + 3]
        if a == 0:
            pm.extend((0, 0, 0, 0))
        else:
            f = a / 255.0
            pm.extend((int(r * f), int(g * f), int(b * f), a))
    tmp = Image.frombytes("RGBA", (w, h), bytes(pm))
    tmp = tmp.resize(size, Image.Resampling.LANCZOS)
    raw2 = tmp.tobytes()
    out = bytearray()
    for i in range(0, len(raw2), 4):
        r, g, b, a = raw2[i], raw2[i + 1], raw2[i + 2], raw2[i + 3]
        if a == 0:
            out.extend((0, 0, 0, 0))
        else:
            f = 255.0 / float(a)
            out.extend(
                (
                    min(255, int(round(r * f))),
                    min(255, int(round(g * f))),
                    min(255, int(round(b * f))),
                    a,
                )
            )
    return Image.frombytes("RGBA", size, bytes(out))


def _square_min_side_for_cap(square: Image.Image, min_side: int = 1024) -> Image.Image:
    """Upscale small sources to match launcher icon detail before mask+scale (reduces blur from tiny screenshots)."""
    w, h = square.size
    if min(w, h) >= min_side:
        return square
    return square.resize((min_side, min_side), Image.Resampling.LANCZOS)


def _unsharp_cap_rgba(rgba: Image.Image) -> Image.Image:
    """RGB unsharp only; pulls cap edges closer to vector text clarity without touching alpha."""
    rgba = rgba.convert("RGBA")
    r, g, b, a = rgba.split()
    rgb = Image.merge("RGB", (r, g, b))
    rgb = rgb.filter(ImageFilter.UnsharpMask(radius=0.9, percent=140, threshold=1))
    r2, g2, b2 = rgb.split()
    return Image.merge("RGBA", (r2, g2, b2, a))


def _smooth_scale_rgba(im: Image.Image, tw: int, th: int) -> Image.Image:
    """Premultiplied LANCZOS. If source is already larger than target, one downscale only (avoids double-soft blur)."""
    im = im.convert("RGBA")
    iw, ih = im.size
    if iw < 1 or ih < 1:
        return _resize_rgba_premultiplied(im, (max(1, tw), max(1, th)))
    if iw >= tw and ih >= th:
        return _resize_rgba_premultiplied(im, (tw, th))
    scale = 4
    big_w = max(tw * scale, iw)
    big_h = max(th * scale, ih)
    big = _resize_rgba_premultiplied(im, (big_w, big_h))
    return _resize_rgba_premultiplied(big, (tw, th))


def render_feature_graphic(
    square: Image.Image,
    w: int = 1024,
    h: int = 500,
) -> Image.Image:
    """One horizontal gradient; cap composited on top (not a second full-square image — avoids a visible seam)."""
    left_c, right_c = _sample_lr_colors(square)
    base = _horizontal_gradient_rgb((w, h), left_c, right_c)
    img = Image.new("RGBA", (w, h))
    img.paste(base, (0, 0))

    # Same min resolution as app icon when source is small — extracting from a 300px screenshot was the main blur.
    cap_src = _extract_cap_rgba(_square_min_side_for_cap(square, 1024))
    box = cap_src.split()[-1].getbbox()
    if box:
        cap_src = cap_src.crop(box)
    else:
        cap_src = _square_min_side_for_cap(square, 1024).convert("RGBA")
    cap_h = 230
    cw, ch = cap_src.size
    cap_w = max(1, int(cw * cap_h / ch))
    cap_scaled = _unsharp_cap_rgba(_smooth_scale_rgba(cap_src, cap_w, cap_h))
    cap_x = 48
    cap_y = (h - cap_h) // 2
    img.paste(cap_scaled, (cap_x, cap_y), cap_scaled)

    draw = ImageDraw.Draw(img)
    title_font = _find_font(64, True)
    sub_font = _find_font(26, False)

    title = "Exam Ace"
    x_left = cap_x + cap_w + 36

    tb = draw.textbbox((0, 0), title, font=title_font)
    title_h = tb[3] - tb[1]
    title_top_offset = tb[1]

    gap_title_sub = 24
    sub_line = "Syllabus · prep · mocks · exams"
    sb = draw.textbbox((0, 0), sub_line, font=sub_font)
    sub_h = sb[3] - sb[1]
    block_h = title_h + gap_title_sub + sub_h
    block_top = (h - block_h) // 2 - title_top_offset

    draw.text((x_left, block_top), title, font=title_font, fill=(255, 255, 255, 255))

    sub_y = block_top + title_h + gap_title_sub
    draw.text((x_left, sub_y), sub_line, font=sub_font, fill=(255, 255, 255, 230))

    return img


def main() -> None:
    if not os.path.isfile(SOURCE_ICON):
        print(
            f"Missing source image: {SOURCE_ICON}\n"
            "Add your reference PNG (graduation cap on blue→teal gradient) there, then re-run.",
            file=sys.stderr,
        )
        sys.exit(1)

    raw = Image.open(SOURCE_ICON)
    square = _trim_border_square_center(raw)

    out_dir = os.path.join(ROOT, "docs", "store_assets")
    assets_dir = os.path.join(ROOT, "assets")
    os.makedirs(out_dir, exist_ok=True)
    os.makedirs(assets_dir, exist_ok=True)

    icon_1024 = square.resize((1024, 1024), Image.Resampling.LANCZOS)
    if icon_1024.mode != "RGBA":
        icon_1024 = icon_1024.convert("RGBA")
    icon_1024.save(os.path.join(assets_dir, "app_icon.png"), "PNG", optimize=True)

    icon_512 = icon_1024.resize((512, 512), Image.Resampling.LANCZOS)
    icon_512.save(os.path.join(out_dir, "google_play_icon_512.png"), "PNG", optimize=True)

    banner = render_feature_graphic(square, 1024, 500)
    fg_path = os.path.join(out_dir, "google_play_feature_graphic_1024x500.png")
    banner.save(fg_path, "PNG", optimize=True)
    print(
        "Feature graphic: cap composited on one gradient (no full-square paste).",
        file=sys.stderr,
    )

    for path in [
        os.path.join(assets_dir, "app_icon.png"),
        os.path.join(out_dir, "google_play_icon_512.png"),
        fg_path,
    ]:
        print(path, os.path.getsize(path), "bytes")


if __name__ == "__main__":
    main()

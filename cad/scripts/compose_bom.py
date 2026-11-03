#!/usr/bin/env python3
"""
LUME — BOM tear-down grid composer.
Reads the 20 per-part PNGs in renders/parts/ and tiles them into a labeled
5x4 grid with a title bar. Replaces the OpenSCAD scattered-coordinates
attempt with a clean Pillow composite.

Usage:
    python3 scripts/compose_bom.py

Output:
    renders/bom_grid.png
"""
from __future__ import annotations

import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
PARTS = ROOT / "renders" / "parts"
OUT = ROOT / "renders" / "bom_grid.png"

# Fixed grid order. Mirrors lume-bom-grid.scad / render.sh bom tile order.
# 2026-04-26: jetson_sled retired (compute pivoted to K11 in pod). Replaced
# in row 1 by `pod_compute_sled` (T-form era K11 mount, ships with the pod).
ROWS = [
    ["shell_front_L", "shell_front_R",   "shell_rear_L", "shell_rear_R", "bezel"],
    ["pod_compute_sled", "fan_shroud",   "thermal_baffle","femto_mount",  "splice_plate"],
    ["svpro_L",       "svpro_R",         "mic_rail",     "led_diffuser", "cable_backbone"],
    ["port_anchors",  "port_bracket",    "vesa_plate",   "cleat_bar",    "cleat_wall"],
]

TILE_W = 480
TILE_H = 480
LABEL_H = 56
GAP = 16
PAD = 24
BG = (26, 26, 26)
LABEL_BG = (32, 32, 32)
LABEL_FG = (232, 232, 232)
TITLE_FG = (245, 245, 245)
TITLE = "LUME v1  ·  BOM tear-down  ·  20 printed parts"
TITLE_H = 96

FONT_REG = "/System/Library/Fonts/Supplemental/Arial.ttf"
FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"


def load_font(path: str, size: int) -> ImageFont.FreeTypeFont:
    try:
        return ImageFont.truetype(path, size=size)
    except OSError:
        return ImageFont.load_default()


def fit_image(p: Path, w: int, h: int) -> Image.Image:
    """Open image, fit into w×h while preserving aspect, on transparent canvas."""
    img = Image.open(p).convert("RGBA")
    img.thumbnail((w, h), Image.LANCZOS)
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    canvas.paste(img, ((w - img.width) // 2, (h - img.height) // 2), img)
    return canvas


def main() -> int:
    rows = len(ROWS)
    cols = len(ROWS[0])

    grid_w = PAD * 2 + cols * TILE_W + (cols - 1) * GAP
    grid_h = PAD * 2 + TITLE_H + GAP + rows * (TILE_H + LABEL_H + GAP) - GAP

    canvas = Image.new("RGBA", (grid_w, grid_h), BG + (255,))
    draw = ImageDraw.Draw(canvas)

    # Title bar
    title_font = load_font(FONT_BOLD, 44)
    title_bbox = draw.textbbox((0, 0), TITLE, font=title_font)
    title_w = title_bbox[2] - title_bbox[0]
    draw.text(((grid_w - title_w) // 2, PAD + 22), TITLE,
              fill=TITLE_FG, font=title_font)

    label_font = load_font(FONT_REG, 22)
    missing = []

    for r, row in enumerate(ROWS):
        for c, name in enumerate(row):
            x = PAD + c * (TILE_W + GAP)
            y = PAD + TITLE_H + GAP + r * (TILE_H + LABEL_H + GAP)

            # Tile backdrop (slightly lighter than page bg)
            draw.rectangle(
                (x, y, x + TILE_W, y + TILE_H + LABEL_H),
                fill=(36, 36, 36, 255)
            )

            png = PARTS / f"{name}.png"
            if not png.exists():
                missing.append(name)
                # Placeholder X
                draw.line((x + 60, y + 60, x + TILE_W - 60, y + TILE_H - 60),
                          fill=(120, 30, 30), width=4)
                draw.line((x + TILE_W - 60, y + 60, x + 60, y + TILE_H - 60),
                          fill=(120, 30, 30), width=4)
            else:
                img = fit_image(png, TILE_W - 12, TILE_H - 12)
                canvas.paste(img, (x + 6, y + 6), img)

            # Label band
            label_bbox = draw.textbbox((0, 0), name, font=label_font)
            label_w = label_bbox[2] - label_bbox[0]
            draw.text(
                (x + (TILE_W - label_w) // 2, y + TILE_H + 14),
                name, fill=LABEL_FG, font=label_font
            )

    canvas.convert("RGB").save(OUT, "PNG", optimize=True)
    print(f"✔ wrote {OUT.relative_to(ROOT)}  ({canvas.width}×{canvas.height})")
    if missing:
        print(f"⚠ missing per-part PNGs: {missing} (run ./render.sh parts first)")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

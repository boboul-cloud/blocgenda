#!/usr/bin/env python3
"""Génère l'icône de Blocgenda : 1024 x 1024, RVB strict, sans canal alpha.

Le motif : une bande de papier qui sort de la machine, déchirée en bas,
avec ses lignes imprimées et le trait ambré du total ; derrière elle, le
soleil de l'éphéméride qui se lève.

    python3 Tools/make_icon.py

Le fichier est écrit dans Resources/Assets.xcassets/AppIcon.appiconset/.
"""

from __future__ import annotations

import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
SS = 4                      # suréchantillonnage pour l'anticrénelage
W = SIZE * SS

CHASSIS_TOP = (32, 36, 45)
CHASSIS_BOTTOM = (16, 18, 22)
PAPER = (250, 246, 236)
PAPER_SHADE = (232, 224, 208)
INK = (27, 29, 34)
INK_SOFT = (110, 108, 100)
AMBER = (224, 145, 58)
AMBER_DEEP = (194, 116, 42)
SEA = (30, 127, 140)


def vertical_gradient(size: int, top: tuple, bottom: tuple) -> Image.Image:
    """Dégradé vertical plein cadre, sans transparence."""
    base = Image.new("RGB", (1, size))
    px = base.load()
    for y in range(size):
        t = y / (size - 1)
        px[0, y] = tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
    return base.resize((size, size), Image.BICUBIC)


def radial_glow(size: int, center: tuple, radius: float, color: tuple, strength: float) -> Image.Image:
    """Halo doux, rendu comme un calque de luminosité à composer."""
    layer = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(layer)
    steps = 60
    for i in range(steps, 0, -1):
        r = radius * i / steps
        value = int(255 * strength * (1 - i / steps) ** 1.6)
        draw.ellipse([center[0] - r, center[1] - r, center[0] + r, center[1] + r], fill=value)
    layer = layer.filter(ImageFilter.GaussianBlur(radius * 0.08))
    tint = Image.new("RGB", (size, size), color)
    return Image.composite(tint, Image.new("RGB", (size, size), (0, 0, 0)), layer), layer


def torn_edge_points(x0: float, x1: float, y: float, depth: float, seed: int, teeth: int = 22):
    """Suite de points formant une déchirure irrégulière mais reproductible."""
    rng = random.Random(seed)
    pts = []
    for i in range(teeth + 1):
        x = x0 + (x1 - x0) * i / teeth
        pts.append((x, y + rng.uniform(-depth, depth)))
    return pts


def build() -> Image.Image:
    canvas = vertical_gradient(W, CHASSIS_TOP, CHASSIS_BOTTOM)

    # --- Halo ambré en haut à gauche : la lumière du jour qui se lève
    glow, mask = radial_glow(W, (W * 0.30, W * 0.20), W * 0.62, AMBER, 0.34)
    canvas = Image.composite(
        Image.blend(canvas, glow, 0.55), canvas, mask.point(lambda v: int(v * 0.9))
    )

    draw = ImageDraw.Draw(canvas, "RGBA")

    # --- Le soleil, derrière la bande
    sun_c = (W * 0.50, W * 0.255)
    sun_r = W * 0.145
    for i in range(40, 0, -1):
        r = sun_r * (1 + i * 0.035)
        a = int(26 * (1 - i / 40) ** 1.4)
        draw.ellipse([sun_c[0] - r, sun_c[1] - r, sun_c[0] + r, sun_c[1] + r],
                     fill=AMBER + (a,))
    # Disque plein, dégradé du cœur clair vers le bord ambré.
    core = (247, 205, 138)
    steps = 48
    for i in range(steps, 0, -1):
        r = sun_r * i / steps
        t = i / steps
        color = tuple(round(core[c] + (AMBER[c] - core[c]) * t) for c in range(3))
        draw.ellipse([sun_c[0] - r, sun_c[1] - r, sun_c[0] + r, sun_c[1] + r],
                     fill=color + (255,))

    # --- La bande de papier
    pad = W * 0.145
    left, right = pad, W - pad
    top = W * 0.300
    bottom = W * 0.905
    tear_depth = W * 0.017

    # Contour complet de la bande, déchirée en haut et en bas.
    body = torn_edge_points(left, right, top, tear_depth, seed=11)
    body += torn_edge_points(right, left, bottom, tear_depth, seed=29)

    # Ombre portée, calquée sur le contour réel.
    shadow = Image.new("L", (W, W), 0)
    ImageDraw.Draw(shadow).polygon([(x, y + W * 0.022) for x, y in body], fill=190)
    shadow = shadow.filter(ImageFilter.GaussianBlur(W * 0.026))
    canvas.paste(Image.new("RGB", (W, W), (0, 0, 0)), (0, 0), shadow)

    # Le papier est composé sur son propre calque : tout ce qu'on y peint,
    # liseré compris, reste à l'intérieur de la déchirure.
    paper = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    pdraw = ImageDraw.Draw(paper, "RGBA")
    pdraw.polygon(body, fill=PAPER + (255,))

    # Épaisseur du rouleau : un liseré plus sombre sur le bord droit.
    edge = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(edge).rectangle([right - W * 0.052, 0, right, W], fill=PAPER_SHADE + (150,))
    mask = Image.new("L", (W, W), 0)
    ImageDraw.Draw(mask).polygon(body, fill=255)
    paper = Image.alpha_composite(paper, Image.composite(
        edge, Image.new("RGBA", (W, W), (0, 0, 0, 0)), mask))

    pdraw = ImageDraw.Draw(paper, "RGBA")

    # --- Perforations latérales
    hole_r = W * 0.0105
    y = top + W * 0.052
    while y < bottom - W * 0.045:
        for x in (left + W * 0.036, right - W * 0.034):
            pdraw.ellipse([x - hole_r, y - hole_r, x + hole_r, y + hole_r],
                          fill=(206, 199, 185, 255))
        y += W * 0.062

    # --- Lignes imprimées
    text_left = left + W * 0.078
    text_right = right - W * 0.088
    line_h = W * 0.028
    rows = [0.88, 0.60, 0.75, 0.44]
    y = top + W * 0.078
    for i, ratio in enumerate(rows):
        pdraw.rounded_rectangle(
            [text_left, y, text_left + (text_right - text_left) * ratio, y + line_h],
            radius=line_h / 2, fill=INK_SOFT + (235 if i % 2 else 255,))
        y += line_h * 2.45

    # --- Le trait du total, en ambre, aligné à droite
    y += line_h * 0.5
    pdraw.rounded_rectangle([text_left, y, text_right, y + W * 0.0075],
                            radius=W * 0.0038, fill=INK + (210,))
    y += W * 0.034
    total_w = (text_right - text_left) * 0.50
    pdraw.rounded_rectangle([text_right - total_w, y, text_right, y + line_h * 1.4],
                            radius=line_h * 0.65, fill=AMBER_DEEP + (255,))

    # --- Coche : les actions faites de l'agenda
    cx, cy = text_left + line_h * 0.85, y + line_h * 0.72
    s = line_h * 1.05
    pdraw.line([(cx - s * 0.58, cy), (cx - s * 0.12, cy + s * 0.46), (cx + s * 0.64, cy - s * 0.58)],
               fill=SEA + (255,), width=int(W * 0.0115), joint="curve")

    canvas.paste(paper, (0, 0), paper)
    return canvas.resize((SIZE, SIZE), Image.LANCZOS)


def main() -> None:
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out_dir = os.path.join(root, "Resources", "Assets.xcassets", "AppIcon.appiconset")
    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, "icon-1024.png")

    icon = build()
    assert icon.mode == "RGB", f"mode inattendu : {icon.mode}"
    # Sauvegarde sans canal alpha : ni RGBA, ni tRNS dans le PNG.
    icon.save(path, format="PNG", optimize=True)

    check = Image.open(path)
    print(f"écrit  : {path}")
    print(f"taille : {check.size[0]} x {check.size[1]}")
    print(f"mode   : {check.mode} (alpha : {'oui' if check.mode in ('RGBA', 'LA') else 'non'})")


if __name__ == "__main__":
    main()

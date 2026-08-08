#!/usr/bin/env python3
"""Met les captures aux dimensions exactes exigées par App Store Connect.

Les simulateurs ne rendent aucun des formats demandés au pixel près : leur
proportion diffère de quelques millièmes. On agrandit donc jusqu'à couvrir la
cible, puis on rogne au centre — jamais plus d'une poignée de pixels, pris dans
la barre d'état et sous la barre d'onglets, où il n'y a rien à perdre.

    python3 Tools/captures-fit.py <dossier source> <dossier cible> <largeur>x<hauteur>
"""

import os
import sys

from PIL import Image


def fit(source, target, size):
    largeur, hauteur = size
    image = Image.open(source).convert("RGB")
    facteur = max(largeur / image.width, hauteur / image.height)
    intermediaire = image.resize(
        (round(image.width * facteur), round(image.height * facteur)),
        Image.LANCZOS,
    )
    gauche = (intermediaire.width - largeur) // 2
    haut = (intermediaire.height - hauteur) // 2
    coupe = intermediaire.crop((gauche, haut, gauche + largeur, haut + hauteur))
    coupe.save(target, optimize=True)


def main():
    if len(sys.argv) != 4:
        print(__doc__)
        sys.exit(1)
    source, cible, mesure = sys.argv[1], sys.argv[2], sys.argv[3]
    size = tuple(int(n) for n in mesure.lower().split("x"))
    os.makedirs(cible, exist_ok=True)
    for nom in sorted(os.listdir(source)):
        if not nom.endswith(".png"):
            continue
        fit(os.path.join(source, nom), os.path.join(cible, nom), size)
        print(f"{nom} → {mesure}")


if __name__ == "__main__":
    main()

#!/bin/bash
#
# Refait toutes les captures d'écran de la fiche App Store.
#
#   ./Tools/captures.sh
#
# Le simulateur est peuplé d'une journée de démonstration (captures-seed.py),
# piloté par un test d'interface (Tests/UI/CaptureTests.swift), puis les images
# sont mises aux formats exacts d'App Store Connect (captures-fit.py).
#
# La marée et la météo sont demandées au réseau : sans connexion, la fiche du
# jour s'affichera en panne. L'heure de la barre d'état est calée sur l'heure
# réelle de la prise, pour qu'elle ne contredise pas ce que l'app affiche
# (« pleine mer dans 3 h »).

set -euo pipefail
cd "$(dirname "$0")/.."

IPHONE="iPhone 17 Pro Max"     # 1320 × 2868, le gabarit 6,9 pouces d'Apple
IPAD="iPad Pro 13-inch (M5)"   # 2064 × 2752, le gabarit 13 pouces
BUNDLE="com.oulhen.blocgenda"
TRAVAIL="build/captures"

prendre() {
  local nom_appareil="$1" dossier="$2"
  local udid
  udid=$(xcrun simctl list devices available | grep -F "$nom_appareil (" | head -1 |
         sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
  if [ -z "$udid" ]; then
    echo "Simulateur introuvable : $nom_appareil" >&2
    exit 1
  fi
  echo "== $nom_appareil ($udid)"

  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b >/dev/null

  xcodebuild build-for-testing -project Blocgenda.xcodeproj -scheme Blocgenda \
    -destination "id=$udid" -derivedDataPath build >/dev/null

  # Une première ouverture crée le conteneur partagé ; on y écrit ensuite la
  # journée de démonstration, à la place du contenu d'accueil.
  xcrun simctl install "$udid" build/Build/Products/Debug-iphonesimulator/Blocgenda.app
  xcrun simctl privacy "$udid" grant location "$BUNDLE" >/dev/null 2>&1 || true
  xcrun simctl location "$udid" set 48.3904,-4.4861
  xcrun simctl launch "$udid" "$BUNDLE" >/dev/null
  sleep 6
  xcrun simctl terminate "$udid" "$BUNDLE" >/dev/null 2>&1 || true

  local conteneur
  conteneur=$(dirname "$(find ~/Library/Developer/CoreSimulator/Devices/"$udid"/data/Containers/Shared/AppGroup \
                          -name tape.json | head -1)")
  python3 Tools/captures-seed.py "$conteneur"

  xcrun simctl status_bar "$udid" override \
    --time "$(date +%H:%M)" --batteryState charged --batteryLevel 100 \
    --cellularBars 4 --wifiBars 3 --dataNetwork wifi

  rm -rf "$TRAVAIL/$dossier.xcresult" "$TRAVAIL/$dossier"
  mkdir -p "$TRAVAIL"
  xcodebuild test-without-building -project Blocgenda.xcodeproj -scheme Blocgenda \
    -destination "id=$udid" -derivedDataPath build \
    -only-testing:BlocgendaUITests/CaptureTests \
    -resultBundlePath "$TRAVAIL/$dossier.xcresult" >/dev/null

  xcrun xcresulttool export attachments \
    --path "$TRAVAIL/$dossier.xcresult" --output-path "$TRAVAIL/$dossier-brut" >/dev/null
  python3 - "$TRAVAIL/$dossier-brut" "$TRAVAIL/$dossier" <<'PY'
import json, os, shutil, sys
brut, sortie = sys.argv[1], sys.argv[2]
os.makedirs(sortie, exist_ok=True)
for test in json.load(open(f"{brut}/manifest.json")):
    for piece in test.get("attachments", []):
        nom = piece["suggestedHumanReadableName"].split("_")[0]
        shutil.copy(f"{brut}/{piece['exportedFileName']}", f"{sortie}/{nom}.png")
PY
  echo "   $(ls "$TRAVAIL/$dossier" | wc -l | tr -d ' ') captures"
}

prendre "$IPHONE" iphone
prendre "$IPAD" ipad

# Les deux tailles acceptées par App Store Connect pour chaque famille.
python3 Tools/captures-fit.py "$TRAVAIL/iphone" Marketing/Captures/iphone-6.9 1320x2868
python3 Tools/captures-fit.py "$TRAVAIL/iphone" Marketing/Captures/iphone-6.5 1242x2688
python3 Tools/captures-fit.py "$TRAVAIL/ipad"   Marketing/Captures/ipad-13   2064x2752
python3 Tools/captures-fit.py "$TRAVAIL/ipad"   Marketing/Captures/ipad-12.9 2048x2732

echo "Captures dans Marketing/Captures/"

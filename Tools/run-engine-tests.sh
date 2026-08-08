#!/bin/bash
# Vérifie le moteur (calculatrice, barre intelligente, éphémérides solaires)
# sans passer par le simulateur :  ./Tools/run-engine-tests.sh
set -e
cd "$(dirname "$0")/.."
OUT=$(mktemp -d)
swiftc -O -o "$OUT/enginetests" \
  Sources/Shared/Engine/Calculator.swift \
  Sources/Shared/Engine/SmartInput.swift \
  Sources/Shared/Engine/Astronomy.swift \
  Sources/Shared/Engine/Tides.swift \
  Sources/Shared/Models/Place.swift \
  Sources/Shared/Models/Contact.swift \
  Sources/Shared/Models/AgendaEvent.swift \
  Tools/EngineTests/main.swift
TZ=Europe/Paris "$OUT/enginetests"

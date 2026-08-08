#!/usr/bin/env python3
"""Remplit le conteneur partagé d'un simulateur avec un contenu de démonstration.

Les captures de l'App Store ne peuvent pas montrer le rouleau d'accueil : trois
lignes ne disent rien de ce que l'application sait faire. Ce script écrit
directement les fichiers lus par l'app (tape.json, events.json, contacts.json,
settings.json) avec une journée plausible, à Brest, datée du jour de la prise.

    python3 Tools/captures-seed.py <dossier du conteneur App Group>

Le dossier se trouve avec :
    find ~/Library/Developer/CoreSimulator/Devices/<UDID>/data/Containers/Shared/AppGroup \
         -name tape.json
"""

import json
import sys
import uuid
from datetime import datetime, timedelta

PLACE = {"name": "Brest", "latitude": 48.3904, "longitude": -4.4861, "isAutomatic": True}


def uid():
    return str(uuid.uuid4()).upper()


def stamp(day, hour, minute=0):
    """Une heure locale du jour donné, au format attendu par le décodeur."""
    moment = day.replace(hour=hour, minute=minute, second=0, microsecond=0)
    return moment.astimezone().isoformat()


def line(date, kind, text="", expression=None, value=None, done=False, tags=None, event_id=None):
    entry = {
        "id": uid(),
        "date": date,
        "kind": kind,
        "text": text,
        "done": done,
        "tags": tags or [],
        "pinned": False,
    }
    if expression is not None:
        entry["expression"] = expression
    if value is not None:
        entry["value"] = value
    if event_id is not None:
        entry["eventID"] = event_id
    return entry


def event(title, start, duration=3600, place="", color=0, repeat="none",
          all_day=False, reminders=(15,), notes=""):
    return {
        "id": uid(),
        "title": title,
        "start": start,
        "duration": duration,
        "isAllDay": all_day,
        "place": place,
        "notes": notes,
        "colorIndex": color,
        "repeatRule": repeat,
        "reminders": list(reminders),
        "completedDays": [],
    }


def contact(first, last, group, color, phone="", email="", company="",
            address="", favorite=False, birthday=None, note=""):
    fiche = {
        "id": uid(),
        "firstName": first,
        "lastName": last,
        "company": company,
        "phone": phone,
        "email": email,
        "address": address,
        "note": note,
        "isFavorite": favorite,
        "group": group,
        "colorIndex": color,
    }
    if birthday:
        fiche["birthday"] = birthday
    return fiche


def build(today):
    hier = today - timedelta(days=1)

    marche = event("Marché du port", stamp(today, 10, 0), duration=5400,
                   place="Quai Malbert", color=1, repeat="weekly")
    carenage = event("Carénage — mise à l'eau", stamp(today + timedelta(days=1), 9, 0),
                     duration=7200, place="Chantier du Moulin Blanc", color=2,
                     reminders=(60, 15))
    dentiste = event("Dentiste", stamp(today + timedelta(days=2), 14, 30),
                     duration=1800, place="3 rue des Lilas", color=3, reminders=(1440, 60))
    voile = event("Livraison de la grand-voile", stamp(today + timedelta(days=3), 8, 15),
                  duration=1800, place="Voilerie du Conquet", color=4)
    apero = event("Apéro chez Marie", stamp(today + timedelta(days=4), 19, 0),
                  duration=7200, place="Le Conquet", color=0)

    events = [marche, carenage, dentiste, voile, apero]

    tape = [
        # Hier — une journée déjà refermée par un sous-total.
        line(stamp(hier, 8, 40), "task", "Réserver la place au ponton",
             done=True, tags=["bateau"]),
        line(stamp(hier, 9, 15), "calc", expression="12,50 × 3", value=37.5),
        line(stamp(hier, 18, 20), "note", "Courses du marché", value=24.6, tags=["maison"]),
        line(stamp(hier, 18, 22), "subtotal", "TOTAL", value=62.1),

        # Aujourd'hui.
        line(stamp(today, 8, 5), "event", "Marché du port", event_id=marche["id"]),
        line(stamp(today, 8, 32), "note", "Gasoil", value=62.3, tags=["bateau"]),
        line(stamp(today, 9, 10), "calc", expression="62,30 + 18,90", value=81.2),
        line(stamp(today, 9, 40), "task", "Appeler la capitainerie pour le ponton",
             tags=["mer"]),
        line(stamp(today, 10, 15), "task", "Prendre le pain", done=True),
        line(stamp(today, 11, 2), "calc", expression="200 + 10%", value=220.0),
        line(stamp(today, 11, 30), "note", "Antifouling — deux pots", value=148.0,
             tags=["bateau"]),
        line(stamp(today, 12, 5), "task", "Sortir à la pleine mer", tags=["mer"]),
    ]

    contacts = [
        contact("Marie", "Lambert", "Famille", 1, phone="06 12 34 56 78",
                email="marie.lambert@example.com", favorite=True,
                birthday=stamp((today + timedelta(days=5)).replace(year=1989), 12, 0)),
        contact("Yann", "Le Goff", "Mer", 2, phone="02 98 02 20 02",
                company="Capitainerie du Moulin Blanc", favorite=True),
        contact("Docteur", "Renard", "Santé", 4, phone="02 97 11 22 33",
                address="3 rue des Lilas, Brest"),
        contact("Chantier", "Kerdrec'h", "Mer", 5, phone="02 98 45 67 89",
                company="Chantier naval", address="Port du Moulin Blanc"),
        contact("Pharmacie", "du Port", "Santé", 3, phone="02 98 44 22 11",
                address="Quai Malbert, Brest"),
        contact("Anne", "Kerlan", "Travail", 0, phone="06 98 76 54 32",
                email="anne.kerlan@example.com"),
        contact("École", "Jules Ferry", "Maison", 2, phone="02 98 33 44 55"),
        contact("Taxi", "Brest", "Urgences", 4, phone="02 98 80 43 43"),
    ]

    settings = {
        "place": PLACE,
        "followLocation": True,
        "morningBriefingEnabled": True,
        "morningBriefingHour": 7,
        "morningBriefingMinute": 30,
        "eveningReviewEnabled": True,
        "eveningReviewHour": 21,
        "eveningReviewMinute": 0,
        "goldenHourAlert": True,
        "tideAlert": True,
        "currencySymbol": "€",
        "vatRate": 20,
        "paperTint": 0,
        "hasSeededSample": True,
        # Laissé à faux : l'app crée elle-même le rendez-vous d'anniversaire
        # depuis l'annuaire, comme elle le ferait chez un vrai utilisateur.
        "hasImportedBirthdays": False,
        "customContactGroups": [],
    }

    return {"tape": tape, "events": events, "contacts": contacts, "settings": settings}


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    folder = sys.argv[1].rstrip("/")
    today = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    for name, value in build(today).items():
        with open(f"{folder}/{name}.json", "w", encoding="utf-8") as handle:
            json.dump(value, handle, ensure_ascii=False, indent=2)
        print(f"écrit {name}.json")


if __name__ == "__main__":
    main()

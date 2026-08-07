# Fiche App Store — Blocgenda 1.1

Textes prêts à coller dans App Store Connect. Les limites de caractères indiquées
sont celles d'Apple ; les compteurs ont été vérifiés.

---

## Identité

| Champ | Valeur |
|---|---|
| Nom (30 car. max) | `Blocgenda` |
| Sous-titre (30 car. max) | `Bloc-notes, calcul et marées` |
| Bundle ID | `com.oulhen.blocgenda` |
| SKU | `BLOCGENDA-1` |
| Catégorie principale | Productivité |
| Catégorie secondaire | Utilitaires |
| Langue principale | Français (France) |
| Classement d'âge | 4+ |
| Prix | Gratuit |
| Achats intégrés | Aucun |
| URL d'assistance | `https://boboul-cloud.github.io/blocgenda/assistance.html` |
| URL marketing | `https://boboul-cloud.github.io/blocgenda/` |
| URL de confidentialité | `https://boboul-cloud.github.io/blocgenda/confidentialite.html` |
| Droits d'auteur | `© 2026 Bob Oulhen` |

---

## Texte promotionnel (170 car. max, modifiable sans nouvelle version)

```
Une seule bande de papier pour vos calculs, vos notes, vos rendez-vous. Et chaque
matin : l'éphéméride, le soleil, la lune et la marée du lieu où vous êtes.
```

---

## Description

```
Blocgenda est un bloc-notes qui pense comme une additionneuse de comptoir : une
bande de papier sans fin où s'impriment, dans l'ordre où ils arrivent, vos
calculs, vos notes, vos actions et vos rendez-vous.

UNE SEULE BARRE DE SAISIE

Les autres applications vous demandent de choisir : est-ce une note, une tâche,
un calcul, un rendez-vous ? Blocgenda ne demande rien. Vous écrivez, il comprend
— et il vous montre ce qu'il a compris avant que vous validiez.

• 12,50 × 3 → un calcul, résultat aligné à droite
• 200 + 10% → 220, comme sur une calculatrice de bureau
• - rappeler le garage → une action à cocher
• demain 14h30 dentiste → un rendez-vous, avec notification
• réunion lundi 9h pendant 2h → un rendez-vous de deux heures
• essence 62,30 #bateau → une note chiffrée, étiquetée

LA BANDE

En haut, le total en cours. En bas, le clavier de la calculatrice quand vous en
avez besoin, avec la touche TOTAL qui imprime un sous-total et repart de zéro.
Et les ciseaux, qui déchirent la bande : les lignes terminées partent aux
archives, l'application en fait une image à envoyer, et les actions non faites
restent sur le rouleau.

CHAQUE JOUR, CE QUE LA JOURNÉE A D'OBJECTIF

• La course du soleil en arc, avec l'écart de durée par rapport à la veille
• La marée du lieu : courbe des 24 heures, pleines et basses mers à la minute,
  marnage, vive-eau ou morte-eau — et le port de référence le plus proche
  quand vous n'êtes pas sur la côte
• La lune : phase dessinée, éclairement, âge, lever et coucher
• L'éphéméride : saint du jour, dicton, jours fériés, « ce jour-là »
• Les anniversaires de votre annuaire
• L'heure dorée et l'heure bleue, pour les photographes
• Les périodes de pêche, calculées d'après la lune
• La météo : température, vent, force Beaufort

L'AGENDA ET L'ANNUAIRE

Une bande des sept jours, des récurrences, plusieurs rappels par rendez-vous.
Un annuaire de vos numéros utiles, groupés, avec appel, SMS, courriel et plan à
portée de pouce — et les anniversaires qui remontent dans l'éphéméride.

WIDGETS ET NOTIFICATIONS

Deux widgets, écran d'accueil et écran verrouillé. Sur le format moyen, la
première action non faite se coche sans même ouvrir l'application. Rappels de
rendez-vous, point du matin, bilan du soir, alerte heure dorée, alerte marée une
heure avant chaque étale.

RIEN NE PART DE VOTRE TÉLÉPHONE

Pas de compte, pas de nuage, pas d'analytique, pas de publicité, pas de traceur.
Vos notes, votre agenda et votre annuaire restent sur l'appareil. Le soleil et la
lune sont calculés sur place : l'application marche en mer, sans réseau. Seules
la marée et la météo sont demandées à Open-Meteo, à partir de coordonnées
arrondies, sans aucun identifiant.

IMPORTANT — SÉCURITÉ EN MER

Les marées affichées sont des prévisions, données par rapport au niveau moyen de
la mer. Elles conviennent pour organiser sa journée, pas pour naviguer : pour
cela, référez-vous à l'annuaire officiel des marées (SHOM) et aux bulletins de la
météo marine.
```

---

## Mots-clés (100 car. max, séparés par des virgules, sans espaces)

```
notes,calculatrice,marée,agenda,éphéméride,soleil,lune,rouleau,tâches,annuaire,pêche,marin
```

*(96 caractères — ne pas répéter le nom de l'app ni les mots de la catégorie,
Apple les indexe déjà.)*

---

## Nouveautés de cette version

```
• On peut maintenant écrire directement depuis l'agenda : la barre unique y
  ajoute au jour que vous avez sélectionné.
• Portsall, Le Conquet et l'Aber-Wrac'h rejoignent les ports de référence.
• Toute la typographie a été agrandie, et l'app suit désormais le réglage
  « Taille du texte » d'iOS.
• Correction : une étale de marée pouvait s'afficher deux fois, et le marnage
  annoncé ne portait pas sur la journée montrée.
```

---

## Confidentialité de l'app (questionnaire App Store Connect)

Réponses à donner dans la section *App Privacy* :

**« Collectez-vous des données de cette app ? » → NON.**

Justification, si Apple demande des précisions :

- L'application ne transmet aucune donnée à l'éditeur, qui n'exploite aucun
  serveur, aucun compte et aucun outil d'analyse.
- La position est utilisée **sur l'appareil** pour calculer les éphémérides. Des
  coordonnées arrondies sont envoyées à un service météorologique tiers
  (Open-Meteo) uniquement pour obtenir la marée et la météo du lieu ; l'envoi ne
  comporte aucun identifiant et n'est ni conservé ni relié à l'utilisateur par
  l'éditeur. Il s'agit d'un traitement en temps réel au sens des lignes
  directrices d'Apple, non d'une collecte.
- Aucune donnée n'est utilisée pour du suivi publicitaire. Le drapeau
  *App Tracking Transparency* n'est pas requis.

**Autorisations demandées et textes affichés :**

| Clé | Texte |
|---|---|
| `NSLocationWhenInUseUsageDescription` | Blocgenda utilise votre position pour calculer les marées, le lever et le coucher du soleil et la météo du lieu où vous vous trouvez. |
| `NSPhotoLibraryAddUsageDescription` | Blocgenda enregistre les morceaux de rouleau que vous déchirez dans vos photos. |

**Chiffrement :** `ITSAppUsesNonExemptEncryption = false` (l'app n'utilise que
HTTPS standard, exempté).

---

## Captures d'écran à fournir

Apple exige au minimum le format 6,9 pouces (1320 × 2868). Les captures du site
(`docs/captures/`) ont été prises sur iPhone 17 et doivent être refaites au bon
format avant dépôt.

Ordre suggéré, avec les légendes à incruster :

1. **Rouleau** — « Une seule bande. Tout s'y imprime. »
2. **Le jour** — « Le soleil et la marée du lieu où vous êtes. »
3. **Rouleau, barre active** — « Écrivez. Blocgenda comprend. »
4. **Agenda** — « Vos rendez-vous, vos rappels. »
5. **Annuaire** — « Vos numéros utiles à portée de pouce. »
6. **Widgets** — « La journée d'un coup d'œil. »

---

## Avant de déposer — liste de contrôle

- [ ] Remplacer l'équipe de signature et vérifier le groupe d'app
      `group.com.oulhen.blocgenda` sur les **deux** cibles
- [ ] Compléter les mentions légales (adresse, SIREN) si le compte est une
      organisation — voir `docs/mentions-legales.html`
- [ ] Refaire les captures au format 6,9 pouces
- [ ] Vérifier que les trois URL (marketing, assistance, confidentialité)
      répondent bien en HTTPS
- [ ] Incrémenter `MARKETING_VERSION` et `CURRENT_PROJECT_VERSION` dans
      `project.yml`
- [ ] `./Tools/run-engine-tests.sh` au vert, compilation Release sans
      avertissement
- [ ] Archive testée sur un appareil réel : widgets, notifications, position

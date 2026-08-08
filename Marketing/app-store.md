# Fiche App Store — Blocgenda 1.3

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
• Un bouton de dictée dans la barre de saisie : on parle, la ligne s'écrit, et
  le clavier ne monte jamais.
• On peut maintenant écrire directement depuis l'agenda : la barre unique y
  ajoute au jour que vous avez sélectionné.
• Portsall, Le Conquet et l'Aber-Wrac'h rejoignent les ports de référence.
• Toute la typographie a été agrandie, et l'app suit désormais le réglage
  « Taille du texte » d'iOS.
• Correction : une étale de marée pouvait s'afficher deux fois, et le marnage
  annoncé ne portait pas sur la journée montrée.
• L'agenda ne montre plus que les notes et les actions ; les calculs restent
  sur le rouleau.
• Les étiquettes sont enfin visibles : une rangée les propose sous la barre de
  saisie, et les toucher sur le rouleau filtre la bande.
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
- La dictée est traitée sur l'appareil chaque fois que le modèle français local
  est disponible. À défaut, iOS transmet l'audio au service de reconnaissance
  d'Apple, comme pour la touche micro du clavier ; l'éditeur n'y a pas accès et
  n'en conserve rien.
- Aucune donnée n'est utilisée pour du suivi publicitaire. Le drapeau
  *App Tracking Transparency* n'est pas requis.

**Autorisations demandées et textes affichés :**

| Clé | Texte |
|---|---|
| `NSLocationWhenInUseUsageDescription` | Blocgenda utilise votre position pour calculer les marées, le lever et le coucher du soleil et la météo du lieu où vous vous trouvez. |
| `NSContactsUsageDescription` | Blocgenda recopie dans son annuaire les fiches que vous choisissez d'importer. Vos contacts ne sont ni modifiés ni envoyés ailleurs. |
| `NSPhotoLibraryAddUsageDescription` | Blocgenda enregistre les morceaux de rouleau que vous déchirez dans vos photos. |
| `NSMicrophoneUsageDescription` | Blocgenda écoute le micro seulement quand vous touchez le bouton de dictée, le temps d'écrire votre ligne sur le rouleau. |
| `NSSpeechRecognitionUsageDescription` | Blocgenda transcrit ce que vous dictez pour l'inscrire sur le rouleau. La reconnaissance se fait sur l'appareil dès que celui-ci en est capable. |

**Chiffrement :** `ITSAppUsesNonExemptEncryption = false` (l'app n'utilise que
HTTPS standard, exempté).

---

## Captures d'écran

Prêtes dans `Marketing/Captures/`, aux quatre tailles acceptées par App Store
Connect. Apple n'exige que le 6,9 pouces et le 13 pouces ; les deux autres sont
fournies pour les emplacements facultatifs.

| Dossier | Dimensions | Emplacement App Store Connect |
|---|---|---|
| `iphone-6.9/` | 1320 × 2868 | iPhone 6,9″ — **obligatoire** |
| `iphone-6.5/` | 1242 × 2688 | iPhone 6,5″ |
| `ipad-13/` | 2064 × 2752 | iPad 13″ — **obligatoire** |
| `ipad-12.9/` | 2048 × 2732 | iPad 12,9″ |

Cinq images, dans l'ordre de dépôt :

1. **Rouleau** — la bande, deux journées, le total en cours
2. **Barre active** — « demain 14h30 dentiste », et l'intention reconnue
3. **Le jour** — soleil, marée de Brest, lune, éphéméride
4. **Agenda** — la semaine, le rendez-vous, les notes et actions du jour
5. **Annuaire** — les fiches, par tiroir

Pour les refaire : `./Tools/captures.sh`. Le script peuple un simulateur d'une
journée de démonstration, prend les images par un test d'interface, puis les met
aux quatre formats. La marée et la météo viennent du réseau : sans connexion, la
fiche du jour se prendrait en panne. L'heure de la barre d'état est celle de la
prise, pour ne pas contredire ce que l'app affiche.

Légendes à incruster, si l'on décide d'en mettre :

1. « Une seule bande. Tout s'y imprime. »
2. « Écrivez. Blocgenda comprend. »
3. « Le soleil et la marée du lieu où vous êtes. »
4. « Vos rendez-vous, vos rappels. »
5. « Vos numéros utiles à portée de pouce. »

---

## Avant de déposer — liste de contrôle

- [ ] Remplacer l'équipe de signature et vérifier le groupe d'app
      `group.com.oulhen.blocgenda` sur les **deux** cibles
- [ ] Compléter les mentions légales (adresse, SIREN) si le compte est une
      organisation — voir `docs/mentions-legales.html`
- [ ] Refaire les captures le jour du dépôt — `./Tools/captures.sh` : elles
      portent la date et la marée du jour de la prise
- [ ] Vérifier que les trois URL (marketing, assistance, confidentialité)
      répondent bien en HTTPS
- [ ] Incrémenter `MARKETING_VERSION` et `CURRENT_PROJECT_VERSION` dans
      `project.yml`
- [ ] `./Tools/run-engine-tests.sh` au vert, compilation Release sans
      avertissement
- [ ] Archive testée sur un appareil réel : widgets, notifications, position

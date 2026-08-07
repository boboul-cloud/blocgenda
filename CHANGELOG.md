# Journal des modifications

Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) et la
numérotation [SemVer](https://semver.org/lang/fr/).

## [1.1] — 2026-08-07

### Ajouté

- **Saisie depuis l'agenda.** La barre unique est désormais présente sur l'écran
  Agenda et écrit dans **le jour sélectionné**, pas dans aujourd'hui. Sur un jour
  à venir, « 9h » désigne neuf heures ce jour-là, sans basculer au lendemain
  comme le ferait une heure déjà passée. Ce qui est écrit apparaît aussitôt sous
  les rendez-vous, dans une section « Sur le rouleau » où les actions se cochent.
- **Portsall** (Finistère) rejoint les ports de référence, avec Le Conquet et
  l'Aber-Wrac'h.
- Le naufrage de l'Amoco Cadiz sur les roches de Portsall entre dans
  l'éphéméride du 16 mars.
- Une cible de **tests d'interface** qui pilote réellement l'application, et des
  identifiants d'accessibilité sur les commandes principales — utiles aussi à
  VoiceOver.

### Modifié

- **Typographie agrandie de 18 %** sur toute l'application, gouttières et
  colonnes chiffrées comprises. L'app suit en plus le réglage « Taille du texte »
  d'iOS, dans une limite qui préserve l'alignement des colonnes de la bande.
  Le widget garde sa taille : ses gabarits sont imposés par le système.

### Corrigé

- **Marée dupliquée** : une étale étalée sur deux relevés horaires de même
  hauteur était détectée — et affichée — deux fois. Les étales de même sens
  séparées de moins de trois heures sont maintenant fusionnées.
- **Marnage incohérent** : la valeur affichée portait sur toute la période
  récupérée (quatre jours) et non sur la journée montrée, si bien qu'elle ne
  correspondait à aucune des heures listées juste au-dessus.
- Un décompte de marée à moins d'une minute affichait « dans 0 min » ; il dit
  désormais « maintenant ».
- Retrait de deux déclarations sans usage dans l'`Info.plist` — l'autorisation
  d'accès aux contacts et le mode d'actualisation en arrière-plan — qu'Apple
  refuse quand rien ne les justifie dans le code.

## [1.0] — 2026-08-07

Première version.

### Le rouleau

- Bande de papier continue où s'impriment, dans l'ordre, calculs, notes, actions
  et rendez-vous, avec perforations, grain et bord déchiré.
- **Barre de saisie unique** : l'application reconnaît d'elle-même un calcul, une
  action, un rendez-vous ou une note chiffrée, et annonce ce qu'elle a compris
  avant validation.
- Analyseur d'expressions « à la française » : virgule décimale, espaces de
  milliers, `× ÷`, parenthèses, puissances, `racine`, `abs`, `arrondi`, `min`,
  `max`, et pourcentages à la manière d'une calculatrice de bureau
  (`200 + 10%` → 220, `20% de 80` → 16).
- Reconnaissance des dates en français : `demain`, `après-demain`, `ce soir`,
  jours de la semaine, `dans 3 jours`, `12/09`, `12 septembre`, `14h30`,
  `pendant 2h`.
- Étiquettes `#…` et mentions `@…` rattachées aux fiches de l'annuaire.
- Afficheur du total en cours, touche `TOTAL` qui imprime un sous-total et repart
  de zéro, clavier de calculatrice avec `%` et `TVA` paramétrable.
- **Déchirure de la bande** : archive les lignes terminées, conserve les actions
  non faites et les lignes épinglées, et produit une image du ticket à partager.
- Recherche plein texte, épinglage, modification et suppression ligne par ligne.

### Le jour

- Course du soleil en arc, position en temps réel, lever, coucher, durée du jour
  et écart avec la veille.
- Marée du lieu : courbe des vingt-quatre heures, pleines et basses mers à la
  minute par interpolation parabolique, sens du courant, marnage, vive-eau ou
  morte-eau. Repli automatique sur le port de référence le plus proche hors
  couverture maritime ; vingt-cinq ports embarqués, métropole et outre-mer.
- Lune : phase dessinée, éclairement, âge, lever et coucher, prochaines pleine et
  nouvelle lunes.
- Éphéméride embarquée : saint du jour (366 jours), dictons, jours fériés — Pâques
  calculée par l'algorithme de Butcher —, jour de l'année, semaine, jours restants
  et rubrique « ce jour-là ».
- Anniversaires de l'annuaire, avec l'âge et l'appel direct.
- Heures dorée et bleue, nuit noire, avec repère « en cours ».
- Périodes solunaires majeures et mineures, et note du jour sur quatre.
- Météo : température, ressenti, vent, rose des vents et force Beaufort.

### Agenda

- Bande des sept jours avec points de densité et balayage de semaine.
- Récurrences : quotidien, jours ouvrés, hebdomadaire, quinzaine, mensuel, annuel.
- Rappels multiples par événement, couleur, lieu, rattachement à un contact,
  validation par occurrence.
- Les actions du rouleau du jour apparaissent sous les rendez-vous.

### Annuaire

- Fiches groupées, favoris, recherche insensible aux accents.
- Appeler, écrire un SMS, envoyer un courriel, ouvrir le plan.
- Anniversaires reversés dans l'éphéméride.

### Widgets et notifications

- Widget **Le jour** en petit, moyen et grand format, plus écran verrouillé.
  Sur le format moyen, la première action non faite se coche sans ouvrir l'app.
- Widget **Marée** avec décompte jusqu'à la prochaine étale, version circulaire
  pour l'écran verrouillé.
- Rappels de rendez-vous, point du matin, bilan du soir, alerte heure dorée,
  alerte marée une heure avant chaque étale.
- Liens `blocgenda://rouleau`, `://jour`, `://agenda`, `://annuaire`, `://reglages`.

### Sous le capot

- SwiftUI et WidgetKit, iOS 18 minimum, sans aucune dépendance extérieure.
- Éphémérides solaires et lunaires calculées sur l'appareil (algorithmes de
  Meeus) : l'application reste utilisable sans réseau.
- Stockage local en JSON dans un groupe d'app partagé avec le widget, écriture
  différée, repli propre sur *Application Support* si le groupe est indisponible.
- Banc de tests du moteur exécutable sans simulateur
  (`./Tools/run-engine-tests.sh`).
- Icône générée par script, 1024 × 1024 en RVB strict, sans canal alpha.

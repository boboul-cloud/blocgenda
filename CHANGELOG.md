# Journal des modifications

Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) et la
numérotation [SemVer](https://semver.org/lang/fr/).

## [Non publié]

### Corrigé

- **Changer de lieu ne changeait pas la marée.** Un port de marée épinglé — par
  « Utiliser le port le plus proche » — continuait de servir quel que soit le
  lieu choisi ensuite, alors qu'il avait justement été retenu comme le plus
  proche du lieu d'alors. Il suit désormais le lieu, et la fiche annonce
  « marée : Brest » dès que les heures ne sont pas celles du lieu affiché.
- **Tirer la liste pour mettre à jour effaçait la marée.** Un relevé manqué
  remplaçait des heures justes par « Marée indisponible ». La courbe déjà
  affichée est maintenant conservée, l'échec se dit en un mot au-dessus avec
  l'heure du dernier relevé, et un simple geste relâché ne compte plus pour une
  panne. Au passage, toute erreur réseau était rangée sous « hors couverture
  maritime », ce qui déclenchait un second appel voué à l'échec sur un port de
  repli : la raison donnée par le service est désormais reprise telle quelle.

- **Les heures de marée avançaient d'environ trois quarts d'heure.** Les
  hauteurs viennent du modèle océanique global SMOC de Météo-France, dont la
  maille de huit kilomètres ne résout pas le port : pour Brest, elle tombe à une
  dizaine de kilomètres au large. Comparé aux annuaires officiels sur douze
  marées par port, le modèle avançait de 29 à 55 minutes selon l'endroit. Chaque
  lieu est désormais rattaché à la station calibrée la plus proche, comme un
  annuaire rattache un port secondaire à un port de référence : l'écart moyen
  tombe de 44 à 7 minutes. Là où aucune station ne couvre le lieu —
  Méditerranée, outre-mer — rien n'est corrigé, et la fiche le dit.
- **Le filtre par groupe de l'annuaire pouvait rester vide.** La liste des
  tiroirs se construisait à partir d'un ensemble, dont l'ordre de parcours est
  tiré au sort à chaque démarrage ; deux noms ne différant que par la casse ou
  les accents donnaient deux entrées jumelles dont une seule contenait les
  fiches, dans un ordre qui changeait d'un lancement à l'autre. Les tiroirs sont
  désormais rapprochés par la même règle partout — création, classement, filtre,
  compte et suppression — et leur ordre ne dépend plus du lancement.
- **Un groupe accentué se rangeait derrière les Z.** Les sections de l'annuaire
  se triaient sur l'ordre brut des points de code alors que le filtre triait
  alphabétiquement : « École » se retrouvait en fin de liste.

## [1.0] — 2026-08-08

Première version destinée à l'App Store, en **version 1.0, build 1**. Les
numéros 1.1 à 1.4 ci-dessous étaient des étapes de développement : rien n'ayant
jamais été publié, la numérotation repart de zéro. Leur contenu est intégralement
présent dans cette version.

### Ajouté

- **Un anniversaire renvoie à sa fiche.** Dans l'agenda, la ligne d'un
  anniversaire porte désormais un bouton « Voir la fiche », avec la pastille de
  la personne et l'âge qu'elle atteint ce jour-là quand l'année de naissance est
  connue. Il ouvre l'annuaire directement sur la fiche : recherche et filtre des
  favoris sont levés au passage pour qu'elle ne reste pas cachée, la liste s'y
  déplace toute seule et la carte s'annonce d'un liseré ambré le temps qu'on la
  trouve des yeux. On y trouve tout ce que l'agenda ne redit pas — le numéro
  pour appeler, l'adresse, le courriel. Le même renvoi figure dans l'éditeur du
  rendez-vous.
- **L'annuaire reprend les contacts du téléphone.** Un bouton ⤓ en haut de
  l'annuaire ouvre la liste du carnet d'adresses : on **coche les fiches à
  importer** — une par une, ou toutes d'un coup — on choisit le groupe
  d'arrivée, et c'est fait. Rien n'est repris à l'aveugle : les fiches déjà
  présentes portent la mention « Déjà là » et ne peuvent pas se dupliquer,
  le rapprochement se faisant sur le numéro (« 06 12 34 56 78 » et
  « +33 6 12 34 56 78 » sont la même personne), à défaut sur le courriel, à
  défaut sur le nom. C'est une recopie une fois pour toutes, pas une
  synchronisation : les contacts du téléphone ne sont jamais modifiés, et une
  fiche importée se corrige ensuite librement. Les dates de naissance suivent
  et s'inscrivent à l'agenda comme les autres ; quand le carnet ne donne que le
  jour et le mois, l'anniversaire revient tous les ans mais l'âge reste tu
  jusqu'à ce qu'on renseigne l'année.

### Modifié

- **Toute l'interface passe au clair.** Le châssis sombre est remplacé par un
  ivoire mat ; les cartes sont d'un blanc chaud légèrement soulevé, le texte est
  en encre noire. La métaphore reste celle d'une machine à écrire, mais dans sa
  version ivoire plutôt que noire — un carnet posé sur une table, qui se lit
  aussi bien en plein soleil que le soir. Les feuilles (réglages, éditeurs,
  archives) reprennent le même fond au lieu du gris d'iOS. La lune garde son
  propre rond de ciel nocturne : c'est la seule note sombre, et c'est bien ce
  qu'on vient y chercher.
- **La typographie grossit franchement.** Le grossissement de base passe de 1,18
  à 1,24, et les petits corps sont remontés davantage que les grands : les
  mentions à 9 ou 10 points — libellés de colonnes, unités, heures de marée —
  étaient les seules vraiment illisibles, et un agrandissement uniforme les
  aurait laissées derrière. Les pictogrammes, les boutons ronds, les touches de
  la calculatrice et la place réservée à la barre d'onglets suivent désormais la
  même échelle : rien ne rétrécit pendant que le texte grandit.
- **Les couleurs tiennent le contraste.** Sur fond clair, l'ambre vif ne se lit
  plus : les textes et les pictogrammes passent à un ambre profond, qui dépasse
  les 4,5:1 demandés par l'accessibilité, tandis que l'ambre vif reste réservé
  aux aplats. L'onglet ouvert est signalé par sa pastille autant que par sa
  couleur.

## [1.4] — 2026-08-07

### Ajouté

- **Les anniversaires s'inscrivent à l'agenda.** Dès qu'une fiche de l'annuaire
  porte une date de naissance, l'agenda reçoit un rendez-vous toute la journée,
  répété tous les ans, rappelé la veille, rattaché à la personne concernée.
  L'intitulé et la date suivent la fiche : renommer quelqu'un ou corriger sa
  date met le rendez-vous à jour, effacer la date le retire, supprimer la fiche
  aussi. Les rappels, la couleur et les notes ajoutés depuis l'agenda sont
  préservés. Les fiches déjà remplies sont reportées une fois, au lancement.

### Corrigé

- **Aucune notification n'arrivait jamais.** L'application ne demandait
  l'autorisation nulle part, sauf sous un bouton de l'écran des réglages qu'il
  fallait avoir l'idée d'aller chercher. Tant que la question n'est pas posée,
  iOS refuse tout en silence et n'affiche même pas Blocgenda dans
  *Réglages ▸ Notifications* : ni rappel de rendez-vous, ni point du matin, ni
  bilan du soir, alors que les deux derniers sont actifs d'origine. La demande
  est désormais faite au premier lancement.
- **Autorisation refusée : le bouton ne servait à rien.** iOS ne repose jamais
  la question ; l'écran des réglages le dit maintenant, et ouvre directement
  les Réglages d'iOS. L'état est relu au retour.

## [1.3] — 2026-08-07

### Ajouté

- **Les étiquettes deviennent trouvables.** Elles existaient depuis la première
  version — un mot précédé d'un dièse dans la ligne — mais rien ne le laissait
  deviner. Dès que la barre de saisie a le focus, une rangée s'affiche au-dessus :
  un bouton `#` pour en créer une, et les étiquettes déjà employées, les plus
  fréquentes d'abord, à placer d'un geste.
- **Toucher une étiquette sur le rouleau** ouvre la loupe et n'affiche plus que
  les lignes qui la portent.
- **Champ « Étiquettes » dans l'éditeur d'une ligne**, pour classer après coup
  sans avoir à retaper la ligne. Il accepte les espaces comme les virgules, avec
  ou sans dièse, et propose les étiquettes existantes.

## [1.2] — 2026-08-07

### Modifié

- **L'agenda ne montre plus les calculs.** La section du jour s'appelle
  désormais « Notes et actions » et ne retient que cela : un calcul et un
  sous-total ont leur place dans la colonne de chiffres du rouleau, pas dans
  une journée. Écrire une opération depuis la barre de l'agenda continue de
  fonctionner — elle part sur la bande, à la date du jour choisi, sans
  encombrer la liste. Les pastilles de la bande des sept jours comptent la
  même chose que ce qui est affiché.

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

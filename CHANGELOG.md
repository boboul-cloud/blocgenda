# Journal des modifications

Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) et la
numérotation [SemVer](https://semver.org/lang/fr/).

## [Non publié]

### Ajouté

- **Souhaits d'anniversaire et de fête.** Blocgenda rapproche chaque jour les
  fiches de l'annuaire du calendrier des postes — la date de naissance pour
  l'anniversaire, le prénom pour la fête — et prépare un message pour chacun.
  La comparaison des prénoms ignore la casse et les accents, accepte les
  variantes (« Rémi », « Rémy ») et fête un prénom composé avec chacune de ses
  parties. Deux règles la bordent : **seules les fiches de l'annuaire** sont
  concernées, jamais le carnet d'adresses du téléphone, et **seuls les groupes
  cochés** en réglages — aucun groupe coché, rien n'est préparé. La formule est
  tirée d'une réserve modifiable (`{prenom}` et `{age}` sont remplacés), en
  évitant celle servie la fois précédente à la même personne. L'envoi se fait
  d'un bouton, qui ouvre Messages avec le destinataire et le texte déjà écrits ;
  pour qu'il parte sans y penser, l'action **« Salutations du jour »** est
  exposée à Raccourcis, avec son mode d'emploi dans *Réglages ▸ Annuaire ▸
  Souhaits*. Une personne n'est rendue qu'une fois par jour, même si
  l'automatisation se déclenche deux fois. Tout se fait sur l'appareil : aucune
  application iOS n'ayant le droit d'envoyer un SMS d'elle-même, Blocgenda
  prépare, et c'est Raccourcis qui envoie.
- **Les fêtes du prénom dans l'écran *Le jour*.** La carte des anniversaires
  accueille les fiches dont c'est la fête, et l'éphéméride nomme les prénoms
  fêtés que son titre passe sous silence — le 14 juillet, c'est Camille.

- **Coefficient de marée.** La fiche *Marée* de l'écran *Le jour* porte
  désormais le coefficient, sur l'échelle française de 20 à 120 — un chiffre par
  pleine mer, comme dans un annuaire — et dit en toutes lettres ce qu'il vaut :
  morte-eau, vive-eau, grande marée. Il est calculé sur l'appareil, sans réseau,
  d'après les positions du soleil et de la lune : distance et déclinaison de
  chaque astre, écart entre les deux, et le retard d'un jour et demi que l'océan
  met à répondre. Les deux constantes de ce calcul ont été ajustées sur les
  coefficients officiels du SHOM de 2015, 2024, 2025 et 2026 — mille quatre cent
  soixante et un jours : l'écart type est de **1,5 point**, 96 % des journées
  tombent à moins de trois points, aucune au-delà de six. Cela reste une
  estimation ; pour naviguer, l'annuaire officiel fait foi.

### Modifié

- L'indication **vive-eau / morte-eau** se lit maintenant sur le coefficient là
  où il y en a un, et non plus sur la seule phase de la lune : la carte ne peut
  plus annoncer « morte-eau » à côté d'un coefficient de 95.
- Le coefficient est une convention française : il ne s'affiche que sur la
  façade **Manche–Atlantique**, où il a cours. En Méditerranée et outre-mer, la
  fiche s'en tient à la vive-eau lue sur la lune, comme avant.

## [1.1] - 2026-08-09

### Ajouté

- **Thèmes de l'agenda.** La fiche d'un rendez-vous porte désormais un
  **thème** — anniversaire, véhicule, santé, maison, travail, famille, loisirs,
  papiers — choisi dans un menu déroulant qui propose les thèmes d'office et
  tous ceux que l'on crée, depuis la fiche, depuis l'agenda ou depuis
  *Réglages ▸ Agenda ▸ Thèmes*. En haut de l'agenda, **Rechercher un thème**
  quitte la journée pour le sujet et rassemble tout ce qui s'y rapporte, la
  prochaine échéance d'abord, le passé ensuite ; chaque rendez-vous n'y paraît
  qu'une fois, à sa prochaine date, pour qu'une récurrence quotidienne ne
  remplisse pas la page à elle seule. Deux noms qui ne diffèrent que par la
  casse ou les accents désignent le même thème. **Les anniversaires venus de
  l'annuaire se rangent seuls sous « Anniversaire »** — ceux que l'agenda tient
  déjà comme ceux qu'une date de naissance y inscrira ; c'est le seul
  rendez-vous que l'application écrit elle-même, elle le range elle-même. Un
  anniversaire déplacé à la main sous un autre thème — « Famille », par
  exemple — y reste, et une modification de la fiche ne l'en sort pas.
  Retirer un thème ne
  supprime aucun rendez-vous : ceux qu'il rangeait se retrouvent sans thème.

- **Journal du jour.** Un cinquième écran, sur feuille de classeur : réglure
  bleue, marge rouge, perforations. On y dépose au fil de la journée des
  moments et des pensées — au clavier ou dictés — sans que rien ne soit analysé
  ni rangé ailleurs : le journal ne fait pas de calculs et ne prend pas de
  rendez-vous. Un moteur remet la page en forme selon **l'humeur du moment**,
  et l'on peut en changer autant de fois qu'on veut sans rien perdre :
  *posée* coud les moments en paragraphes, du matin au soir ; *vive* garde une
  ligne par moment, l'heure en marge, et tire en exergue la phrase la plus
  forte ; *songeuse* efface les heures et les titres, met une pensée en tête de
  page et laisse couler le reste. L'écriture tombe sur les lignes : chaque bloc
  occupe un nombre entier de réglures, y compris les titres et les citations en
  gros corps. Chaque page **retient la journée qu'il faisait** — température et
  ciel, lever et coucher, longueur du jour, lune, vent, pleine mer, saint,
  dicton, anniversaires, « ce jour-là » — relevé une fois pour toutes : dans un
  an, la météo du 9 août ne se retrouve plus. On tourne les pages vers le passé,
  jamais vers l'avenir, et la liste des moments permet de corriger une dictée
  mal comprise ou de retirer une ligne.

### Corrigé

- **La carte d'un rendez-vous découpait ses informations en colonnes.** Le
  thème, le lieu, la répétition et le rappel se partageaient une seule rangée :
  dès qu'ils étaient trois ou quatre, ou qu'une adresse un peu longue s'y
  trouvait, chacun était comprimé jusqu'à empiler ses lettres une par ligne. La
  rangée passe désormais à la ligne : chaque information garde sa largeur
  naturelle, le lieu peut prendre deux lignes — une adresse complète tient donc
  tout entière — et le nom du thème recherché ne se coupe plus dans son
  bouton.

- **« Voir la fiche » ouvrait l'annuaire sans montrer la personne.** Le lien
  d'un anniversaire, dans l'agenda, changeait bien d'onglet mais laissait la
  liste en tête, sans liseré : il fallait chercher la fiche à la main. Chaque
  tiroir était posé d'un bloc dans la liste, si bien que les fiches qu'il
  contient n'existaient pas tant que le tiroir n'était pas à l'écran — la visée
  portait sur une fiche introuvable et ne faisait rien. Les fiches sont
  désormais posées une à une : celle qu'on demande est amenée au centre, quel
  que soit son rang dans l'annuaire. Au passage, une visée interrompue — l'onglet
  qu'on quitte aussitôt — restait en attente et allumait une fiche au hasard
  d'un passage suivant.
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

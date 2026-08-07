# Contribuer à Blocgenda

Merci de l'intérêt. Blocgenda est une application personnelle dont le code est
publié pour la transparence, sous une [licence propriétaire](LICENSE) : les
contributions sont les bienvenues, mais le projet n'est pas ouvert au sens des
licences libres. Voici comment les choses fonctionnent.

## Ce qui aide le plus

1. **Signaler un bug.** C'est le plus utile.
   [Ouvrir un ticket](https://github.com/boboul-cloud/blocgenda/issues/new/choose).
2. **Signaler une donnée fausse.** Un saint du jour erroné, un dicton mal
   attribué, une heure de marée qui ne colle pas à l'annuaire du SHOM, une phrase
   que la barre de saisie comprend de travers : dites-le, avec le texte exact et
   le résultat attendu.
3. **Proposer une idée**, en expliquant l'usage réel derrière — pas seulement la
   fonctionnalité.

## Signaler un bug utilement

Indiquez :

- modèle d'appareil et version d'iOS ;
- version de Blocgenda (réglages → *À propos*) ;
- ce que vous avez fait, ce que vous attendiez, ce qui s'est produit ;
- pour un calcul ou une date mal comprise : **le texte exact tapé** ;
- une capture d'écran si l'affichage est en cause.

## Proposer du code

Les *pull requests* sont acceptées pour des **corrections ciblées** : un bug, une
faute de français, une donnée inexacte, un problème d'accessibilité. Pour une
fonctionnalité, ouvrez d'abord un ticket : mieux vaut discuter du principe avant
d'écrire cinq cents lignes qui ne seront pas retenues.

En proposant une contribution, vous accordez à l'auteur le droit de l'intégrer,
de la modifier et de la distribuer dans Blocgenda, y compris commercialement,
sous la licence du projet.

### Avant d'envoyer

```bash
xcodegen generate            # régénère le projet Xcode
./Tools/run-engine-tests.sh  # doit afficher « Tout est vert. »
xcodebuild -project Blocgenda.xcodeproj -scheme Blocgenda \
  -sdk iphonesimulator -destination 'name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO build
```

La compilation doit passer **sans avertissement**.

### Style

Le projet a des conventions ; suivez celles du fichier que vous modifiez.

- **Interface et commentaires en français**, y compris les noms de types visibles
  par l'utilisateur. Les identifiants Swift restent en anglais quand c'est
  l'usage (`start`, `duration`), en français quand c'est plus clair.
- Les commentaires expliquent **pourquoi**, pas **quoi**. Un commentaire qui
  paraphrase la ligne suivante n'a pas sa place.
- Pas de dépendance extérieure. Si une fonction manque, on l'écrit.
- Tout ce qui touche au moteur (calculatrice, dates, astronomie) doit être
  couvert dans `Tools/EngineTests/main.swift`.
- Typographie française : espace insécable avant `? ! : ; %`, guillemets `« »`,
  apostrophes courbes `’`.

### Commits

Messages en français, à l'impératif, une idée par commit :

```
Corrige la marée quand le port de repli est à cheval sur deux fuseaux
```

## Ce qui ne sera pas retenu

- L'ajout d'un SDK d'analyse, de publicité ou de suivi. Jamais.
- Toute fonction qui enverrait le contenu de l'utilisateur sur un serveur.
- Une traduction partielle : soit une langue est complète, soit elle attend.
- Un renommage massif ou une réécriture de style sans corriger de bug.

## Code de conduite

Restez courtois et factuel. Les échanges se font en français ou en anglais.
Tout propos insultant ou harcelant entraîne un blocage, sans discussion.

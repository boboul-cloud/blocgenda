# Politique de sécurité

## Versions suivies

| Version | Suivie |
|---|---|
| 1.0.x | oui |

## Signaler une faille

**N'ouvrez pas de ticket public** pour une faille de sécurité.

Écrivez à **bob.oulhen@gmail.com** avec, si possible :

- une description du problème et de son impact ;
- les étapes pour le reproduire ;
- la version de Blocgenda et d'iOS concernées.

Vous recevrez un accusé de réception sous une semaine. Une faille confirmée est
corrigée en priorité, et vous serez cité dans les notes de version si vous le
souhaitez. Il n'y a pas de programme de récompense : c'est une application
gratuite faite par une personne.

## Ce qui est dans le périmètre

- Fuite ou exposition des données de l'utilisateur (rouleau, agenda, annuaire).
- Faille dans la manipulation du conteneur partagé entre l'app et le widget.
- Injection ou dépassement dans l'analyseur d'expressions ou de dates.
- Interception ou détournement des liens `blocgenda://`.

## Ce qui est hors périmètre

- Les traitements opérés par Apple (sauvegarde iCloud, géocodage inverse) ou par
  Open-Meteo : signalez-les à ces éditeurs.
- Un appareil jailbreaké ou déverrouillé physiquement : les données de
  l'application y sont, par construction, accessibles.
- L'absence de chiffrement applicatif du stockage local. Blocgenda s'appuie sur
  la protection des données d'iOS, liée au code de déverrouillage de l'appareil.

## Modèle de menace, en clair

Blocgenda n'a **ni compte, ni serveur, ni synchronisation**. Il n'y a donc pas de
base de données à voler côté éditeur. La surface d'attaque se limite à
l'appareil, au conteneur partagé avec le widget, et aux deux appels réseau vers
Open-Meteo — qui ne transportent que des coordonnées arrondies, sans identifiant.

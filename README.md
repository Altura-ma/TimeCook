# Time Cook

Application iOS SwiftUI de calcul de temps de cuisson et de multi-cuisson pour que tous les plats soient prêts en même temps.

## Fonctionnalités

- Ajout de plusieurs plats avec durée de cuisson.
- Calcul automatique de l’ordre de lancement.
- Notifications locales de démarrage des plats courts et de fin de cuisson.
- Live Activity Apple / Dynamic Island pour suivre une cuisson en cours.
- Tests unitaires sur la logique de planning et de notifications.

## Identifiants App Store

- App existante : `Time Cook`
- Bundle ID principal : `com.vibecode.timecook`
- Extension Live Activity : `com.vibecode.timecook.LiveActivity`
- Version préparée : `1.1` / build `2`

## Commandes utiles

```bash
# Générer le projet Xcode si project.yml change
xcodegen generate

# Tests du cœur métier
swift test --package-path TimeCookCore

# Tests iOS simulateur
xcodebuild -project TimeCook.xcodeproj -scheme TimeCook -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' test CODE_SIGNING_ALLOWED=NO

# Build Release sans signature, pour validation technique locale
xcodebuild -project TimeCook.xcodeproj -scheme TimeCook -configuration Release -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO
```

## Publication

Pour envoyer la mise à jour App Store, ouvrir `TimeCook.xcodeproj`, connecter le compte Apple Developer, définir la Team sur les cibles `TimeCook` et `TimeCookLiveActivity`, puis faire `Product > Archive` et uploader via Organizer.

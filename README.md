# KalorienTracker

Minimalistischer Kalorientracker (iOS 17+, SwiftUI). Architektur- und Scope-Entscheidungen: siehe `TODO.md`.

## Setup

Das Xcode-Projekt wird nicht eingecheckt, sondern per [XcodeGen](https://github.com/yonaskolb/XcodeGen) aus `project.yml` generiert:

```sh
brew install xcodegen
xcodegen generate
open KalorienTracker.xcodeproj
```

Nach jeder Änderung an `project.yml` erneut `xcodegen generate` ausführen.

## Tests

```sh
# App
xcodebuild test -project KalorienTracker.xcodeproj -scheme KalorienTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Package (Domain, Data, Features)
cd CalorieCore && xcodebuild test -scheme CalorieCore-Package \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

## Lint & Format

```sh
swiftlint lint
swiftformat .
```

Ein vollständiger Architekturüberblick folgt in Phase 8 (siehe `TODO.md`).

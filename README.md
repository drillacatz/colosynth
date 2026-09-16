# ColoSynth

ColoSynth is a 2D mobile action combat game developed with Flutter and Flame. The game features timing-based combat mechanics, stylized comic-inspired visual presentation, interactive story sequences, a 3D character inspector, and monetization integrated via RevenueCat.

This project was built for the RevenueCat Shipaton 2026 hackathon (Next Gen Award track).

---

## Features

- Dynamic Combat Engine: Real-time 2D combat featuring attack sequences, parrying, dodging, counter-attacks, and stagger states.
- Comic Visual Design: Custom comic-inspired user interface with expressive layouts, bold typography, and hand-crafted animations.
- 3D Character Inspector: Interactive 3D model viewer allowing players to inspect unlocked characters with rotation controls and toon-shaded rendering.
- Narrative Sequences: Story cutscenes featuring typewriter text effects, character portraits, and guided onboarding tutorials.
- RevenueCat Monetization: Integrated in-app purchases supporting in-game resource bundles (Ink and Paint) alongside an Ad-Free entitlement.

---

## Technical Architecture

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart SDK >=3.3.0 <4.0.0) |
| Game Engine | Flame and Flame Audio |
| State Management | Flutter Riverpod |
| Monetization | RevenueCat (purchases_flutter) and Google Mobile Ads |
| Persistence and Sync | SharedPreferences with HMAC integrity checks and Firebase Firestore backup |
| 3D Presentation | model_viewer_plus (Google model-viewer Web Component) |

---

## Getting Started

### Prerequisites

- Flutter SDK (version 3.3.0 or higher)
- Android Studio or Visual Studio Code with the Flutter extension
- Android SDK (API 34 or higher recommended)

### Installation and Run (Quick Start for Reviewers & Judges)

1. Clone the repository:
   ```bash
   git clone https://github.com/drillacatz/colosynth.git
   cd colosynth
   ```

2. Fetch project dependencies:
   ```bash
   flutter pub get
   ```

3. Launch the application:
   The repository includes a ready-to-run mock environment template (`env.dart-define.example`) and automated Google Services fallback. Reviewers can launch directly in offline development mode without external API keys:
   ```bash
   flutter run --dart-define-from-file=env.dart-define.example
   ```
   Or run the automated test suite:
   ```bash
   flutter test --dart-define-from-file=env.dart-define.example
   ```

### Custom Configuration (For Production & Live Services)

To connect your own live Firebase, AdMob, or RevenueCat projects:
1. Create a local environment file:
   ```bash
   cp env.dart-define.example env.dart-define
   ```
2. Populate your live API credentials into `env.dart-define` (this file is gitignored and will remain local).
3. Place your active `google-services.json` into `android/app/` (also gitignored).
4. Run:
   ```bash
   flutter run --dart-define-from-file=env.dart-define
   ```

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for terms and conditions.

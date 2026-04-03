# TeamUp ⚽🏐🏀

Randomly generate fair, balanced teams from a list of players — right before the game, no arguments needed.

Built with **Flutter 3.41.6** · runs as an **Android app** and a **browser PWA**.

[![Deploy to GitHub Pages](https://github.com/micheleIT/teamup/actions/workflows/pages.yml/badge.svg)](https://github.com/micheleIT/teamup/actions/workflows/pages.yml)

---

## Features

- **Add & manage players** — add names on the spot, rename or remove them at any time
- **Sport presets** — Soccer ⚽, Volleyball 🏐, Basketball 🏀, or a fully custom mode
- **Configurable team count** — pick 2 … N teams with a simple +/− stepper
- **Fair shuffling** — players are distributed as evenly as possible across teams
- **Wheel of Fortune mode** — animated wheel-spin assignment as an alternative to instant shuffle
- **Reshuffle at any time** — one tap to generate a completely new draw; prompts to record the current result first (opt-out in Settings)
- **Record game results** — log wins, losses, and draws right after a match; each result can only be recorded once per team arrangement
- **Player statistics** — view aggregated per-player stats (games played, wins, losses, draws) across all recorded games
- **Settings screen** — toggle Wheel of Fortune mode, auto-ask for results, and other preferences
- **Light & dark theme** — follows the system preference automatically
- **PWA-ready** — installable from the browser, works offline

---

## Live Demo

> **[https://micheleIT.github.io/teamup/](https://micheleIT.github.io/teamup/)**

---

## Getting Started

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter | 3.41.6 |
| Dart | 3.11.4 |
| Brave / Chromium | any recent |

**Key pub dependencies**

| Package | Purpose |
|---------|---------|
| `shared_preferences` | Local persistence for game records & statistics |

### Run in the browser

```bash
# First time only — set your Chromium-based browser
export CHROME_EXECUTABLE=/usr/bin/brave   # or /usr/bin/chromium, etc.

flutter pub get
flutter run -d chrome
```

### Run on Android

```bash
flutter run   # with a device connected or emulator running
```

### Build for production

```bash
# Web (output → build/web/)
flutter build web --release --base-href /teamup/

# Android APK (output → build/app/outputs/flutter-apk/)
flutter build apk --release
```

---

## Project Structure

```
lib/
├── main.dart                      # App entry point & MaterialApp setup
├── app_state.dart                 # ChangeNotifier state (players, sport, team count, wheel flag)
├── models/
│   ├── game_record.dart           # GameRecord / GameTeam / GamePlayer value objects
│   ├── player.dart                # Player value object
│   ├── player_stats.dart          # Aggregated per-player statistics
│   ├── sport.dart                 # Sport enum with presets
│   └── team.dart                  # Team value object
├── services/
│   └── stats_service.dart         # Persist game records & compute player stats (shared_preferences)
├── utils/
│   └── team_generator.dart        # Shuffle & even distribution logic
├── widgets/
│   ├── court_background.dart      # Sport-specific court background widget
│   └── fortune_wheel.dart         # Animated Wheel-of-Fortune widget
└── screens/
    ├── home_screen.dart           # Player list, sport selector, team count stepper
    ├── teams_screen.dart          # Colour-coded team result cards
    ├── wheel_assignment_screen.dart # Animated wheel-spin team assignment
    ├── record_result_sheet.dart   # Bottom sheet for recording game results
    ├── stats_screen.dart          # Per-player statistics view
    └── settings_screen.dart       # App settings (Wheel of Fortune toggle, etc.)
```

---

## CI / CD

### Web deployment (`pages.yml`)

Every push to `main` triggers a GitHub Actions workflow that:

1. Installs Flutter (with caching)
2. Runs `flutter build web --release`
3. Deploys the output to **GitHub Pages**

To enable, go to **Settings → Pages → Source → GitHub Actions** in your repository.

### Android release (`release.yml`)

Pushing a version tag (e.g. `v1.2.3`) triggers a second workflow that:

1. Builds a signed release APK using keystore credentials stored as repository secrets
2. Creates a GitHub Release with the APK attached and an auto-generated changelog

Required repository secrets: `KEYSTORE_BASE64`, `KEY_ALIAS`, `KEY_PASSWORD`, `KEYSTORE_PASSWORD`.

---

## License

[GPL-3.0](LICENSE)

# TeamUp ⚽🏐🏀

Randomly generate fair, balanced teams from a list of players — right before the game, no arguments needed.

Built with **Flutter 3.41.6** · runs as an **Android app** and a **browser PWA**.

[![Tests](https://github.com/micheleIT/teamup/actions/workflows/test.yml/badge.svg)](https://github.com/micheleIT/teamup/actions/workflows/test.yml)
[![Deploy to GitHub Pages](https://github.com/micheleIT/teamup/actions/workflows/pages.yml/badge.svg)](https://github.com/micheleIT/teamup/actions/workflows/pages.yml)

---

## Features

- **Add & manage players** — add names on the spot, rename or remove them at any time; player names must be unique (case-insensitive)
- **Sport presets** — Soccer ⚽, Volleyball 🏐, Basketball 🏀, or a fully custom mode
- **Configurable team count** — pick 2 … N teams with a simple +/− stepper
- **Fair shuffling** — players are distributed as evenly as possible across teams
- **Wheel of Fortune mode** — animated wheel-spin assignment as an alternative to instant shuffle
- **Reshuffle at any time** — one tap to generate a completely new draw; prompts to record the current result first (opt-out in Settings)
- **Record game results** — log wins, losses, and draws right after a match; each result can only be recorded once per team arrangement
- **Player statistics** — view aggregated per-player stats (games played, wins, losses, draws) with a **Today / All Time** toggle and per-sport breakdown
- **Import / Export statistics** — export game records as JSON (today's games or all-time) to a clipboard-ready string; import on any device and choose to **merge** (add new records, skip duplicates) or **replace** (overwrite all local data)
- **In-app update notifications** — background check against GitHub Releases; opt into dev-version notifications in Settings
- **Settings screen** — toggle Wheel of Fortune mode, auto-ask for results, and dev-release notifications
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

### Key dependencies

| Package | Purpose |
|---------|---------|
| `shared_preferences` | Persist game records, statistics & settings |
| `http` | Fetch GitHub Releases API for update checks |
| `package_info_plus` | Read the app's current version at runtime |
| `url_launcher` | Open release URLs in the system browser |

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

## Project structure

```
lib/
├── main.dart                        # App entry point & MaterialApp setup
├── app_state.dart                   # ChangeNotifier (players, sport, team count, settings)
├── models/
│   ├── game_record.dart             # GameRecord / GameTeam / GamePlayer value objects
│   ├── player.dart                  # Player value object
│   ├── player_stats.dart            # Aggregated per-player statistics model
│   ├── sport.dart                   # Sport enum with per-sport presets
│   └── team.dart                    # Team value object
├── services/
│   ├── stats_service.dart           # Persist game records & compute player stats
│   └── update_service.dart          # GitHub Releases update checker
├── utils/
│   └── team_generator.dart          # Shuffle & even-distribution logic
├── widgets/
│   ├── court_background.dart        # Sport-specific court background widget
│   └── fortune_wheel.dart           # Animated Wheel-of-Fortune widget
└── screens/
    ├── home_screen.dart             # Player list, sport selector, team count stepper
    ├── teams_screen.dart            # Colour-coded team result cards
    ├── wheel_assignment_screen.dart # Animated wheel-spin team assignment
    ├── record_result_sheet.dart     # Bottom sheet for recording game results
    ├── stats_screen.dart            # Per-player statistics (Today / All Time toggle)
    └── settings_screen.dart         # Wheel of Fortune, auto-ask & update settings

test/
├── widget_test.dart                 # Smoke test for the app widget tree
├── app_state_test.dart              # Unit tests for player name uniqueness
├── teams_screen_test.dart           # Teams screen widget tests
├── stats_service_test.dart          # Unit tests for stats computation & period filter
└── update_service_test.dart         # Unit tests for version comparison & update checks
```

---

## Running tests

```bash
flutter test
```

The test suite covers:

- **Player name uniqueness** — duplicate detection on add and rename (exact and case-insensitive)
- **Stats computation** — wins / losses / draws aggregation, `Today` vs. `All Time` period filter, sport filter, combined filters
- **Import / Export** — `exportToJson` (all-time and today-only), `importFromJson` (merge mode, replace mode, roundtrip, persistence, error handling)
- **Update checker** — semantic version comparison, dev-version detection, GitHub API integration (mocked)
- **Widget smoke tests** — app starts and core screens render without errors

---

## CI / CD

### Tests (`test.yml`)

Every pull request targeting `main` runs the full unit and widget test suite. To make this a required check, enable **"Require status checks to pass before merging"** for the `main` branch under **Settings → Branches** and select the `test` job.

### Web deployment (`pages.yml`)

Every push to `main` triggers a workflow that:

1. Installs Flutter (with caching)
2. Runs `flutter build web --release`
3. Deploys the output to **GitHub Pages**

To enable, go to **Settings → Pages → Source → GitHub Actions** in your repository.

### Android release (`release.yml`)

Pushing a version tag (e.g. `v1.2.3`) triggers a workflow that:

1. Builds a signed release APK using keystore credentials stored as repository secrets
2. Creates a GitHub Release with the APK attached and an auto-generated changelog

Required repository secrets:

| Secret | Description |
|--------|-------------|
| `KEYSTORE_BASE64` | Base64-encoded `.jks` / `.keystore` file |
| `KEY_ALIAS` | Key alias inside the keystore |
| `KEY_PASSWORD` | Key password |
| `KEYSTORE_PASSWORD` | Store password |

---

## License

[GPL-3.0](LICENSE)

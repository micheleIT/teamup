# TeamUp ⚽🏐🏀

Randomly generate fair, balanced teams from a list of players — right before the game, no arguments needed.

Built with **Flutter 3.41.2** · runs as an **Android app** and a **browser PWA**.

[![Deploy to GitHub Pages](https://github.com/micheleIT/teamup/actions/workflows/pages.yml/badge.svg)](https://github.com/micheleIT/teamup/actions/workflows/pages.yml)

---

## Features

- **Add & manage players** — add names on the spot, rename or remove them at any time
- **Sport presets** — Soccer ⚽, Volleyball 🏐, Basketball 🏀, or a fully custom mode
- **Configurable team count** — pick 2 … N teams with a simple +/− stepper
- **Fair shuffling** — players are distributed as evenly as possible across teams
- **Reshuffle at any time** — one tap to generate a completely new draw
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
| Flutter | 3.41.2 |
| Dart | 3.11.4 |
| Brave / Chromium | any recent |

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
├── main.dart                 # App entry point & MaterialApp setup
├── app_state.dart            # ChangeNotifier state (players, sport, team count)
├── models/
│   ├── player.dart           # Player value object
│   ├── sport.dart            # Sport enum with presets
│   └── team.dart             # Team value object
├── utils/
│   └── team_generator.dart   # Shuffle & even distribution logic
└── screens/
    ├── home_screen.dart      # Player list, sport selector, team count stepper
    └── teams_screen.dart     # Colour-coded team result cards
```

---

## CI / CD

Every push to `main` triggers a GitHub Actions workflow that:

1. Installs Flutter (with caching)
2. Runs `flutter build web --release`
3. Deploys the output to **GitHub Pages**

To enable, go to **Settings → Pages → Source → GitHub Actions** in your repository.

---

## License

MIT

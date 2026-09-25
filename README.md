# 🌟 VERNEXA — AI Multilingual Classroom Assistant

**VERNEXA** is an offline-first AI classroom assistant application built with Flutter, enabling real-time speech translation, teacher coaching, interactive flashcards, worksheets, and curriculum learning between Hindi and regional/tribal Indian languages (e.g., Santali, Gondi, Kurukh, Mundari, Kui).

---


---

## 💻 Local Development

### Prerequisites
* Flutter SDK (3.13+ or latest stable)
* Chrome / Edge (recommended for Speech Recognition APIs)

### Run in Browser
```bash
cd mobile_app
flutter pub get
flutter run -d chrome
```

### Build for Production
```bash
cd mobile_app
flutter build web --release --no-wasm-dry-run
```

---

## 📁 Project Structure

```
VERNEXA/
├── .github/
│   └── workflows/
│       └── deploy.yml        # Automated GitHub Actions build & verification
├── .gitignore                # Clean GitHub ignore rules (builds, caches, temp files)
├── README.md                 # Project documentation & deployment guide
├── TECH_STACK.md             # Complete architecture and ML model specification
├── build.sh                  # Automated Vercel / CI build pipeline script
├── package.json              # Vercel deployment detection manifest
├── vercel.json               # Vercel SPA routing and caching configuration
└── mobile_app/               # Core Flutter Application
    ├── lib/                  # Screens, Core Services, Widgets & State
    ├── assets/               # Production Images, Banners & Flashcard Assets
    ├── web/                  # Web wrapper with Vercel SPA config & Web Speech API
    ├── android/              # Native Android project configuration
    ├── ios/                  # Native iOS project configuration
    └── pubspec.yaml          # Flutter dependencies and asset registrations
```

---

## 🛡️ License

This project is licensed under the Apache 2.0 License.

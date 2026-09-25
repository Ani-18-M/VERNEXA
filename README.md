# 🌟 VERNEXA — AI Multilingual Classroom Assistant

**VERNEXA** is an offline-first AI classroom assistant application built with Flutter, enabling real-time speech translation, teacher coaching, interactive flashcards, worksheets, and curriculum learning between Hindi and regional/tribal Indian languages (e.g., Santali, Gondi, Kurukh, Mundari, Kui).

---

## 🚀 Easy Deployment on Vercel

VERNEXA is pre-configured with **zero-configuration Vercel deployment** and complete **Single-Page Application (SPA) reload support** (eliminates 404 errors on browser refresh across all routes).

### Option A: 1-Click Vercel Git Integration (Recommended)

1. Push this repository to your **GitHub** account (see instructions below).
2. Go to [Vercel Dashboard](https://vercel.com/dashboard) and click **"Add New Project"**.
3. Import your **VERNEXA** repository.
4. Vercel automatically detects [`vercel.json`](vercel.json) and [`package.json`](package.json).
   - **Framework Preset**: Other
   - **Build Command**: `bash build.sh` (automatic)
   - **Output Directory**: `mobile_app/build/web` (automatic)
5. Click **Deploy**!
   > During deployment, `build.sh` automatically installs the stable Flutter SDK on Vercel, runs `flutter pub get`, and compiles the release web build.

### Option B: Deploy via Vercel CLI

```bash
# 1. Build the Flutter Web application locally
cd mobile_app
flutter build web --release

# 2. Deploy directly with Vercel CLI
npm install -g vercel
vercel deploy --prod
```

### 🔄 No Reload Errors Guaranteed

All sub-routes (such as `/home`, `/translate`, `/teacher_coach`, `/worksheets`, `/flashcards`, etc.) are configured with:
* **SPA Rewrites**: In [`vercel.json`](vercel.json), all non-asset requests rewrite to `/index.html`.
* **Path URL Strategy**: Clean HTML5 URLs without the `/#/` hash (`usePathUrlStrategy()`).
* **Route Normalization**: Automatic handling of trailing slashes, query parameters, and unknown routes in [`mobile_app/lib/main.dart`](mobile_app/lib/main.dart).

---

## 📦 Uploading to GitHub

To upload this project to your GitHub account:

```bash
# 1. From the VERNEXA root directory:
cd /path/to/VERNEXA

# 2. If not already a git repository:
git init

# 3. Stage and commit the clean codebase:
git add .
git commit -m "feat: initial commit of VERNEXA ready for GitHub & Vercel"

# 4. Link to your GitHub repository:
git remote add origin https://github.com/<YOUR-USERNAME>/VERNEXA.git
git branch -M main

# 5. Push to GitHub:
git push -u origin main
```

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

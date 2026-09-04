# FocusFlow

FocusFlow is a personal productivity platform consisting of:

- **Web Application**: Built with Next.js (located in `/planner`)
- **Mobile Application**: Built with Flutter (located in `/mobile`)

---

## Repository Structure

```
FocusFlow/
├── planner/              # Next.js Web Application
│   ├── src/              # Application source code
│   ├── public/           # Static public assets
│   ├── prisma/           # Database schema & migrations
│   ├── supabase/         # Supabase SQL migrations
│   ├── package.json      # Dependencies & scripts
│   └── ...
│
├── mobile/               # Flutter Mobile Application
│   ├── lib/              # Dart application source code
│   ├── assets/           # Images, animations, and icons
│   ├── android/          # Native Android project configuration
│   ├── ios/              # Native iOS project configuration
│   ├── pubspec.yaml      # Dependencies & assets configuration
│   └── ...
│
└── README.md             # Repository documentation
```

---

## Quick Start

### Web Application (`/planner`)
```bash
cd planner
npm install
npm run dev
```

### Mobile Application (`/mobile`)
```bash
cd mobile
flutter pub get
flutter run
```

# BoiBitan (বইবিতান)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Core%20%7C%20Auth%20%7C%20Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

BoiBitan is an open-access e-library and reader application built with Flutter. It brings together curated Bengali literature, translated world classics, and public-domain works from digital archives such as Internet Archive and Project Gutenberg. The app is engineered for offline reading, resilient bilingual search, and cloud synchronization across devices.

---

## Key Features

### Fuzzy Multilingual Search

- Custom similarity scoring based on Levenshtein distance, character trigrams, and phonetic normalization.
- Handles typos, partial matches, and phonetic transliterations across Bengali and English (e.g., matching `"robindro"` to Rabindranath Tagore, or `"gitanjoli"` to Gitanjali).
- Multi-field ranking evaluates matches across titles, author names, and category tags.

### Offline-First PDF Storage

- Direct PDF rendering via native views (`flutter_pdfview`) with dynamic page detection.
- Remote documents and public-domain titles are cached to the local device storage using Dio, allowing offline reading without repeated network downloads.
- Bookmarks and reading progress update immediately on device and persist across app launches.

### Firestore Cloud Sync

- Real-time synchronization for bookmarks and reading history via Cloud Firestore subcollections:
  - `users/{uid}/reading_history/{bookId}`
  - `users/{uid}/bookmarks/{bookId}`
- Offline persistence enabled by default, queuing updates locally when offline and reconciling changes transparently when back online.

### Scoped User Isolation

- Strict user data scoping keyed by Firebase Auth `uid`.
- Saved books, downloads, and progress state are stored in user-specific namespaces (`downloads/user_${uid}/`).
- Account switching cleanly flushes in-memory controllers and caches to avoid cross-account data leakage on shared devices.
- Guest sessions operate safely within a dedicated local guest namespace.

### Bilingual Interface & Reading Themes

- Full bilingual UI in Bengali (বাংলা) and English with localized typography and numeral conversions.
- Dual visual themes: **Parchment Light** (warm paper aesthetic) and **Obsidian Dark** (high-contrast night reading).
- Language toggle available on authentication screens and settings to keep the main reading views focused.

---

## Project Structure

```text
lib/
├── config/              # App constants and service configuration
├── data/                # Static curated catalog and collection definitions
├── l10n/                # Localization maps and locale notifier
├── models/              # Immutable domain models (Book, UserBookProgress, BookmarkItem)
├── repositories/        # Cloud Firestore sync and remote repository layer
├── screens/             # UI screens
│   ├── auth/            # Authentication, OTP verification, and password reset
│   ├── home_screen.dart # Catalog browsing and category feeds
│   ├── my_library_screen.dart # User bookmarks, active reads, and downloads
│   ├── pdf_reader_screen.dart # In-app PDF viewer and progress tracking
│   └── settings_screen.dart   # Language, theme, and profile preferences
├── services/            # Core business logic (Auth, Storage, BookApi, Downloads)
├── theme/               # Application color schemes and typography
├── utils/               # Fuzzy search and string normalization utilities
└── widgets/             # Reusable UI widgets and components
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.19.0 or higher
- [Dart SDK](https://dart.dev/get-dart) 3.3.0 or higher
- Android Studio, VS Code, or command-line tools
- An active Android/iOS device, emulator, or desktop runner

### Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/si4795/BoiBitan.git
   cd BoiBitan
   ```

2. **Install project dependencies:**

   ```bash
   flutter pub get
   ```

3. **Firebase Configuration:**
   If you are running the project under your own Firebase project, configure it using the FlutterFire CLI:

   ```bash
   flutterfire configure
   ```

   Ensure `lib/firebase_options.dart` contains the generated platform options for your project.

4. **Run the application:**

   ```bash
   # Launch on the default connected device
   flutter run

   # Or specify a target
   flutter run -d android
   flutter run -d windows
   ```

---

## Testing

The project includes unit and widget tests covering search scoring, language integrity filtering, Firestore serialization, and multi-user storage scoping.

```bash
# Run static code analysis
flutter analyze

# Run the automated test suite
flutter test
```

---

## License

Distributed under the [MIT License](LICENSE).

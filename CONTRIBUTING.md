# Contributing to MyQuran

First off, thank you for considering contributing to **(قرآني)**! 

## 🎯 Core Philosophy
1.  **Performance First:** We use `ScrollablePositionedList` and Hit-Testing because standard rendering is too slow for 600+ pages. Any PR that causes scroll jank will be rejected.
2.  **Zero Bloat:** The app size must stay as small as possible.
3.  **100% Offline:** The app must function perfectly without internet access.
4.  **Privacy:** We track nothing. Do not add analytics or telemetry.

---

## 🛠️ Getting Started

### 1. Prerequisites
*   Flutter SDK (Stable channel).
*   Dart SDK.

### 2. Setup
```bash
# Clone the repo
git clone https://github.com/dmouayad/my_quran.git

# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## 📂 Project Architecture

We use a "Pure Flutter" approach to keep things simple:

*   **State Management:** We use `ValueNotifier` and `setState`. We deliberately avoid heavy libraries like Bloc or Riverpod to keep the app lightweight.
*   **Data Source:** The Quran text is **not** hardcoded in Dart. It is loaded from `assets/quran.json` into memory at startup.
*   **Search Engine:** We use a custom Inverted Index (`assets/search_index.json`) loaded via Isolate.

---

## 🚀 Submitting a Pull Request

1.  **Fork** the repo and create your branch from `main`.
2.  If you've added code that should be tested, add tests.
3.  **Format your code:**
    ```bash
    dart format .
    ```
4.  **Run the Analyzer:**
    ```bash
    flutter analyze
    ```
5.  Ensure your build size hasn't exploded.
6.  Submit the PR with a clear description and **Screenshots** (if you changed the UI).

---

## 🐛 Reporting Bugs

If you find a bug, please open an issue and include:
*   Device / Android Version.
*   Steps to reproduce.
*   If it's a Quran text error, please provide the Surah and Verse number.

---

**Jazak Allah Khair for your help!**

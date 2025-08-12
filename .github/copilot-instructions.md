# Copilot Instructions for MangaMari

## Project Overview
MangaMari is an Android manga reader built with Flutter (latest stable), inspired by Kotatsu, and designed for legal, open-source manga source extensions. Architecture uses MVVM and Clean Architecture, Riverpod for state management, and Material 3 for UI. All code and assets must comply with open-source licensing.

## Key Directories & Files
- `lib/`: Main Flutter app code. Entry point: `main.dart`.
- `test/`: Widget and unit tests. Example: `widget_test.dart`.
- `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/`: Platform-specific code and build configs.
- `pubspec.yaml`: Dependencies and project metadata.
- `.github/copilot-instructions.md`: This file.

## Stack & Architecture
- **Flutter (latest stable)**: Cross-platform UI framework.
- **Android target**: Main deployment platform.
- **Riverpod**: All state management via Riverpod providers.
- **MVVM / Clean Architecture**: Separate UI, business logic, and data layers. Use ViewModels for state and logic.
- **Material 3**: UI components and theming must follow Material 3 guidelines.

## Architecture & Patterns
**Source Extensions**: Integrate manga sources via a loader system. Only use open-source, legally safe APIs.

## Developer Workflows
- **Build (Android):**
  ```powershell
  flutter build apk
  flutter run
  ```
- **Test:**
  ```powershell
  flutter test
  ```
- **Hot Reload:**
  Use IDE hot reload or:
  ```powershell
  flutter run
  ```
- **Add Dependencies:**
  ```powershell
  flutter pub add <package>
  ```

## Core Features
- Home (latest, popular, trending)
- Multi-source search + category filters
- Manga details, chapter list, reader modes (vertical/horizontal, continuous scroll, zoom, LTR/RTL, brightness/bg)
- Favorites, bookmarks, downloads (offline)
- Multi-source toggle, history tracking
- Dark/light theme, settings

## Project-Specific Conventions
- **Licensing:** Only use MIT, Apache-2.0, or GPL-compatible dependencies and sources. If license is unclear, stop and suggest alternatives.
- **No copyrighted APIs/assets.**
- **Status Tracker:**
  Always update the following tracker in your replies:
  ```
  PH1: [ ] Project created  [ ] Deps added  [ ] Folder structure  [ ] Theme  [ ] Nav  
  PH2: [ ] Extension loader  [ ] Source UI  [ ] Multi-language  
  PH3: [ ] Home  [ ] Search  [ ] Filters  [ ] Details  [ ] Chapters  [ ] Reader modes  
  PH4: [ ] Favorites  [ ] Downloads  [ ] History  
  PH5: [ ] UI refine  [ ] Performance  [ ] QA
  ```
  Also update `Last Completed Step` after each reply.

## Work Method for AI Agents
At each reply:
1. Recap Status Tracker + Last Completed Step
2. Compliance check (licensing, assets)
3. Plan next steps
4. Code/implement
5. Update tracker

## Integration Points
- **Source Loader:** All manga sources must be loaded via the extension system. Reference the loader in the source integration phase.
- **State Management:** Use Riverpod for all cross-component communication.

## Example Patterns
- Widget tests in `test/widget_test.dart`.
- Main app entry in `lib/main.dart`.

## References
- [Flutter Docs](https://docs.flutter.dev/)
- [Riverpod Docs](https://riverpod.dev/)
- [Material 3](https://m3.material.io/)

---
For unclear or incomplete sections, request feedback and iterate. Always document only discoverable, enforced patterns—not aspirational practices.

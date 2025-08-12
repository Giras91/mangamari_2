# mangamari

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

## Versioning, Releases, and Update Checker

### Semantic Versioning
- The app uses `major.minor.patch+build` format in `pubspec.yaml`.
- Example: `1.0.0+1`
- Bump version for releases:
  - Breaking changes: increase major (e.g. 2.0.0+1)
  - New features: increase minor (e.g. 1.1.0+1)
  - Bugfixes: increase patch (e.g. 1.0.1+1)
  - For each build: increase build number (e.g. 1.0.0+2)

### Git Branching & Tagging
- Branches:
  - `main`: stable
  - `dev`: development
  - `feature/*`: per feature
- Tag releases on `main`:
  ```sh
  git checkout main
  git pull
  git tag -a v1.0.0 -m "Release v1.0.0"
  git push origin v1.0.0
  ```

### GitHub Actions Release Pipeline
- On push of a tag (e.g. `v1.0.0`), GitHub Actions builds the APK and attaches it to the release.
- See `.github/workflows/release-apk.yml` for details.

### version.json (GitHub Pages)
- Host `version.json` at `https://Giras91.github.io/mangamari_2/version.json`.
- Example:
  ```json
  {
    "latest_version": "1.0.1+2",
    "apk_url": "https://github.com/Giras91/mangamari_2/releases/download/v1.0.1/app-release.apk",
    "changelog": "• Bug fixes\n• Improved reader performance\n• New source manager UI"
  }
  ```

### Update Checker Widget
- The app checks for updates in Settings using `UpdateChecker`.
- If a newer version is found, a dialog shows changelog and download button.
- To update, host a new APK and update `version.json`.

### License Compliance
- All dependencies are checked for MIT compatibility.
- If you add new packages, verify their license before use.

---

## How to Release a New Version
1. Bump version in `pubspec.yaml`.
2. Commit and push to `main`.
3. Tag the release:
   ```sh
   git tag -a v1.0.1 -m "Release v1.0.1"
   git push origin v1.0.1
   ```
4. GitHub Actions will build and attach the APK to the release.
5. Update `version.json` on GitHub Pages with new version, APK URL, and changelog.

## How the Update Checker Works
- On app launch (Settings), the widget fetches `version.json`.
- Compares with current app version.
- If newer, shows dialog with changelog and download link.

---

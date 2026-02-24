# bulls_eye

A new Flutter project.

## iOS build: CocoaPods required

If you see **"CocoaPods not installed or not in valid state"** when running on iOS:

1. **Install CocoaPods** (run in your system terminal, not inside Cursor):

   **Option A – Homebrew** (fix permissions first if needed):
   ```bash
   sudo chown -R $(whoami) /opt/homebrew
   brew install cocoapods
   ```

   **Option B – Ruby gem**:
   ```bash
   sudo gem install cocoapods
   ```

2. **Install iOS dependencies** from the project root:
   ```bash
   cd ios && pod install && cd ..
   ```

3. Run the app again: `flutter run` or run from your IDE.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

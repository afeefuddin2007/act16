# ICA16 Class A: Starter Project (Flutter + OpenTDB + Firebase)

This is a starting point, not a finished submission. You must run it yourself, complete the Firebase setup, collect your own test evidence, and write your own answers. Your instructor check will ask you to explain and reproduce your code.

**Status:** this code was written without a Flutter SDK available, so it has NOT been compiled. Step 0 below is where you find and fix any errors.

## 0. Create the Flutter project and copy these files

```bash
flutter create ica16_quiz
cd ica16_quiz
```

Replace `lib/` with this folder's `lib/`. Then add dependencies:

```bash
flutter pub add http html_unescape firebase_core firebase_auth cloud_firestore
```

Run `flutter analyze` and fix any reported errors before continuing.

## 1. Firebase setup (about 20 minutes)

1. Go to https://console.firebase.google.com and create or select a class project. Use only the project your instructor approves, or your own separate project.
2. **Firestore Database**: Create database, choose **Standard edition**, **Native mode**, **production mode**.
3. **Authentication**: Sign-in method, enable **Email/Password**. Under Users, add **two** test users (test A and test B). Do not paste these passwords into code or the repo.
4. Install the tools:
   ```bash
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   ```
5. From the Flutter project root, run `flutterfire configure`. Pick the project and the Android app. This creates `lib/firebase_options.dart`, which `main.dart` imports.
6. Android: add this line inside `<manifest>` in `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   ```
   If the build complains about minimum SDK, set `minSdk` to 23 in `android/app/build.gradle` (or `build.gradle.kts`).

## 2. Deploy the security rules

Copy `firebase/firestore.rules` and `firebase/firebase.json` into the Firebase project folder (or your project root), then:

```bash
firebase use --add     # pick the same project
firebase deploy --only firestore:rules
```

Verify in the console that the rules changed. Never switch to open rules (`allow read, write: if true`) to fix an error.

## 3. Run

```bash
flutter run
```

Sign in as test user A. Play a round, submit, and confirm the status shows **Cloud verified**.

## 4. Build the APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`. Rename it `ICA16_A_YourName.apk` and install-test it.

## 5. Evidence and tests

Use `TEST_CASES.md`. Run T01 to T12 in order. Take screenshots and save console records. For T09 and T12, label each injected fault clearly.

## Things that will probably go wrong (check these first)

- `firebase_options.dart` missing: run `flutterfire configure` again.
- Permission denied on submit: rules not deployed, or you are signed in as the wrong user.
- "unavailable" while online: check internet on the emulator, and that the Firebase project is the one you configured.
- Questions fail to load: wait at least 5 seconds between OpenTDB requests (rate limit). Do not retry in a loop.
- Each `Submit` should create exactly one document, at `users/{yourUid}/attempts/{roundId}`. Check the Firestore data viewer.

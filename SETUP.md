# Bonkilingo Flutter - Setup Guide

## Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.2.0 or higher)
  - [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (comes with Flutter)
- **Android Studio** (for Android development)
- **Xcode** (for iOS development - macOS only)
- **Git**

## Step 1: Clone the Repository

```bash
cd /Users/klev/Code/BONK-APP/bonkilingo_flutter
```

The project has already been created with the proper structure.

## Step 2: Install Dependencies

```bash
flutter pub get
```

This will install all the packages defined in `pubspec.yaml`.

## Step 3: Environment Configuration

### 3.1 Create `.env` File

Create a `.env` file in the root directory:

```bash
cp .env.example .env
```

### 3.2 Configure Environment Variables

Edit `.env` with your actual values:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key
API_BASE_URL=http://localhost:3000
```

**Getting Supabase Credentials:**
1. Go to [Supabase](https://supabase.com)
2. Create a new project or use existing one
3. Go to Settings > API
4. Copy the `URL` and `anon` public key

**API Base URL:**
- For local development, point to your Next.js backend: `http://localhost:3000`
- For production, use your deployed API URL

## Step 4: Run Code Generation

The project uses `freezed` and `json_serializable` for code generation:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates:
- `*.freezed.dart` files for immutable models
- `*.g.dart` files for JSON serialization

## Step 5: Database Setup

### 5.1 Apply Supabase Schema

Use the schema from your web app:

```bash
# Navigate to web app supabase folder
cd ../bonkilingua-web-app/bonkilingua-web-app/supabase

# Apply the schema to your Supabase project
# You can do this via Supabase dashboard > SQL Editor
# Or use Supabase CLI:
supabase db push
```

The schema includes:
- `profiles` table
- `chat_sessions` table
- `saved_lessons` table
- Row Level Security policies
- Automatic user profile creation trigger

## Step 6: Backend API Setup

Make sure your Next.js backend is running:

```bash
cd ../bonkilingua-web-app/bonkilingua-web-app
npm install
npm run dev
```

The Flutter app depends on these API endpoints:
- `POST /api/correct` - Text correction
- `POST /api/chat` - Generate lessons
- `POST /api/detect-language` - Language detection

## Step 7: Run the App

### For Android

```bash
flutter run
```

Or using Android Studio:
1. Open the project
2. Select an Android device/emulator
3. Press "Run" (green play button)

### For iOS (macOS only)

```bash
cd ios
pod install
cd ..
flutter run
```

Or using Xcode:
1. Open `ios/Runner.xcworkspace`
2. Select a simulator/device
3. Press "Run"

### For Web

```bash
flutter run -d chrome
```

## Step 8: Testing

Run tests to ensure everything is working:

```bash
# Unit tests
flutter test

# Integration tests (if device is connected)
flutter test integration_test/
```

## Common Issues & Solutions

### Issue: Build runner fails

**Solution:**
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: Supabase connection fails

**Solution:**
- Verify `.env` file exists and has correct values
- Check if Supabase project is active
- Ensure API keys are correct
- Check internet connection

### Issue: API calls fail

**Solution:**
- Ensure Next.js backend is running
- Check `API_BASE_URL` in `.env`
- For Android emulator, use `http://10.0.2.2:3000` instead of `localhost`
- For iOS simulator, use `http://localhost:3000`
- For physical devices, use your machine's IP address

### Issue: "No pubspec.yaml found"

**Solution:**
Make sure you're in the correct directory:
```bash
cd /Users/klev/Code/BONK-APP/bonkilingo_flutter
```

### Issue: Hive initialization fails

**Solution:**
The app automatically initializes Hive on startup. If issues persist:
```bash
flutter clean
flutter pub get
```

## Project Structure

```
lib/
├── core/              # Core functionality
│   ├── constants/     # App constants, languages
│   ├── theme/         # Colors, theme configuration
│   ├── utils/         # Extensions, validators
│   └── network/       # Dio client, exceptions
├── data/              # Data layer
│   ├── models/        # Data models (freezed)
│   ├── data_sources/  # API clients, local storage
│   ├── repositories/  # Repository implementations
│   └── services/      # Business services
├── presentation/      # UI layer
│   ├── screens/       # App screens
│   ├── widgets/       # Reusable widgets
│   └── providers/     # Riverpod providers
└── main.dart          # App entry point
```

## Development Workflow

### 1. Code Generation Watch Mode

For continuous code generation during development:

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 2. Hot Reload

While app is running:
- Press `r` in terminal for hot reload
- Press `R` for hot restart
- Press `q` to quit

### 3. Linting

Check code quality:

```bash
flutter analyze
```

### 4. Formatting

Format code:

```bash
flutter format lib/
```

## Building for Production

### Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS

```bash
flutter build ios --release
```

Then use Xcode to archive and upload to App Store.

## Environment Variables for Production

Update `.env` for production:

```env
SUPABASE_URL=https://your-production-project.supabase.co
SUPABASE_ANON_KEY=your_production_anon_key
API_BASE_URL=https://api.bonkilingo.com
```

## Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Supabase Flutter Documentation](https://supabase.com/docs/reference/dart)
- [Freezed Documentation](https://pub.dev/packages/freezed)

## Support

For issues or questions:
1. Check this setup guide
2. Review the main README.md
3. Check Flutter and Supabase documentation
4. Create an issue in the repository

## Next Steps

After successful setup:

1. **Customize Branding**: Update app icon and splash screen
2. **Configure Firebase** (optional): For analytics and crash reporting
3. **Setup CI/CD**: Automate builds and deployments
4. **Add Tests**: Write more unit and integration tests
5. **Performance Optimization**: Profile and optimize the app

Enjoy building with Bonkilingo Flutter! 🚀


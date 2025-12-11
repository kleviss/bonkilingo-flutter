# Bonkilingo Flutter

A language learning mobile application with AI-powered text correction and gamification features.

## Features

- **Text Correction**: AI-powered grammar and spelling correction using OpenAI
- **Language Learning**: Personalized lessons and vocabulary building
- **Gamification**: BONK points system with rewards and streaks
- **Multi-language Support**: English, Spanish, French, German, Italian, Portuguese
- **Offline Support**: Save lessons and history for offline access

## Architecture

This app follows Clean Architecture principles with three main layers:

```
lib/
├── core/           # Core functionality (theme, constants, utils)
├── data/           # Data sources, repositories implementation
├── domain/         # Business logic, entities, use cases
└── presentation/   # UI layer (screens, widgets, providers)
```

### State Management
- **Riverpod**: Type-safe, compile-time dependency injection and state management

### Backend
- **Supabase**: Authentication, database, and storage
- **OpenAI API**: Text correction and language learning features (via Next.js BFF)

### Local Storage
- **Hive**: Lightweight key-value storage for app data
- **Flutter Secure Storage**: Encrypted storage for sensitive data

## Setup

1. Install Flutter SDK (3.2.0 or higher)
2. Run `flutter pub get` to install dependencies
3. Create a `.env` file with required API keys:
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   API_BASE_URL=your_backend_api_url
   ```
4. Run `flutter pub run build_runner build` to generate code
5. Run `flutter run` to start the app

## Project Structure

- `/lib/core` - Core functionality, constants, theme
- `/lib/data` - Data models, repositories, API clients
- `/lib/domain` - Business entities, use cases
- `/lib/presentation` - UI screens, widgets, state providers
- `/test` - Unit and widget tests

## Development

### Code Generation
```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Testing
```bash
flutter test
```

### Build
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## License

Proprietary - All rights reserved


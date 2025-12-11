# Bonkilingo Flutter - Quick Start

Get up and running in 5 minutes! 🚀

## ⚡ Fast Setup

### 1. Prerequisites Check
```bash
# Check Flutter installation
flutter doctor

# You should see all green checkmarks for your target platform
```

### 2. Install Dependencies
```bash
cd /Users/klev/Code/BONK-APP/bonkilingo_flutter
flutter pub get
```

### 3. Generate Code
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Configure Environment

**Option A: Use Default (Development Mode)**

The app will work without `.env` but will use default values:
- API: `http://localhost:3000`
- Supabase: Will fail (need real credentials)

**Option B: Full Setup (Recommended)**

1. Copy example file:
```bash
cp .env.example .env
```

2. Edit `.env` with your Supabase credentials:
```env
SUPABASE_URL=your_url_here
SUPABASE_ANON_KEY=your_key_here
API_BASE_URL=http://localhost:3000
```

### 5. Start Backend (Next.js)
```bash
# In another terminal
cd ../bonkilingua-web-app/bonkilingua-web-app
npm install
npm run dev
```

### 6. Run the App
```bash
# Back to Flutter project
flutter run
```

That's it! The app should now be running on your device/emulator! 🎉

## 📱 Testing Without Full Setup

You can test the app without Supabase by using local storage only:

1. Skip authentication (tap "Continue as Guest" if implemented)
2. Use text correction (requires backend API)
3. All data will be stored locally in Hive

## 🎯 Quick Feature Tour

### Home Screen
1. Enter text in the input field
2. Select target language (or use auto-detect)
3. Tap "Correct Text"
4. View corrected text
5. Copy or get explanation

### Learn Screen
1. Tap "Create Lesson"
2. Describe a situation
3. Generate vocabulary and phrases
4. Save to your cheatsheet

### Rewards Screen
1. View your BONK points balance
2. See available rewards
3. Track your activity

### Authentication
1. Tap "Sign In" in app bar
2. Create account or log in
3. Access profile and sync data

## 🔧 Development Mode

### Hot Reload
While app is running:
- Type `r` - Hot reload
- Type `R` - Hot restart
- Type `q` - Quit

### Live Code Generation
For automatic rebuilds:
```bash
flutter pub run build_runner watch
```

### Check Issues
```bash
flutter analyze
```

## 🐛 Quick Troubleshooting

### App won't start?
```bash
flutter clean
flutter pub get
flutter run
```

### Code generation errors?
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Supabase errors?
- Check `.env` file exists
- Verify credentials are correct
- Ensure Supabase project is active

### API errors?
- Ensure Next.js backend is running
- Check `API_BASE_URL` in `.env`
- Android emulator: Use `http://10.0.2.2:3000`
- iOS simulator: Use `http://localhost:3000`

## 📚 Next Steps

1. ✅ **Read the docs**: Check `PROJECT_OVERVIEW.md` for architecture
2. ✅ **Full setup**: Follow `SETUP.md` for production setup
3. ✅ **Explore code**: Start with `lib/main.dart`
4. ✅ **Add features**: Use clean architecture patterns
5. ✅ **Write tests**: Add unit and widget tests

## 🎓 Understanding the Code

### Key Files to Start
1. `lib/main.dart` - App entry point
2. `lib/presentation/screens/main_navigation.dart` - Main navigation
3. `lib/presentation/screens/home/home_screen.dart` - Home screen
4. `lib/core/constants/` - App configuration

### Architecture Flow
```
Screen → Provider → Repository → API/Storage → Data
```

### Adding a New Feature
1. Create model in `data/models/`
2. Create API method in `data/data_sources/remote/`
3. Create repository in `data/repositories/`
4. Create provider in `presentation/providers/`
5. Create screen in `presentation/screens/`

## 💡 Pro Tips

1. **Use Flutter DevTools**: Great for debugging state
2. **Check provider state**: Use Riverpod's logging
3. **Hot reload often**: Faster than restarting
4. **Read the logs**: Dio logger shows all network calls
5. **Test on real device**: Better performance testing

## 🆘 Need Help?

- Check `SETUP.md` for detailed setup
- Check `PROJECT_OVERVIEW.md` for architecture
- Review Flutter docs: https://docs.flutter.dev/
- Review Riverpod docs: https://riverpod.dev/

---

**Happy Coding! 🚀**


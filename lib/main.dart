import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'data/data_sources/local/local_storage.dart';
import 'presentation/providers/providers.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/main_navigation.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Initialize local storage
  final localStorage = AppLocalStorage();
  await localStorage.init();

  // First launch shows onboarding. People who are already signed in (e.g.
  // updating from a version without onboarding) go straight to the app.
  final showOnboarding = !await OnboardingScreen.isComplete() &&
      Supabase.instance.client.auth.currentSession == null;

  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(localStorage),
      ],
      child: BonkilingoApp(showOnboarding: showOnboarding),
    ),
  );
}

class BonkilingoApp extends ConsumerWidget {
  final bool showOnboarding;

  const BonkilingoApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return CupertinoApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: themeMode == ThemeMode.dark 
          ? AppThemes.darkTheme 
          : AppThemes.lightTheme,
      home: showOnboarding ? const OnboardingScreen() : const MainNavigation(),
      localizationsDelegates: const [
        DefaultCupertinoLocalizations.delegate,
      ],
    );
  }
}


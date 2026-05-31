// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/app_info.dart';
import 'core/storage.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/lookup_provider.dart';
import 'providers/matching_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/projects_provider.dart';
import 'providers/settings_provider.dart';
import 'repositories/admin_repo.dart';
import 'repositories/auth_repo.dart';
import 'repositories/chat_repo.dart';
import 'repositories/feed_repo.dart';
import 'repositories/lookup_repo.dart';
import 'repositories/matching_repo.dart';
import 'repositories/notifications_repo.dart';
import 'repositories/project_repo.dart';
import 'repositories/settings_repo.dart';
import 'repositories/user_repo.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/verification_screen.dart';
import 'screens/common/splash_screen.dart';
import 'screens/onboarding/complete_profile_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/shell/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    AppInfo.version = (await PackageInfo.fromPlatform()).version;
  } catch (_) {
    // Keep the default version where it can't be read.
  }
  runApp(const TeamUpApp());
}

class TeamUpApp extends StatefulWidget {
  const TeamUpApp({super.key});

  @override
  State<TeamUpApp> createState() => _TeamUpAppState();
}

class _TeamUpAppState extends State<TeamUpApp> {
  late final TokenStorage _storage = TokenStorage();
  late final ApiClient _api = ApiClient(storage: _storage);
  late final AuthRepository _authRepo = AuthRepository(_api);
  late final AdminRepository _adminRepo = AdminRepository(_api);
  late final UserRepository _userRepo = UserRepository(_api);
  late final ProjectRepository _projectRepo = ProjectRepository(_api);
  late final LookupRepository _lookupRepo = LookupRepository(_api);
  late final MatchingRepository _matchingRepo = MatchingRepository(_api);
  late final ChatRepository _chatRepo = ChatRepository(_api);
  late final FeedRepository _feedRepo = FeedRepository(_api);
  late final NotificationsRepository _notificationsRepo = NotificationsRepository(_api);
  late final SettingsRepository _settingsRepo = SettingsRepository(_api);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: _api),
        Provider<UserRepository>.value(value: _userRepo),
        Provider<ProjectRepository>.value(value: _projectRepo),
        Provider<ChatRepository>.value(value: _chatRepo),
        Provider<FeedRepository>.value(value: _feedRepo),
        Provider<AdminRepository>.value(value: _adminRepo),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            repo: _authRepo,
            storage: _storage,
            api: _api,
          )..bootstrap(),
        ),
        ChangeNotifierProvider(create: (_) => ProjectsProvider(_projectRepo)),
        ChangeNotifierProvider(create: (_) => LookupProvider(_lookupRepo)),
        ChangeNotifierProvider(create: (_) => MatchingProvider(_matchingRepo)),
        ChangeNotifierProvider(create: (_) => ChatProvider(_chatRepo, _storage)),
        ChangeNotifierProvider(create: (_) => FeedProvider(_feedRepo)),
        ChangeNotifierProvider(create: (_) => NotificationsProvider(_notificationsRepo)),
        ChangeNotifierProvider(create: (_) => SettingsProvider(_settingsRepo)),
      ],
      child: const _Root(),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final authed =
        context.watch<AuthProvider>().status == AuthStatus.authenticated;
    final seed = settings.seedColor;
    // Only honor the user's dark-mode choice while authenticated; the login
    // screen always renders light.
    final mode = authed ? settings.themeMode : ThemeMode.light;
    return MaterialApp(
      title: 'TeamUp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(brightness: Brightness.light, seed: seed),
      darkTheme: AppTheme.build(brightness: Brightness.dark, seed: seed),
      themeMode: mode,
      locale: Locale(settings.language),
      supportedLocales: const [Locale('en'), Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: ClipRect(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child,
            ),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _minSplashElapsed = false;
  AuthStatus? _prevStatus;
  bool _transitioning = false;
  Timer? _transitionTimer;

  @override
  void initState() {
    super.initState();
    // Keep the animated splash visible for ~2s on every cold start.
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _minSplashElapsed = true);
    });
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    // Hold the splash until the minimum launch time has elapsed.
    if (!_minSplashElapsed) return const SplashScreen();

    // Show a brief loading screen when signing in or out (a smoother hand-off
    // than an instant cut between the login screen and the home shell).
    if (auth.status != AuthStatus.unknown &&
        _prevStatus != null &&
        auth.status != _prevStatus) {
      _transitioning = true;
      _transitionTimer?.cancel();
      _transitionTimer = Timer(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _transitioning = false);
      });
    }
    _prevStatus = auth.status;

    if (_transitioning) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    switch (auth.status) {
      case AuthStatus.unknown:
        return const SplashScreen();
      case AuthStatus.authenticated:
        // Unverified e-mail → block everything behind the verification screen.
        if (auth.user != null && !auth.user!.emailVerified) {
          return const VerificationScreen();
        }
        // Brand-new accounts are routed through profile completion first.
        if (auth.justRegistered) {
          return CompleteProfileScreen(
            onDone: () => context.read<AuthProvider>().clearJustRegistered(),
          );
        }
        return const AppShell();
      case AuthStatus.unauthenticated:
        // First launch ever shows the intro before the login screen.
        if (!auth.onboarded) {
          return OnboardingScreen(
            onDone: () => context.read<AuthProvider>().setOnboarded(),
          );
        }
        return const LoginScreen();
    }
  }
}

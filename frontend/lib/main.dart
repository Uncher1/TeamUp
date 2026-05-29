import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
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
import 'screens/shell/app_shell.dart';

void main() => runApp(const TeamUpApp());

class TeamUpApp extends StatefulWidget {
  const TeamUpApp({super.key});

  @override
  State<TeamUpApp> createState() => _TeamUpAppState();
}

class _TeamUpAppState extends State<TeamUpApp> {
  late final TokenStorage _storage = TokenStorage();
  late final ApiClient _api = ApiClient(storage: _storage);
  late final AuthRepository _authRepo = AuthRepository(_api);
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

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;
    switch (status) {
      case AuthStatus.unknown:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.authenticated:
        return const AppShell();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}

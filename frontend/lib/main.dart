import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/storage.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/lookup_provider.dart';
import 'providers/projects_provider.dart';
import 'repositories/auth_repo.dart';
import 'repositories/lookup_repo.dart';
import 'repositories/project_repo.dart';
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

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: _api),
        Provider<UserRepository>.value(value: _userRepo),
        Provider<ProjectRepository>.value(value: _projectRepo),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            repo: _authRepo,
            storage: _storage,
            api: _api,
          )..bootstrap(),
        ),
        ChangeNotifierProvider(create: (_) => ProjectsProvider(_projectRepo)),
        ChangeNotifierProvider(create: (_) => LookupProvider(_lookupRepo)),
      ],
      child: MaterialApp(
        title: 'TeamUp',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
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

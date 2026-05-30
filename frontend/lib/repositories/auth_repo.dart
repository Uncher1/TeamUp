import '../core/api_client.dart';
import '../models/user.dart';

class AuthResult {
  final String token;
  final User user;
  const AuthResult(this.token, this.user);
}

class AuthRepository {
  final ApiClient api;
  AuthRepository(this.api);

  Future<AuthResult> login(String email, String password) async {
    final res = await api.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return _parse(res.data as Map<String, dynamic>);
  }

  Future<AuthResult> register(
      String fullName, String email, String password) async {
    final res = await api.dio.post('/auth/register', data: {
      'full_name': fullName,
      'email': email,
      'password': password,
    });
    return _parse(res.data as Map<String, dynamic>);
  }

  /// Authenticates via Google, exchanging the GIS [idToken] for our JWT.
  Future<AuthResult> google(String idToken) async {
    final res = await api.dio.post('/auth/google', data: {'id_token': idToken});
    return _parse(res.data as Map<String, dynamic>);
  }

  /// Fetches the full profile of the authenticated user.
  Future<User> me() async {
    final res = await api.dio.get('/users/me');
    return User.fromJson(res.data as Map<String, dynamic>);
  }

  AuthResult _parse(Map<String, dynamic> data) => AuthResult(
        data['token'] as String,
        User.fromJson(data['user'] as Map<String, dynamic>),
      );
}

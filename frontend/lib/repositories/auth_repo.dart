import '../core/api_client.dart';
import '../models/user.dart';

class AuthResult {
  final String token;
  final User user;

  /// Only meaningful for Google sign-in: true when the account was just
  /// created (vs. an existing account that was logged into).
  final bool isNew;
  const AuthResult(this.token, this.user, {this.isNew = false});
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
      String fullName, String email, String password,
      {String language = 'en'}) async {
    final res = await api.dio.post('/auth/register', data: {
      'full_name': fullName,
      'email': email,
      'password': password,
      'language': language,
    });
    return _parse(res.data as Map<String, dynamic>);
  }

  /// Authenticates via Google, exchanging the GIS [idToken] for our JWT.
  Future<AuthResult> google(String idToken, {String language = 'en'}) async {
    final res = await api.dio
        .post('/auth/google', data: {'id_token': idToken, 'language': language});
    return _parse(res.data as Map<String, dynamic>);
  }

  /// Fetches the full profile of the authenticated user.
  Future<User> me() async {
    final res = await api.dio.get('/users/me');
    return User.fromJson(res.data as Map<String, dynamic>);
  }

  /// Confirms the e-mail verification code (XXXX-XXXX).
  Future<void> verifyEmail(String code) async {
    await api.dio.post('/auth/verify', data: {'code': code});
  }

  /// Requests a fresh verification code by e-mail.
  Future<void> resendCode() async {
    await api.dio.post('/auth/resend');
  }

  AuthResult _parse(Map<String, dynamic> data) => AuthResult(
        data['token'] as String,
        User.fromJson(data['user'] as Map<String, dynamic>),
        isNew: data['isNew'] == true,
      );
}

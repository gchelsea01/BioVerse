import '../core/network/api_client.dart';
import '../models/json.dart';
import '../models/user.dart';

class AuthService {
  AuthService(this._api);
  final ApiClient _api;

  Future<AuthResult> login(String email, String password) async {
    final data = await _api.post<Json>('/app/auth/login',
        auth: false, body: {'email': email.trim(), 'password': password, 'device_info': 'android'});
    return _store(data);
  }

  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    final data = await _api.post<Json>('/app/auth/register', auth: false, body: {
      'full_name': fullName.trim(),
      'email': email.trim(),
      'password': password,
      'timezone': 'Asia/Jakarta',
      'preferred_currency_code': 'IDR',
      if (referralCode != null && referralCode.isNotEmpty) 'referral_code': referralCode.trim(),
    });
    return _store(data);
  }

  Future<void> verifyEmail(String token) =>
      _api.post('/app/auth/verify-email', auth: false, body: {'token': token.trim()});

  Future<void> forgotPassword(String email) =>
      _api.post('/app/auth/forgot-password', auth: false, body: {'email': email.trim()});

  Future<void> resetPassword(String token, String newPassword) => _api.post('/app/auth/reset-password',
      auth: false, body: {'token': token.trim(), 'new_password': newPassword});

  Future<void> logout() async {
    final refresh = _api.tokens.refreshToken;
    try {
      if (refresh != null) await _api.post('/app/auth/logout', body: {'refresh_token': refresh});
    } finally {
      await _api.tokens.clear();
    }
  }

  Future<AuthResult> _store(Json data) async {
    final result = AuthResult.fromJson(data);
    await _api.tokens.save(access: result.accessToken, refresh: result.refreshToken);
    return result;
  }
}

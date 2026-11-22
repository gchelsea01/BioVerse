import 'json.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.gender,
    this.dateOfBirth,
    this.timezone = 'Asia/Jakarta',
    this.currency = 'IDR',
    this.avatarUrl,
    this.referralCode,
    this.points = 0,
    this.lockedPoints = 0,
    this.isEmailVerified = false,
    this.createdAt,
  });

  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? gender;
  final String? dateOfBirth;
  final String timezone;
  final String currency;
  final String? avatarUrl;
  final String? referralCode;
  final int points;
  final int lockedPoints;
  final bool isEmailVerified;
  final DateTime? createdAt;

  String get firstName => fullName.trim().split(' ').first;
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }

  UserProfile copyWith({int? points}) => UserProfile(
        id: id,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        gender: gender,
        dateOfBirth: dateOfBirth,
        timezone: timezone,
        currency: currency,
        avatarUrl: avatarUrl,
        referralCode: referralCode,
        points: points ?? this.points,
        lockedPoints: lockedPoints,
        isEmailVerified: isEmailVerified,
        createdAt: createdAt,
      );

  factory UserProfile.fromJson(Json j) => UserProfile(
        id: str(j, 'id'),
        email: str(j, 'email'),
        fullName: str(j, 'full_name', 'Guardian'),
        phoneNumber: strOrNull(j, 'phone_number'),
        gender: strOrNull(j, 'gender'),
        dateOfBirth: strOrNull(j, 'date_of_birth'),
        timezone: str(j, 'timezone', 'Asia/Jakarta'),
        currency: str(j, 'preferred_currency_code', 'IDR'),
        avatarUrl: strOrNull(j, 'avatar_url'),
        referralCode: strOrNull(j, 'referral_code'),
        points: integer(j, 'points_balance'),
        lockedPoints: integer(j, 'locked_points_balance'),
        isEmailVerified: boolean(j, 'is_email_verified'),
        createdAt: date(j, 'created_at'),
      );
}

class AuthResult {
  const AuthResult(this.accessToken, this.refreshToken, this.user);
  final String accessToken;
  final String refreshToken;
  final UserProfile? user;

  factory AuthResult.fromJson(Json j) => AuthResult(
        str(j, 'access_token'),
        str(j, 'refresh_token'),
        j['user'] is Map ? UserProfile.fromJson(Map<String, dynamic>.from(j['user'])) : null,
      );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Json j) => AppNotification(
        id: str(j, 'id'),
        title: str(j, 'title'),
        body: str(j, 'body'),
        type: str(j, 'notification_type'),
        isRead: boolean(j, 'is_read'),
        createdAt: date(j, 'created_at'),
      );
}

import 'dart:io';

import '../core/network/api_client.dart';
import '../models/json.dart';
import '../models/user.dart';

class UserService {
  UserService(this._api);
  final ApiClient _api;

  Future<UserProfile> me() async => UserProfile.fromJson(await _api.get<Json>('/app/users/me'));

  Future<UserStats> stats() async => UserStats.fromJson(await _api.get<Json>('/app/users/me/stats'));

  Future<UserProfile> update({
    String? fullName,
    String? phoneNumber,
    String? gender,
    String? dateOfBirth,
    String? currency,
    String? avatarObjectKey,
  }) async {
    final data = await _api.patch<Json>('/app/users/me', body: {
      if (fullName != null) 'full_name': fullName.trim(),
      if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone_number': phoneNumber.trim(),
      'gender': ?gender,
      'date_of_birth': ?dateOfBirth,
      'preferred_currency_code': ?currency,
      'avatar_object_key': ?avatarObjectKey,
    });
    return UserProfile.fromJson(data);
  }

  /// Accepts both the new `{items, next_cursor}` shape and the old plain list.
  Future<Paged<AppNotification>> notifications({String? cursor, int limit = 30}) async => Paged.from(
        await _api.get('/app/notifications', query: {'cursor': cursor, 'limit': limit}),
        AppNotification.fromJson,
      );

  Future<void> markRead(String id) => _api.patch('/app/notifications/$id/read');
  Future<void> markAllRead() => _api.post('/app/notifications/read-all');

  /// Presigned upload: ask the API for a URL, PUT the file there, return the
  /// object key the other endpoints expect. [purpose] is `avatar` or `mission_proof`.
  Future<String> upload(File file, {required String purpose}) async {
    final bytes = await file.readAsBytes();
    final name = file.path.split(Platform.pathSeparator).last;
    final ext = name.split('.').last.toLowerCase();
    final type = switch (ext) { 'png' => 'image/png', 'webp' => 'image/webp', _ => 'image/jpeg' };
    final presign = await _api.post<Json>('/app/uploads/presign', body: {
      'file_name': name,
      'content_type': type,
      'size_bytes': bytes.length,
      'purpose': purpose,
    });
    final headers = <String, String>{'Content-Type': type};
    final extra = presign['headers'];
    if (extra is Map) extra.forEach((k, v) => headers[k.toString()] = v.toString());
    await _api.putBytes(str(presign, 'upload_url'), bytes, headers);
    return str(presign, 'object_key');
  }
}

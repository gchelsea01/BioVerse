import '../core/network/api_client.dart';
import '../models/gamification.dart';
import '../models/json.dart';

/// Pets, eco-missions, streaks, leaderboard, shop, and inventory.
class GameService {
  GameService(this._api);
  final ApiClient _api;

  // Pets
  Future<List<VirtualPet>> pets() async => list(await _api.get('/app/pets'), VirtualPet.fromJson);

  Future<List<PetSpecies>> species() async => list(await _api.get('/app/pets/species'), PetSpecies.fromJson);

  /// [species] is a `species_id` from [species()]; [displayName] goes to the
  /// backend's required `coral_type` field.
  Future<VirtualPet> createPet({required String name, required String species, required String displayName}) async =>
      VirtualPet.fromJson(await _api.post<Json>('/app/pets',
          body: {'pet_name': name.trim(), 'pet_species': species, 'coral_type': displayName}));

  /// [type] is `feed`, `clean`, or `pet`. The API returns the updated pet.
  Future<VirtualPet> interact(VirtualPet pet, String type) async {
    final j = await _api.post<Json>('/app/pets/${pet.id}/interact', body: {'interaction_type': type});
    if (j['id'] != null) return VirtualPet.fromJson(j);
    return pet.copyWith(
      health: integer(j, 'health_percent', pet.health),
      xp: integer(j, 'experience_points', pet.xp),
      level: integer(j, 'level', pet.level),
    );
  }

  Future<VirtualPet> equip(String petId, String productId) async =>
      VirtualPet.fromJson(await _api.post<Json>('/app/pets/$petId/equip', body: {'product_id': productId}));

  // Missions

  /// Missions with today's progress. The API's `completed_today` /
  /// `my_last_submission_status` are currently always empty (backend scan
  /// bug, see docs/BACKEND_NOTES.md), so they are filled in from the user's
  /// own submissions when missing.
  Future<Paged<EcoMission>> missions({String? cursor}) async {
    final results = await Future.wait<Object?>([
      _api.get('/app/missions', query: {'cursor': cursor, 'limit': 30}),
      mySubmissions().then<Object?>((v) => v).catchError((_) => null),
    ]);
    final page = Paged.from(results[0], EcoMission.fromJson);
    final subs = results[1] as List<MissionSubmission>?;
    if (subs == null) return page;

    final today = DateTime.now();
    bool isToday(DateTime? d) => d != null && d.year == today.year && d.month == today.month && d.day == today.day;
    final latest = <String, MissionSubmission>{};
    for (final s in subs) {
      final id = s.missionId;
      if (id == null) continue;
      final prev = latest[id];
      if (prev == null || (s.createdAt?.isAfter(prev.createdAt ?? DateTime(0)) ?? false)) latest[id] = s;
    }
    return Paged(
      [
        for (final m in page.items)
          if (m.completedToday || m.lastStatus != null || latest[m.id] == null)
            m
          else
            m.withProgress(
              completedToday: isToday(latest[m.id]!.createdAt) && latest[m.id]!.status != 'rejected',
              lastStatus: latest[m.id]!.status,
            ),
      ],
      page.nextCursor,
    );
  }

  Future<List<MissionSubmission>> mySubmissions() async =>
      Paged.from(await _api.get('/app/mission-submissions/my', query: {'limit': 50}), MissionSubmission.fromJson).items;

  Future<MissionSubmission> submitMission(String missionId, String proofKey, {String? petId}) async =>
      MissionSubmission.fromJson(await _api.post<Json>('/app/missions/$missionId/submit',
          body: {'proof_object_key': proofKey, 'pet_id': ?petId}));

  Future<MissionSubmission> submission(String id) async =>
      MissionSubmission.fromJson(await _api.get<Json>('/app/mission-submissions/$id'));

  // Streaks & leaderboard
  Future<Streak> streak() async => Streak.fromJson(await _api.get<Json>('/app/streaks'));

  Future<void> useStreakFreeze() => _api.post('/app/inventory/streak-freeze/use');

  Future<List<LeaderboardEntry>> leaderboard({String period = 'all_time', String? category}) async => Paged.from(
        await _api.get('/app/leaderboard', query: {'period': period, 'category': category, 'limit': 50}),
        LeaderboardEntry.fromJson,
        key: 'rankings',
      ).items;

  // Shop & inventory
  Future<List<ShopProduct>> products() async =>
      list(await _api.get('/app/catalog/products', auth: false), ShopProduct.fromJson);

  /// Buys with points; returns the remaining points balance.
  Future<int> buy(String productId) async {
    final j = await _api.post<Json>('/app/shop/buy',
        headers: {'Idempotency-Key': ApiClient.idempotencyKey()}, body: {'product_id': productId});
    return integer(j, 'remaining_points_balance');
  }

  Future<List<InventoryItem>> inventory() async => list(await _api.get('/app/inventory'), InventoryItem.fromJson);
}

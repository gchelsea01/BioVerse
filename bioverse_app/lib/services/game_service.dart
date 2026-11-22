import '../core/network/api_client.dart';
import '../models/gamification.dart';
import '../models/json.dart';

/// Pets, eco-missions, streaks, leaderboard, shop, and inventory.
class GameService {
  GameService(this._api);
  final ApiClient _api;

  // Pets
  Future<List<VirtualPet>> pets() async => list(await _api.get('/app/pets'), VirtualPet.fromJson);

  Future<VirtualPet> createPet({required String name, required String species, required String coralType}) async =>
      VirtualPet.fromJson(await _api.post<Json>('/app/pets',
          body: {'pet_name': name.trim(), 'pet_species': species, 'coral_type': coralType}));

  /// [type] is `feed`, `clean`, or `pet`.
  Future<VirtualPet> interact(VirtualPet pet, String type) async {
    final j = await _api.post<Json>('/app/pets/${pet.id}/interact', body: {'interaction_type': type});
    return pet.copyWith(
      health: integer(j, 'health_percent', pet.health),
      xp: integer(j, 'experience_points', pet.xp),
      level: integer(j, 'level', pet.level),
    );
  }

  Future<VirtualPet> equip(String petId, String productId) async =>
      VirtualPet.fromJson(await _api.post<Json>('/app/pets/$petId/equip', body: {'product_id': productId}));

  // Missions
  Future<Paged<EcoMission>> missions({String? cursor}) async =>
      Paged.from(await _api.get('/app/missions', query: {'cursor': cursor, 'limit': 30}), EcoMission.fromJson);

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

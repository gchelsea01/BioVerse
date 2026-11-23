import 'conservation.dart';
import 'donation.dart';
import 'json.dart';

enum GrowthStage {
  hatchling('Hatchling'),
  juvenile('Juvenile'),
  adult('Adult'),
  elder('Elder');

  const GrowthStage(this.label);
  final String label;

  static GrowthStage parse(String? v) =>
      GrowthStage.values.firstWhere((s) => s.name == v, orElse: () => GrowthStage.hatchling);

  GrowthStage? get next => index < GrowthStage.values.length - 1 ? GrowthStage.values[index + 1] : null;
}

class VirtualPet {
  const VirtualPet({
    required this.id,
    required this.name,
    required this.species,
    required this.coralType,
    required this.stage,
    required this.level,
    required this.xp,
    required this.health,
    required this.isPrimary,
    this.equippedProductId,
    int? xpToNextLevel,
  }) : _xpToNext = xpToNextLevel;

  final String id;
  final String name;
  final String species;
  final String coralType;
  final GrowthStage stage;
  final int level;
  final int xp;
  final int health;
  final bool isPrimary;
  final String? equippedProductId;
  final int? _xpToNext;

  /// Mirrors the backend curve: level = 1 + floor(sqrt(xp / 100)), so level L
  /// starts at 100·(L-1)² XP.
  static int xpForLevel(int level) => 100 * (level - 1) * (level - 1);

  int get xpToNextLevel => _xpToNext ?? (xpForLevel(level + 1) - xp).clamp(0, 1 << 30);

  double get levelProgress {
    final start = xpForLevel(level);
    final span = xpForLevel(level + 1) - start;
    return span <= 0 ? 0 : ((span - xpToNextLevel) / span).clamp(0, 1).toDouble();
  }

  /// Which habitat/art to show for this pet's species.
  Ecosystem get ecosystem => PetSpecies.ecosystemFor(species);

  String get mood => health >= 70 ? 'Happy' : (health >= 40 ? 'Okay' : 'Needs care');

  VirtualPet copyWith({int? health, int? xp, int? level}) => VirtualPet(
        id: id,
        name: name,
        species: species,
        coralType: coralType,
        stage: stage,
        level: level ?? this.level,
        xp: xp ?? this.xp,
        health: health ?? this.health,
        isPrimary: isPrimary,
        equippedProductId: equippedProductId,
      );

  factory VirtualPet.fromJson(Json j) => VirtualPet(
        id: str(j, 'id'),
        name: str(j, 'pet_name', 'Buddy'),
        species: str(j, 'pet_species', 'coral'),
        coralType: str(j, 'coral_type'),
        stage: GrowthStage.parse(strOrNull(j, 'growth_stage')),
        level: integer(j, 'level', 1),
        xp: integer(j, 'experience_points'),
        health: integer(j, 'health_percent', 100),
        isPrimary: boolean(j, 'is_primary'),
        equippedProductId: strOrNull(j, 'equipped_product_id'),
        xpToNextLevel: intOrNull(j, 'xp_to_next_level'),
      );
}

/// Companion species from `/pets/species`.
class PetSpecies {
  const PetSpecies({
    required this.id,
    required this.name,
    required this.description,
    required this.element,
    required this.rarity,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String description;
  final String element;
  final String rarity;
  final String? imageUrl;

  Ecosystem get ecosystem => ecosystemFor(id, element);

  static const _marine = {'ocean', 'reef', 'pelagic', 'seagrass', 'coral'};
  static const _coast = {'mangrove', 'coast', 'coastal'};
  static const _ids = {
    'crab': Ecosystem.mangrove,
    'hornbill': Ecosystem.tree,
    'deer': Ecosystem.tree,
    'orangutan': Ecosystem.tree,
    'sun_bear': Ecosystem.tree,
  };

  /// Maps a species id (or its element) to one of the three ecosystems.
  static Ecosystem ecosystemFor(String speciesId, [String? element]) {
    for (final e in Ecosystem.values) {
      if (e.api == speciesId) return e;
    }
    final known = _ids[speciesId];
    if (known != null) return known;
    if (element != null) {
      if (_marine.contains(element)) return Ecosystem.coral;
      if (_coast.contains(element)) return Ecosystem.mangrove;
      return Ecosystem.tree;
    }
    return Ecosystem.coral;
  }

  factory PetSpecies.fromJson(Json j) => PetSpecies(
        id: str(j, 'species_id'),
        name: str(j, 'name'),
        description: str(j, 'description'),
        element: str(j, 'element'),
        rarity: str(j, 'rarity', 'common'),
        imageUrl: strOrNull(j, 'avatar_asset_url'),
      );
}

class EcoMission {
  const EcoMission({
    required this.id,
    required this.title,
    required this.description,
    required this.instructions,
    required this.points,
    required this.xp,
    this.category,
    this.difficulty,
    this.imageUrl,
    this.estimatedMinutes,
    this.completedToday = false,
    this.lastStatus,
  });

  final int? estimatedMinutes;
  final bool completedToday;
  final String? lastStatus;

  EcoMission withProgress({required bool completedToday, String? lastStatus}) => EcoMission(
        id: id,
        title: title,
        description: description,
        instructions: instructions,
        points: points,
        xp: xp,
        category: category,
        difficulty: difficulty,
        imageUrl: imageUrl,
        estimatedMinutes: estimatedMinutes,
        completedToday: completedToday,
        lastStatus: lastStatus,
      );

  final String id;
  final String title;
  final String description;
  final String instructions;
  final int points;
  final int xp;
  final String? category;
  final String? difficulty;

  /// Returned by the API although not in the OpenAPI spec yet.
  final String? imageUrl;

  /// Instructions arrive as one block; split numbered/new lines into steps.
  List<String> get steps => instructions
      .split(RegExp(r'\n|(?=\d+\.\s)'))
      .map((s) => s.replaceFirst(RegExp(r'^\s*\d+\.\s*'), '').trim())
      .where((s) => s.isNotEmpty)
      .toList();

  factory EcoMission.fromJson(Json j) => EcoMission(
        id: str(j, 'id'),
        title: str(j, 'title'),
        description: str(j, 'description'),
        instructions: str(j, 'instructions'),
        points: integer(j, 'points_reward'),
        xp: integer(j, 'xp_reward'),
        category: strOrNull(j, 'category'),
        difficulty: strOrNull(j, 'difficulty'),
        imageUrl: strOrNull(j, 'image_url'),
        estimatedMinutes: intOrNull(j, 'estimated_minutes'),
        completedToday: boolean(j, 'completed_today'),
        lastStatus: strOrNull(j, 'my_last_submission_status'),
      );
}

class MissionSubmission {
  const MissionSubmission({
    required this.id,
    required this.status,
    this.missionId,
    this.missionTitle,
    this.message,
    this.awardedPoints,
    this.awardedXp,
    this.createdAt,
  });

  final String id;
  final String status;
  final String? missionId;
  final String? missionTitle;
  final String? message;
  final int? awardedPoints;
  final int? awardedXp;
  final DateTime? createdAt;

  bool get isFinal => status == 'verified' || status == 'rejected' || status == 'needs_review';

  factory MissionSubmission.fromJson(Json j) => MissionSubmission(
        id: str(j, 'id', str(j, 'submission_id')),
        status: str(j, 'status', 'pending'),
        missionId: strOrNull(j, 'mission_id'),
        missionTitle: strOrNull(j, 'mission_title'),
        message: strOrNull(j, 'message'),
        awardedPoints: intOrNull(j, 'awarded_points'),
        awardedXp: intOrNull(j, 'awarded_xp'),
        createdAt: date(j, 'created_at'),
      );
}

class Streak {
  const Streak({this.current = 0, this.longest = 0, this.lastActivity, this.freezeActive = false, this.freezeCount = 0});
  final int current;
  final int longest;
  final DateTime? lastActivity;
  final bool freezeActive;
  final int freezeCount;

  bool get activeToday {
    final d = lastActivity;
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  factory Streak.fromJson(Json j) => Streak(
        current: integer(j, 'current_streak'),
        longest: integer(j, 'longest_streak'),
        lastActivity: date(j, 'last_activity_date'),
        freezeActive: boolean(j, 'is_freeze_active'),
        freezeCount: integer(j, 'freeze_count'),
      );
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.totalUsd,
    required this.units,
    this.avatarUrl,
    this.isAnonymous = false,
  });

  final int rank;
  final String name;
  final double totalUsd;
  final int units;
  final String? avatarUrl;
  final bool isAnonymous;

  factory LeaderboardEntry.fromJson(Json j) => LeaderboardEntry(
        rank: integer(j, 'rank'),
        name: boolean(j, 'is_anonymous') ? 'Anonymous Guardian' : str(j, 'display_name', 'Guardian'),
        totalUsd: number(j, 'total_donations_usd'),
        units: integer(j, 'total_units_adopted'),
        avatarUrl: strOrNull(j, 'avatar_url'),
        isAnonymous: boolean(j, 'is_anonymous'),
      );
}

class ShopProduct {
  const ShopProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.itemType,
    required this.pricePoints,
    required this.prices,
    this.previewUrl,
  });

  final String id;
  final String name;
  final String description;
  final String itemType;
  final int pricePoints;
  final List<CurrencyPrice> prices;
  final String? previewUrl;

  factory ShopProduct.fromJson(Json j) => ShopProduct(
        id: str(j, 'id'),
        name: str(j, 'name'),
        description: str(j, 'description'),
        itemType: str(j, 'item_type'),
        pricePoints: integer(j, 'price_points'),
        prices: list(j['prices'], CurrencyPrice.fromJson),
        previewUrl: strOrNull(j, 'preview_asset_url'),
      );
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.itemType,
    required this.quantity,
  });

  final String id;
  final String productId;
  final String name;
  final String itemType;
  final int quantity;

  bool get isEquippable => itemType == 'pet_skin' || itemType == 'pet_accessory' || itemType == 'habitat_background';

  factory InventoryItem.fromJson(Json j) => InventoryItem(
        id: str(j, 'id'),
        productId: str(j, 'product_id'),
        name: str(j, 'name'),
        itemType: str(j, 'item_type'),
        quantity: integer(j, 'quantity', 1),
      );
}

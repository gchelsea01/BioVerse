import 'json.dart';

/// The three ecosystems BioVerse restores (Ridge-to-Reef).
enum Ecosystem {
  coral('coral', 'Coral', 'coral fragment'),
  mangrove('mangrove', 'Mangrove', 'mangrove seedling'),
  tree('tree', 'Tree', 'tree');

  const Ecosystem(this.api, this.label, this.unitName);
  final String api;
  final String label;
  final String unitName;

  static Ecosystem parse(String? v) =>
      Ecosystem.values.firstWhere((e) => e.api == v, orElse: () => Ecosystem.coral);

  String get donationType => switch (this) {
        Ecosystem.coral => 'coral_adoption',
        Ecosystem.mangrove => 'mangrove_planting',
        Ecosystem.tree => 'tree_planting',
      };

  static Ecosystem? fromDonationType(String type) => switch (type) {
        'coral_adoption' => Ecosystem.coral,
        'mangrove_planting' => Ecosystem.mangrove,
        'tree_planting' => Ecosystem.tree,
        _ => null,
      };
}

class Project {
  const Project({
    required this.id,
    required this.title,
    required this.description,
    required this.objectives,
    required this.ecosystem,
    required this.speciesName,
    required this.status,
    required this.healthStatus,
    required this.currency,
    required this.pricePerUnit,
    required this.pricePerUnitPoints,
    required this.targetUnits,
    required this.fundedUnits,
    required this.plantedUnits,
    required this.imageUrl,
    required this.isUrgent,
    this.survivingUnits,
    this.startDate,
    this.endDate,
    this.plantingDate,
    this.locationName,
    this.latitude,
    this.longitude,
    this.contributors = 0,
  });

  final String? locationName;
  final double? latitude;
  final double? longitude;
  final int contributors;

  final String id;
  final String title;
  final String description;
  final String objectives;
  final Ecosystem ecosystem;
  final String speciesName;
  final String status;
  final String healthStatus;
  final String currency;
  final double pricePerUnit;
  final int pricePerUnitPoints;
  final int targetUnits;
  final int fundedUnits;
  final int plantedUnits;
  final int? survivingUnits;
  final String imageUrl;
  final bool isUrgent;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? plantingDate;

  double get progress => targetUnits == 0 ? 0 : (fundedUnits / targetUnits).clamp(0, 1).toDouble();
  bool get isOpen => status == 'open_for_donation';
  int get remainingUnits => (targetUnits - fundedUnits).clamp(0, targetUnits);

  factory Project.fromJson(Json j) => Project(
        id: str(j, 'id'),
        title: str(j, 'title'),
        description: str(j, 'description'),
        objectives: str(j, 'objectives'),
        ecosystem: Ecosystem.parse(strOrNull(j, 'category')),
        speciesName: str(j, 'species_or_type_name'),
        status: str(j, 'status'),
        healthStatus: str(j, 'physical_health_status', 'healthy'),
        currency: str(j, 'currency_code', 'USD'),
        pricePerUnit: number(j, 'price_per_unit_money'),
        pricePerUnitPoints: integer(j, 'price_per_unit_points'),
        targetUnits: integer(j, 'target_units'),
        fundedUnits: integer(j, 'funded_units_count'),
        plantedUnits: integer(j, 'planted_units_count'),
        survivingUnits: intOrNull(j, 'surviving_units_count'),
        imageUrl: str(j, 'image_url'),
        isUrgent: boolean(j, 'is_urgent'),
        startDate: date(j, 'donation_start_date'),
        endDate: date(j, 'donation_end_date'),
        plantingDate: date(j, 'estimated_planting_date'),
        locationName: strOrNull(j, 'location_name'),
        latitude: j['latitude'] == null ? null : number(j, 'latitude'),
        longitude: j['longitude'] == null ? null : number(j, 'longitude'),
        contributors: integer(j, 'contributors_count'),
      );
}

/// Something the user adopted: a coral fragment, mangrove seedlings, or trees.
/// From `/conservation/units/my` (all ecosystems) or the older
/// `/conservation/corals/my` (corals only).
class AdoptedUnit {
  const AdoptedUnit({
    required this.id,
    required this.code,
    required this.ecosystem,
    required this.projectId,
    required this.projectName,
    required this.speciesName,
    required this.lifecycleStatus,
    required this.healthStatus,
    this.quantity = 1,
    this.nickname,
    this.locationName,
    this.plantedAt,
    this.frameTag,
    this.latestPhotoUrl,
    this.createdAt,
    this.milestones = const [],
  });

  final String id;
  final String code;
  final Ecosystem ecosystem;
  final int quantity;
  final String? nickname;
  final String projectId;
  final String projectName;
  final String speciesName;
  final String? locationName;
  final String lifecycleStatus;
  final String healthStatus;
  final DateTime? plantedAt;
  final String? frameTag;
  final String? latestPhotoUrl;
  final DateTime? createdAt;

  /// Embedded reports, sorted by month. May include future-dated entries;
  /// use [MilestoneUpdate.isReceived] to tell real reports from expected ones.
  final List<MilestoneUpdate> milestones;

  String get title => nickname ?? projectName;

  factory AdoptedUnit.fromJson(Json j) => AdoptedUnit(
        id: str(j, 'id'),
        code: str(j, 'unit_code', str(j, 'fragment_code')),
        ecosystem: Ecosystem.parse(strOrNull(j, 'category') ?? 'coral'),
        quantity: integer(j, 'quantity', 1),
        nickname: strOrNull(j, 'nickname'),
        projectId: str(j, 'project_id'),
        projectName: str(j, 'project_name'),
        speciesName: str(j, 'species_name'),
        locationName: strOrNull(j, 'location_name'),
        lifecycleStatus: str(j, 'lifecycle_status'),
        healthStatus: str(j, 'health_status', 'healthy'),
        plantedAt: date(j, 'planted_at'),
        frameTag: strOrNull(j, 'spider_frame_tag'),
        latestPhotoUrl: strOrNull(j, 'latest_photo_url'),
        createdAt: date(j, 'created_at'),
        milestones: list(j['milestones'], MilestoneUpdate.fromJson)..sort((a, b) => a.month.compareTo(b.month)),
      );
}

/// Periodic field report: month 1, 3 or 6 after planting.
class MilestoneUpdate {
  const MilestoneUpdate({
    required this.month,
    required this.photoUrl,
    required this.healthStatus,
    this.growthCm,
    this.title,
    this.notes,
    this.verifiedAt,
  });

  final int month;
  final String photoUrl;
  final String healthStatus;
  final double? growthCm;
  final String? title;
  final String? notes;
  final DateTime? verifiedAt;

  /// A report dated in the future is a placeholder, not a real field photo.
  bool get isReceived => verifiedAt != null && !verifiedAt!.isAfter(DateTime.now());

  factory MilestoneUpdate.fromJson(Json j) => MilestoneUpdate(
        month: integer(j, 'milestone_month'),
        photoUrl: str(j, 'photo_url', str(j, 'media_url')),
        healthStatus: str(j, 'health_status', 'healthy'),
        growthCm: j['growth_cm'] == null ? null : number(j, 'growth_cm'),
        title: strOrNull(j, 'milestone_title'),
        notes: strOrNull(j, 'notes') ?? strOrNull(j, 'subtitle_metrics'),
        verifiedAt: date(j, 'verified_at') ?? date(j, 'captured_at'),
      );
}

class ImpactSummary {
  const ImpactSummary({this.corals = 0, this.trees = 0, this.guardians = 0, this.biomassKg = 0});
  final int corals;
  final int trees;
  final int guardians;
  final double biomassKg;

  factory ImpactSummary.fromJson(Json j) => ImpactSummary(
        corals: integer(j, 'total_corals_adopted'),
        trees: integer(j, 'total_trees_planted'),
        guardians: integer(j, 'active_guardians_count'),
        biomassKg: number(j, 'total_biomass_restored_kg'),
      );
}

class NewsArticle {
  const NewsArticle({
    required this.id,
    required this.title,
    required this.ecosystem,
    required this.summary,
    required this.content,
    required this.thumbnailUrl,
    this.publishedAt,
  });

  final String id;
  final String title;
  final Ecosystem ecosystem;
  final String summary;
  final String content;
  final String thumbnailUrl;
  final DateTime? publishedAt;

  factory NewsArticle.fromJson(Json j) => NewsArticle(
        id: str(j, 'id'),
        title: str(j, 'title'),
        ecosystem: Ecosystem.parse(strOrNull(j, 'category')),
        summary: str(j, 'summary'),
        content: str(j, 'content'),
        thumbnailUrl: str(j, 'thumbnail_url'),
        publishedAt: date(j, 'published_at'),
      );
}

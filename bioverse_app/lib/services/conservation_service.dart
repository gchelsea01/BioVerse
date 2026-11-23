import '../core/network/api_client.dart';
import '../models/conservation.dart';
import '../models/json.dart';

class ConservationService {
  ConservationService(this._api);
  final ApiClient _api;

  Future<Paged<Project>> projects({Ecosystem? ecosystem, String? status, String? cursor, int limit = 20}) async =>
      Paged.from(
        await _api.get('/app/conservation/projects', query: {
          'category': ecosystem?.api,
          'status': status,
          'cursor': cursor,
          'limit': limit,
        }),
        Project.fromJson,
      );

  Future<Project> project(String id) async =>
      Project.fromJson(await _api.get<Json>('/app/conservation/projects/$id'));

  /// Everything the user adopted across coral, mangrove, and tree projects,
  /// with growth reports embedded.
  Future<Paged<AdoptedUnit>> myUnits({String? cursor}) async => Paged.from(
        await _api.get('/app/conservation/units/my', query: {'cursor': cursor, 'limit': 50}),
        AdoptedUnit.fromJson,
      );

  /// Coral-only timeline; used when a unit has no embedded reports.
  Future<List<MilestoneUpdate>> timeline(String coralId) async {
    final items = list(await _api.get('/app/conservation/corals/$coralId/timeline'), MilestoneUpdate.fromJson);
    return items..sort((a, b) => a.month.compareTo(b.month));
  }

  Future<ImpactSummary> impact() async =>
      ImpactSummary.fromJson(await _api.get<Json>('/app/impact/summary', auth: false));

  Future<Paged<NewsArticle>> news({Ecosystem? ecosystem, String? cursor}) async => Paged.from(
        await _api.get('/app/news', auth: false, query: {'category': ecosystem?.api, 'cursor': cursor, 'limit': 20}),
        NewsArticle.fromJson,
      );
}

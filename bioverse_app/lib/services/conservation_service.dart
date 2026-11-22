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

  Future<Paged<AdoptedUnit>> myCorals({String? cursor}) async => Paged.from(
        await _api.get('/app/conservation/corals/my', query: {'cursor': cursor, 'limit': 50}),
        AdoptedUnit.fromJson,
      );

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

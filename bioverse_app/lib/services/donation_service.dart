import '../core/network/api_client.dart';
import '../models/conservation.dart';
import '../models/donation.dart';
import '../models/json.dart';

/// How the user pays at checkout. Values map to backend `PaymentMethodType`.
enum PayMethod {
  qris('qris', 'QRIS'),
  virtualAccount('virtual_account', 'Virtual Account'),
  ewallet('ewallet', 'E-Wallet'),
  points('points_only', 'BioVerse Points');

  const PayMethod(this.api, this.label);
  final String api;
  final String label;
}

class DonationService {
  DonationService(this._api);
  final ApiClient _api;

  Future<Donation> checkout({
    required Project project,
    required int quantity,
    required PayMethod method,
    String? bankCode,
    String? nickname,
    String? petId,
    bool anonymous = false,
  }) async {
    final points = method == PayMethod.points ? project.pricePerUnitPoints * quantity : 0;
    final data = await _api.post<Json>(
      '/app/donations/checkout',
      headers: {'Idempotency-Key': ApiClient.idempotencyKey()},
      body: {
        'donation_type': project.ecosystem.donationType,
        'project_id': project.id,
        'quantity': quantity,
        'payment_method_type': method.api,
        if (method == PayMethod.virtualAccount) 'bank_code': bankCode ?? 'BCA',
        if (nickname != null && nickname.isNotEmpty) 'coral_nickname': nickname,
        'target_pet_id': ?petId,
        'points_to_burn': points,
        'is_anonymous': anonymous,
      },
    );
    return Donation.fromJson(data);
  }

  Future<Donation> detail(String id) async => Donation.fromJson(await _api.get<Json>('/app/donations/$id'));

  Future<Page<Donation>> history({String? status, String? type, String? cursor}) async => Page.from(
        await _api.get('/app/donations/history', query: {
          'payment_status': status,
          'donation_type': type,
          'cursor': cursor,
          'limit': 30,
        }),
        Donation.fromJson,
      );

  Future<List<SubscriptionPlan>> plans() async =>
      list(await _api.get('/app/catalog/plans', auth: false), SubscriptionPlan.fromJson);

  Future<Subscription> subscribe({
    required String planId,
    required String projectId,
    required int quantity,
    required PayMethod method,
  }) async {
    final data = await _api.post<Json>(
      '/app/subscriptions',
      headers: {'Idempotency-Key': ApiClient.idempotencyKey()},
      body: {'plan_id': planId, 'project_id': projectId, 'unit_quantity': quantity, 'payment_method_type': method.api},
    );
    return Subscription.fromJson(data);
  }

  Future<List<Subscription>> mySubscriptions() async =>
      list(await _api.get('/app/subscriptions/my'), Subscription.fromJson);

  Future<void> pause(String id) => _api.post('/app/subscriptions/$id/pause');
  Future<void> resume(String id) => _api.post('/app/subscriptions/$id/resume');
  Future<void> cancel(String id) => _api.post('/app/subscriptions/$id/cancel');
}

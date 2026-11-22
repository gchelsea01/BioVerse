import 'json.dart';

class PaymentDetails {
  const PaymentDetails({this.paymentUrl, this.qrString, this.vaNumber, this.bankCode});
  final String? paymentUrl;
  final String? qrString;
  final String? vaNumber;
  final String? bankCode;

  static PaymentDetails? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final j = Map<String, dynamic>.from(raw);
    return PaymentDetails(
      paymentUrl: strOrNull(j, 'payment_url'),
      qrString: strOrNull(j, 'qr_code_string'),
      vaNumber: strOrNull(j, 'va_number'),
      bankCode: strOrNull(j, 'bank_code'),
    );
  }
}

/// Used for both checkout responses and history items.
class Donation {
  const Donation({
    required this.id,
    required this.type,
    required this.status,
    required this.grossAmount,
    required this.netAmount,
    required this.currency,
    required this.settlementAmount,
    required this.settlementCurrency,
    required this.pointsBurned,
    required this.paymentMethod,
    this.isAnonymous = false,
    this.payment,
    this.paidAt,
    this.expiredAt,
    this.createdAt,
  });

  final String id;
  final String type;
  final String status;
  final double grossAmount;
  final double netAmount;
  final String currency;
  final double settlementAmount;
  final String settlementCurrency;
  final int pointsBurned;
  final String paymentMethod;
  final bool isAnonymous;
  final PaymentDetails? payment;
  final DateTime? paidAt;
  final DateTime? expiredAt;
  final DateTime? createdAt;

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';

  String get typeLabel => switch (type) {
        'coral_adoption' => 'Coral adoption',
        'tree_planting' => 'Tree / mangrove planting',
        'bio_shield_addon' => 'Bio-Shield add-on',
        'maintenance' => 'Monthly maintenance',
        _ => 'General support',
      };

  factory Donation.fromJson(Json j) => Donation(
        id: str(j, 'id', str(j, 'donation_id')),
        type: str(j, 'donation_type'),
        status: str(j, 'status', 'pending'),
        grossAmount: number(j, 'gross_amount'),
        netAmount: number(j, 'net_payable_amount'),
        currency: str(j, 'currency_code', 'USD'),
        settlementAmount: number(j, 'settlement_amount'),
        settlementCurrency: str(j, 'settlement_currency_code', 'IDR'),
        pointsBurned: integer(j, 'points_burned'),
        paymentMethod: str(j, 'payment_method_type'),
        isAnonymous: boolean(j, 'is_anonymous'),
        payment: PaymentDetails.fromJson(j['payment_details']),
        paidAt: date(j, 'paid_at'),
        expiredAt: date(j, 'expired_at'),
        createdAt: date(j, 'created_at'),
      );
}

class CurrencyPrice {
  const CurrencyPrice(this.currency, this.amount);
  final String currency;
  final double amount;
  factory CurrencyPrice.fromJson(Json j) => CurrencyPrice(str(j, 'currency_code'), number(j, 'amount'));
}

/// Picks the price in [currency], falling back to the first one listed.
CurrencyPrice? priceIn(List<CurrencyPrice> prices, String currency) {
  if (prices.isEmpty) return null;
  return prices.firstWhere((p) => p.currency == currency, orElse: () => prices.first);
}

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.interval,
    required this.prices,
    required this.benefits,
  });

  final String id;
  final String name;
  final String interval;
  final List<CurrencyPrice> prices;
  final List<String> benefits;

  factory SubscriptionPlan.fromJson(Json j) => SubscriptionPlan(
        id: str(j, 'id'),
        name: str(j, 'name'),
        interval: str(j, 'billing_interval', 'monthly'),
        prices: list(j['prices'], CurrencyPrice.fromJson),
        benefits: (j['benefits'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
}

class Subscription {
  const Subscription({
    required this.id,
    required this.status,
    required this.planName,
    required this.interval,
    this.authorizationUrl,
    this.nextBillingDate,
    this.createdAt,
  });

  final String id;
  final String status;
  final String planName;
  final String interval;
  final String? authorizationUrl;
  final DateTime? nextBillingDate;
  final DateTime? createdAt;

  factory Subscription.fromJson(Json j) => Subscription(
        id: str(j, 'id'),
        status: str(j, 'status'),
        planName: str(j, 'plan_name'),
        interval: str(j, 'billing_interval', 'monthly'),
        authorizationUrl: strOrNull(j, 'authorization_url'),
        nextBillingDate: date(j, 'next_billing_date'),
        createdAt: date(j, 'created_at'),
      );
}

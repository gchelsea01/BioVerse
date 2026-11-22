/// Lenient readers so a missing or null field never crashes a screen.
typedef Json = Map<String, dynamic>;

String str(Json j, String k, [String fallback = '']) => j[k]?.toString() ?? fallback;
String? strOrNull(Json j, String k) {
  final v = j[k]?.toString();
  return (v == null || v.isEmpty) ? null : v;
}

int integer(Json j, String k, [int fallback = 0]) {
  final v = j[k];
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

int? intOrNull(Json j, String k) => j[k] == null ? null : integer(j, k);

/// Money comes from the API as decimal strings ("3.20").
double number(Json j, String k, [double fallback = 0]) {
  final v = j[k];
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? fallback;
}

bool boolean(Json j, String k, [bool fallback = false]) {
  final v = j[k];
  if (v is bool) return v;
  if (v is String) return v == 'true';
  return fallback;
}

DateTime? date(Json j, String k) => DateTime.tryParse(j[k]?.toString() ?? '')?.toLocal();

List<T> list<T>(Object? raw, T Function(Json) parse) =>
    raw is List ? raw.whereType<Map>().map((e) => parse(Map<String, dynamic>.from(e))).toList() : <T>[];

/// Cursor-paginated responses: `{items: [...], next_cursor: "..."}`.
class Paged<T> {
  const Paged(this.items, this.nextCursor);
  final List<T> items;
  final String? nextCursor;

  factory Paged.from(Object? raw, T Function(Json) parse, {String key = 'items'}) {
    if (raw is List) return Paged(list(raw, parse), null);
    final j = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    return Paged(list(j[key], parse), strOrNull(j, 'next_cursor'));
  }
}

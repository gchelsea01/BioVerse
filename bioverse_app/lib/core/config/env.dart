/// Build-time configuration. Override with
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/v1`.
class Env {
  Env._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.ourprojects.my.id/v1',
  );
}

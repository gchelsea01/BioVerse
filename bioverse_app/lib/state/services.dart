import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../services/auth_service.dart';
import '../services/conservation_service.dart';
import '../services/donation_service.dart';
import '../services/game_service.dart';
import '../services/user_service.dart';

/// Single place that wires services to one shared [ApiClient].
class Services {
  Services._(this.api)
      : auth = AuthService(api),
        user = UserService(api),
        conservation = ConservationService(api),
        donations = DonationService(api),
        game = GameService(api);

  factory Services.create() => Services._(ApiClient(TokenStorage()));

  final ApiClient api;
  final AuthService auth;
  final UserService user;
  final ConservationService conservation;
  final DonationService donations;
  final GameService game;
}

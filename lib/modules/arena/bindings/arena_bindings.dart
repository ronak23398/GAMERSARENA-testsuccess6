
import 'package:gamers_gram/data/services/arena_firebase_service.dart';
import 'package:gamers_gram/modules/arena/controllers/arena_controller.dart';
import 'package:gamers_gram/modules/auth/controllers/auth_controller.dart';
import 'package:gamers_gram/modules/wallet/controllers/wallet_controller.dart';
import 'package:get/get.dart';

class ArenaBindings extends Bindings {
  @override
  void dependencies() {
    // Register Firebase Service as a singleton
    Get.lazyPut<TournamentFirebaseService>(() => TournamentFirebaseService(),
        fenix: true);

    // Register Tournament Controller as a singleton
    Get.lazyPut<ArenaController>(() => ArenaController(), fenix: true);
    Get.put(WalletController(), permanent: true);

    Get.put(AuthController(), permanent: true);
  }
}

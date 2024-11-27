import 'package:gamers_gram/data/services/auth_service.dart';
import 'package:gamers_gram/data/services/user_service.dart';
import 'package:gamers_gram/modules/profile/controllers/profile_controller.dart';
import 'package:gamers_gram/modules/wallet/controllers/wallet_controller.dart';
import 'package:get/get.dart';

class ProfileBindings extends Bindings {
  @override
  void dependencies() {
    // Singleton services
    Get.lazyPut<AuthService>(() => AuthService(), fenix: true);
    Get.lazyPut<UserService>(() => UserService(), fenix: true);

    // Profile controller
    Get.lazyPut<ProfileController>(() => ProfileController());

    Get.lazyPut<WalletController>(() => WalletController());
  }
}

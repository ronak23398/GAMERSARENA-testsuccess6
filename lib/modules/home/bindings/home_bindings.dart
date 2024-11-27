import 'package:gamers_gram/modules/challenges/controllers/1v1_challenege_controller.dart';
import 'package:gamers_gram/modules/challenges/controllers/scrim_controller.dart';
import 'package:gamers_gram/modules/home/controllers/home_controller.dart';
import 'package:gamers_gram/modules/wallet/controllers/wallet_controller.dart';
import 'package:get/get.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Main controllers
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<WalletController>(() => WalletController());
    Get.lazyPut<ChallengeController>(
      () => ChallengeController(),
      fenix: true,
    );
    Get.lazyPut<ScrimController>(
      () => ScrimController(),
      fenix: true,
    );
  }
}

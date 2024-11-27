import 'package:gamers_gram/modules/wallet/controllers/wallet_controller.dart';
import 'package:get/get.dart';

class WalletBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WalletController>(() => WalletController());
  }
}

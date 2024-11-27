import 'package:gamers_gram/modules/marketplace/controllers/market_controller.dart';
import 'package:get/get.dart';

class MarketBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MarketController>(() => MarketController());
  }
}

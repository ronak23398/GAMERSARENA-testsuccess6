import 'package:gamers_gram/modules/challenges/controllers/1v1_challenege_controller.dart';
import 'package:get/get.dart';

class ChallengeBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChallengeController>(
      () => ChallengeController(),
      fenix: true, // Keeps the controller alive throughout the app lifecycle
    );
  }
}

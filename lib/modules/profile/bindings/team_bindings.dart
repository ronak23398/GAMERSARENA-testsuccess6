import 'package:gamers_gram/data/services/auth_service.dart';
import 'package:gamers_gram/modules/profile/controllers/team_controller.dart';
import 'package:get/get.dart';

class TeamBindings extends Bindings {
  @override
  void dependencies() {
    // Ensure AuthService is available
    Get.lazyPut<AuthService>(() => AuthService(), fenix: true);

    // Create TeamController with dependencies
    Get.lazyPut<TeamController>(() => TeamController(), fenix: true);
  }
}

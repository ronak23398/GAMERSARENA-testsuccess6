import 'package:gamers_gram/data/repository/user_repository.dart';
import 'package:gamers_gram/data/services/auth_service.dart';
import 'package:gamers_gram/modules/auth/controllers/auth_controller.dart';
import 'package:get/get.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize core services
    Get.put(AuthService(), permanent: true);
    Get.put(UserRepository(), permanent: true);

    // Initialize controllers
    Get.lazyPut<AuthController>(
      () => AuthController(),
    );
  }
}

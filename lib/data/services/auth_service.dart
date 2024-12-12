import 'package:firebase_auth/firebase_auth.dart';
import 'package:gamers_gram/data/models/user_model.dart';
import 'package:get/get.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Rx<User?> currentUser = Rx<User?>(null);

  @override
  void onInit() {
    currentUser.bindStream(_auth.authStateChanges());
    super.onInit();
  }

  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> getCurrentUserModel(dynamic userService) async {
    final userId = getCurrentUserId();
    if (userId != null) {
      // Fetch user from database or create UserModel
      // This depends on how you store user data
      return await userService.getUserById(userId);
    }
    return null;
  }

  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  Future<UserCredential?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

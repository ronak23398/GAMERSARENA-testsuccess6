import 'package:gamers_gram/data/repository/user_repository.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/user_model.dart';
import '../../../core/utils/loading_state.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final UserRepository _userRepository = Get.find<UserRepository>();

  final RxBool isLoading = false.obs;
  final Rx<LoadingState> loadingState = LoadingState.initial.obs;
  final RxString errorMessage = ''.obs;

  // User state
  final Rx<User?> user = Rx<User?>(null);
  final Rx<UserModel?> userModel = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes
    ever(_authService.currentUser, _handleAuthChanged);
    user.bindStream(_authService.currentUser.stream);
  }

  void _handleAuthChanged(User? user) async {
    if (user != null) {
      try {
        // Get user data from database
        final userData = await _userRepository.getUser(user.uid);
        if (userData != null) {
          userModel.value = userData;
          Get.offAllNamed('/mainpage');
        } else {
          // If user data doesn't exist, sign out
          await signOut();
          errorMessage.value = 'User data not found';
        }
      } catch (e) {
        errorMessage.value = 'Failed to load user data';
      }
    } else {
      userModel.value = null;
      if (Get.currentRoute != '/login' && Get.currentRoute != '/signup') {
        Get.offAllNamed('/login');
      }
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      errorMessage.value = '';
      loadingState.value = LoadingState.loading;

      await _authService.signInWithEmailAndPassword(email, password);

      loadingState.value = LoadingState.success;
    } catch (e) {
      loadingState.value = LoadingState.error;
      errorMessage.value = _getErrorMessage(e);
    }
  }

  Future<void> signUp(
    String email,
    String password,
    String username, {
    String? valorantTeam,
    String? cs2Team,
    String? bgmiTeam,
  }) async {
    try {
      errorMessage.value = '';
      loadingState.value = LoadingState.loading;

      // Create auth user
      final userCredential = await _authService.signUpWithEmailAndPassword(
        email,
        password,
      );

      if (userCredential?.user != null) {
        // Create user in database
        final newUser = UserModel(
          uid: userCredential!.user!.uid,
          email: email,
          username: username,
          walletBalance: 0,
          challenges: [],
          tournaments: [],
          // Add optional team names
          valorantTeam: valorantTeam,
          cs2Team: cs2Team,
          bgmiTeam: bgmiTeam,
        );

        await _userRepository.createUser(newUser);
        loadingState.value = LoadingState.success;
      }
    } catch (e) {
      loadingState.value = LoadingState.error;
      errorMessage.value = _getErrorMessage(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      userModel.value = null;
    } catch (e) {
      errorMessage.value = _getErrorMessage(e);
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'Email is already in use.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'operation-not-allowed':
          return 'Operation not allowed.';
        case 'user-disabled':
          return 'This user has been disabled.';
        default:
          return 'Authentication failed. Please try again.';
      }
    }
    return 'An error occurred. Please try again.';
  }
}

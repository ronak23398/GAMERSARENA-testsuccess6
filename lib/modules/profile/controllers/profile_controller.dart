import 'package:flutter/material.dart';
import 'package:gamers_gram/data/models/user_model.dart';
import 'package:gamers_gram/data/services/auth_service.dart';
import 'package:gamers_gram/data/services/user_service.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final UserService _userService = Get.find<UserService>();

  // Observables for different profile sections
  Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  RxBool isLoading = false.obs;
  RxList<dynamic> challenges = RxList<dynamic>();
  RxList<dynamic> tournaments = RxList<dynamic>();
  RxDouble walletBalance = 0.0.obs;

  // Form controllers for editing
  final teamFormKey = GlobalKey<FormState>();
  final valorantTeamController = TextEditingController();
  final cs2TeamController = TextEditingController();
  final bgmiTeamController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchCurrentUserProfile();
  }

  Future<void> fetchCurrentUserProfile() async {
    try {
      isLoading.value = true;
      String? uid = _authService.getCurrentUserId();

      if (uid != null) {
        UserModel? user = await _userService.getUserById(uid);
        if (user != null) {
          currentUser.value = user;
          challenges.value = user.challenges;
          tournaments.value = user.tournaments;
          walletBalance.value = user.walletBalance;
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not load profile');
    } finally {
      isLoading.value = false;
    }
  }

  // Comprehensive team update method
  Future<void> updateTeams() async {
    if (!teamFormKey.currentState!.validate()) return;

    try {
      Map<String, dynamic> updates = {
        'valorantTeam': valorantTeamController.text.trim(),
        'cs2Team': cs2TeamController.text.trim(),
        'bgmiTeam': bgmiTeamController.text.trim(),
      };

      String? uid = _authService.getCurrentUserId();
      if (uid != null) {
        await _userService.updateUserFields(uid, updates);
        await fetchCurrentUserProfile();
        Get.back(); // Close bottom sheet
        Get.snackbar('Success', 'Teams updated successfully');
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not update teams');
    }
  }



  // Logout method
  Future<void> logout() async {
    await _authService.signOut();
    Get.offAllNamed('/login');
  }

  @override
  void onClose() {
    // Dispose controllers
    valorantTeamController.dispose();
    cs2TeamController.dispose();
    bgmiTeamController.dispose();
    super.onClose();
  }
}

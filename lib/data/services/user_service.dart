import 'package:firebase_database/firebase_database.dart';
import 'package:gamers_gram/data/models/user_model.dart';
import 'package:get/get.dart';

class UserService extends GetxService {
  final DatabaseReference _userRef =
      FirebaseDatabase.instance.ref().child('users');

  // Create or update user in database
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await _userRef.child(user.uid).set(user.toMap());
    } catch (e) {
      Get.snackbar('Error', 'Failed to update user profile');
      print('User update error: $e');
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      DatabaseEvent event = await _userRef.child(uid).once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value != null) {
        return UserModel.fromMap(
            Map<String, dynamic>.from(snapshot.value as Map));
      }
      return null;
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  // Update specific fields
  Future<void> updateUserFields(
      String uid, Map<String, dynamic> updates) async {
    try {
      await _userRef.child(uid).update(updates);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile');
      print('Partial update error: $e');
    }
  }

  // Add challenge to user
  Future<void> addChallenge(String uid, dynamic challenge) async {
    try {
      await _userRef.child(uid).child('challenges').push().set(challenge);
    } catch (e) {
      Get.snackbar('Error', 'Could not add challenge');
    }
  }

  // Add tournament to user
  Future<void> addTournament(String uid, dynamic tournament) async {
    try {
      await _userRef.child(uid).child('tournaments').push().set(tournament);
    } catch (e) {
      Get.snackbar('Error', 'Could not add tournament');
    }
  }
}

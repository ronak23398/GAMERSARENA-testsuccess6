import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class UserRepository {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Create a new user in the database
  Future<void> createUser(UserModel user) async {
    try {
      // Store user data under their unique UID in 'users' node
      await _database.child('users').child(user.uid).set(user.toMap());
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  // Retrieve user data by UID
  Future<UserModel?> getUser(String uid) async {
    try {
      // Fetch user data from Realtime Database
      final snapshot = await _database.child('users').child(uid).get();

      if (snapshot.exists) {
        // Convert the snapshot value to a map and create UserModel
        return UserModel.fromMap(
            Map<String, dynamic>.from(snapshot.value as Map));
      }
      return null;
    } catch (e) {
      print('Error fetching user: $e');
      rethrow;
    }
  }

  // Update user profile including team names
  Future<void> updateUser(UserModel user) async {
    try {
      await _database.child('users').child(user.uid).update(user.toMap());
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // Update specific team name
  Future<void> updateTeamName({
    required String uid,
    String? valorantTeam,
    String? cs2Team,
    String? bgmiTeam,
  }) async {
    try {
      // Prepare update map with only the provided team names
      final updateMap = <String, dynamic>{};

      if (valorantTeam != null) {
        updateMap['valorantTeam'] = valorantTeam;
      }
      if (cs2Team != null) {
        updateMap['cs2Team'] = cs2Team;
      }
      if (bgmiTeam != null) {
        updateMap['bgmiTeam'] = bgmiTeam;
      }

      // Update only the provided team names
      await _database.child('users').child(uid).update(updateMap);
    } catch (e) {
      print('Error updating team name: $e');
      rethrow;
    }
  }
}

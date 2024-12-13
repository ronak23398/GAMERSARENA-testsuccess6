import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gamers_gram/data/models/team_model.dart';
import 'package:gamers_gram/data/models/user_model.dart';
import 'package:gamers_gram/data/services/auth_service.dart';
import 'package:get/get.dart';

class TeamController extends GetxController {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  Rx<TeamModel?> currentTeam = Rx<TeamModel?>(null);
  Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  RxList<TeamModel> userTeams = RxList<TeamModel>([]);

  final AuthService _authService = Get.find<AuthService>();

  // Fetch user's teams
  Future<void> fetchUserTeams() async {
    try {
      String? currentUserUid = _authService.getCurrentUserId();
      print('[DEBUG] Fetching user teams for user ID: $currentUserUid');

      if (currentUserUid == null) {
        print('[ERROR] No current user found');
        Get.snackbar('Error', 'User not authenticated');
        return;
      }

      // Fetch user data to get teamIds
      DatabaseEvent userEvent =
          await _database.ref('users/$currentUserUid').once();

      // Ensure userData is not null and is a Map
      if (userEvent.snapshot.value == null) {
        print('[ERROR] User data is null');
        return;
      }

      Map<String, dynamic> userData =
          Map<String, dynamic>.from(userEvent.snapshot.value as Map);
      print('[DEBUG] User data retrieved: $userData');

      // Ensure teamIds is a list
      List<dynamic> teamIds = List.from(userData['teamIds'] ?? []);
      print('[DEBUG] Team IDs found: $teamIds');

      userTeams.clear();

      // Fetch teams based on teamIds
      for (String teamId in teamIds) {
        print('[DEBUG] Fetching details for team ID: $teamId');
        DatabaseEvent teamEvent = await _database.ref('teams/$teamId').once();

        if (teamEvent.snapshot.value != null) {
          Map<String, dynamic> teamData =
              Map<String, dynamic>.from(teamEvent.snapshot.value as Map);

          print('[DEBUG] Team Data for $teamId: $teamData');

          TeamModel team = TeamModel.fromJson(teamData, teamId);
          userTeams.add(team);
          print('[DEBUG] Team added: ${team.name}');
        } else {
          print('[WARNING] No data found for team ID: $teamId');
        }
      }

      // Handle current team logic
      String? currentTeamId = userData['currentTeamId'];
      print('[DEBUG] Current team ID from user data: $currentTeamId');

      if (currentTeamId != null) {
        try {
          currentTeam.value = userTeams.firstWhere(
            (team) => team.teamId == currentTeamId,
            orElse: () => userTeams.isNotEmpty
                ? userTeams.first
                : TeamModel(
                    name: '',
                    tag: '',
                    username: '',
                    owner: '',
                    members: {}), // Use a default TeamModel instead of null
          );
          print('[DEBUG] Current team set to: ${currentTeam.value?.name}');
        } catch (e) {
          print('[ERROR] Could not find current team: $e');
          currentTeam.value = userTeams.isNotEmpty ? userTeams.first : null;
        }
      } else if (userTeams.isNotEmpty) {
        currentTeam.value = userTeams.first;
        print(
            '[DEBUG] No current team, setting to first team: ${currentTeam.value?.name}');
      }
    } catch (e) {
      print('[ERROR] Comprehensive Error in fetchUserTeams: $e');
      Get.snackbar('Error', 'Failed to fetch teams: $e');
    }
  }

  // Set current team for user
  Future<void> setCurrentTeam(TeamModel team) async {
    try {
      String? currentUserUid = _authService.getCurrentUserId();
      print('[DEBUG] Setting current team for user ID: $currentUserUid');

      if (currentUserUid == null) {
        print('[ERROR] No current user found when setting team');
        return;
      }

      if (team.teamId == null) {
        print('[ERROR] Team ID is null');
        return;
      }

      // Update user's profile with current team ID
      await _database
          .ref('users/$currentUserUid/currentTeamId')
          .set(team.teamId);
      print('[DEBUG] Updated user profile with team ID: ${team.teamId}');

      // Set current team in controller
      currentTeam.value = team;
      print('[DEBUG] Current team set to: ${team.name}');
    } catch (e) {
      print('[ERROR] Error setting current team: $e');
      Get.snackbar('Error', 'Failed to set current team');
    }
  }

  @override
  void onInit() {
    super.onInit();
    print('[DEBUG] TeamController initialized');
    _listenToTeamInvitations();
    fetchUserTeams();
  }

  // Create a new team
  Future<void> createTeam({
    required String name,
    required String tag,
    required BuildContext context,
    required String ownerUid,
  }) async {
    try {
      // Dismiss keyboard
      FocusScope.of(context).unfocus();

      // Get current user ID and username
      String? currentUserUid = _authService.getCurrentUserId();
      print('[DEBUG] Creating team. Current user ID: $currentUserUid');

      if (currentUserUid == null) {
        _showErrorMessage(context, 'No authenticated user found');
        return;
      }

      // Fetch current user's username
      DatabaseEvent userEvent =
          await _database.ref('users/$currentUserUid').once();
      Map<dynamic, dynamic> userData =
          userEvent.snapshot.value as Map<dynamic, dynamic>;
      String currentUsername = userData['username'] ?? 'Unknown';

      // Validate inputs
      if (name.trim().isEmpty || tag.trim().isEmpty) {
        _showErrorMessage(context, 'Team name and tag cannot be empty');
        return;
      }

      // Generate a new team ID
      DatabaseReference teamRef = _database.ref().child('teams').push();
      String? newTeamId = teamRef.key;
      print('[DEBUG] Generated new team ID: $newTeamId');

      if (newTeamId == null) {
        _showErrorMessage(context, 'Failed to generate team ID');
        return;
      }

      // Create team model
      TeamModel newTeam = TeamModel(
        teamId: newTeamId,
        name: name,
        tag: tag,
        owner: currentUserUid,
        username: currentUsername,
        members: {
          currentUserUid: {
            'role': 'owner',
            'username': currentUsername,
            'joinedAt': ServerValue.timestamp,
          }
        },
      );

      // Save team to database
      await teamRef.set(newTeam.toJson());
      print('[DEBUG] New team saved to database: ${newTeam.name}');

      // Update user's team information
      DatabaseReference userRef = _database.ref('users/$currentUserUid');
      DatabaseEvent userDataEvent = await userRef.once();
      Map<dynamic, dynamic> existingUserData =
          userDataEvent.snapshot.value as Map<dynamic, dynamic>;

      List<dynamic> teamIds = List.from(existingUserData['teamIds'] ?? []);
      if (!teamIds.contains(newTeamId)) {
        teamIds.add(newTeamId);
      }

      await userRef.update({'teamIds': teamIds, 'currentTeamId': newTeamId});
      await userRef.update({
        'valorantTeam': name,
      });

      // Update local state
      currentTeam.value = newTeam;
      userTeams.add(newTeam);

      // Show success message
      Get.snackbar('Success', 'Team created successfully');
    } catch (e) {
      print('[ERROR] Team Creation Error: $e');
      _showErrorMessage(context, 'Failed to create team: ${e.toString()}');
    }
  }

  // Helper method to show error messages
  void _showErrorMessage(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Invite a user to team
  Future<void> inviteUserToTeam({
    required String username,
    required String teamId,
  }) async {
    try {
      print('[DEBUG] Attempting to invite user: $username to team: $teamId');

      // Find user by username
      DatabaseEvent event = await _database
          .ref('users')
          .orderByChild('username')
          .equalTo(username)
          .once();

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> users =
            event.snapshot.value as Map<dynamic, dynamic>;
        String userUid = users.keys.first;
        print('[DEBUG] Found user ID for $username: $userUid');

        // Fetch inviting user's username
        String? currentUserUid = _authService.getCurrentUserId();
        String invitingUsername = 'Unknown';
        if (currentUserUid != null) {
          DatabaseEvent inviterEvent =
              await _database.ref('users/$currentUserUid').once();
          Map<dynamic, dynamic> inviterData =
              inviterEvent.snapshot.value as Map<dynamic, dynamic>;
          invitingUsername = inviterData['username'] ?? 'Unknown';
        }

        // Add invitation to team
        DatabaseReference invitationRef =
            _database.ref('teams/$teamId/invitations/$userUid');

        await invitationRef.set({
          'status': 'pending',
          'invitedAt': ServerValue.timestamp,
          'invitedBy': currentUserUid,
          'invitedByUsername': invitingUsername,
        });
        print('[DEBUG] Invitation sent to $username');

        Get.snackbar('Success', 'Invitation sent to $username');
      } else {
        print('[ERROR] User not found: $username');
        Get.snackbar('Error', 'User not found');
      }
    } catch (e) {
      print('[ERROR] Failed to invite user: $e');
      Get.snackbar('Error', 'Failed to invite user: ${e.toString()}');
    }
  }

  // Accept team invitation
  Future<void> acceptTeamInvitation(String teamId) async {
    try {
      String? currentUserUid = _authService.getCurrentUserId();
      if (currentUserUid == null) return;

      // Fetch current user's username
      DatabaseEvent userEvent =
          await _database.ref('users/$currentUserUid').once();
      Map<dynamic, dynamic> userData =
          userEvent.snapshot.value as Map<dynamic, dynamic>;
      String currentUsername = userData['username'] ?? 'Unknown';

      // Update team members
      await _database.ref('teams/$teamId/members/$currentUserUid').set({
        'role': 'member',
        'username': currentUsername,
        'joinedAt': ServerValue.timestamp
      });

      // Remove invitation
      await _database.ref('teams/$teamId/invitations/$currentUserUid').remove();

      // Update user's team information
      DatabaseReference userRef = _database.ref('users/$currentUserUid');
      DatabaseEvent userDataEvent = await userRef.once();
      Map<dynamic, dynamic> existingUserData =
          userDataEvent.snapshot.value as Map<dynamic, dynamic>;

      List<dynamic> teamIds = List.from(existingUserData['teamIds'] ?? []);
      if (!teamIds.contains(teamId)) {
        teamIds.add(teamId);
      }

      // Update user's current team and team list
      await userRef.update({'teamIds': teamIds, 'currentTeamId': teamId});

      Get.snackbar('Success', 'Team invitation accepted');

      // Refresh teams
      await fetchUserTeams();
    } catch (e) {
      Get.snackbar('Error', 'Failed to accept invitation: ${e.toString()}');
    }
  }

  // Listen to team invitations
  void _listenToTeamInvitations() {
    String? currentUserUid = _authService.getCurrentUserId();
    if (currentUserUid == null) return;

    _database.ref('teams').onValue.listen((event) {
      List<TeamInvitation> invitations = [];

      Map<dynamic, dynamic>? teamsData =
          event.snapshot.value as Map<dynamic, dynamic>?;

      if (teamsData != null) {
        teamsData.forEach((teamId, teamData) {
          Map<dynamic, dynamic>? teamInvitations = teamData['invitations'];

          if (teamInvitations != null &&
              teamInvitations.containsKey(currentUserUid)) {
            var invitationData = teamInvitations[currentUserUid];

            if (invitationData['status'] == 'pending') {
              invitations.add(TeamInvitation(
                teamId: teamId,
                teamName: teamData['name'],
                invitedBy: invitationData['invitedByUsername'] ?? 'Unknown',
                invitedAt: DateTime.fromMillisecondsSinceEpoch(
                    invitationData['invitedAt']),
              ));
            }
          }
        });
      }

      pendingInvitations.value = invitations;
    });
  }

  // Decline team invitation
  Future<void> declineTeamInvitation(String teamId) async {
    try {
      String? currentUserUid = _authService.getCurrentUserId();
      if (currentUserUid == null) return;

      // Remove invitation
      await _database.ref('teams/$teamId/invitations/$currentUserUid').remove();

      Get.snackbar('Invitation', 'Team invitation declined');
    } catch (e) {
      Get.snackbar('Error', 'Failed to decline invitation: ${e.toString()}');
    }
  }

  // Leave the current team
  Future<void> leaveTeam() async {
    try {
      String? currentUserUid = _authService.getCurrentUserId();
      if (currentUserUid == null) {
        Get.snackbar('Error', 'No authenticated user found');
        return;
      }

      if (currentTeam.value == null) {
        Get.snackbar('Error', 'No current team selected');
        return;
      }

      // Check if user is the owner
      if (currentTeam.value!.owner == currentUserUid) {
        Get.snackbar('Error',
            'Team owner must promote another member to admin before leaving');
        return;
      }

      // Remove user from team members
      await _database
          .ref('teams/${currentTeam.value!.teamId}/members/$currentUserUid')
          .remove();

      // Remove team from user's team list
      DatabaseReference userRef = _database.ref('users/$currentUserUid');
      DatabaseEvent userDataEvent = await userRef.once();
      Map<dynamic, dynamic> existingUserData =
          userDataEvent.snapshot.value as Map<dynamic, dynamic>;

      List<dynamic> teamIds = List.from(existingUserData['teamIds'] ?? []);
      teamIds.remove(currentTeam.value!.teamId);

      // Update user's team information
      await userRef.update({
        'teamIds': teamIds,
        'currentTeamId': teamIds.isNotEmpty ? teamIds.first : null
      });

      // Refresh teams
      await fetchUserTeams();

      Get.snackbar('Success', 'You have left the team');
    } catch (e) {
      print('[ERROR] Leave team error: $e');
      Get.snackbar('Error', 'Failed to leave team: ${e.toString()}');
    }
  }

// Promote a member to admin
  // In TeamController class
// Promote a member to admin
  Future<void> promoteMemberToAdmin(String memberUid) async {
    try {
      String? currentUserUid = _authService.getCurrentUserId();
      if (currentUserUid == null) {
        Get.snackbar('Error', 'No authenticated user found');
        return;
      }

      if (currentTeam.value == null) {
        Get.snackbar('Error', 'No current team selected');
        return;
      }

      // Verify that only the owner can promote
      if (currentTeam.value!.owner != currentUserUid) {
        Get.snackbar('Error', 'Only team owner can promote members');
        return;
      }

      // Update member's role to admin
      await _database
          .ref('teams/${currentTeam.value!.teamId}/members/$memberUid/role')
          .set('admin');

      Get.snackbar('Success', 'Member promoted to admin');
    } catch (e) {
      print('[ERROR] Promote member error: $e');
      Get.snackbar('Error', 'Failed to promote member: ${e.toString()}');
    }
  }

// Remove a member from the team
  Future<void> removeMemberFromTeam(String memberUid) async {
    try {
      String? currentUserUid = _authService.getCurrentUserId();
      if (currentUserUid == null) {
        Get.snackbar('Error', 'No authenticated user found');
        return;
      }

      if (currentTeam.value == null) {
        Get.snackbar('Error', 'No current team selected');
        return;
      }

      // Verify that only the owner can remove members
      if (currentTeam.value!.owner != currentUserUid) {
        Get.snackbar('Error', 'Only team owner can remove members');
        return;
      }

      // Remove user from team members
      await _database
          .ref('teams/${currentTeam.value!.teamId}/members/$memberUid')
          .remove();

      // Remove team from user's team list
      DatabaseReference userRef = _database.ref('users/$memberUid');
      DatabaseEvent userDataEvent = await userRef.once();
      Map<dynamic, dynamic> existingUserData =
          userDataEvent.snapshot.value as Map<dynamic, dynamic>;

      List<dynamic> teamIds = List.from(existingUserData['teamIds'] ?? []);
      teamIds.remove(currentTeam.value!.teamId);

      // Update user's team information
      await userRef.update({
        'teamIds': teamIds,
        'currentTeamId': teamIds.isNotEmpty ? teamIds.first : null
      });

      Get.snackbar('Success', 'Member removed from the team');
    } catch (e) {
      print('[ERROR] Remove member error: $e');
      Get.snackbar('Error', 'Failed to remove member: ${e.toString()}');
    }
  }

  Rx<List<TeamInvitation>> pendingInvitations = Rx<List<TeamInvitation>>([]);
}

class TeamInvitation {
  final String teamId;
  final String teamName;
  final String invitedBy;
  final DateTime invitedAt;

  TeamInvitation({
    required this.teamId,
    required this.teamName,
    required this.invitedBy,
    required this.invitedAt,
  });
}

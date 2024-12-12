import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gamers_gram/data/models/team_model.dart';
import 'package:gamers_gram/data/models/user_model.dart';
import 'package:gamers_gram/data/services/auth_service.dart';
import 'package:gamers_gram/modules/profile/view/team_view.dart';
import 'package:get/get.dart';

class TeamController extends GetxController {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  Rx<TeamModel?> currentTeam = Rx<TeamModel?>(null);
  Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  RxList<TeamModel> userTeams = RxList<TeamModel>([]);

  final AuthService _authService = Get.find<AuthService>();

  // List to store all team memberships
  Future<void> fetchUserTeams() async {
    try {
      String? currentUserUid = _authService.getCurrentUserId();

      if (currentUserUid == null) {
        print('No current user found');
        Get.snackbar('Error', 'User not authenticated');
        return;
      }

      // Fetch user data to get teamIds
      DatabaseEvent userEvent =
          await _database.ref('users/$currentUserUid').once();

      Map<String, dynamic> userData =
          Map<String, dynamic>.from(userEvent.snapshot.value as Map);

      List<dynamic> teamIds = userData['teamIds'] ?? [];

      userTeams.clear();

      // Fetch teams based on teamIds
      for (String teamId in teamIds) {
        DatabaseEvent teamEvent = await _database.ref('teams/$teamId').once();

        if (teamEvent.snapshot.value != null) {
          Map<String, dynamic> teamData =
              Map<String, dynamic>.from(teamEvent.snapshot.value as Map);

          TeamModel team = TeamModel.fromJson(teamData, teamId);
          userTeams.add(team);
        }
      }

      // Set current team logic remains similar
      String? currentTeamId = userData['currentTeamId'];

      if (currentTeamId != null) {
        try {
          currentTeam.value =
              userTeams.firstWhere((team) => team.teamId == currentTeamId);
        } catch (e) {
          print('Could not find current team: $e');
          currentTeam.value = userTeams.isNotEmpty ? userTeams.first : null;
        }
      } else if (userTeams.isNotEmpty) {
        currentTeam.value = userTeams.first;
      }
    } catch (e) {
      print('Comprehensive Error in fetchUserTeams: $e');
      Get.snackbar('Error', 'Failed to fetch teams: $e');
    }
  }

  // Method to set current team for user
  Future<void> setCurrentTeam(TeamModel team) async {
    try {
      String? currentUserUid = _authService.getCurrentUserId();
      if (currentUserUid == null) return;

      // Update user's profile with current team ID
      await _database
          .ref('users/$currentUserUid/currentTeamId')
          .set(team.teamId);

      // Set current team in controller
      currentTeam.value = team;
    } catch (e) {
      print('Error setting current team: $e');
      Get.snackbar('Error', 'Failed to set current team');
    }
  }

  @override
  void onInit() {
    super.onInit();
    _listenToTeamInvitations();
    fetchUserTeams(); // Fetch teams when controller initializes
    _listenToTeamInvitations();
  }

  // Create a new team
  Future<void> createTeam(
      {required String name,
      required String tag,
      required BuildContext context,
      required String ownerUid}) async {
    try {
      // Get current user ID
      String? currentUserUid = _authService.getCurrentUserId();

      if (currentUserUid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No authenticated user found')),
        );
        return;
      }

      // Validate inputs
      if (name.isEmpty || tag.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team name and tag cannot be empty')),
        );
        return;
      }

      // Generate a new team ID
      DatabaseReference teamRef = _database.ref().child('teams').push();
      String? newTeamId = teamRef.key;

      if (newTeamId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate team ID')),
        );
        return;
      }

      // Create team model
      TeamModel newTeam = TeamModel(
          teamId: newTeamId,
          name: name,
          tag: tag,
          owner: currentUserUid,
          members: {
            currentUserUid: {'role': 'owner', 'joinedAt': ServerValue.timestamp}
          });

      // Save team to database
      await teamRef.set(newTeam.toJson());

      // Update user's team information
      DatabaseReference userRef = _database.ref('users/$currentUserUid');

      // Fetch current user data
      DatabaseEvent userEvent = await userRef.once();

      // Convert snapshot to map
      Map<dynamic, dynamic> userData =
          userEvent.snapshot.value as Map<dynamic, dynamic>;

      // Prepare team IDs list
      List<dynamic> teamIds = userData['teamIds'] ?? [];

      // Add new team ID
      if (!teamIds.contains(newTeamId)) {
        teamIds.add(newTeamId);
      }

      // Update user's data
      await userRef.update({'teamIds': teamIds, 'currentTeamId': newTeamId});

      // Update local state
      currentTeam.value = newTeam;
      userTeams.add(newTeam);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Team created successfully')),
      );

      // Navigate to team view or close creation screen
      Get.to(() => TeamManagementPage());
    } catch (e) {
      // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create team: ${e.toString()}')),
      );
      print('Team Creation Error: $e');
    }
  }

  // Invite a user to team
  Future<void> inviteUserToTeam(
      {required String username, required String teamId}) async {
    try {
      // First, find user by username
      DatabaseEvent event = await _database
          .ref('users')
          .orderByChild('username')
          .equalTo(username)
          .once();

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> users =
            event.snapshot.value as Map<dynamic, dynamic>;
        String userUid = users.keys.first;

        // Add invitation to team
        DatabaseReference invitationRef =
            _database.ref('teams/$teamId/invitations/$userUid');

        await invitationRef.set({
          'status': 'pending',
          'invitedAt': ServerValue.timestamp,
          'invitedBy': userUid
        });

        Get.snackbar('Success', 'Invitation sent to $username');
      } else {
        Get.snackbar('Error', 'User not found');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to invite user: ${e.toString()}');
    }
  }

  // Accept team invitation
  Future<void> acceptTeamInvitation(String teamId) async {
    try {
      String? currentUserUid = _authService.getCurrentUserId();

      // Update team members
      await _database
          .ref('teams/$teamId/members/$currentUserUid')
          .set({'role': 'member', 'joinedAt': ServerValue.timestamp});

      // Remove invitation
      await _database.ref('teams/$teamId/invitations/$currentUserUid').remove();

      // Update user's current team
      await _database.ref('users/$currentUserUid/currentTeamId').set(teamId);

      Get.snackbar('Success', 'Team invitation accepted');
    } catch (e) {
      Get.snackbar('Error', 'Failed to accept invitation: ${e.toString()}');
    }
  }

  Rx<List<TeamInvitation>> pendingInvitations = Rx<List<TeamInvitation>>([]);

  // Listen to team invitations for current user
  void _listenToTeamInvitations() {
    String? currentUserUid = _authService.getCurrentUserId();

    _database.ref('teams').onValue.listen((event) {
      List<TeamInvitation> invitations = [];

      // Iterate through all teams
      Map<dynamic, dynamic>? teamsData =
          event.snapshot.value as Map<dynamic, dynamic>?;

      if (teamsData != null) {
        teamsData.forEach((teamId, teamData) {
          // Check if this team has an invitation for current user
          Map<dynamic, dynamic>? teamInvitations = teamData['invitations'];

          if (teamInvitations != null &&
              teamInvitations.containsKey(currentUserUid)) {
            var invitationData = teamInvitations[currentUserUid];

            if (invitationData['status'] == 'pending') {
              invitations.add(TeamInvitation(
                teamId: teamId,
                teamName: teamData['name'],
                invitedBy: invitationData['invitedBy'],
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

      // Remove invitation
      await _database.ref('teams/$teamId/invitations/$currentUserUid').remove();

      Get.snackbar('Invitation', 'Team invitation declined');
    } catch (e) {
      Get.snackbar('Error', 'Failed to decline invitation: ${e.toString()}');
    }
  }
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

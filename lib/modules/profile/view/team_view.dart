import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gamers_gram/data/models/team_model.dart';
import 'package:gamers_gram/modules/auth/controllers/auth_controller.dart';
import 'package:gamers_gram/modules/profile/controllers/team_controller.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class TeamManagementPage extends StatelessWidget {
  final TeamController _teamController = Get.find<TeamController>();
  final AuthController _authController = Get.find<AuthController>();

  TeamManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _teamController.fetchUserTeams(),
          ),
          _buildTeamActionsMenu(context),
        ],
      ),
      body: Obx(() {
        // Check if teams are loading
        if (_teamController.userTeams.isEmpty) {
          return _buildNoTeamContent(context);
        }

        return RefreshIndicator(
          onRefresh: () async => await _teamController.fetchUserTeams(),
          child: ListView(
            children: [
              // Team Invitations Section
              _buildTeamInvitationsSection(),

              // Current Team Overview
              _buildTeamOverviewSection(),

              // Team Members Section
              _buildTeamMembersSection(),

              // Match History Section
              _buildMatchHistorySection(),
            ],
          ),
        );
      }),
    );
  }

  // No Team Content
  Widget _buildNoTeamContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'You are not part of any team',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _showCreateTeamDialog(context),
            child: const Text('Create Team'),
          ),
        ],
      ),
    );
  }

  // Team Invitations Section
  Widget _buildTeamInvitationsSection() {
    return Obx(() {
      final invitations = _teamController.pendingInvitations.value;

      if (invitations.isEmpty) {
        return const SizedBox.shrink();
      }

      return ExpansionTile(
        title: Text('Team Invitations (${invitations.length})'),
        children: invitations.map((invitation) {
          return ListTile(
            title: Text('Invited to ${invitation.teamName}'),
            subtitle: Text(
                'Invited on ${DateFormat.yMMMd().format(invitation.invitedAt)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () =>
                      _teamController.acceptTeamInvitation(invitation.teamId),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () =>
                      _teamController.declineTeamInvitation(invitation.teamId),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  // Team Overview Section
  Widget _buildTeamOverviewSection() {
    final currentTeam = _teamController.currentTeam.value;
    if (currentTeam == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentTeam.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Team Tag: ${currentTeam.tag}'),
                Text('Members: ${currentTeam.members.length}'),
              ],
            ),
            const SizedBox(height: 8),
            Text('Owner: ${currentTeam.owner}'),
          ],
        ),
      ),
    );
  }

  // Team Members Section
  // Team Members Section
  Widget _buildTeamMembersSection() {
    final currentTeam = _teamController.currentTeam.value;
    if (currentTeam == null) return const SizedBox.shrink();

    return ExpansionTile(
      title: Text('Team Members (${currentTeam.members.length})'),
      children: currentTeam.members.entries.map((entry) {
        // Convert entry.value to Map<String, dynamic>
        final memberData = Map<String, dynamic>.from(entry.value as Map);

        return ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.person),
          ),
          title: Text(
              entry.key.toString()), // User ID - replace with username lookup
          subtitle: Text(memberData['role'] ?? 'Member'),
          trailing: _buildMemberActions(entry.key.toString(), memberData),
        );
      }).toList(),
    );
  }

  // Member Actions (Only visible to team owner)
  Widget _buildMemberActions(String memberId, Map<String, dynamic> memberData) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentTeam = _teamController.currentTeam.value;

    if (currentTeam == null ||
        currentUser == null ||
        currentTeam.owner != currentUser.uid) {
      return const SizedBox.shrink();
    }

    // Only show actions if current user is the owner
    return PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          child: const Text('Promote to Admin'),
          onTap: () {
            // Implement promote logic
          },
        ),
        PopupMenuItem(
          child: const Text('Remove from Team'),
          onTap: () {
            // Implement remove member logic
          },
        ),
      ],
    );
  }

  // Match History Section
  Widget _buildMatchHistorySection() {
    final currentTeam = _teamController.currentTeam.value;
    final matchHistory = currentTeam?.matchHistory ?? [];

    if (matchHistory.isEmpty) {
      return const ExpansionTile(
        title: Text('Match History'),
        children: [Center(child: Text('No match history available'))],
      );
    }

    return ExpansionTile(
      title: Text('Match History (${matchHistory.length})'),
      children: matchHistory.map((match) {
        return ListTile(
          title: Text('Match against ${match['opponent'] ?? 'Unknown'}'),
          subtitle: Text('Result: ${match['result'] ?? 'N/A'}'),
          trailing: Text(DateFormat.yMMMd().format(
              DateTime.parse(match['date'] ?? DateTime.now().toString()))),
        );
      }).toList(),
    );
  }

  // Team Actions Menu
  Widget _buildTeamActionsMenu(BuildContext context) {
    return PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          child: const Text('Create New Team'),
          onTap: () => _showCreateTeamDialog(context),
        ),
        PopupMenuItem(
          child: const Text('Invite Member'),
          onTap: () => _showInviteUserDialog(context),
        ),
        PopupMenuItem(
          child: const Text('Leave Team'),
          onTap: () => _showLeaveTeamDialog(context),
        ),
      ],
    );
  }

  // Create Team Dialog
  void _showCreateTeamDialog(BuildContext context) {
    final nameController = TextEditingController();
    final tagController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Team Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: tagController,
              decoration: const InputDecoration(
                labelText: 'Team Tag',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser != null) {
                _teamController.createTeam(
                  name: nameController.text,
                  tag: tagController.text,
                  ownerUid: currentUser.uid,
                  context: context,
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // Invite User Dialog
  void _showInviteUserDialog(BuildContext context) {
    final usernameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite User to Team'),
        content: TextField(
          controller: usernameController,
          decoration: const InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final currentTeam = _teamController.currentTeam.value;
              if (currentTeam?.teamId != null) {
                _teamController.inviteUserToTeam(
                  username: usernameController.text,
                  teamId: currentTeam!.teamId!,
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Invite'),
          ),
        ],
      ),
    );
  }

  // Leave Team Dialog
  void _showLeaveTeamDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Team'),
        content: const Text('Are you sure you want to leave this team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // Implement leave team logic
              Navigator.of(context).pop();
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

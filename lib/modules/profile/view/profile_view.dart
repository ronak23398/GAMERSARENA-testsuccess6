import 'package:flutter/material.dart';
import 'package:gamers_gram/data/models/user_model.dart';
import 'package:gamers_gram/modules/profile/controllers/profile_controller.dart';
import 'package:get/get.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.wallet),
            onPressed: () => Get.toNamed("/wallet"),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => controller.logout(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = controller.currentUser.value;
        if (user == null) {
          return const Center(child: Text('No user data found'));
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchCurrentUserProfile(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildProfileHeader(user),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              _buildTeamsSection(),
              const SizedBox(height: 16),
              _buildChallengesSection(),
              const SizedBox(height: 16),
              _buildTournamentsSection(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 80),
            const SizedBox(height: 10),
            Text(
              user.username,
              style: Get.textTheme.headlineSmall,
            ),
            Text(
              user.email,
              style: Get.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsSection() {
    final user = controller.currentUser.value!;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('My Teams', style: Get.textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showTeamEditBottomSheet,
                ),
              ],
            ),
            _buildTeamTile('Valorant', user.valorantTeam),
            _buildTeamTile('CS2', user.cs2Team),
            _buildTeamTile('BGMI', user.bgmiTeam),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamTile(String game, String? teamName) {
    return ListTile(
      title: Text(game),
      trailing: Text(teamName ?? 'No Team',
          style:
              TextStyle(color: teamName == null ? Colors.grey : Colors.black)),
    );
  }

  Widget _buildChallengesSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Challenges', style: Get.textTheme.titleMedium),
            const SizedBox(height: 10),
            controller.challenges.isEmpty
                ? const Text('No challenges yet')
                : Column(
                    children: controller.challenges
                        .map((challenge) => ListTile(
                              title: Text(
                                  challenge['name'] ?? 'Unknown Challenge'),
                              subtitle:
                                  Text(challenge['status'] ?? 'No status'),
                            ))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentsSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tournaments', style: Get.textTheme.titleMedium),
            const SizedBox(height: 10),
            controller.tournaments.isEmpty
                ? const Text('No tournaments yet')
                : Column(
                    children: controller.tournaments
                        .map((tournament) => ListTile(
                              title: Text(
                                  tournament['name'] ?? 'Unknown Tournament'),
                              subtitle: Text(tournament['date'] ?? 'No date'),
                            ))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  // Continuation of the previous ProfileView...

  // Bottom sheet method (continued)
  void _showTeamEditBottomSheet() {
    final user = controller.currentUser.value!;

    // Pre-fill existing team names
    controller.valorantTeamController.text = user.valorantTeam ?? '';
    controller.cs2TeamController.text = user.cs2Team ?? '';
    controller.bgmiTeamController.text = user.bgmiTeam ?? '';

    Get.bottomSheet(
      backgroundColor: Colors.white,
      Form(
        key: controller.teamFormKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Edit Teams', style: Get.textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.valorantTeamController,
                decoration: const InputDecoration(labelText: 'Valorant Team'),
                validator: (value) {
                  return null; // Add validation if needed
                },
              ),
              TextFormField(
                controller: controller.cs2TeamController,
                decoration: const InputDecoration(labelText: 'CS2 Team'),
                validator: (value) {
                  return null; // Add validation if needed
                },
              ),
              TextFormField(
                controller: controller.bgmiTeamController,
                decoration: const InputDecoration(labelText: 'BGMI Team'),
                validator: (value) {
                  return null; // Add validation if needed
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: controller.updateTeams,
                child: const Text('Save Teams'),
              ),
            ],
          ),
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  // Add funds dialog
}

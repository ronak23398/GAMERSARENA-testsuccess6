import 'package:flutter/material.dart';
import 'package:gamers_gram/data/models/tournament_models.dart';
import 'package:gamers_gram/modules/tournamnets_page/controllers/tournament_controller.dart';
import 'package:gamers_gram/modules/tournamnets_page/view/create_tournament_view.dart';
import 'package:gamers_gram/modules/tournamnets_page/view/tournament_details_view.dart';
import 'package:get/get.dart';

class TournamentView extends GetView<TournamentController> {
  const TournamentView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: controller.currentTabIndex.value,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tournaments'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Get.to(() => const CreateTournamentView()),
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterBottomSheet(context),
            ),
          ],
          bottom: TabBar(
            onTap: controller.onTabChanged,
            tabs: const [
              Tab(text: 'All Tournaments'),
              Tab(text: 'My Tournaments'),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildTournamentList();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentList() {
    return Obx(() {
      final tournaments = controller.currentTabIndex.value == 0
          ? controller.tournaments
          : controller.myTournaments;

      return RefreshIndicator(
        onRefresh: controller.refreshTournaments,
        child: tournaments.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No tournaments found',
                      style: TextStyle(fontSize: 18),
                    ),
                    TextButton(
                      onPressed: controller.refreshTournaments,
                      child: const Text('Refresh'),
                    )
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tournaments.length,
                itemBuilder: (context, index) {
                  final tournament = tournaments[index];
                  return _buildTournamentCard(tournament);
                },
              ),
      );
    });
  }

  Widget _buildTournamentCard(Tournament tournament) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showTournamentJoinDialog(tournament),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(tournament),
              const SizedBox(height: 8),
              _buildCardDetails(tournament),
              const SizedBox(height: 8),
              _buildCardFooter(tournament),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(Tournament tournament) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            tournament.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: controller.getStatusColor(tournament.status),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            tournament.status,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildCardDetails(Tournament tournament) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.videogame_asset, size: 16),
            const SizedBox(width: 8),
            Text(tournament.game),
            const SizedBox(width: 16),
            const Icon(Icons.calendar_today, size: 16),
            const SizedBox(width: 8),
            Text(controller.formatDate(tournament.startDate)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.people, size: 16),
            const SizedBox(width: 8),
            Text(
              'Participants: ${tournament.participants?.length ?? 0}/${tournament.maxParticipants}',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardFooter(Tournament tournament) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Prize Pool: \$${tournament.prizePool.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        Text(
          'Entry Fee: \$${tournament.entryFee.toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  void _showTournamentJoinDialog(Tournament tournament) {
    final TextEditingController teamNameController = TextEditingController();

    if (!controller.isTournamentJoinable(tournament)) {
      Get.snackbar(
        'Tournament Closed',
        'Tournament registration is closed',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    Get.defaultDialog(
      title: 'Join Tournament',
      content: TextField(
        controller: teamNameController,
        decoration: const InputDecoration(
          labelText: 'Team Name',
          hintText: 'Enter your team name',
        ),
      ),
      textConfirm: 'Join',
      textCancel: 'Cancel',
      onConfirm: () async {
        final teamName = teamNameController.text.trim();
        if (teamName.isEmpty) {
          Get.snackbar(
            'Error',
            'Please enter a team name',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }

        final success = await controller.joinTournament(tournament, teamName);
        if (success) {
          Get.back(); // Close dialog
          final tournamentDetails =
              await controller.navigateToTournamentDetails(tournament.id);
          if (tournamentDetails != null) {
            Get.to(() => TournamentDetailsView(tournament: tournamentDetails));
          }
        } else {
          Get.snackbar(
            'Error',
            'Unable to join tournament',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      },
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Tournaments',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Game'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['CS:GO', 'DOTA 2', 'Valorant', 'PUBG']
                  .map((game) => FilterChip(
                        label: Text(game),
                        selected: controller.selectedGameFilter.value == game,
                        onSelected: (selected) {
                          controller.setGameFilter(selected ? game : '');
                          Get.back();
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text('Status'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Open', 'Registration', 'Ongoing', 'Completed']
                  .map((status) => FilterChip(
                        label: Text(status),
                        selected:
                            controller.selectedStatusFilter.value == status,
                        onSelected: (selected) {
                          controller.setStatusFilter(selected ? status : '');
                          Get.back();
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text('Sort By'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Start Date'),
                  selected: controller.sortBy.value == 'startDate',
                  onSelected: (selected) {
                    if (selected) {
                      controller.setSortBy('startDate');
                      Get.back();
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Prize Pool'),
                  selected: controller.sortBy.value == 'prizePool',
                  onSelected: (selected) {
                    if (selected) {
                      controller.setSortBy('prizePool');
                      Get.back();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

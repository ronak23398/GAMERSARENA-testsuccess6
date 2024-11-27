import 'package:flutter/material.dart';
import 'package:gamers_gram/data/models/tournament_models.dart';
import 'package:gamers_gram/modules/tournamnets_page/controllers/tournament_controller.dart';
import 'package:gamers_gram/modules/tournamnets_page/view/create_tournament_view.dart';
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
                if (controller.isLoading.value &&
                    controller.tournaments.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildTournamentList();
              }),
            ),
            Obx(() => controller.hasMoreData.value
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () => controller.currentTabIndex.value == 0
                          ? controller.fetchTournaments()
                          : controller.fetchMyTournaments(),
                      child: const Text('Load More Tournaments'),
                    ),
                  )
                : const SizedBox.shrink()),
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
        onTap: () => controller.getTournamentDetails(tournament.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tournament Name and Status
              Row(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(tournament.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tournament.status,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Game and Date Info
              Row(
                children: [
                  const Icon(Icons.videogame_asset, size: 16),
                  const SizedBox(width: 4),
                  Text(tournament.game),
                  const SizedBox(width: 16),
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 4),
                  Text(_formatDate(tournament.startDate)),
                ],
              ),
              const SizedBox(height: 8),

              // Participants Info
              Row(
                children: [
                  const Icon(Icons.people, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Participants: ${tournament.participants?.length ?? 0}/${tournament.maxParticipants}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Registration Deadline
              Row(
                children: [
                  const Icon(Icons.timer, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Reg. Deadline: ${_formatDate(tournament.registrationEndDate)}',
                    style: TextStyle(
                      color: _isRegistrationClosed(tournament)
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Prize Pool and Entry Fee
              Row(
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
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Platform and Tournament Type
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Platform: ${tournament.platform}',
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'Type: ${tournament.format}',
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),

              // Join Tournament Button
              if (_isTournamentJoinable(tournament))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ElevatedButton(
                    onPressed: () => _joinTournament(tournament),
                    child: const Text('Join Tournament'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isRegistrationClosed(Tournament tournament) {
    return DateTime.now().isAfter(tournament.registrationEndDate);
  }

  bool _isTournamentJoinable(Tournament tournament) {
    final now = DateTime.now();
    return now.isBefore(tournament.registrationEndDate) &&
        tournament.status.toLowerCase() == 'open';
  }

  Future<void> _joinTournament(Tournament tournament) async {
    final success =
        await controller.joinTournament(tournament.id as Tournament);
    if (success) {
      Get.snackbar(
        'Success',
        'You have joined the tournament',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        'Unable to join tournament',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
      case 'registration':
        return Colors.green;
      case 'ongoing':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
              children: [
                'CS:GO',
                'DOTA 2',
                'Valorant',
                'PUBG',
              ]
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
              children: [
                'Open',
                'Registration',
                'Ongoing',
                'Completed',
              ]
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

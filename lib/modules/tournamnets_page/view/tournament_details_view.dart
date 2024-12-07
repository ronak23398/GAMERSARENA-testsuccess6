import 'package:flutter/material.dart';
import 'package:gamers_gram/data/models/tournament_models.dart';
import 'package:gamers_gram/modules/tournamnets_page/controllers/tournament_controller.dart';
import 'package:get/get.dart';

class TournamentDetailsView extends StatelessWidget {
  final Tournament tournament;
  final TournamentController controller = Get.find();

  TournamentDetailsView({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tournament.name),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTournamentHeader(),
              const SizedBox(height: 16),
              _buildTournamentDetails(),
              const SizedBox(height: 16),
              _buildParticipantsList(),
              const SizedBox(height: 16),
              _buildMatchBrackets(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTournamentHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tournament.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
            ),
            const SizedBox(height: 16),
            _buildHeaderInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildInfoColumn(
          Icons.calendar_today,
          'Start Date',
          controller.formatDate(tournament.startDate),
        ),
        _buildInfoColumn(
          Icons.timer,
          'Reg. Deadline',
          controller.formatDate(tournament.registrationEndDate),
        ),
        _buildInfoColumn(
          Icons.attach_money,
          'Prize Pool',
          '\$${tournament.prizePool.toStringAsFixed(2)}',
        ),
      ],
    );
  }

  Widget _buildInfoColumn(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(value),
      ],
    );
  }

  Widget _buildTournamentDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tournament Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Game', tournament.game),
            _buildDetailRow('Platform', tournament.platform),
            _buildDetailRow('Format', tournament.format),
            _buildDetailRow(
                'Entry Fee', '\$${tournament.entryFee.toStringAsFixed(2)}'),
            _buildDetailRow('Participants',
                '${tournament.participants?.length ?? 0}/${tournament.maxParticipants}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildParticipantsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Participants',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (tournament.participants != null &&
                tournament.participants!.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tournament.participants!.length,
                itemBuilder: (context, index) {
                  final participant =
                      tournament.participants!.values.elementAt(index);
                  return ListTile(
                    title: Text(participant['teamName'] ?? 'Unknown Team'),
                    subtitle: Text('Joined: ${participant['joinedAt']}'),
                  );
                },
              )
            else
              const Text('No participants yet'),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchBrackets() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tournament Brackets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('Brackets will be available soon'),
            // You can add more complex bracket logic here later
          ],
        ),
      ),
    );
  }
}

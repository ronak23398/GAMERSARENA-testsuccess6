import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gamers_gram/modules/challenges/controllers/scrim_controller.dart';
import 'package:gamers_gram/modules/profile/controllers/team_controller.dart';
import 'package:get/get.dart';

class CreateScrimDialog extends StatelessWidget {
  final ScrimController scrimController = Get.find<ScrimController>();
  final TeamController teamController = Get.find<TeamController>();
  final TextEditingController amountController = TextEditingController();

  CreateScrimDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Scrim'),
      content: Obx(() {
        final currentTeam = teamController.currentTeam.value;

        if (currentTeam == null) {
          return const Text('No team selected');
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Team: ${currentTeam.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: scrimController.selectedGame.value,
              items: scrimController.games.map((game) {
                return DropdownMenuItem(
                  value: game,
                  child: Text(game),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  scrimController.updateSelectedGame(value);
                }
              },
              decoration: const InputDecoration(
                labelText: 'Select Game',
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: scrimController.selectedServer.value,
              items: scrimController
                  .serversByGame[scrimController.selectedGame.value]!
                  .map((server) {
                return DropdownMenuItem(
                  value: server,
                  child: Text(server),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  scrimController.updateSelectedServer(value);
                }
              },
              decoration: const InputDecoration(
                labelText: 'Select Server',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),
          ],
        );
      }),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
        Obx(() {
          final currentTeam = teamController.currentTeam.value;

          return ElevatedButton(
            onPressed: scrimController.isProcessing.value || currentTeam == null
                ? null
                : () {
                    final amount = double.tryParse(amountController.text);
                    if (amount != null && amount > 0) {
                      scrimController
                          .createScrim(amount, currentTeam)
                          .then((success) {
                        if (success) {
                          Get.back();
                        }
                      });
                    } else {
                      Get.snackbar('Error', 'Please enter a valid amount');
                    }
                  },
            child: scrimController.isProcessing.value
                ? const CircularProgressIndicator()
                : const Text('Create Scrim'),
          );
        }),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gamers_gram/modules/challenges/controllers/scrim_controller.dart';
import 'package:get/get.dart';

class CreateScrimDialog extends StatelessWidget {
  final ScrimController scrimController = Get.find<ScrimController>();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController teamNameController = TextEditingController();

  CreateScrimDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Scrim'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => DropdownButtonFormField<String>(
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
              )),
          const SizedBox(height: 10),
          Obx(() => DropdownButtonFormField<String>(
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
              )),
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
          const SizedBox(height: 10),
          TextField(
            controller: teamNameController,
            decoration: const InputDecoration(
              labelText: 'Team Name',
              prefixIcon: Icon(Icons.group),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
        Obx(() => ElevatedButton(
              onPressed: scrimController.isProcessing.value
                  ? null
                  : () {
                      final amount = double.tryParse(amountController.text);
                      final teamName = teamNameController.text.trim();
                      if (amount != null && amount > 0 && teamName.isNotEmpty) {
                        scrimController
                            .createScrim(amount, teamName)
                            .then((success) {
                          if (success) {
                            Get.back();
                          }
                        });
                      } else {
                        Get.snackbar('Error',
                            'Please enter a valid amount and team name');
                      }
                    },
              child: scrimController.isProcessing.value
                  ? const CircularProgressIndicator()
                  : const Text('Create Scrim'),
            )),
      ],
    );
  }
}

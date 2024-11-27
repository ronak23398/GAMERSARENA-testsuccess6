import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/1v1_challenege_controller.dart';

class CreateChallengeDialog extends StatelessWidget {
  final ChallengeController controller = Get.find<ChallengeController>();
  final TextEditingController amountController = TextEditingController();

  CreateChallengeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Challenge'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => DropdownButtonFormField<String>(
                  value: controller.selectedGame.value,
                  decoration: const InputDecoration(
                    labelText: 'Select Game',
                    border: OutlineInputBorder(),
                  ),
                  items: controller.games.map((String game) {
                    return DropdownMenuItem<String>(
                      value: game,
                      child: Text(game),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      controller.updateSelectedGame(newValue);
                    }
                  },
                )),
            const SizedBox(height: 16),
            Obx(() => DropdownButtonFormField<String>(
                  value: controller.selectedServer.value,
                  decoration: const InputDecoration(
                    labelText: 'Select Server',
                    border: OutlineInputBorder(),
                  ),
                  items: controller
                      .serversByGame[controller.selectedGame.value]!
                      .map((String server) {
                    return DropdownMenuItem<String>(
                      value: server,
                      child: Text(server),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      controller.updateSelectedServer(newValue);
                    }
                  },
                )),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: 'Enter amount',
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (amountController.text.isNotEmpty) {
              controller.createChallenge(
                double.parse(amountController.text),
              );
              amountController.clear();
              Get.back();
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

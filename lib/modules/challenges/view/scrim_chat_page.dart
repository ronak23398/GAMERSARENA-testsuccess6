import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gamers_gram/data/models/scrim_model.dart';
import 'package:gamers_gram/modules/challenges/controllers/scrim_chat_controller.dart';
import 'package:get/get.dart';

class ScrimChatPage extends StatelessWidget {
  final String scrimId;
  final ScrimModel scrim;

  const ScrimChatPage({super.key, required this.scrimId, required this.scrim});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ScrimChatController(
      scrimId: scrimId,
      scrim: scrim,
    ));
    final auth = FirebaseAuth.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text('Scrim Chat - ${scrim.game} ${scrim.server}'),
      ),
      body: Column(
        children: [
          // Scrim Details Header
          Container(
            color: Colors.purple[100],
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Amount: \Rs ${scrim.amount}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Status: ${scrim.status}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          GetBuilder<ScrimChatController>(
            builder: (controller) {
              if (controller.hasSelectedOutcome.value) {
                final remainingTime = controller.getRemainingTime();
                final minutes = remainingTime.inMinutes;
                final seconds = remainingTime.inSeconds % 60;

                return Container(
                  color: const Color.fromARGB(255, 135, 46, 250),
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Text(
                        controller.outcomeSelectedBy.value ==
                                auth.currentUser?.uid
                            ? "Waiting for opponent to declare result"
                            : "Time left for you to declare result",
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "$minutes:${seconds.toString().padLeft(2, '0')}",
                        style: TextStyle(
                          color: controller.isTimerRunning.value
                              ? Colors.green
                              : Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Messages ListView
          Expanded(
            child: Obx(() {
              return ListView.builder(
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  final isCurrentUser =
                      message['senderId'] == auth.currentUser?.uid;

                  return Align(
                    alignment: isCurrentUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            isCurrentUser ? Colors.blue[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message['message'] ?? '',
                        style: TextStyle(
                            color: isCurrentUser
                                ? Colors.black87
                                : Colors.black87),
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          // Outcome selection buttons (only for accepted scrims)
          if (scrim.status == 'accepted')
            Obx(() {
              if (controller.shouldShowOutcomeButtons()) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          controller.selectScrimOutcome(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        disabledBackgroundColor: Colors.green.withOpacity(0.5),
                      ),
                      child: const Text('Win'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          controller.selectScrimOutcome(context, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        disabledBackgroundColor: Colors.red.withOpacity(0.5),
                      ),
                      child: const Text('Lose'),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            }),

          // Message input section
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        if (controller.messageController.text.isNotEmpty) {
                          controller.sendMessage(
                              message: controller.messageController.text);
                          controller.messageController.clear();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

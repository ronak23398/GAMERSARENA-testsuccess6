import 'package:appwrite/appwrite.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gamers_gram/modules/challenges/controllers/challenge_chat_controller.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ChallengeChatPage extends StatelessWidget {
  final String challengeId;
  final String opponentId;

  const ChallengeChatPage(
      {super.key, required this.challengeId, required this.opponentId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChallengeChatController(
      challengeId: challengeId,
      opponentId: opponentId,
      client: Client(),
      storage: Storage(Client()),
    ));
    final auth = FirebaseAuth.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge Chat'),
      ),
      body: Column(
        children: [
          // Countdown Timer Display
          GetBuilder<ChallengeChatController>(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Display image if exists
                          if (message['imageUrl'] != null)
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    child: Image.network(
                                      message['imageUrl'],
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                );
                              },
                              child: Image.network(
                                message['imageUrl'],
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const CircularProgressIndicator();
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 50,
                                  );
                                },
                              ),
                            ),

                          // Display text message if exists
                          if (message['message'] != null &&
                              message['message'].isNotEmpty)
                            Text(
                              message['message'],
                              style: TextStyle(
                                  color: isCurrentUser
                                      ? Colors.black87
                                      : Colors.black87),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          // Outcome selection buttons
          Obx(() {
            // Check if outcome buttons should be shown
            if (controller.shouldShowOutcomeButtons()) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => controller.selectOutcome(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      // Disable if an outcome has already been selected
                      disabledBackgroundColor: Colors.green.withOpacity(0.5),
                    ),
                    child: const Text('Win'),
                  ),
                  ElevatedButton(
                    onPressed: () => controller.selectOutcome(context, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      // Disable if an outcome has already been selected
                      disabledBackgroundColor: Colors.red.withOpacity(0.5),
                    ),
                    child: const Text('Lose'),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          }),

          // Message input and image pick section
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: () => controller.pickImage(ImageSource.camera),
              ),
              IconButton(
                icon: const Icon(Icons.photo_library),
                onPressed: () => controller.pickImage,
              ),
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

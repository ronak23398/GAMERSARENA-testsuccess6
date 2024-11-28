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
    // Initialize the controller with Appwrite dependencies
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
          Obx(() {
            if (controller.hasSelectedOutcome.value) {
              return Container(
                decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 135, 46, 250)),
                child: Column(
                  children: [
                    Text(
                      "Time left for opponent to declare result",
                      style: TextStyle(color: Colors.white),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: LinearProgressIndicator(
                        value: controller.calculateRemainingTime(),
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          controller.isTimerRunning.value
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Expanded(
            child: Obx(() {
              return ListView.builder(
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  final isCurrentUser = message['senderId'] == auth.currentUser;

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
                      child: message['imageUrl'] != null
                          ? Image.network(message['imageUrl'], width: 200)
                          : Text(message['message'] ?? ''),
                    ),
                  );
                },
              );
            }),
          ),
          Obx(() {
            if (!controller.hasSelectedOutcome.value) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => controller.selectOutcome(context, true),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Win'),
                  ),
                  ElevatedButton(
                    onPressed: () => controller.selectOutcome(context, false),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Lose'),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: () => controller.pickImage(ImageSource.camera),
              ),
              IconButton(
                icon: const Icon(Icons.photo_library),
                onPressed: () => controller.pickImage(ImageSource.gallery),
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

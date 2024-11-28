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
          // Existing outcome selection indicator
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

          // Messages ListView
          Expanded(
            child: Obx(() {
              return ListView.builder(
                reverse: true, // Newest messages at the bottom
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  // Reverse index to show newest messages at the bottom
                  final message = controller
                      .messages[controller.messages.length - 1 - index];
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
                                // Optional: Implement full screen image view
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
                                  return CircularProgressIndicator();
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
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

          // Outcome selection buttons (if not selected)
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

          // Message input and image pick section
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

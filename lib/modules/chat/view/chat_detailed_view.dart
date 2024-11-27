import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gamers_gram/core/widgets/chat_bubble.dart';
import 'package:gamers_gram/core/widgets/chat_input_field.dart';
import 'package:gamers_gram/data/models/chat_model.dart';
import 'package:gamers_gram/modules/chat/controllers/chat_controller.dart';
import 'package:get/get.dart';

class ChatDetailScreen extends StatelessWidget {
  final String? matchId;
  final String? recipientId;
  final bool isMatchChat;
  final chatController = Get.find<ChatController>();
  final messageController = TextEditingController();

  ChatDetailScreen({super.key, 
    this.matchId,
    this.recipientId,
    required this.isMatchChat,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isMatchChat ? 'Match Chat' : 'Direct Message'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: chatController.getMessages(
                recipientId ?? '',
                matchId: matchId,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final message = snapshot.data![index];
                    final isMe = message.senderId ==
                        FirebaseAuth.instance.currentUser?.uid;

                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),
          ChatInputField(
            controller: messageController,
            onSend: () {
              if (messageController.text.trim().isNotEmpty) {
                chatController.sendMessage(
                  content: messageController.text,
                  recipientId: recipientId ?? '',
                  matchId: matchId,
                );
                messageController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}

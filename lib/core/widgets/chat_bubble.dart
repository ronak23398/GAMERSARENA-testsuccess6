import 'package:flutter/material.dart';
import 'package:gamers_gram/data/models/chat_model.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const MessageBubble({super.key, 
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: isMe ? Colors.blue : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.imageUrl != null)
                Image.network(
                  message.imageUrl!,
                  height: 150,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                ),
              ),
              Text(
                DateFormat('HH:mm').format(message.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: isMe ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

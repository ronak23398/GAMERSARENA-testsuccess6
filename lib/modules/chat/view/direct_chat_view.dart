import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gamers_gram/modules/chat/view/chat_detailed_view.dart';
import 'package:get/get.dart';

class DirectChatsTab extends StatelessWidget {
  const DirectChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      // Listen to the 'users' node in Realtime Database
      stream: FirebaseDatabase.instance.ref().child('users').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Convert the database snapshot to a map
        final usersMap =
            Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

        // Convert map to list and remove current user
        final usersList = usersMap.entries
            .where(
                (entry) => entry.key != FirebaseAuth.instance.currentUser?.uid)
            .map((entry) {
          final userData = Map<String, dynamic>.from(entry.value as Map);
          return {
            'id': entry.key,
            ...userData,
          };
        }).toList();

        return ListView.builder(
          itemCount: usersList.length,
          itemBuilder: (context, index) {
            final user = usersList[index];

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(
                  (user['username'] as String? ?? '?')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(user['username'] as String? ?? 'Unknown User'),
              onTap: () => Get.to(
                () => ChatDetailScreen(
                  recipientId: user['id'],
                  isMatchChat: false,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:gamers_gram/modules/chat/view/chat_detailed_view.dart';
import 'package:get/get.dart';

class MatchChatsTab extends StatelessWidget {
  const MatchChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance
          .ref()
          .child('challenges')
          .orderByChild('status')
          .equalTo('accepted')
          .onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Convert the database snapshot to a map
        final challengesMap =
            Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

        // Filter challenges for current user and convert to list
        final challengesList = challengesMap.entries
            .where((entry) {
              final challenge = Map<String, dynamic>.from(entry.value as Map);
              final participants =
                  List<String>.from(challenge['participants'] ?? []);
              return participants.contains(currentUserId);
            })
            .map((entry) => {
                  'id': entry.key,
                  ...Map<String, dynamic>.from(entry.value as Map),
                })
            .toList();

        return ListView.builder(
          itemCount: challengesList.length,
          itemBuilder: (context, index) {
            final challenge = challengesList[index];

            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.sports_esports),
              ),
              title: Text('Match: ${challenge['game'] ?? 'Unknown Game'}'),
              subtitle:
                  Text('Amount: \$${challenge['amount']?.toString() ?? '0'}'),
              onTap: () => Get.to(
                () => ChatDetailScreen(
                  matchId: challenge['id'],
                  isMatchChat: true,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

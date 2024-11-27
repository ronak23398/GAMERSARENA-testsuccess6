import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:gamers_gram/data/models/chat_model.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final _db = FirebaseDatabase.instance;
  final _auth = FirebaseAuth.instance;

  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isMatchChat = true.obs;

  Future<void> sendMessage({
    required String content,
    required String recipientId,
    String? matchId,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: user.uid,
      content: content,
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
    );

    final chatId = isMatchChat.value
        ? 'match_$matchId'
        : _getChatId(user.uid, recipientId);

    // Create a reference to the chat messages
    final messageRef = _db.ref().child('chats/$chatId/messages');

    // Push creates a unique key for each message
    await messageRef.push().set(message.toJson());
  }

  String _getChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  Stream<List<ChatMessage>> getMessages(String otherId, {String? matchId}) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    final chatId =
        isMatchChat.value ? 'match_$matchId' : _getChatId(user.uid, otherId);

    return _db
        .ref()
        .child('chats/$chatId/messages')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      final snapshot = event.snapshot;
      if (snapshot.value == null) return [];

      // Convert the database snapshot to a list of messages
      final messagesMap = Map<String, dynamic>.from(snapshot.value as Map);
      return messagesMap.entries.map((entry) {
        final data = Map<String, dynamic>.from(entry.value as Map);
        data['id'] = entry.key; // Add the Firebase key as the message id
        return ChatMessage.fromJson(data);
      }).toList()
        ..sort((a, b) =>
            b.timestamp.compareTo(a.timestamp)); // Sort by timestamp descending
    });
  }
}

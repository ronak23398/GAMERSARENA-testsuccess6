class ChatMessage {
  late final String id;
  final String matchId;
  final String senderId;
  final String senderUsername;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.senderUsername,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'matchId': matchId,
        'senderId': senderId,
        'senderUsername': senderUsername,
        'content': content,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'isRead': isRead,
      };

  factory ChatMessage.fromJson(String id, Map<dynamic, dynamic> json) {
    return ChatMessage(
      id: id,
      matchId: json['matchId'],
      senderId: json['senderId'],
      senderUsername: json['senderUsername'],
      content: json['content'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      isRead: json['isRead'] ?? false,
    );
  }
}

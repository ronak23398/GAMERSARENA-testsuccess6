class WalletTransaction {
  final String id;
  final String
      type; // 'deposit', 'withdrawal', 'freeze', 'unfreeze', 'win', 'loss'
  final double amount;
  final String description;
  final String? challengeId;
  final DateTime timestamp;
  final String status; // 'completed', 'pending', 'failed'

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    this.challengeId,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'description': description,
        'challengeId': challengeId,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'status': status,
      };

  factory WalletTransaction.fromJson(String id, Map<String, dynamic> json) {
    return WalletTransaction(
      id: id,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      challengeId: json['challengeId'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      status: json['status'] as String,
    );
  }
}

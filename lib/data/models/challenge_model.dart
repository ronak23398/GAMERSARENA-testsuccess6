class ChallengeModel {
  final String id;
  final String creatorId;
  final String? acceptorId;
  final String game;
  final String server;
  final double amount;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? winnerId;
  final Map<String, String>? results;

  ChallengeModel({
    required this.id,
    required this.creatorId,
    this.acceptorId,
    required this.game,
    required this.server,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.acceptedAt,
    this.completedAt,
    this.cancelledAt,
    this.winnerId,
    this.results,
  });

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id'] ?? '',
      creatorId: json['creatorId'] ?? '',
      acceptorId: json['acceptorId'],
      game: json['game'] ?? '',
      server: json['server'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'open',
      createdAt: _parseDateTime(json['createdAt']),
      expiresAt: _parseDateTime(json['expiresAt']),
      acceptedAt: json['acceptedAt'] != null
          ? _parseDateTime(json['acceptedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? _parseDateTime(json['completedAt'])
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? _parseDateTime(json['cancelledAt'])
          : null,
      winnerId: json['winnerId'],
      results: json['results'] != null
          ? Map<String, String>.from(json['results'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creatorId': creatorId,
      'acceptorId': acceptorId,
      'game': game,
      'server': server,
      'amount': amount,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'acceptedAt': acceptedAt?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'cancelledAt': cancelledAt?.millisecondsSinceEpoch,
      'winnerId': winnerId,
      'results': results,
    };
  }

  // Helper method to parse different datetime formats
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  // Create a copy of the model with updated fields
  ChallengeModel copyWith({
    String? id,
    String? creatorId,
    String? acceptorId,
    String? game,
    String? server,
    double? amount,
    String? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? winnerId,
    Map<String, String>? results,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      acceptorId: acceptorId ?? this.acceptorId,
      game: game ?? this.game,
      server: server ?? this.server,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      winnerId: winnerId ?? this.winnerId,
      results: results ?? this.results,
    );
  }

  // Helper method to check if challenge is expired
  bool isExpired() {
    return DateTime.now().isAfter(expiresAt);
  }

  // Helper method to check if challenge can be accepted
  bool canBeAccepted() {
    return status == 'open' && !isExpired();
  }

  // Helper method to check if winner can be declared
  bool canDeclareWinner() {
    return status == 'accepted' && !isExpired();
  }

  // Helper method to check if challenge can be cancelled
  bool canBeCancelled() {
    return (status == 'open' || status == 'accepted') && !isExpired();
  }

  @override
  String toString() {
    return 'ChallengeModel(id: $id, status: $status, game: $game, amount: $amount)';
  }
}

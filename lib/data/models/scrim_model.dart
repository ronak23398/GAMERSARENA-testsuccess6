class ScrimModel {
  final String id;
  final String creatorId;
  final String? acceptorId;
  final String game;
  final String server;
  final double amount;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String creatorTeamName;
  final String? acceptorTeamName;
  final String? creatorUsername;
  final String? acceptorUsername;
  final String? winnerId;
  final String? loserId;
  final String? finalOutcome;

  ScrimModel({
    required this.id,
    required this.creatorId,
    this.acceptorId,
    required this.game,
    required this.server,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.creatorTeamName,
    this.acceptorTeamName,
    this.creatorUsername,
    this.acceptorUsername,
    this.winnerId,
    this.loserId,
    this.finalOutcome,
  });

  factory ScrimModel.fromJson(Map<String, dynamic> json) {
    return ScrimModel(
      id: json['id'],
      creatorId: json['creatorId'],
      acceptorId: json['acceptorId'],
      game: json['game'],
      server: json['server'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      creatorTeamName: json['creatorTeamName'],
      acceptorTeamName: json['acceptorTeamName'],
      creatorUsername: json['creatorUsername'],
      acceptorUsername: json['acceptorUsername'],
      winnerId: json['winnerId'],
      loserId: json['loserId'],
      finalOutcome: json['finalOutcome'],
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
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'creatorTeamName': creatorTeamName,
      'acceptorTeamName': acceptorTeamName,
      'creatorUsername': creatorUsername,
      'acceptorUsername': acceptorUsername,
      'winnerId': winnerId,
      'loserId': loserId,
      'finalOutcome': finalOutcome,
    };
  }
}

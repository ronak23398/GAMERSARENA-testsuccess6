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
  });

  factory ScrimModel.fromJson(Map<String, dynamic> json) {
    return ScrimModel(
      id: json['id'],
      creatorId: json['creatorId'],
      acceptorId: json['acceptorId'],
      game: json['game'],
      server: json['server'],
      amount: (json['amount'] as num).toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      creatorTeamName: json['creatorTeamName'],
      acceptorTeamName: json['acceptorTeamName'],
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
    };
  }
}

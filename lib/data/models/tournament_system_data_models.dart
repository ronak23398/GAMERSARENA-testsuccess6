import 'package:firebase_database/firebase_database.dart';

enum TournamentStage { stage1, stage2, stage3, stage4, stage5Knockout }

enum MatchStatus { pending, inProgress, completed, disputed }

class TournamentPlayer {
  String userId;
  String username;
  int tokens;
  TournamentStage currentStage;
  int matchesWonInCurrentStage;
  bool isDisqualified;

  TournamentPlayer(
      {required this.userId,
      required this.username,
      this.tokens = 5,
      this.currentStage = TournamentStage.stage1,
      this.matchesWonInCurrentStage = 0,
      this.isDisqualified = false});

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'tokens': tokens,
        'currentStage': currentStage.index,
        'matchesWonInCurrentStage': matchesWonInCurrentStage,
        'isDisqualified': isDisqualified
      };

  factory TournamentPlayer.fromSnapshot(DataSnapshot snapshot, value) {
    final data = snapshot.value as Map<dynamic, dynamic>? ?? {};
    return TournamentPlayer(
      userId: snapshot.key ?? '',
      username: data['username'] ?? '',
      tokens: (data['tokens'] is int) ? data['tokens'] : 5,
      currentStage: data['currentStage'] is int
          ? TournamentStage.values[data['currentStage']]
          : TournamentStage.stage1,
      matchesWonInCurrentStage: (data['matchesWonInCurrentStage'] is int)
          ? data['matchesWonInCurrentStage']
          : 0,
      isDisqualified: data['isDisqualified'] == true,
    );
  }
}

class TournamentMatch {
  String? matchId;
  String player1Id;
  String player2Id;
  MatchStatus status;
  String? winnerId;
  TournamentStage stage;
  DateTime createdAt;

  TournamentMatch(
      {this.matchId,
      required this.player1Id,
      required this.player2Id,
      this.status = MatchStatus.pending,
      this.winnerId,
      required this.stage,
      DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'player1Id': player1Id,
        'player2Id': player2Id,
        'status': status.index,
        'winnerId': winnerId,
        'stage': stage.index,
        'createdAt': createdAt.toIso8601String()
      };

  factory TournamentMatch.fromSnapshot(DataSnapshot snapshot, value) {
    final data =
        snapshot.value is Map ? snapshot.value as Map<dynamic, dynamic> : {};
    return TournamentMatch(
      matchId: snapshot.key,
      player1Id: data['player1Id'] ?? '',
      player2Id: data['player2Id'] ?? '',
      status: data['status'] is int
          ? MatchStatus.values[data['status']]
          : MatchStatus.pending,
      winnerId:
          data['winnerId'] ?? '', // Ensure winnerId is treated as a String.
      stage: data['stage'] is int
          ? TournamentStage.values[data['stage']]
          : TournamentStage.stage1,
      createdAt: data['createdAt'] is String
          ? DateTime.tryParse(data['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

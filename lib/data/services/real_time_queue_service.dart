import 'package:firebase_database/firebase_database.dart';
import 'package:gamers_gram/data/models/arena_system_data_models.dart';
import 'dart:developer';

class TournamentQueueService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Stream for active tournament queue
  Stream<List<TournamentPlayer>> getTournamentQueue(TournamentStage stage) {
    return _database
        .child('tournament_queue')
        .orderByChild('currentStage')
        .equalTo(stage.index)
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return <TournamentPlayer>[];

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .map((entry) => TournamentPlayer.fromSnapshot(entry.key, entry.value))
          .where((player) => !player.isDisqualified)
          .toList();
    }).handleError((error) {
      log('Error fetching tournament queue: $error');
    });
  }

  // Add player to tournament queue
  Future<bool> joinTournamentQueue(TournamentPlayer player) async {
    try {
      await _database
          .child('tournament_queue')
          .child(player.userId)
          .set(player.toJson());
      return true;
    } catch (e) {
      log('Error joining tournament queue: $e');
      return false;
    }
  }

  // Remove player from tournament queue
  Future<bool> leaveTournamentQueue(String playerId) async {
    try {
      await _database.child('tournament_queue').child(playerId).remove();
      return true;
    } catch (e) {
      log('Error leaving tournament queue: $e');
      return false;
    }
  }

  // Match players in queue
  Stream<TournamentMatch?> matchPlayers(TournamentStage stage) {
    return getTournamentQueue(stage)
        .where((players) => players.length >= 2)
        .map((players) {
      // Filter eligible players
      final eligiblePlayers = players
          .where((player) =>
              !player.isDisqualified &&
              player.tokens > 0 &&
              player.matchesWonInCurrentStage < 3)
          .toList();

      if (eligiblePlayers.length < 2) return null;

      // Select first two players for a match
      final player1 = eligiblePlayers[0];
      final player2 = eligiblePlayers[1];

      final match = TournamentMatch(
        player1Id: player1.userId,
        player2Id: player2.userId,
        stage: stage,
      );

      // Remove matched players from the queue
      leaveTournamentQueue(player1.userId);
      leaveTournamentQueue(player2.userId);

      return match;
    }).handleError((error) {
      log('Error matching players: $error');
    });
  }

  // Save tournament match
  Future<bool> createTournamentMatch(TournamentMatch match) async {
    try {
      final matchRef = _database.child('tournament_matches').push();
      match.matchId = matchRef.key;
      await matchRef.set(match.toJson());
      return true;
    } catch (e) {
      log('Error creating tournament match: $e');
      return false;
    }
  }

  // Monitor active tournament matches
  Stream<List<TournamentMatch>> getActiveTournamentMatches(
      TournamentStage stage) {
    return _database
        .child('tournament_matches')
        .orderByChild('stage')
        .equalTo(stage.index)
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return <TournamentMatch>[];

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .map((entry) => TournamentMatch.fromSnapshot(entry.key, entry.value))
          .where((match) =>
              match.status != MatchStatus.completed && match.stage == stage)
          .toList();
    }).handleError((error) {
      log('Error fetching active tournament matches: $error');
    });
  }
}

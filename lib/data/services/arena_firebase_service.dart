import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gamers_gram/data/models/tournament_system_data_models.dart';

class TournamentFirebaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a new tournament match
  Future<String?> createTournamentMatch(TournamentMatch match) async {
    try {
      DatabaseReference matchRef = _database.child('tournament_matches').push();
      await matchRef.set(match.toJson());
      return matchRef.key;
    } catch (e) {
      print('Error creating tournament match: $e');
      return null;
    }
  }

  Future<void> updateMatchStatus(String matchId, MatchStatus status,
      {String? winnerId}) async {
    try {
      final updateData = {
        'status': status.index, // Status is an enum, stored as an int.
      };

      if (winnerId != null) {
        updateData['winnerId'] =
            winnerId as int; // Ensure winnerId is always treated as a String.
      }

      await _database
          .child('tournament_matches')
          .child(matchId)
          .update(updateData);
    } catch (e) {
      print('Error updating match status: $e');
      rethrow;
    }
  }

  /// Get active tournament matches for a player
  Stream<List<TournamentMatch>> getPlayerActiveTournamentMatches(
      String playerId) {
    return _database
        .child('tournament_matches')
        .orderByChild('player1Id')
        .equalTo(playerId)
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return <TournamentMatch>[];

      final matchesMap = event.snapshot.value as Map<dynamic, dynamic>? ?? {};

      return matchesMap.entries
          .map((entry) => TournamentMatch.fromSnapshot(
              event.snapshot.child(entry.key), entry.value))
          .where((match) => match.status.index < MatchStatus.completed.index)
          .toList();
    });
  }

  /// Update a player's tournament progress
  Future<void> updatePlayerTournamentProgress(TournamentPlayer player) async {
    try {
      await _database
          .child('tournament_players/${player.userId}')
          .update(player.toJson());
    } catch (e) {
      print('Error updating player tournament progress: $e');
      rethrow;
    }
  }

  /// Admin resolve a disputed match
  Future<void> adminResolveMatch(String matchId,
      {required String winnerId, bool refundTokens = false}) async {
    try {
      await _database.child('tournament_matches/$matchId').update({
        'status': MatchStatus.completed.index,
        'winnerId': winnerId,
      });

      if (refundTokens) {
        // Add refund logic here if needed
      }
    } catch (e) {
      print('Error resolving match by admin: $e');
      rethrow;
    }
  }

  /// Get a real-time tournament leaderboard
  Stream<List<TournamentPlayer>> getTournamentLeaderboard() {
    return _database
        .child('tournament_players')
        .orderByChild('tokens')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return <TournamentPlayer>[];

      final playersMap = event.snapshot.value as Map<dynamic, dynamic>? ?? {};

      return playersMap.entries
          .map((entry) => TournamentPlayer.fromSnapshot(
              event.snapshot.child(entry.key), entry.value))
          .toList()
          .reversed
          .toList(); // Reversed to show highest tokens first
    });
  }

  /// Find an available opponent for matchmaking
  Future<TournamentPlayer?> findAvailableOpponent(
      String currentPlayerId) async {
    try {
      DatabaseEvent event = await _database
          .child('tournament_players')
          .orderByChild('currentStage')
          .equalTo(TournamentStage.stage1.index)
          .once();

      if (event.snapshot.value != null) {
        final playersMap = event.snapshot.value as Map<dynamic, dynamic>? ?? {};

        for (var entry in playersMap.entries) {
          if (entry.key != currentPlayerId) {
            return TournamentPlayer.fromSnapshot(
                event.snapshot.child(entry.key), entry.value);
          }
        }
      }
      return null;
    } catch (e) {
      print('Error finding opponent: $e');
      return null;
    }
  }
}

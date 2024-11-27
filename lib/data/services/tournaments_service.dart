import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:gamers_gram/data/models/tournament_models.dart';

class TournamentService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<String?> createTournament(Tournament tournament) async {
    try {
      // Validate current user
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to create a tournament');
      }

      // Perform comprehensive validation
      final validationResult = TournamentValidator.validate(tournament);
      if (!validationResult.isValid) {
        print('Tournament validation failed: ${validationResult.errors}');
        return null;
      }

      // Create a new tournament reference
      final tournamentRef = _database.ref('tournaments').push();
      final newTournamentId = tournamentRef.key;

      if (newTournamentId == null) {
        throw Exception('Failed to generate tournament ID');
      }

      // Prepare tournament data
      final tournamentData = _prepareTournamentData(tournament, user.uid);

      await tournamentRef.set(tournamentData);

      // Update user's created tournaments
      final userTournamentsRef = _database
          .ref('users')
          .child(user.uid)
          .child('createdTournaments')
          .child(newTournamentId);

      await userTournamentsRef.set(true);

      return newTournamentId;
    } catch (e) {
      print('Tournament Creation Error: $e');
      return null;
    }
  }

  Map<String, dynamic> _prepareTournamentData(
      Tournament tournament, String userId) {
    return {
      'name': tournament.name,
      'game': tournament.game,
      'platform': tournament.platform,
      'entryFee': tournament.entryFee,
      'prizePool': tournament.prizePool,
      'format': tournament.format,
      'participationType': tournament.participationType,
      'maxParticipants': tournament.maxParticipants,
      'status': 'Open',
      'startDate': tournament.startDate.toIso8601String(),
      'registrationEndDate': tournament.registrationEndDate.toIso8601String(),
      'endDate': tournament.endDate.toIso8601String(),
      'createdBy': userId,
      'createdAt': DateTime.now().toIso8601String(),
      'rules': tournament.rules,
      'prizes': tournament.prizes,
      'participants': {
        userId: {
          'userId': userId,
          'joinedAt': DateTime.now().toIso8601String(),
          'status': 'active',
          'isCreator': true
        }
      }
    };
  }
}

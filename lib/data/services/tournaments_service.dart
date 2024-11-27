import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

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
      final validationResult = _validateTournamentData(tournament);
      if (!validationResult.isValid) {
        // Log validation errors
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

      // Use ref().set() instead of transaction for this scenario
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
      // Comprehensive error logging
      print('Tournament Creation Error: $e');

      // Optional: Log to a more robust error tracking service
      // FirebaseCrashlytics.instance.recordError(e, StackTrace.current);

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
      'rules': tournament.rules ?? [],
      'prizes': {
        'first': tournament.prizePool * 0.6,
        'second': tournament.prizePool * 0.3,
        'third': tournament.prizePool * 0.1,
      },
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

  ValidationResult _validateTournamentData(Tournament tournament) {
    final List<String> errors = [];

    // Comprehensive validation checks
    if (tournament.name.trim().isEmpty) {
      errors.add('Tournament name cannot be empty');
    }

    if (tournament.game.trim().isEmpty) {
      errors.add('Game name cannot be empty');
    }

    if (tournament.maxParticipants <= 1) {
      errors.add('Maximum participants must be at least 2');
    }

    final now = DateTime.now();

    // Registration date validations
    if (tournament.registrationEndDate.isBefore(now)) {
      errors.add('Registration end date must be in the future');
    }

    // Start date validations
    if (tournament.startDate.isBefore(now)) {
      errors.add('Tournament start date must be in the future');
    }

    // Date sequence validations
    if (tournament.registrationEndDate.isAfter(tournament.startDate)) {
      errors.add('Registration end date must be before tournament start date');
    }

    if (tournament.startDate.isAfter(tournament.endDate)) {
      errors.add('Tournament start date must be before end date');
    }

    // Prize pool validations
    if (tournament.prizePool <= 0) {
      errors.add('Prize pool must be greater than zero');
    }

    // Entry fee validations
    if (tournament.entryFee < 0) {
      errors.add('Entry fee cannot be negative');
    }

    return ValidationResult(errors.isEmpty, errors: errors);
  }
}

// Validation result class for detailed feedback
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult(this.isValid, {this.errors = const []});
}

// Tournament model with validation method
class Tournament {
  final String name;
  final String game;
  final String platform;
  final double entryFee;
  final double prizePool;
  final String format;
  final String participationType;
  final int maxParticipants;
  final DateTime startDate;
  final DateTime registrationEndDate;
  final DateTime endDate;
  final List<String>? rules;

  Tournament({
    required this.name,
    required this.game,
    required this.platform,
    required this.entryFee,
    required this.prizePool,
    required this.format,
    required this.participationType,
    required this.maxParticipants,
    required this.startDate,
    required this.registrationEndDate,
    required this.endDate,
    this.rules, required String status, required Map<String, double> prizes, required String id, required String createdBy,
  });

  // Optional: Model-level validation
  bool validate() {
    return TournamentService()._validateTournamentData(this).isValid;
  }
}

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gamers_gram/data/models/challenge_model.dart';
import 'package:gamers_gram/modules/wallet/controllers/wallet_controller.dart';
import 'package:get/get.dart';

class ChallengeController extends GetxController {
  final _challenges = <ChallengeModel>[].obs;
  final _db = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;

  // Get access to wallet controller
  final _walletController = Get.find<WalletController>();

  // Game and server options
  final List<String> games = ['Valorant', 'CS2', 'BGMI'];
  final Map<String, List<String>> serversByGame = {
    'Valorant': ['Mumbai', 'Singapore'],
    'CS2': ['Mumbai', 'Singapore'],
    'BGMI': ['India', 'Asia'],
  };

  final selectedGame = ''.obs;
  final selectedServer = ''.obs;
  final isProcessing = false.obs;

  // Add stream subscription for proper cleanup
  StreamSubscription<DatabaseEvent>? _challengesSubscription;

  @override
  void onInit() {
    super.onInit();
    _loadChallenges();
    selectedGame.value = games[0];
    selectedServer.value = serversByGame[games[0]]![0];
    _setupChallengeExpiryCheck();
    _setupChallengeOutcomeCheck(); // Add this line
  }

  @override
  void onClose() {
    _challengesSubscription?.cancel();
    super.onClose();
  }

  void _setupChallengeExpiryCheck() {
    print("setupchallengeexpirycheck started");
    // Use Timer instead of Future.periodic for better control
    Timer.periodic(const Duration(hours: 1), (_) => _checkExpiredChallenges());
  }

  void _loadChallenges() {
    try {
      _challengesSubscription = _db.child('challenges').onValue.listen((event) {
        if (event.snapshot.value != null) {
          final challenges = <ChallengeModel>[];
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);

          data.forEach((key, value) {
            try {
              final challenge =
                  ChallengeModel.fromJson(Map<String, dynamic>.from(value));
              if (challenge.status == 'open' ||
                  challenge.status == 'accepted') {
                challenges.add(challenge);
              }
            } catch (e) {
              print('Error parsing challenge: $e');
            }
          });

          _challenges.value = challenges;
        } else {
          _challenges.clear();
        }
      }, onError: (error) {
        print('Error loading challenges: $error');
        Get.snackbar('Error', 'Failed to load challenges');
      });
    } catch (e) {
      print('Error setting up challenges listener: $e');
      Get.snackbar('Error', 'Failed to initialize challenges');
    }
  }

  Future<bool> createChallenge(double amount) async {
    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'User not logged in');
      return false;
    }

    if (amount <= 0) {
      Get.snackbar('Error', 'Invalid amount');
      return false;
    }

    try {
      isProcessing.value = true;

      // Validate if user has sufficient balance
      final validation = await _walletController.validateTransaction(amount);
      if (!validation['isValid']) {
        Get.snackbar('Error', validation['message'] ?? 'Insufficient balance');
        return false;
      }

      // Create the challenge first
      final newChallengeRef = _db.child('challenges').push();
      final challenge = ChallengeModel(
        id: newChallengeRef.key!,
        creatorId: user.uid,
        game: selectedGame.value,
        server: selectedServer.value,
        amount: amount,
        status: 'open',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      // Use transaction to ensure atomicity
      await _db
          .child('challenges/${challenge.id}')
          .runTransaction((Object? post) {
        if (post == null) {
          return Transaction.success(challenge.toJson());
        }
        return Transaction.abort();
      });

      // Freeze the amount in user's wallet
      final frozen = await _walletController.freezeAmount(amount, challenge.id);
      if (!frozen) {
        // If freezing fails, delete the challenge
        await newChallengeRef.remove();
        Get.snackbar('Error', 'Failed to freeze amount for challenge');
        return false;
      }

      Get.snackbar('Success', 'Challenge created successfully');
      return true;
    } catch (e) {
      print('Error creating challenge: $e');
      Get.snackbar('Error', 'Failed to create challenge');
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  Future<bool> acceptChallenge(String challengeId) async {
    print("challenge accepted ");
    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'User not logged in');
      return false;
    }

    try {
      isProcessing.value = true;

      // Use transaction to ensure atomicity
      final result = await _db
          .child('challenges/$challengeId')
          .runTransaction((Object? post) {
        if (post == null) return Transaction.abort();

        final challengeData = Map<String, dynamic>.from(post as Map);

        if (challengeData['status'] != 'open' ||
            challengeData['creatorId'] == user.uid) {
          return Transaction.abort();
        }

        challengeData['acceptorId'] = user.uid;
        challengeData['status'] = 'accepted';
        challengeData['acceptedAt'] = ServerValue.timestamp;

        return Transaction.success(challengeData);
      });

      if (!result.committed) {
        Get.snackbar('Error',
            'dumbass you cant accept your own challenge , want to lose money go ahead and accept it , i dont care baka');
        return false;
      }

      final challengeData =
          Map<String, dynamic>.from(result.snapshot.value as Map);
      final amount = (challengeData['amount'] as num).toDouble();

      // Validate if user has sufficient balance
      final validation = await _walletController.validateTransaction(amount);
      if (!validation['isValid']) {
        // Rollback the challenge acceptance
        await _db.child('challenges/$challengeId').update({
          'acceptorId': null,
          'status': 'open',
          'acceptedAt': null,
        });
        Get.snackbar('Error', validation['message'] ?? 'Insufficient balance');
        return false;
      }

      // Freeze the matching amount from acceptor's wallet
      final frozen = await _walletController.freezeAmount(amount, challengeId);
      if (!frozen) {
        // Rollback the challenge acceptance
        await _db.child('challenges/$challengeId').update({
          'acceptorId': null,
          'status': 'open',
          'acceptedAt': null,
        });
        Get.snackbar('Error', 'Failed to freeze amount');
        return false;
      }

      // Remove any previous outcome data when challenge is accepted
      await _db.child('challenges/$challengeId').update(
          {'outcome': null, 'outcomeSenderId': null, 'outcomeTimestamp': null});

      Get.snackbar('Success', 'Challenge accepted successfully');
      return true;
    } catch (e) {
      print('Error accepting challenge: $e');
      Get.snackbar('Error', 'Failed to accept challenge');
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> cancelChallenge(String challengeId) async {
    try {
      isProcessing.value = true;

      final result = await _db
          .child('challenges/$challengeId')
          .runTransaction((Object? post) {
        if (post == null) return Transaction.abort();

        final challengeData = Map<String, dynamic>.from(post as Map);

        if (challengeData['status'] != 'open' &&
            challengeData['status'] != 'accepted') {
          return Transaction.abort();
        }

        challengeData['status'] = 'cancelled';
        challengeData['cancelledAt'] = ServerValue.timestamp;

        return Transaction.success(challengeData);
      });

      if (!result.committed) {
        Get.snackbar('Error', 'Cannot cancel this challenge');
        return;
      }

      final challengeData =
          Map<String, dynamic>.from(result.snapshot.value as Map);
      final creatorId = challengeData['creatorId'] as String;
      final acceptorId = challengeData['acceptorId'];

      // Release creator's frozen amount
      await _walletController.releaseFrozenAmount(challengeId, creatorId);

      // Release acceptor's frozen amount if challenge was accepted
      if (acceptorId != null) {
        await _walletController.releaseFrozenAmount(challengeId, acceptorId);
      }

      Get.snackbar(
        'Success',
        'Challenge cancelled and amounts released',
      );
    } catch (e) {
      print('Error cancelling challenge: $e');
      Get.snackbar('Error', 'Failed to cancel challenge');
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> _checkExpiredChallenges() async {
    print("_checkExpiredChallenges started");
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final snapshot = await _db
          .child('challenges')
          .orderByChild('status')
          .equalTo('open')
          .get();

      if (!snapshot.exists) return;

      final challenges = Map<String, dynamic>.from(snapshot.value as Map);

      for (var entry in challenges.entries) {
        final challenge = Map<String, dynamic>.from(entry.value);
        final expiresAt = challenge['expiresAt'] as int;

        if (now > expiresAt) {
          await cancelChallenge(entry.key);
        }
      }
    } catch (e) {
      print('Error checking expired challenges: $e');
    }
  }

  void updateSelectedGame(String game) {
    if (games.contains(game)) {
      selectedGame.value = game;
      selectedServer.value = serversByGame[game]![0];
    }
  }

  void updateSelectedServer(String server) {
    if (serversByGame[selectedGame.value]?.contains(server) ?? false) {
      selectedServer.value = server;
    }
  }

  List<ChallengeModel> get challenges => _challenges;

  Future<Map<String, dynamic>> resolveChallenge(String challengeId) async {
    try {
      print('Starting challenge resolution for challengeId: $challengeId');

      // Fetch the latest challenge data
      final challengeSnapshot =
          await _db.child('challenges').child(challengeId).get();
      print('Challenge snapshot exists: ${challengeSnapshot.exists}');

      if (!challengeSnapshot.exists) {
        print('Challenge not found for ID: $challengeId');
        return _createErrorResponse(
          'Challenge not found',
          'CHALLENGE_NOT_FOUND',
        );
      }

      // Convert snapshot to map
      final challengeData = Map<String, dynamic>.from(
        challengeSnapshot.value as Map<dynamic, dynamic>,
      );
      print('Challenge data retrieved: $challengeData');

      // Validate challenge is in a state that can be resolved
      final validationResult = _validateChallengeResolution(challengeData);
      print('Challenge validation result: ${validationResult['isValid']}');

      if (!validationResult['isValid']) {
        print('Challenge validation failed: ${validationResult['response']}');
        return validationResult['response'];
      }

      // Determine winner and loser
      final outcomeResult = _determineOutcome(challengeData);
      print('Outcome determination result: ${outcomeResult['success']}');

      if (!outcomeResult['success']) {
        print('Outcome determination failed: ${outcomeResult['response']}');
        return outcomeResult['response'];
      }

      final String winnerId = outcomeResult['winnerId'];
      final String loserId = outcomeResult['loserId'];
      print('Identified winnerId: $winnerId, loserId: $loserId');

      // Determine final outcome type
      final String finalOutcome =
          winnerId == challengeData['creatorId'] ? 'creatorWin' : 'acceptorWin';
      print('Final outcome determined: $finalOutcome');

      // Transfer winnings
      final transferResult = await _performWinningsTransfer(
          challengeId, winnerId, loserId, challengeData['amount']);
      print('Winnings transfer result: ${transferResult['success']}');

      if (!transferResult['success']) {
        print('Winnings transfer failed: $transferResult');
        return transferResult;
      }

      // Update challenge status in database
      print('Updating challenge status');
      await _updateChallengeStatus(
          challengeId, winnerId, loserId, finalOutcome);

      // Log successful resolution
      print('Logging challenge resolution');
      LoggingService().logChallengeResolution(
          challengeId: challengeId,
          winnerId: winnerId,
          loserId: loserId,
          amount: challengeData['amount']);

      print('Challenge resolved successfully');
      return {
        'success': true,
        'winnerId': winnerId,
        'loserId': loserId,
        'finalOutcome': finalOutcome,
        'message': 'Challenge resolved successfully'
      };
    } catch (e, stackTrace) {
      // Log unexpected errors
      print('Unexpected error during challenge resolution: $e');
      print('Stacktrace: $stackTrace');

      LoggingService().logError(
          context: 'Challenge Resolution', error: e, stackTrace: stackTrace);

      return _createErrorResponse(
          'Unexpected error during challenge resolution', 'UNEXPECTED_ERROR',
          additionalDetails: e.toString());
    }
  }

  Map<String, dynamic> _validateChallengeResolution(
      Map<String, dynamic> challengeData) {
    print('Starting challenge resolution validation');
    print('Challenge Data: $challengeData');

    // Check if challenge is already completed
    if (challengeData['status'] == 'completed') {
      print('Challenge already completed');
      return {
        'isValid': false,
        'response': _createErrorResponse(
            'Challenge already completed', 'CHALLENGE_ALREADY_COMPLETED')
      };
    }

    final int currentTime = DateTime.now().millisecondsSinceEpoch;
    final int expiresAt = challengeData['expiresAt'] ?? currentTime;
    print('Current Time: $currentTime, Expires At: $expiresAt');

    // Case 1: Only one user selected outcome
    if ((challengeData['firstUserOutcome'] == null) !=
        (challengeData['secondUserOutcome'] == null)) {
      print('Only one user selected outcome');
      final String? singleOutcome = challengeData['firstUserOutcome'] ??
          challengeData['secondUserOutcome'];
      print('Single Outcome: $singleOutcome');

      if (singleOutcome == 'win') {
        return {
          'isValid': true,
          'winner': singleOutcome == challengeData['firstUserOutcome']
              ? challengeData['firstUserOutcomeSenderId']
              : challengeData['creatorId'],
          'loserId': singleOutcome == challengeData['firstUserOutcome']
              ? challengeData['creatorId']
              : challengeData['firstUserOutcomeSenderId'],
          'resolution': 'SINGLE_USER_OUTCOME'
        };
      }

      if (singleOutcome == 'loss') {
        return {
          'isValid': true,
          'winner': singleOutcome == challengeData['firstUserOutcome']
              ? challengeData['creatorId']
              : challengeData['firstUserOutcomeSenderId'],
          'loserId': singleOutcome == challengeData['firstUserOutcome']
              ? challengeData['firstUserOutcomeSenderId']
              : challengeData['creatorId'],
          'resolution': 'SINGLE_USER_OUTCOME'
        };
      }
    }

    // Case 2: Both users selected outcome
    if (challengeData['firstUserOutcome'] != null &&
        challengeData['secondUserOutcome'] != null) {
      print('Both users selected outcomes');
      print('First User Outcome: ${challengeData['firstUserOutcome']}');
      print('Second User Outcome: ${challengeData['secondUserOutcome']}');

      // Both claim win - requires admin resolution
      if (challengeData['firstUserOutcome'] == 'win' &&
          challengeData['secondUserOutcome'] == 'win') {
        print('Both users claimed win - admin resolution required');
        return {
          'isValid': false,
          'response': _createErrorResponse(
              'Conflicting win claims require admin resolution',
              'ADMIN_RESOLUTION_REQUIRED')
        };
      }

      // Standard resolution logic
      if (challengeData['firstUserOutcome'] == 'win') {
        print('First user claimed win');
        return {
          'isValid': true,
          'winner': challengeData['firstUserOutcomeSenderId'],
          'resolution': 'STANDARD_RESOLUTION'
        };
      }

      if (challengeData['secondUserOutcome'] == 'win') {
        print('Second user claimed win');
        return {
          'isValid': true,
          'winner': challengeData['acceptorId'],
          'resolution': 'STANDARD_RESOLUTION'
        };
      }
    }

    // Fallback for unexpected scenarios
    print('Unexpected resolution state');
    return {
      'isValid': false,
      'response': _createErrorResponse(
          'Invalid challenge resolution state', 'INVALID_RESOLUTION')
    };
  }

  Map<String, dynamic> _determineOutcome(Map<String, dynamic> challengeData) {
    print('Entering _determineOutcome method');
    print('Challenge Data: $challengeData');

    final firstUserOutcome = challengeData['firstUserOutcome'];
    final secondUserOutcome = challengeData['secondUserOutcomeSenderOutcome'];
    final firstUserOutcomeSenderId = challengeData['firstUserOutcomeSenderId'];
    final secondUserOutcomeSenderId =
        challengeData['secondUserOutcomeSenderId'];

    // Explicitly get both user IDs
    final creatorId = challengeData['creatorId'];
    final acceptorId = challengeData['acceptorId'];

    print('First User Outcome: $firstUserOutcome');
    print('Second User Outcome: $secondUserOutcome');
    print('First User Outcome Sender ID: $firstUserOutcomeSenderId');
    print('Second User Outcome Sender ID: $secondUserOutcomeSenderId');
    print('Creator ID: $creatorId');
    print('Acceptor ID: $acceptorId');

    // If only one user has selected an outcome
    if ((firstUserOutcome == null) != (secondUserOutcome == null)) {
      print('Only one user has selected an outcome');

      final String? singleOutcome = firstUserOutcome ?? secondUserOutcome;
      final String? singleOutcomeSenderId = firstUserOutcome != null
          ? firstUserOutcomeSenderId
          : secondUserOutcomeSenderId;

      // Determine the other user's ID explicitly
      final String otherId =
          (singleOutcomeSenderId == creatorId) ? acceptorId : creatorId;

      print('Single Outcome: $singleOutcome');
      print('Single Outcome Sender ID: $singleOutcomeSenderId');
      print('Other User ID: $otherId');

      if (singleOutcome == 'win') {
        print('Single user claimed win');
        return {
          'success': true,
          'winnerId': singleOutcomeSenderId,
          'loserId': otherId
        };
      }

      if (singleOutcome == 'loss') {
        print('Single user claimed loss');
        return {
          'success': true,
          'winnerId': otherId,
          'loserId': singleOutcomeSenderId
        };
      }
    }

    // If outcomes are the same, return an error
    if (firstUserOutcome == secondUserOutcome) {
      print('Both users claimed the same outcome');
      return {
        'success': false,
        'response': _createErrorResponse(
            'Both users claimed the same outcome', 'SAME_OUTCOME')
      };
    }

    // Determine winner based on different outcomes
    String winnerId;
    String loserId;

    if (firstUserOutcome == 'win' && secondUserOutcome == 'loss') {
      print('First user claimed win, second user claimed loss');
      winnerId = firstUserOutcomeSenderId;
      loserId = secondUserOutcomeSenderId;
    } else if (firstUserOutcome == 'loss' && secondUserOutcome == 'win') {
      print('First user claimed loss, second user claimed win');
      winnerId = secondUserOutcomeSenderId;
      loserId = firstUserOutcomeSenderId;
    } else {
      print('Unexpected outcome combination');
      return {
        'success': false,
        'response': _createErrorResponse(
            'Invalid outcome combination', 'INVALID_OUTCOME')
      };
    }

    print('Final winner ID: $winnerId');
    print('Final loser ID: $loserId');
    return {'success': true, 'winnerId': winnerId, 'loserId': loserId};
  }

  /// Transfers winnings to the winner
  Future<Map<String, dynamic>> _performWinningsTransfer(
      String challengeId, String winnerId, String loserId, num amount) async {
    try {
      final transferred = await _walletController.transferWinnings(
        challengeId,
        winnerId,
        loserId,
      );

      if (!transferred) {
        return _createErrorResponse(
            'Failed to transfer winnings', 'TRANSFER_FAILED');
      }

      return {'success': true};
    } catch (e) {
      return _createErrorResponse('Winnings transfer error', 'TRANSFER_ERROR',
          additionalDetails: e.toString());
    }
  }

  /// Updates challenge status in the database
  Future<void> _updateChallengeStatus(String challengeId, String winnerId,
      String loserId, String finalOutcome) async {
    await _db.child('challenges/$challengeId').update({
      'status': 'completed',
      'winnerId': winnerId,
      'loserId': loserId,
      'finalOutcome': finalOutcome,
      'completedAt': ServerValue.timestamp
    });
  }

  /// Creates a standardized error response
  Map<String, dynamic> _createErrorResponse(String message, String errorCode,
      {String? additionalDetails}) {
    return {
      'success': false,
      'error': message,
      'errorCode': errorCode,
      if (additionalDetails != null) 'details': additionalDetails
    };
  }
}

void _setupChallengeOutcomeCheck() {
  print("_setupChallengeOutcomeCheck started in challengecontroller");
  // Check challenge outcomes every 5 minutes
  Timer.periodic(
      const Duration(minutes: 5), (_) => _setupChallengeOutcomeCheck());
}

/// Logging service to track challenge-related events
class LoggingService {
  void logChallengeResolution({
    required String challengeId,
    required String winnerId,
    required String loserId,
    required num amount,
  }) {
    // Implement your logging mechanism (e.g., Firebase Analytics, custom logging)
    debugPrint(
        'Challenge Resolved: $challengeId - Winner: $winnerId, Loser: $loserId, Amount: $amount');
  }

  void logError({
    required String context,
    required Object error,
    StackTrace? stackTrace,
  }) {
    // Implement error logging (e.g., Crashlytics, custom error tracking)
    debugPrint('Error in $context: $error');
    if (stackTrace != null) {
      debugPrint('Stack Trace: $stackTrace');
    }
  }
}

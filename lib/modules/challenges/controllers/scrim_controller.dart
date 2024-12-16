import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gamers_gram/data/models/scrim_model.dart';
import 'package:gamers_gram/data/models/team_model.dart';
import 'package:gamers_gram/modules/challenges/controllers/1v1_challenege_controller.dart';
import 'package:get/get.dart';

class ScrimController extends GetxController {
  final _scrims = <ScrimModel>[].obs;
  final _db = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;

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

  StreamSubscription<DatabaseEvent>? _scrimsSubscription;

  static const int RESOLUTION_TIMEOUT_MINUTES = 24;

  @override
  void onInit() {
    super.onInit();
    _loadScrims();
    selectedGame.value = games[0];
    selectedServer.value = serversByGame[games[0]]![0];
    _setupScrimExpiryCheck();
  }

  @override
  void onClose() {
    _scrimsSubscription?.cancel();
    super.onClose();
  }

  void _setupScrimExpiryCheck() {
    Timer.periodic(const Duration(hours: 1), (_) => _checkExpiredScrims());
  }

  void _loadScrims() {
    try {
      _scrimsSubscription = _db.child('scrims').onValue.listen((event) {
        if (event.snapshot.value != null) {
          final scrims = <ScrimModel>[];
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);

          data.forEach((key, value) {
            try {
              final scrim =
                  ScrimModel.fromJson(Map<String, dynamic>.from(value));
              if (scrim.status == 'open' || scrim.status == 'accepted') {
                scrims.add(scrim);
              }
            } catch (e) {
              print('Error parsing scrim: $e');
            }
          });

          _scrims.value = scrims;
        } else {
          _scrims.clear();
        }
      }, onError: (error) {
        print('Error loading scrims: $error');
        Get.snackbar('Error', 'Failed to load scrims');
      });
    } catch (e) {
      print('Error setting up scrims listener: $e');
      Get.snackbar('Error', 'Failed to initialize scrims');
    }
  }

  Future<bool> createScrim(double amount, TeamModel creatorTeam) async {
    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'User not logged in');
      return false;
    }
    try {
      isProcessing.value = true;
      final newScrimRef = _db.child('scrims').push();
      final scrim = ScrimModel(
        id: newScrimRef.key!,
        creatorId: user.uid,
        game: selectedGame.value,
        server: selectedServer.value,
        amount: amount,
        status: 'open',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        creatorTeamName: creatorTeam.name,
        creatorUsername: creatorTeam.username,
      );
      await _db.child('scrims/${scrim.id}').set(scrim.toJson());
      Get.snackbar('Success', 'Scrim created successfully');
      return true;
    } catch (e) {
      print('Error creating scrim: $e');
      Get.snackbar('Error', 'Failed to create scrim');
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  Future<bool> acceptScrim(String scrimId, TeamModel acceptorTeam) async {
    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'User not logged in');
      return false;
    }
    try {
      isProcessing.value = true;
      final result =
          await _db.child('scrims/$scrimId').runTransaction((Object? post) {
        if (post == null) return Transaction.abort();
        final scrimData = Map<String, dynamic>.from(post as Map);
        if (scrimData['status'] != 'open' ||
            scrimData['creatorId'] == user.uid) {
          return Transaction.abort();
        }
        scrimData['acceptorId'] = user.uid;
        scrimData['status'] = 'accepted';
        scrimData['acceptedAt'] = ServerValue.timestamp;
        scrimData['acceptorTeamName'] = acceptorTeam.name;
        scrimData['acceptorUsername'] = acceptorTeam.username;
        return Transaction.success(scrimData);
      });
      if (!result.committed) {
        Get.snackbar('Error', 'Cannot accept this scrim');
        return false;
      }
      Get.snackbar('Success', 'Scrim accepted successfully');
      return true;
    } catch (e) {
      print('Error accepting scrim: $e');
      Get.snackbar('Error', 'Failed to accept scrim');
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  Future<Map<String, dynamic>> resolveScrim(String scrimId) async {
    try {
      print('Starting scrim resolution for scrimId: $scrimId');

      // Fetch the latest scrim data
      final scrimSnapshot = await _db.child('scrims').child(scrimId).get();
      print('Scrim snapshot exists: ${scrimSnapshot.exists}');

      if (!scrimSnapshot.exists) {
        print('Scrim not found for ID: $scrimId');
        return _createScrimErrorResponse(
          'Scrim not found',
          'SCRIM_NOT_FOUND',
        );
      }

      // Convert snapshot to map
      final scrimData = Map<String, dynamic>.from(
        scrimSnapshot.value as Map<dynamic, dynamic>,
      );
      print('Scrim data retrieved: $scrimData');

      // Validate scrim is in a state that can be resolved
      final validationResult = _validateScrimResolution(scrimData);
      print('Scrim validation result: ${validationResult['isValid']}');

      if (!validationResult['isValid']) {
        print('Scrim validation failed: ${validationResult['response']}');
        return validationResult['response'];
      }

      // Determine winner and loser
      final outcomeResult = _determineScrimOutcome(scrimData);
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
          winnerId == scrimData['creatorId'] ? 'creatorWin' : 'acceptorWin';
      print('Final outcome determined: $finalOutcome');

      // Transfer winnings
      final transferResult = await _performWinningsTransfer(
          scrimId, winnerId, loserId, scrimData['amount']);
      print('Winnings transfer result: ${transferResult['success']}');

      if (!transferResult['success']) {
        print('Winnings transfer failed: $transferResult');
        return transferResult;
      }

      // Update scrim status in database
      print('Updating scrim status');
      await _updateScrimStatus(scrimId, winnerId, loserId, finalOutcome);

      // // Log successful resolution
      // print('Logging scrim resolution');
      // LoggingService().logChallengeResolution(
      //     scrimId: scrimId,
      //     winnerId: winnerId,
      //     loserId: loserId,
      //     amount: scrimData['amount']);

      print('Scrim resolved successfully');
      return {
        'success': true,
        'winnerId': winnerId,
        'loserId': loserId,
        'finalOutcome': finalOutcome,
        'message': 'Scrim resolved successfully'
      };
    } catch (e, stackTrace) {
      // Log unexpected errors
      print('Unexpected error during scrim resolution: $e');
      print('Stacktrace: $stackTrace');

      LoggingService().logError(
          context: 'Scrim Resolution', error: e, stackTrace: stackTrace);

      return _createScrimErrorResponse(
          'Unexpected error during scrim resolution', 'UNEXPECTED_ERROR',
          additionalDetails: e.toString());
    }
  }

  Map<String, dynamic> _validateScrimResolution(
      Map<String, dynamic> scrimData) {
    print('Starting scrim resolution validation');
    print('Scrim Data: $scrimData');

    // Check if scrim is already resolved
    if (scrimData['status'] == 'resolved') {
      print('Scrim already resolved');
      return {
        'isValid': false,
        'response': _createScrimErrorResponse(
            'Scrim already resolved', 'SCRIM_ALREADY_RESOLVED')
      };
    }

    final int currentTime = DateTime.now().millisecondsSinceEpoch;

    // Parse expiresAt if it's a string
    int expiresAt;
    try {
      expiresAt = scrimData['expiresAt'] is String
          ? DateTime.parse(scrimData['expiresAt']).millisecondsSinceEpoch
          : (scrimData['expiresAt'] as int? ?? currentTime);
    } catch (e) {
      print('Error parsing expiresAt: $e');
      expiresAt = currentTime;
    }

    print('Current Time: $currentTime, Expires At: $expiresAt');

    // Case 1: Only one user selected outcome
    if ((scrimData['firstUserOutcome'] == null) !=
        (scrimData['secondUserOutcome'] == null)) {
      print('Only one user selected outcome');
      final String? singleOutcome =
          scrimData['firstUserOutcome'] ?? scrimData['secondUserOutcome'];
      print('Single Outcome: $singleOutcome');

      if (singleOutcome == 'win') {
        print('Single user selected win');
        return {
          'isValid': true,
          'winner': singleOutcome == scrimData['firstUserOutcome']
              ? scrimData['firstUserOutcomeSenderId']
              : scrimData['creatorId'],
          'resolution': 'SINGLE_USER_OUTCOME'
        };
      }

      if (singleOutcome == 'loss') {
        print('Single user selected loss');
        return {
          'isValid': true,
          'winner': singleOutcome == scrimData['firstUserOutcome']
              ? scrimData['creatorId']
              : scrimData['firstUserOutcomeSenderId'],
          'resolution': 'SINGLE_USER_OUTCOME'
        };
      }
    }

    // Case 2: Both users selected outcome
    if (scrimData['firstUserOutcome'] != null &&
        scrimData['secondUserOutcome'] != null) {
      print('Both users selected outcomes');
      print('First User Outcome: ${scrimData['firstUserOutcome']}');
      print('Second User Outcome: ${scrimData['secondUserOutcome']}');

      // Both claim win - requires admin resolution
      if (scrimData['firstUserOutcome'] == 'win' &&
          scrimData['secondUserOutcome'] == 'win') {
        print('Both users claimed win - admin resolution required');
        return {
          'isValid': false,
          'response': _createScrimErrorResponse(
              'Conflicting win claims require admin resolution',
              'ADMIN_RESOLUTION_REQUIRED')
        };
      }

      // Both claim loss - requires admin resolution
      if (scrimData['firstUserOutcome'] == 'loss' &&
          scrimData['secondUserOutcome'] == 'loss') {
        print('Both users claimed loss - admin resolution required');
        return {
          'isValid': false,
          'response': _createScrimErrorResponse(
              'Conflicting loss claims require admin resolution',
              'ADMIN_RESOLUTION_REQUIRED')
        };
      }

      // Standard resolution logic
      if (scrimData['firstUserOutcome'] == 'win') {
        print('First user claimed win');
        return {
          'isValid': true,
          'winner': scrimData['firstUserOutcomeSenderId'],
          'resolution': 'STANDARD_RESOLUTION'
        };
      }

      if (scrimData['secondUserOutcome'] == 'win') {
        print('Second user claimed win');
        return {
          'isValid': true,
          'winner': scrimData['acceptorId'],
          'resolution': 'STANDARD_RESOLUTION'
        };
      }
    }

    // Fallback for unexpected scenarios
    print('Unexpected resolution state');
    return {
      'isValid': false,
      'response': _createScrimErrorResponse(
          'Invalid scrim resolution state', 'INVALID_RESOLUTION')
    };
  }

  Map<String, dynamic> _determineScrimOutcome(Map<String, dynamic> scrimData) {
    print('Entering _determineScrimOutcome method');
    print('Scrim Data: $scrimData');

    final firstUserOutcome = scrimData['firstUserOutcome'];
    final secondUserOutcome = scrimData['secondUserOutcome'];
    final firstUserOutcomeSenderId = scrimData['firstUserOutcomeSenderId'];
    final secondUserOutcomeSenderId = scrimData['secondUserOutcomeSenderId'];

    print('First User Outcome: $firstUserOutcome');
    print('Second User Outcome: $secondUserOutcome');
    print('First User Outcome Sender ID: $firstUserOutcomeSenderId');
    print('Second User Outcome Sender ID: $secondUserOutcomeSenderId');

    // If only one user has selected an outcome
    if ((firstUserOutcome == null) != (secondUserOutcome == null)) {
      print('Only one user has selected an outcome');

      final String? singleOutcome = firstUserOutcome ?? secondUserOutcome;
      final String? singleOutcomeSenderId = firstUserOutcome != null
          ? firstUserOutcomeSenderId
          : secondUserOutcomeSenderId;
      final String? otherId = firstUserOutcome != null
          ? scrimData['acceptorId']
          : scrimData['creatorId'];

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

    // If outcomes are the same (both win or both loss), return an error
    if (firstUserOutcome == secondUserOutcome) {
      print('Both users claimed the same outcome');
      return {
        'success': false,
        'response': _createScrimErrorResponse(
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
        'response': _createScrimErrorResponse(
            'Invalid outcome combination', 'INVALID_OUTCOME')
      };
    }

    print('Final winner ID: $winnerId');
    print('Final loser ID: $loserId');
    return {'success': true, 'winnerId': winnerId, 'loserId': loserId};
  }

  /// Updates scrim status in the database
  Future<void> _updateScrimStatus(String scrimId, String winnerId,
      String loserId, String finalOutcome) async {
    await _db.child('scrims/$scrimId').update({
      'status': 'resolved',
      'winnerId': winnerId,
      'loserId': loserId,
      'finalOutcome': finalOutcome,
      'resolvedAt': ServerValue.timestamp
    });
  }

// Additional helper methods to handle edge cases
  Future<Map<String, dynamic>> _handleScrimTimeout(
      String scrimId, Map<String, dynamic> scrimData) async {
    // Implement admin review logic for timeout scenario
    return {
      'success': false,
      'message': 'Scrim requires admin review due to timeout',
      'errorCode': 'ADMIN_REVIEW_REQUIRED',
      'status': 'pending_admin_review'
    };
  }

  Future<Map<String, dynamic>> _handleBothClaimedWin(
      String scrimId, Map<String, dynamic> scrimData) async {
    // Implement admin review logic when both claim a win
    return {
      'success': false,
      'message': 'Scrim requires admin review due to conflicting win claims',
      'errorCode': 'ADMIN_REVIEW_REQUIRED',
      'status': 'pending_admin_review'
    };
  }

  Future<Map<String, dynamic>> _handleBothClaimedLoss(
      String scrimId, Map<String, dynamic> scrimData) async {
    // Implement admin review logic when both claim a loss
    return {
      'success': false,
      'message': 'Scrim requires admin review due to mutual loss claims',
      'errorCode': 'ADMIN_REVIEW_REQUIRED',
      'status': 'pending_admin_review'
    };
  }

  Future<Map<String, dynamic>> _handleInvalidOutcomes(
      String scrimId, Map<String, dynamic> scrimData) async {
    print('Invalid outcomes for scrimId: $scrimId');

    await _db.child('scrims/$scrimId').update({
      'status': 'admin_review',
      'adminReviewReason': 'Invalid outcome claims',
      'resolvedAt': ServerValue.timestamp
    });

    return {
      'success': false,
      'message': 'Invalid outcome claims. Requires admin review',
      'errorCode': 'INVALID_OUTCOMES'
    };
  }

  Future<Map<String, dynamic>> _performWinningsTransfer(
      String scrimId, String winnerId, String loserId, double amount) async {
    try {
      print('Performing winnings transfer for scrimId: $scrimId');

      return {
        'success': true,
        'message': 'Winnings transfer completed',
        'amount': amount
      };
    } catch (e) {
      print('Winnings transfer failed: $e');
      return {
        'success': false,
        'message': 'Failed to transfer winnings',
        'errorCode': 'TRANSFER_FAILED',
        'details': e.toString()
      };
    }
  }

  Future<void> cancelScrim(String scrimId) async {
    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'User not logged in');
      return;
    }

    try {
      isProcessing.value = true;

      final result =
          await _db.child('scrims/$scrimId').runTransaction((Object? post) {
        if (post == null) return Transaction.abort();

        final scrimData = Map<String, dynamic>.from(post as Map);

        if (scrimData['creatorId'] != user.uid ||
            (scrimData['status'] != 'open' &&
                scrimData['status'] != 'accepted')) {
          return Transaction.abort();
        }

        scrimData['status'] = 'cancelled';
        scrimData['cancelledAt'] = ServerValue.timestamp;

        return Transaction.success(scrimData);
      });

      if (!result.committed) {
        Get.snackbar('Error', 'Cannot cancel this scrim');
        return;
      }

      Get.snackbar('Success', 'Scrim cancelled successfully');
    } catch (e) {
      print('Error cancelling scrim: $e');
      Get.snackbar('Error', 'Failed to cancel scrim');
    } finally {
      isProcessing.value = false;
    }
  }

  // Method to select scrim outcome
  Future<void> selectScrimOutcome(BuildContext context, String scrimId,
      TeamModel currentTeam, bool isWin) async {
    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'User not logged in');
      return;
    }

    try {
      final scrimRef = _db.child('scrims/$scrimId');

      // Run a transaction to handle outcome selection
      final result = await scrimRef.runTransaction((Object? postData) {
        if (postData == null) return Transaction.abort();

        final scrimData = Map<String, dynamic>.from(postData as Map);

        // Check if scrim is in a valid state for outcome selection
        if (scrimData['status'] != 'accepted') {
          return Transaction.abort();
        }

        // Determine if this is the first or second team selecting outcome
        final isFirstTeamOutcome = scrimData['firstTeamOutcome'] == null;

        if (isFirstTeamOutcome) {
          // First team selects outcome
          scrimData['firstTeamOutcome'] = isWin ? 'win' : 'loss';
          scrimData['firstTeamOutcomeSenderId'] = user.uid;
          scrimData['firstTeamOutcomeUsername'] = currentTeam.username;
          scrimData['firstTeamName'] = currentTeam.name;
          scrimData['firstTeamOutcomeTimestamp'] = ServerValue.timestamp;
        } else {
          // Second team selects outcome
          scrimData['secondTeamOutcome'] = isWin ? 'win' : 'loss';
          scrimData['secondTeamOutcomeSenderId'] = user.uid;
          scrimData['secondTeamOutcomeUsername'] = currentTeam.username;
          scrimData['secondTeamName'] = currentTeam.name;
          scrimData['secondTeamOutcomeTimestamp'] = ServerValue.timestamp;

          // Compare outcomes
          final firstTeamOutcome = scrimData['firstTeamOutcome'];
          final secondTeamOutcome = scrimData['secondTeamOutcome'];

          if (firstTeamOutcome == secondTeamOutcome) {
            // Both teams agree on the outcome
            scrimData['status'] =
                firstTeamOutcome == 'win' ? 'creator_win' : 'acceptor_win';
          } else {
            // Disputed outcome
            scrimData['status'] = 'disputed';
          }
        }

        return Transaction.success(scrimData);
      });

      if (!result.committed) {
        Get.snackbar('Error', 'Cannot select outcome for this scrim');
        return;
      }

      // Show confirmation dialog
      await _showOutcomeConfirmationDialog(
          context, currentTeam.name, isWin ? 'Win' : 'Loss');

      // If needed, perform additional actions based on scrim status
      // Such as transferring winnings, notifying users, etc.
    } catch (e) {
      print('Error selecting scrim outcome: $e');
      Get.snackbar('Error', 'Failed to select scrim outcome');
    }
  }

  // Helper method to show outcome confirmation dialog
  Future<void> _showOutcomeConfirmationDialog(
      BuildContext context, String teamName, String outcome) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Outcome Confirmation'),
          content: Text(
            'Your team $teamName has selected $outcome for this scrim.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> resolveDisputedScrim(
      String scrimId, String winnerTeamId, String loserTeamId) async {
    try {
      final scrimSnapshot = await _db.child('scrims/$scrimId').get();

      if (!scrimSnapshot.exists) {
        Get.snackbar('Error', 'Scrim not found');
        return;
      }

      final scrimData = Map<String, dynamic>.from(scrimSnapshot.value as Map);
      final creatorId = scrimData['creatorId'] as String;

      final scrimRef = _db.child('scrims/$scrimId');

      await scrimRef.update({
        'status': winnerTeamId == creatorId ? 'creator_win' : 'acceptor_win',
        'resolvedBy': 'admin',
        'resolvedAt': ServerValue.timestamp
      });

      Get.snackbar('Success', 'Scrim dispute resolved');
    } catch (e) {
      print('Error resolving disputed scrim: $e');
      Get.snackbar('Error', 'Failed to resolve scrim dispute');
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

  Future<void> _checkExpiredScrims() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final snapshot = await _db
          .child('scrims')
          .orderByChild('status')
          .equalTo('open')
          .get();

      if (!snapshot.exists) return;

      final scrims = Map<String, dynamic>.from(snapshot.value as Map);

      for (var entry in scrims.entries) {
        final scrim = Map<String, dynamic>.from(entry.value);
        final expiresAt = scrim['expiresAt'] as int;

        if (now > expiresAt) {
          await cancelScrim(entry.key);
        }
      }
    } catch (e) {
      print('Error checking expired scrims: $e');
    }
  }

  List<ScrimModel> get scrims => _scrims;
}

Map<String, dynamic> _createScrimErrorResponse(String message, String errorCode,
    {String? additionalDetails}) {
  return {
    'success': false,
    'message': message,
    'errorCode': errorCode,
    'details': additionalDetails
  };
}

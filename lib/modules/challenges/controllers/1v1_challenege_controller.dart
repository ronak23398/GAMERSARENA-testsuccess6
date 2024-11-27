import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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

  Future<bool> declareWinner(String challengeId, String winnerId) async {
    try {
      isProcessing.value = true;

      final result = await _db
          .child('challenges/$challengeId')
          .runTransaction((Object? post) {
        if (post == null) return Transaction.abort();

        final challengeData = Map<String, dynamic>.from(post as Map);

        if (challengeData['status'] != 'accepted') {
          return Transaction.abort();
        }

        final creatorId = challengeData['creatorId'] as String;
        final acceptorId = challengeData['acceptorId'] as String;

        if (winnerId != creatorId && winnerId != acceptorId) {
          return Transaction.abort();
        }

        challengeData['status'] = 'completed';
        challengeData['winnerId'] = winnerId;
        challengeData['completedAt'] = ServerValue.timestamp;

        return Transaction.success(challengeData);
      });

      if (!result.committed) {
        Get.snackbar('Error', 'Cannot declare winner for this challenge');
        return false;
      }

      final challengeData =
          Map<String, dynamic>.from(result.snapshot.value as Map);
      final creatorId = challengeData['creatorId'] as String;
      final acceptorId = challengeData['acceptorId'] as String;
      final loserId = winnerId == creatorId ? acceptorId : creatorId;

      // Transfer winnings
      final transferred = await _walletController.transferWinnings(
        challengeId,
        winnerId,
        loserId,
      );

      if (!transferred) {
        // Rollback the winner declaration
        await _db.child('challenges/$challengeId').update({
          'status': 'accepted',
          'winnerId': null,
          'completedAt': null,
        });
        Get.snackbar('Error', 'Failed to transfer winnings');
        return false;
      }

      Get.snackbar('Success', 'Winner declared and winnings transferred');
      return true;
    } catch (e) {
      print('Error declaring winner: $e');
      Get.snackbar('Error', 'Failed to declare winner');
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

  Future<void> checkChallengeOutcome() async {
    try {
      // Query for challenges in 'accepted' status with an outcome
      final snapshot = await _db
          .child('challenges')
          .orderByChild('status')
          .equalTo('accepted')
          .get();

      if (!snapshot.exists) return;

      final challenges = Map<String, dynamic>.from(snapshot.value as Map);

      for (var entry in challenges.entries) {
        final challengeData = Map<String, dynamic>.from(entry.value);

        // Check if outcome has been selected
        if (challengeData.containsKey('outcome') &&
            challengeData.containsKey('outcomeTimestamp')) {
          final outcomeTimestamp = challengeData['outcomeTimestamp'];
          final outcomeSenderId = challengeData['outcomeSenderId'];
          final currentTime = DateTime.now().millisecondsSinceEpoch;

          // Check if 10 minutes have passed since outcome selection
          if (currentTime - outcomeTimestamp > 600000) {
            // 10 minutes in milliseconds
            await _resolveChallenge(entry.key, challengeData);
          }
        }
      }
    } catch (e) {
      print('Error checking challenge outcomes: $e');
    }
  }

  Future<void> _resolveChallenge(
      String challengeId, Map<String, dynamic> challengeData) async {
    try {
      // Determine winner based on outcome
      final outcomeSenderId = challengeData['outcomeSenderId'];
      final creatorId = challengeData['creatorId'];
      final acceptorId = challengeData['acceptorId'];
      final outcome = challengeData['outcome'];

      String winnerId;
      String loserId;

      if (outcome == 'win') {
        // If outcome sender believes they won
        winnerId = outcomeSenderId;
        loserId = outcomeSenderId == creatorId ? acceptorId : creatorId;
      } else {
        // If outcome sender believes they lost
        loserId = outcomeSenderId;
        winnerId = outcomeSenderId == creatorId ? acceptorId : creatorId;
      }

      // Transfer winnings
      final transferred = await _walletController.transferWinnings(
        challengeId,
        winnerId,
        loserId,
      );

      if (transferred) {
        // Update challenge status
        await _db.child('challenges/$challengeId').update({
          'status': 'completed',
          'winnerId': winnerId,
          'completedAt': ServerValue.timestamp
        });
      }
    } catch (e) {
      print('Error resolving challenge: $e');
    }
  }

  void _setupChallengeOutcomeCheck() {
    // Check challenge outcomes every 5 minutes
    Timer.periodic(const Duration(minutes: 5), (_) => checkChallengeOutcome());
  }
}

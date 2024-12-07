import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gamers_gram/modules/challenges/controllers/1v1_challenege_controller.dart';
import 'package:gamers_gram/modules/wallet/controllers/wallet_controller.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ChallengeChatController extends GetxController {
  final String challengeId;
  final String opponentId;

  final Rx<User?> _currentUser = Rx<User?>(FirebaseAuth.instance.currentUser);
  final _database = FirebaseDatabase.instance.ref();
  final _walletController = Get.find<WalletController>();

  // Appwrite dependencies
  final Client _client;
  final Storage _storage;

  ChallengeChatController({
    required this.challengeId,
    required this.opponentId,
    required Client client,
    required Storage storage,
  })  : _client = client,
        _storage = storage;

  final RxList<dynamic> messages = <dynamic>[].obs;
  final TextEditingController messageController = TextEditingController();

  // Outcome and timer-related observables
  Rx<DateTime?> outcomeSelectionTime = Rx<DateTime?>(null);
  RxBool isTimerRunning = RxBool(false);
  RxBool hasSelectedOutcome = RxBool(false);
  RxString currentOutcome = RxString('');
  RxString outcomeSelectedBy = RxString('');
  RxBool bothClaimedWin = RxBool(false);

  // Timer for periodic updates
  Timer? _progressTimer;

  // Total time for outcome selection
  final Duration totalTime = const Duration(minutes: 1);

  @override
  void onInit() {
    super.onInit();
    _loadChatMessages();
    _monitorChallengeOutcome();
  }

  void _loadChatMessages() {
    _database
        .child('challenge_chats/$challengeId/messages')
        .orderByChild('timestamp')
        .onChildAdded
        .listen((event) {
      if (event.snapshot.value != null) {
        final newMessage = {
          ...?event.snapshot.value as Map,
          'key': event.snapshot.key
        };
        messages.insert(0, newMessage);
      }
    });
  }

  void _monitorChallengeOutcome() {
    print("monitorchallengeoutcome started");
    _database.child('challenges/$challengeId').onValue.listen((event) {
      final challengeData = event.snapshot.value as Map?;

      if (challengeData != null) {
        // Check if outcomes have been selected
        if (challengeData.containsKey('firstUserOutcome') &&
            challengeData.containsKey('firstUserOutcomeTimestamp')) {
          hasSelectedOutcome.value = true;
          currentOutcome.value = challengeData['firstUserOutcome'] ?? '';
          outcomeSelectedBy.value =
              challengeData['firstUserOutcomeSenderId'] ?? '';

          // Start timer when first outcome is selected
          dynamic timestamp = challengeData['firstUserOutcomeTimestamp'];
          if (timestamp != null) {
            outcomeSelectionTime.value = DateTime.fromMillisecondsSinceEpoch(
                int.tryParse(timestamp.toString()) ?? 0);
            _startTimer();
          }

          // Check for second user's outcome
          if (challengeData.containsKey('secondUserOutcome')) {
            final secondUserOutcome = challengeData['secondUserOutcome'];
            final firstUserOutcome = challengeData['firstUserOutcome'];

            if (firstUserOutcome == 'win' && secondUserOutcome == 'win') {
              bothClaimedWin.value = true;
            }
          }
        }
      }
    });
  }

  void _startTimer() {
    print("timer started");
    _progressTimer?.cancel();

    if (outcomeSelectionTime.value != null) {
      isTimerRunning.value = true;

      _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final now = DateTime.now();
        final difference = now.difference(outcomeSelectionTime.value!);

        if (difference >= totalTime) {
          _handleTimerExpiration();
          timer.cancel();
        }

        update(); // Force UI update
      });
    }
  }

  void _handleTimerExpiration() async {
    print("timer stopped");

    try {
      // First, fetch the complete challenge data
      final challengeSnapshot =
          await _database.child('challenges/$challengeId').get();
      final challengeData = challengeSnapshot.value as Map?;
      print(" datat fetched from firebase $challengeData");

      if (challengeData == null) {
        print('No challenge data found');
        return;
      }

      // Prepare resolution data
      final Map<String, dynamic> resolutionData = {
        'creatorId': challengeData['creatorId'],
        'acceptorId': challengeData['acceptorId'],
        'firstUserOutcome': currentOutcome.value,
        'secondUserOutcome': 'loss', // Since no second outcome was selected
        'firstUserOutcomeSenderId': outcomeSelectedBy.value,
        'secondUserOutcomeSenderId':
            challengeData['acceptorId'] != outcomeSelectedBy.value
                ? challengeData['acceptorId']
                : challengeData['creatorId']
      };

      // Update challenge status
      await _database.child('challenges/$challengeId').update({
        'finalOutcome': currentOutcome.value,
        'winnerId': outcomeSelectedBy.value,
        'status': 'completed',
        'secondUserOutcome': 'loss'
      });
      print("updating challenge status ");

      // Resolve challenge with complete data
      await _resolveChallenge(challengeId, resolutionData);
      print("resolvechallenge started");

      isTimerRunning.value = false;
      update();
    } catch (e) {
      print('Error in timer expiration: $e');
    }
  }

  void selectOutcome(BuildContext context, bool isWin) {
    print("outcome selected ");
    // Check if this is the first or second user selecting outcome
    final isFirstUser = !hasSelectedOutcome.value;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Outcome'),
        content: Text(
          'Are you sure you want to declare this as a ${isWin ? 'Win' : 'Loss'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (isFirstUser) {
                // First user selects outcome
                _database.child('challenges/$challengeId').update({
                  'firstUserOutcome': isWin ? 'win' : 'loss',
                  'firstUserOutcomeSenderId': _currentUser.value?.uid,
                  'firstUserOutcomeTimestamp': ServerValue.timestamp
                });

                // Set the outcome selection time
                outcomeSelectionTime.value = DateTime.now();
                hasSelectedOutcome.value = true;
                currentOutcome.value = isWin ? 'win' : 'loss';
                outcomeSelectedBy.value = _currentUser.value?.uid ?? '';

                // Start the timer
                _startTimer();
              } else {
                print("outcome seleced by second user");
                // Second user selects outcome
                _database.child('challenges/$challengeId').update({
                  'secondUserOutcome': isWin ? 'win' : 'loss',
                  'secondUserOutcomeSenderId': _currentUser.value?.uid,
                });

                // Retrieve first user's outcome
                final firstUserOutcome = currentOutcome.value;
                final secondUserOutcome = isWin ? 'win' : 'loss';

                // Resolve challenge based on outcomes
                if (firstUserOutcome == secondUserOutcome) {
                  // Both claim win or both claim loss
                  _handleBothClaimedSameOutcome(context);
                } else {
                  // Different outcomes - proceed with challenge resolution

                  ChallengeController().resolveChallenge(challengeId, {});
                }

                Navigator.pop(context);
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _resolveChallenge(
      String challengeId, Map<String, dynamic> resolutionData) async {
    try {
      final creatorId = resolutionData['creatorId'];
      final acceptorId = resolutionData['acceptorId'];
      final firstUserOutcome = resolutionData['firstUserOutcome'];
      final secondUserOutcome = resolutionData['secondUserOutcome'];
      final firstUserOutcomeSenderId =
          resolutionData['firstUserOutcomeSenderId'];
      final secondUserOutcomeSenderId =
          resolutionData['secondUserOutcomeSenderId'];

      String winnerId;
      String loserId;

      // Logic to determine winner when outcomes differ
      if (firstUserOutcome == 'win' && secondUserOutcome == 'loss') {
        winnerId = firstUserOutcomeSenderId;
        loserId = secondUserOutcomeSenderId;
      } else if (firstUserOutcome == 'loss' && secondUserOutcome == 'win') {
        winnerId = secondUserOutcomeSenderId;
        loserId = firstUserOutcomeSenderId;
      } else {
        // This should not happen due to previous check, but added for completeness
        throw Exception('Invalid outcome combination');
      }

      // Transfer winnings
      final transferred = await _walletController.transferWinnings(
        challengeId,
        winnerId,
        loserId,
      );
      print("winning transferred");

      

      if (transferred) {
        // Update challenge status
        await _database.child('challenges/$challengeId').update({
          'status': 'completed',
          'winnerId': winnerId,
          'loserId': loserId,
          'finalOutcome': winnerId == creatorId ? 'creatorWin' : 'acceptorWin',
          'completedAt': ServerValue.timestamp
        });
      } else {
        // Handle transfer failure (you might want to add specific error handling)
        throw Exception('Winnings transfer failed');
      }
    } catch (e) {
      print('Error resolving challenge: $e');
      // Optionally, you could add more robust error handling here
    }
  }

// New method to handle both users claiming same outcome
  void _handleBothClaimedSameOutcome(BuildContext context) {
    print("handlebothclaimedsameoutcome");
    // Implement your logic for when both users claim the same outcome
    // This could involve:
    // - Splitting the stake
    // - Cancelling the challenge
    // - Requiring additional resolution
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Challenge Unresolved'),
        content: const Text(
            'Both users claimed the same outcome. Manual resolution required.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleBothClaimedWin(BuildContext context) {
    print("handlebothclaimedwin");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conflict'),
        content: const Text(
          'Both users have claimed a win. Please review or contact support.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Option to change outcome
              Navigator.pop(context);
              selectOutcome(context, false); // Force to select loss
            },
            child: const Text('Change Outcome'),
          ),
          TextButton(
            onPressed: () {
              // Escalate to admin
              _database.child('challenges/$challengeId').update({
                'status': 'admin_review',
                'adminReviewReason': 'Both users claimed win'
              });
              Navigator.pop(context);
            },
            child: const Text('Escalate to Admin'),
          ),
        ],
      ),
    );
  }

  Future<String?> _uploadImage(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last.toLowerCase();
      final fileName =
          '${_currentUser.value?.uid}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      final file = await _storage.createFile(
        bucketId: '67471025003b5f7d49e2', // Your Appwrite bucket ID
        fileId: ID.unique(),
        file: InputFile.fromBytes(
          bytes: bytes,
          filename: fileName,
        ),
        permissions: [
          Permission.read(Role.any()),
        ],
      );

      // Get the direct view URL
      final fileUrl = _storage.getFileView(
        bucketId: '67471025003b5f7d49e2',
        fileId: file.$id,
      );

      return fileUrl.toString();
    } catch (e) {
      Get.snackbar(
        'Upload Error',
        'Failed to upload image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  Future<void> sendMessage({String? message, String? imageUrl}) async {
    if ((message == null || message.trim().isEmpty) && imageUrl == null) {
      return;
    }

    await _database.child('challenge_chats/$challengeId/messages').push().set({
      'senderId': _currentUser.value?.uid,
      'senderName': _currentUser.value?.displayName ?? 'User',
      'message': message?.trim(),
      'imageUrl': imageUrl,
      'timestamp': ServerValue.timestamp
    });
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final fileSize = await pickedFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        Get.snackbar('Error', 'Image size must be less than 10MB');
        return;
      }

      final imageUrl = await _uploadImage(pickedFile);
      if (imageUrl != null) {
        await sendMessage(imageUrl: imageUrl);
      }
    }
  }

  Duration getRemainingTime() {
    print("getremainingtime started");
    if (outcomeSelectionTime.value == null) return Duration.zero;
    final elapsedTime = DateTime.now().difference(outcomeSelectionTime.value!);
    final remainingTime = totalTime - elapsedTime;
    print("$remainingTime");
    return remainingTime.isNegative ? Duration.zero : remainingTime;
  }

  bool shouldShowOutcomeButtons() {
    print("$hasSelectedOutcome.value");
    return !hasSelectedOutcome.value ||
        (hasSelectedOutcome.value &&
            outcomeSelectedBy.value != _currentUser.value?.uid);
  }

  @override
  void onClose() {
    _progressTimer?.cancel();
    messageController.dispose();
    super.onClose();
  }
}

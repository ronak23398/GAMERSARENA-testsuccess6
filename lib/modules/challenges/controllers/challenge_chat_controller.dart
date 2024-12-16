import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gamers_gram/data/services/supabase_storage.dart';
import 'package:gamers_gram/modules/challenges/controllers/1v1_challenege_controller.dart';
import 'package:gamers_gram/modules/wallet/controllers/wallet_controller.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ChallengeChatController extends GetxController {
  final ChallengeImageUploadService imageUploadService;
  RxString challengeProofImageUrl = RxString('');
  final String challengeId;
  final String opponentId;

  final Rx<User?> _currentUser = Rx<User?>(FirebaseAuth.instance.currentUser);
  final _database = FirebaseDatabase.instance.ref();
  final _walletController = Get.find<WalletController>();

  ChallengeChatController({
    required ChallengeImageUploadService imageUploadService,
    required this.challengeId,
    required this.opponentId,
  }) : imageUploadService = imageUploadService;

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
  final Duration totalTime = const Duration(seconds: 10);

  @override
  void onInit() {
    super.onInit();
    print('ChallengeChatController onInit called');
    _loadChatMessages();
    _monitorChallengeOutcome();
  }

  Future<void> uploadChallengeProofImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920, // Optional: Limit image width
        maxHeight: 1080, // Optional: Limit image height
        imageQuality: 80, // Optional: Compress image quality
      );

      if (pickedFile != null) {
        final uploadedImageUrl =
            await imageUploadService.uploadChallengeProofImage(
          imageFile: pickedFile,
          challengeId: challengeId,
        );

        if (uploadedImageUrl != null) {
          challengeProofImageUrl.value = uploadedImageUrl;
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      Get.snackbar(
        'Image Selection Error',
        'Failed to select an image',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _loadChatMessages() {
    print('Loading chat messages for challenge: $challengeId');
    _database
        .child('challenge_chats/$challengeId/messages')
        .orderByChild('timestamp')
        .onChildAdded
        .listen((event) {
      print('New message received for challenge: $challengeId');
      if (event.snapshot.value != null) {
        final newMessage = {
          ...event.snapshot.value as Map,
          'key': event.snapshot.key
        };
        messages.insert(0, newMessage);
        print('Message added: $newMessage');
      }
    });
  }

  void _monitorChallengeOutcome() {
    print("Monitoring challenge outcome for challengeId: $challengeId");
    _database.child('challenges/$challengeId').onValue.listen((event) {
      final challengeData = event.snapshot.value as Map?;
      print('Challenge data updated: $challengeData');

      if (challengeData != null) {
        // Check if outcomes have been selected
        if (challengeData.containsKey('firstUserOutcome') &&
            challengeData.containsKey('firstUserOutcomeTimestamp')) {
          hasSelectedOutcome.value = true;
          currentOutcome.value = challengeData['firstUserOutcome'] ?? '';
          outcomeSelectedBy.value =
              challengeData['firstUserOutcomeSenderId'] ?? '';

          print(
              'First user outcome selected: ${currentOutcome.value} by ${outcomeSelectedBy.value}');

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

            print('Second user outcome: $secondUserOutcome');

            if (firstUserOutcome == 'win' && secondUserOutcome == 'win') {
              bothClaimedWin.value = true;
              print('Both users claimed win');
            }
          }
        }
      }
    });
  }

  void _startTimer() {
    print("Starting timer for challengeId: $challengeId");
    _progressTimer?.cancel();

    if (outcomeSelectionTime.value != null) {
      isTimerRunning.value = true;

      _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final now = DateTime.now();
        final difference = now.difference(outcomeSelectionTime.value!);

        print('Timer running - Time elapsed: $difference');

        if (difference >= totalTime) {
          print('Timer expired for challengeId: $challengeId');
          _handleTimerExpiration();
          timer.cancel();
        }

        update(); // Force UI update
      });
    }
  }

  void _handleTimerExpiration() async {
    print("Handling timer expiration for challengeId: $challengeId");

    try {
      // First, fetch the complete challenge data
      final challengeSnapshot =
          await _database.child('challenges/$challengeId').get();
      final challengeData = challengeSnapshot.value as Map?;
      print("Challenge data fetched from Firebase: $challengeData");

      if (challengeData == null) {
        print('No challenge data found');
        return;
      }

      // Resolve challenge with complete data
      await ChallengeController().resolveChallenge(
        challengeId,
      );
      print("Resolve challenge started for challengeId: $challengeId");

      isTimerRunning.value = false;
      update();
    } catch (e) {
      print('Error in timer expiration for challengeId: $challengeId - $e');
    }
  }

  void selectOutcome(BuildContext context, bool isWin) {
    print("Selecting outcome for challengeId: $challengeId - isWin: $isWin");

    // Check if challenge proof image is uploaded
    if (challengeProofImageUrl.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please upload challenge proof image before selecting outcome',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Check if this is the first or second user selecting outcome
    final isFirstUser = !hasSelectedOutcome.value;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Outcome'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to declare this as a ${isWin ? 'Win' : 'Loss'}?',
            ),
            Image.network(challengeProofImageUrl.value, height: 100),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (isFirstUser) {
                print("Outcome selected by first user");
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
                print("Outcome selected by second user");
                // Second user selects outcome
                _database.child('challenges/$challengeId').update({
                  'secondUserOutcome': isWin ? 'win' : 'loss',
                  'secondUserOutcomeSenderId': _currentUser.value?.uid,
                });

                // Retrieve first user's outcome
                final firstUserOutcome = currentOutcome.value;
                final secondUserOutcome = isWin ? 'win' : 'loss';

                print(
                    'First user outcome: $firstUserOutcome, Second user outcome: $secondUserOutcome');

                // Resolve challenge based on outcomes
                if (firstUserOutcome == secondUserOutcome) {
                  // Both claim win or both claim loss
                  _handleBothClaimedWin(context);
                } else {
                  // Different outcomes - proceed with challenge resolution
                  print('Resolving challenge due to different outcomes');
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

  void _handleBothClaimedWin(BuildContext context) {
    print("Handling both users claiming win for challengeId: $challengeId");
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
              print('Forcing user to change outcome');
              Navigator.pop(context);
              selectOutcome(context, false); // Force to select loss
            },
            child: const Text('Change Outcome'),
          ),
          TextButton(
            onPressed: () {
              // Escalate to admin
              print('Escalating challenge to admin review');
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

  Future<void> sendMessage({String? message, String? imageUrl}) async {
    print("Sending message for challengeId: $challengeId");
    if ((message == null || message.trim().isEmpty) && imageUrl == null) {
      print('No message or image to send');
      return;
    }

    await _database.child('challenge_chats/$challengeId/messages').push().set({
      'senderId': _currentUser.value?.uid,
      'senderName': _currentUser.value?.displayName ?? 'User',
      'message': message?.trim(),
      'imageUrl': imageUrl,
      'timestamp': ServerValue.timestamp
    });

    print('Message sent: ${message ?? 'Image message'}');
  }

  Duration getRemainingTime() {
    print("Getting remaining time for challengeId: $challengeId");
    if (outcomeSelectionTime.value == null) return Duration.zero;
    final elapsedTime = DateTime.now().difference(outcomeSelectionTime.value!);
    final remainingTime = totalTime - elapsedTime;
    print("Remaining time: $remainingTime");
    return remainingTime.isNegative ? Duration.zero : remainingTime;
  }

  bool shouldShowOutcomeButtons() {
    print(
        "Checking if outcome buttons should be shown for challengeId: $challengeId");
    final shouldShow = !hasSelectedOutcome.value ||
        (hasSelectedOutcome.value &&
            outcomeSelectedBy.value != _currentUser.value?.uid);
    print("Should show outcome buttons: $shouldShow");
    return shouldShow;
  }

  @override
  void onClose() {
    _progressTimer?.cancel();
    messageController.dispose();
    super.onClose();
  }
}

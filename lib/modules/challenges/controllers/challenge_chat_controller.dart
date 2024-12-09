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
        _storage = storage {
    print(
        'ChallengeChatController initialized with challengeId: $challengeId, opponentId: $opponentId');
  }

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
          ...?event.snapshot.value as Map,
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

      // // Update challenge status
      // await _database.child('challenges/$challengeId').update({
      //   'finalOutcome': currentOutcome.value,
      //   'winnerId': outcomeSelectedBy.value,
      //   'status': 'completed',
      //   'secondUserOutcome': 'loss'
      // });
      print("Updating challenge status for challengeId: $challengeId");

      isTimerRunning.value = false;
      update();
    } catch (e) {
      print('Error in timer expiration for challengeId: $challengeId - $e');
    }
  }

  void selectOutcome(BuildContext context, bool isWin) {
    print("Selecting outcome for challengeId: $challengeId - isWin: $isWin");

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
            onPressed: () {
              print('Outcome selection cancelled');
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
                  // ChallengeController().resolveChallenge(
                  //   challengeId,
                  // );
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

  Future<String?> _uploadImage(XFile imageFile) async {
    print("Uploading image for challengeId: $challengeId");
    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last.toLowerCase();
      final fileName =
          '${_currentUser.value?.uid}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      print('Uploading file with name: $fileName');

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

      print('Image uploaded successfully: ${fileUrl.toString()}');
      return fileUrl.toString();
    } catch (e) {
      print('Error uploading image for challengeId: $challengeId - $e');
      Get.snackbar(
        'Upload Error',
        'Failed to upload image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
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

  Future<void> pickImage(ImageSource source) async {
    print(
        "Picking image from ${source == ImageSource.camera ? 'camera' : 'gallery'}");
    final pickedFile = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final fileSize = await pickedFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        print('Image size exceeds 10MB limit');
        Get.snackbar('Error', 'Image size must be less than 10MB');
        return;
      }

      final imageUrl = await _uploadImage(pickedFile);
      if (imageUrl != null) {
        await sendMessage(imageUrl: imageUrl);
      }
    } else {
      print('No image picked');
    }
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

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gamers_gram/data/models/scrim_model.dart';
import 'package:gamers_gram/modules/challenges/controllers/scrim_controller.dart';
import 'package:get/get.dart';

class ScrimChatController extends GetxController {
  final String scrimId;
  final ScrimModel scrim;

  // Determine opponent ID based on current user's role
  late final String opponentId;

  final Rx<User?> _currentUser = Rx<User?>(FirebaseAuth.instance.currentUser);
  final _database = FirebaseDatabase.instance.ref();


  ScrimChatController({
    required this.scrimId,
    required this.scrim,
  })  ;

 

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
    print('ScrimChatController onInit called');
    _loadChatMessages();
    _monitorScrimOutcome();
  }

  void _loadChatMessages() {
    print('Loading chat messages for scrim: $scrimId');
    _database
        .child('scrim_chats/$scrimId/messages')
        .orderByChild('timestamp')
        .onChildAdded
        .listen((event) {
      print('New message received for scrim: $scrimId');
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

  void _monitorScrimOutcome() {
    print("Monitoring scrim outcome for scrimId: $scrimId");
    _database.child('scrims/$scrimId').onValue.listen((event) {
      final scrimData = event.snapshot.value as Map?;
      print('Scrim data updated: $scrimData');

      if (scrimData != null) {
        // Check if outcomes have been selected
        if (scrimData.containsKey('firstUserOutcome') &&
            scrimData.containsKey('firstUserOutcomeTimestamp')) {
          hasSelectedOutcome.value = true;
          currentOutcome.value = scrimData['firstUserOutcome'] ?? '';
          outcomeSelectedBy.value = scrimData['firstUserOutcomeSenderId'] ?? '';

          print(
              'First user outcome selected: ${currentOutcome.value} by ${outcomeSelectedBy.value}');

          // Start timer when first outcome is selected
          dynamic timestamp = scrimData['firstUserOutcomeTimestamp'];
          if (timestamp != null) {
            outcomeSelectionTime.value = DateTime.fromMillisecondsSinceEpoch(
                int.tryParse(timestamp.toString()) ?? 0);
            _startTimer();
          }

          // Check for second user's outcome
          if (scrimData.containsKey('secondUserOutcome')) {
            final secondUserOutcome = scrimData['secondUserOutcome'];
            final firstUserOutcome = scrimData['firstUserOutcome'];

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
    print("Starting timer for scrimId: $scrimId");
    _progressTimer?.cancel();

    if (outcomeSelectionTime.value != null) {
      isTimerRunning.value = true;

      _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final now = DateTime.now();
        final difference = now.difference(outcomeSelectionTime.value!);

        print('Timer running - Time elapsed: $difference');

        if (difference >= totalTime) {
          print('Timer expired for scrimId: $scrimId');
          _handleTimerExpiration();
          timer.cancel();
        }

        update(); // Force UI update
      });
    }
  }

  void _handleTimerExpiration() async {
    print("Handling timer expiration for scrimId: $scrimId");

    try {
      // First, fetch the complete scrim data
      final scrimSnapshot = await _database.child('scrims/$scrimId').get();
      final scrimData = scrimSnapshot.value as Map?;
      print("Scrim data fetched from Firebase: $scrimData");

      

      if (scrimData == null) {
        print('No scrim data found');
        return;
      }

      // Resolve scrim
      await ScrimController().resolveScrim(scrimId);
      print("Resolve scrim started for scrimId: $scrimId");

      isTimerRunning.value = false;
      update();
    } catch (e) {
      print('Error in timer expiration for scrimId: $scrimId - $e');
    }
  }

  void selectScrimOutcome(BuildContext context, bool isWin) {
    print("Selecting outcome for scrimId: $scrimId - isWin: $isWin");

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
                _database.child('scrims/$scrimId').update({
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
                _database.child('scrims/$scrimId').update({
                  'secondUserOutcome': isWin ? 'win' : 'loss',
                  'secondUserOutcomeSenderId': _currentUser.value?.uid,
                });

                // Retrieve first user's outcome
                final firstUserOutcome = currentOutcome.value;
                final secondUserOutcome = isWin ? 'win' : 'loss';

                print(
                    'First user outcome: $firstUserOutcome, Second user outcome: $secondUserOutcome');

                // Resolve scrim based on outcomes
                if (firstUserOutcome == secondUserOutcome) {
                  // Both claim win or both claim loss
                  _handleBothClaimedWin(context);
                } else {
                  // Different outcomes - proceed with scrim resolution
                  print('Resolving scrim due to different outcomes');
                  ScrimController().resolveScrim(scrimId);
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
    print("Handling both users claiming win for scrimId: $scrimId");
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
              selectScrimOutcome(context, false); // Force to select loss
            },
            child: const Text('Change Outcome'),
          ),
          TextButton(
            onPressed: () {
              // Escalate to admin
              print('Escalating scrim to admin review');
              _database.child('scrims/$scrimId').update({
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
    print("Sending message for scrimId: $scrimId");
    if ((message == null || message.trim().isEmpty) && imageUrl == null) {
      print('No message or image to send');
      return;
    }

    await _database.child('scrim_chats/$scrimId/messages').push().set({
      'senderId': _currentUser.value?.uid,
      'senderName': _currentUser.value?.displayName ?? 'User',
      'message': message?.trim(),
      'imageUrl': imageUrl,
      'timestamp': ServerValue.timestamp
    });

    print('Message sent: ${message ?? 'Image message'}');
  }


  Duration getRemainingTime() {
    print("Getting remaining time for scrimId: $scrimId");
    if (outcomeSelectionTime.value == null) return Duration.zero;
    final elapsedTime = DateTime.now().difference(outcomeSelectionTime.value!);
    final remainingTime = totalTime - elapsedTime;
    print("Remaining time: $remainingTime");
    return remainingTime.isNegative ? Duration.zero : remainingTime;
  }

  bool shouldShowOutcomeButtons() {
    print("Checking if outcome buttons should be shown for scrimId: $scrimId");
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

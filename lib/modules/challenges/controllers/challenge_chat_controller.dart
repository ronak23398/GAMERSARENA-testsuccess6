import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ChallengeChatController extends GetxController {
  final String challengeId;
  final String opponentId;

  final Rx<User?> _currentUser = Rx<User?>(FirebaseAuth.instance.currentUser);
  final _database = FirebaseDatabase.instance.ref();

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

  // Timer for periodic updates
  Timer? _progressTimer;

  // Total time for outcome selection
  final Duration totalTime = const Duration(minutes: 5);

  @override
  void onInit() {
    super.onInit();
    _loadChatMessages();
    _checkPreviousOutcome();
  }

  void _loadChatMessages() {
    _database
        .child('challenge_chats/$challengeId/messages')
        .orderByChild('timestamp')
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        messages.value = (event.snapshot.value as Map)
            .entries
            .map((e) => {...e.value, 'key': e.key})
            .toList();
      }
    });
  }

  void _checkPreviousOutcome() {
    _database.child('challenges/$challengeId/outcome').onValue.listen((event) {
      final outcomeData = event.snapshot.value;
      if (outcomeData != null) {
        hasSelectedOutcome.value = true;

        // Handle different potential timestamp formats
        dynamic timestamp;
        if (outcomeData is Map) {
          timestamp = outcomeData['outcomeTimestamp'];
        } else if (outcomeData is int) {
          timestamp = outcomeData;
        }

        if (timestamp != null) {
          outcomeSelectionTime.value = DateTime.fromMillisecondsSinceEpoch(
              int.tryParse(timestamp.toString()) ?? 0);
          _startTimer();
        }
      }
    });
  }

  void _startTimer() {
    // Cancel any existing timer
    _progressTimer?.cancel();

    if (outcomeSelectionTime.value != null) {
      isTimerRunning.value = true;

      _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        // Check if 5 minutes have passed
        if (DateTime.now().difference(outcomeSelectionTime.value!) >=
            totalTime) {
          timer.cancel();
          isTimerRunning.value = false;
          update(); // Update UI
        }

        // Trigger UI update
        update();
      });
    }
  }

  void selectOutcome(BuildContext context, bool isWin) {
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
              // Update Firebase database
              _database.child('challenges/$challengeId').update({
                'outcome': isWin ? 'win' : 'loss',
                'outcomeSenderId': _currentUser.value?.uid,
                'outcomeTimestamp': ServerValue.timestamp
              });

              // Set the outcome selection time
              outcomeSelectionTime.value = DateTime.now();
              hasSelectedOutcome.value = true;

              // Start the timer
              _startTimer();

              Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  double calculateRemainingTime() {
    if (outcomeSelectionTime.value == null) return 0.0;

    final elapsedTime = DateTime.now().difference(outcomeSelectionTime.value!);

    // Ensure the value doesn't exceed 1.0
    double progress = elapsedTime.inMilliseconds / totalTime.inMilliseconds;
    return progress.clamp(0.0, 1.0);
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

  @override
  void onClose() {
    // Cancel the timer if it's running
    _progressTimer?.cancel();
    messageController.dispose();
    super.onClose();
  }
}

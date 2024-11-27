import 'dart:io';
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

  final RxBool hasSelectedOutcome = false.obs;
  final Rx<DateTime?> outcomeSelectionTime = Rx<DateTime?>(null);
  final RxBool isTimerRunning = false.obs;

  final RxList<dynamic> messages = <dynamic>[].obs;
  final TextEditingController messageController = TextEditingController();

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
    if (outcomeSelectionTime.value != null) {
      isTimerRunning.value = true;
    }
  }

  Future<void> sendMessage({String? message, String? imageUrl}) async {
    await _database.child('challenge_chats/$challengeId/messages').push().set({
      'senderId': _currentUser.value?.uid,
      'senderName': _currentUser.value?.displayName ?? 'User',
      'message': message,
      'imageUrl': imageUrl,
      'timestamp': ServerValue.timestamp
    });
  }

  Future<String?> _uploadImage(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';

      final file = await _storage.createFile(
        bucketId: '67471025003b5f7d49e2',
        fileId: ID.unique(),
        file: InputFile.fromBytes(
          bytes: bytes,
          filename: fileName,
        ),
        permissions: [
          Permission.read(Role.any()),
        ],
      );

      return _storage
          .getFileView(
            bucketId: '67471025003b5f7d49e2',
            fileId: file.$id,
          )
          .toString();
    } catch (e) {
      Get.snackbar('Upload Error', 'Failed to upload image: ${e.toString()}');
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
              _database.child('challenges/$challengeId').update({
                'outcome': isWin ? 'win' : 'loss',
                'outcomeSenderId': _currentUser.value?.uid,
                'outcomeTimestamp': ServerValue.timestamp
              });
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
    const totalTime = Duration(minutes: 5);

    return elapsedTime.inMilliseconds / totalTime.inMilliseconds;
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}

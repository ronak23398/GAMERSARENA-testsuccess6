// arena_controller.dart

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:gamers_gram/data/models/arena_chat_model.dart';
import 'package:gamers_gram/data/models/arena_system_data_models.dart';
import 'package:gamers_gram/data/repository/user_repository.dart';
import 'package:gamers_gram/data/services/auth_service.dart';
import 'package:gamers_gram/modules/auth/controllers/auth_controller.dart';
import 'package:get/get.dart';

class ArenaController extends GetxController {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final AuthController _authController = Get.find<AuthController>();

  final AuthService _authService = Get.find<AuthService>();
  final UserRepository _userRepository = Get.find<UserRepository>();
  final RxString errorMessage = ''.obs;
  final _auth = FirebaseAuth.instance;

  // Observables
  final isAuthenticated = false.obs;
  final isRegistered = false.obs;
  final isInQueue = false.obs;
  final currentStage = 1.obs;
  final balance = 0.0.obs;
  final registeredPlayers = <TournamentPlayer>[].obs;
  final currentMatches = <TournamentMatch>[].obs;
  final currentChatMessages = <ChatMessage>[].obs;
  final unreadMessageCounts = <String, int>{}.obs;
  final activeMatch = Rx<TournamentMatch?>(null);
  final isTyping = false.obs;
  final currentPlayer = Rx<TournamentPlayer?>(null);
  final isAdmin = false.obs;

  // Stream subscriptions
  final List<StreamSubscription> _subscriptions = [];
  final Map<String, List<ChatMessage>> _messageCache = {};
  static const int initialMessageLoad = 50;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes
    ever(_authController.user, _handleAuthChanged);
    // Initialize if user is already authenticated
    if (_authController.user.value != null) {
      _handleAuthChanged(_authController.user.value);
    }
  }

  void _handleAuthChanged(user) async {
    if (user != null) {
      isAuthenticated.value = true;
      await _initializeController();
    } else {
      isAuthenticated.value = false;
      _clearControllerState();
    }
  }

  void _clearControllerState() {
    isRegistered.value = false;
    isInQueue.value = false;
    currentStage.value = 1;
    registeredPlayers.clear();
    currentMatches.clear();
    currentChatMessages.clear();
    unreadMessageCounts.clear();
    activeMatch.value = null;
    currentPlayer.value = null;
    isAdmin.value = false;

    // Cancel all subscriptions
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  Future<void> _initializeController() async {
    try {
      await _initializeCurrentPlayer();
      _setupListeners();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to initialize: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _initializeCurrentPlayer() async {
    final user = _auth.currentUser;
    if (user == null) return; // Return silently instead of throwing

    final snapshot = await _database
        .child('tournament_registrations')
        .child(user.uid)
        .once();

    if (snapshot.snapshot.value != null) {
      currentPlayer.value = TournamentPlayer.fromSnapshot(
        snapshot.snapshot,
        snapshot.snapshot.value,
      );
      isRegistered.value = true;
    }
  }

  @override
  void onClose() {
    _clearControllerState();
    super.onClose();
  }

  void _setupListeners() {
    final user = _auth.currentUser;
    if (user == null) return;

    // Listen to registrations
    _subscriptions.add(
      _database.child('tournament_registrations').onValue.listen((event) {
        if (event.snapshot.value != null) {
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          registeredPlayers.value = data.entries
              .map((e) => TournamentPlayer.fromSnapshot(e.value, e.value))
              .toList();
        }
      }),
    );

    // Listen to matches
    _subscriptions.add(
      _database.child('matches').onValue.listen((event) {
        if (event.snapshot.value != null) {
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          currentMatches.value = data.entries
              .map((e) => TournamentMatch.fromSnapshot(e.value, e.value))
              .where((match) => match.stage.index == currentStage.value - 1)
              .toList();
        }
      }),
    );

    // Check admin status
    _checkAdminStatus(user.uid);
  }

  Future<void> _checkAdminStatus(String userId) async {
    final snapshot = await _database.child('admins').child(userId).once();
    isAdmin.value = snapshot.snapshot.value == true;
  }

  Future<void> registerForTournament() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

    

      final player = TournamentPlayer(
        userId: user.uid,
        username: user.displayName ?? 'Unknown Player',
      );

      await _database
          .child('tournament_registrations')
          .child(player.userId)
          .set(player.toJson());

      currentPlayer.value = player;
      isRegistered.value = true;

      Get.snackbar(
        'Success',
        'Successfully registered for tournament',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to register: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Refresh Wallet Balance
  Future<void> _refreshWalletBalance() async {
    try {
      final userId = _authService.currentUser.value?.uid;
      if (userId != null) {
        final userData = await _userRepository.getUser(userId);
        if (userData != null) {
          balance.value = userData.walletBalance;
        }
      }
    } catch (e) {
      errorMessage.value = 'Failed to refresh wallet balance';
    }
  }

  Future<void> joinQueue() async {
    try {
      if (activeMatch.value != null) {
        throw Exception('Please complete your current match first');
      }

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _database
          .child('queue')
          .child('stage${currentStage.value}')
          .child(user.uid)
          .set({
        'timestamp': ServerValue.timestamp,
        'stage': currentStage.value,
      });

      isInQueue.value = true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to join queue: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> leaveQueue() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _database
          .child('queue')
          .child('stage${currentStage.value}')
          .child(user.uid)
          .remove();

      isInQueue.value = false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to leave queue: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void setCurrentStage(int stage) {
    if (stage >= 1 && stage <= 5) {
      currentStage.value = stage;
    }
  }

  Future<void> openMatchChat(TournamentMatch match) async {
    activeMatch.value = match;
    currentChatMessages.clear();

    if (_messageCache.containsKey(match.matchId)) {
      currentChatMessages.value = _messageCache[match.matchId]!;
    }

    await markMessagesAsRead(match.matchId!);
  }

  Future<void> sendMessage(String matchId, String content) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final message = ChatMessage(
        id: '',
        matchId: matchId,
        senderId: user.uid,
        senderUsername: user.displayName ?? 'Unknown Player',
        content: content,
        timestamp: DateTime.now(),
      );

      final ref = _database.child('chats').child(matchId).push();
      message.id = ref.key!;
      await ref.set(message.toJson());
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send message: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> markMessagesAsRead(String matchId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final messages = _messageCache[matchId] ?? [];
      final updates = <String, dynamic>{};

      for (var message in messages) {
        if (!message.isRead && message.senderId != user.uid) {
          updates['chats/$matchId/${message.id}/isRead'] = true;
        }
      }

      if (updates.isNotEmpty) {
        await _database.update(updates);
      }

      unreadMessageCounts[matchId] = 0;
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<void> reportMatchResult(String matchId, bool won) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final result = {
        'reportedBy': user.uid,
        'claimed': won ? 'win' : 'loss',
        'timestamp': ServerValue.timestamp,
      };

      await _database
          .child('match_results')
          .child(matchId)
          .child(user.uid)
          .set(result);

      final snapshot =
          await _database.child('match_results').child(matchId).once();

      if (snapshot.snapshot.value != null) {
        final results = snapshot.snapshot.value as Map<dynamic, dynamic>;
        if (results.length == 2) {
          final reports = results.entries.toList();
          if (reports[0].value['claimed'] != reports[1].value['claimed']) {
            await _database
                .child('disputed_matches')
                .child(matchId)
                .set(results);
          }
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to report match result: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> startTournament() async {
    try {
      if (!isAdmin.value) {
        throw Exception('Unauthorized access');
      }

      await _database.child('tournament_status').set({'status': 'active'});
      Get.snackbar(
        'Success',
        'Tournament has started',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to start tournament: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

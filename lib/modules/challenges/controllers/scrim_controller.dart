import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:gamers_gram/data/models/scrim_model.dart';
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

  Future<bool> createScrim(double amount, String creatorTeamName) async {
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
        creatorTeamName: creatorTeamName,
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

  Future<bool> acceptScrim(String scrimId, String acceptorTeamName) async {
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
        scrimData['acceptorTeamName'] = acceptorTeamName;

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

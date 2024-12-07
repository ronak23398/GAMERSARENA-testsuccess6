import 'package:flutter/material.dart';
import 'package:gamers_gram/data/models/tournament_models.dart';
import 'package:gamers_gram/modules/auth/controllers/auth_controller.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';

class TournamentController extends GetxController {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final _auth = Get.find<AuthController>();

  final RxList<Tournament> tournaments = <Tournament>[].obs;
  final RxList<Tournament> myTournaments = <Tournament>[].obs;
  final RxInt currentTabIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxString selectedGameFilter = ''.obs;
  final RxString selectedStatusFilter = ''.obs;
  final RxString sortBy = 'startDate'.obs;
  final RxBool hasMoreData = true.obs;

  final int _pageSize = 20;
  String? _lastKey;

  @override
  void onInit() {
    super.onInit();
    _setupFirebaseListeners();
    refreshTournaments();
  }

  void _setupFirebaseListeners() {
    _database.child('tournaments').onChildAdded.listen((event) {
      _addNewTournament(event.snapshot);
    });

    _database.child('tournaments').onChildChanged.listen((event) {
      _updateExistingTournament(event.snapshot);
    });

    _database.child('tournaments').onChildRemoved.listen((event) {
      _removeTournament(event.snapshot.key);
    });
  }

  Future<void> refreshTournaments() async {
    isLoading.value = true;
    _lastKey = null;
    hasMoreData.value = true;
    tournaments.clear();
    myTournaments.clear();

    await fetchTournaments();
    await fetchMyTournaments();

    isLoading.value = false;
  }

  Future<void> fetchTournaments() async {
    try {
      Query query = _database
          .child('tournaments')
          .orderByChild('startDate')
          .limitToFirst(_pageSize);

      if (_lastKey != null) {
        query = query.startAfter(_lastKey!);
      }

      final snapshot = await query.get();
      _processTournamentSnapshot(snapshot, false);
    } catch (e) {
      print('Tournament fetch error: $e');
    }
  }

  Future<void> fetchMyTournaments() async {
    final userId = _auth.user.value?.uid;
    if (userId == null) return;

    try {
      Query query = _database
          .child('tournaments')
          .orderByChild('participants/$userId/status')
          .equalTo('active');

      final snapshot = await query.get();
      _processTournamentSnapshot(snapshot, true);
    } catch (e) {
      print('My tournaments fetch error: $e');
    }
  }

  void _processTournamentSnapshot(DataSnapshot snapshot, bool isMyTournaments) {
    if (!snapshot.exists) return;

    final Map<dynamic, dynamic> data =
        Map<dynamic, dynamic>.from(snapshot.value as Map);
    print('Raw Tournament Data: $data');

    data.forEach((key, value) {
      final tournament =
          Tournament.fromJson(Map<String, dynamic>.from(value), key.toString());

      if (isMyTournaments) {
        if (!myTournaments.any((t) => t.id == tournament.id)) {
          myTournaments.add(tournament);
        }
      } else {
        if (!tournaments.any((t) => t.id == tournament.id)) {
          tournaments.add(tournament);
        }
      }
    });

    _applyFiltersAndSort();
  }

  void _addNewTournament(DataSnapshot snapshot) {
    if (snapshot.exists) {
      final tournament = Tournament.fromJson(
          Map<String, dynamic>.from(snapshot.value as Map), snapshot.key!);

      if (!tournaments.any((t) => t.id == tournament.id)) {
        tournaments.add(tournament);
        _applyFiltersAndSort();
      }
    }
  }

  void _updateExistingTournament(DataSnapshot snapshot) {
    if (snapshot.exists) {
      final tournament = Tournament.fromJson(
          Map<String, dynamic>.from(snapshot.value as Map), snapshot.key!);

      final index = tournaments.indexWhere((t) => t.id == tournament.id);
      if (index != -1) {
        tournaments[index] = tournament;
        _applyFiltersAndSort();
      }
    }
  }

  void _removeTournament(String? tournamentId) {
    if (tournamentId != null) {
      tournaments.removeWhere((t) => t.id == tournamentId);
      myTournaments.removeWhere((t) => t.id == tournamentId);
    }
  }

 Future<bool> joinTournament(Tournament tournament, String teamName) async {
    final userId = _auth.user.value?.uid;
    if (userId == null) return false;

    try {
      final tournamentRef = _database.child('tournaments/${tournament.id}');

      await tournamentRef.child('participants/$userId').set({
        'userId': userId,
        'teamName': teamName,
        'joinedAt': DateTime.now().toIso8601String(),
        'status': 'active'
      });

      return true;
    } catch (e) {
      print('Tournament join error: $e');
      return false;
    }
  }

  Future<Tournament?> navigateToTournamentDetails(String tournamentId) async {
    try {
      final snapshot = await _database.child('tournaments/$tournamentId').get();

      if (snapshot.exists) {
        final tournament = Tournament.fromJson(
            Map<String, dynamic>.from(snapshot.value as Map), tournamentId);
        return tournament;
      }
      return null;
    } catch (e) {
      print('Tournament details fetch error: $e');
      return null;
    }
  }

  bool isRegistrationClosed(Tournament tournament) {
    return DateTime.now().isAfter(tournament.registrationEndDate);
  }

  bool isTournamentJoinable(Tournament tournament) {
    final now = DateTime.now();
    return now.isBefore(tournament.registrationEndDate) &&
        tournament.status.toLowerCase() == 'open';
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
      case 'registration':
        return Colors.green;
      case 'ongoing':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  bool _isTournamentRegistrationOpen(Tournament tournament) {
    final now = DateTime.now();
    return now.isBefore(tournament.registrationEndDate) &&
        tournament.maxParticipants > 0;
  }

  void setGameFilter(String game) {
    selectedGameFilter.value = game;
    _applyFiltersAndSort();
  }

  void setStatusFilter(String status) {
    selectedStatusFilter.value = status;
    _applyFiltersAndSort();
  }

  void setSortBy(String sortType) {
    sortBy.value = sortType;
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    final RxList<Tournament> currentList =
        currentTabIndex.value == 0 ? tournaments : myTournaments;

    List<Tournament> filteredList = currentList.toList();

    if (selectedGameFilter.isNotEmpty) {
      filteredList = filteredList
          .where((t) => t.game == selectedGameFilter.value)
          .toList();
    }

    if (selectedStatusFilter.isNotEmpty) {
      filteredList = filteredList
          .where((t) => t.status == selectedStatusFilter.value)
          .toList();
    }

    filteredList.sort((a, b) {
      if (sortBy.value == 'startDate') {
        return b.startDate.compareTo(a.startDate);
      } else {
        return b.prizePool.compareTo(a.prizePool);
      }
    });

    if (currentTabIndex.value == 0) {
      tournaments.value = filteredList;
    } else {
      myTournaments.value = filteredList;
    }
  }

  void onTabChanged(int index) {
    currentTabIndex.value = index;
    refreshTournaments();
  }

  Future<Tournament?> getTournamentDetails(String tournamentId) async {
    try {
      final snapshot = await _database.child('tournaments/$tournamentId').get();
      print('Raw Tournament Data: $snapshot');

      if (snapshot.exists) {
        return Tournament.fromJson(
            Map<String, dynamic>.from(snapshot.value as Map), tournamentId);
      }
      return null;
    } catch (e) {
      print('Tournament details fetch error: $e');
      return null;
    }
  }
}

import 'package:gamers_gram/data/repository/user_repository.dart';
import 'package:get/get.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/utils/loading_state.dart';

class HomeController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final UserRepository _userRepository = Get.find<UserRepository>();

  // Bottom Navigation
  final RxInt currentIndex = 0.obs;

  // User Data
  final RxString username = ''.obs;
  final RxDouble walletBalance = 0.0.obs;
  final RxBool isVerified = false.obs;

  // Loading States
  final Rx<LoadingState> challengesLoadingState = LoadingState.initial.obs;
  final Rx<LoadingState> tournamentsLoadingState = LoadingState.initial.obs;
  final RxBool isRefreshing = false.obs;

  // Dashboard Data
  final RxList activeChallenges = [].obs;
  final RxList activeTournaments = [].obs;
  final RxList recentMatches = [].obs;

  // Error Handling
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeUserData();
    _loadDashboardData();
  }

  // Initialize user data when the home screen loads
  Future<void> _initializeUserData() async {
    try {
      final userId = _authService.currentUser.value?.uid;
      if (userId != null) {
        final userData = await _userRepository.getUser(userId);
        if (userData != null) {
          username.value = userData.username;
          walletBalance.value = userData.walletBalance;
          // Add more user data initialization as needed
        }
      }
    } catch (e) {
      errorMessage.value = 'Failed to load user data';
    }
  }

  // Load initial dashboard data
  Future<void> _loadDashboardData() async {
    await Future.wait([
      _loadActiveChallenges(),
      _loadActiveTournaments(),
      _loadRecentMatches(),
    ]);
  }

  // Navigation Methods
  void changePage(int index) {
    currentIndex.value = index;
    // Refresh data when switching tabs
    _refreshPageData(index);
  }

  // Refresh data based on current tab
  Future<void> _refreshPageData(int index) async {
    switch (index) {
      case 0: // Home
        await _loadDashboardData();
        break;
      case 1: // Tournaments
        await _loadActiveTournaments();
        break;
      case 2: // Wallet
        await _refreshWalletBalance();
        break;
      case 3: // Profile
        await _initializeUserData();
        break;
    }
  }

  // Load Active Challenges
  Future<void> _loadActiveChallenges() async {
    try {
      challengesLoadingState.value = LoadingState.loading;
      // TODO: Implement challenge loading logic
      // final challenges = await challengeRepository.getActiveChallenges();
      // activeChallenges.value = challenges;
      challengesLoadingState.value = LoadingState.success;
    } catch (e) {
      challengesLoadingState.value = LoadingState.error;
      errorMessage.value = 'Failed to load challenges';
    }
  }

  // Load Active Tournaments
  Future<void> _loadActiveTournaments() async {
    try {
      tournamentsLoadingState.value = LoadingState.loading;
      // TODO: Implement tournament loading logic
      // final tournaments = await tournamentRepository.getActiveTournaments();
      // activeTournaments.value = tournaments;
      tournamentsLoadingState.value = LoadingState.success;
    } catch (e) {
      tournamentsLoadingState.value = LoadingState.error;
      errorMessage.value = 'Failed to load tournaments';
    }
  }

  // Load Recent Matches
  Future<void> _loadRecentMatches() async {
    try {
      // TODO: Implement recent matches loading logic
      // final matches = await matchRepository.getRecentMatches();
      // recentMatches.value = matches;
    } catch (e) {
      errorMessage.value = 'Failed to load recent matches';
    }
  }

  // Refresh Wallet Balance
  Future<void> _refreshWalletBalance() async {
    try {
      final userId = _authService.currentUser.value?.uid;
      if (userId != null) {
        final userData = await _userRepository.getUser(userId);
        if (userData != null) {
          walletBalance.value = userData.walletBalance;
        }
      }
    } catch (e) {
      errorMessage.value = 'Failed to refresh wallet balance';
    }
  }

  // Pull to refresh functionality
  Future<void> onRefresh() async {
    isRefreshing.value = true;
    await _refreshPageData(currentIndex.value);
    isRefreshing.value = false;
  }

  // Clear error message
  void clearError() {
    errorMessage.value = '';
  }
}

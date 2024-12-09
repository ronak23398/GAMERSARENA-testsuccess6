import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gamers_gram/data/models/wallet_model.dart';
import 'package:get/get.dart';

class WalletController extends GetxController {
  // Firebase instances
  final _db = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;

  // Observable variables
  final balance = 0.0.obs;
  final frozenBalance = 0.0.obs;
  final transactions = <WalletTransaction>[].obs;
  final isLoading = false.obs;

  // Constants
  static const double MIN_BALANCE = 100.0;
  static const double MAX_TRANSACTION = 10000.0;
  static const double MIN_DEPOSIT = 100.0;
  static const double MAX_DEPOSIT = 50000.0;
  static const double MIN_WITHDRAWAL = 100.0;

  @override
  void onInit() {
    super.onInit();
    _initializeWallet();
    _listenToTransactions();
  }

  // Initialize wallet and listen to balance changes
  void _initializeWallet() {
    final user = _auth.currentUser;
    if (user != null) {
      _db.child('wallets/${user.uid}').onValue.listen((event) {
        if (event.snapshot.value != null) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          balance.value = (data['balance'] ?? 0.0).toDouble();
          frozenBalance.value = (data['frozenAmount'] ?? 0.0).toDouble();
        }
      });
    }
  }

  // Listen to transaction updates
  void _listenToTransactions() {
    final user = _auth.currentUser;
    if (user != null) {
      _db
          .child('wallets/${user.uid}/transactions')
          .orderByChild('timestamp')
          .limitToLast(50)
          .onValue
          .listen((event) {
        if (event.snapshot.value != null) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          transactions.value = data.entries
              .map((e) => WalletTransaction.fromJson(
                  e.key, Map<String, dynamic>.from(e.value as Map)))
              .toList();

          transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        }
      });
    }
  }

  // Add balance to wallet
  Future<bool> addBalance(double amount) async {
    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'User not logged in');
      return false;
    }

    // Validate amount
    if (amount < MIN_DEPOSIT) {
      Get.snackbar('Error', 'Minimum deposit amount is ₹$MIN_DEPOSIT');
      return false;
    }

    if (amount > MAX_DEPOSIT) {
      Get.snackbar('Error', 'Maximum deposit amount is ₹$MAX_DEPOSIT');
      return false;
    }

    try {
      isLoading.value = true;

      // Update wallet balance
      await _db.child('wallets/${user.uid}').update({
        'balance': ServerValue.increment(amount),
      });

      // Record transaction
      await recordTransaction(
        type: 'deposit',
        amount: amount,
        description: 'Added balance to wallet',
        status: 'completed',
      );

      Get.snackbar(
        'Success',
        'Successfully added ₹${amount.toStringAsFixed(2)} to wallet',
        backgroundColor: Colors.green[100],
      );

      return true;
    } catch (e) {
      print('Error adding balance: $e');
      await recordTransaction(
        type: 'deposit',
        amount: amount,
        description: 'Failed to add balance to wallet',
        status: 'failed',
      );

      Get.snackbar(
        'Error',
        'Failed to add balance. Please try again later.',
        backgroundColor: Colors.red[100],
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Deduct balance from wallet
  Future<bool> deductBalance(double amount) async {
    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'User not logged in');
      return false;
    }

    // Validate amount
    if (amount < MIN_WITHDRAWAL) {
      Get.snackbar('Error', 'Minimum withdrawal amount is ₹$MIN_WITHDRAWAL');
      return false;
    }

    // Check if sufficient balance is available
    final validation = await validateTransaction(amount);
    if (!validation['isValid']) {
      Get.snackbar('Error', validation['message']);
      return false;
    }

    try {
      isLoading.value = true;

      // Update wallet balance
      await _db.child('wallets/${user.uid}').update({
        'balance': ServerValue.increment(-amount),
      });

      // Record transaction
      await recordTransaction(
        type: 'withdrawal',
        amount: amount,
        description: 'Withdrew balance from wallet',
        status: 'completed',
      );

      Get.snackbar(
        'Success',
        'Successfully withdrew ₹${amount.toStringAsFixed(2)} from wallet',
        backgroundColor: Colors.green[100],
      );

      return true;
    } catch (e) {
      print('Error deducting balance: $e');
      await recordTransaction(
        type: 'withdrawal',
        amount: amount,
        description: 'Failed to withdraw balance from wallet',
        status: 'failed',
      );

      Get.snackbar(
        'Error',
        'Failed to withdraw balance. Please try again later.',
        backgroundColor: Colors.red[100],
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> validateTransaction(double amount) async {
    if (amount <= 0) {
      return {'isValid': false, 'message': 'Amount must be greater than 0'};
    }

    if (amount > MAX_TRANSACTION) {
      return {'isValid': false, 'message': 'Amount exceeds maximum limit'};
    }

    if (balance.value - amount < MIN_BALANCE) {
      return {'isValid': false, 'message': 'Insufficient balance'};
    }

    return {'isValid': true, 'message': 'Valid transaction'};
  }

  Future<bool> freezeAmount(double amount, String challengeId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final validation = await validateTransaction(amount);
    if (!validation['isValid']) {
      Get.snackbar('Error', validation['message']);
      return false;
    }

    try {
      isLoading.value = true;

      // Update wallet balance
      await _db.child('wallets/${user.uid}').update({
        'balance': balance.value - amount,
        'frozenAmount': frozenBalance.value + amount,
      });

      // Record the frozen amount for this challenge
      await _db.child('frozenFunds').child(challengeId).child(user.uid).set({
        'amount': amount,
        'timestamp': ServerValue.timestamp,
        'expiresAt': DateTime.now()
            .add(const Duration(hours: 24))
            .millisecondsSinceEpoch,
      });

      // Record transaction
      await recordTransaction(
          type: 'freeze',
          amount: amount,
          description: 'Amount frozen for challenge',
          challengeId: challengeId,
          status: 'completed');

      return true;
    } catch (e) {
      print('Error freezing amount: $e');
      await recordTransaction(
          type: 'freeze',
          amount: amount,
          description: 'Failed to freeze amount for challenge',
          challengeId: challengeId,
          status: 'failed');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> transferWinnings(
      String challengeId, String winnerId, String loserId) async {
    try {
      print('Starting transferWinnings for challenge: $challengeId');
      isLoading.value = true;

      final frozenFundsSnapshot =
          await _db.child('frozenFunds').child(challengeId).get();
      print('Frozen funds snapshot exists: ${frozenFundsSnapshot.exists}');

      if (!frozenFundsSnapshot.exists) {
        print('No frozen funds found for challenge: $challengeId');
        return false;
      }

      final frozenFunds = Map.from(frozenFundsSnapshot.value as Map);
      print('Frozen funds: $frozenFunds');

      double totalAmount = 0;

      // Calculate total winnings
      frozenFunds.forEach((userId, data) {
        final Map dataMap = Map.from(data as Map);
        final amount = (dataMap['amount'] as num).toDouble();
        totalAmount += amount;
        print('User $userId contributed: $amount');
      });

      print('Total amount to transfer: $totalAmount');

      // Update winner's wallet
      print('Updating winner wallet for: $winnerId');
      await _db.child('wallets/$winnerId').update({
        'balance': ServerValue.increment(totalAmount),
        'frozenAmount': ServerValue.increment(-(totalAmount / 2)),
      });

      // Record transaction only for the winner
      print('Recording transaction for challenge: $challengeId');
      await _db.child('wallets/$winnerId/transactions').push().set({
        'type': 'win',
        'amount': totalAmount,
        'description': 'Challenge winnings received',
        'challengeId': challengeId,
        'timestamp': ServerValue.timestamp,
        'status': 'completed'
      });

      // Update loser's wallet
      print('Updating loser wallet for: $loserId');
      await _db.child('wallets/$loserId').update({
        'frozenAmount': ServerValue.increment(-(totalAmount / 2)),
      });

      // Record transaction for the loser
      print('Recording transaction for loser: $loserId');
      await _db.child('wallets/$loserId/transactions').push().set({
        'type': 'loss',
        'amount': totalAmount / 2,
        'description': 'Challenge amount lost',
        'challengeId': challengeId,
        'timestamp': ServerValue.timestamp,
        'status': 'completed'
      });

      // Clear frozen funds
      print('Removing frozen funds for challenge: $challengeId');
      await _db.child('frozenFunds').child(challengeId).remove();

      print('Winnings transfer completed successfully');
      return true;
    } catch (e) {
      print('Error transferring winnings: $e');
      return false;
    } finally {
      isLoading.value = false;
      print('Transfer process completed, loading state reset');
    }
  }

  Future<bool> releaseFrozenAmount(String challengeId, String userId) async {
    try {
      isLoading.value = true;

      final frozenRef =
          _db.child('frozenFunds').child(challengeId).child(userId);
      final snapshot = await frozenRef.get();

      if (!snapshot.exists) return false;

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final amount = (data['amount'] as num).toDouble();

      // Return amount to user's wallet
      await _db.child('wallets/$userId').update({
        'balance': ServerValue.increment(amount),
        'frozenAmount': ServerValue.increment(-amount),
      });

      // Record transaction
      await recordTransaction(
          type: 'unfreeze',
          amount: amount,
          description: 'Frozen amount released',
          challengeId: challengeId,
          status: 'completed');

      // Remove frozen fund record
      await frozenRef.remove();

      return true;
    } catch (e) {
      print('Error releasing frozen amount: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> recordTransaction({
    required String type,
    required double amount,
    required String description,
    String? challengeId,
    required String status,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final transactionRef = _db.child('wallets/${user.uid}/transactions').push();
    final transaction = WalletTransaction(
      id: transactionRef.key!,
      type: type,
      amount: amount,
      description: description,
      challengeId: challengeId,
      timestamp: DateTime.now(),
      status: status,
    );

    await transactionRef.set(transaction.toJson());
  }

  Future<void> checkExpiredFrozenAmounts() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final expiredFunds = await _db
        .child('frozenFunds')
        .orderByChild('expiresAt')
        .endAt(now)
        .get();

    if (expiredFunds.exists) {
      final data = Map<String, dynamic>.from(expiredFunds.value as Map);

      for (var challengeId in data.keys) {
        final challenge = Map<String, dynamic>.from(data[challengeId] as Map);

        for (var userId in challenge.keys) {
          await releaseFrozenAmount(challengeId, userId);
        }
      }
    }
  }

  Future<List<WalletTransaction>> getTransactionHistory({
    required int page,
    required int limit,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _db
          .child('wallets/${user.uid}/transactions')
          .orderByChild('timestamp')
          .limitToLast(page * limit)
          .get();

      if (!snapshot.exists) return [];

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final transactions = data.entries
          .map((e) => WalletTransaction.fromJson(
              e.key, Map<String, dynamic>.from(e.value as Map)))
          .toList();

      // Sort and take the required number of transactions
      transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return transactions.take(limit).toList();
    } catch (e) {
      print('Error fetching transaction history: $e');
      return [];
    }
  }
}

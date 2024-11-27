// lib/modules/marketplace/controller/market_controller.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:gamers_gram/data/models/market_item_model.dart';
import 'package:gamers_gram/data/models/purchase_modedl.dart';
import 'package:gamers_gram/data/services/auth_service.dart';
import 'package:get/get.dart';

class MarketController extends GetxController {
  final _db = FirebaseDatabase.instance.ref();
  final _authService = Get.find<AuthService>();

  final items = <MarketItem>[].obs;
  final purchases = <Purchase>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _listenToItems();
    _listenToPurchases();
  }

  void _listenToItems() {
    isLoading.value = true;
    _db.child('marketItems').onValue.listen((event) {
      if (event.snapshot.value != null) {
        items.clear();
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final item = MarketItem.fromJson(Map<String, dynamic>.from(value));
          items.add(item);
        });
      }
      isLoading.value = false;
    }, onError: (error) {
      isLoading.value = false;
      Get.snackbar('Error', 'Failed to load items');
    });
  }

  void _listenToPurchases() {
    final userId = _authService.currentUser.value?.uid;
    if (userId == null) return;

    _db
        .child('purchases')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        purchases.clear();
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final purchase = Purchase.fromJson(Map<String, dynamic>.from(value));
          purchases.add(purchase);
        });
      }
    });
  }

  Future<void> addItem(
    String name,
    String description,
    double price,
    int quantity,
  ) async {
    try {
      final newItemRef = _db.child('marketItems').push();
      final item = MarketItem(
        id: newItemRef.key!,
        name: name,
        description: description,
        price: price,
        quantity: quantity,
      );
      await newItemRef.set(item.toJson());
      Get.snackbar('Success', 'Item added successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add item');
    }
  }

  Future<bool> buyItem(MarketItem item, int quantity) async {
    final userId = _authService.currentUser.value?.uid;
    if (userId == null) return false;

    try {
      // Get current wallet balance
      final walletSnapshot = await _db.child('wallets/$userId').get();
      if (!walletSnapshot.exists) return false;

      final walletData = Map<String, dynamic>.from(walletSnapshot.value as Map);
      final currentBalance = (walletData['balance'] ?? 0.0).toDouble();
      final totalCost = item.price * quantity;

      if (currentBalance < totalCost) {
        Get.snackbar('Error', 'Insufficient balance');
        return false;
      }

      // Instead of using transaction, we'll perform updates sequentially
      try {
        // Update wallet balance
        final newBalance = currentBalance - totalCost;
        await _db.child('wallets/$userId/balance').set(newBalance);

        // Add transaction record
        final transactionRef = _db.child('wallets/$userId/transactions').push();
        await transactionRef.set({
          'amount': -totalCost,
          'description': 'Purchase: ${item.name} x$quantity',
          'id': transactionRef.key,
          'status': 'completed',
          'timestamp': ServerValue.timestamp,
          'type': 'purchase',
        });

        // Update item quantity
        final newQuantity = item.quantity - quantity;
        await _db.child('marketItems/${item.id}/quantity').set(newQuantity);

        // Record purchase
        final purchaseRef = _db.child('purchases').push();
        final purchase = Purchase(
          id: purchaseRef.key!,
          itemId: item.id,
          itemName: item.name,
          quantity: quantity,
          price: item.price,
          userId: userId,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        await purchaseRef.set(purchase.toJson());

        Get.snackbar('Success', 'Purchase completed');
        return true;
      } catch (e) {
        // If any operation fails, we should ideally implement a rollback mechanism here
        Get.snackbar('Error', 'Failed to complete purchase');
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to complete purchase');
      return false;
    }
  }
}

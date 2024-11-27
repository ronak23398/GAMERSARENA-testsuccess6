import 'package:flutter/material.dart';
import 'package:gamers_gram/data/models/market_item_model.dart';
import 'package:gamers_gram/modules/marketplace/controllers/market_controller.dart';
import 'package:get/get.dart';

class MarketView extends GetView<MarketController> {
  const MarketView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showPurchaseHistory(context),
          ),
        ],
      ),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: controller.items.length,
                itemBuilder: (context, index) {
                  final item = controller.items[index];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.description),
                          Text('Price: \$${item.price.toStringAsFixed(2)}'),
                          Text('Available: ${item.quantity}'),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: item.quantity > 0
                            ? () => _showBuyDialog(context, item)
                            : null,
                        child: const Text('Buy'),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final qtyController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Add New Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  priceController.text.isNotEmpty &&
                  qtyController.text.isNotEmpty) {
                controller.addItem(
                    nameController.text,
                    descController.text,
                    double.parse(priceController.text),
                    int.parse(qtyController.text));
                Get.back();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showBuyDialog(BuildContext context, MarketItem item) {
    final qtyController = TextEditingController(text: '1');

    Get.dialog(
      AlertDialog(
        title: Text('Buy ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Price: \$${item.price.toStringAsFixed(2)}'),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(qtyController.text) ?? 0;
              if (quantity > 0) {
                controller.buyItem(item, quantity);
                Get.back();
              }
            },
            child: const Text('Buy'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList() {
    return Obx(
      () => controller.isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: controller.items.length,
              itemBuilder: (context, index) {
                final item = controller.items[index];
                // Find the matching icon from our list

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.description),
                        Text('Price: \$${item.price.toStringAsFixed(2)}'),
                        Text('Available: ${item.quantity}'),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: item.quantity > 0
                          ? () => _showBuyDialog(context, item)
                          : null,
                      child: const Text('Buy'),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showPurchaseHistory(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Purchase History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Obx(() => ListView.builder(
                itemCount: controller.purchases.length,
                itemBuilder: (context, index) {
                  final purchase = controller.purchases[index];
                  return ListTile(
                    title: Text(purchase.itemName),
                    subtitle: Text('Quantity: ${purchase.quantity}\n'
                        'Price: \$${purchase.price.toStringAsFixed(2)}\n'
                        'Date: ${DateTime.fromMillisecondsSinceEpoch(purchase.timestamp)}'),
                    trailing: Text(
                      '\$${(purchase.price * purchase.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              )),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

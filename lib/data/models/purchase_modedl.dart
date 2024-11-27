class Purchase {
  final String id;
  final String itemId;
  final String itemName;
  final int quantity;
  final double price;
  final String userId;
  final int timestamp;

  Purchase({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.price,
    required this.userId,
    required this.timestamp,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) => Purchase(
        id: json['id'] ?? '',
        itemId: json['itemId'] ?? '',
        itemName: json['itemName'] ?? '',
        quantity: json['quantity'] ?? 0,
        price: (json['price'] ?? 0.0).toDouble(),
        userId: json['userId'] ?? '',
        timestamp: json['timestamp'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemId': itemId,
        'itemName': itemName,
        'quantity': quantity,
        'price': price,
        'userId': userId,
        'timestamp': timestamp,
      };
}

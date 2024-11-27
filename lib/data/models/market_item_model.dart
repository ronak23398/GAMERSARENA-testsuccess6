class MarketItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final int quantity;

  MarketItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
  });

  factory MarketItem.fromJson(Map<String, dynamic> json) => MarketItem(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        price: (json['price'] ?? 0.0).toDouble(),
        quantity: json['quantity'] ?? 0,
        // Default icon
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'quantity': quantity,
      };
}

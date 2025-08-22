class FoodCategory {
  final int id;
  final String name;
  final int position;
  final bool isActive;

  FoodCategory({
    required this.id,
    required this.name,
    required this.position,
    required this.isActive,
  });

  factory FoodCategory.fromJson(Map<String, dynamic> json) {
    return FoodCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      position: (json['position'] as int?) ?? 0,
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }
}

class FoodItem {
  final int id;
  final int? categoryId;
  final String name;
  final String? description;
  final String? imageUrl;
  final double price;
  final Map<String, Map<String, dynamic>>? sizePrices;
  final bool isActive;

  FoodItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    this.sizePrices,
    required this.isActive,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    Map<String, Map<String, dynamic>>? sizePrices;
    if (json['size_prices'] != null) {
      final raw = json['size_prices'] as Map<String, dynamic>;
      sizePrices = raw.map(
        (key, value) => MapEntry(key, value as Map<String, dynamic>),
      );
    }

    return FoodItem(
      id: json['id'] as int,
      categoryId: json['category_id'] as int?,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      price: (json['price'] as num).toDouble(),
      sizePrices: sizePrices,
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }

  List<String> get availableSizes {
    if (sizePrices == null) return ['M'];
    return sizePrices!.keys.toList()..sort();
  }

  double getPriceForSize(String size) {
    if (sizePrices == null || !sizePrices!.containsKey(size)) {
      return price; // fallback to base price
    }
    return (sizePrices![size]!['price'] as num).toDouble();
  }

  String? getVolumeForSize(String size) {
    if (sizePrices == null || !sizePrices!.containsKey(size)) {
      return null;
    }
    return sizePrices![size]!['volume'] as String?;
  }
}

class FoodOrderItem {
  final int id;
  final int orderId;
  final int foodId;
  final int quantity;
  final double unitPrice;

  FoodOrderItem({
    required this.id,
    required this.orderId,
    required this.foodId,
    required this.quantity,
    required this.unitPrice,
  });

  factory FoodOrderItem.fromJson(Map<String, dynamic> json) {
    return FoodOrderItem(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      foodId: json['food_id'] as int,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
    );
  }
}

class FoodOrder {
  final int id;
  final String userId;
  final int screeningId;
  final String? seatRow;
  final int? seatNumber;
  final String status;
  final double totalAmount;

  FoodOrder({
    required this.id,
    required this.userId,
    required this.screeningId,
    required this.seatRow,
    required this.seatNumber,
    required this.status,
    required this.totalAmount,
  });

  factory FoodOrder.fromJson(Map<String, dynamic> json) {
    return FoodOrder(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      screeningId: json['screening_id'] as int,
      seatRow: json['seat_row'] as String?,
      seatNumber: json['seat_number'] as int?,
      status: json['status'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
    );
  }
}

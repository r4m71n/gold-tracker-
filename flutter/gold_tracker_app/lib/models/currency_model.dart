class Currency {
  final int id;
  final String name;
  final String code;
  final int price;
  final double change24h;
  final String lastUpdated;

  Currency({
    required this.id,
    required this.name,
    required this.code,
    required this.price,
    required this.change24h,
    required this.lastUpdated,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      price: json['price'],
      change24h: (json['change_24h'] ?? 0).toDouble(),
      lastUpdated: json['last_updated'],
    );
  }
}

class Ingredient {
  final int? id;
  final String name;
  final String unit;
  final double quantity;
  final String? photoPath;
  final bool isCustom;

  const Ingredient({
    this.id,
    required this.name,
    required this.unit,
    this.quantity = 0.0,
    this.photoPath,
    this.isCustom = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'quantity': quantity,
      'photoPath': photoPath,
      'isCustom': isCustom ? 1 : 0,
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'] as int?,
      name: map['name'] as String,
      unit: map['unit'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      photoPath: map['photoPath'] as String?,
      isCustom: (map['isCustom'] as int) == 1,
    );
  }
  
  Ingredient copyWith({
    int? id,
    String? name,
    String? unit,
    double? quantity,
    String? photoPath,
    bool? isCustom,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      photoPath: photoPath ?? this.photoPath,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}
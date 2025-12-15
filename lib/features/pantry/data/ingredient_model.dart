import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Ingredient {
  final String id;
  final String name;
  final String? notes;
  final String unit;
  final int quantity;
  final String? photoPath;
  final String? photoUrl;
  final bool isCustom;

  Ingredient({
    String? id,
    required this.name,
    required this.unit,
    this.notes,
    this.quantity = 0,
    this.photoPath,
    this.photoUrl,
    this.isCustom = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'notes': notes,
      'unit': unit,
      'quantity': quantity,
      'photoPath': photoPath,
      'photoUrl': photoUrl,
      'isCustom': isCustom ? 1 : 0,
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'] as String,
      name: map['name'] as String,
      notes: map['notes'] as String?,
      unit: map['unit'] as String,
      quantity: (map['quantity'] as num).toInt(),
      photoPath: map['photoPath'] as String?,
      photoUrl: map['photoUrl'] as String?,
      isCustom: (map['isCustom'] as int) == 1,
    );
  }

  factory Ingredient.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Ingredient(
      id: doc.id,
      name: data['name'] ?? '',
      unit: data['unit'] ?? 'pcs',
      notes: data['notes'],
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      photoUrl: data['photoUrl'],
      isCustom: data['isCustom'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'unit': unit,
      'photoUrl': photoUrl,
      'isCustom': isCustom,
    };
  }
  
  Ingredient copyWith({
    String? id,
    String? name,
    String? notes,
    String? unit,
    int? quantity,
    String? photoPath,
    String? photoUrl,
    bool? isCustom,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      photoPath: photoPath ?? this.photoPath,
      photoUrl: photoUrl ?? this.photoUrl,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}
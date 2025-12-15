import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Recipe {
  final String id;
  final String name;
  final String? photoPath;
  final String? photoUrl;
  final int cookingTime;
  final String steps;
  final bool isCustom;

  Recipe({
    String? id,
    required this.name,
    this.photoPath,
    this.photoUrl,
    required this.cookingTime,
    required this.steps,
    this.isCustom = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'photoPath': photoPath,
      'photoUrl': photoUrl,
      'cookingTime': cookingTime,
      'steps': steps,
      'isCustom': isCustom ? 1 : 0,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as String,
      name: map['name'] as String,
      photoPath: map['photoPath'] as String?,
      photoUrl: map['photoUrl'] as String?,
      cookingTime: map['cookingTime'] as int,
      steps: map['steps'] as String,
      isCustom: (map['isCustom'] as int) == 1,
    );
  }

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Recipe(
      id: doc.id,
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'],
      cookingTime: (data['cookingTime'] as num?)?.toInt() ?? 0,
      steps: data['steps'] ?? '',
      isCustom: data['isCustom'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'photoUrl': photoUrl,
      'cookingTime': cookingTime,
      'steps': steps,
      'isCustom': isCustom,
    };
  }

  Recipe copyWith({
    String? id,
    String? name,
    String? photoPath,
    String? photoUrl,
    int? cookingTime,
    String? steps,
    bool? isCustom,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
      photoUrl: photoUrl ?? this.photoUrl,
      cookingTime: cookingTime ?? this.cookingTime,
      steps: steps ?? this.steps,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}
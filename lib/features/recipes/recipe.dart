class Recipe {
  final String name;
  final String description;
  final int timeMinutes;
  final int estimatedCost;
  final int servings;
  final String difficulty;
  final int ingredientMatch;

  final List<RecipeIngredient> ingredients;
  final List<String> missingIngredients;
  final List<String> substitutions;
  final List<String> equipment;
  final List<String> steps;
  final List<String> tips;
  final List<String> warnings;

  // Image fetched from the TADKA Firestore dish library.
  final String imageUrl;

  const Recipe({
    required this.name,
    required this.description,
    required this.timeMinutes,
    required this.estimatedCost,
    required this.servings,
    required this.difficulty,
    required this.ingredientMatch,
    required this.ingredients,
    required this.missingIngredients,
    required this.substitutions,
    required this.equipment,
    required this.steps,
    required this.tips,
    required this.warnings,
    this.imageUrl = '',
  });

  Recipe copyWith({
    String? name,
    String? description,
    int? timeMinutes,
    int? estimatedCost,
    int? servings,
    String? difficulty,
    int? ingredientMatch,
    List<RecipeIngredient>? ingredients,
    List<String>? missingIngredients,
    List<String>? substitutions,
    List<String>? equipment,
    List<String>? steps,
    List<String>? tips,
    List<String>? warnings,
    String? imageUrl,
  }) {
    return Recipe(
      name: name ?? this.name,
      description: description ?? this.description,
      timeMinutes: timeMinutes ?? this.timeMinutes,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      servings: servings ?? this.servings,
      difficulty: difficulty ?? this.difficulty,
      ingredientMatch:
      ingredientMatch ?? this.ingredientMatch,
      ingredients:
      ingredients ?? this.ingredients,
      missingIngredients:
      missingIngredients ?? this.missingIngredients,
      substitutions:
      substitutions ?? this.substitutions,
      equipment:
      equipment ?? this.equipment,
      steps: steps ?? this.steps,
      tips: tips ?? this.tips,
      warnings: warnings ?? this.warnings,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory Recipe.fromJson(
      Map<String, dynamic> json,
      ) {
    return Recipe(
      name: _string(json['name']),
      description: _string(json['description']),
      timeMinutes: _int(json['timeMinutes']),
      estimatedCost: _int(json['estimatedCost']),
      servings: _int(json['servings']),
      difficulty: _string(json['difficulty']),
      ingredientMatch:
      _int(json['ingredientMatch']),

      ingredients:
      _listOfMaps(json['ingredients'])
          .map(RecipeIngredient.fromJson)
          .toList(),

      missingIngredients:
      _stringList(
        json['missingIngredients'],
      ),

      substitutions:
      _stringList(
        json['substitutions'],
      ),

      equipment:
      _stringList(
        json['equipment'],
      ),

      steps:
      _stringList(
        json['steps'],
      ),

      tips:
      _stringList(
        json['tips'],
      ),

      warnings:
      _stringList(
        json['warnings'],
      ),

      // Normally this is empty because Gemini doesn't
      // generate the image URL. The service fills it
      // from Firestore afterwards.
      imageUrl:
      _string(json['imageUrl']),
    );
  }

  static String _string(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static int _int(dynamic value) {
    if (value is int) return value;

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  static List<String> _stringList(
      dynamic value,
      ) {
    if (value is! List) return [];

    return value
        .map(
          (item) =>
          item.toString().trim(),
    )
        .where(
          (item) => item.isNotEmpty,
    )
        .toList();
  }

  static List<Map<String, dynamic>>
  _listOfMaps(dynamic value) {
    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map(
          (item) =>
      Map<String, dynamic>.from(item),
    )
        .toList();
  }
}

class RecipeIngredient {
  final String name;
  final String quantity;
  final bool available;

  const RecipeIngredient({
    required this.name,
    required this.quantity,
    required this.available,
  });

  factory RecipeIngredient.fromJson(
      Map<String, dynamic> json,
      ) {
    return RecipeIngredient(
      name:
      json['name']?.toString() ?? '',
      quantity:
      json['quantity']?.toString() ?? '',
      available:
      json['available'] == true,
    );
  }
}
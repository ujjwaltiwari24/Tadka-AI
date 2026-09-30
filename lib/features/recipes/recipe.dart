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
      ingredientMatch: ingredientMatch ?? this.ingredientMatch,
      ingredients: ingredients ?? this.ingredients,
      missingIngredients: missingIngredients ?? this.missingIngredients,
      substitutions: substitutions ?? this.substitutions,
      equipment: equipment ?? this.equipment,
      steps: steps ?? this.steps,
      tips: tips ?? this.tips,
      warnings: warnings ?? this.warnings,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory Recipe.fromJson(
      Map<String, dynamic> json, {
        List<String>? userIngredients,
      }) {
    final rawIngredients = _listOfMaps(json['ingredients'])
        .map(RecipeIngredient.fromJson)
        .toList();

    // Support camelCase and snake_case from AI responses
    int parsedMatch = _int(json['ingredientMatch'] ?? json['ingredient_match']);

    // Fallback calculation if AI returns 0 or missing match score
    if (parsedMatch <= 0) {
      parsedMatch = calculateMatchPercentage(
        recipeIngredients: rawIngredients,
        userIngredients: userIngredients,
      );
    }

    return Recipe(
      name: _string(json['name']),
      description: _string(json['description']),
      timeMinutes: _int(json['timeMinutes'] ?? json['time_minutes']),
      estimatedCost: _int(json['estimatedCost'] ?? json['estimated_cost']),
      servings: _int(json['servings']),
      difficulty: _string(json['difficulty']),
      ingredientMatch: parsedMatch.clamp(0, 100),
      ingredients: rawIngredients,
      missingIngredients: _stringList(
        json['missingIngredients'] ?? json['missing_ingredients'],
      ),
      substitutions: _stringList(json['substitutions']),
      equipment: _stringList(json['equipment']),
      steps: _stringList(json['steps'] ?? json['instructions']),
      tips: _stringList(json['tips']),
      warnings: _stringList(json['warnings']),
      imageUrl: _string(json['imageUrl'] ?? json['image_url']),
    );
  }

  // Universal fuzzy-matching algorithm for match calculation
  static int calculateMatchPercentage({
    required List<RecipeIngredient> recipeIngredients,
    List<String>? userIngredients,
  }) {
    if (recipeIngredients.isEmpty) return 0;

    int matchedCount = 0;

    if (userIngredients != null && userIngredients.isNotEmpty) {
      final normalizedUserInputs = userIngredients
          .map((e) => _normalizeString(e))
          .where((e) => e.isNotEmpty)
          .toSet();

      for (final ing in recipeIngredients) {
        final normRecipeIng = _normalizeString(ing.name);

        final isFuzzyMatch = normalizedUserInputs.any((userIng) {
          return normRecipeIng.contains(userIng) || userIng.contains(normRecipeIng);
        });

        if (ing.available || isFuzzyMatch) {
          matchedCount++;
        }
      }
    } else {
      matchedCount = recipeIngredients.where((i) => i.available).length;
    }

    final percentage = (matchedCount / recipeIngredients.length) * 100;
    return percentage.round().clamp(0, 100);
  }

  static String _normalizeString(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  static String _string(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static List<Map<String, dynamic>> _listOfMaps(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
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

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name']?.toString().trim() ?? '',
      quantity: json['quantity']?.toString().trim() ?? '',
      available: _bool(json['available']),
    );
  }

  static bool _bool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;

    final str = value?.toString().toLowerCase().trim() ?? '';
    return str == 'true' || str == '1' || str == 'yes';
  }
}
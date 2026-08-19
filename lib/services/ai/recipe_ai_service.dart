import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../../features/preferences/cooking_preferences.dart';
import '../../features/recipes/recipe.dart';

class RecipeAIException implements Exception {
  final String message;

  const RecipeAIException(this.message);

  @override
  String toString() => message;
}

class RecipeAIService {
  RecipeAIService._();

  static final RecipeAIService instance =
  RecipeAIService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const Duration _requestTimeout =
  Duration(seconds: 60);

  // ===========================================================================
  // GENERATE RECIPES FROM INGREDIENTS
  // ===========================================================================

  Future<List<Recipe>> generateRecipes({
    required List<String> ingredients,
    required CookingPreferences preferences,
  }) async {
    try {
      if (ingredients.isEmpty) {
        throw const RecipeAIException(
          'Please add at least one ingredient.',
        );
      }

      // -----------------------------------------------------------------------
      // 1. Get Gemini configuration from Firestore
      // -----------------------------------------------------------------------

      final config = await _getGeminiConfig();

      // -----------------------------------------------------------------------
      // 2. Build recipe prompt
      // -----------------------------------------------------------------------

      final prompt = _buildPrompt(
        ingredients: ingredients,
        preferences: preferences,
      );

      // -----------------------------------------------------------------------
      // 3. Call Gemini
      // -----------------------------------------------------------------------

      final generatedText = await _callGemini(
        apiKey: config.apiKey,
        model: config.model,
        prompt: prompt,
      );

      // -----------------------------------------------------------------------
      // 4. Parse response
      // -----------------------------------------------------------------------

      final recipes = _parseRecipes(
        generatedText,
      );

      // -----------------------------------------------------------------------
      // 5. Attach images from Firestore
      // -----------------------------------------------------------------------

      return await _attachDishImages(
        recipes,
      );
    } on RecipeAIException {
      rethrow;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const RecipeAIException(
          'TADKA AI does not have permission to access '
              'its configuration.',
        );
      }

      throw const RecipeAIException(
        'Could not connect to TADKA AI configuration.',
      );
    } on http.ClientException {
      throw const RecipeAIException(
        'Could not connect to Gemini. '
            'Please check your internet connection.',
      );
    } on FormatException {
      throw const RecipeAIException(
        'TADKA AI returned an invalid response.',
      );
    } catch (_) {
      throw const RecipeAIException(
        'Could not reach TADKA AI right now. '
            'Please try again.',
      );
    }
  }

  // ===========================================================================
  // GENERATE RECIPE FROM DISH / USER REQUEST
  // ===========================================================================

  //
  // Examples:
  //
  // "Paneer Butter Masala"
  // "Restaurant style biryani"
  // "Something spicy with paneer"
  // "Easy dinner under 30 minutes"
  //
  // This method intentionally does NOT use CookingPreferences because this
  // flow starts directly from the Home search.
  //
  // ===========================================================================

  Future<List<Recipe>> generateRecipeByName(
      String dishRequest,
      ) async {
    final request = dishRequest.trim();

    if (request.isEmpty) {
      throw const RecipeAIException(
        'Please tell me what you want to cook.',
      );
    }

    try {
      // -----------------------------------------------------------------------
      // 1. Get the same Gemini configuration used by ingredient generation
      // -----------------------------------------------------------------------

      final config = await _getGeminiConfig();

      // -----------------------------------------------------------------------
      // 2. Build dish-search prompt
      // -----------------------------------------------------------------------

      final prompt =
      _buildDishRequestPrompt(request);

      // -----------------------------------------------------------------------
      // 3. Call Gemini
      // -----------------------------------------------------------------------

      final generatedText = await _callGemini(
        apiKey: config.apiKey,
        model: config.model,
        prompt: prompt,
      );

      // -----------------------------------------------------------------------
      // 4. Parse recipe JSON
      // -----------------------------------------------------------------------

      final recipes = _parseRecipes(
        generatedText,
      );

      // -----------------------------------------------------------------------
      // 5. Attach images from Firestore
      // -----------------------------------------------------------------------

      return await _attachDishImages(
        recipes,
      );
    } on RecipeAIException {
      rethrow;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const RecipeAIException(
          'TADKA AI does not have permission to access '
              'its configuration.',
        );
      }

      throw const RecipeAIException(
        'Could not connect to TADKA AI configuration.',
      );
    } on http.ClientException {
      throw const RecipeAIException(
        'Could not connect to Gemini. '
            'Please check your internet connection.',
      );
    } on FormatException {
      throw const RecipeAIException(
        'TADKA AI returned an invalid response.',
      );
    } catch (_) {
      throw const RecipeAIException(
        'Could not reach TADKA AI right now. '
            'Please try again.',
      );
    }
  }

  // ===========================================================================
  // FIRESTORE GEMINI CONFIGURATION
  // ===========================================================================

  Future<_GeminiConfig> _getGeminiConfig() async {
    final configSnapshot = await _firestore
        .collection('app_config')
        .doc('gemini')
        .get();

    if (!configSnapshot.exists) {
      throw const RecipeAIException(
        'TADKA AI configuration was not found.',
      );
    }

    final config = configSnapshot.data();

    if (config == null) {
      throw const RecipeAIException(
        'TADKA AI configuration is empty.',
      );
    }

    final enabled = config['enabled'] == true;

    if (!enabled) {
      throw const RecipeAIException(
        'TADKA AI is temporarily unavailable.',
      );
    }

    final apiKey =
    config['apiKey']?.toString().trim();

    if (apiKey == null || apiKey.isEmpty) {
      throw const RecipeAIException(
        'TADKA AI API key is not configured.',
      );
    }

    var model =
    config['model']?.toString().trim();

    if (model == null || model.isEmpty) {
      model = 'gemini-2.5-flash-lite';
    }

    return _GeminiConfig(
      apiKey: apiKey,
      model: model,
    );
  }

  // ===========================================================================
  // GEMINI REQUEST
  // ===========================================================================

  Future<String> _callGemini({
    required String apiKey,
    required String model,
    required String prompt,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/'
          'models/$model:generateContent',
    );

    final response = await http
        .post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
      },
      body: jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text': prompt,
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.7,
          'responseMimeType': 'application/json',
        },
      }),
    )
        .timeout(_requestTimeout);

    // -------------------------------------------------------------------------
    // Handle Gemini errors
    // -------------------------------------------------------------------------

    if (response.statusCode != 200) {
      String message =
          'TADKA AI could not generate recipes right now.';

      try {
        final errorBody =
        jsonDecode(response.body);

        final error = errorBody['error'];

        if (error is Map) {
          final apiMessage =
          error['message']?.toString();

          if (apiMessage != null &&
              apiMessage.trim().isNotEmpty) {
            message = apiMessage.trim();
          }
        }
      } catch (_) {
        // Keep default message.
      }

      if (response.statusCode == 400) {
        throw const RecipeAIException(
          'TADKA AI rejected the request. '
              'Please try a different request.',
        );
      }

      if (response.statusCode == 401 ||
          response.statusCode == 403) {
        throw const RecipeAIException(
          'TADKA AI authentication failed. '
              'Please check the Gemini API configuration.',
        );
      }

      if (response.statusCode == 429) {
        throw const RecipeAIException(
          'TADKA AI is temporarily busy. '
              'Please try again in a moment.',
        );
      }

      if (response.statusCode >= 500) {
        throw const RecipeAIException(
          'Gemini is temporarily unavailable. '
              'Please try again in a moment.',
        );
      }

      throw RecipeAIException(message);
    }

    // -------------------------------------------------------------------------
    // Decode Gemini response
    // -------------------------------------------------------------------------

    final responseBody =
    jsonDecode(response.body);

    if (responseBody is! Map<String, dynamic>) {
      throw const RecipeAIException(
        'TADKA AI returned an invalid response.',
      );
    }

    final candidates =
    responseBody['candidates'];

    if (candidates is! List ||
        candidates.isEmpty) {
      throw const RecipeAIException(
        'TADKA AI did not return any recipes.',
      );
    }

    final firstCandidate =
        candidates.first;

    if (firstCandidate is! Map) {
      throw const RecipeAIException(
        'TADKA AI returned an invalid recipe response.',
      );
    }

    final content =
    firstCandidate['content'];

    if (content is! Map) {
      throw const RecipeAIException(
        'TADKA AI returned an empty response.',
      );
    }

    final parts = content['parts'];

    if (parts is! List ||
        parts.isEmpty) {
      throw const RecipeAIException(
        'TADKA AI returned an empty response.',
      );
    }

    final textParts = parts
        .whereType<Map>()
        .map(
          (part) =>
      part['text']?.toString() ?? '',
    )
        .where(
          (text) => text.trim().isNotEmpty,
    )
        .toList();

    if (textParts.isEmpty) {
      throw const RecipeAIException(
        'TADKA AI returned an empty recipe response.',
      );
    }

    return textParts.join('\n').trim();
  }

  // ===========================================================================
  // PARSE RECIPES
  // ===========================================================================

  List<Recipe> _parseRecipes(
      String generatedText,
      ) {
    final cleanedJson =
    _cleanJsonResponse(generatedText);

    final decodedRecipes =
    jsonDecode(cleanedJson);

    List<dynamic> recipesJson;

    if (decodedRecipes is List) {
      recipesJson = decodedRecipes;
    } else if (decodedRecipes is Map) {
      final recipes =
      decodedRecipes['recipes'];

      if (recipes is List) {
        recipesJson = recipes;
      } else {
        // Single recipe fallback.
        recipesJson = [
          decodedRecipes,
        ];
      }
    } else {
      throw const RecipeAIException(
        'TADKA AI returned an invalid recipe format.',
      );
    }

    if (recipesJson.isEmpty) {
      throw const RecipeAIException(
        'No suitable recipes were found.',
      );
    }

    final recipes = <Recipe>[];

    for (final recipeJson in recipesJson) {
      if (recipeJson is! Map) {
        continue;
      }

      try {
        final recipe =
        Recipe.fromJson(
          Map<String, dynamic>.from(
            recipeJson,
          ),
        );

        if (recipe.name.trim().isNotEmpty) {
          recipes.add(recipe);
        }
      } catch (_) {
        // Ignore malformed individual recipes.
      }
    }

    if (recipes.isEmpty) {
      throw const RecipeAIException(
        'TADKA AI could not create valid recipes.',
      );
    }

    return recipes;
  }

  // ===========================================================================
  // DISH IMAGE LOOKUP
  // ===========================================================================

  Future<List<Recipe>> _attachDishImages(
      List<Recipe> recipes,
      ) async {
    if (recipes.isEmpty) {
      return recipes;
    }

    final updatedRecipes =
    await Future.wait(
      recipes.map(
            (recipe) async {
          try {
            final imageUrl =
            await _findDishImage(
              recipe.name,
            );

            if (imageUrl.isEmpty) {
              return recipe;
            }

            return recipe.copyWith(
              imageUrl: imageUrl,
            );
          } catch (_) {
            // Image lookup should NEVER break recipe generation.
            return recipe;
          }
        },
      ),
    );

    return updatedRecipes;
  }

  // ===========================================================================
  // FIND DISH IMAGE
  // ===========================================================================

  Future<String> _findDishImage(
      String recipeName,
      ) async {
    final originalName =
    recipeName.trim();

    if (originalName.isEmpty) {
      return '';
    }

    // -------------------------------------------------------------------------
    // 1. Try exact canonical document ID
    //
    // Example:
    // "Paneer Butter Masala"
    //       ↓
    // "paneer_butter_masala"
    //       ↓
    // dishes/paneer_butter_masala
    // -------------------------------------------------------------------------

    final canonicalKey =
    _normalizeDishKey(
      originalName,
    );

    if (canonicalKey.isNotEmpty) {
      final exactSnapshot =
      await _firestore
          .collection('dishes')
          .doc(canonicalKey)
          .get();

      if (exactSnapshot.exists) {
        final data =
        exactSnapshot.data();

        if (data != null) {
          final active =
              data['active'] != false;

          if (active) {
            final image =
            _getPrimaryImage(data);

            if (image.isNotEmpty) {
              return image;
            }
          }
        }
      }
    }

    // -------------------------------------------------------------------------
    // 2. Try aliases using the natural lowercase name
    //
    // Our admin panel stores aliases like:
    //
    // "paneer makhani"
    // "butter paneer"
    //
    // So we search using the same format.
    // -------------------------------------------------------------------------

    final normalizedAlias =
    _normalizeAlias(
      originalName,
    );

    if (normalizedAlias.isNotEmpty) {
      final aliasSnapshot =
      await _firestore
          .collection('dishes')
          .where(
        'aliases',
        arrayContains:
        normalizedAlias,
      )
          .limit(1)
          .get();

      if (aliasSnapshot.docs.isNotEmpty) {
        final data =
        aliasSnapshot.docs.first.data();

        final active =
            data['active'] != false;

        if (active) {
          final image =
          _getPrimaryImage(data);

          if (image.isNotEmpty) {
            return image;
          }
        }
      }
    }

    // -------------------------------------------------------------------------
    // 3. No matching dish/image
    // -------------------------------------------------------------------------

    return '';
  }

  // ===========================================================================
  // GET PRIMARY IMAGE
  // ===========================================================================

  String _getPrimaryImage(
      Map<String, dynamic> data,
      ) {
    final primary =
    data['primaryImageUrl']
        ?.toString()
        .trim();

    if (primary != null &&
        primary.isNotEmpty) {
      return primary;
    }

    final imageUrls =
    data['imageUrls'];

    if (imageUrls is List) {
      for (final item in imageUrls) {
        final url =
        item.toString().trim();

        if (url.isNotEmpty) {
          return url;
        }
      }
    }

    return '';
  }

  // ===========================================================================
  // NORMALIZE DISH KEY
  // ===========================================================================

  String _normalizeDishKey(
      String value,
      ) {
    var result =
    value.toLowerCase().trim();

    // Remove text inside parentheses.
    result = result.replaceAll(
      RegExp(r'\([^)]*\)'),
      '',
    );

    // Convert ampersand.
    result = result.replaceAll(
      '&',
      'and',
    );

    // Remove punctuation.
    result = result.replaceAll(
      RegExp(r'[^a-z0-9]+'),
      ' ',
    );

    // Remove duplicate spaces.
    result = result.replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    result = result.trim();

    // Convert spaces to underscores.
    return result.replaceAll(
      ' ',
      '_',
    );
  }

  // ===========================================================================
  // NORMALIZE ALIAS
  // ===========================================================================

  String _normalizeAlias(
      String value,
      ) {
    var result =
    value.toLowerCase().trim();

    result = result.replaceAll(
      RegExp(r'\([^)]*\)'),
      '',
    );

    result = result.replaceAll(
      '&',
      'and',
    );

    result = result.replaceAll(
      RegExp(r'[^a-z0-9]+'),
      ' ',
    );

    result = result.replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    return result.trim();
  }

  // ===========================================================================
  // INGREDIENT RECIPE PROMPT
  // ===========================================================================

  String _buildPrompt({
    required List<String> ingredients,
    required CookingPreferences preferences,
  }) {
    final ingredientsText = ingredients
        .map(
          (ingredient) =>
          ingredient.trim(),
    )
        .where(
          (ingredient) =>
      ingredient.isNotEmpty,
    )
        .join(', ');

    final avoidText =
    preferences.avoid.isEmpty
        ? 'None'
        : preferences.avoid.join(', ');

    return '''
You are TADKA AI, an intelligent Indian cooking assistant.

Your job is to create practical, delicious and realistic recipes
based strictly on the user's available ingredients and cooking
preferences.

USER INGREDIENTS:
$ingredientsText

COOKING PREFERENCES:
- Maximum cooking time: ${preferences.time}
- Budget: ${preferences.budget}
- Servings: ${preferences.servings}
- Diet: ${preferences.diet}
- Avoid: $avoidText
- Spice level: ${preferences.spiceLevel}
- Cooking skill: ${preferences.skill}

RECIPE REQUIREMENTS:

1. Generate exactly 3 different recipes.
2. Recipes must be realistic and actually cookable.
3. Prefer ingredients the user already has.
4. You may add a small number of common additional ingredients
   when necessary.
5. Clearly list ingredients that the user does not have.
6. Respect the user's diet.
7. Never use ingredients explicitly listed under "Avoid".
8. Respect the requested spice level.
9. Respect the requested cooking skill.
10. Try to stay within the requested cooking time.
11. Try to stay within the requested budget.
12. Quantities must be realistic.
13. Cooking steps must be ordered and easy to follow.
14. Do not invent impossible cooking techniques.
15. Do not provide medical claims.
16. Do not return markdown.
17. Return ONLY valid JSON.
18. Do not wrap the JSON in markdown code blocks.

IMPORTANT FOR DISH NAMES:

Use a natural, standard dish name.

Do not unnecessarily append descriptions,
diet labels or cooking instructions to the name.

For example, prefer:

"Paneer Butter Masala"

instead of:

"Paneer Butter Masala (No Onion No Garlic)"

The dish name should represent the actual dish.

The JSON must be an ARRAY of exactly 3 recipe objects.

Each recipe MUST have exactly these fields:

[
  {
    "name": "Recipe name",
    "description": "Short appetizing description",
    "timeMinutes": 20,
    "estimatedCost": 80,
    "servings": 2,
    "difficulty": "Beginner",
    "ingredientMatch": 90,
    "ingredients": [
      {
        "name": "Potato",
        "quantity": "2 medium",
        "available": true
      },
      {
        "name": "Oil",
        "quantity": "1 tablespoon",
        "available": false
      }
    ],
    "missingIngredients": [
      "Oil"
    ],
    "substitutions": [
      "You can use butter instead of oil."
    ],
    "equipment": [
      "Pan",
      "Knife"
    ],
    "steps": [
      "Wash and cut the potatoes.",
      "Heat oil in a pan.",
      "Cook the potatoes until golden."
    ],
    "tips": [
      "Do not overcrowd the pan."
    ],
    "warnings": []
  }
]

IMPORTANT:

- ingredientMatch must be an integer from 0 to 100.
- timeMinutes must be an integer.
- estimatedCost must be an integer representing INR.
- servings must be an integer.
- ingredients must always be an array of objects.
- available must be true only when the user already has that ingredient.
- missingIngredients must contain ingredients where available is false.
- substitutions must be useful and realistic.
- warnings should only contain genuinely relevant cooking warnings.
- Keep descriptions concise.
- Keep steps clear and practical.
- Return exactly 3 recipes.
''';
  }

  // ===========================================================================
  // DISH SEARCH PROMPT
  // ===========================================================================

  String _buildDishRequestPrompt(
      String request,
      ) {
    return '''
You are TADKA AI, an intelligent cooking assistant.

The user wants to cook:

"$request"

Understand the user's request intelligently.

The request may be:
- an exact dish name
- a regional dish
- a restaurant-style dish
- a specific cuisine
- a craving
- a description such as "something spicy with paneer"
- a request such as "easy dinner under 30 minutes"

If the user gives a specific dish name, create the most
recognizable and practical version of that dish.

If the user gives a vague request, choose a suitable recipe
that matches what the user asked for.

IMPORTANT:
- Do not ask follow-up questions.
- Make reasonable assumptions when information is missing.
- The recipe must actually be cookable.
- Use realistic quantities.
- Use commonly available ingredients where possible.
- Estimated cost must be in INR.
- Do not make medical claims.
- Keep the recipe practical for a normal home kitchen.
- Return ONLY valid JSON.
- Do not return markdown.
- Do not wrap the JSON in ```.

IMPORTANT FOR THE RECIPE NAME:

If the user asks for a specific dish, use the standard canonical
dish name rather than adding unnecessary descriptions.

For example:

"Paneer Butter Masala"

NOT:

"Paneer Butter Masala - Restaurant Style Easy Recipe"

This is important because TADKA AI uses the recipe name to look
for a matching dish image in its image library.

Generate exactly ONE recipe.

Return an ARRAY containing exactly ONE recipe object.

The recipe MUST have exactly these fields:

[
  {
    "name": "Recipe name",
    "description": "Short appetizing description",
    "timeMinutes": 30,
    "estimatedCost": 150,
    "servings": 2,
    "difficulty": "Beginner",
    "ingredientMatch": 0,
    "ingredients": [
      {
        "name": "Paneer",
        "quantity": "250 g",
        "available": false
      },
      {
        "name": "Butter",
        "quantity": "2 tablespoons",
        "available": false
      }
    ],
    "missingIngredients": [
      "Paneer",
      "Butter"
    ],
    "substitutions": [],
    "equipment": [
      "Pan",
      "Knife"
    ],
    "steps": [
      "Prepare the ingredients.",
      "Heat the pan.",
      "Cook the recipe until done."
    ],
    "tips": [
      "Serve hot for the best experience."
    ],
    "warnings": []
  }
]

IMPORTANT:

- ingredientMatch must be an integer from 0 to 100.
- Since the user did not provide their kitchen inventory,
  do NOT assume ingredients are available.
- Set "available" to false for ingredients unless availability
  is explicitly known.
- missingIngredients should therefore contain the ingredients
  needed for the recipe.
- timeMinutes must be an integer.
- estimatedCost must be an integer representing INR.
- servings must be an integer.
- ingredients must always be an array of objects.
- substitutions must be useful and realistic.
- warnings should only contain genuinely relevant cooking warnings.
- Keep descriptions concise.
- Keep steps clear and practical.
- Return exactly ONE recipe.
''';
  }

  // ===========================================================================
  // CLEAN GEMINI JSON
  // ===========================================================================

  String _cleanJsonResponse(
      String text,
      ) {
    var cleaned = text.trim();

    // Remove markdown code fences if Gemini
    // accidentally returns them.
    if (cleaned.startsWith('```')) {
      final firstNewLine =
      cleaned.indexOf('\n');

      if (firstNewLine != -1) {
        cleaned = cleaned.substring(
          firstNewLine + 1,
        );
      }

      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(
          0,
          cleaned.length - 3,
        );
      }
    }

    cleaned = cleaned.trim();

    // Handle accidental text before JSON.
    final arrayStart =
    cleaned.indexOf('[');

    if (arrayStart > 0) {
      cleaned =
          cleaned.substring(arrayStart);
    }

    // Handle accidental text after JSON.
    final arrayEnd =
    cleaned.lastIndexOf(']');

    if (arrayEnd != -1 &&
        arrayEnd < cleaned.length - 1) {
      cleaned = cleaned.substring(
        0,
        arrayEnd + 1,
      );
    }

    return cleaned.trim();
  }
}

// ============================================================================
// GEMINI CONFIG MODEL
// ============================================================================

class _GeminiConfig {
  final String apiKey;
  final String model;

  const _GeminiConfig({
    required this.apiKey,
    required this.model,
  });
}
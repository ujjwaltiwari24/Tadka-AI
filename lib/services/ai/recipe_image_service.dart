import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class RecipeImageException implements Exception {
  final String message;

  const RecipeImageException(this.message);

  @override
  String toString() => message;
}

class RecipeImageService {
  RecipeImageService._();

  static final RecipeImageService instance =
  RecipeImageService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const Duration _timeout =
  Duration(seconds: 60);

  /// Generates a food image for a recipe.
  ///
  /// Returns raw image bytes that can be displayed using
  /// Image.memory().
  Future<Uint8List> generateRecipeImage({
    required String recipeName,
    String? description,
  }) async {
    try {
      if (recipeName.trim().isEmpty) {
        throw const RecipeImageException(
          'Recipe name is empty.',
        );
      }

      // ---------------------------------------------------------
      // 1. Get image-generation configuration
      // ---------------------------------------------------------

      final configSnapshot = await _firestore
          .collection('app_config')
          .doc('image_generation')
          .get();

      if (!configSnapshot.exists) {
        throw const RecipeImageException(
          'Image generation configuration was not found.',
        );
      }

      final config = configSnapshot.data();

      if (config == null) {
        throw const RecipeImageException(
          'Image generation configuration is empty.',
        );
      }

      final enabled = config['enabled'] == true;

      if (!enabled) {
        throw const RecipeImageException(
          'AI food images are temporarily unavailable.',
        );
      }

      final apiKey =
      config['apiKey']?.toString().trim();

      if (apiKey == null || apiKey.isEmpty) {
        throw const RecipeImageException(
          'Image generation API key is not configured.',
        );
      }

      final model =
      config['model']?.toString().trim();

      if (model == null || model.isEmpty) {
        throw const RecipeImageException(
          'Image generation model is not configured.',
        );
      }

      // ---------------------------------------------------------
      // 2. Build image prompt
      // ---------------------------------------------------------

      final prompt = _buildPrompt(
        recipeName: recipeName,
        description: description,
      );

      // ---------------------------------------------------------
      // 3. Gemini image generation request
      // ---------------------------------------------------------

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
            'responseModalities': [
              'IMAGE',
            ],
          },
        }),
      )
          .timeout(_timeout);

      // ---------------------------------------------------------
      // 4. Handle API errors
      // ---------------------------------------------------------

      if (response.statusCode != 200) {
        String message =
            'TADKA could not generate the food image.';

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
          throw RecipeImageException(
            'Gemini rejected the image request. '
                '$message',
          );
        }

        if (response.statusCode == 401 ||
            response.statusCode == 403) {
          throw const RecipeImageException(
            'Gemini image authentication failed.',
          );
        }

        if (response.statusCode == 429) {
          throw RecipeImageException(
            'Gemini 429 RESOURCE_EXHAUSTED\n\n'
                '${response.body}',
          );
        }

        if (response.statusCode >= 500) {
          throw const RecipeImageException(
            'Gemini image generation is temporarily '
                'unavailable.',
          );
        }

        throw RecipeImageException(message);
      }

      // ---------------------------------------------------------
      // 5. Decode Gemini response
      // ---------------------------------------------------------

      final responseBody =
      jsonDecode(response.body);

      if (responseBody
      is! Map<String, dynamic>) {
        throw const RecipeImageException(
          'Gemini returned an invalid image response.',
        );
      }

      final candidates =
      responseBody['candidates'];

      if (candidates is! List ||
          candidates.isEmpty) {
        throw const RecipeImageException(
          'Gemini did not return an image.',
        );
      }

      // ---------------------------------------------------------
      // 6. Find inline image data
      // ---------------------------------------------------------

      for (final candidate in candidates) {
        if (candidate is! Map) {
          continue;
        }

        final content =
        candidate['content'];

        if (content is! Map) {
          continue;
        }

        final parts = content['parts'];

        if (parts is! List) {
          continue;
        }

        for (final part in parts) {
          if (part is! Map) {
            continue;
          }

          final inlineData =
          part['inlineData'];

          if (inlineData is! Map) {
            continue;
          }

          final data =
          inlineData['data']?.toString();

          if (data == null ||
              data.trim().isEmpty) {
            continue;
          }

          try {
            return base64Decode(data);
          } catch (_) {
            throw const RecipeImageException(
              'Gemini returned invalid image data.',
            );
          }
        }
      }

      throw const RecipeImageException(
        'Gemini returned no usable food image.',
      );
    } on RecipeImageException {
      rethrow;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const RecipeImageException(
          'TADKA does not have permission to access '
              'image configuration.',
        );
      }

      throw const RecipeImageException(
        'Could not access image generation configuration.',
      );
    } on http.ClientException {
      throw const RecipeImageException(
        'Could not connect to Gemini image generation.',
      );
    } on FormatException {
      throw const RecipeImageException(
        'Gemini returned an invalid image response.',
      );
    } catch (_) {
      throw const RecipeImageException(
        'Could not generate the food image right now.',
      );
    }
  }

  String _buildPrompt({
    required String recipeName,
    String? description,
  }) {
    final cleanName = recipeName.trim();

    final cleanDescription =
        description?.trim() ?? '';

    return '''
Create a realistic and appetizing food photograph
of the Indian dish "$cleanName".

${cleanDescription.isNotEmpty ? 'Dish description: $cleanDescription' : ''}

The image is for a mobile cooking application.

Requirements:
- Photorealistic food photography.
- The dish must clearly look like "$cleanName".
- Freshly cooked and appetizing.
- Realistic Indian food appearance.
- Natural warm lighting.
- Clean, simple background.
- Food should be the main focus.
- Attractive but realistic presentation.
- Three-quarter overhead food photography angle.
- Realistic portion size.
- No people.
- No hands.
- No text.
- No logos.
- No watermark.
- No UI elements.
- No plates or props covering the food.
''';
  }
}
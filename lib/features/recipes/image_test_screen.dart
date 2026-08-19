import 'package:flutter/material.dart';

import '../../services/ai/recipe_image_service.dart';
import 'dart:typed_data';
class ImageTestScreen extends StatefulWidget {
  const ImageTestScreen({super.key});

  @override
  State<ImageTestScreen> createState() =>
      _ImageTestScreenState();
}

class _ImageTestScreenState
    extends State<ImageTestScreen> {
  bool _loading = false;
  String? _error;
  Uint8List? _imageBytes;

  Future<void> _generateImage() async {
    setState(() {
      _loading = true;
      _error = null;
      _imageBytes = null;
    });

    try {
      final image =
      await RecipeImageService.instance
          .generateRecipeImage(
        recipeName: 'Paneer Masala',
        description:
        'A rich and creamy Indian paneer curry made with tomatoes, onions and aromatic spices.',
      );

      if (!mounted) return;

      setState(() {
        _imageBytes = image;
        _loading = false;
      });
    } on RecipeImageException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Image Test',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _buildContent(),
              ),
            ),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed:
                _loading ? null : _generateImage,
                child: Text(
                  _loading
                      ? 'GENERATING...'
                      : 'GENERATE FOOD IMAGE',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 18),
          Text(
            'Creating your food image...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'This may take a few seconds.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 14),
          const Text(
            'Image generation failed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    if (_imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.memory(
          _imageBytes!,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.restaurant_rounded,
          size: 64,
          color: Colors.orange,
        ),
        SizedBox(height: 16),
        Text(
          'Paneer Masala',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Tap the button to generate an AI food image.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
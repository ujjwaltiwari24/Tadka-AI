import express from 'express';

import {
  generateRecipes,
} from '../services/gemini_service.js';

const router = express.Router();

router.post('/generate', async (req, res) => {
  try {
    const {
      ingredients,
      preferences,
    } = req.body;

    if (!Array.isArray(ingredients)) {
      return res.status(400).json({
        success: false,
        message:
          'Ingredients must be provided as an array.',
      });
    }

    if (ingredients.length === 0) {
      return res.status(400).json({
        success: false,
        message:
          'Please provide at least one ingredient.',
      });
    }

    if (ingredients.length > 50) {
      return res.status(400).json({
        success: false,
        message:
          'You can provide a maximum of 50 ingredients.',
      });
    }

    if (
      !preferences ||
      typeof preferences !== 'object'
    ) {
      return res.status(400).json({
        success: false,
        message:
          'Cooking preferences are required.',
      });
    }

    const cleanedIngredients = ingredients
      .map((ingredient) =>
        String(ingredient).trim(),
      )
      .filter(
        (ingredient) =>
          ingredient.length > 0,
      );

    if (cleanedIngredients.length === 0) {
      return res.status(400).json({
        success: false,
        message:
          'Please provide valid ingredients.',
      });
    }

    const recipes = await generateRecipes({
      ingredients: cleanedIngredients,
      preferences,
    });

    return res.status(200).json({
      success: true,
      recipes,
    });
  } catch (error) {
    console.error(
      'Recipe route error:',
      error,
    );

    return res.status(500).json({
      success: false,
      message:
        'TADKA AI could not generate recipes right now.',
    });
  }
});

export default router;
import { GoogleGenAI } from '@google/genai';

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

if (!GEMINI_API_KEY) {
  console.error('❌ GEMINI_API_KEY is missing.');
  process.exit(1);
}

const ai = new GoogleGenAI({
  apiKey: GEMINI_API_KEY,
});

/*
 * We try the preferred model first.
 * If Google temporarily returns 503/UNAVAILABLE,
 * we automatically try the fallback model.
 */
const MODELS = [
  'gemini-3.6-flash',
  'gemini-2.5-flash',
];

const recipeSchema = {
  type: 'object',

  properties: {
    recipes: {
      type: 'array',

      items: {
        type: 'object',

        properties: {
          name: {
            type: 'string',
          },

          description: {
            type: 'string',
          },

          timeMinutes: {
            type: 'integer',
          },

          estimatedCost: {
            type: 'integer',
          },

          servings: {
            type: 'integer',
          },

          difficulty: {
            type: 'string',
          },

          ingredientMatch: {
            type: 'integer',
          },

          ingredients: {
            type: 'array',

            items: {
              type: 'object',

              properties: {
                name: {
                  type: 'string',
                },

                quantity: {
                  type: 'string',
                },

                available: {
                  type: 'boolean',
                },
              },

              required: [
                'name',
                'quantity',
                'available',
              ],
            },
          },

          missingIngredients: {
            type: 'array',

            items: {
              type: 'string',
            },
          },

          substitutions: {
            type: 'array',

            items: {
              type: 'string',
            },
          },

          equipment: {
            type: 'array',

            items: {
              type: 'string',
            },
          },

          steps: {
            type: 'array',

            items: {
              type: 'string',
            },
          },

          tips: {
            type: 'array',

            items: {
              type: 'string',
            },
          },

          warnings: {
            type: 'array',

            items: {
              type: 'string',
            },
          },
        },

        required: [
          'name',
          'description',
          'timeMinutes',
          'estimatedCost',
          'servings',
          'difficulty',
          'ingredientMatch',
          'ingredients',
          'missingIngredients',
          'substitutions',
          'equipment',
          'steps',
          'tips',
          'warnings',
        ],
      },
    },
  },

  required: [
    'recipes',
  ],
};

function sanitizePreferences(preferences) {
  return {
    time: String(
      preferences?.time ??
        'Not specified',
    ),

    budget: String(
      preferences?.budget ??
        'Not specified',
    ),

    servings: Number(
      preferences?.servings ?? 2,
    ),

    diet: String(
      preferences?.diet ??
        'No preference',
    ),

    avoid: Array.isArray(
      preferences?.avoid,
    )
      ? preferences.avoid
          .map((item) =>
            String(item).trim(),
          )
          .filter(Boolean)
      : [],

    spiceLevel: String(
      preferences?.spiceLevel ??
        'Medium',
    ),

    skill: String(
      preferences?.skill ??
        'Beginner',
    ),
  };
}

function buildPrompt({
  ingredients,
  preferences,
}) {
  const safePreferences =
    sanitizePreferences(
      preferences,
    );

  return `
You are TADKA AI, an Indian cooking assistant.

Create up to 3 realistic recipes from the user's ingredients.

USER INGREDIENTS:
${JSON.stringify(
  ingredients,
)}

USER PREFERENCES:
${JSON.stringify(
  safePreferences,
)}

RULES:

- Respect diet strictly.
- Never use anything in "avoid".
- Respect cooking time.
- Respect budget.
- Respect servings.
- Respect spice level.
- Respect cooking skill.
- Prefer ingredients already available.
- Clearly identify missing ingredients.
- Use realistic Indian quantities.
- estimatedCost must be approximate INR.
- ingredientMatch must be between 0 and 100.
- Never invent ridiculous combinations.
- If the ingredients cannot reasonably make a meal,
  return ONE result named "No suitable recipe found".
- Keep descriptions short.
- Keep cooking steps concise.
- Return ONLY JSON matching the schema.
`;
}

function validateRecipes(data) {
  if (
    !data ||
    typeof data !== 'object' ||
    !Array.isArray(
      data.recipes,
    )
  ) {
    throw new Error(
      'Invalid Gemini response.',
    );
  }

  if (
    data.recipes.length === 0
  ) {
    throw new Error(
      'Gemini returned no recipes.',
    );
  }

  return data.recipes
    .slice(0, 3)
    .map((recipe) => ({
      name: String(
        recipe.name ?? '',
      ).trim(),

      description: String(
        recipe.description ?? '',
      ).trim(),

      timeMinutes: Number(
        recipe.timeMinutes ?? 0,
      ),

      estimatedCost: Number(
        recipe.estimatedCost ?? 0,
      ),

      servings: Number(
        recipe.servings ?? 1,
      ),

      difficulty: String(
        recipe.difficulty ??
          'Easy',
      ),

      ingredientMatch: Math.min(
        100,
        Math.max(
          0,
          Number(
            recipe.ingredientMatch ??
              0,
          ),
        ),
      ),

      ingredients:
        Array.isArray(
          recipe.ingredients,
        )
          ? recipe.ingredients.map(
              (ingredient) => ({
                name: String(
                  ingredient.name ??
                    '',
                ),

                quantity: String(
                  ingredient.quantity ??
                    '',
                ),

                available:
                  Boolean(
                    ingredient.available,
                  ),
              }),
            )
          : [],

      missingIngredients:
        Array.isArray(
          recipe.missingIngredients,
        )
          ? recipe.missingIngredients.map(
              String,
            )
          : [],

      substitutions:
        Array.isArray(
          recipe.substitutions,
        )
          ? recipe.substitutions.map(
              String,
            )
          : [],

      equipment:
        Array.isArray(
          recipe.equipment,
        )
          ? recipe.equipment.map(
              String,
            )
          : [],

      steps:
        Array.isArray(
          recipe.steps,
        )
          ? recipe.steps.map(
              String,
            )
          : [],

      tips:
        Array.isArray(
          recipe.tips,
        )
          ? recipe.tips.map(
              String,
            )
          : [],

      warnings:
        Array.isArray(
          recipe.warnings,
        )
          ? recipe.warnings.map(
              String,
            )
          : [],
    }));
}

function isTemporaryGeminiError(error) {
  const status =
    error?.status ??
    error?.code;

  const message =
    String(
      error?.message ?? '',
    ).toLowerCase();

  return (
    status === 503 ||
    status === 429 ||
    message.includes(
      'high demand',
    ) ||
    message.includes(
      'unavailable',
    ) ||
    message.includes(
      'overloaded',
    ) ||
    message.includes(
      'rate limit',
    )
  );
}

function sleep(milliseconds) {
  return new Promise(
    (resolve) =>
      setTimeout(
        resolve,
        milliseconds,
      ),
  );
}

async function generateWithModel(
  model,
  prompt,
) {
  console.log(
    `🤖 Trying model: ${model}`,
  );

  const startTime =
    Date.now();

  const response =
    await ai.models.generateContent({
      model,

      contents: prompt,

      config: {
        temperature: 0.6,

        responseMimeType:
          'application/json',

        responseSchema:
          recipeSchema,
      },
    });

  const elapsed =
    Date.now() -
    startTime;

  console.log(
    `⏱️ ${model}: ${(elapsed / 1000).toFixed(1)}s`,
  );

  if (!response.text) {
    throw new Error(
      'Gemini returned an empty response.',
    );
  }

  let parsed;

  try {
    parsed = JSON.parse(
      response.text,
    );
  } catch {
    throw new Error(
      'Gemini returned invalid JSON.',
    );
  }

  return validateRecipes(
    parsed,
  );
}

export async function generateRecipes({
  ingredients,
  preferences,
}) {
  const prompt =
    buildPrompt({
      ingredients,
      preferences,
    });

  let lastError;

  for (
    let modelIndex = 0;
    modelIndex < MODELS.length;
    modelIndex++
  ) {
    const model =
      MODELS[modelIndex];

    try {
      const recipes =
        await generateWithModel(
          model,
          prompt,
        );

      console.log(
        `✅ ${model} generated ${recipes.length} result(s).`,
      );

      return recipes;
    } catch (error) {
      lastError = error;

      console.error(
        `❌ ${model} failed:`,
        error?.message ??
          error,
      );

      if (
        !isTemporaryGeminiError(
          error,
        )
      ) {
        break;
      }

      /*
       * Give the temporary overloaded
       * model a short chance to recover
       * before moving to the fallback.
       */
      if (
        modelIndex <
        MODELS.length - 1
      ) {
        console.log(
          '⏳ Temporary Gemini issue. Trying fallback model...',
        );

        await sleep(1200);
      }
    }
  }

  console.error(
    '❌ All Gemini models failed.',
    lastError,
  );

  throw new Error(
    'TADKA AI is temporarily busy. Please try again in a moment.',
  );
}
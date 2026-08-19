import 'dotenv/config';

import express from 'express';
import cors from 'cors';

import recipeRoutes from './routes/recipe_routes.js';

const app = express();

const PORT = Number(process.env.PORT || 3000);

app.use(cors());

app.use(
  express.json({
    limit: '1mb',
  }),
);

app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    service: 'TADKA AI Backend',
    status: 'healthy',
  });
});

app.use('/api/recipes', recipeRoutes);

app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint not found.',
  });
});

app.use((error, req, res, next) => {
  console.error('Unhandled server error:', error);

  res.status(500).json({
    success: false,
    message: 'Something went wrong on the server.',
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log('');
  console.log('🔥 TADKA AI Backend');
  console.log('────────────────────────────');
  console.log(`🚀 Server: http://localhost:${PORT}`);
  console.log(`❤️  Health: http://localhost:${PORT}/health`);
  console.log('🤖 Gemini: Ready');
  console.log('────────────────────────────');
  console.log('');
});
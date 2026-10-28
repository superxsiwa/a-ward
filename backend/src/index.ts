import express from 'express';
import cors from 'cors';
import path from 'path';
import fs from 'fs';
import { ENV } from './config/env';
import authRoutes from './routes/auth.routes';
import casesRoutes from './routes/cases.routes';
import progressRoutes from './routes/progress.routes';
import rosterRoutes from './routes/roster.routes';
import instructorRoutes from './routes/instructor.routes';
import { errorHandler } from './middleware/errorHandler';
import { seedDefaultCases, seedDemoUsers } from './services/seedService';

const app = express();

app.use(cors());
app.use(express.json({ limit: '10mb' }));

// Health check
app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', service: 'Critical Care API', timestamp: new Date().toISOString() });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/cases', casesRoutes);
app.use('/api/progress', progressRoutes);
app.use('/api/roster', rosterRoutes);
app.use('/api/instructor', instructorRoutes);

// Serve Frontend SPA build in production if available
const frontendDist = path.resolve(__dirname, '../../frontend/dist');
if (fs.existsSync(frontendDist)) {
  app.use(express.static(frontendDist));
  app.get('*', (req, res, next) => {
    if (req.path.startsWith('/api')) {
      next();
      return;
    }
    res.sendFile(path.join(frontendDist, 'index.html'));
  });
}

app.use(errorHandler);

async function bootstrap() {
  try {
    await seedDefaultCases(false);
    await seedDemoUsers();
  } catch (err) {
    console.warn('Initial seed check warning:', err);
  }

  app.listen(ENV.PORT, () => {
    console.log(`🩺 Critical Care Full-Stack Backend running at http://localhost:${ENV.PORT}`);
  });
}

bootstrap();

export default app;

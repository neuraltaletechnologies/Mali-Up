import fastify from 'fastify';
import { serializerCompiler, validatorCompiler, ZodTypeProvider } from 'fastify-type-provider-zod';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import jwt from '@fastify/jwt';
import rateLimit from '@fastify/rate-limit';
import autoload from '@fastify/autoload';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Fail fast rather than silently signing every JWT with a public,
// hardcoded string if the operator forgets to set JWT_SECRET.
const jwtSecret = process.env.JWT_SECRET;
if (!jwtSecret) {
  throw new Error('JWT_SECRET environment variable must be set — refusing to start with an insecure default.');
}

const allowedOrigins = (process.env.CORS_ALLOWED_ORIGINS ?? '')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

export const buildApp = async () => {
  const app = fastify({
    logger: true,
  }).withTypeProvider<ZodTypeProvider>();

  // Zod Compilers
  app.setValidatorCompiler(validatorCompiler);
  app.setSerializerCompiler(serializerCompiler);

  // Core Plugins
  await app.register(helmet);
  await app.register(cors, {
    // Reflects every origin if none are configured, so local/dev setups
    // keep working — set CORS_ALLOWED_ORIGINS in production.
    origin: allowedOrigins.length > 0 ? allowedOrigins : true,
  });
  await app.register(jwt, { secret: jwtSecret });
  await app.register(rateLimit, {
    global: true,
    max: 100,
    timeWindow: '1 minute',
  });

  // Autoload Plugins
  await app.register(autoload, {
    dir: path.join(__dirname, 'plugins'),
  });

  // Autoload Routes
  await app.register(autoload, {
    dir: path.join(__dirname, 'routes'),
    options: { prefix: '/api/v1' },
  });

  app.get('/health', async () => {
    return { status: 'OK', service: 'auth-service', version: '1.0.0' };
  });

  return app;
};

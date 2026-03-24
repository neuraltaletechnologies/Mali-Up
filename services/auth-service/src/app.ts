import fastify from 'fastify';
import { serializerCompiler, validatorCompiler, ZodTypeProvider } from 'fastify-type-provider-zod';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import jwt from '@fastify/jwt';
import autoload from '@fastify/autoload';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export const buildApp = async () => {
  const app = fastify({
    logger: true,
  }).withTypeProvider<ZodTypeProvider>();

  // Zod Compilers
  app.setValidatorCompiler(validatorCompiler);
  app.setSerializerCompiler(serializerCompiler);

  // Core Plugins
  await app.register(helmet);
  await app.register(cors, { origin: true });
  await app.register(jwt, {
    secret: process.env.JWT_SECRET || 'neuraltale-shhh-dont-tell-anyone-it-is-a-secret',
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

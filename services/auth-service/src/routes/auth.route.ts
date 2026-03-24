import { FastifyInstance } from 'fastify';
import { loginHandler, registerHandler } from '../controllers/auth.controller.js';
import { loginSchema, registerSchema } from '../schemas/auth.schema.js';

export default async function authRoutes(app: FastifyInstance) {
  app.post('/auth/register', {
    schema: {
      body: registerSchema,
    },
    handler: registerHandler,
  });

  app.post('/auth/login', {
    schema: {
      body: loginSchema,
    },
    handler: loginHandler,
  });
}

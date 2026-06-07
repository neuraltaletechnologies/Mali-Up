import { FastifyInstance } from 'fastify';
import { loginHandler, registerHandler } from '../controllers/auth.controller.js';
import { lookupHandler } from '../controllers/lookup.controller.js';
import { recoveryHandler } from '../controllers/recovery.controller.js';
import { loginSchema, registerSchema, lookupSchema, recoverySchema } from '../schemas/auth.schema.js';

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

  app.post('/auth/lookup', {
    schema: {
      body: lookupSchema,
    },
    handler: lookupHandler,
  });

  app.post('/auth/recovery', {
    schema: {
      body: recoverySchema,
    },
    handler: recoveryHandler,
  });
}

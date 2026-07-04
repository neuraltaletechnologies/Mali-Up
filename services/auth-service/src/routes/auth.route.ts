import { FastifyInstance } from 'fastify';
import { loginHandler, registerHandler } from '../controllers/auth.controller.js';
import { lookupHandler } from '../controllers/lookup.controller.js';
import { recoveryHandler } from '../controllers/recovery.controller.js';
import { loginSchema, registerSchema, lookupSchema, recoverySchema } from '../schemas/auth.schema.js';

// Sensitive auth endpoints get a tighter per-IP limit than the app-wide
// default — these are exactly the routes brute-force/enumeration targets.
const strictRateLimit = { max: 10, timeWindow: '1 minute' };

export default async function authRoutes(app: FastifyInstance) {
  app.post('/auth/register', {
    schema: {
      body: registerSchema,
    },
    config: { rateLimit: strictRateLimit },
    handler: registerHandler,
  });

  app.post('/auth/login', {
    schema: {
      body: loginSchema,
    },
    config: { rateLimit: strictRateLimit },
    handler: loginHandler,
  });

  app.post('/auth/lookup', {
    schema: {
      body: lookupSchema,
    },
    config: { rateLimit: strictRateLimit },
    handler: lookupHandler,
  });

  app.post('/auth/recovery', {
    schema: {
      body: recoverySchema,
    },
    config: { rateLimit: strictRateLimit },
    handler: recoveryHandler,
  });
}

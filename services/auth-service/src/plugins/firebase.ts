import fp from 'fastify-plugin';
import admin from 'firebase-admin';

export default fp(async (fastify) => {
  if (!admin.apps.length) {
    admin.initializeApp({
      projectId: process.env.FIREBASE_PROJECT_ID || 'neuraltale-mali-up',
    });
  }

  const firestore = admin.firestore();
  fastify.decorate('firestore', firestore);
  fastify.decorate('firebaseAdmin', admin);
});

declare module 'fastify' {
  interface FastifyInstance {
    firestore: admin.firestore.Firestore;
    firebaseAdmin: typeof admin;
  }
}

import fp from 'fastify-plugin';
import { FastifyPluginAsync } from 'fastify';

declare module 'fastify' {
  interface FastifyInstance {
    prisma: any;
  }
}

const prismaPlugin: FastifyPluginAsync = fp(async (server) => {
  const prisma = {};

  server.decorate('prisma', prisma);
});

export default prismaPlugin;

import { buildApp } from './app.js';
import 'dotenv/config';

const start = async () => {
  const app = await buildApp();
  const port = Number(process.env.PORT) || 3001;
  const host = '0.0.0.0';

  try {
    await app.listen({ port, host });
    console.log(`🚀 Auth Service is listening on http://${host}:${port}`);
    console.log(`📡 Health Check: http://${host}:${port}/health`);
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
};

start();

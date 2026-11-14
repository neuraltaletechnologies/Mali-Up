/**
 * Local-only Workers AI proxy for scripts/backfill-catalog-images.ts.
 * POST { prompt, steps } → { result: { image: <base64 jpeg> } }, the
 * same shape as the Cloudflare REST API, so the script handles both alike.
 * See wrangler.toml — run with `wrangler dev`, never deploy.
 */
interface Env {
  AI: { run(model: string, input: Record<string, unknown>): Promise<{ image?: string }> };
}

const MODEL = '@cf/black-forest-labs/flux-1-schnell';

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method !== 'POST') return new Response('POST only', { status: 405 });
    try {
      const { prompt, steps } = (await request.json()) as { prompt: string; steps?: number };
      const out = await env.AI.run(MODEL, { prompt, steps: steps ?? 6 });
      if (!out.image) return Response.json({ errors: ['no image returned'] }, { status: 502 });
      return Response.json({ result: { image: out.image } });
    } catch (e) {
      return Response.json({ errors: [String(e)] }, { status: 500 });
    }
  },
};

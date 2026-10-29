// Interop smoke test: loads the dart2js runtime in Node (with browser
// globals polyfilled, as node.ts does) and asserts the installed surface.
// Run `npm run build:dart` first (npm test assumes it; CI runs build).
import { beforeAll, expect, test } from 'vitest';

beforeAll(async () => {
  const g = globalThis as any;
  if (typeof g.self === 'undefined') g.self = g;
  if (typeof g.window === 'undefined') g.window = g;
  await import('../build/dart/google_texttospeech_js.js');
});

test('installs GoogleTtsJs with the expected surface', async () => {
  const ns = (globalThis as any).GoogleTtsJs;
  expect(ns).toBeDefined();
  expect(ns.version).toBe('0.1.0');
  expect(typeof ns.withApiKey).toBe('function');
  expect(typeof ns.withOAuth).toBe('function');

  const handle = await ns.withApiKey('test-key', undefined);
  expect(typeof handle.voicesList).toBe('function');
  expect(typeof handle.synthesize).toBe('function');
  expect(typeof handle.close).toBe('function');
  handle.close();
});

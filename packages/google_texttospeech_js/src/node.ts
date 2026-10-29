/**
 * Node.js entrypoint for google_texttospeech_js.
 *
 * dart2js output targets the browser runtime — it expects `self`/`window`
 * globals, so we polyfill them before loading the compiled module.
 */

import { GoogleTts as Base } from './index.js';
import type { ConnectOptions } from './types.js';

export * from './index.js';

const ensurePolyfills = () => {
  const g = globalThis as any;
  if (typeof g.self === 'undefined') g.self = g;
  if (typeof g.window === 'undefined') g.window = g;
};

const loadDart = async () => {
  ensurePolyfills();
  // @ts-expect-error -- resolved at build/runtime; the file sits in dist/.
  await import('./google_texttospeech_js.runtime.js');
};

export class GoogleTts extends Base {
  static override async withApiKey(
    apiKey: string,
    opts: ConnectOptions = {},
  ): Promise<GoogleTts> {
    return (await Base.withApiKey(apiKey, opts, loadDart)) as GoogleTts;
  }

  static override async withOAuth(
    opts: ConnectOptions = {},
  ): Promise<GoogleTts> {
    return (await Base.withOAuth(opts, loadDart)) as GoogleTts;
  }

  /**
   * Convenience: create from `process.env.GOOGLE_TTS_API_KEY`, or `null` if
   * unset. Node-only (browsers have no `process`).
   */
  static async fromEnv(
    opts: ConnectOptions = {},
  ): Promise<GoogleTts | null> {
    const apiKey = process.env.GOOGLE_TTS_API_KEY;
    if (!apiKey) return null;
    return GoogleTts.withApiKey(apiKey, opts);
  }
}

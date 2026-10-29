/**
 * Loads the dart2js-compiled runtime and returns the `GoogleTtsJs` namespace
 * installed on `globalThis`. Dispatch is platform-specific — see `browser.ts`
 * and `node.ts` for the loader implementations.
 */

import type { GoogleTtsJsNamespace } from './types.js';

let cached: GoogleTtsJsNamespace | undefined;

export type DartRuntimeLoader = () => Promise<void>;

export async function getRuntime(
  loader: DartRuntimeLoader,
): Promise<GoogleTtsJsNamespace> {
  if (cached) return cached;
  await loader();
  const ns = (globalThis as any).GoogleTtsJs as
    | GoogleTtsJsNamespace
    | undefined;
  if (!ns) {
    throw new Error(
      'google_texttospeech_js runtime failed to initialise: ' +
        'globalThis.GoogleTtsJs was not installed.',
    );
  }
  cached = ns;
  return ns;
}

/**
 * Browser entrypoint for google_texttospeech_js.
 *
 * Loads the dart2js runtime (copied to dist by scripts/build.sh) and re-exports
 * the public API bound to it.
 */

import { GoogleTts as Base } from './index.js';
import type { ConnectOptions } from './types.js';

export * from './index.js';

const loadDart = async () => {
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
}

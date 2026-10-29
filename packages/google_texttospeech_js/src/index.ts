/**
 * google_texttospeech_js — public TypeScript API.
 *
 * Wraps the dart2js-compiled `google_texttospeech` core in an idiomatic,
 * Promise-based, typed API for the Google Cloud Text-to-Speech REST API v1.
 * The loader-less base lives here; `browser.ts` / `node.ts` bind the concrete
 * dart2js runtime and re-export this class's surface.
 */

import { getRuntime, type DartRuntimeLoader } from './runtime.js';
import type {
  ConnectOptions,
  GoogleTtsJsHandle,
  ListVoicesResponse,
  SynthesizeSpeechRequest,
  SynthesizeSpeechResponse,
} from './types.js';

export * from './types.js';

export class GoogleTts {
  protected constructor(private readonly handle: GoogleTtsJsHandle) {}

  /** Create a client using a Cloud Console API key (browser-recommended). */
  static async withApiKey(
    apiKey: string,
    opts: ConnectOptions = {},
    loader?: DartRuntimeLoader,
  ): Promise<GoogleTts> {
    const ns = await getRuntime(requireLoader(loader));
    const handle = await ns.withApiKey(apiKey, opts.logLevel);
    return new GoogleTts(handle);
  }

  /**
   * Create a client using OAuth. Unsupported in the browser (needs a loopback
   * redirect + filesystem); provided for Node parity with the Dart client.
   */
  static async withOAuth(
    opts: ConnectOptions = {},
    loader?: DartRuntimeLoader,
  ): Promise<GoogleTts> {
    const ns = await getRuntime(requireLoader(loader));
    const handle = await ns.withOAuth(opts.logLevel);
    return new GoogleTts(handle);
  }

  /** List voices, optionally filtered to a BCP-47 language (e.g. `en-US`). */
  voicesList(languageCode?: string): Promise<ListVoicesResponse> {
    return this.handle.voicesList(languageCode);
  }

  /** Synthesize speech; the response's `audioContent` is base64-encoded. */
  synthesize(
    request: SynthesizeSpeechRequest,
  ): Promise<SynthesizeSpeechResponse> {
    return this.handle.synthesize(request);
  }

  /** Close the underlying HTTP client. */
  close(): void {
    this.handle.close();
  }
}

function requireLoader(loader?: DartRuntimeLoader): DartRuntimeLoader {
  if (!loader) {
    throw new Error(
      "No Dart runtime loader provided. Import from " +
        "'@unngh/google-texttospeech/browser' or " +
        "'@unngh/google-texttospeech/node' instead.",
    );
  }
  return loader;
}

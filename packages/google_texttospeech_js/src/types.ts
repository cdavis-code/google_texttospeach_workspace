/** Public TypeScript type surface for @unngh/google-texttospeech. */

export type AudioEncoding = 'LINEAR16' | 'MP3' | 'OGG_OPUS';
export type SsmlVoiceGender =
  | 'SSML_GENDER_UNSPECIFIED'
  | 'MALE'
  | 'FEMALE'
  | 'NEUTRAL';

export interface SynthesisInput {
  text?: string;
  ssml?: string;
  /** System instruction for promptable models (e.g. Gemini-TTS). */
  prompt?: string;
}

export interface VoiceSelectionParams {
  languageCode: string;
  name?: string;
  /** Required for some model-backed voices (e.g. 'chirp_3_hd'). */
  modelName?: string;
  ssmlGender?: SsmlVoiceGender;
}

export interface AudioConfig {
  audioEncoding: AudioEncoding;
  speakingRate?: number;
  pitch?: number;
  sampleRateHertz?: number;
  volumeGainDb?: number;
  effectsProfile?: string[];
}

/** Body accepted by `synthesize()` — mirrors the REST request wire shape. */
export interface SynthesizeSpeechRequest {
  input: SynthesisInput;
  voice: VoiceSelectionParams;
  audioConfig: AudioConfig;
}

export interface SynthesizeSpeechResponse {
  /** Base64-encoded audio. Decode with `atob(...)` / `Buffer.from(...,'base64')`. */
  audioContent?: string;
}

export interface Voice {
  name?: string;
  languageCodes?: string[];
  ssmlGender?: SsmlVoiceGender;
  naturalSampleRateHertz?: number;
}

export interface ListVoicesResponse {
  voices?: Voice[];
}

export interface ConnectOptions {
  logLevel?: 'all' | 'debug' | 'info' | 'warning' | 'error' | 'off';
}

/** The opaque handle returned by the dart2js interop layer. */
export interface GoogleTtsJsHandle {
  voicesList(languageCode?: string): Promise<ListVoicesResponse>;
  synthesize(request: SynthesizeSpeechRequest): Promise<SynthesizeSpeechResponse>;
  close(): void;
}

/** `globalThis.GoogleTtsJs`, installed by the compiled Dart runtime. */
export interface GoogleTtsJsNamespace {
  version: string;
  withApiKey(apiKey: string, logLevel?: string): Promise<GoogleTtsJsHandle>;
  withOAuth(logLevel?: string): Promise<GoogleTtsJsHandle>;
}

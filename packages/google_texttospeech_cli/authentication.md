# Authentication

`google_texttospeech_cli` supports two authentication modes. **The API key
mode is the recommended default** — it covers both v1 methods
(`tts voices list`, `tts synthesize`) and its blast radius can be limited
to a single API.

## 1. API key (recommended)

1. In the [Google Cloud Console](https://console.cloud.google.com/), create
   or select a project and **enable the Cloud Text-to-Speech API**.
2. **Credentials > Create credentials > API key**.
3. **Restrict the key** (this is the important step): open the key, set
   *API restrictions* to *Restrict keys* → **Text-to-Speech API**. An
   unrestricted key can be used for every API enabled in the project; a
   restricted key can only burn your TTS quota.
4. Provide it to the CLI via environment or `.env` in the working directory:

   ```sh
   export GOOGLE_TTS_API_KEY=your-api-key
   # or, in ./.env:
   # GOOGLE_TTS_API_KEY=your-api-key
   ```

   The `.env` file is read from the current working directory. In shared or
   CI environments where another party controls the checkout, set
   `GOOGLE_TTS_DISABLE_DOTENV=1` so only real environment variables are
   honored.

## 2. OAuth 2.0 (higher quotas / per-project billing)

Use this only when you need quota or billing beyond an API key.

1. Configure the **OAuth consent screen** first: Google Auth platform →
   Audience → create it in **Testing** mode, then under **Test users** add the
   exact Google account you will sign in with. Without this the browser flow
   returns `Error 403: access_denied`.
2. In the Cloud Console, enable the Text-to-Speech API, then
   **Credentials > Create credentials > OAuth client ID** and choose
   **Desktop app** (or Android/iOS for mobile flows).
3. Download the generated `client_secret.json`.
4. Run the authorization flow:

   ```sh
   tts authorize --credentials-file client_secret.json
   ```

   This opens the Google consent page in your browser and stores the
   resulting tokens in `tts_access_tokens.json` (override with `--tokens-file`
   or `GOOGLE_TTS_ACCESS_TOKENS_FILE`).

### Troubleshooting: `Error 403: access_denied`

The consent screen is in **Testing** and the signing-in account is not a
listed Test user. Add it (Google Auth platform → Audience → Test users),
save, wait a few seconds, then re-run `tts authorize`. On the "unverified
app" page choose **Advanced → Continue**. If the account is on a managed
Google Workspace domain, a domain admin must grant the app instead.

### Security notes on stored OAuth tokens — read before using mode 2

- **Scope blast radius.** The Cloud Text-to-Speech v1 API exposes exactly
  one OAuth scope: `https://www.googleapis.com/auth/cloud-platform`, which
  authorizes *your whole project's API surface*, not just TTS. A leaked
  refresh token is far more dangerous than a leaked TTS-restricted API key.
  Request it only if you actually need it, and revoke at
  <https://myaccount.google.com/permissions> if a device is compromised.
- **Storage.** Tokens are persisted as plaintext JSON, written `chmod 600`
  into `~/.tts/` (or the current directory / your `--tokens-file` path).
  File permissions protect against *other users*, not against any process
  running as *you* — malware, editors with undo/swap archives, and home
  directories synced to cloud storage (Dropbox, iCloud, OneDrive) can all
  read it. Keep your disk encrypted and your token directory out of sync
  folders.
- **Machine-independent refresh tokens.** The stored refresh token works
  from any machine until revoked; there is no device binding. Prefer short
  credential lifetimes at the org level if your GCP org supports them.
- **No token on disk (safest).** Use `GoogleTts.withGenerator(...)` from the
  library and feed a live access token from your own secret manager
  (1Password CLI, GCP Secret Manager, ADC on GCP). The library then never
  persists anything itself.

## Gemini-TTS (promptable) models

Passing `--model-name gemini-3.1-flash-tts-preview` (with `--prompt`) synthesizes
through the **Cloud Text-to-Speech API** on the `global` endpoint — no separate
Vertex client is needed. But these models need project entitlements an API key
cannot provide, so use OAuth (this file, mode 2) and ensure all four:

1. Project linked to an **active billing account** (unbilled projects return
   `403 PERMISSION_DENIED` on the preview model).
2. **Cloud Text-to-Speech API enabled**.
3. Signed-in user granted **`roles/aiplatform.user`** (carries
   `aiplatform.endpoints.predict` — the permission named in the error).
4. Region support: `gemini-3.1-flash-tts-preview` is available in `global`
   (the unprefixed endpoint this CLI uses).

## Credential file resolution order

Paths resolve independently, first match wins:

1. `--credentials-file` / `--tokens-file` CLI flags
2. `GOOGLE_TTS_CLIENT_SECRETS_FILE` / `GOOGLE_TTS_ACCESS_TOKENS_FILE` env vars
3. the same names in `./.env` (disable with `GOOGLE_TTS_DISABLE_DOTENV=1`)
4. defaults in the current directory, then `~/.tts/`

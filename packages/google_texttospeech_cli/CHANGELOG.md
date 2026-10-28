# Changelog

## 0.1.0

- Initial release: `tts` command-line tool for the Google Cloud Text-to-Speech
  REST API v1, built on the `google_texttospeech` package.
- Commands: `voices list` (prints usable voice names by default; `--full` for
  the raw JSON records), `synthesize synthesize` (`--text`/`--ssml`/`--prompt`,
  `--name`, `--model-name`, encoding/pitch/rate, `--out`), `authorize` (OAuth2
  loopback flow), and `version`.

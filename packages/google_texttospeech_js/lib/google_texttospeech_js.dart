/// dart2js entry point for the google_texttospeech_js npm package.
///
/// When this module is loaded in a JavaScript environment, `main()` installs
/// a `globalThis.GoogleTtsJs` namespace with an interop-friendly surface
/// (`withApiKey`, `withOAuth`). The typed, Promise-based API is layered on top
/// in TypeScript (see `src/index.ts`).
library;

import 'package:google_texttospeech_js/src/js_bindings.dart' as bindings;

void main() {
  bindings.install();
}

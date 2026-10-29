import { defineConfig } from 'tsup';

// scripts/build.sh copies the dart2js output to dist/google_texttospeech_js.runtime.js,
// so the (external) dynamic import below resolves next to the emitted bundles.
const dartRuntime = './google_texttospeech_js.runtime.js';

export default defineConfig([
  {
    entry: { browser: 'src/browser.ts' },
    format: ['esm'],
    dts: true,
    sourcemap: true,
    clean: false,
    platform: 'browser',
    target: 'es2022',
    external: [dartRuntime],
  },
  {
    entry: { node: 'src/node.ts' },
    format: ['esm', 'cjs'],
    dts: true,
    sourcemap: true,
    clean: false,
    platform: 'node',
    target: 'node18',
    external: [dartRuntime],
  },
  {
    entry: { index: 'src/index.ts' },
    format: ['esm'],
    dts: true,
    sourcemap: true,
    clean: false,
    platform: 'neutral',
    target: 'es2022',
  },
]);

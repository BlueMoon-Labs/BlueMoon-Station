/**
 * @file
 * @copyright 2026
 * @license MIT
 */

const path = require('path');

const workspaceRoot = __dirname;
const resolvePackage = (name) => path.resolve(workspaceRoot, 'packages', name);

const aliases = [
  { find: /^~tgui\//, replacement: `${resolvePackage('tgui')}/` },
  { find: /^common\//, replacement: `${resolvePackage('common')}/` },
  { find: /^tgui\//, replacement: `${resolvePackage('tgui')}/` },
  { find: /^tgui-panel\//, replacement: `${resolvePackage('tgui-panel')}/` },
  { find: /^tgui-dev-server\//, replacement: `${resolvePackage('tgui-dev-server')}/` },
];

// Legacy interface files use JSX inside plain .js files, which esbuild
// does not parse by default. Transform them with the jsx loader.
// Uses esbuild directly: requiring 'vite' from CJS breaks on Node 20
// (ESM facade fails to resolve rollup under PnP).
const esbuild = require('esbuild');

const createJsxInJsPlugin = () => ({
  name: 'tgui-jsx-in-js',
  enforce: 'pre',
  async transform(code, id) {
    const normalizedId = id.replace(/\\/g, '/');
    if (!/\/packages\/.*\.js$/.test(normalizedId)) {
      return null;
    }
    const result = await esbuild.transform(code, {
      loader: 'jsx',
      jsx: 'automatic',
      jsxImportSource: 'react',
      sourcefile: id,
      sourcemap: true,
    });
    return {
      code: result.code,
      map: result.map || null,
    };
  },
});

const createViteConfig = ({ entry, bundleName, globalName }) => {
  return ({ mode }) => ({
    root: workspaceRoot,
    publicDir: false,
    base: '',
    plugins: [createJsxInJsPlugin()],
    css: {
      preprocessorOptions: {
        scss: {
          api: 'modern-compiler',
        },
        sass: {
          api: 'modern-compiler',
        },
      },
    },
    resolve: {
      alias: aliases,
      extensions: ['.mjs', '.js', '.cjs', '.ts', '.tsx', '.json'],
    },
    define: {
      'process.env.NODE_ENV': JSON.stringify(mode),
      'process.env.DEV_SERVER_IP': JSON.stringify(
        mode === 'development' ? (process.env.DEV_SERVER_IP || null) : null
      ),
    },
    esbuild: {
      target: 'es2020',
      jsx: 'automatic',
      jsxImportSource: 'react',
      drop: mode === 'production' ? ['console'] : [],
    },
    build: {
      target: 'es2020',
      outDir: path.resolve(workspaceRoot, 'public'),
      emptyOutDir: false,
      chunkSizeWarningLimit: 2000,
      minify: mode === 'production' ? 'terser' : false,
      terserOptions: {
        format: {
          ascii_only: true,
          comments: false,
        },
      },
      sourcemap: mode !== 'production',
      cssCodeSplit: false,
      assetsInlineLimit: Number.MAX_SAFE_INTEGER,
      rollupOptions: {
        input: path.resolve(workspaceRoot, entry),
        output: {
          format: 'iife',
          name: globalName,
          inlineDynamicImports: true,
          entryFileNames: `${bundleName}.bundle.js`,
          assetFileNames: (assetInfo) => {
            if (assetInfo.name && assetInfo.name.endsWith('.css')) {
              return `${bundleName}.bundle.css`;
            }
            return 'assets/[name][extname]';
          },
        },
      },
    },
  });
};

module.exports = {
  createViteConfig,
};

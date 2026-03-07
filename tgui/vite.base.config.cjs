/**
 * @file
 * @copyright 2026
 * @license MIT
 */

const path = require('path');
const babel = require('@babel/core');

const workspaceRoot = __dirname;
const resolvePackage = (name) => path.resolve(workspaceRoot, 'packages', name);

const aliases = [
  { find: /^~tgui\//, replacement: `${resolvePackage('tgui')}/` },
  { find: /^common\//, replacement: `${resolvePackage('common')}/` },
  { find: /^tgui\//, replacement: `${resolvePackage('tgui')}/` },
  { find: /^tgui-panel\//, replacement: `${resolvePackage('tgui-panel')}/` },
  { find: /^tgui-dev-server\//, replacement: `${resolvePackage('tgui-dev-server')}/` },
];

const createBabelTransformPlugin = (mode) => ({
  name: 'tgui-babel-inferno',
  enforce: 'pre',
  async transform(code, id) {
    const normalizedId = id.replace(/\\/g, '/');
    if (!/\/packages\/.*\.(js|ts|tsx)$/.test(normalizedId)) {
      return null;
    }
    const result = await babel.transformAsync(code, {
      filename: id,
      babelrc: false,
      configFile: false,
      sourceMaps: true,
      compact: false,
      presets: [
        [require.resolve('@babel/preset-typescript'), {
          allowDeclareFields: true,
          allExtensions: true,
          isTSX: true,
        }],
      ],
      plugins: [
        require.resolve('babel-plugin-inferno'),
        mode === 'production' && require.resolve('babel-plugin-transform-remove-console'),
        require.resolve('common/string.babel-plugin.cjs'),
      ].filter(Boolean),
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
    plugins: [createBabelTransformPlugin(mode)],
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

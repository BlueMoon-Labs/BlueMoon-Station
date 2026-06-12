/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

/**
 * `import.meta.glob` is Vite-only syntax; under Jest the modules are
 * CommonJS and `import.meta` is a parse error. Replace such calls with an
 * empty object so modules that use them (routes, KitchenSink) stay loadable
 * in tests.
 */
const importMetaGlobPlugin = ({ types: t }) => ({
  visitor: {
    CallExpression(path) {
      const callee = path.node.callee;
      if (
        t.isMemberExpression(callee)
        && t.isMetaProperty(callee.object)
        && t.isIdentifier(callee.property, { name: 'glob' })
      ) {
        path.replaceWith(t.objectExpression([]));
      }
    },
  },
});

const createBabelConfig = options => {
  const { mode, presets = [], plugins = [] } = options;
  return {
    presets: [
      [require.resolve('@babel/preset-typescript'), {
        allowDeclareFields: true,
      }],
      [require.resolve('@babel/preset-env'), {
        modules: 'commonjs',
        spec: false,
        loose: true,
        targets: {
          edge: '109',
        },
      }],
      [require.resolve('@babel/preset-react'), {
        runtime: 'automatic',
      }],
      ...presets,
    ],
    // Class properties are native in the build target (Edge 109) and in the
    // Node that runs Jest. A standalone class-properties plugin would also
    // run before preset-typescript and choke on TS `declare` fields.
    plugins: [
      ...(mode === 'test' ? [importMetaGlobPlugin] : []),
      ...plugins,
    ],
    compact: true,
  };
};

module.exports = api => {
  api.cache(true);
  const mode = process.env.NODE_ENV;
  return createBabelConfig({ mode });
};

module.exports.createBabelConfig = createBabelConfig;

/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

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
    plugins: [
      [require.resolve('@babel/plugin-transform-class-properties'), {
        loose: true,
      }],
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

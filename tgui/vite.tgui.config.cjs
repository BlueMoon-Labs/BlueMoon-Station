const { createViteConfig } = require('./vite.base.config.cjs');

module.exports = createViteConfig({
  entry: 'packages/tgui/index.js',
  bundleName: 'tgui',
  globalName: 'TguiBundle',
});

const { createViteConfig } = require('./vite.base.config.cjs');

module.exports = createViteConfig({
  entry: 'packages/tgui-panel/index.js',
  bundleName: 'tgui-panel',
  globalName: 'TguiPanelBundle',
});

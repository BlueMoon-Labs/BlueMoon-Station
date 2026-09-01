/**
 * @file Следит за пересборкой бандлов в public/ и дёргает broadcast.
 * @license MIT
 */

const fs = require('fs');

const isBundleFile = (filename) => /\.bundle\.(js|css)$/.test(filename || '');

// Возвращает обработчик имени файла, который с debounce шлёт hotUpdate.
const createDebouncedReload = (broadcast, delay = 100) => {
  let timer = null;
  return (filename) => {
    if (!isBundleFile(filename)) {
      return;
    }
    if (timer) {
      clearTimeout(timer);
    }
    timer = setTimeout(() => {
      timer = null;
      broadcast({ type: 'hotUpdate' });
    }, delay);
  };
};

const watchBundles = (publicDir, broadcast) => {
  const onChange = createDebouncedReload(broadcast);
  return fs.watch(publicDir, (_eventType, filename) => onChange(filename));
};

module.exports = { isBundleFile, createDebouncedReload, watchBundles };

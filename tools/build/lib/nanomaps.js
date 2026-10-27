import fs from 'node:fs';

import Juke from '../juke/index.js';

const MANIFEST = 'code/modules/asset_cache/assets/nanomaps.dm';
const STAMP = 'data/nanomaps.stamp';

/** LOWMEMORYMODE грузит только RuntimeStation, NanoMap для него не собираются. */
export const isLowMemoryBuild = (defines = [], basemap = '_maps/_basemap.dm') => defines.includes('LOWMEMORYMODE')
  || /^[ \t]*#define[ \t]+LOWMEMORYMODE\b/m.test(fs.existsSync(basemap) ? fs.readFileSync(basemap, 'utf8') : '');

// Рендер берёт только карты из _maps/*.json: правки руин, ЦК и шаттлов его не запускают.
const stationMaps = () => Juke.glob('_maps/*.json').flatMap(file => {
  try {
    const config = JSON.parse(fs.readFileSync(file, 'utf8'));
    if (!config.map_path || !config.map_file) {
      return [];
    }
    return [config.map_file].flat().map(map => `_maps/${config.map_path}/${map}`.replaceAll('\\', '/'));
  }
  catch {
    return [];
  }
});

export const NanomapsTarget = new Juke.Target({
  // Обычные правки DM не меняют PNG. Изменения внешности типов в DM требуют явной генерации.
  inputs: () => [
    'SpacemanDMM.toml',
    'tools/nanomaps/render.cjs',
    'tools/nanomaps/renderer.cjs',
    ...Juke.glob('_maps/*.json'),
    ...stationMaps(),
    ...Juke.glob('icons/**/*.dmi'),
    ...Juke.glob('modular_*/**/*.dmi'),
  ],
  // Свежесть отмечает штамп: Juke касается выходов после рендера, а неизменные PNG
  // со старой меткой не заставляют DM пересобираться. Пропавшие файлы запускают рендер.
  outputs: () => {
    const results = fs.existsSync(MANIFEST)
      ? [...fs.readFileSync(MANIFEST, 'utf8').matchAll(/'(icons\/_nanomaps\/[^']+\.png)'/g)].map(match => match[1])
      : [];
    return [STAMP, ...[MANIFEST, ...results].filter(file => !fs.existsSync(file))];
  },
  executes: async () => {
    await Juke.exec('node', ['tools/nanomaps/render.cjs', '--incremental']);
    fs.mkdirSync('data', { recursive: true });
  },
});

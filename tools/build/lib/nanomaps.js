import fs from 'node:fs';

import Juke from '../juke/index.js';

export const NanomapsTarget = new Juke.Target({
  // Обычные правки DM не меняют PNG. Изменения внешности типов в DM требуют явной генерации.
  inputs: () => [
    'SpacemanDMM.toml',
    'tools/nanomaps/render.cjs',
    'tools/nanomaps/renderer.cjs',
    ...Juke.glob('_maps/*.json'),
    ...Juke.glob('_maps/map_files/**/*.dmm'),
    ...Juke.glob('icons/**/*.dmi'),
    ...Juke.glob('modular_*/**/*.dmi'),
  ],
  outputs: () => [
    'code/modules/asset_cache/assets/nanomaps.dm',
    // Список из манифеста позволяет заметить отсутствующие PNG даже в чистой копии репозитория.
    ...(fs.existsSync('code/modules/asset_cache/assets/nanomaps.dm')
      ? [...fs.readFileSync('code/modules/asset_cache/assets/nanomaps.dm', 'utf8')
        .matchAll(/'(icons\/_nanomaps\/[^']+\.png)'/g)].map(match => match[1])
      : []),
  ],
  executes: async () => {
    await Juke.exec('node', ['tools/nanomaps/render.cjs']);
  },
});

const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');
const { crc32, deflateSync, inflateSync } = require('node:zlib');

const root = path.resolve(__dirname, '../..');
const { ensureRenderer } = require('./renderer.cjs');
const outputDirectory = path.join(root, 'icons/_nanomaps');
const assetFile = path.join(root, 'code/modules/asset_cache/assets/nanomaps.dm');

// Пересжатие IDAT не меняет пиксели и уменьшает размер PNG, выдаваемых рендерером.
function compressPng(input) {
  const chunks = [];
  const imageData = [];
  for (let offset = 8; offset < input.length;) {
    const length = input.readUInt32BE(offset);
    const type = input.toString('ascii', offset + 4, offset + 8);
    chunks.push({ type, data: input.subarray(offset, offset + length + 12) });
    if (type === 'IDAT') {
      imageData.push(input.subarray(offset + 8, offset + length + 8));
    }
    offset += length + 12;
  }
  const compressed = deflateSync(inflateSync(Buffer.concat(imageData)), { level: 9 });
  const idat = Buffer.alloc(compressed.length + 12);
  idat.writeUInt32BE(compressed.length);
  idat.write('IDAT', 4);
  compressed.copy(idat, 8);
  idat.writeUInt32BE(crc32(idat.subarray(4, -4)), idat.length - 4);
  let written = false;
  return Buffer.concat([input.subarray(0, 8), ...chunks.flatMap(chunk => {
    if (chunk.type !== 'IDAT') {
      return [chunk.data];
    }
    if (written) {
      return [];
    }
    written = true;
    return [idat];
  })]);
}

async function main() {
  process.chdir(root);
  const renderer = await ensureRenderer();

  const sources = new Map();
  for (const filename of fs.readdirSync('_maps').filter(name => name.endsWith('.json')).sort()) {
    const config = JSON.parse(fs.readFileSync(path.join('_maps', filename), 'utf8'));
    if (!config.map_path || !config.map_file) {
      continue;
    }
    for (const file of [config.map_file].flat()) {
      const key = `${config.map_path}/${file}`.replaceAll('\\', '/');
      const source = `_maps/${key}`;
      if (!fs.existsSync(source)) {
        throw new Error(`Не найден файл карты из ${filename}: ${source}`);
      }
      sources.set(key, source);
    }
  }

  const sizes = JSON.parse(execFileSync(renderer, ['map-info', '--json', ...sources.values()], {
    encoding: 'utf8', maxBuffer: 4 * 1024 * 1024,
  }));
  const groups = new Map();
  for (const source of sources.values()) {
    const [width, height] = sizes[source].size;
    const key = `${width}x${height}`;
    if (!groups.has(key)) {
      groups.set(key, { width, height, sources: [] });
    }
    groups.get(key).sources.push(source);
  }

  // Настройки SS1984: NanoMap-проход, без сглаживания, по восемь пикселей на тайл.
  for (const { width, height, sources: groupSources } of groups.values()) {
    execFileSync(renderer, [
      '-e', 'tgstation.dme', 'minimap', '--enable', 'nanomaps',
      '--width', String(width * 8), '--height', String(height * 8),
      '--disable', 'icon-smoothing', ...groupSources,
    ], { stdio: 'inherit' });
  }

  fs.mkdirSync(outputDirectory, { recursive: true });
  const assets = [];
  const mapData = [];
  const assetNames = new Set();
  for (const [key, source] of sources) {
    const [width, height, floors] = sizes[source].size;
    const prefix = key.replace(/\.dmm$/i, '').replace(/[^a-z0-9]+/gi, '-').toLowerCase();
    const entries = [];
    for (let floor = 1; floor <= floors; floor++) {
      const name = `nanomap-${prefix}-z${floor}.png`;
      if (assetNames.has(name)) {
        throw new Error(`Совпали имена изображений разных карт: ${name}`);
      }
      assetNames.add(name);
      const rendered = path.join('data/minimaps', `${path.basename(source, '.dmm')}-${floor}.png`);
      fs.writeFileSync(path.join(outputDirectory, name), compressPng(fs.readFileSync(rendered)));
      fs.unlinkSync(rendered);
      assets.push(`\t\t"${name}" = 'icons/_nanomaps/${name}',`);
      entries.push(`\t\t\tlist("asset" = "${name}", "width" = ${width}, "height" = ${height}),`);
    }
    mapData.push(`\t\t"${key}" = list(\n${entries.join('\n')}\n\t\t),`);
  }
  fs.writeFileSync(assetFile,
    '// Создаётся tools/nanomaps/render.cjs; обновляется штатной целью nanomaps.\n'
    + `/datum/asset/simple/nanomaps\n\tassets = list(\n${assets.join('\n')}\n\t)\n`
    + `\tvar/list/map_data = list(\n${mapData.join('\n')}\n\t)\n`);
  console.log(`Подготовлено миникарт: ${assetNames.size}, файлов карт: ${sources.size}.`);
}

main().catch(error => {
  console.error(error.message);
  process.exitCode = 1;
});

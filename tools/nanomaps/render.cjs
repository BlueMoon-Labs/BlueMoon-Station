const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');
const { crc32, deflateSync, inflateSync } = require('node:zlib');

const root = path.resolve(__dirname, '../..');
const outputDirectory = 'icons/_nanomaps';
const assetFile = 'code/modules/asset_cache/assets/nanomaps.dm';
const cacheFile = 'data/nanomaps-cache.json';

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

const sha256 = data => crypto.createHash('sha256').update(data).digest('hex');

// Неизменный файл не трогаем: иначе Git видит правку без диффа, а DM пересобирается зря.
function writeIfChanged(file, contents) {
  const existing = fs.existsSync(file) ? fs.readFileSync(file) : null;
  if (typeof contents === 'string') {
    const text = existing?.toString('utf8');
    if (text !== undefined && text.replace(/\r\n/g, '\n') === contents) {
      return false;
    }
    // Чекаут с core.autocrlf отдаёт CRLF, его и сохраняем.
    contents = text?.includes('\r\n') ? contents.replace(/\n/g, '\r\n') : contents;
  }
  else if (existing?.equals(contents)) {
    return false;
  }
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, contents);
  return true;
}

function buildManifest(maps) {
  const assets = [];
  const mapData = [];
  for (const { key, width, height, names } of maps) {
    assets.push(...names.map(name => `\t\t"${name}" = 'icons/_nanomaps/${name}',`));
    const entries = names.map(name => `\t\t\tlist("asset" = "${name}", "width" = ${width}, "height" = ${height}),`);
    mapData.push(`\t\t"${key}" = list(\n${entries.join('\n')}\n\t\t),`);
  }
  // LOWMEMORYMODE собирается без PNG, поэтому ссылки на них прячутся от компилятора.
  return '// Создаётся tools/nanomaps/render.cjs; обновляется штатной целью nanomaps.\n'
    + '/datum/asset/simple/nanomaps\n'
    + '#ifndef LOWMEMORYMODE\n'
    + `\tassets = list(\n${assets.join('\n')}\n\t)\n`
    + `\tvar/list/map_data = list(\n${mapData.join('\n')}\n\t)\n`
    + '#else\n'
    + '\tvar/list/map_data = list()\n'
    + '#endif\n';
}

function collectSources() {
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
  return sources;
}

function listDmi(directory, result = []) {
  if (!fs.existsSync(directory)) {
    return result;
  }
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const file = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      listDmi(file, result);
    }
    else if (entry.name.endsWith('.dmi')) {
      const stat = fs.statSync(file);
      result.push(`${file.replaceAll('\\', '/')}:${stat.size}:${stat.mtimeMs}`);
    }
  }
  return result;
}

// Всё, что влияет на каждую карту сразу: при смене подписи перерисовываются все.
function sharedSignature(renderer) {
  const dmi = [
    ...listDmi('icons'),
    ...fs.readdirSync('.').filter(name => name.startsWith('modular_')).flatMap(name => listDmi(name)),
  ].sort();
  return sha256([
    path.basename(path.dirname(renderer)),
    fs.readFileSync(__filename),
    fs.existsSync('SpacemanDMM.toml') ? fs.readFileSync('SpacemanDMM.toml') : '',
    ...dmi,
  ].join('\n'));
}

function readCache() {
  try {
    return JSON.parse(fs.readFileSync(cacheFile, 'utf8'));
  }
  catch {
    return { shared: null, maps: {} };
  }
}

const assetPrefix = key => key.replace(/\.dmm$/i, '').replace(/[^a-z0-9]+/gi, '-').toLowerCase();

async function main() {
  process.chdir(root);
  // Цель сборки перерисовывает только изменённые карты; прямой запуск обновляет все.
  const incremental = process.argv.includes('--incremental');
  const { ensureRenderer } = require('./renderer.cjs');
  const renderer = await ensureRenderer();
  const sources = collectSources();

  const shared = sharedSignature(renderer);
  const cache = readCache();
  const reuse = incremental && cache.shared === shared;
  const hashes = new Map([...sources].map(([key, source]) => [key, sha256(fs.readFileSync(source))]));
  const stale = [...sources.keys()].filter(key => {
    const cached = cache.maps[key];
    return !reuse || !cached || cached.hash !== hashes.get(key)
      || cached.names.some(name => !fs.existsSync(path.join(outputDirectory, name)));
  });

  const sizes = stale.length === 0 ? {} : JSON.parse(execFileSync(renderer,
    ['map-info', '--json', ...stale.map(key => sources.get(key))],
    { encoding: 'utf8', maxBuffer: 4 * 1024 * 1024 }));
  const groups = new Map();
  for (const key of stale) {
    const source = sources.get(key);
    const [width, height] = sizes[source].size;
    const group = `${width}x${height}`;
    if (!groups.has(group)) {
      groups.set(group, { width, height, sources: [] });
    }
    groups.get(group).sources.push(source);
  }

  // Настройки SS1984: NanoMap-проход, без сглаживания, по восемь пикселей на тайл.
  for (const { width, height, sources: groupSources } of groups.values()) {
    execFileSync(renderer, [
      '-e', 'tgstation.dme', 'minimap', '--enable', 'nanomaps',
      '--width', String(width * 8), '--height', String(height * 8),
      '--disable', 'icon-smoothing', ...groupSources,
    ], { stdio: 'inherit' });
  }

  const maps = [];
  const nextCache = { shared, maps: {} };
  const assetNames = new Set();
  for (const [key, source] of sources) {
    let entry = cache.maps[key];
    if (stale.includes(key)) {
      const [width, height, floors] = sizes[source].size;
      const names = [];
      for (let floor = 1; floor <= floors; floor++) {
        const name = `nanomap-${assetPrefix(key)}-z${floor}.png`;
        const rendered = path.join('data/minimaps', `${path.basename(source, '.dmm')}-${floor}.png`);
        writeIfChanged(path.join(outputDirectory, name), compressPng(fs.readFileSync(rendered)));
        fs.unlinkSync(rendered);
        names.push(name);
      }
      entry = { hash: hashes.get(key), width, height, names };
    }
    for (const name of entry.names) {
      if (assetNames.has(name)) {
        throw new Error(`Совпали имена изображений разных карт: ${name}`);
      }
      assetNames.add(name);
    }
    nextCache.maps[key] = entry;
    maps.push({ key, ...entry });
  }

  fs.mkdirSync(outputDirectory, { recursive: true });
  for (const name of fs.readdirSync(outputDirectory)) {
    if (name.endsWith('.png') && !assetNames.has(name)) {
      fs.unlinkSync(path.join(outputDirectory, name));
    }
  }
  writeIfChanged(assetFile, buildManifest(maps));
  writeIfChanged(cacheFile, `${JSON.stringify(nextCache, null, 2)}\n`);
  console.log(`Миникарт: ${assetNames.size}, файлов карт: ${sources.size}, перерисовано карт: ${stale.length}.`);
}

if (require.main === module) {
  main().catch(error => {
    console.error(error.message);
    process.exitCode = 1;
  });
}

module.exports = { buildManifest, writeIfChanged };

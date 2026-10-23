const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { test } = require('node:test');
const { pathToFileURL } = require('node:url');
const { crc32, inflateSync } = require('node:zlib');
const { selectCompatibleRenderer } = require('./renderer.cjs');

const root = path.resolve(__dirname, '../..');
const manifest = 'code/modules/asset_cache/assets/nanomaps.dm';
const image = 'icons/_nanomaps/nanomap-test-z1.png';
const secondImage = 'icons/_nanomaps/nanomap-test-z2.png';
const fakeManifest = `/datum/asset/simple/nanomaps\n\tassets = list(\n\t\t"first.png" = '${image}',\n\t\t"second.png" = '${secondImage}',\n\t)\n`;

function fixture(t) {
  const parent = path.join(root, 'data');
  fs.mkdirSync(parent, { recursive: true });
  const directory = fs.mkdtempSync(path.join(parent, 'nanomaps-ci-'));
  t.after(() => {
    // Удаляем только созданный этим тестом каталог непосредственно внутри data.
    assert.equal(path.dirname(directory), parent);
    assert.ok(path.basename(directory).startsWith('nanomaps-ci-'));
    fs.rmSync(directory, { recursive: true, force: true });
  });
  const write = (name, contents) => {
    const filename = path.join(directory, name);
    fs.mkdirSync(path.dirname(filename), { recursive: true });
    fs.writeFileSync(filename, contents);
  };
  write('SpacemanDMM.toml', '');
  write('_maps/test.json', '{}');
  write('_maps/map_files/test.dmm', '');
  write('icons/test.dmi', '');
  write('modular_test/icons/test.dmi', '');
  write('tools/nanomaps/renderer.cjs', '');
  write(manifest, fakeManifest);
  // Подменяем только дорогой рендер; проверяется настоящая цель NanoMap и механизм Juke.
  write('tools/nanomaps/render.cjs', `
    const fs = require('node:fs');
    fs.mkdirSync('icons/_nanomaps', { recursive: true });
    fs.mkdirSync('code/modules/asset_cache/assets', { recursive: true });
    fs.writeFileSync(${JSON.stringify(manifest)}, ${JSON.stringify(fakeManifest)});
    fs.writeFileSync(${JSON.stringify(image)}, 'png');
    fs.writeFileSync(${JSON.stringify(secondImage)}, 'png');
    fs.appendFileSync('renders.txt', 'render\\n');
  `);
  const targetUrl = pathToFileURL(path.join(root, 'tools/build/lib/nanomaps.js')).href;
  const jukeUrl = pathToFileURL(path.join(root, 'tools/build/juke/index.js')).href;
  write('build.mjs', `
    import Juke from ${JSON.stringify(jukeUrl)};
    export { NanomapsTarget } from ${JSON.stringify(targetUrl)};
    Juke.chdir('.', import.meta.url);
    Juke.setup({ file: import.meta.url }).then(code => process.exit(code));
  `);
  const run = () => {
    const result = spawnSync(process.execPath, ['build.mjs', 'nanomaps'], {
      cwd: directory,
      encoding: 'utf8',
      timeout: 30000,
      env: { ...process.env, PATH: `${path.dirname(process.execPath)}${path.delimiter}${process.env.PATH || ''}` },
    });
    assert.equal(result.error, undefined);
    assert.equal(result.status, 0, result.stdout + result.stderr);
  };
  const renders = () => fs.readFileSync(path.join(directory, 'renders.txt'), 'utf8').split('render').length - 1;
  const change = name => {
    write(name, 'changed');
    // Не полагаемся на разрешение файловых меток времени и скорость выполнения CI.
    const future = new Date(Date.now() + 2000);
    fs.utimesSync(path.join(directory, name), future, future);
  };
  return { directory, run, renders, change };
}

test('чистая копия: PNG из манифеста создаются, повторная сборка пропускает рендер', t => {
  const f = fixture(t);
  f.run();
  assert.ok(fs.existsSync(path.join(f.directory, image)));
  assert.ok(fs.existsSync(path.join(f.directory, secondImage)));
  f.run();
  assert.equal(f.renders(), 1);
});

test('обычные правки DM и DME не запускают рендер', t => {
  const f = fixture(t);
  f.run();
  f.change('code/unrelated.dm');
  f.change('modular_test/code/unrelated.dm');
  f.change('tgstation.dme');
  f.run();
  assert.equal(f.renders(), 1);
});

for (const output of [image, secondImage, manifest]) {
  test(`восстанавливается отсутствующий результат: ${output}`, t => {
    const f = fixture(t);
    f.run();
    fs.unlinkSync(path.join(f.directory, output));
    f.run();
    assert.ok(fs.existsSync(path.join(f.directory, output)));
    assert.equal(f.renders(), 2);
  });
}

for (const input of [
  '_maps/map_files/test.dmm', '_maps/test.json', 'icons/test.dmi',
  'modular_test/icons/test.dmi', 'SpacemanDMM.toml', 'tools/nanomaps/renderer.cjs',
]) {
  test(`изменение входного файла запускает рендер: ${input}`, t => {
    const f = fixture(t);
    f.run();
    f.change(input);
    f.run();
    assert.equal(f.renders(), 2);
  });
}

test('изменение самого генератора запускает рендер', t => {
  const f = fixture(t);
  f.run();
  const filename = path.join(f.directory, 'tools/nanomaps/render.cjs');
  fs.appendFileSync(filename, '\n// Изменение генератора.\n');
  const future = new Date(Date.now() + 2000);
  fs.utimesSync(filename, future, future);
  f.run();
  assert.equal(f.renders(), 2);
});

test('настоящие PNG целы и соответствуют размерам всех этажей манифеста', () => {
  const source = fs.readFileSync(path.join(root, manifest), 'utf8');
  const entries = [...source.matchAll(/list\("asset" = "([^"]+)", "width" = (\d+), "height" = (\d+)\)/g)];
  assert.ok(entries.length > 0, 'В манифесте нет этажей.');
  const assets = new Map([...source.matchAll(/"([^"]+\.png)" = '(icons\/_nanomaps\/[^']+\.png)'/g)]
    .map(match => [match[1], match[2]]));
  assert.equal(assets.size, entries.length);
  const seen = new Set();
  for (const [, name, width, height] of entries) {
    assert.ok(!seen.has(name), `Повтор ассета: ${name}`);
    seen.add(name);
    assert.ok(assets.has(name), `Нет объявления ассета: ${name}`);
    const png = fs.readFileSync(path.join(root, assets.get(name)));
    assert.deepEqual(png.subarray(0, 8), Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), name);
    assert.equal(png.toString('ascii', 12, 16), 'IHDR', name);
    assert.equal(png.readUInt32BE(16), Number(width) * 8, name);
    assert.equal(png.readUInt32BE(20), Number(height) * 8, name);
    const idat = [];
    let ended = false;
    for (let offset = 8; offset < png.length;) {
      const size = png.readUInt32BE(offset);
      assert.ok(offset + size + 12 <= png.length, `Обрезанный PNG: ${name}`);
      const type = png.toString('ascii', offset + 4, offset + 8);
      assert.equal(crc32(png.subarray(offset + 4, offset + size + 8)), png.readUInt32BE(offset + size + 8), name);
      if (type === 'IDAT') idat.push(png.subarray(offset + 8, offset + size + 8));
      offset += size + 12;
      if (type === 'IEND') {
        assert.equal(offset, png.length, name);
        ended = true;
        break;
      }
    }
    assert.ok(ended && idat.length > 0, `Незавершённый PNG: ${name}`);
    assert.ok(inflateSync(Buffer.concat(idat)).length > 0, name);
  }
});

test('совместимый Linux-релиз не требует Cargo', async () => {
  let builds = 0;
  const selected = await selectCompatibleRenderer('release', {
    platform: 'linux', run: () => {}, build: () => { builds++; },
  });
  assert.equal(selected, 'release');
  assert.equal(builds, 0);
});

test('ошибка GLIBC_2.39 включает локальную сборку и проверку её результата', async () => {
  const checked = [];
  const selected = await selectCompatibleRenderer('release', {
    platform: 'linux',
    run: file => {
      checked.push(file);
      if (file === 'release') {
        const error = new Error('Command failed');
        error.stderr = Buffer.from("libc.so.6: version `GLIBC_2.39' not found");
        throw error;
      }
    },
    build: async () => 'local',
  });
  assert.equal(selected, 'local');
  assert.deepEqual(checked, ['release', 'local']);
});

test('посторонние ошибки запуска не скрываются локальной сборкой', async () => {
  const error = new Error('Permission denied');
  await assert.rejects(selectCompatibleRenderer('release', {
    platform: 'linux', run: () => { throw error; },
    build: () => assert.fail('Сборка не должна запускаться'),
  }), candidate => candidate === error);
});

test('ошибка самой локальной сборки передаётся вызывающему коду', async () => {
  const error = new Error('Cargo build failed');
  await assert.rejects(selectCompatibleRenderer('release', {
    platform: 'linux', run: () => { throw new Error('GLIBC_2.39 not found'); },
    build: async () => { throw error; },
  }), candidate => candidate === error);
});

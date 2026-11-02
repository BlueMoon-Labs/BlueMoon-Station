import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import test from 'node:test';
import { ensureCoreSource, resolveCoreSource } from './core-source.mjs';

/** Локальный Git origin проверяет реальный clone/checkout без GitHub и без пользовательского checkout. */
function fixture(t) {
  const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'netrun-source-'));
  t.after(() => {
    assert.equal(path.dirname(temporary), path.resolve(os.tmpdir()));
    fs.rmSync(temporary, { recursive: true, force: true });
  });
  const root = path.join(temporary, 'station');
  const origin = path.join(temporary, 'origin');
  fs.mkdirSync(path.join(root, 'tools/netrun'), { recursive: true });
  fs.mkdirSync(origin);
  const git = (...args) => {
    const result = spawnSync('git', ['-C', origin, ...args], { encoding: 'utf8', windowsHide: true });
    assert.equal(result.status, 0, result.stderr);
    return result.stdout.trim();
  };
  git('init');
  fs.writeFileSync(path.join(origin, '.gitattributes'), '* text eol=lf\n');
  for (const relative of ['global.json', 'src/Netrun.Host/Netrun.Host.csproj', 'native/netrun_bridge.cpp']) {
    fs.mkdirSync(path.dirname(path.join(origin, relative)), { recursive: true });
    fs.writeFileSync(path.join(origin, relative), '{}\n');
  }
  git('add', '.');
  git('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', '-c', 'commit.gpgsign=false', 'commit', '-m', 'pinned');
  const revision = git('rev-parse', 'HEAD');
  fs.writeFileSync(path.join(origin, 'native/netrun_bridge.cpp'), 'newer commit\n');
  git('add', '.');
  git('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', '-c', 'commit.gpgsign=false', 'commit', '-m', 'newer');
  const writePin = (pin) => fs.writeFileSync(path.join(root, 'tools/netrun/core-source.json'), JSON.stringify(pin));
  writePin({ repository: origin, revision });
  return { root, origin, revision, temporary, writePin, source: resolveCoreSource(root) };
}

test('missing Core is cloned at the reviewed commit, never remote HEAD', async (t) => {
  const options = fixture(t);
  assert.equal(await ensureCoreSource(options), options.source);
  assert.equal(fs.readFileSync(path.join(options.source, 'native/netrun_bridge.cpp'), 'utf8'), '{}\n');
  const result = spawnSync('git', ['-C', options.source, 'rev-parse', 'HEAD'], { encoding: 'utf8' });
  assert.equal(result.stdout.trim(), options.revision);
});

test('existing dirty Core is reused without fetch/reset or reading a changed pin', async (t) => {
  const options = fixture(t);
  await ensureCoreSource(options);
  const modified = path.join(options.source, 'native/netrun_bridge.cpp');
  fs.writeFileSync(modified, 'local work\n');
  options.writePin({ repository: 'https://invalid.invalid/core', revision: '0'.repeat(40) });
  await ensureCoreSource(options);
  assert.equal(fs.readFileSync(modified, 'utf8'), 'local work\n');
});

test('failed checkout leaves no partial target and permits a later successful retry', async (t) => {
  const options = fixture(t);
  options.writePin({ repository: options.origin, revision: '0'.repeat(40) });
  await assert.rejects(ensureCoreSource(options), /core_download_failed/);
  assert.equal(fs.existsSync(options.source), false);
  assert.equal(fs.readdirSync(options.temporary).some((name) => name.startsWith('.netrun-core-download-')), false);
  options.writePin({ repository: options.origin, revision: options.revision });
  await ensureCoreSource(options);
});

test('concurrent launchers publish one complete Core checkout', async (t) => {
  const options = fixture(t);
  const results = await Promise.all([ensureCoreSource(options), ensureCoreSource(options)]);
  assert.deepEqual(results, [options.source, options.source]);
  assert.equal(fs.readFileSync(path.join(options.source, 'native/netrun_bridge.cpp'), 'utf8'), '{}\n');
});

test('an occupied source directory is never replaced or cleaned', async (t) => {
  const options = fixture(t);
  fs.mkdirSync(options.source);
  fs.writeFileSync(path.join(options.source, 'user-file'), 'keep');
  await assert.rejects(ensureCoreSource(options));
  assert.equal(fs.readFileSync(path.join(options.source, 'user-file'), 'utf8'), 'keep');
});

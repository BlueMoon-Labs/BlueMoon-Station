import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { spawnSync } from 'node:child_process';
import { EventEmitter } from 'node:events';
import { fileURLToPath } from 'node:url';
import { boundedLog, compileLive, parseLiveCoreOptions, runLiveCore } from './run-live-core-test.mjs';

test('live CLI keeps the hermetic default and combines a full-map selection with no-build', () => {
  assert.deepEqual(parseLiveCoreOptions([]), { noBuild: false });
  assert.deepEqual(parseLiveCoreOptions(['--no-build']), { noBuild: true });
  assert.deepEqual(parseLiveCoreOptions(['--peace-map']), { noBuild: false, map: '_maps/peacesyndicatestation.json' });
  assert.deepEqual(parseLiveCoreOptions(['--no-build', '--peace-map']), { noBuild: true, map: '_maps/peacesyndicatestation.json' });
  assert.throws(() => parseLiveCoreOptions(['--map']), /Usage:.*--peace-map/);
});

test('live CLI rejects unknown flags before a build, lock or world launch', () => {
  const runner = fileURLToPath(new URL('./run-live-core-test.mjs', import.meta.url));
  const result = spawnSync(process.execPath, [runner, '--peace-map', '--unknown'], {
    cwd: os.tmpdir(), encoding: 'utf8', windowsHide: true,
  });
  assert.equal(result.status, 2);
  assert.match(result.stderr, /Usage: run-live-core-test\.mjs \[--no-build\] \[--peace-map\]/);
  assert.equal(result.stdout, '');
});

test('live compile forwards full-map FORCE_MAP as one JSON-quoted define and preserves the opt-in flag', async () => {
  const root = path.join(os.tmpdir(), 'netrun-live-compile-fixture');
  const environment = { NETRUN_CORE_MODE: 'external' };
  const artifact = { dmb: path.join(root, 'live.dmb'), daemon: 'fixture-dd.exe' };
  const output = [];
  const cases = [
    { options: {}, profile: 'hermetic', defines: [] },
    { options: { map: '_maps/peacesyndicatestation.json' }, profile: 'full-map',
      defines: ['--define=FORCE_MAP "_maps/peacesyndicatestation.json"'] },
    { options: { map: '_maps/map with "quoted" name.json' }, profile: 'full-map',
      defines: ['--define=FORCE_MAP "_maps/map with \\"quoted\\" name.json"'] },
  ];
  for (const { options, profile, defines } of cases) {
    let calls = 0;
    const spawnProcess = (command, args, settings) => {
      calls++;
      assert.equal(command, process.execPath);
      assert.deepEqual(args, [path.join(root, 'tools/build/build.js'), 'dm-test-artifact',
        `--unit-test-profile=${profile}`, '--define=NETRUN_CORE_LIVE_TEST', ...defines, '--warnings-as-errors']);
      assert.equal(settings.cwd, root);
      assert.equal(settings.env, environment);
      assert.equal(settings.windowsHide, true);
      const child = Object.assign(new EventEmitter(), { stdout: new EventEmitter(), stderr: new EventEmitter(),
        exitCode: null, signalCode: null });
      queueMicrotask(() => {
        child.stdout.emit('data', Buffer.from(`NETRUN_TEST_ARTIFACT:${JSON.stringify(artifact)}\n`));
        child.exitCode = 0;
        child.emit('exit', 0);
      });
      return child;
    };
    assert.deepEqual(await compileLive(root, environment, { write: (chunk) => output.push(chunk) }, { ...options, spawnProcess }), artifact);
    assert.equal(calls, 1);
  }
  assert.equal(output.length, cases.length);
});

/** Проверки launcher не создают Host, DD либо native sources; guards должны сработать раньше. */
test('live runner refuses an absent opt-in include before taking the unit-world lock', async (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'netrun-live-guard-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  fs.mkdirSync(path.join(root, 'code/modules/unit_tests'), { recursive: true });
  fs.writeFileSync(path.join(root, 'code/modules/unit_tests/_unit_tests.dm'), '');
  await assert.rejects(runLiveCore({ root, noBuild: true }), /live_test_include_required/);
  assert.equal(fs.existsSync(path.join(root, 'tmp/netrun-tests.lock')), false);
});

test('live runner preserves an existing owner lock and cannot start a second station world', async (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'netrun-live-lock-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  fs.mkdirSync(path.join(root, 'code/modules/unit_tests'), { recursive: true });
  fs.mkdirSync(path.join(root, 'tmp'));
  fs.writeFileSync(path.join(root, 'code/modules/unit_tests/_unit_tests.dm'), '#include "netrun_core_live.dm"\n');
  const lock = path.join(root, 'tmp/netrun-tests.lock');
  fs.writeFileSync(lock, 'existing-owner\n');
  await assert.rejects(runLiveCore({ root, noBuild: true }), /another_station_test_world_owns_lock/);
  assert.equal(fs.readFileSync(lock, 'utf8'), 'existing-owner\n');
});

test('live logs cap stored process output and record explicit truncation once', (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'netrun-live-log-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const filename = path.join(root, 'world.log');
  const log = boundedLog(filename, 12);
  log.write(Buffer.from('12345678'));
  log.write(Buffer.from('abcdefgh'));
  log.write(Buffer.from('must-not-grow'));
  log.close();
  assert.equal(fs.readFileSync(filename, 'utf8'), '12345678abcd\n[log truncated]\n');
});

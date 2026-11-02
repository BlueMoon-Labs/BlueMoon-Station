import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { boundedLog, runLiveCore } from './run-live-core-test.mjs';

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

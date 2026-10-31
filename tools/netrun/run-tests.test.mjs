import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';
import { NetrunTestSuite } from './run-tests.mjs';

const sampleName = '/datum/unit_test/netrun_sample';

function fixture(context) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'netrun-runner-'));
  context.after(() => {
    assert.equal(path.dirname(root), path.resolve(os.tmpdir()));
    fs.rmSync(root, { recursive: true, force: true });
  });
  const write = (relative, content) => {
    const file = path.join(root, relative);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, content);
  };
  return { root, write };
}

test('discover only included, executable Run definitions and deduplicate names', (context) => {
  const { root, write } = fixture(context);
  write('code/modules/unit_tests/_unit_tests.dm', `
// #include "netrun_missing.dm"
#include "netrun_alpha.dm"
#include "netrun_alpha.dm"
#include "unrelated.dm"
`);
  write('code/modules/unit_tests/netrun_alpha.dm', `
/* /datum/unit_test/netrun_comment/Run()
/datum/unit_test/netrun_also_comment/Run()
*/
var/text = {"
/datum/unit_test/netrun_string/Run()
"}
/datum/unit_test/netrun_alpha/Run()
  // actual code
/datum/unit_test/netrun_beta/child/Run()
`);
  write('code/modules/unit_tests/netrun_orphan.dm', '/datum/unit_test/netrun_orphan/Run()');
  const suite = new NetrunTestSuite(root);
  assert.deepEqual(suite.discoverDm(), [
    '/datum/unit_test/netrun_alpha', '/datum/unit_test/netrun_beta/child',
  ]);
  assert.deepEqual(suite.discoverDm('BETA'), ['/datum/unit_test/netrun_beta/child']);
  assert.throws(() => suite.discoverDm('absent'), /No Netrun tests matched/);
});

test('report validation rejects missing, skipped, failed and malformed results', () => {
  const suite = new NetrunTestSuite();
  assert.doesNotThrow(() => suite.validateResults({ [sampleName]: { status: 0 } }, [sampleName]));
  for (const results of [null, [], {}, { [sampleName]: { status: 2 } }, { [sampleName]: { status: 1 } }, { [sampleName]: {} }]) {
    assert.throws(() => suite.validateResults(results, [sampleName]));
  }
  assert.throws(() => suite.validateResults({}, []), /nothing was run/);
});

test('a stale success report cannot pass a run that produces no report', async (context) => {
  const { root, write } = fixture(context);
  write('data/logs/ci-hermetic/unit_tests.json', JSON.stringify({ [sampleName]: { status: 0 } }));
  const suite = new NetrunTestSuite(root, async () => {
    assert.equal(fs.existsSync(suite.resultsFile), false);
  });
  await assert.rejects(suite.runDm([sampleName]), /did not write a fresh/);
  assert.equal(fs.existsSync(suite.lockFile), false, 'Failure must release the runner lock');
});

test('DM dispatch passes an explicit hermetic selection and verifies the fresh report', async (context) => {
  const { root, write } = fixture(context);
  const suite = new NetrunTestSuite(root, async (executable, args, cwd) => {
    assert.equal(executable, process.execPath);
    assert.equal(cwd, root);
    assert.deepEqual(args.slice(1), ['dm-test', '--unit-test-profile=hermetic', '--test-list=tmp/netrun-tests.txt']);
    assert.equal(fs.readFileSync(suite.selectionFile, 'utf8'), `${sampleName}\n`);
    write('data/logs/ci-hermetic/unit_tests.json', JSON.stringify({ [sampleName]: { status: 0 } }));
  });
  await suite.runDm([sampleName]);
  assert.equal(fs.existsSync(suite.lockFile), false);
});

test('a failed compiler cannot be overridden by a superficially successful report', async (context) => {
  const { root, write } = fixture(context);
  const suite = new NetrunTestSuite(root, async () => {
    write('data/logs/ci-hermetic/unit_tests.json', JSON.stringify({ [sampleName]: { status: 0 } }));
    throw new Error('compiler exit 1');
  });
  await assert.rejects(suite.runDm([sampleName]), /compiler exit 1/);
  assert.equal(fs.existsSync(suite.lockFile), false);
});

test('full-map run quotes the DM map define and verifies only its fresh profile report', async (context) => {
  const { root, write } = fixture(context);
  write('data/logs/ci-full-map/unit_tests.json', JSON.stringify({ [sampleName]: { status: 0 } }));
  write('data/logs/ci-hermetic/unit_tests.json', JSON.stringify({ [sampleName]: { status: 0 } }));
  const suite = new NetrunTestSuite(root, async (executable, args) => {
    assert.equal(executable, process.execPath);
    assert.deepEqual(args.slice(1), ['dm-test', '--unit-test-profile=full-map', '--test-list=tmp/netrun-tests.txt', '--define=FORCE_MAP "_maps/peacesyndicatestation.json"']);
    assert.equal(fs.existsSync(path.join(root, 'data/logs/ci-full-map/unit_tests.json')), false);
    write('data/logs/ci-full-map/unit_tests.json', JSON.stringify({ [sampleName]: { status: 0 } }));
  });
  await suite.runDm([sampleName], { map: '_maps/peacesyndicatestation.json' });
  suite.execute = async () => {};
  await assert.rejects(suite.runDm([sampleName], { map: '_maps/peacesyndicatestation.json' }), /did not write a fresh/);
  assert.equal(fs.existsSync(suite.lockFile), false);
});

test('concurrent runner detection preserves the existing owner lock', async (context) => {
  const { root, write } = fixture(context);
  write('tmp/netrun-tests.lock', 'existing owner');
  const suite = new NetrunTestSuite(root, async () => assert.fail('Must not start another world'));
  await assert.rejects(suite.runDm([sampleName]), /already owns/);
  assert.equal(fs.readFileSync(suite.lockFile, 'utf8'), 'existing owner');
});

test('frontend discovery stays inside NetrunTerminal and includes nested tests', (context) => {
  const { root, write } = fixture(context);
  write('tgui/packages/tgui/interfaces/NetrunTerminal/Map.test.tsx', '');
  write('tgui/packages/tgui/interfaces/NetrunTerminal/nested/stream.spec.ts', '');
  write('tgui/packages/tgui/interfaces/NetrunTerminal/Content.tsx', '');
  write('tgui/packages/tgui/interfaces/Unrelated.test.tsx', '');
  const suite = new NetrunTestSuite(root);
  assert.deepEqual(suite.discoverFrontend(), [
    'packages/tgui/interfaces/NetrunTerminal/Map.test.tsx',
    'packages/tgui/interfaces/NetrunTerminal/nested/stream.spec.ts',
  ]);
  assert.deepEqual(suite.discoverFrontend('STREAM'), ['packages/tgui/interfaces/NetrunTerminal/nested/stream.spec.ts']);
});

test('list works from a different working directory and bad CLI arguments fail before building', () => {
  const runner = fileURLToPath(new URL('./run-tests.mjs', import.meta.url));
  const listed = spawnSync(process.execPath, [runner, '--list', '--filter', 'scheduler'], { cwd: os.tmpdir(), encoding: 'utf8' });
  assert.equal(listed.status, 0, listed.stderr);
  assert.match(listed.stdout, /\/datum\/unit_test\/netrun_scheduler_/);
  const invalid = spawnSync(process.execPath, [runner, '--filter'], { cwd: os.tmpdir(), encoding: 'utf8' });
  assert.equal(invalid.status, 1);
  assert.match(invalid.stderr, /requires a nonempty substring/);
  const empty = spawnSync(process.execPath, [runner, '--list', '--filter=no_such_netrun_test_123456'], { cwd: os.tmpdir(), encoding: 'utf8' });
  assert.equal(empty.status, 1);
  assert.match(empty.stderr, /No Netrun tests matched/);
  const mapList = spawnSync(process.execPath, [runner, '--list', '--peace-map'], { cwd: os.tmpdir(), encoding: 'utf8' });
  assert.equal(mapList.status, 0, mapList.stderr);
  assert.equal(mapList.stdout.trim(), '/datum/unit_test/atmos_netrun_roundstart_registration');
  const mixed = spawnSync(process.execPath, [runner, '--peace-map', '--frontend'], { cwd: os.tmpdir(), encoding: 'utf8' });
  assert.equal(mixed.status, 1);
  assert.match(mixed.stderr, /cannot combine/);
});

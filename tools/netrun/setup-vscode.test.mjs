import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { createVscodeConfiguration, installVscode, parseVscodeJson } from './setup-vscode.mjs';

const launch = { version: '0.2.0', configurations: [{ name: 'Launch DreamSeeker', type: 'byond', request: 'launch',
  dmb: '${workspaceFolder}/${command:CurrentDMB}', preLaunchTask: 'Build All', env: { TGUI_DEV_SERVER_IP: '127.0.0.1' } }],
  compounds: [{ name: 'Existing workflow', configurations: ['Other'] }] };
const tasks = { version: '2.0.0', tasks: [{ label: 'Build All', type: 'process', command: 'existing-build' }] };

test('VS Code parser accepts comments/trailing commas without corrupting strings', () => {
  assert.deepEqual(parseVscodeJson('\uFEFF{/* comment */"url":"https://example/x,]", // trailing\n"args":["/*literal*/",],}'), { url: 'https://example/x,]', args: ['/*literal*/'] });
});

test('portable profiles preserve existing work and install idempotently', () => {
  const first = createVscodeConfiguration(launch, tasks);
  const second = createVscodeConfiguration(first.launch, first.tasks);
  assert.deepEqual(first, second);
  assert.deepEqual(first.launch.configurations[0], launch.configurations[0]);
  assert.deepEqual(first.launch.compounds[0], launch.compounds[0]);
  assert.equal(first.tasks.tasks[0].command, 'existing-build');
  const compound = first.launch.compounds.find((entry) => entry.name === 'NETRUN + DreamSeeker');
  assert.equal(compound.preLaunchTask, 'Build All');
  assert.equal(compound.stopAll, true);
  const dm = first.launch.configurations.find((entry) => entry.name === 'NETRUN: Launch DreamSeeker');
  assert.equal(dm.env.TGUI_DEV_SERVER_IP, '127.0.0.1');
  assert.equal(dm.env.NETRUN_CORE_TOKEN_FILE, '${workspaceFolder}/data/netrun-core/session-token.txt');
  assert.equal(dm.env.NETRUN_CORE_LIBRARY, '${workspaceFolder}/data/netrun-core/debug/netrun_bridge.dll');
  assert.equal(dm.preLaunchTask, 'NETRUN: wait for Host');
  assert.equal(dm.postDebugTask, undefined, 'An old session must not stop a newly started workspace Host');
});

test('installer keeps exact backups and tracked templates work on a fresh checkout', (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'netrun-vscode-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const directory = path.join(root, '.vscode');
  fs.mkdirSync(directory);
  const original = '// custom comments\n' + JSON.stringify(launch);
  fs.writeFileSync(path.join(directory, 'launch.json'), original);
  fs.writeFileSync(path.join(directory, 'tasks.json'), JSON.stringify(tasks));
  installVscode({ root });
  installVscode({ root });
  assert.equal(fs.readFileSync(path.join(directory, 'launch.json.netrun-backup'), 'utf8'), original);
  assert.equal(JSON.parse(fs.readFileSync(path.join(directory, 'tasks.json'), 'utf8')).tasks[0].command, 'existing-build');
  const fresh = path.join(root, 'fresh');
  const installed = installVscode({ root: fresh });
  assert.ok(installed.launch.compounds.some((entry) => entry.name === 'NETRUN + DreamSeeker (LOWMEMORYMODE)'));
  assert.ok(installed.tasks.tasks.some((entry) => entry.label === 'Build All'));
});

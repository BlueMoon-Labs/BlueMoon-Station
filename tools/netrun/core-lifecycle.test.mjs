import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import test from 'node:test';
import { snapshotCoreSource, prepareCoreContext, verifyCoreBuild, ensureTokenFile, supervisePair, runManaged } from './core-lifecycle.mjs';

/** Каждый fixture имеет собственный temp root; ни станция, ни настоящий Host в этих тестах не запускаются. */
function fixture(t) {
  const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'netrun-lifecycle-'));
  t.after(() => fs.rmSync(temporary, { recursive: true, force: true }));
  const root = path.join(temporary, 'station');
  const source = path.join(temporary, 'core');
  fs.mkdirSync(root);
  for (const [relative, content] of [
    ['src/Netrun.Host/Netrun.Host.csproj', '<Project />'], ['src/Netrun.Host/Program.cs', 'class Program {}'],
    ['global.json', '{}'], ['native/netrun_bridge.cpp', 'bridge'], ['native/netrun_bridge.def', 'EXPORTS'],
    ['scripts/ensure-toolchains.ps1', 'bootstrap'], ['scripts/toolchain-functions.ps1', 'functions'],
  ]) {
    fs.mkdirSync(path.dirname(path.join(source, relative)), { recursive: true });
    fs.writeFileSync(path.join(source, relative), content);
  }
  return { temporary, root, source };
}

test('retired DM and shadow engines cannot launch an alternate server', async () => {
  for (const mode of ['dm', 'shadow', 'unknown']) await assert.rejects(runManaged({ mode }), /only external is supported/);
});

test('context pins exact dirty source bytes and excludes artifacts/user configuration', (t) => {
  const options = fixture(t);
  const initial = snapshotCoreSource(options.source).digest;
  fs.mkdirSync(path.join(options.source, 'src/Netrun.Host/bin'), { recursive: true });
  fs.writeFileSync(path.join(options.source, 'src/Netrun.Host/bin/stale.cs'), 'ignored');
  fs.writeFileSync(path.join(options.source, 'src/Netrun.Host/appsettings.json'), '{"private":"fixture"}');
  assert.equal(snapshotCoreSource(options.source).digest, initial);
  const staged = prepareCoreContext(options);
  const bytes = fs.readFileSync(path.join(staged.directory, 'source-files.sha256'));
  assert.equal(crypto.createHash('sha256').update(bytes).digest('hex'), staged.digest);
  assert.equal(fs.existsSync(path.join(staged.directory, 'src/Netrun.Host/appsettings.json')), false);
  fs.writeFileSync(path.join(options.source, 'src/Netrun.Host/Program.cs'), 'class Modified {}');
  assert.notEqual(snapshotCoreSource(options.source).digest, staged.digest);
  assert.equal(fs.readFileSync(path.join(staged.directory, 'src/Netrun.Host/Program.cs'), 'utf8'), 'class Program {}');
});

test('toolchain bootstrap changes participate in the source digest and staged build', (t) => {
  const options = fixture(t);
  const staged = prepareCoreContext(options);
  assert.equal(fs.readFileSync(path.join(staged.directory, 'scripts/toolchain-functions.ps1'), 'utf8'), 'functions');
  fs.writeFileSync(path.join(options.source, 'scripts/toolchain-functions.ps1'), 'new verified archive pin');
  assert.notEqual(snapshotCoreSource(options.source).digest, staged.digest);
});

test('launch rejects stale source and corrupted published binaries', (t) => {
  const { root, source } = fixture(t);
  const directory = path.join(root, 'data/netrun-core/builds/generation');
  fs.mkdirSync(directory, { recursive: true });
  const binary = Buffer.from('reviewed artifact');
  fs.writeFileSync(path.join(directory, 'netrun_bridge.dll'), binary);
  const manifest = { directory, source_digest: snapshotCoreSource(source).digest,
    files: [{ path: 'netrun_bridge.dll', sha256: crypto.createHash('sha256').update(binary).digest('hex') }] };
  const pointer = path.join(root, 'data/netrun-core/build.json');
  fs.writeFileSync(pointer, JSON.stringify(manifest));
  assert.equal(verifyCoreBuild({ root, source }).directory, directory);
  fs.writeFileSync(path.join(directory, 'netrun_bridge.dll'), 'modified');
  assert.throws(() => verifyCoreBuild({ root, source }), /core_artifact_checksum/);
  fs.writeFileSync(path.join(source, 'src/Netrun.Host/Program.cs'), 'source changed');
  assert.throws(() => verifyCoreBuild({ root, source }), /core_rebuild_required/);
});

test('token is generated outside checkout, reused unchanged and malformed file fails safely', (t) => {
  const { temporary, root } = fixture(t);
  const filename = path.join(temporary, 'private/token.txt');
  assert.equal(ensureTokenFile({ root, filename }), filename);
  const first = fs.readFileSync(filename, 'utf8');
  assert.match(first, /^[!-~]{32,256}$/);
  ensureTokenFile({ root, filename });
  assert.equal(fs.readFileSync(filename, 'utf8'), first);
  fs.writeFileSync(filename, 'invalid');
  assert.throws(() => ensureTokenFile({ root, filename }), /^Error: invalid_token_file$/);
  assert.throws(() => ensureTokenFile({ root, filename: path.join(root, 'tracked-token.txt') }), /token_file_must_be_ignored_or_external/);
});

test('world starts after Host readiness and normal world exit closes the owned Host', async (t) => {
  const { temporary } = fixture(t);
  const pidFile = path.join(temporary, 'host.pid');
  const host = `require('node:fs').writeFileSync(process.argv[1],String(process.pid));console.log('NETRUN Host listening on loopback:1');setInterval(()=>{},1000)`;
  let started = false;
  let hostOutput = '';
  const exits = [];
  const code = await supervisePair({ cwd: temporary, env: process.env,
    hostCommand: [process.execPath, '-e', host, pidFile], worldCommand: [process.execPath, '-e', 'process.exit(0)'],
    onWorldStarted: () => { started = true; assert.ok(fs.existsSync(pidFile)); },
    hostOutput: (chunk) => { hostOutput += chunk; }, onProcessExit: (result) => exits.push(result) });
  assert.equal(code, 0);
  assert.equal(started, true);
  assert.match(hostOutput, /NETRUN Host listening on loopback:1/);
  assert.equal(exits.length, 2);
  assert.equal(exits[0].process, 'world');
  assert.equal(exits[0].code, 0);
  assert.equal(exits[1].process, 'host');
  assert.throws(() => process.kill(Number(fs.readFileSync(pidFile, 'utf8')), 0));
});

test('unexpected Host exit stops its world and cannot silently switch engines', async (t) => {
  const { temporary } = fixture(t);
  let worldPid;
  const code = await supervisePair({ cwd: temporary, env: process.env,
    hostCommand: [process.execPath, '-e', `console.log('NETRUN Host listening on loopback:1');setTimeout(()=>process.exit(3),250)`],
    worldCommand: [process.execPath, '-e', 'setInterval(()=>{},1000)'], onWorldStarted: (child) => { worldPid = child.pid; } });
  assert.equal(code, 1);
  assert.throws(() => process.kill(worldPid, 0));
});

test('Host failure before readiness never starts a game process', async (t) => {
  const { temporary } = fixture(t);
  let started = false;
  await assert.rejects(supervisePair({ cwd: temporary, env: process.env,
    hostCommand: [process.execPath, '-e', 'process.exit(2)'], worldCommand: [process.execPath, '-e', 'process.exit(0)'],
    onWorldStarted: () => { started = true; } }), /host_exited_before_world/);
  assert.equal(started, false);
  await assert.rejects(supervisePair({ cwd: temporary, env: process.env,
    hostCommand: [path.join(temporary, 'missing-executable')], worldCommand: [process.execPath, '-e', 'process.exit(0)'] }), /host_start_failed/);
});

test('synchronous parent exit, including the Juke signal trap, stops both owned processes', (t) => {
  const { temporary } = fixture(t);
  const hostPidFile = path.join(temporary, 'host.pid');
  const worldPidFile = path.join(temporary, 'world.pid');
  const hostCode = `require('node:fs').writeFileSync(process.argv[1],String(process.pid));console.log('NETRUN Host listening on loopback:1');setInterval(()=>{},1000)`;
  const script = `import fs from 'node:fs';import {supervisePair} from ${JSON.stringify(new URL('./core-lifecycle.mjs', import.meta.url).href)};await supervisePair({cwd:${JSON.stringify(temporary)},env:process.env,hostCommand:[process.execPath,'-e',${JSON.stringify(hostCode)},${JSON.stringify(hostPidFile)}],worldCommand:[process.execPath,'-e','setInterval(()=>{},1000)'],onWorldStarted:child=>{fs.writeFileSync(${JSON.stringify(worldPidFile)},String(child.pid));setTimeout(()=>process.exit(2),100)}})`;
  const ran = spawnSync(process.execPath, ['--input-type=module', '-e', script], { encoding: 'utf8', windowsHide: true, timeout: 5000 });
  assert.equal(ran.status, 2, ran.stderr);
  for (const filename of [hostPidFile, worldPidFile]) {
    assert.throws(() => process.kill(Number(fs.readFileSync(filename, 'utf8')), 0));
  }
});

test('world deadline stops the owned world and Host without exposing captured output', async (t) => {
  const { temporary } = fixture(t);
  let captured = '';
  const code = await supervisePair({ cwd: temporary, env: process.env,
    hostCommand: [process.execPath, '-e', `console.log('NETRUN Host listening on loopback:1');setInterval(()=>{},1000)`],
    worldCommand: [process.execPath, '-e', `console.log('captured-only');setInterval(()=>{},1000)`],
    worldTimeoutMs: 250, worldOutput: (chunk) => { captured += chunk; } });
  assert.equal(code, 1);
  assert.match(captured, /captured-only/);
});

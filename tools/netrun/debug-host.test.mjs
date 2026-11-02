import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { startDebugHost, waitReady, stopDebugHost } from './debug-host.mjs';

function fixture(t, child = null) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'netrun-debug-'));
  const directory = path.join(root, 'build');
  fs.mkdirSync(directory);
  fs.writeFileSync(path.join(directory, 'netrun_bridge.dll'), 'fixture-x86');
  const pidFile = path.join(root, 'host.pid');
  const base = `require('node:fs').writeFileSync(process.argv[1],String(process.pid));`;
  const options = { root, output: () => {}, verifyBuild: () => ({ directory }),
    ensureToken: ({ root: tokenRoot, filename }) => {
      assert.equal(tokenRoot, root);
      assert.equal(filename, path.join(root, 'data/netrun-core/session-token.txt'));
      return filename;
    },
    hostCommand: [process.execPath, '-e', base + (child || `console.log('NETRUN Host listening on loopback:18462');setInterval(()=>{},1000)`), pidFile],
  };
  let started;
  t.after(async () => {
    await stopDebugHost({ root });
    if (started) await started.catch(() => {});
    fs.rmSync(root, { recursive: true, force: true });
  });
  return { root, directory, pidFile, options, start: () => (started = startDebugHost(options)) };
}

async function fileReady(filename) {
  const deadline = Date.now() + 2000;
  while (!fs.existsSync(filename)) {
    if (Date.now() > deadline) throw new Error('fixture_child_missing');
    await new Promise((resolve) => setTimeout(resolve, 10));
  }
}

test('readiness requires a live owner and ignores stale JSON/PIDs', async (t) => {
  const { root } = fixture(t);
  const directory = path.join(root, 'data/netrun-core/debug');
  fs.mkdirSync(directory, { recursive: true });
  fs.writeFileSync(path.join(directory, 'ready.json'), JSON.stringify({ pid: process.pid, hostPid: process.pid }));
  await assert.rejects(waitReady({ root, timeoutMs: 150 }), /debug_host_ready_timeout/);
});

test('ready is published after the DLL copy and stopping closes only the owned Host', async (t) => {
  const { root, pidFile, start } = fixture(t);
  const started = start();
  await waitReady({ root, timeoutMs: 3000 });
  assert.equal(fs.readFileSync(path.join(root, 'data/netrun-core/debug/netrun_bridge.dll'), 'utf8'), 'fixture-x86');
  const hostPid = Number(fs.readFileSync(pidFile, 'utf8'));
  await stopDebugHost({ root });
  assert.equal(await started, 130);
  assert.throws(() => process.kill(hostPid, 0));
  await assert.rejects(waitReady({ root, timeoutMs: 150 }), /debug_host_ready_timeout/);
});

test('concurrent starts cannot replace the DLL or prepare a second Host', async (t) => {
  const { root, directory, pidFile, options, start } = fixture(t, `setTimeout(()=>console.log('NETRUN Host listening on loopback:18462'),200);setInterval(()=>{},1000)`);
  const started = start();
  await fileReady(pidFile);
  let prepared = false;
  await assert.rejects(startDebugHost({ ...options, verifyBuild: () => { prepared = true; return { directory }; } }), /debug_host_already_running/);
  assert.equal(prepared, false);
  await waitReady({ root, timeoutMs: 3000 });
  await stopDebugHost({ root });
  await started;
});

test('an inherited literal token cannot override the generated shared token file', async (t) => {
  const old = process.env.NETRUN_SESSION_TOKEN;
  process.env.NETRUN_SESSION_TOKEN = 'fixture-stale-literal-token-that-must-not-win';
  t.after(() => { if (old === undefined) delete process.env.NETRUN_SESSION_TOKEN; else process.env.NETRUN_SESSION_TOKEN = old; });
  const { root, start } = fixture(t, `if(process.env.NETRUN_SESSION_TOKEN||!process.env.NETRUN_SESSION_TOKEN_FILE.endsWith('session-token.txt'))process.exit(4);console.log('NETRUN Host listening on loopback:18462');setInterval(()=>{},1000)`);
  const started = start();
  await waitReady({ root, timeoutMs: 3000 });
  await stopDebugHost({ root });
  await started;
});

test('Host readiness timeout closes the child and releases the workspace owner', async (t) => {
  const { root, pidFile, options } = fixture(t, 'setInterval(()=>{},1000)');
  await assert.rejects(startDebugHost({ ...options, startupTimeoutMs: 100 }), /debug_host_start_timeout/);
  assert.throws(() => process.kill(Number(fs.readFileSync(pidFile, 'utf8')), 0));
  // A fresh foreground launch can own the same pipe after the failed startup.
  const started = startDebugHost({ ...options, hostCommand: [process.execPath, '-e', `console.log('NETRUN Host listening on loopback:18462');setInterval(()=>{},1000)`] });
  await waitReady({ root, timeoutMs: 3000 });
  await stopDebugHost({ root });
  await started;
});

test('spawn failure and premature Host exit release the control endpoint', async (t) => {
  const { options, root } = fixture(t);
  await assert.rejects(startDebugHost({ ...options, hostCommand: [path.join(root, 'missing.exe')] }), /debug_host_start_failed/);
  await assert.rejects(startDebugHost({ ...options, hostCommand: [process.execPath, '-e', 'process.exit(2)'] }), /debug_host_exited_before_ready/);
});

test('parallel readiness receives a failed Host startup instead of waiting for its deadline', async (t) => {
  const { options, root } = fixture(t);
  for (const [overrides, code] of [
    [{ hostCommand: [path.join(root, 'missing.exe')] }, 'debug_host_start_failed'],
    [{ hostCommand: [process.execPath, '-e', 'process.exit(2)'] }, 'debug_host_exited_before_ready'],
    [{ ensureToken: () => { throw new Error('invalid_token_file'); } }, 'invalid_token_file'],
  ]) {
    const started = assert.rejects(startDebugHost({ ...options, ...overrides }), new RegExp(`^Error: ${code}$`));
    // The normal deadline is deliberately much longer than the handoff window.
    // Racing against a short bound catches the old vanished-pipe/60s timeout bug.
    let timer;
    try {
      await Promise.race([
        assert.rejects(waitReady({ root, timeoutMs: 10000 }), new RegExp(`^Error: ${code}$`)),
        new Promise((_, reject) => { timer = setTimeout(() => reject(new Error('failure_not_handed_to_waiter')), 2000); }),
      ]);
    } finally { clearTimeout(timer); }
    await started;
  }
});

test('readiness failure handoff never exposes arbitrary exception contents', async (t) => {
  const { options, root } = fixture(t);
  const started = assert.rejects(startDebugHost({ ...options, ensureToken: () => { throw new Error('fixture-secret-must-not-cross-the-control-pipe'); } }), /fixture-secret/);
  await assert.rejects(waitReady({ root, timeoutMs: 2000 }), /^Error: debug_host_prepare_failed$/);
  await started;
});

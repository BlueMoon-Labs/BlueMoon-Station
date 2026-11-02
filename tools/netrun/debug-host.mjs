#!/usr/bin/env node
/** VS Code owns this process and its Host. Readiness is checked through a live local control pipe. */
import fs from 'node:fs';
import net from 'node:net';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawn } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import { stationRoot, verifyCoreBuild, ensureTokenFile, dotnetPath, stopChild } from './core-lifecycle.mjs';

/** A workspace has one owner even while the SDK and DLL are still being prepared. */
export function debugEndpoint(root = stationRoot) {
  const normalized = path.resolve(root);
  const id = crypto.createHash('sha256').update(process.platform === 'win32' ? normalized.toLowerCase() : normalized).digest('hex').slice(0, 24);
  return process.platform === 'win32' ? `\\\\.\\pipe\\netrun-debug-${id}` : path.join(os.tmpdir(), `netrun-debug-${id}.sock`);
}

/** Only fixed status/stop messages cross this pipe; it cannot launch commands or reveal the token. */
function controlRequest(root, command, timeoutMs = 1000) {
  return new Promise((resolve, reject) => {
    const socket = net.connect(debugEndpoint(root));
    let response = '';
    socket.setTimeout(timeoutMs, () => socket.destroy(new Error('debug_host_control_timeout')));
    socket.once('error', reject);
    socket.once('connect', () => socket.write(`${command}\n`));
    socket.on('data', (chunk) => {
      response += chunk;
      if (response.length > 4096) socket.destroy(new Error('debug_host_control_response'));
    });
    socket.once('end', () => {
      try { resolve(JSON.parse(response)); } catch { reject(new Error('debug_host_control_response')); }
    });
  });
}

/** A stale JSON file or a reused PID can never satisfy this readiness check. */
export async function waitReady({ root = stationRoot, timeoutMs = 60000 } = {}) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    try {
      const status = await controlRequest(root, 'status', Math.min(1000, Math.max(1, deadline - Date.now())));
      if (status.state === 'ready') return;
      if (status.state === 'failed') throw new Error(status.code || 'debug_host_start_failed');
    } catch (error) {
      if (!['ENOENT', 'ECONNREFUSED', 'ECONNRESET', 'EPIPE'].includes(error.code)) throw error;
    }
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  throw new Error('debug_host_ready_timeout: start a NETRUN compound configuration');
}

/** The live pipe asks its owner to stop its own child; no PID from a file is killed. */
export async function stopDebugHost({ root = stationRoot } = {}) {
  try { await controlRequest(root, 'stop', 6500); }
  catch (error) {
    if (!['ENOENT', 'ECONNREFUSED', 'ECONNRESET', 'EPIPE'].includes(error.code)) throw error;
  }
}

/** Dependency seams let tests use a tiny child instead of a real station, SDK, or secret. */
export async function startDebugHost({ root = stationRoot, verifyBuild = verifyCoreBuild, ensureToken = ensureTokenFile,
  resolveDotnet = dotnetPath, hostCommand = null, port = '18462', output = (chunk) => process.stdout.write(chunk), startupTimeoutMs = 10000 } = {}) {
  const debugDirectory = path.join(root, 'data/netrun-core/debug');
  const status = { state: 'starting', pid: process.pid };
  let host;
  let interrupted = false;
  let timer;
  let failureObserved = () => {};
  const interrupt = () => { interrupted = true; status.state = 'stopping'; void stopChild(host); };
  const cleanupAtExit = () => {
    if (host?.pid && host.exitCode === null && host.signalCode === null) host.kill('SIGTERM');
  };
  const control = net.createServer((socket) => {
    let command = '';
    socket.setTimeout(1000, () => socket.destroy());
    socket.on('error', () => {});
    socket.on('data', (chunk) => {
      command += chunk;
      if (command.length > 16) { socket.destroy(); return; }
      if (!command.endsWith('\n')) return;
      if (command === 'status\n') {
        if (status.state === 'failed') socket.once('finish', () => failureObserved());
        socket.end(JSON.stringify(status));
      }
      else if (command === 'stop\n') {
        interrupt();
        void stopChild(host).then(() => socket.end('{"state":"stopped"}'));
      } else socket.destroy();
    });
  });
  await new Promise((resolve, reject) => {
    control.once('error', (error) => reject(new Error(error.code === 'EADDRINUSE' ? 'debug_host_already_running' : 'debug_host_control_start_failed')));
    control.listen(debugEndpoint(root), resolve);
  });
  process.once('exit', cleanupAtExit);
  process.once('SIGINT', interrupt);
  process.once('SIGTERM', interrupt);
  try {
    const built = verifyBuild({ root });
    // VS Code and DM always use the same generated file, regardless of inherited token overrides.
    const token = ensureToken({ root, filename: path.join(root, 'data/netrun-core/session-token.txt') });
    const dotnet = hostCommand ? null : await resolveDotnet({ root });
    if (interrupted) return 130;
    fs.mkdirSync(debugDirectory, { recursive: true });
    fs.copyFileSync(path.join(built.directory, 'netrun_bridge.dll'), path.join(debugDirectory, 'netrun_bridge.dll'));
    const env = { ...process.env, NETRUN_SESSION_TOKEN_FILE: token };
    delete env.NETRUN_SESSION_TOKEN;
    const command = hostCommand || [dotnet, path.join(built.directory, 'host/Netrun.Host.dll'), 'serve', port];
    host = spawn(command[0], command.slice(1), { cwd: root, env, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] });
    status.hostPid = host.pid;
    let tail = '';
    let ready = false;
    let timedOut = false;
    timer = setTimeout(() => { timedOut = true; void stopChild(host); }, startupTimeoutMs);
    const read = (chunk) => {
      output(chunk);
      tail = (tail + chunk.toString()).slice(-65536);
      if (!ready && tail.includes(`NETRUN Host listening on loopback:${port}`)) {
        ready = true;
        clearTimeout(timer);
        status.state = 'ready';
      }
    };
    host.stdout.on('data', read);
    host.stderr.on('data', read);
    const code = await new Promise((resolve, reject) => {
      host.once('error', () => reject(new Error('debug_host_start_failed')));
      host.once('exit', (value) => resolve(value ?? 1));
    });
    if (timedOut) throw new Error('debug_host_start_timeout');
    if (!ready && !interrupted) throw new Error('debug_host_exited_before_ready');
    return interrupted ? 130 : code;
  } catch (error) {
    status.state = 'failed';
    // Report only fixed startup diagnostics, never arbitrary exception text,
    // paths or the contents of a malformed token file to the parallel DM task.
    status.code = ['debug_host_start_failed', 'debug_host_start_timeout', 'debug_host_exited_before_ready',
      'core_rebuild_required', 'core_artifact_manifest', 'core_artifact_checksum', 'invalid_token_file',
      'token_file_must_be_ignored_or_external'].includes(error.message) ? error.message : 'debug_host_prepare_failed';
    // A failed Host may exit before the first readiness poll. Keep its live
    // endpoint until that poll consumes the error, with a bounded handoff.
    let handoffTimer;
    try {
      await new Promise((resolve) => {
        failureObserved = resolve;
        handoffTimer = setTimeout(resolve, 1000);
      });
    } finally {
      clearTimeout(handoffTimer);
    }
    throw error;
  } finally {
    clearTimeout(timer);
    cleanupAtExit();
    await stopChild(host);
    await new Promise((resolve) => control.close(resolve));
    process.removeListener('exit', cleanupAtExit);
    process.removeListener('SIGINT', interrupt);
    process.removeListener('SIGTERM', interrupt);
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  const command = process.argv[2];
  (command === 'wait-ready' ? waitReady() : command === 'stop' ? stopDebugHost() : command === 'start' ? startDebugHost() : Promise.reject(new Error('Usage: debug-host.mjs start | wait-ready | stop')))
    .then((code) => { process.exitCode = code || 0; })
    .catch((error) => { console.error(`NETRUN: ${error.message}`); process.exitCode = 1; });
}

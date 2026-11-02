#!/usr/bin/env node
/** VS Code owns this process; its exit hook closes only the Host it started. */
import fs from 'node:fs';
import path from 'node:path';
import { spawn } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import { stationRoot, verifyCoreBuild, ensureTokenFile, dotnetPath, stopChild } from './core-lifecycle.mjs';

const debugDirectory = path.join(stationRoot, 'data/netrun-core/debug');
const readyFile = path.join(debugDirectory, 'ready.json');

function running(pid) {
  if (!Number.isSafeInteger(pid) || pid <= 0) return false;
  try { process.kill(pid, 0); return true; } catch { return false; }
}

function readReady() {
  try { return JSON.parse(fs.readFileSync(readyFile, 'utf8')); } catch { return null; }
}

export async function waitReady(timeoutMs = 60000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const ready = readReady();
    if (ready && running(ready.pid) && running(ready.hostPid)) return;
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  throw new Error('debug_host_ready_timeout: start a NETRUN compound configuration');
}

export async function startDebugHost() {
  const previous = readReady();
  if (previous && running(previous.pid) && running(previous.hostPid)) throw new Error('debug_host_already_running');
  const built = verifyCoreBuild();
  const token = ensureTokenFile();
  const dotnet = await dotnetPath();
  fs.mkdirSync(debugDirectory, { recursive: true });
  fs.copyFileSync(path.join(built.directory, 'netrun_bridge.dll'), path.join(debugDirectory, 'netrun_bridge.dll'));
  const env = { ...process.env, NETRUN_SESSION_TOKEN_FILE: token };
  delete env.NETRUN_SESSION_TOKEN;
  // The matching launch.json explicitly uses this port and token path for DM.
  const host = spawn(dotnet, [path.join(built.directory, 'host/Netrun.Host.dll'), 'serve', '18462'],
    { cwd: stationRoot, env, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] });
  const cleanup = () => {
    if (readReady()?.pid === process.pid) fs.rmSync(readyFile, { force: true });
    if (host.pid && host.exitCode === null) host.kill('SIGTERM');
  };
  const interrupt = () => { void stopChild(host); };
  process.once('exit', cleanup);
  process.once('SIGINT', interrupt);
  process.once('SIGTERM', interrupt);
  let tail = '';
  let ready = false;
  const timer = setTimeout(interrupt, 10000);
  const read = (chunk) => {
    process.stdout.write(chunk);
    tail = (tail + chunk.toString()).slice(-1024);
    if (!ready && tail.includes('NETRUN Host listening on loopback:18462')) {
      ready = true;
      clearTimeout(timer);
      fs.writeFileSync(readyFile, JSON.stringify({ pid: process.pid, hostPid: host.pid }));
    }
  };
  host.stdout.on('data', read);
  host.stderr.on('data', read);
  try {
    return await new Promise((resolve, reject) => {
      host.once('error', () => reject(new Error('debug_host_start_failed')));
      host.once('exit', (code) => resolve(code ?? 1));
    });
  } finally {
    clearTimeout(timer);
    cleanup();
    process.removeListener('exit', cleanup);
    process.removeListener('SIGINT', interrupt);
    process.removeListener('SIGTERM', interrupt);
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  const command = process.argv[2];
  (command === 'wait-ready' ? waitReady() : command === 'start' ? startDebugHost() : Promise.reject(new Error('Usage: debug-host.mjs start | wait-ready')))
    .then((code) => { process.exitCode = code || 0; })
    .catch((error) => { console.error(`NETRUN: ${error.message}`); process.exitCode = 1; });
}

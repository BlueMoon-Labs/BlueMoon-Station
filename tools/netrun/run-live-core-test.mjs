#!/usr/bin/env node
/** Opt-in настоящий station-code smoke: Juke compile, затем owned published Host + DreamDaemon. */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawn, spawnSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import { stationRoot, buildCore, verifyCoreBuild, ensureTokenFile, dotnetPath, supervisePair } from './core-lifecycle.mjs';

export const liveTestName = '/datum/unit_test/netrun_core_live';

/** Вывод пишется в ignored logfile с пределом, stdout получает только фиксированные stage markers. */
export function boundedLog(filename, limit = 8 * 1024 * 1024, reportStages = false) {
  const descriptor = fs.openSync(filename, 'wx');
  let used = 0;
  let truncated = false;
  let tail = '';
  const seen = new Set();
  return {
    write(chunk) {
      const bytes = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
      const count = Math.min(bytes.length, Math.max(0, limit - used));
      if (count) { fs.writeSync(descriptor, bytes.subarray(0, count)); used += count; }
      if (count < bytes.length && !truncated) { fs.writeSync(descriptor, '\n[log truncated]\n'); truncated = true; }
      if (reportStages) {
        tail = (tail + bytes.toString()).slice(-1024);
        for (const match of tail.matchAll(/NETRUN_CORE_LIVE_(?:STAGE|PASS) [a-z0-9_ ]+/g)) {
          const marker = match[0].trim();
          if (!seen.has(marker) && seen.size < 32) { seen.add(marker); console.log(marker); }
        }
      }
    },
    close() { fs.closeSync(descriptor); },
  };
}

/** Собирает фактический Juke artifact и читает только его отдельный bounded metadata marker. */
export async function compileLive(root, environment, log, { map, spawnProcess = spawn } = {}) {
  let child;
  let deadline;
  // На Windows TerminateProcess не вызывает JS trap дочернего Juke; вместе с ним закрываем только его compiler tree.
  const stopAtExit = () => {
    if (!child?.pid || child.exitCode !== null || child.signalCode !== null) return;
    if (process.platform === 'win32') spawnSync('taskkill.exe', ['/PID', `${child.pid}`, '/T', '/F'], { windowsHide: true, stdio: 'ignore' });
    else child.kill('SIGTERM');
  };
  const stopOnSignal = () => { stopAtExit(); };
  process.once('exit', stopAtExit);
  process.once('SIGINT', stopOnSignal);
  process.once('SIGTERM', stopOnSignal);
  try {
    return await new Promise((resolve, reject) => {
      let tail = '';
      child = spawnProcess(process.execPath, [path.join(root, 'tools/build/build.js'), 'dm-test-artifact',
        `--unit-test-profile=${map ? 'full-map' : 'hermetic'}`, '--define=NETRUN_CORE_LIVE_TEST',
        ...(map ? [`--define=FORCE_MAP ${JSON.stringify(map)}`] : []), '--warnings-as-errors'],
      { cwd: root, env: environment, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] });
      // Полная DM-компиляция на Windows при параллельной Docker-сборке занимает более пяти минут.
      deadline = setTimeout(stopAtExit, 600000);
      const read = (chunk) => { log.write(chunk); tail = (tail + chunk.toString()).slice(-16384); };
      child.stdout.on('data', read);
      child.stderr.on('data', read);
      child.once('error', () => reject(new Error('live_compile_start_failed')));
      child.once('exit', (code) => {
        if (code !== 0) { reject(new Error('live_compile_failed')); return; }
        const marker = tail.match(/NETRUN_TEST_ARTIFACT:(\{[^\r\n]+\})/);
        if (!marker) { reject(new Error('live_compile_artifact_missing')); return; }
        try { resolve(JSON.parse(marker[1])); } catch { reject(new Error('live_compile_artifact_invalid')); }
      });
    });
  } finally {
    clearTimeout(deadline);
    process.removeListener('exit', stopAtExit);
    process.removeListener('SIGINT', stopOnSignal);
    process.removeListener('SIGTERM', stopOnSignal);
  }
}

/** Shared unit-world lock сохраняет RSC/assets/test arena exclusivity с обычным station test runner. */
export async function runLiveCore({ root = stationRoot, noBuild = false, timeoutSeconds = 600, map } = {}) {
  const manifestFile = path.join(root, 'code/modules/unit_tests/_unit_tests.dm');
  if (!/^\s*#include\s+"netrun_core_live\.dm"/m.test(fs.readFileSync(manifestFile, 'utf8'))) throw new Error('live_test_include_required');
  const lockPath = path.join(root, 'tmp/netrun-tests.lock');
  fs.mkdirSync(path.dirname(lockPath), { recursive: true });
  let lock;
  try { lock = fs.openSync(lockPath, 'wx'); } catch (error) { if (error.code === 'EEXIST') throw new Error('another_station_test_world_owns_lock'); throw error; }
  let compileLog;
  let worldLog;
  let hostLog;
  try {
    fs.writeFileSync(lock, `${process.pid}\n`);
    if (!noBuild) await buildCore({ root });
    const built = verifyCoreBuild({ root });
    const tokenFile = ensureTokenFile({ root });
    const runId = `core-live-${crypto.randomBytes(6).toString('hex')}`;
    const directory = path.join(root, 'data/netrun-core/live-tests', runId);
    fs.mkdirSync(directory, { recursive: true });
    const selection = path.join(root, 'tmp/netrun-core-live.txt');
    fs.writeFileSync(selection, `${liveTestName}\n`);
    const environment = { ...process.env, NETRUN_CORE_MODE: 'external', NETRUN_CORE_LIVE_TEST: '1', NETRUN_CORE_BUILD: '0',
      NETRUN_CORE_TOKEN_FILE: tokenFile, NETRUN_SESSION_TOKEN_FILE: tokenFile, NETRUN_CORE_LIBRARY: path.join(built.directory, 'netrun_bridge.dll') };
    delete environment.NETRUN_SESSION_TOKEN;
    compileLog = boundedLog(path.join(directory, 'compile.log'));
    console.log('Compiling the opt-in live station profile...');
    const artifact = await compileLive(root, environment, compileLog, { map });
    const dmb = path.resolve(artifact.dmb);
    if (!dmb.startsWith(path.resolve(root) + path.sep) || !fs.existsSync(dmb)) throw new Error('live_artifact_outside_checkout');
    if (typeof artifact.daemon !== 'string' || !artifact.daemon.length) throw new Error('live_daemon_path_missing');
    const corePort = process.env.NETRUN_CORE_PORT || '18462';
    if (!/^[1-9]\d{0,4}$/.test(corePort) || Number(corePort) > 65535) throw new Error('invalid_core_port');
    environment.NETRUN_CORE_PORT = corePort;
    const logDirectory = `ci-netrun-${runId}`;
    worldLog = boundedLog(path.join(directory, 'world.log'), 8 * 1024 * 1024, true);
    hostLog = boundedLog(path.join(directory, 'host.log'));
    console.log('Starting the published Host and real station DreamDaemon...');
    const code = await supervisePair({ cwd: root, env: environment,
      hostCommand: [await dotnetPath({ root }), path.join(built.directory, 'host/Netrun.Host.dll'), 'serve', corePort],
      worldCommand: [artifact.daemon, dmb, '-close', '-trusted', '-invisible', '-verbose', '-params',
        `log-directory=${logDirectory}&unit-test-instance=${runId}&unit-test-list=tmp/netrun-core-live.txt`],
      worldOutput: (chunk) => worldLog.write(chunk), hostOutput: (chunk) => hostLog.write(chunk),
      onProcessExit: (result) => fs.appendFileSync(path.join(directory, 'process-exits.jsonl'), `${JSON.stringify(result)}\n`),
      worldTimeoutMs: timeoutSeconds * 1000 });
    const reportFile = path.join(root, 'data/logs', logDirectory, 'unit_tests.json');
    if (code !== 0 || !fs.existsSync(reportFile)) throw new Error(`live_world_failed exit=${code}; logs=${directory}`);
    const report = JSON.parse(fs.readFileSync(reportFile, 'utf8'));
    if (report[liveTestName]?.status !== 0) throw new Error(`live_assertion_failed: ${`${report[liveTestName]?.message || 'missing result'}`.slice(0, 4096)}; logs=${directory}`);
    const output = fs.readFileSync(path.join(directory, 'world.log'), 'utf8');
    if (!output.includes('NETRUN_CORE_LIVE_PASS discovery native_once projection source_tree movement state external_only')) throw new Error('live_pass_marker_missing');
    console.log(`PASS: real station Core smoke; source=${built.source_digest}; logs=${directory}`);
    return { digest: built.source_digest, directory };
  } finally {
    compileLog?.close();
    worldLog?.close();
    hostLog?.close();
    fs.closeSync(lock);
    fs.rmSync(lockPath);
  }
}

/** Разбор CLI отделён от запуска, чтобы проверка опций не создавала station world. */
export function parseLiveCoreOptions(args) {
  if (args.some((arg) => arg !== '--no-build' && arg !== '--peace-map')) {
    throw new Error('Usage: run-live-core-test.mjs [--no-build] [--peace-map]');
  }
  return { noBuild: args.includes('--no-build'),
    ...(args.includes('--peace-map') ? { map: '_maps/peacesyndicatestation.json' } : {}) };
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  let options;
  try { options = parseLiveCoreOptions(process.argv.slice(2)); }
  catch (error) { console.error(error.message); process.exitCode = 2; }
  if (options) runLiveCore(options).catch((error) => { console.error(`NETRUN live: ${error.message}`); process.exitCode = 1; });
}

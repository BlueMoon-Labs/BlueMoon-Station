#!/usr/bin/env node
/** Сборка и парный lifecycle внешнего ядра; секреты не передаются через argv или build context. */
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawn, spawnSync } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';

export const stationRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const sha256 = (value) => crypto.createHash('sha256').update(value).digest('hex');
const stateRoot = (root) => path.join(root, 'data/netrun-core');

/** Берёт явный local checkout; удалённый latest, clone и автоматический pull здесь отсутствуют. */
export const resolveCoreSource = (root = stationRoot, source = process.env.NETRUN_CORE_SOURCE) =>
  path.resolve(source || path.join(root, '..', 'netrun-core'));

/** Перечисляет только build inputs; bin/obj, symlinks, user settings и secrets не копируются. */
function sourceFiles(source) {
  const result = [];
  const walk = (directory) => {
    for (const entry of fs.readdirSync(path.join(source, directory), { withFileTypes: true })) {
      if (entry.name === 'bin' || entry.name === 'obj') continue;
      const relative = `${directory}/${entry.name}`;
      if (entry.isSymbolicLink()) throw new Error('core_source_symlink');
      if (entry.isDirectory()) walk(relative);
      else if (entry.isFile() && (/\.(cs|csproj|props|targets)$/.test(entry.name) || entry.name === 'packages.lock.json')) result.push(relative);
    }
  };
  walk('src');
  for (const relative of ['global.json', 'Directory.Build.props', 'Directory.Build.targets', '.editorconfig',
    'native/netrun_bridge.cpp', 'native/netrun_bridge.def', 'native/netrun_bridge.map', 'scripts/build-native.ps1']) {
    if (fs.existsSync(path.join(source, relative))) result.push(relative);
  }
  if (!result.includes('src/Netrun.Host/Netrun.Host.csproj') || !result.includes('native/netrun_bridge.cpp')) throw new Error('core_source_invalid');
  return result.sort();
}

/** Сохраняет bytes один раз: digest и staged context относятся к одному состоянию dirty checkout. */
export function snapshotCoreSource(source) {
  const files = new Map();
  let total = 0;
  for (const relative of sourceFiles(source)) {
    if (!/^[A-Za-z0-9_./-]+$/.test(relative)) throw new Error('core_source_filename');
    const filename = path.join(source, relative);
    if (fs.lstatSync(filename).isSymbolicLink()) throw new Error('core_source_symlink');
    const size = fs.statSync(filename).size;
    if (files.size >= 10000 || size > 4 * 1024 * 1024 || (total += size) > 64 * 1024 * 1024) throw new Error('core_source_size');
    files.set(relative, fs.readFileSync(filename));
  }
  const manifest = [...files].map(([relative, bytes]) => `${sha256(bytes)}  ${relative}\n`).join('');
  const revision = spawnSync('git', ['-C', source, 'rev-parse', 'HEAD'], { encoding: 'utf8', windowsHide: true });
  return { files, manifest, digest: sha256(manifest), revision: revision.status === 0 ? revision.stdout.trim() : null };
}

/** BuildKit получает отдельный минимальный context с checksum manifest вместо всего соседнего checkout. */
export function prepareCoreContext({ root = stationRoot, source = resolveCoreSource(root) } = {}) {
  const snapshot = snapshotCoreSource(source);
  const parent = path.join(stateRoot(root), 'contexts');
  fs.mkdirSync(parent, { recursive: true });
  const directory = fs.mkdtempSync(path.join(parent, `${snapshot.digest.slice(0, 12)}-`));
  for (const [relative, bytes] of snapshot.files) {
    fs.mkdirSync(path.dirname(path.join(directory, relative)), { recursive: true });
    fs.writeFileSync(path.join(directory, relative), bytes);
  }
  fs.writeFileSync(path.join(directory, 'source-files.sha256'), snapshot.manifest);
  fs.writeFileSync(path.join(directory, 'source-manifest.json'), JSON.stringify({ source_digest: snapshot.digest, revision: snapshot.revision }, null, 2));
  return { directory, digest: snapshot.digest, revision: snapshot.revision };
}

/** Запускает один инструмент напрямую, без shell interpolation и видимых вспомогательных Windows окон. */
export function runCommand(command, args, options = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, { stdio: 'inherit', windowsHide: true, ...options });
    const stopAtExit = () => { if (child.pid && child.exitCode === null) child.kill('SIGTERM'); };
    process.once('exit', stopAtExit);
    child.once('close', () => process.removeListener('exit', stopAtExit));
    child.once('error', () => reject(new Error(`tool_start_failed:${path.basename(command)}`)));
    child.once('exit', (code) => code === 0 ? resolve() : reject(new Error(`tool_failed:${path.basename(command)}:${code}`)));
  });
}

/** Предпочитает явно выбранный SDK, затем уже установленный user-local SDK; ничего не устанавливает. */
export function dotnetPath() {
  if (process.env.NETRUN_DOTNET) return process.env.NETRUN_DOTNET;
  const cached = path.join(os.homedir(), '.codex/cache/netrun-dotnet/sdk', process.platform === 'win32' ? 'dotnet.exe' : 'dotnet');
  return fs.existsSync(cached) ? cached : 'dotnet';
}

/** Хэширует уже собранные bounded outputs; manifest launcher проверяет до открытия listener. */
function outputFiles(directory, prefix = '') {
  const result = [];
  for (const entry of fs.readdirSync(path.join(directory, prefix), { withFileTypes: true })) {
    const relative = prefix ? `${prefix}/${entry.name}` : entry.name;
    if (entry.isDirectory()) result.push(...outputFiles(directory, relative));
    else if (entry.isFile()) result.push({ path: relative, sha256: sha256(fs.readFileSync(path.join(directory, relative))) });
    else throw new Error('core_output_invalid');
  }
  return result.sort((first, second) => first.path.localeCompare(second.path));
}

/** Local default build публикует Host и x86 DLL в ignored generation, затем атомарно публикует manifest. */
export async function buildCore({ root = stationRoot, source = resolveCoreSource(root) } = {}) {
  if (process.env.NETRUN_CORE_MODE === 'dm' || process.env.NETRUN_CORE_BUILD === '0') return null;
  if (process.platform !== 'win32') throw new Error('local_core_build_requires_windows; use the Docker build on Linux');
  const snapshot = prepareCoreContext({ root, source });
  const stagedSource = snapshot.directory;
  const parent = path.join(stateRoot(root), 'builds');
  fs.mkdirSync(parent, { recursive: true });
  const directory = fs.mkdtempSync(path.join(parent, `${snapshot.digest.slice(0, 12)}-`));
  await runCommand(dotnetPath(), ['restore', path.join(stagedSource, 'src/Netrun.Host/Netrun.Host.csproj'), '--locked-mode'], { cwd: stagedSource });
  await runCommand(dotnetPath(), ['publish', path.join(stagedSource, 'src/Netrun.Host/Netrun.Host.csproj'), '--configuration', 'Release',
    '--no-restore', '--output', path.join(directory, 'host'), '/p:UseAppHost=false'], { cwd: stagedSource });
  const nativeArguments = ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(stagedSource, 'scripts/build-native.ps1'), '-Target', 'windows-x86'];
  if (process.env.NETRUN_ZIG) nativeArguments.push('-ZigPath', process.env.NETRUN_ZIG);
  await runCommand('powershell.exe', nativeArguments, { cwd: stagedSource });
  fs.copyFileSync(path.join(stagedSource, 'native/bin/netrun_bridge.dll'), path.join(directory, 'netrun_bridge.dll'));
  if (snapshotCoreSource(source).digest !== snapshot.digest) throw new Error('core_source_changed_during_build');
  const manifest = { directory, source, source_digest: snapshot.digest, revision: snapshot.revision, files: outputFiles(directory) };
  const destination = path.join(stateRoot(root), 'build.json');
  const temporary = `${destination}.${process.pid}.tmp`;
  fs.writeFileSync(temporary, JSON.stringify(manifest, null, 2));
  fs.renameSync(temporary, destination);
  console.log(`NETRUN Core built: ${snapshot.digest}`);
  return manifest;
}

/** Не допускает устаревший или изменённый бинарный пакет при --no-build запуске. */
export function verifyCoreBuild({ root = stationRoot, source = resolveCoreSource(root) } = {}) {
  const manifest = JSON.parse(fs.readFileSync(path.join(stateRoot(root), 'build.json'), 'utf8'));
  const allowed = path.resolve(stateRoot(root), 'builds') + path.sep;
  if (!path.resolve(manifest.directory).startsWith(allowed) || snapshotCoreSource(source).digest !== manifest.source_digest) throw new Error('core_rebuild_required');
  if (!Array.isArray(manifest.files) || manifest.files.length > 1024) throw new Error('core_artifact_manifest');
  for (const file of manifest.files) {
    const target = path.resolve(manifest.directory, file.path);
    if (!target.startsWith(path.resolve(manifest.directory) + path.sep) || sha256(fs.readFileSync(target)) !== file.sha256) throw new Error('core_artifact_checksum');
  }
  const actual = outputFiles(manifest.directory);
  if (actual.length !== manifest.files.length || actual.some((file) => !manifest.files.some((expected) => expected.path === file.path && expected.sha256 === file.sha256))) throw new Error('core_artifact_checksum');
  return manifest;
}

/** Создаёт token только в ignored data либо использует внешний файл; значение не возвращается в логи/argv. */
export function ensureTokenFile({ root = stationRoot, filename = process.env.NETRUN_CORE_TOKEN_FILE } = {}) {
  const target = path.resolve(filename || path.join(stateRoot(root), 'session-token.txt'));
  if (target.startsWith(path.resolve(root) + path.sep)) {
    const ignored = spawnSync('git', ['check-ignore', '--quiet', '--', target], { cwd: root, windowsHide: true });
    if (ignored.status !== 0) throw new Error('token_file_must_be_ignored_or_external');
  }
  fs.mkdirSync(path.dirname(target), { recursive: true });
  try {
    fs.writeFileSync(target, crypto.randomBytes(48).toString('base64url'), { flag: 'wx', mode: 0o640 });
  } catch (error) {
    if (error.code !== 'EEXIST') throw error;
  }
  const info = fs.lstatSync(target);
  if (!info.isFile() || info.size < 32 || info.size > 1024 || !/^[!-~]{32,256}$/.test(fs.readFileSync(target, 'utf8').trim())) throw new Error('invalid_token_file');
  return target;
}

/** Закрывает только принадлежащий launcher child; ожидание имеет deadline и не перечисляет чужие процессы. */
export async function stopChild(child) {
  if (!child?.pid || child.exitCode !== null || child.signalCode !== null) return;
  const exited = new Promise((resolve) => child.once('exit', resolve));
  child.kill('SIGTERM');
  const timer = setTimeout(() => child.kill('SIGKILL'), 5000);
  try { await exited; } finally { clearTimeout(timer); }
}

/** Host обязан открыть listener до старта DM; exit любого процесса завершает пару без автоматического replay. */
export async function supervisePair({ hostCommand, worldCommand, cwd, env, onWorldStarted = () => {},
  worldOutput = null, hostOutput = null, onProcessExit = () => {}, worldTimeoutMs = 0 }) {
  let host;
  let world;
  let worldDeadline;
  let interrupted = false;
  const terminate = () => { interrupted = true; void stopChild(world); void stopChild(host); };
  // Juke синхронно вызывает process.exit в собственном signal trap; exit-hook успевает остановить оба owned PID.
  const terminateAtExit = () => { if (world?.pid) world.kill('SIGTERM'); if (host?.pid) host.kill('SIGTERM'); };
  process.once('SIGINT', terminate);
  process.once('SIGTERM', terminate);
  process.once('exit', terminateAtExit);
  try {
    host = spawn(hostCommand[0], hostCommand.slice(1), { cwd, env, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] });
    const hostExit = new Promise((resolve) => host.once('exit', (code, signal) => {
      onProcessExit({ process: 'host', code, signal });
      resolve({ process: 'host', code });
    }));
    await new Promise((resolve, reject) => {
      let tail = '';
      const timer = setTimeout(() => reject(new Error('host_start_timeout')), 10000);
      const finish = (error) => { clearTimeout(timer); error ? reject(error) : resolve(); };
      host.once('error', () => finish(new Error('host_start_failed')));
      host.once('exit', () => finish(new Error('host_exited_before_world')));
      const read = (chunk) => {
        hostOutput?.(chunk);
        tail = (tail + chunk.toString()).slice(-65536);
        if (tail.includes('NETRUN Host listening on loopback:')) finish();
      };
      host.stdout.on('data', read);
      host.stderr.on('data', read);
    });
    if (interrupted) return 130;
    world = spawn(worldCommand[0], worldCommand.slice(1), { cwd, env, windowsHide: true, stdio: worldOutput ? ['ignore', 'pipe', 'pipe'] : 'inherit' });
    if (worldOutput) {
      world.stdout.on('data', worldOutput);
      world.stderr.on('data', worldOutput);
    }
    if (worldTimeoutMs > 0) worldDeadline = setTimeout(() => { void stopChild(world); }, worldTimeoutMs);
    const worldExit = new Promise((resolve, reject) => {
      world.once('exit', (code, signal) => {
        onProcessExit({ process: 'world', code, signal });
        resolve({ process: 'world', code });
      });
      world.once('error', () => reject(new Error('world_start_failed')));
    });
    onWorldStarted(world);
    const first = await Promise.race([hostExit, worldExit]);
    return interrupted ? 130 : first.process === 'world' ? first.code ?? 1 : 1;
  } finally {
    clearTimeout(worldDeadline);
    await Promise.all([stopChild(world), stopChild(host)]);
    process.removeListener('SIGINT', terminate);
    process.removeListener('SIGTERM', terminate);
    process.removeListener('exit', terminateAtExit);
  }
}

/** Default local launch явно external; diagnostic dm запускается без Host и без token. */
export async function runManaged({ root = stationRoot, source = resolveCoreSource(root), daemon = 'dd.exe',
  dmb = path.join(root, 'tgstation.dmb'), port = '1337', noBuild = false, mode = process.env.NETRUN_CORE_MODE || 'external' } = {}) {
  if (!['external', 'shadow', 'dm'].includes(mode)) throw new Error('invalid_mode');
  if (!/^\d+$/.test(`${port}`) || Number(port) < 1 || Number(port) > 65535) throw new Error('invalid_game_port');
  if (mode === 'dm') { await runCommand(daemon, [dmb, '-port', `${port}`, '-trusted'], { cwd: root, env: { ...process.env, NETRUN_CORE_MODE: 'dm' } }); return 0; }
  if (!noBuild) await buildCore({ root, source });
  const built = verifyCoreBuild({ root, source });
  const token = ensureTokenFile({ root });
  const corePort = process.env.NETRUN_CORE_PORT || '18462';
  if (!/^[1-9]\d{0,4}$/.test(corePort) || Number(corePort) > 65535) throw new Error('invalid_core_port');
  const env = { ...process.env, NETRUN_CORE_MODE: mode, NETRUN_CORE_PORT: corePort,
    NETRUN_CORE_LIBRARY: path.join(built.directory, 'netrun_bridge.dll'), NETRUN_CORE_TOKEN_FILE: token, NETRUN_SESSION_TOKEN_FILE: token };
  delete env.NETRUN_SESSION_TOKEN;
  return supervisePair({ cwd: root, env, hostCommand: [dotnetPath(), path.join(built.directory, 'host/Netrun.Host.dll'), 'serve', corePort],
    worldCommand: [daemon, dmb, '-port', `${port}`, '-trusted', '-close', '-invisible'] });
}

/** CLI нужен для standalone build/run и подготовки content-pinned Docker context. */
async function main(args) {
  const [command, ...rest] = args;
  if (rest.some((arg) => command !== 'run' || arg !== '--no-build')) throw new Error('invalid_lifecycle_arguments');
  if (command === 'build') { await buildCore(); return; }
  if (command === 'prepare-context') { console.log(JSON.stringify(prepareCoreContext())); return; }
  if (command === 'run') {
    const { getDreamDaemonPath } = await import('../build/lib/byond.js');
    const code = await runManaged({ daemon: await getDreamDaemonPath(), noBuild: rest.includes('--no-build') });
    process.exitCode = code;
    return;
  }
  throw new Error('Usage: core-lifecycle.mjs build | prepare-context | run [--no-build]');
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  // byond.js подключает Juke/readline; standalone CLI завершает процесс после awaited cleanup, как штатный Juke setup.
  main(process.argv.slice(2)).then(() => process.exit(process.exitCode || 0))
    .catch((error) => { console.error(`NETRUN: ${error.message}`); process.exit(1); });
}

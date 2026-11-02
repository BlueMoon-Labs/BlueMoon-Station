#!/usr/bin/env node
/** Docker lifecycle использует content-pinned local Core context и останавливает всю принадлежащую ему пару. */
import fs from 'node:fs';
import path from 'node:path';
import { spawn, spawnSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import { stationRoot, prepareCoreContext, resolveCoreSource, snapshotCoreSource, ensureTokenFile, runCommand } from './core-lifecycle.mjs';

/** Обе цели собираются из одного manifest; source revision/digest не подменяется remote latest. */
export function dockerBuildArguments({ root, context, target, image }) {
  return ['buildx', 'build', '--load', '--platform', 'linux/amd64', '--file', path.join(root, 'Dockerfile'),
    '--build-context', `netrun_core=${context.directory}`, '--build-arg', `NETRUN_CORE_DIGEST=${context.digest}`,
    '--target', target, '--tag', image, root];
}

/** Проверяет Compose identifiers и ACL-compatible non-root Host identity, не читая config content. */
export function composeEnvironment({ root = stationRoot, images, token, environment = process.env } = {}) {
  const config = path.resolve(environment.NETRUN_CONFIG_DIRECTORY || path.join(root, 'config'));
  if (!fs.statSync(config).isDirectory()) throw new Error('station_config_directory_required');
  const uid = environment.NETRUN_HOST_UID || `${process.getuid?.() || 1654}`;
  const gid = environment.NETRUN_HOST_GID || `${process.getgid?.() ?? 1654}`;
  if (!/^[1-9]\d*$/.test(uid) || !/^\d+$/.test(gid)) throw new Error('non_root_host_identity_required');
  const project = environment.NETRUN_COMPOSE_PROJECT || 'molot-netrun';
  if (!/^[a-z0-9][a-z0-9_-]*$/.test(project)) throw new Error('invalid_compose_project');
  const result = { ...environment, NETRUN_CONFIG_DIRECTORY: config, NETRUN_HOST_UID: uid, NETRUN_HOST_GID: gid,
    NETRUN_CORE_TOKEN_FILE: token, NETRUN_STATION_IMAGE: images.station, NETRUN_HOST_IMAGE: images.host,
    NETRUN_COMPOSE_PROJECT: project };
  delete result.NETRUN_SESSION_TOKEN;
  return result;
}

/** Compose управляет только явно названным project; наружу опубликован единственный игровой port. */
export function composeArguments(root, environment, command) {
  return ['compose', '--project-name', environment.NETRUN_COMPOSE_PROJECT, '--file', path.join(root, 'tools/netrun/compose.yml'), ...command];
}

/** Завершение attached compose или launcher signal всегда сопровождается down без удаления game data volume. */
async function attachedCompose(root, environment) {
  let child;
  let interrupted = false;
  const stop = () => { interrupted = true; child?.kill('SIGTERM'); };
  process.once('SIGINT', stop);
  process.once('SIGTERM', stop);
  try {
    return await new Promise((resolve, reject) => {
      child = spawn('docker', composeArguments(root, environment, ['up', '--abort-on-container-exit', '--exit-code-from', 'byond']),
        { cwd: root, env: environment, windowsHide: true, stdio: 'inherit' });
      child.once('error', () => reject(new Error('docker_compose_start_failed')));
      child.once('exit', (code) => resolve(interrupted ? 130 : code ?? 1));
    });
  } finally {
    process.removeListener('SIGINT', stop);
    process.removeListener('SIGTERM', stop);
    await runCommand('docker', composeArguments(root, environment, ['down', '--timeout', '10']), { cwd: root, env: environment });
  }
}

/** Runtime проверяет labels обоих уже собранных images; --no-build не разрешает устаревшую пару. */
function verifyImages(manifest, source) {
  if (snapshotCoreSource(source).digest !== manifest.digest) throw new Error('docker_core_rebuild_required');
  for (const image of Object.values(manifest.images)) {
    const result = spawnSync('docker', ['image', 'inspect', '--format', '{{ index .Config.Labels "org.molot.netrun.source-digest" }}', image],
      { encoding: 'utf8', windowsHide: true });
    if (result.status !== 0 || result.stdout.trim() !== manifest.digest) throw new Error('docker_core_image_digest');
  }
}

/** Build/launch не устанавливает Docker и не изменяет существующие server/watchdog настройки. */
export async function dockerLifecycle(command, { root = stationRoot, source = resolveCoreSource(root), noBuild = false } = {}) {
  const pointer = path.join(root, 'data/netrun-core/docker-build.json');
  let manifest;
  if (command === 'build' || (command === 'up' && !noBuild)) {
    const context = prepareCoreContext({ root, source });
    const images = { station: `molot-netrun:station-${context.digest.slice(0, 12)}`, host: `molot-netrun:host-${context.digest.slice(0, 12)}` };
    await runCommand('docker', dockerBuildArguments({ root, context, target: 'netrun-station', image: images.station }), { cwd: root });
    await runCommand('docker', dockerBuildArguments({ root, context, target: 'netrun-host', image: images.host }), { cwd: root });
    if (snapshotCoreSource(source).digest !== context.digest) throw new Error('core_source_changed_during_build');
    manifest = { digest: context.digest, revision: context.revision, images };
    fs.writeFileSync(pointer, JSON.stringify(manifest, null, 2));
    if (command === 'build') return 0;
  } else {
    manifest = JSON.parse(fs.readFileSync(pointer, 'utf8'));
  }
  if (command !== 'down') verifyImages(manifest, source);
  const token = ensureTokenFile({ root });
  const environment = composeEnvironment({ root, images: manifest.images, token });
  delete environment.NETRUN_SESSION_TOKEN;
  if (command === 'up') return attachedCompose(root, environment);
  if (command === 'down' || command === 'config') {
    await runCommand('docker', composeArguments(root, environment, command === 'config' ? ['config', '--quiet'] : ['down', '--timeout', '10']), { cwd: root, env: environment });
    return 0;
  }
  throw new Error('invalid_docker_lifecycle_command');
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  const [command, ...args] = process.argv.slice(2);
  if (!['build', 'up', 'down', 'config'].includes(command) || args.some((arg) => arg !== '--no-build')) {
    console.error('Usage: docker-lifecycle.mjs build | up [--no-build] | down | config');
    process.exitCode = 2;
  } else {
    dockerLifecycle(command, { noBuild: args.includes('--no-build') }).then((code) => { process.exitCode = code; })
      .catch((error) => { console.error(`NETRUN Docker: ${error.message}`); process.exitCode = 1; });
  }
}

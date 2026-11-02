#!/usr/bin/env node
/** Docker lifecycle использует content-pinned local Core context и останавливает всю принадлежащую ему пару. */
import fs from 'node:fs';
import path from 'node:path';
import { spawn, spawnSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import { stationRoot, prepareCoreContext, ensureCoreSource, resolveCoreSource, snapshotCoreSource, ensureTokenFile, runCommand } from './core-lifecycle.mjs';
import { resolveDocker, preflightDocker } from './docker-tools.mjs';

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
  const port = environment.NETRUN_GAME_PORT || '1337';
  if (!/^[1-9]\d*$/.test(port) || Number(port) > 65535) throw new Error('invalid_game_port');
  const address = environment.NETRUN_GAME_ADDRESS || '127.0.0.1';
  if (!/^(?:\d{1,3}\.){3}\d{1,3}$/.test(address) || address.split('.').some((part) => Number(part) > 255)) throw new Error('invalid_game_address');
  const result = { ...environment, NETRUN_CONFIG_DIRECTORY: config, NETRUN_HOST_UID: uid, NETRUN_HOST_GID: gid,
    NETRUN_CORE_TOKEN_FILE: token, NETRUN_STATION_IMAGE: images.station, NETRUN_HOST_IMAGE: images.host,
    NETRUN_COMPOSE_PROJECT: project, NETRUN_GAME_PORT: port, NETRUN_GAME_ADDRESS: address };
  delete result.NETRUN_SESSION_TOKEN;
  return result;
}

/** Compose управляет только явно названным project; наружу опубликован единственный игровой port. */
export function composeArguments(root, environment, command) {
  return ['compose', '--project-name', environment.NETRUN_COMPOSE_PROJECT, '--file', path.join(root, 'tools/netrun/compose.yml'), ...command];
}

/** Завершение attached compose или launcher signal всегда сопровождается down без удаления game data volume. */
async function attachedCompose(docker, root, environment) {
  let child;
  let interrupted = false;
  const stop = () => { interrupted = true; child?.kill('SIGTERM'); };
  process.once('SIGINT', stop);
  process.once('SIGTERM', stop);
  try {
    return await new Promise((resolve, reject) => {
      child = spawn(docker, composeArguments(root, environment, ['up', '--abort-on-container-exit', '--exit-code-from', 'byond']),
        { cwd: root, env: environment, windowsHide: true, stdio: 'inherit' });
      child.once('error', () => reject(new Error('docker_compose_start_failed')));
      child.once('exit', (code) => resolve(interrupted ? 130 : code ?? 1));
    });
  } finally {
    process.removeListener('SIGINT', stop);
    process.removeListener('SIGTERM', stop);
    await runCommand(docker, composeArguments(root, environment, ['down', '--timeout', '10']), { cwd: root, env: environment });
  }
}

/** Runtime проверяет labels обоих уже собранных images; --no-build не разрешает устаревшую пару. */
function verifyImages(docker, manifest, execute = spawnSync) {
  for (const image of Object.values(manifest.images)) {
    const result = execute(docker, ['image', 'inspect', '--format', '{{ index .Config.Labels "org.molot.netrun.source-digest" }}', image],
      { encoding: 'utf8', windowsHide: true, timeout: 20000 });
    if (result.error || result.status !== 0 || result.stdout.trim() !== manifest.digest) throw new Error('docker_core_image_digest');
  }
}

/** Запоминает immutable IDs: новая сборка с тем же Core digest не меняет уже развёрнутую пару. */
function resolveImages(docker, tags, execute = spawnSync) {
  return Object.fromEntries(Object.entries(tags).map(([service, tag]) => {
    const result = execute(docker, ['image', 'inspect', '--format', '{{.Id}}', tag],
      { encoding: 'utf8', windowsHide: true, timeout: 20000 });
    const id = result.stdout?.trim();
    if (result.error || result.status !== 0 || !/^sha256:[a-f0-9]{64}$/.test(id)) throw new Error('docker_image_identity_unavailable');
    return [service, id];
  }));
}

/** Единственный pointer публикуется после завершения записи; secrets здесь отсутствуют. */
function writeState(filename, value) {
  fs.mkdirSync(path.dirname(filename), { recursive: true });
  const temporary = `${filename}.${process.pid}.tmp`;
  try {
    fs.writeFileSync(temporary, JSON.stringify(value, null, 2));
    fs.renameSync(temporary, filename);
  } finally { fs.rmSync(temporary, { force: true }); }
}

/** Сохраняет только параметры пары, чтобы stop/logs не зависели от текущего shell и наличия Core checkout. */
function deploymentState(manifest, environment) {
  const keys = ['NETRUN_CONFIG_DIRECTORY', 'NETRUN_HOST_UID', 'NETRUN_HOST_GID', 'NETRUN_CORE_TOKEN_FILE',
    'NETRUN_STATION_IMAGE', 'NETRUN_HOST_IMAGE', 'NETRUN_COMPOSE_PROJECT', 'NETRUN_GAME_PORT', 'NETRUN_GAME_ADDRESS'];
  return { version: 1, manifest, environment: Object.fromEntries(keys.map((key) => [key, environment[key]])) };
}

/** Восстанавливает параметры без stat config/token: inspection и down должны работать и после удаления исходников. */
function restoreDeployment(filename, environment) {
  if (!fs.existsSync(filename)) throw new Error('docker_deployment_missing: run deploy or up first');
  const state = JSON.parse(fs.readFileSync(filename, 'utf8'));
  if (state.version !== 1 || !/^[a-z0-9][a-z0-9_-]*$/.test(state.environment?.NETRUN_COMPOSE_PROJECT)
    || !/^[a-f0-9]{64}$/.test(state.manifest?.digest)) throw new Error('invalid_docker_deployment_state');
  const restored = { ...environment, ...state.environment };
  delete restored.NETRUN_SESSION_TOKEN;
  return { manifest: state.manifest, environment: restored };
}

/** Build/launch не устанавливает Docker; dependencies позволяют проверять границу CLI без реальных контейнеров. */
export async function dockerLifecycle(command, { root = stationRoot, source = resolveCoreSource(root), noBuild = false,
  environment: callerEnvironment = process.env, dependencies = {} } = {}) {
  if (!['build', 'up', 'deploy', 'restart', 'down', 'stop', 'status', 'logs', 'config'].includes(command)) throw new Error('invalid_docker_lifecycle_command');
  const services = { resolveDocker, preflightDocker, ensureCoreSource, prepareCoreContext, snapshotCoreSource, ensureTokenFile,
    runCommand, verifyImages, resolveImages, attachedCompose, ...dependencies };
  const docker = services.resolveDocker({ environment: callerEnvironment });
  const launch = command === 'up' || command === 'deploy';
  const build = command === 'build' || (launch && !noBuild);
  services.preflightDocker(docker, { environment: callerEnvironment, build });
  const pointer = path.join(root, 'data/netrun-core/docker-build.json');
  const deployment = path.join(root, 'data/netrun-core/docker-deployment.json');
  let manifest;
  let environment;
  if (command === 'build' || launch) source = await services.ensureCoreSource({ root, source });
  if (build) {
    const context = services.prepareCoreContext({ root, source });
    const tags = { station: `molot-netrun:station-${context.digest.slice(0, 12)}`, host: `molot-netrun:host-${context.digest.slice(0, 12)}` };
    await services.runCommand(docker, dockerBuildArguments({ root, context, target: 'netrun-station', image: tags.station }), { cwd: root, env: callerEnvironment });
    await services.runCommand(docker, dockerBuildArguments({ root, context, target: 'netrun-host', image: tags.host }), { cwd: root, env: callerEnvironment });
    if (services.snapshotCoreSource(source).digest !== context.digest) throw new Error('core_source_changed_during_build');
    manifest = { digest: context.digest, revision: context.revision, tags, images: services.resolveImages(docker, tags) };
    writeState(pointer, manifest);
    if (command === 'build') return 0;
  } else if (launch) {
    manifest = JSON.parse(fs.readFileSync(pointer, 'utf8'));
  }
  if (launch) {
    if (services.snapshotCoreSource(source).digest !== manifest.digest) throw new Error('docker_core_rebuild_required');
    services.verifyImages(docker, manifest);
    const token = services.ensureTokenFile({ root, filename: callerEnvironment.NETRUN_CORE_TOKEN_FILE });
    environment = composeEnvironment({ root, images: manifest.images, token, environment: callerEnvironment });
    // Не заменяем параметры ещё работающего project молча: сначала нужно остановить существующую пару.
    if (fs.existsSync(deployment)) {
      const previous = restoreDeployment(deployment, callerEnvironment);
      if (previous.environment.NETRUN_COMPOSE_PROJECT !== environment.NETRUN_COMPOSE_PROJECT) throw new Error('docker_project_changed: use a separate station checkout for another project');
    }
    writeState(deployment, deploymentState(manifest, environment));
  } else {
    ({ manifest, environment } = restoreDeployment(deployment, callerEnvironment));
  }
  if (command === 'up') return services.attachedCompose(docker, root, environment);
  const runCompose = (args) => services.runCommand(docker, composeArguments(root, environment, args), { cwd: root, env: environment });
  if (command === 'restart') {
    services.verifyImages(docker, manifest);
    // Host делит network namespace с BYOND: пересоздаём оба контейнера вместе, сохраняя config/token/data.
    await runCompose(['down', '--timeout', '10']);
  }
  const args = command === 'deploy' || command === 'restart' ? ['up', '--detach', '--force-recreate', '--wait', '--wait-timeout', '300'] :
    command === 'down' ? ['down', '--timeout', '10'] : command === 'stop' ? ['stop', '--timeout', '10'] :
      command === 'status' ? ['ps', '--all'] : command === 'logs' ? ['logs', '--tail', '200', '--no-color'] : ['config', '--quiet'];
  await runCompose(args);
  return 0;
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  const [command, ...args] = process.argv.slice(2);
  if (!['build', 'up', 'deploy', 'restart', 'down', 'stop', 'status', 'logs', 'config'].includes(command)
    || args.some((arg) => arg !== '--no-build') || (args.length && !['up', 'deploy'].includes(command))) {
    console.error('Usage: docker-lifecycle.mjs build | up [--no-build] | deploy [--no-build] | restart | down | stop | status | logs | config');
    process.exitCode = 2;
  } else {
    dockerLifecycle(command, { noBuild: args.includes('--no-build') }).then((code) => { process.exitCode = code; })
      .catch((error) => { console.error(`NETRUN Docker: ${error.message}`); process.exitCode = 1; });
  }
}

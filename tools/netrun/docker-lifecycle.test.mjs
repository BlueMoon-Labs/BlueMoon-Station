import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { dockerBuildArguments, composeEnvironment, composeArguments, dockerLifecycle } from './docker-lifecycle.mjs';

test('Docker builds both targets from an explicit local context and reviewed content digest', () => {
  const context = { directory: '/reviewed checkout/context', digest: 'a'.repeat(64) };
  const arguments_ = dockerBuildArguments({ root: '/station', context, target: 'netrun-station', image: 'local:reviewed' });
  assert.equal(arguments_[arguments_.indexOf('--build-context') + 1], 'netrun_core=/reviewed checkout/context');
  assert.equal(arguments_[arguments_.indexOf('--build-arg') + 1], `NETRUN_CORE_DIGEST=${context.digest}`);
  assert.equal(arguments_[arguments_.indexOf('--target') + 1], 'netrun-station');
  assert.equal(arguments_.includes('https://github.com'), false);
});

test('Compose uses only the owned project, file secret, non-root Host and caller-selected station config', (t) => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'netrun-compose-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  fs.mkdirSync(path.join(root, 'config'));
  const options = { root, images: { station: 'local:station', host: 'local:host' }, token: '/private/token',
    environment: { NETRUN_HOST_UID: '1000', NETRUN_HOST_GID: '1000', NETRUN_COMPOSE_PROJECT: 'reviewed-dev', NETRUN_SESSION_TOKEN: 'do-not-forward' } };
  const environment = composeEnvironment(options);
  assert.equal(environment.NETRUN_SESSION_TOKEN, undefined);
  assert.equal(environment.NETRUN_CORE_TOKEN_FILE, '/private/token');
  assert.equal(environment.NETRUN_CONFIG_DIRECTORY, path.join(root, 'config'));
  assert.equal(environment.NETRUN_GAME_ADDRESS, '127.0.0.1');
  assert.equal(environment.NETRUN_GAME_PORT, '1337');
  assert.deepEqual(composeArguments(root, environment, ['down', '--timeout', '10']),
    ['compose', '--project-name', 'reviewed-dev', '--file', path.join(root, 'tools/netrun/compose.yml'), 'down', '--timeout', '10']);
  assert.throws(() => composeEnvironment({ ...options, environment: { NETRUN_HOST_UID: '0' } }), /non_root_host_identity_required/);
  assert.throws(() => composeEnvironment({ ...options, environment: { NETRUN_COMPOSE_PROJECT: '--other-stack' } }), /invalid_compose_project/);
  assert.throws(() => composeEnvironment({ ...options, environment: { NETRUN_GAME_PORT: '65536' } }), /invalid_game_port/);
});

/** Подменяется только граница Docker CLI/загрузки Core; state и token/config обрабатывает настоящий lifecycle. */
function deploymentFixture(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'netrun-deployment-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  fs.mkdirSync(path.join(root, 'config'));
  const digest = 'a'.repeat(64);
  const manifest = { digest, images: { station: 'local:station', host: 'local:host' } };
  fs.mkdirSync(path.join(root, 'data/netrun-core'), { recursive: true });
  fs.writeFileSync(path.join(root, 'data/netrun-core/docker-build.json'), JSON.stringify(manifest));
  const token = path.join(root, 'data/netrun-core/private-token');
  fs.writeFileSync(token, 'fixture-token-must-never-be-in-state');
  const calls = [];
  let bootstraps = 0;
  let tokens = 0;
  const dependencies = {
    resolveDocker: () => '/resolved/docker', preflightDocker: () => {},
    ensureCoreSource: async ({ source }) => { bootstraps++; return source; },
    snapshotCoreSource: () => ({ digest }), verifyImages: () => {},
    resolveImages: () => ({ station: `sha256:${'1'.repeat(64)}`, host: `sha256:${'2'.repeat(64)}` }),
    ensureTokenFile: () => { tokens++; return token; },
    runCommand: async (command, args, options) => { calls.push({ command, args, options }); },
  };
  return { root, token, calls, dependencies, counts: () => ({ bootstraps, tokens }) };
}

test('detached deploy persists config and token paths, while inspection/stop do not bootstrap or change them', async (t) => {
  const fixture = deploymentFixture(t);
  const { root, token, calls, dependencies } = fixture;
  const environment = { NETRUN_COMPOSE_PROJECT: 'fixture', NETRUN_HOST_UID: '1000', NETRUN_HOST_GID: '1000', NETRUN_SESSION_TOKEN: 'secret-from-shell' };
  await dockerLifecycle('deploy', { root, noBuild: true, environment, dependencies });
  assert.deepEqual(fixture.counts(), { bootstraps: 1, tokens: 1 });
  const stateFile = path.join(root, 'data/netrun-core/docker-deployment.json');
  const state = fs.readFileSync(stateFile, 'utf8');
  assert.equal(state.includes('fixture-token-must-never-be-in-state'), false);
  assert.equal(state.includes('secret-from-shell'), false);
  assert.ok(calls[0].args.includes('--detach'));
  // Удалённый config и другой shell не должны мешать управлению уже созданной парой.
  fs.rmdirSync(path.join(root, 'config'));
  for (const command of ['status', 'logs', 'config', 'stop', 'down']) {
    await dockerLifecycle(command, { root, source: '/absent/core', environment: {
      NETRUN_CONFIG_DIRECTORY: '/changed/config', NETRUN_CORE_TOKEN_FILE: '/changed/token', NETRUN_COMPOSE_PROJECT: 'wrong-project', NETRUN_SESSION_TOKEN: 'changed-secret',
    }, dependencies });
    assert.equal(calls.at(-1).options.env.NETRUN_CONFIG_DIRECTORY, path.join(root, 'config'));
    assert.equal(calls.at(-1).options.env.NETRUN_CORE_TOKEN_FILE, token);
    assert.equal(calls.at(-1).options.env.NETRUN_COMPOSE_PROJECT, 'fixture');
    assert.equal(calls.at(-1).options.env.NETRUN_SESSION_TOKEN, undefined);
    assert.equal(calls.at(-1).args.includes('-v'), false);
  }
  assert.deepEqual(fixture.counts(), { bootstraps: 1, tokens: 1 });
  assert.equal(fs.readFileSync(stateFile, 'utf8'), state);
  assert.equal(fs.readFileSync(token, 'utf8'), 'fixture-token-must-never-be-in-state');
});

test('restart recreates both services together and preserves deployment state and game volume', async (t) => {
  const fixture = deploymentFixture(t);
  const { root, calls, dependencies } = fixture;
  await dockerLifecycle('deploy', { root, noBuild: true, environment: {}, dependencies });
  calls.length = 0;
  await dockerLifecycle('restart', { root, source: '/missing/core', environment: {}, dependencies });
  assert.equal(calls.length, 2);
  assert.deepEqual(calls[0].args.slice(-3), ['down', '--timeout', '10']);
  assert.ok(calls[1].args.includes('--force-recreate'));
  assert.equal(calls[1].args.includes('byond'), false); // Нет service filter: запускается вся пара.
  assert.equal(calls.some((call) => call.args.includes('--volumes') || call.args.includes('-v')), false);
  assert.deepEqual(fixture.counts(), { bootstraps: 1, tokens: 1 });
});

test('failed preflight never clones source, creates a token or starts a build', async (t) => {
  const fixture = deploymentFixture(t);
  await assert.rejects(dockerLifecycle('deploy', { root: fixture.root, dependencies: {
    ...fixture.dependencies, preflightDocker: () => { throw new Error('docker_linux_engine_required'); },
  } }), /docker_linux_engine_required/);
  assert.deepEqual(fixture.counts(), { bootstraps: 0, tokens: 0 });
  assert.equal(fixture.calls.length, 0);
});

test('cold deploy obtains missing Core before staging and publishes a matched image pair only after both builds', async (t) => {
  const fixture = deploymentFixture(t);
  const digest = 'b'.repeat(64);
  const order = [];
  const dependencies = { ...fixture.dependencies,
    ensureCoreSource: async () => { order.push('clone'); return '/downloaded/core'; },
    prepareCoreContext: ({ source }) => {
      assert.equal(source, '/downloaded/core'); order.push('stage'); return { digest, directory: '/staged/core', revision: 'reviewed' };
    },
    snapshotCoreSource: () => ({ digest }),
    runCommand: async (_command, args) => { order.push(args.includes('build') ? 'build' : 'launch'); },
  };
  await dockerLifecycle('deploy', { root: fixture.root, environment: {}, dependencies });
  assert.deepEqual(order, ['clone', 'stage', 'build', 'build', 'launch']);
  const manifest = JSON.parse(fs.readFileSync(path.join(fixture.root, 'data/netrun-core/docker-build.json'), 'utf8'));
  assert.equal(manifest.digest, digest);
  assert.equal(manifest.tags.host, `molot-netrun:host-${digest.slice(0, 12)}`);
  assert.equal(manifest.tags.station, `molot-netrun:station-${digest.slice(0, 12)}`);
  assert.match(manifest.images.station, /^sha256:/);
});

test('later build cannot replace immutable refs in an existing deployment and stop retains its containers', async (t) => {
  const fixture = deploymentFixture(t);
  const { root, calls, dependencies } = fixture;
  const digest = 'a'.repeat(64);
  const oldImages = { station: `sha256:${'1'.repeat(64)}`, host: `sha256:${'2'.repeat(64)}` };
  const context = { digest, directory: '/staged/core', revision: 'reviewed' };
  await dockerLifecycle('deploy', { root, environment: {}, dependencies: { ...dependencies, prepareCoreContext: () => context } });
  await dockerLifecycle('build', { root, environment: {}, dependencies: { ...dependencies, prepareCoreContext: () => context,
    resolveImages: () => ({ station: `sha256:${'3'.repeat(64)}`, host: `sha256:${'4'.repeat(64)}` }),
  } });
  await dockerLifecycle('restart', { root, environment: {}, dependencies });
  assert.equal(calls.at(-1).options.env.NETRUN_STATION_IMAGE, oldImages.station);
  assert.equal(calls.at(-1).options.env.NETRUN_HOST_IMAGE, oldImages.host);
  await dockerLifecycle('stop', { root, environment: {}, dependencies });
  assert.deepEqual(calls.at(-1).args.slice(-3), ['stop', '--timeout', '10']);
});

test('up keeps the attached lifecycle and propagates its exit status', async (t) => {
  const fixture = deploymentFixture(t);
  const code = await dockerLifecycle('up', { root: fixture.root, noBuild: true, environment: {}, dependencies: {
    ...fixture.dependencies, attachedCompose: async (docker, root, environment) => {
      assert.equal(docker, '/resolved/docker'); assert.equal(root, fixture.root);
      assert.equal(environment.NETRUN_CORE_TOKEN_FILE, fixture.token); return 130;
    },
  } });
  assert.equal(code, 130);
  assert.equal(fixture.calls.length, 0);
});

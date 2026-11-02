import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { dockerBuildArguments, composeEnvironment, composeArguments } from './docker-lifecycle.mjs';

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
  assert.deepEqual(composeArguments(root, environment, ['down', '--timeout', '10']),
    ['compose', '--project-name', 'reviewed-dev', '--file', path.join(root, 'tools/netrun/compose.yml'), 'down', '--timeout', '10']);
  assert.throws(() => composeEnvironment({ ...options, environment: { NETRUN_HOST_UID: '0' } }), /non_root_host_identity_required/);
  assert.throws(() => composeEnvironment({ ...options, environment: { NETRUN_COMPOSE_PROJECT: '--other-stack' } }), /invalid_compose_project/);
});

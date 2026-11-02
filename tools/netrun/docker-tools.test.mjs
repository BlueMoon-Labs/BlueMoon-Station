import assert from 'node:assert/strict';
import path from 'node:path';
import test from 'node:test';
import { resolveDocker, preflightDocker } from './docker-tools.mjs';

test('Docker Desktop installed per user works without restarting the inherited terminal PATH', () => {
  const executable = path.join('/user/local', 'Programs', 'DockerDesktop', 'resources', 'bin', 'docker.exe');
  const tried = [];
  assert.equal(resolveDocker({ environment: { LOCALAPPDATA: '/user/local' }, platform: 'win32',
    execute: (command) => { tried.push(command); return { status: command === executable ? 0 : null }; } }), executable);
  assert.deepEqual(tried, ['docker', executable]);
});

test('explicit Docker override is honored and a broken override fails without selecting another engine', () => {
  assert.equal(resolveDocker({ environment: { NETRUN_DOCKER: '/custom/docker' }, execute: () => ({ status: 0 }) }), '/custom/docker');
  const tried = [];
  assert.throws(() => resolveDocker({ environment: { NETRUN_DOCKER: '/missing' }, execute: (command) => {
    tried.push(command); return { status: null, error: new Error('missing') };
  } }), /invalid_NETRUN_DOCKER/);
  assert.deepEqual(tried, ['/missing']);
});

test('preflight rejects stopped or Windows engines before build and checks plugins only when required', () => {
  assert.throws(() => preflightDocker('docker', { execute: () => ({ status: 1 }) }), /docker_engine_unavailable/);
  assert.throws(() => preflightDocker('docker', { execute: () => ({ status: 0, stdout: '"windows"' }) }), /docker_linux_engine_required/);
  const called = [];
  const execute = (_command, args) => { called.push(args); return { status: 0, stdout: '"linux"' }; };
  preflightDocker('docker', { execute });
  assert.equal(called.length, 2);
  called.length = 0;
  preflightDocker('docker', { execute, build: true });
  assert.deepEqual(called.at(-1), ['buildx', 'version']);
  assert.throws(() => preflightDocker('docker', { build: true, execute: (_command, args) =>
    ({ status: args[0] === 'buildx' ? 1 : 0, stdout: '"linux"' }) }), /docker_buildx_required/);
});

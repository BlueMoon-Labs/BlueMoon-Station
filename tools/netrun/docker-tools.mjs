/** Находит Docker Desktop без зависимости от PATH запущенного до установки терминала. */
import path from 'node:path';
import { spawnSync } from 'node:child_process';

/** Явный NETRUN_DOCKER никогда не заменяется другим executable при ошибке. */
export function resolveDocker({ environment = process.env, platform = process.platform, execute = spawnSync } = {}) {
  const candidates = environment.NETRUN_DOCKER ? [environment.NETRUN_DOCKER] : ['docker'];
  if (!environment.NETRUN_DOCKER && platform === 'win32') {
    for (const directory of [environment.LOCALAPPDATA && path.join(environment.LOCALAPPDATA, 'Programs', 'DockerDesktop'),
      environment.ProgramFiles && path.join(environment.ProgramFiles, 'Docker', 'Docker'),
      environment['ProgramFiles(x86)'] && path.join(environment['ProgramFiles(x86)'], 'Docker', 'Docker')]) {
      if (directory) candidates.push(path.join(directory, 'resources', 'bin', 'docker.exe'));
    }
  }
  for (const candidate of candidates) {
    const result = execute(candidate, ['--version'], { encoding: 'utf8', windowsHide: true, env: environment, timeout: 10000 });
    if (!result.error && result.status === 0) return candidate;
  }
  throw new Error(environment.NETRUN_DOCKER ? 'invalid_NETRUN_DOCKER: executable is unavailable' :
    'docker_required: install Docker with Linux containers, or set NETRUN_DOCKER to its executable');
}

/** Проверяет Linux Engine и требуемые plugins до скачивания Core и долгой сборки. */
export function preflightDocker(docker, { environment = process.env, build = false, execute = spawnSync } = {}) {
  const options = { encoding: 'utf8', windowsHide: true, env: environment, timeout: 20000 };
  const info = execute(docker, ['info', '--format', '{{json .OSType}}'], options);
  if (info.error || info.status !== 0) throw new Error('docker_engine_unavailable: start Docker Desktop or the Docker Engine');
  if (info.stdout.trim() !== '"linux"') throw new Error('docker_linux_engine_required: switch Docker Desktop to Linux containers');
  for (const args of [['compose', 'version', '--short'], ...(build ? [['buildx', 'version']] : [])]) {
    const result = execute(docker, args, options);
    if (result.error || result.status !== 0) throw new Error(`docker_${args[0]}_required`);
  }
}

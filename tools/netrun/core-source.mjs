/** Получает отсутствующее публичное ядро; существующий checkout остаётся под управлением разработчика. */
import fs from 'node:fs';
import path from 'node:path';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const defaultRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');

/** Явный путь имеет приоритет над стандартным соседним репозиторием. */
export const resolveCoreSource = (root = defaultRoot, source = process.env.NETRUN_CORE_SOURCE) =>
  path.resolve(source || path.join(root, '..', 'netrun-core'));

/** Проверяет форму исходников до сборки, не требует чистого Git checkout. */
function validateSource(source) {
  for (const relative of ['global.json', 'src/Netrun.Host/Netrun.Host.csproj', 'native/netrun_bridge.cpp']) {
    if (!fs.statSync(path.join(source, relative)).isFile()) throw new Error('core_source_invalid');
  }
  return source;
}

/** Git запускается без shell и интерактивного запроса credentials; зависшая сеть имеет deadline. */
function git(args, cwd) {
  return new Promise((resolve, reject) => {
    const child = spawn('git', args, { cwd, windowsHide: true, stdio: ['ignore', 'inherit', 'inherit'],
      env: { ...process.env, GIT_TERMINAL_PROMPT: '0', GCM_INTERACTIVE: 'never' } });
    const timer = setTimeout(() => child.kill('SIGTERM'), 300000);
    const stopAtExit = () => { if (child.pid && child.exitCode === null) child.kill('SIGTERM'); };
    process.once('exit', stopAtExit);
    child.once('error', () => reject(new Error('git_required_for_core_download')));
    child.once('close', (code) => {
      clearTimeout(timer);
      process.removeListener('exit', stopAtExit);
      code === 0 ? resolve() : reject(new Error(`core_download_failed:${code}`));
    });
  });
}

/** Публикует только полностью полученный pinned checkout; ошибка или гонка не оставляет полурепозиторий. */
export async function ensureCoreSource({ root = defaultRoot, source = resolveCoreSource(root) } = {}) {
  source = path.resolve(source);
  if (fs.existsSync(source)) return validateSource(source);
  const pin = JSON.parse(fs.readFileSync(path.join(root, 'tools/netrun/core-source.json'), 'utf8'));
  if (typeof pin.repository !== 'string' || !pin.repository || /[\r\n\0]/.test(pin.repository)
    || (!pin.repository.startsWith('https://') && !path.isAbsolute(pin.repository))
    || !/^[a-f0-9]{40}$/.test(pin.revision)) throw new Error('invalid_core_source_pin');
  const parent = path.dirname(source);
  fs.mkdirSync(parent, { recursive: true });
  const temporary = fs.mkdtempSync(path.join(parent, '.netrun-core-download-'));
  try {
    console.log(`Downloading NETRUN Core revision ${pin.revision}...`);
    // --no-checkout не запускает код из репозитория; checkout получает конкретный проверенный commit.
    await git(['clone', '--no-checkout', '--', pin.repository, temporary], parent);
    await git(['-C', temporary, 'checkout', '--detach', pin.revision], parent);
    validateSource(temporary);
    try { fs.renameSync(temporary, source); }
    catch (error) {
      if (!fs.existsSync(source)) throw error;
      validateSource(source); // Другой launcher мог первым завершить тот же clone.
    }
    return validateSource(source);
  } finally {
    // Удаляем только созданный нами staging-каталог внутри явно выбранного parent.
    if (path.dirname(temporary) !== parent || !path.basename(temporary).startsWith('.netrun-core-download-')) throw new Error('invalid_core_download_staging');
    fs.rmSync(temporary, { recursive: true, force: true });
  }
}

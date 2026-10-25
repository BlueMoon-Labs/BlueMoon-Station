const crypto = require('node:crypto');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { execFileSync } = require('node:child_process');

const version = 'suite-1.11-P';
const sourceCommit = '0290db5c752fa292f9824521515b603a2afd11dc';
const patchCommit = '3332b864ffa49eef317ddae594879fecb7539f05';
const patchChecksum = '4ee52657e18d221129e5f22b770e8ff0e1c3437402bc98a830ab464324ae0c4c';
const checksums = {
  'dmm-tools-para': 'ee85def74b92c847a545ec8c9bfe3da777f63ed0611dba537930e279b4f429d2',
  'dmm-tools-para.exe': '27cd4f572898aae415f7fefb45ef0b739a570cfffd041d4327d5280fb47100eb',
};
const digest = buffer => crypto.createHash('sha256').update(buffer).digest('hex');

async function download(url, destination, checksum) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`Не удалось загрузить NanoMap: HTTP ${response.status}`);
  const data = Buffer.from(await response.arrayBuffer());
  if (digest(data) !== checksum) throw new Error('Контрольная сумма NanoMap не совпала.');
  fs.mkdirSync(path.dirname(destination), { recursive: true });
  fs.writeFileSync(destination, data, { mode: 0o755 });
}

// Проверка запуска важна: корректный по SHA-256 Linux-релиз может требовать более новую glibc.
async function selectCompatibleRenderer(release, { platform = process.platform, run = execFileSync, build }) {
  try {
    run(release, ['--version'], { stdio: 'pipe' });
    return release;
  } catch (error) {
    const details = `${error.message}\n${error.stderr || ''}`;
    if (platform !== 'linux' || !/GLIBC_[\d.]+.*not found/.test(details)) throw error;
    console.log('Готовый NanoMap несовместим с glibc хоста; собираем закреплённую версию из исходников.');
    const local = await build();
    run(local, ['--version'], { stdio: 'pipe' });
    return local;
  }
}

async function buildLocal(cache, executable) {
  const source = path.join(cache, 'source');
  fs.mkdirSync(source, { recursive: true });
  const patchFile = path.join(cache, 'paradise.patch');
  await download(
    `https://raw.githubusercontent.com/ParadiseSS13/SpacemanDMM-Para/${patchCommit}/SpacemanDMM-Para-patches/0001-Paradise-Nanomap-Changes.patch`,
    patchFile, patchChecksum,
  );
  const git = (...args) => execFileSync('git', ['-C', source, ...args], { stdio: 'inherit' });
  git('init', '-q');
  git('fetch', '--depth=1', 'https://github.com/SpaceManiac/SpacemanDMM.git', sourceCommit);
  git('checkout', '--detach', sourceCommit);
  // После неудачной Cargo-сборки патч уже может быть применён; повторно его не накладываем.
  let applied = false;
  try {
    execFileSync('git', ['-C', source, 'apply', '--reverse', '--check', patchFile], { stdio: 'pipe' });
    applied = true;
  } catch {}
  if (!applied) git('apply', patchFile);
  const userCargo = path.join(os.homedir(), '.cargo/bin/cargo');
  const cargo = process.env.CARGO || (fs.existsSync(userCargo) ? userCargo : 'cargo');
  // Убираем внешнюю настройку i686 из сборки rust-g: генератор нужен для архитектуры самого хоста.
  const env = { ...process.env };
  delete env.CARGO_BUILD_TARGET;
  delete env.CARGO_TARGET_DIR;
  if (path.isAbsolute(cargo)) env.PATH = `${path.dirname(cargo)}${path.delimiter}${env.PATH || ''}`;
  execFileSync(cargo, ['build', '--locked', '--release', '-p', 'dmm-tools-cli', '--bin', 'dmm-tools'], {
    cwd: source, env, stdio: 'inherit',
  });
  const local = path.join(cache, 'local', executable);
  fs.mkdirSync(path.dirname(local), { recursive: true });
  fs.copyFileSync(path.join(source, 'target/release/dmm-tools'), local);
  fs.chmodSync(local, 0o755);
  execFileSync(local, ['--version'], { stdio: 'pipe' });
  fs.writeFileSync(`${local}.json`, JSON.stringify({
    sourceCommit, patchChecksum, arch: process.arch, checksum: digest(fs.readFileSync(local)),
  }));
  return local;
}

async function ensureRenderer() {
  const root = path.resolve(__dirname, '../..');
  const cacheRoot = process.env.TG_BOOTSTRAP_CACHE
    ? path.resolve(process.env.TG_BOOTSTRAP_CACHE) : path.join(root, 'tools/bootstrap/.cache');
  const cache = path.join(cacheRoot, 'nanomaps', version);
  const executable = process.platform === 'win32' ? 'dmm-tools-para.exe' : 'dmm-tools-para';
  const local = path.join(cache, 'local', executable);
  if (process.platform === 'linux' && fs.existsSync(local) && fs.existsSync(`${local}.json`)) {
    const receipt = JSON.parse(fs.readFileSync(`${local}.json`, 'utf8'));
    if (receipt.sourceCommit === sourceCommit && receipt.patchChecksum === patchChecksum
      && receipt.arch === process.arch && receipt.checksum === digest(fs.readFileSync(local))) {
      try {
        execFileSync(local, ['--version'], { stdio: 'pipe' });
        return local;
      } catch {}
    }
  }
  const release = path.join(cache, executable);
  if (!fs.existsSync(release)) {
    console.log(`Загрузка рендерера NanoMap ${version}...`);
    await download(
      `https://github.com/ParadiseSS13/SpacemanDMM-Para/releases/download/${version}/${executable}`,
      release, checksums[executable],
    );
  }
  if (digest(fs.readFileSync(release)) !== checksums[executable]) {
    throw new Error('Контрольная сумма рендерера в кэше не совпала.');
  }
  return selectCompatibleRenderer(release, { build: () => buildLocal(cache, executable) });
}

module.exports = { ensureRenderer, selectCompatibleRenderer };

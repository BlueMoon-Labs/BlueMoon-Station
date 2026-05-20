const { spawn } = require('child_process');
const path = require('path');

const workspaceRoot = path.resolve(__dirname, '..');
const vitePackageJsonPath = require.resolve('vite/package.json');
const viteCliPath = path.join(path.dirname(vitePackageJsonPath), 'dist', 'node', 'cli.js');
const extraArgs = process.argv.slice(2);
const children = [];

process.env.DEV_SERVER_IP = process.env.DEV_SERVER_IP || '127.0.0.1';

const spawnWatcher = (configPath) => {
  const args = [
    viteCliPath,
    'build',
    '--mode',
    'development',
    '--watch',
    '--config',
    configPath,
    ...extraArgs,
  ];
  const child = spawn(process.execPath, args, {
    cwd: workspaceRoot,
    stdio: 'inherit',
    env: process.env,
  });
  children.push(child);
  child.on('exit', (code) => {
    if (code && code !== 0) {
      for (const proc of children) {
        if (proc.pid && !proc.killed) {
          proc.kill();
        }
      }
      process.exit(code);
    }
  });
};

spawnWatcher('vite.tgui.config.cjs');
spawnWatcher('vite.tgui-panel.config.cjs');

for (const signal of ['SIGINT', 'SIGTERM']) {
  process.on(signal, () => {
    for (const child of children) {
      if (child.pid && !child.killed) {
        child.kill(signal);
      }
    }
    process.exit(0);
  });
}

const {
  DEV_SERVER_PORT,
  createDevServer,
} = require('../packages/tgui-dev-server/server.cjs');
const { watchBundles } = require('../packages/tgui-dev-server/watcher.cjs');

const publicDir = path.join(workspaceRoot, 'public');
const devServer = createDevServer({ port: DEV_SERVER_PORT, publicDir });
devServer.listen().then(
  () => {
    console.log(`tgui dev-server: http+ws on http://127.0.0.1:${DEV_SERVER_PORT}`);
    watchBundles(publicDir, devServer.broadcast);
  },
  (err) => {
    console.error(`tgui dev-server failed to start on port ${DEV_SERVER_PORT}:`, err);
    for (const child of children) {
      if (child.pid && !child.killed) {
        child.kill();
      }
    }
    process.exit(1);
  },
);

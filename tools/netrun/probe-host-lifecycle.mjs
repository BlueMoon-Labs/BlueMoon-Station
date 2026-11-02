#!/usr/bin/env node
/** Проверяет настоящий Host с tiny TCP child вместо station world; listener обязан закрыться вместе с парой. */
import net from 'node:net';
import path from 'node:path';
import { stationRoot, verifyCoreBuild, ensureTokenFile, dotnetPath, supervisePair } from './core-lifecycle.mjs';

const listener = net.createServer();
await new Promise((resolve, reject) => { listener.once('error', reject); listener.listen(0, '127.0.0.1', resolve); });
const port = listener.address().port;
await new Promise((resolve) => listener.close(resolve));
const built = verifyCoreBuild();
const tokenFile = ensureTokenFile();
const environment = { ...process.env, NETRUN_SESSION_TOKEN_FILE: tokenFile, NETRUN_PROBE_PORT: `${port}` };
delete environment.NETRUN_SESSION_TOKEN;
const probe = `const c=require('node:net').connect({host:'127.0.0.1',port:Number(process.env.NETRUN_PROBE_PORT)});c.once('error',()=>process.exit(2));c.once('connect',()=>{c.destroy();process.exit(0)});setTimeout(()=>process.exit(3),5000).unref()`;
const code = await supervisePair({ cwd: stationRoot, env: environment,
  hostCommand: [await dotnetPath(), path.join(built.directory, 'host/Netrun.Host.dll'), 'serve', `${port}`],
  worldCommand: [process.execPath, '-e', probe] });
if (code) throw new Error('managed_host_probe_failed');
await new Promise((resolve, reject) => {
  const socket = net.connect({ host: '127.0.0.1', port });
  socket.once('error', resolve);
  socket.once('connect', () => { socket.destroy(); reject(new Error('managed_host_listener_leaked')); });
});
console.log('PASS: real published Host ready before TCP child; owned processes and listener closed after child exit');

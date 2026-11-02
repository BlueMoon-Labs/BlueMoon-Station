#!/usr/bin/env node
/** Installs portable NETRUN profiles while preserving the workspace's existing build/debug choices. */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { stationRoot } from './core-lifecycle.mjs';

const templates = path.dirname(fileURLToPath(import.meta.url));
const hostName = 'NETRUN Core Host';
const waitTask = 'NETRUN: wait for Host';
const stopTask = 'NETRUN: stop Host';

/** VS Code accepts comments and trailing commas; preserve their string contents while decoding. */
export function parseVscodeJson(source) {
  let result = '';
  let index = 0;
  while (index < source.length) {
    if (source[index] === '"') {
      const start = index++;
      while (index < source.length) {
        if (source[index] === '\\') index += 2;
        else if (source[index++] === '"') break;
      }
      result += source.slice(start, index);
    } else if (source.startsWith('//', index)) {
      while (index < source.length && source[index] !== '\n') index++;
    } else if (source.startsWith('/*', index)) {
      const end = source.indexOf('*/', index + 2);
      if (end < 0) throw new Error('unterminated_vscode_comment');
      index = end + 2;
    } else {
      result += source[index++];
    }
  }
  source = result;
  result = '';
  index = 0;
  while (index < source.length) {
    if (source[index] === '"') {
      const start = index++;
      while (index < source.length) {
        if (source[index] === '\\') index += 2;
        else if (source[index++] === '"') break;
      }
      result += source.slice(start, index);
    } else if (source[index] === ',' && /^[\s]*[}\]]/.test(source.slice(index + 1))) index++;
    else result += source[index++];
  }
  return JSON.parse(result.replace(/^\uFEFF/, ''));
}

/** An outer compound builds once; DM starts only after the matching live Host is ready. */
export function createVscodeConfiguration(launch, tasks) {
  launch = structuredClone(launch);
  tasks = structuredClone(tasks);
  launch.configurations = (launch.configurations || []).filter((entry) => entry.name !== hostName && !entry.name?.startsWith('NETRUN: '));
  const profiles = launch.configurations.filter((entry) => entry.type === 'byond' && entry.request === 'launch');
  if (!profiles.length) throw new Error('byond_launch_profile_required');
  launch.compounds = (launch.compounds || []).filter((entry) => !entry.name?.startsWith('NETRUN + '));
  launch.configurations.push({
    name: hostName, type: 'node', request: 'launch', program: '${workspaceFolder}/tools/netrun/debug-host.mjs', args: ['start'],
    cwd: '${workspaceFolder}', console: 'integratedTerminal', skipFiles: ['<node_internals>/**'], presentation: { hidden: true },
  });
  for (const profile of profiles) {
    const name = `NETRUN: ${profile.name}`;
    const debug = { ...profile, name, preLaunchTask: waitTask, presentation: { ...profile.presentation, hidden: true }, env: {
      ...profile.env, NETRUN_CORE_MODE: 'external', NETRUN_CORE_PORT: '18462',
      NETRUN_CORE_LIBRARY: '${workspaceFolder}/data/netrun-core/debug/netrun_bridge.dll',
      NETRUN_CORE_TOKEN_FILE: '${workspaceFolder}/data/netrun-core/session-token.txt',
    } };
    launch.configurations.push(debug);
    launch.compounds.push({ name: `NETRUN + ${profile.name.replace(/^Launch /, '')}`, configurations: [hostName, name],
      ...(profile.preLaunchTask ? { preLaunchTask: profile.preLaunchTask } : {}), stopAll: true });
  }
  tasks.tasks = (tasks.tasks || []).filter((entry) => ![waitTask, stopTask].includes(entry.label));
  for (const [label, command] of [[waitTask, 'wait-ready'], [stopTask, 'stop']]) {
    tasks.tasks.push({ label, type: 'process', command: 'node', args: ['${workspaceFolder}/tools/netrun/debug-host.mjs', command],
      options: { cwd: '${workspaceFolder}' }, problemMatcher: [] });
  }
  return { launch, tasks };
}

/** Templates install the same profiles on another PC while preserving its existing settings. */
export function installVscode({ root = stationRoot } = {}) {
  const directory = path.join(root, '.vscode');
  const read = (name) => {
    const destination = path.join(directory, `${name}.json`);
    const source = fs.existsSync(destination) ? destination : path.join(templates, `vscode-${name}.json`);
    return parseVscodeJson(fs.readFileSync(source, 'utf8'));
  };
  const result = createVscodeConfiguration(read('launch'), read('tasks'));
  fs.mkdirSync(directory, { recursive: true });
  for (const [name, content] of Object.entries(result)) {
    const destination = path.join(directory, `${name}.json`);
    if (fs.existsSync(destination)) {
      try { fs.copyFileSync(destination, `${destination}.netrun-backup`, fs.constants.COPYFILE_EXCL); }
      catch (error) { if (error.code !== 'EEXIST') throw error; }
    }
    fs.writeFileSync(destination, JSON.stringify(content, null, '\t') + '\n');
  }
  return result;
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  try { installVscode(); console.log('NETRUN VS Code profiles installed. Select NETRUN + DreamSeeker (or its build variant).'); }
  catch (error) { console.error(`NETRUN: ${error.message}`); process.exitCode = 1; }
}

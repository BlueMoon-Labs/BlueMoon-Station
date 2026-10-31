#!/usr/bin/env node
/** Focused Netrun suites; the normal build tool still owns DM compilation. */
import fs from 'node:fs';
import path from 'node:path';
import { spawn } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';

const repositoryRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');

// Preserve newlines so a path in a comment or multiline string is never a test.
function maskDmSource(source, maskStrings = false) {
  let output = '';
  let cursor = 0;
  while (cursor < source.length) {
    const char = source[cursor];
    if (source.startsWith('//', cursor)) {
      const end = source.indexOf('\n', cursor);
      const next = end < 0 ? source.length : end;
      output += source.slice(cursor, next).replace(/[^\r\n]/g, ' ');
      cursor = next;
    } else if (source.startsWith('/*', cursor)) {
      let depth = 1;
      const start = cursor;
      cursor += 2;
      while (cursor < source.length && depth) {
        if (source.startsWith('/*', cursor)) {
          depth++;
          cursor += 2;
        } else if (source.startsWith('*/', cursor)) {
          depth--;
          cursor += 2;
        } else {
          cursor++;
        }
      }
      output += source.slice(start, cursor).replace(/[^\r\n]/g, ' ');
    } else if (char === '"' || char === "'") {
      const start = cursor++;
      while (cursor < source.length) {
        if (source[cursor] === '\\') {
          cursor += 2;
        } else if (source[cursor++] === char) {
          break;
        }
      }
      const literal = source.slice(start, cursor);
      output += maskStrings ? literal.replace(/[^\r\n]/g, ' ') : literal;
    } else {
      output += char;
      cursor++;
    }
  }
  return output;
}

export function runProcess(executable, args, cwd, env = process.env) {
  return new Promise((resolve, reject) => {
    const child = spawn(executable, args, { cwd, env, stdio: 'inherit', shell: false });
    child.once('error', reject);
    child.once('close', (code, signal) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`${path.basename(executable)} failed (${signal || `exit ${code}`}).`));
      }
    });
  });
}

export class NetrunTestSuite {
  constructor(root = repositoryRoot, execute = runProcess) {
    this.root = path.resolve(root);
    this.execute = execute;
    this.selectionFile = path.join(this.root, 'tmp/netrun-tests.txt');
    this.lockFile = path.join(this.root, 'tmp/netrun-tests.lock');
    this.resultsFile = path.join(this.root, 'data/logs/ci-hermetic/unit_tests.json');
  }

  discoverDm(filter = '') {
    const directory = path.join(this.root, 'code/modules/unit_tests');
    const manifest = maskDmSource(fs.readFileSync(path.join(directory, '_unit_tests.dm'), 'utf8'));
    const files = [...manifest.matchAll(/^\s*#include\s+"(netrun[^"/\\]*\.dm)"/gm)]
      .map((match) => match[1]);
    const selected = new Set();
    for (const file of new Set(files)) {
      const source = maskDmSource(fs.readFileSync(path.join(directory, file), 'utf8'), true);
      for (const match of source.matchAll(/^\s*(\/datum\/unit_test\/netrun_[\w/]+)\/Run\s*\(/gm)) {
        if (match[1].toLowerCase().includes(filter.toLowerCase())) {
          selected.add(match[1]);
        }
      }
    }
    return this.requireSelection([...selected].sort(), filter);
  }

  discoverFrontend(filter = '') {
    const directory = path.join(this.root, 'tgui/packages/tgui/interfaces/NetrunTerminal');
    const files = [];
    const visit = (folder) => {
      for (const entry of fs.readdirSync(folder, { withFileTypes: true })) {
        const absolute = path.join(folder, entry.name);
        if (entry.isDirectory()) {
          visit(absolute);
        } else if (/\.(test|spec)\.[jt]sx?$/.test(entry.name)) {
          const relative = path.relative(path.join(this.root, 'tgui'), absolute).replace(/\\/g, '/');
          if (relative.toLowerCase().includes(filter.toLowerCase())) {
            files.push(relative);
          }
        }
      }
    };
    visit(directory);
    return this.requireSelection(files.sort(), filter);
  }

  requireSelection(selected, filter) {
    if (!selected.length) {
      throw new Error(`No Netrun tests matched${filter ? ` '${filter}'` : ''}; nothing was run.`);
    }
    return selected;
  }

  validateResults(results, selected) {
    this.requireSelection(selected, '');
    if (!results || Array.isArray(results) || typeof results !== 'object') {
      throw new Error('The fresh unit_tests.json is not a test result object.');
    }
    const failures = [];
    for (const name of selected) {
      if (!Object.hasOwn(results, name)) {
        failures.push(`${name}: missing result`);
      } else if (results[name]?.status !== 0) {
        failures.push(`${name}: ${results[name]?.status === 2 ? 'SKIPPED' : 'FAILED'}${results[name]?.message ? `\n${results[name].message}` : ''}`);
      }
    }
    if (failures.length) {
      throw new Error(`${failures.length}/${selected.length} selected tests did not pass:\n${failures.join('\n')}`);
    }
  }

  async runDm(selected, { map } = {}) {
    this.requireSelection(selected, '');
    const profile = map ? 'full-map' : 'hermetic';
    const resultsFile = map ? path.join(this.root, 'data/logs/ci-full-map/unit_tests.json') : this.resultsFile;
    fs.mkdirSync(path.dirname(this.selectionFile), { recursive: true });
    let lock;
    try {
      lock = fs.openSync(this.lockFile, 'wx');
    } catch (error) {
      if (error.code === 'EEXIST') {
        throw new Error('A Netrun test runner already owns tmp/netrun-tests.lock. If it was interrupted, stop its world before removing that lock.');
      }
      throw error;
    }
    try {
      fs.writeFileSync(lock, `${process.pid}\n`);
      fs.writeFileSync(this.selectionFile, `${selected.join('\n')}\n`);
      // A cached successful report must never make a failed/no-op run look green.
      fs.rmSync(resultsFile, { force: true });
      await this.execute(process.execPath, [
        path.join(this.root, 'tools/build/build.js'),
        'dm-test',
        `--unit-test-profile=${profile}`,
        '--test-list=tmp/netrun-tests.txt',
        ...(map ? [`--define=FORCE_MAP ${JSON.stringify(map)}`] : []),
      ], this.root);
      if (!fs.existsSync(resultsFile)) {
        throw new Error(`The test world did not write a fresh ${path.relative(this.root, resultsFile)}.`);
      }
      this.validateResults(JSON.parse(fs.readFileSync(resultsFile, 'utf8')), selected);
    } finally {
      fs.closeSync(lock);
      fs.rmSync(this.lockFile, { force: true });
    }
  }

  async runFrontend(selected) {
    this.requireSelection(selected, '');
    const directory = path.join(this.root, 'tgui');
    const config = fs.readFileSync(path.join(directory, '.yarnrc.yml'), 'utf8');
    const yarnPath = /^yarnPath:\s*["']?([^\r\n"']+)/m.exec(config)?.[1].trim();
    if (!yarnPath || !fs.existsSync(path.resolve(directory, yarnPath))) {
      throw new Error('The repository Yarn release is missing; restore tgui/.yarn/releases.');
    }
    if (!fs.existsSync(path.join(directory, '.pnp.cjs')) && !fs.existsSync(path.join(directory, 'node_modules/jest'))) {
      throw new Error('TGUI dependencies are missing. Run the repository Yarn install in tgui first (see tools/netrun/README.md).');
    }
    await this.execute(process.execPath, [
      path.resolve(directory, yarnPath), 'jest', '--ci', '--runInBand', '--runTestsByPath', ...selected,
    ], directory, { ...process.env, CI: 'true' });
  }
}

export async function main(args = process.argv.slice(2)) {
  let list = false;
  let frontend = false;
  let peaceMap = false;
  let filter = '';
  for (let index = 0; index < args.length; index++) {
    const arg = args[index];
    if (arg === '--help' || arg === '-h') {
      console.log('Usage: node tools/netrun/run-tests.mjs [--list] [--filter substring] [--frontend | --peace-map]\nDefault: compile and run every included Netrun DM test in the hermetic profile.\n--frontend selects NetrunTerminal Jest; --peace-map checks atmosphere startup on the real Peace Syndicate Station.\n--list only prints selected tests.');
      return;
    }
    if (arg === '--list') {
      list = true;
    } else if (arg === '--frontend') {
      frontend = true;
    } else if (arg === '--peace-map') {
      peaceMap = true;
    } else if (arg === '--filter') {
      if (!args[index + 1] || args[index + 1].startsWith('--')) {
        throw new Error('--filter requires a nonempty substring.');
      }
      filter = args[++index];
    } else if (arg.startsWith('--filter=')) {
      filter = arg.slice('--filter='.length);
      if (!filter) {
        throw new Error('--filter requires a nonempty substring.');
      }
    } else {
      throw new Error(`Unknown argument '${arg}'. Use --help.`);
    }
  }
  if (peaceMap && (frontend || filter)) {
    throw new Error('--peace-map selects its own full-map regression and cannot combine with --frontend or --filter.');
  }
  const suite = new NetrunTestSuite();
  const selected = peaceMap ? ['/datum/unit_test/atmos_netrun_roundstart_registration']
    : frontend ? suite.discoverFrontend(filter) : suite.discoverDm(filter);
  if (list) {
    console.log(selected.join('\n'));
    return;
  }
  console.log(`Running ${selected.length} Netrun ${frontend ? 'Jest files' : 'DM tests'}...`);
  await (frontend ? suite.runFrontend(selected) : suite.runDm(selected, peaceMap ? { map: '_maps/peacesyndicatestation.json' } : {}));
  console.log(`PASS: all ${selected.length} selected Netrun ${frontend ? 'Jest files' : 'DM tests'}.`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  main().catch((error) => {
    console.error(`Netrun tests: ${error.message}`);
    process.exitCode = 1;
  });
}

#!/usr/bin/env node
/**
 * Build script for /tg/station 13 codebase.
 *
 * This script uses Juke Build, read the docs here:
 * https://github.com/stylemistake/juke-build
 *
 * @file
 * @copyright 2021 Aleksej Komarov
 * @license MIT
 */

import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { spawn } from 'child_process';
import { DreamDaemon, DreamMaker, getDmPath, getDreamDaemonPath } from './lib/byond.js';
import { yarn } from './lib/yarn.js';
import { NanomapsTarget } from './lib/nanomaps.js';
import Juke from './juke/index.js';

export { NanomapsTarget };

Juke.chdir('../..', import.meta.url);
Juke.setup({ file: import.meta.url }).then((code) => process.exit(code));

const DME_NAME = 'tgstation';

export const DefineParameter = new Juke.Parameter({
  type: 'string[]',
  alias: 'D',
});

export const PortParameter = new Juke.Parameter({
  type: 'string',
  alias: 'p',
});

export const CiParameter = new Juke.Parameter({
  type: 'boolean',
});

export const UnitTestProfileParameter = new Juke.Parameter({
  type: 'string',
});

/** Number of DreamDaemon worlds that split one unit-test run. */
export const ShardsParameter = new Juke.Parameter({
  type: 'string',
});

/** File with unit-test type paths, one per line: runs them without TEST_FOCUS and a recompile. */
export const TestListParameter = new Juke.Parameter({
  type: 'string',
});

/** "J/M": this machine is part J of M that split one sharded run, its worlds take
 * shards (J-1)*S+1 .. J*S of S*M. */
export const ShardGroupParameter = new Juke.Parameter({
  type: 'string',
});

/** Comma-separated names of _maps/*.json: one world per map, all at once. */
export const MapsParameter = new Juke.Parameter({
  type: 'string',
});

/** Run the unit-test DMB that is already there instead of compiling it (CI test jobs). */
export const PrebuiltParameter = new Juke.Parameter({
  type: 'boolean',
});

/** Minutes after which a test world is killed as hung. */
export const WorldTimeoutParameter = new Juke.Parameter({
  type: 'string',
});

/** Run the failed tests of an unclean world once more: passing there marks them flaky. */
export const RetryFailedParameter = new Juke.Parameter({
  type: 'boolean',
});

/** Fail the compile on DreamMaker warnings, not only on errors. */
export const WarningsAsErrorsParameter = new Juke.Parameter({
  type: 'boolean',
});

// Run even when compiled assets are up to date: the Node installation may change.
// This code comes from the deployed repository, unlike TGS's installed EventScripts.
export const LoadoutCryptoRuntimeTarget = new Juke.Target({
  executes: async () => {
    const nodePath = process.execPath.replace(/\\/g, '/');
    fs.writeFileSync('tools/loadout_crypto/node_path.txt', `${nodePath}\n`);
    Juke.logger.info(`Loadout crypto Node: ${nodePath}`);
  },
});

export const DmMapsIncludeTarget = new Juke.Target({
  executes: async () => {
    const folders = [
      ...Juke.glob('_maps/RandomRuins/**/*.dmm'),
      ...Juke.glob('_maps/RandomZLevels/**/*.dmm'),
      // ...Juke.glob('_maps/shuttles/**/*.dmm'),
      ...Juke.glob('_maps/templates/**/*.dmm'),
    ];
    const content = folders
      .map((file) => file.replace('_maps/', ''))
      .map((file) => `#include "${file}"`)
      .join('\n') + '\n';
    fs.writeFileSync('_maps/templates.dm', content);
  },
});

const CENTCOM_MAP = '_maps/map_files/generic/CentCom.dmm';
const CENTCOM_HERMETIC_MAP = '_maps/map_files/generic/CentCom_hermetic.dmm';

/** CentCom for the hermetic unit-test profile: only z1. The other z-levels are
 * empty event space, about 4 seconds of init on every test world. */
export const CentComHermeticTarget = new Juke.Target({
  inputs: [CENTCOM_MAP],
  outputs: [CENTCOM_HERMETIC_MAP],
  executes: async () => {
    const map = fs.readFileSync(CENTCOM_MAP, 'utf-8');
    const firstBlock = map.search(/^\(\d+,\d+,\d+\) = \{"/m);
    const blocks = map.slice(firstBlock).split(/^(?=\(\d+,\d+,\d+\) = \{")/m);
    const kept = blocks.filter((block) => /^\(\d+,\d+,1\) = \{"/.test(block));
    if (firstBlock < 0 || kept.length === 0) {
      Juke.logger.error(`${CENTCOM_MAP} is not in TGM format, cannot cut z1 out of it.`);
      throw new Juke.ExitCode(1);
    }
    fs.writeFileSync(CENTCOM_HERMETIC_MAP, map.slice(0, firstBlock) + kept.join(''));
  },
});

export const StatbrowserTarget = new Juke.Target({
  inputs: [
    'html/statbrowser/build.js',
    'html/statbrowser/template.html',
    'html/statbrowser/src/**/*.js',
    'html/statbrowser/styles/**/*.css',
  ],
  outputs: [
    'html/statbrowser.html',
  ],
  executes: async () => {
    await Juke.exec('node', ['html/statbrowser/build.js']);
  },
});


export const DmTarget = new Juke.Target({
  dependsOn: ({ get }) => [
    LoadoutCryptoRuntimeTarget,
    StatbrowserTarget,
    NanomapsTarget,
    get(DefineParameter).includes('ALL_TEMPLATES') && DmMapsIncludeTarget,
  ],
  inputs: async () => [
    'dependencies.sh',
    await getDmPath(),
    '_maps/map_files/generic/**',
    'code/**',
    'goon/**',
    'html/**',
    'icons/**',
    'interface/**',
    'tgui/public/tgui.html',
    "modular_*/**", // BLUEMOON ADD
    `${DME_NAME}.dme`,
    'modular_citadel/**',
    'modular_sand/**',
  ],
  outputs: [
    `${DME_NAME}.dmb`,
    `${DME_NAME}.rsc`,
  ],
  parameters: [DefineParameter, WarningsAsErrorsParameter],
  executes: async ({ get }) => {
    const defines = get(DefineParameter);
    if (defines.length > 0) {
      Juke.logger.info('Using defines:', defines.join(', '));
    }
    await DreamMaker(`${DME_NAME}.dme`, {
      defines: ['CBT', ...defines],
      warningsAsErrors: get(WarningsAsErrorsParameter),
    });
  },
});

const UNIT_TEST_PROFILES = new Set(['all', 'hermetic', 'full-map']);

const getUnitTestProfile = (get) => {
  const profile = get(UnitTestProfileParameter) || 'all';
  if (!UNIT_TEST_PROFILES.has(profile)) {
    Juke.logger.error(`Unknown unit test profile '${profile}'. Expected all, hermetic, or full-map.`);
    throw new Juke.ExitCode(1);
  }
  return profile;
};

const getUnitTestDefines = (get) => {
  const profile = getUnitTestProfile(get);
  const profileDefines = [];
  if (profile === 'hermetic') {
    profileDefines.push('LOWMEMORYMODE', 'UNIT_TEST_PROFILE_HERMETIC');
  }
  else if (profile === 'full-map') {
    profileDefines.push('UNIT_TEST_PROFILE_FULL_MAP');
  }
  return [...new Set(['CBT', 'CIBUILDING', ...profileDefines, ...get(DefineParameter)])];
};

const getUnitTestArtifactBase = (get) => {
  const profile = getUnitTestProfile(get);
  const userDefines = get(DefineParameter);
  if (profile === 'all' && userDefines.length === 0) {
    return `${DME_NAME}.test`;
  }
  const signature = crypto
    .createHash('sha256')
    .update(JSON.stringify(getUnitTestDefines(get).slice().sort()))
    .digest('hex')
    .slice(0, 12);
  return `${DME_NAME}.test.${profile}.${signature}`;
};

const getUnitTestLogDirectory = (get) => {
  const profile = getUnitTestProfile(get);
  return profile === 'all' ? 'ci' : `ci-${profile}`;
};

const dmTestInputs = [
  'dependencies.sh',
  '_maps/map_files/generic/**',
  'code/**',
  'goon/**',
  'html/**',
  'icons/**',
  'interface/**',
  'tgui/public/tgui.html',
  'modular_*/**',
  `${DME_NAME}.dme`,
  'modular_citadel/**',
  'modular_sand/**',
  'tools/build/build.js',
  'tools/build/lib/byond.js',
];

/** Compile a reusable unit-test DMB. The artifact name includes the profile
 * and define set, while the compiler executable is an input so a BYOND update
 * invalidates the cached output. */
export const DmTestBuildTarget = new Juke.Target({
  parameters: [DefineParameter, UnitTestProfileParameter, WarningsAsErrorsParameter],
  dependsOn: ({ get }) => [
    StatbrowserTarget,
    NanomapsTarget,
    get(DefineParameter).includes('ALL_TEMPLATES') && DmMapsIncludeTarget,
    getUnitTestProfile(get) === 'hermetic' && CentComHermeticTarget,
  ],
  inputs: async () => [
    ...dmTestInputs,
    await getDmPath(),
  ],
  outputs: ({ get }) => {
    const artifactBase = getUnitTestArtifactBase(get);
    return [
      `${artifactBase}.dme`,
      `${artifactBase}.dmb`,
      `${artifactBase}.rsc`,
    ];
  },
  executes: async ({ get }) => {
    const artifactBase = getUnitTestArtifactBase(get);
    const defines = getUnitTestDefines(get);
    Juke.logger.info('Using unit test defines:', defines.join(', '));
    fs.copyFileSync(`${DME_NAME}.dme`, `${artifactBase}.dme`);
    await DreamMaker(`${artifactBase}.dme`, {
      defines,
      warningsAsErrors: get(WarningsAsErrorsParameter),
    });
  },
});

const UNIT_TEST_DURATIONS = 'data/unit_test_durations.json';
/** A world that printed "Shutdown complete" and is still alive after this long is hung. */
const SHARD_HANG_GRACE_MS = 30000;
const MERGED_SHARD_LOGS = ['tests.log', 'runtime.log', 'harddels.log'];
/** More failures than this in one world are a broken change, not a flaky test. */
const MAX_RETRIED_TESTS = 10;
/** Statuses in unit_tests.json, as in code/modules/unit_tests/_unit_tests.dm. */
const UNIT_TEST_PASSED = 0;
const UNIT_TEST_FAILED = 1;

const getShardCount = (get) => {
  const shards = Number(get(ShardsParameter) || 1);
  if (!Number.isInteger(shards) || shards < 1) {
    Juke.logger.error(`--shards expects a positive integer, got '${get(ShardsParameter)}'.`);
    throw new Juke.ExitCode(1);
  }
  return shards;
};

/** Worlds that run side by side, or null for the plain single world. Each is
 * { name, directory, params }: its file names, log directory and world params. */
const getTestWorlds = (get, logDirectory) => {
  const maps = (get(MapsParameter) || '').split(',').map((map) => map.trim()).filter(Boolean);
  const shards = getShardCount(get);
  const group = get(ShardGroupParameter);
  if (maps.length > 0) {
    if (shards > 1 || group) {
      Juke.logger.error('--maps does not combine with --shards or --shard-group.');
      throw new Juke.ExitCode(1);
    }
    return maps.map((map) => {
      const config = `_maps/${map}.json`;
      if (!fs.existsSync(config)) {
        Juke.logger.error(`No map config ${config}.`);
        throw new Juke.ExitCode(1);
      }
      return {
        name: map,
        directory: `${logDirectory}-${map}`,
        params: [`unit-test-map=${config}`, `unit-test-instance=${map}`, testListParam(get)],
      };
    });
  }
  if (shards === 1 && !group) {
    return null;
  }
  const [groupIndex, groupCount] = group ? group.split('/').map(Number) : [1, 1];
  if (!Number.isInteger(groupIndex) || !Number.isInteger(groupCount) || groupIndex < 1 || groupIndex > groupCount) {
    Juke.logger.error(`--shard-group expects J/M with 1 <= J <= M, got '${group}'.`);
    throw new Juke.ExitCode(1);
  }
  const total = shards * groupCount;
  return Array.from({ length: shards }, (_, index) => {
    const shard = (groupIndex - 1) * shards + index + 1;
    return {
      name: `shard${shard}`,
      directory: `${logDirectory}-shard${shard}`,
      params: [`unit-test-shard=${shard}/${total}`, `unit-test-durations=${UNIT_TEST_DURATIONS}`, testListParam(get)],
    };
  });
};

const getWorldTimeoutMs = (get) => {
  const minutes = Number(get(WorldTimeoutParameter) || 0);
  if (!Number.isFinite(minutes) || minutes < 0) {
    Juke.logger.error(`--world-timeout expects minutes, got '${get(WorldTimeoutParameter)}'.`);
    throw new Juke.ExitCode(1);
  }
  return minutes * 60000;
};

const readJson = (file) => {
  try {
    return JSON.parse(fs.readFileSync(file, 'utf-8'));
  }
  catch {
    return null;
  }
};

/** A clock step back counts in REALTIMEOFDAY as a midnight, a whole day added to one test:
 * such a time would leave that test alone in its shard on every later run. */
const MAX_TEST_WALL = 3600;

/** Keeps the last wall time of every test that ran, for balancing later shards. */
const recordUnitTestDurations = (logDirectories) => {
  const durations = readJson(UNIT_TEST_DURATIONS) || {};
  for (const logDirectory of logDirectories) {
    const results = readJson(`data/logs/${logDirectory}/unit_tests.json`) || {};
    for (const [name, result] of Object.entries(results)) {
      if (typeof result?.wall === 'number' && result.wall >= 0 && result.wall < MAX_TEST_WALL) {
        durations[name] = Math.round(result.wall * 1000) / 1000;
      }
    }
  }
  fs.mkdirSync(path.dirname(UNIT_TEST_DURATIONS), { recursive: true });
  fs.writeFileSync(UNIT_TEST_DURATIONS, JSON.stringify(durations, null, 1));
};

const runWorldParams = (logDirectory, extra = []) => [
  `log-directory=${logDirectory}`,
  ...extra,
].filter(Boolean).join('&');

const testListParam = (get) => get(TestListParameter) && `unit-test-list=${get(TestListParameter)}`;

/** One test world with its output in a file. Kills it if it hangs after shutdown
 * or outlives the timeout. */
const runTestWorld = (ddPath, dmbFile, params, outputFile, timeoutMs) => new Promise((resolve) => {
  const sink = fs.createWriteStream(outputFile);
  const child = spawn(ddPath, [dmbFile, '-close', '-trusted', '-verbose', '-params', params], {
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  let tail = '';
  let hangTimer;
  let timedOut = false;
  const deadline = timeoutMs > 0 && setTimeout(() => {
    timedOut = true;
    child.kill('SIGKILL');
  }, timeoutMs);
  const onData = (chunk) => {
    sink.write(chunk);
    tail = (tail + chunk.toString()).slice(-256);
    if (!hangTimer && tail.includes('Shutdown complete')) {
      hangTimer = setTimeout(() => child.kill('SIGKILL'), SHARD_HANG_GRACE_MS);
    }
  };
  child.stdout.on('data', onData);
  child.stderr.on('data', onData);
  child.on('close', (code) => {
    clearTimeout(hangTimer);
    clearTimeout(deadline);
    sink.end(() => resolve({ code, timedOut }));
  });
});

const worldOutputFile = (logDirectory, world) => `data/logs/${logDirectory}/${world.name}.out.log`;
const isWorldClean = (world) => fs.existsSync(`data/logs/${world.directory}/clean_run.lk`);

/** Starts the worlds side by side from hardlinks of one DMB and waits for all of them.
 * Each world gets world.json with its exit, cleanliness and init time. */
const startWorlds = async (get, artifactBase, logDirectory, worlds) => {
  const ddPath = await getDreamDaemonPath();
  const timeoutMs = getWorldTimeoutMs(get);
  const worldBases = worlds.map((world) => `${artifactBase}.${world.name}`);
  worlds.forEach((world, index) => {
    // Hardlinks, not copies: the rsc is ~600 MB. Each name gets its own .dyn.rsc.
    for (const extension of ['dmb', 'rsc']) {
      fs.rmSync(`${worldBases[index]}.${extension}`, { force: true });
      fs.linkSync(`${artifactBase}.${extension}`, `${worldBases[index]}.${extension}`);
    }
    fs.rmSync(`${worldBases[index]}.dyn.rsc`, { force: true });
    Juke.rm(`data/logs/${world.directory}`, { recursive: true });
  });
  fs.mkdirSync(`data/logs/${logDirectory}`, { recursive: true });
  Juke.logger.info(`Running ${worlds.map((world) => world.name).join(', ')}, output in data/logs/${logDirectory}/<name>.out.log`);
  const outcomes = await Promise.all(worlds.map((world, index) => runTestWorld(
    ddPath,
    `${worldBases[index]}.dmb`,
    runWorldParams(world.directory, world.params),
    worldOutputFile(logDirectory, world),
    timeoutMs,
  )));
  for (const worldBase of worldBases) {
    for (const extension of ['dmb', 'rsc', 'dyn.rsc']) {
      fs.rmSync(`${worldBase}.${extension}`, { force: true });
    }
  }
  worlds.forEach((world, index) => {
    const output = fs.readFileSync(worldOutputFile(logDirectory, world), 'utf-8');
    const init = /Initializations complete within ([\d.]+) seconds/.exec(output);
    fs.mkdirSync(`data/logs/${world.directory}`, { recursive: true });
    fs.writeFileSync(`data/logs/${world.directory}/world.json`, JSON.stringify({
      name: world.name,
      exit: outcomes[index].code,
      timed_out: outcomes[index].timedOut,
      clean: isWorldClean(world),
      init_seconds: init ? Number(init[1]) : null,
    }, null, 1));
  });
  return outcomes;
};

/** Failed tests of a world that finished its run, or null when it did not finish. */
const failedTests = (world) => {
  const results = readJson(`data/logs/${world.directory}/unit_tests.json`);
  return results && Object.entries(results)
    .filter(([, result]) => result.status === UNIT_TEST_FAILED)
    .map(([name]) => name);
};

/** Runs the failed tests of each unclean world once more in a fresh world. A world whose
 * failed tests all pass there, with no runtimes, counts as clean: its failures were flaky.
 * A world with many failures or one that did not finish is not retried. */
const retryFailedTests = async (get, artifactBase, logDirectory, worlds) => {
  const retries = worlds
    .filter((world) => !isWorldClean(world))
    .map((world) => ({ world, failed: failedTests(world) }))
    .filter(({ failed }) => failed && failed.length > 0 && failed.length <= MAX_RETRIED_TESTS)
    .map(({ world, failed }) => {
      const listFile = `data/logs/${logDirectory}/${world.name}-retry.txt`;
      fs.writeFileSync(listFile, failed.join('\n') + '\n');
      return {
        world,
        failed,
        retry: {
          name: `${world.name}-retry`,
          directory: `${world.directory}-retry`,
          params: [
            ...world.params.filter((param) => param && param.startsWith('unit-test-map=')),
            `unit-test-instance=${world.name}-retry`,
            `unit-test-list=${listFile}`,
          ],
        },
      };
    });
  if (retries.length === 0) {
    return { retryWorlds: [], flaky: [] };
  }
  Juke.logger.info(`Retrying the failed tests of ${retries.map(({ world }) => world.name).join(', ')}`);
  const retryWorlds = retries.map(({ retry }) => retry);
  await startWorlds(get, artifactBase, logDirectory, retryWorlds);
  const flaky = [];
  for (const { world, failed, retry } of retries) {
    const results = readJson(`data/logs/${retry.directory}/unit_tests.json`) || {};
    if (isWorldClean(retry) && failed.every((name) => results[name]?.status === UNIT_TEST_PASSED)) {
      world.recovered = true;
      flaky.push(...failed.map((test) => ({ world: world.name, test })));
    }
  }
  return { retryWorlds, flaky };
};

const runWorlds = async (get, artifactBase, logDirectory, worlds) => {
  const startedAt = Date.now();
  const outcomes = await startWorlds(get, artifactBase, logDirectory, worlds);
  for (const name of MERGED_SHARD_LOGS) {
    const merged = worlds
      .map((world) => `data/logs/${world.directory}/${name}`)
      .filter((file) => fs.existsSync(file))
      .map((file) => fs.readFileSync(file, 'utf-8'))
      .join('');
    fs.writeFileSync(`data/logs/${logDirectory}/${name}`, merged);
  }
  const { retryWorlds, flaky } = get(RetryFailedParameter)
    ? await retryFailedTests(get, artifactBase, logDirectory, worlds)
    : { retryWorlds: [], flaky: [] };
  fs.writeFileSync(`data/logs/${logDirectory}/flaky.json`, JSON.stringify(flaky, null, 1));
  // In CI the raw output carries the ::group:: and ::error:: workflow commands of every test.
  if (get(CiParameter)) {
    for (const world of [...worlds, ...retryWorlds]) {
      Juke.logger.info(`Output of ${world.name}:`);
      console.log(fs.readFileSync(worldOutputFile(logDirectory, world), 'utf-8'));
    }
    for (const { world, test } of flaky) {
      console.log(`::warning title=Нестабильный тест::${test} упал в ${world} и прошёл при повторе`);
    }
  }
  let clean = true;
  worlds.forEach((world, index) => {
    const worldClean = isWorldClean(world);
    clean &&= worldClean || world.recovered === true;
    const testsFile = `data/logs/${world.directory}/tests.log`;
    const testsLog = fs.existsSync(testsFile) ? fs.readFileSync(testsFile, 'utf-8') : '';
    const passed = (testsLog.match(/\] PASS: /g) || []).length;
    const failed = (testsLog.match(/\] FAIL: /g) || []).length;
    const { code, timedOut } = outcomes[index];
    const verdict = worldClean ? 'clean' : world.recovered ? 'flaky, passed on retry' : 'NOT clean';
    Juke.logger.info(`${world.name}: exit ${code}${timedOut ? ' (killed by timeout)' : ''}, ${passed} passed, ${failed} failed, ${verdict}`);
    for (const block of testsLog.split(/\n(?=\[)/)) {
      if (block.includes('] FAIL: ')) {
        console.log(block);
      }
    }
  });
  Juke.logger.info(`Worlds finished in ${((Date.now() - startedAt) / 1000).toFixed(1)}s`);
  recordUnitTestDurations(worlds.map((world) => world.directory));
  if (clean) {
    fs.writeFileSync(`data/logs/${logDirectory}/clean_run.lk`, 'Success!');
  }
  return clean;
};

const dmTestRunParameters = [
  DefineParameter,
  UnitTestProfileParameter,
  ShardsParameter,
  TestListParameter,
  ShardGroupParameter,
  MapsParameter,
  PrebuiltParameter,
  WorldTimeoutParameter,
  RetryFailedParameter,
  CiParameter,
];

/** Run an already up-to-date unit-test DMB. This target intentionally has no
 * outputs so each invocation runs the world, while dm-test-build is cached. */
export const DmTestRunTarget = new Juke.Target({
  parameters: dmTestRunParameters,
  dependsOn: ({ get }) => [
    LoadoutCryptoRuntimeTarget,
    !get(PrebuiltParameter) && DmTestBuildTarget,
  ],
  executes: async ({ get }) => {
    const artifactBase = getUnitTestArtifactBase(get);
    if (!fs.existsSync(`${artifactBase}.dmb`)) {
      Juke.logger.error(`${artifactBase}.dmb is missing, build it with dm-test-build.`);
      throw new Juke.ExitCode(1);
    }
    const logDirectory = getUnitTestLogDirectory(get);
    const worlds = getTestWorlds(get, logDirectory);
    Juke.rm(`data/logs/${logDirectory}`, { recursive: true });
    if (worlds) {
      if (!await runWorlds(get, artifactBase, logDirectory, worlds)) {
        Juke.logger.error('Test run was not clean, exiting');
        throw new Juke.ExitCode(1);
      }
      console.log('Success!');
      return;
    }
    await DreamDaemon(
      `${artifactBase}.dmb`,
      '-close', '-trusted', '-verbose',
      '-params', runWorldParams(logDirectory, [testListParam(get)])
    );
    recordUnitTestDurations([logDirectory]);
    try {
      const cleanRun = fs.readFileSync(`data/logs/${logDirectory}/clean_run.lk`, 'utf-8');
      console.log(cleanRun);
    }
    catch (err) {
      Juke.logger.error('Test run was not clean, exiting');
      throw new Juke.ExitCode(1);
    }
  },
});

/** Backwards-compatible compile-and-run entrypoint. */
export const DmTestTarget = new Juke.Target({
  parameters: dmTestRunParameters,
  dependsOn: [DmTestRunTarget],
});

export const YarnTarget = new Juke.Target({
  inputs: [
    'tgui/.yarn/+(cache|releases|plugins|sdks)/**/*',
    'tgui/**/package.json',
    'tgui/yarn.lock',
  ],
  outputs: [
    'tgui/.yarn/install-target',
  ],
  executes: async () => {
    await yarn('install');
  },
});

export const TgFontTarget = new Juke.Target({
  dependsOn: [YarnTarget],
  inputs: [
    'tgui/.yarn/install-target',
    'tgui/packages/tgfont/**/*.+(js|cjs|svg)',
    'tgui/packages/tgfont/package.json',
  ],
  outputs: [
    'tgui/packages/tgfont/dist/tgfont.css',
    'tgui/packages/tgfont/dist/tgfont.eot',
    'tgui/packages/tgfont/dist/tgfont.woff2',
  ],
  executes: async () => {
    await yarn('workspace', 'tgfont', 'build');
  },
});

export const TguiTarget = new Juke.Target({
  dependsOn: [YarnTarget, LoadoutCryptoRuntimeTarget],
  inputs: [
    'tgui/.yarn/install-target',
    'tgui/vite.base.config.cjs',
    'tgui/vite.tgui.config.cjs',
    'tgui/vite.tgui-panel.config.cjs',
    'tgui/**/package.json',
    'tgui/packages/**/*.+(js|cjs|ts|tsx|scss)',
  ],
  outputs: [
    'tgui/public/tgui.bundle.css',
    'tgui/public/tgui.bundle.js',
    'tgui/public/tgui-panel.bundle.css',
    'tgui/public/tgui-panel.bundle.js',
  ],
  executes: async () => {
    await yarn('vite', 'build', '--mode=production', '--config', 'vite.tgui.config.cjs');
    await yarn('vite', 'build', '--mode=production', '--config', 'vite.tgui-panel.config.cjs');
  },
});

export const TguiEslintTarget = new Juke.Target({
  dependsOn: [YarnTarget],
  parameters: [CiParameter],
  executes: async ({ args, get }) => {
    await yarn(
      'eslint', 'packages',
      ...(!get(CiParameter) ? ['--fix'] : []),
      '--ext', '.js,.cjs,.ts,.tsx',
      ...args
    );
  },
});

export const TguiTscTarget = new Juke.Target({
  dependsOn: [YarnTarget],
  executes: async () => {
    await yarn('tsc');
  },
});

export const TguiTestTarget = new Juke.Target({
  dependsOn: [YarnTarget],
  executes: async ({ args }) => {
    await yarn('jest', ...args);
  },
});

export const TguiLintTarget = new Juke.Target({
  dependsOn: [YarnTarget, TguiEslintTarget, TguiTscTarget, TguiTestTarget],
});

export const TguiDevTarget = new Juke.Target({
  dependsOn: [YarnTarget],
  executes: async ({ args }) => {
    await yarn('run', 'tgui:dev', ...args);
  },
});

export const TguiAnalyzeTarget = new Juke.Target({
  dependsOn: [YarnTarget],
  executes: async () => {
    await yarn('vite', 'build', '--mode=production', '--sourcemap', '--config', 'vite.tgui.config.cjs');
    await yarn('vite', 'build', '--mode=production', '--sourcemap', '--config', 'vite.tgui-panel.config.cjs');
  },
});

export const TestTarget = new Juke.Target({
  dependsOn: [DmTestTarget, TguiTestTarget],
});

export const LintTarget = new Juke.Target({
  dependsOn: [TguiLintTarget],
});

export const BuildTarget = new Juke.Target({
  dependsOn: [TguiTarget, TgFontTarget, DmTarget],
});

export const ServerTarget = new Juke.Target({
  dependsOn: [BuildTarget],
  executes: async ({ get }) => {
    const port = get(PortParameter) || '1337';
    await DreamDaemon(`${DME_NAME}.dmb`, port, '-trusted');
  },
});

export const AllTarget = new Juke.Target({
  dependsOn: [TestTarget, LintTarget, BuildTarget],
});

/**
 * Wrapper around Juke.rm that skips files locked by another process.
 */
const safeRm = (pattern, options) => {
  try {
    Juke.rm(pattern, options);
  } catch (err) {
    if (err.code === 'EBUSY' || err.code === 'EPERM') {
      Juke.logger.warn(
        `Cannot remove '${err.path || pattern}': file is busy or locked, skipping`
      );
    } else {
      throw err;
    }
  }
};

/**
 * Removes the immediate build junk to produce clean builds.
 */
export const CleanTarget = new Juke.Target({
  executes: async () => {
    safeRm('*.dmb');
    safeRm('*.rsc');
    safeRm('*.mdme');
    safeRm('*.mdme*');
    safeRm('*.m.*');
    safeRm('_maps/templates.dm');
    safeRm('tgui/public/.tmp', { recursive: true });
    safeRm('tgui/public/*.map');
    safeRm('tgui/public/*.chunk.*');
    safeRm('tgui/public/*.bundle.*');
    safeRm('tgui/public/*.hot-update.*');
    safeRm('tgui/packages/tgfont/dist', { recursive: true });
    safeRm('tgui/.yarn/cache', { recursive: true });
    safeRm('tgui/.yarn/unplugged', { recursive: true });
    safeRm('tgui/.yarn/build-state.yml');
    safeRm('tgui/.yarn/install-state.gz');
    safeRm('tgui/.yarn/install-target');
    safeRm('tgui/.pnp.*');
  },
});

/**
 * Removes more junk at expense of much slower initial builds.
 */
export const DistCleanTarget = new Juke.Target({
  dependsOn: [CleanTarget],
  executes: async () => {
    const bootstrapCacheDir = 'tools/bootstrap/.cache';

    Juke.logger.info('Cleaning up data/logs');
    safeRm('data/logs', { recursive: true });

    Juke.logger.info('Cleaning up bootstrap cache');
    if (!fs.existsSync(bootstrapCacheDir)) {
      Juke.logger.info('Bootstrap cache directory not found, skipping');
    }
    else {
      const cacheRealPath = fs.realpathSync(bootstrapCacheDir);
      const nodeRealPath = fs.realpathSync(process.execPath);
      const nodeRelativePath = path.relative(cacheRealPath, nodeRealPath);
      const nodeRunsFromBootstrapCache = nodeRelativePath
        && !nodeRelativePath.startsWith('..')
        && !path.isAbsolute(nodeRelativePath);

      if (!nodeRunsFromBootstrapCache) {
        safeRm(bootstrapCacheDir, { recursive: true });
      }
      else {
        const activeNodeDir = nodeRelativePath.split(path.sep)[0];
        const entries = fs.readdirSync(bootstrapCacheDir);

        for (const entry of entries) {
          const isActiveNodeDir = process.platform === 'win32'
            ? entry.toLowerCase() === activeNodeDir.toLowerCase()
            : entry === activeNodeDir;
          if (isActiveNodeDir) {
            continue;
          }

          safeRm(path.posix.join(bootstrapCacheDir, entry), { recursive: true });
        }
      }
    }

    Juke.logger.info('Cleaning up global yarn cache');
    await yarn('cache', 'clean', '--all');
  },
});

/**
 * Prepends the defines to the .dme.
 * Does not clean them up, as this is intended for TGS which
 * clones new copies anyway.
 */
const prependDefines = (...defines) => {
  const dmeContents = fs.readFileSync(`${DME_NAME}.dme`);
  const textToWrite = defines.map(define => `#define ${define}\n`);
  fs.writeFileSync(`${DME_NAME}.dme`, `${textToWrite}\n${dmeContents}`);
};

export const TgsTarget = new Juke.Target({
  dependsOn: [TguiTarget, TgFontTarget, NanomapsTarget],
  executes: async () => {
    Juke.logger.info('Prepending TGS define');
    prependDefines('TGS');
  },
});

const TGS_MODE = process.env.CBT_BUILD_MODE === 'TGS';

export default TGS_MODE ? TgsTarget : BuildTarget;

#!/usr/bin/env node
// Collects the results of every CI test world: checks that the hermetic shards ran
// each test exactly once, writes failures, flaky tests and map start times to the job
// summary, and refreshes the history files the next run compares with.
//
// Usage: node tools/ci/unit_test_report.mjs <results dir> <durations json> <map init times json>

import fs from 'node:fs';
import path from 'node:path';

const PASSED = 0;
const FAILED = 1;
// A clock step back counts as a midnight and adds a day to one test, such times are dropped.
const MAX_TEST_WALL = 3600;
const SKIPPED_BY_PROFILE = 'Skipped by unit test profile';
const HERMETIC_SHARD = /^ci-hermetic-shard\d+$/;
const MAP_WORLD = /^ci-full-map-(.+)$/;
const RETRY_SUFFIX = '-retry';
// Runners differ by tens of percent, only a slowdown above both limits is marked.
const SLOWER_RATIO = 1.25;
const SLOWER_SECONDS = 10;

const [resultsRoot, durationsFile, initTimesFile] = process.argv.slice(2);
if (!resultsRoot || !durationsFile || !initTimesFile) {
  console.error('Usage: unit_test_report.mjs <results dir> <durations json> <map init times json>');
  process.exit(2);
}

const readJson = (file, fallback) => {
  try {
    return JSON.parse(fs.readFileSync(file, 'utf-8'));
  }
  catch {
    return fallback;
  }
};

const findFiles = (directory, name) => fs.readdirSync(directory, { withFileTypes: true })
  .flatMap((entry) => {
    const entryPath = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      return findFiles(entryPath, name);
    }
    return entry.name === name ? [entryPath] : [];
  });

const allWorlds = new Map();
for (const file of fs.existsSync(resultsRoot) ? findFiles(resultsRoot, 'unit_tests.json') : []) {
  const directory = path.dirname(file);
  allWorlds.set(path.basename(directory), {
    name: path.basename(directory),
    results: readJson(file, {}),
    info: readJson(path.join(directory, 'world.json'), {}),
  });
}
const worlds = [...allWorlds.values()]
  .filter((world) => !world.name.endsWith(RETRY_SUFFIX))
  .sort((a, b) => a.name.localeCompare(b.name, 'en', { numeric: true }));

const summary = ['## Юнит-тесты', '', '| Мир | Прошло | Упало |', '| --- | ---: | ---: |'];
const failures = [];
const flaky = [];
for (const world of worlds) {
  const entries = Object.entries(world.results);
  const failed = entries.filter(([, result]) => result.status === FAILED);
  summary.push(`| ${world.name} | ${entries.filter(([, result]) => result.status === PASSED).length} | ${failed.length} |`);
  const retry = allWorlds.get(world.name + RETRY_SUFFIX);
  for (const [name, result] of failed) {
    const entry = { world: world.name, name, message: result.message || '' };
    if (retry?.results[name]?.status === PASSED) {
      flaky.push(entry);
    }
    else {
      failures.push(entry);
    }
  }
}

const shards = worlds.filter((world) => HERMETIC_SHARD.test(world.name));
const problems = [];
if (shards.length === 0) {
  problems.push('Ни один hermetic-шард не прислал результатов.');
}
const runs = new Map();
for (const shard of shards) {
  for (const [name, result] of Object.entries(shard.results)) {
    if (!runs.has(name)) {
      runs.set(name, []);
    }
    if (result.status === PASSED || result.status === FAILED) {
      runs.get(name).push(shard.name);
    }
    else if (result.message === SKIPPED_BY_PROFILE) {
      runs.delete(name);
    }
  }
}
for (const [name, ranIn] of runs) {
  if (ranIn.length === 0) {
    problems.push(`${name} не прошёл ни в одном шарде.`);
  }
  else if (ranIn.length > 1) {
    problems.push(`${name} прошёл в нескольких шардах: ${ranIn.join(', ')}.`);
  }
}

const reasons = (message) => message.split('\n').slice(1).map((line) => line.trim()).join('\n');
const details = (entry) => [
  `<details><summary><b>${entry.world}</b> <code>${entry.name}</code></summary>`, '', '```', reasons(entry.message), '```', '</details>',
];
if (failures.length > 0) {
  summary.push('', '### Упавшие тесты', '');
  failures.forEach((entry) => summary.push(...details(entry)));
}
if (flaky.length > 0) {
  summary.push('', '### Нестабильные тесты', '', 'Упали, но прошли при повторе в новом мире. Прогон из-за них не красный, но тест стоит починить.', '');
  flaky.forEach((entry) => summary.push(...details(entry)));
}
if (problems.length > 0) {
  summary.push('', '### Покрытие шардов', '');
  summary.push(...problems.slice(0, 50).map((problem) => `- ${problem}`));
  if (problems.length > 50) {
    summary.push(`- ...и ещё ${problems.length - 50}`);
  }
}

const pastInitTimes = readJson(initTimesFile, {});
const initTimes = {};
for (const world of worlds) {
  const map = MAP_WORLD.exec(world.name)?.[1];
  if (map && typeof world.info.init_seconds === 'number') {
    initTimes[map] = world.info.init_seconds;
  }
}
if (Object.keys(initTimes).length > 0) {
  summary.push('', '### Старт карт', '', '| Карта | Старт, с | На master, с | Разница |', '| --- | ---: | ---: | ---: |');
  for (const [map, seconds] of Object.entries(initTimes).sort(([a], [b]) => a.localeCompare(b))) {
    const past = pastInitTimes[map];
    let change = '-';
    if (typeof past === 'number' && past > 0) {
      const percent = Math.round((seconds / past - 1) * 100);
      change = `${percent > 0 ? '+' : ''}${percent}%`;
      if (seconds > past * SLOWER_RATIO && seconds - past > SLOWER_SECONDS) {
        change = `**${change}**`;
      }
    }
    summary.push(`| ${map} | ${seconds.toFixed(1)} | ${typeof past === 'number' ? past.toFixed(1) : '-'} | ${change} |`);
  }
}

const text = summary.join('\n') + '\n';
if (process.env.GITHUB_STEP_SUMMARY) {
  fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, text);
}
console.log(text);

const durations = readJson(durationsFile, {});
for (const shard of shards) {
  for (const [name, result] of Object.entries(shard.results)) {
    if (typeof result?.wall === 'number' && result.wall >= 0 && result.wall < MAX_TEST_WALL) {
      durations[name] = Math.round(result.wall * 1000) / 1000;
    }
  }
}
for (const [file, data] of [[durationsFile, durations], [initTimesFile, { ...pastInitTimes, ...initTimes }]]) {
  fs.mkdirSync(path.dirname(path.resolve(file)), { recursive: true });
  fs.writeFileSync(file, JSON.stringify(data, null, 1));
}

// GitHub shows ten error annotations per step, the rest is in the summary above.
for (const problem of problems.slice(0, 10)) {
  console.log(`::error title=Покрытие шардов::${problem}`);
}
if (problems.length > 10) {
  console.log(`::error title=Покрытие шардов::Всего проблем: ${problems.length}, список в сводке прогона.`);
}
process.exit(problems.length > 0 ? 1 : 0);

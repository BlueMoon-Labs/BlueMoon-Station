#!/usr/bin/env node
// Publishes the images of tools/ci/map_diff.mjs and puts them into a PR comment.
// Runs from the Map Diff Comment workflow with a write token, so everything from the
// artifact is untrusted data: the manifest is validated and only PNG files are taken.
// Images live on the map-diffs branch, one commit holding a folder per open PR.
//
// Usage: node tools/ci/map_diff_publish.mjs <artifact dir>
// Environment: GH_TOKEN, GITHUB_REPOSITORY, HEAD_SHA (head commit of the rendered PR)

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const BRANCH = 'map-diffs';
const MARKER = '<!-- map-diff -->';
const MAX_IMAGES = 80;
const MAX_IMAGE_BYTES = 8 * 1024 * 1024;
const PNG_SIGNATURE = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
const MAP_PATH = /^_maps\/[\w/. -]+\.dmm$/;
const IMAGE_PATH = /^images\/[\w.-]+\.png$/;
const STATUS_NAMES = { A: 'новая', M: 'изменена', D: 'удалена' };

const [artifactDirectory] = process.argv.slice(2);
const { GH_TOKEN: token, GITHUB_REPOSITORY: repository, HEAD_SHA: headSha } = process.env;
if (!artifactDirectory || !token || !repository || !/^[0-9a-f]{40}$/.test(headSha || '')) {
  console.error('Usage: map_diff_publish.mjs <artifact dir>, with GH_TOKEN, GITHUB_REPOSITORY and HEAD_SHA set');
  process.exit(2);
}

const api = async (method, url, body) => {
  const response = await fetch(`https://api.github.com/repos/${repository}${url}`, {
    method,
    headers: {
      authorization: `Bearer ${token}`,
      accept: 'application/vnd.github+json',
      'x-github-api-version': '2022-11-28',
      ...(body ? { 'content-type': 'application/json' } : {}),
    },
    body: body && JSON.stringify(body),
  });
  if (!response.ok) {
    throw new Error(`${method} ${url}: ${response.status} ${await response.text()}`);
  }
  return response.status === 204 ? null : response.json();
};

const paginate = async (url) => {
  const items = [];
  for (let page = 1; ; page++) {
    const batch = await api('GET', `${url}${url.includes('?') ? '&' : '?'}per_page=100&page=${page}`);
    items.push(...batch);
    if (batch.length < 100) {
      return items;
    }
  }
};

const openPulls = await paginate('/pulls?state=open');
const pull = openPulls.find((candidate) => candidate.head.sha === headSha);
if (!pull) {
  console.log(`No open pull request has head ${headSha}: it was closed or got newer commits.`);
  process.exit(0);
}

// Validate the manifest: only known fields, numbers and paths of the expected shape.
const integer = (value) => Number.isInteger(value) && value >= 0 && value < 100000;
const manifest = JSON.parse(fs.readFileSync(path.join(artifactDirectory, 'manifest.json'), 'utf-8'));
const images = new Map();
const maps = [];
for (const entry of Array.isArray(manifest.maps) ? manifest.maps : []) {
  if (typeof entry?.path !== 'string' || !MAP_PATH.test(entry.path)) {
    continue;
  }
  const map = {
    path: entry.path,
    status: STATUS_NAMES[entry.status] || 'изменена',
    note: typeof entry.note === 'string' ? entry.note.replace(/[<>`|*_[\]\\]/g, '').slice(0, 200) : '',
    regions: [],
  };
  for (const region of Array.isArray(entry.regions) ? entry.regions : []) {
    const numbers = ['z', 'minX', 'minY', 'maxX', 'maxY'].map((key) => region?.[key]);
    if (!numbers.every(integer)) {
      continue;
    }
    const sides = {};
    for (const side of ['before', 'after']) {
      const image = region[side];
      if (typeof image !== 'string' || !IMAGE_PATH.test(image) || images.size >= MAX_IMAGES) {
        continue;
      }
      const file = path.join(artifactDirectory, image);
      if (!fs.existsSync(file) || fs.statSync(file).size > MAX_IMAGE_BYTES) {
        continue;
      }
      const head = Buffer.alloc(PNG_SIGNATURE.length);
      const descriptor = fs.openSync(file, 'r');
      fs.readSync(descriptor, head, 0, head.length, 0);
      fs.closeSync(descriptor);
      if (head.equals(PNG_SIGNATURE)) {
        images.set(path.basename(image), file);
        sides[side] = path.basename(image);
      }
    }
    if (!sides.after) {
      continue;
    }
    const tiles = (Array.isArray(region.tiles) ? region.tiles : [])
      .filter((tile) => Array.isArray(tile) && tile.length === 2 && tile.every(integer))
      .slice(0, 12);
    map.regions.push({
      z: region.z,
      min: [region.minX, region.minY],
      max: [region.maxX, region.maxY],
      changed: integer(region.changed) ? region.changed : null,
      cropped: region.cropped === true,
      tiles,
      ...sides,
    });
  }
  maps.push(map);
}

// Rebuild the branch: folders of open PRs stay, this PR gets only the images of its head.
const short = headSha.slice(0, 7);
const folder = `pr-${pull.number}/${short}`;
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'map-diffs-'));
const auth = Buffer.from(`x-access-token:${token}`).toString('base64');
const git = (...args) => execFileSync('git', [
  '-c', `http.https://github.com/.extraheader=AUTHORIZATION: basic ${auth}`,
  '-c', 'user.name=github-actions[bot]',
  '-c', 'user.email=41898282+github-actions[bot]@users.noreply.github.com',
  ...args,
], { cwd: work, encoding: 'utf-8', stdio: ['ignore', 'pipe', 'inherit'] });
git('init', '-q');
git('remote', 'add', 'origin', `https://github.com/${repository}.git`);
if (git('ls-remote', '--heads', 'origin', BRANCH).trim()) {
  git('fetch', '-q', '--depth=1', 'origin', BRANCH);
  git('checkout', '-q', 'FETCH_HEAD');
}
const openNumbers = new Set(openPulls.map((candidate) => `pr-${candidate.number}`));
for (const entry of fs.readdirSync(work)) {
  if (entry !== '.git' && (!openNumbers.has(entry) || entry === `pr-${pull.number}`)) {
    fs.rmSync(path.join(work, entry), { recursive: true, force: true });
  }
}
if (images.size > 0) {
  fs.mkdirSync(path.join(work, folder), { recursive: true });
  for (const [name, file] of images) {
    fs.copyFileSync(file, path.join(work, folder, name));
  }
}
git('checkout', '-q', '--orphan', 'publish');
git('add', '-A');
git('commit', '-q', '--allow-empty', '-m', 'Map diff images of open pull requests');
git('push', '-q', '-f', 'origin', `HEAD:refs/heads/${BRANCH}`);
fs.rmSync(work, { recursive: true, force: true });

// The comment: one block per map, regions as before/after pairs.
const imageUrl = (name) => `https://raw.githubusercontent.com/${repository}/${BRANCH}/${folder}/${name}`;
const lines = [MARKER, '## Изменения карт', '', `Рендер для коммита ${short}. Слева до PR, справа после.`, ''];
const silent = maps.filter((map) => map.regions.length === 0);
for (const map of maps.filter((candidate) => candidate.regions.length > 0)) {
  lines.push(`<details open><summary><code>${map.path}</code>, ${map.status}, участков: ${map.regions.length}</summary>`, '');
  if (map.note) {
    lines.push(`_${map.note}_`, '');
  }
  for (const region of map.regions) {
    const where = `z${region.z}, x ${region.min[0]}-${region.max[0]}, y ${region.min[1]}-${region.max[1]}`;
    const changed = region.changed === null ? '' : `, изменено клеток: ${region.changed}`;
    const tiles = region.tiles.length > 0 ? ` (${region.tiles.map(([x, y]) => `${x},${y}`).join('; ')})` : '';
    lines.push(`**${where}**${changed}${tiles}${region.cropped ? ', показана середина участка' : ''}`, '');
    if (region.before) {
      lines.push('| До | После |', '| :---: | :---: |', `| <img src="${imageUrl(region.before)}" width="400"> | <img src="${imageUrl(region.after)}" width="400"> |`, '');
    }
    else {
      lines.push(`<img src="${imageUrl(region.after)}" width="400">`, '');
    }
  }
  lines.push('</details>', '');
}
if (silent.length > 0) {
  lines.push('Без картинок:', '', ...silent.map((map) => `- \`${map.path}\`, ${map.status}${map.note ? `: ${map.note}` : ''}`), '');
}
if (maps.length === 0) {
  lines.push('Карты в этом PR больше не меняются.');
}
const body = lines.join('\n');

const comments = await paginate(`/issues/${pull.number}/comments`);
const previous = comments.find((comment) => comment.user?.type === 'Bot' && comment.body?.startsWith(MARKER));
if (previous) {
  await api('PATCH', `/issues/comments/${previous.id}`, { body });
  console.log(`Updated the map diff comment on #${pull.number}.`);
}
else if (maps.length > 0) {
  await api('POST', `/issues/${pull.number}/comments`, { body });
  console.log(`Posted the map diff comment on #${pull.number}.`);
}

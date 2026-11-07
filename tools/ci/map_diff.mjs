#!/usr/bin/env node
// Renders "before" and "after" images of the changed parts of every map a PR touches.
// Changed tiles close to each other are rendered as one region. The output directory
// gets the images and manifest.json, which the Map Diff Comment workflow publishes.
//
// Usage: node tools/ci/map_diff.mjs <base ref> <output dir>

import fs from 'node:fs';
import path from 'node:path';
import { execFileSync, spawnSync } from 'node:child_process';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { ensureRenderer } = require('../nanomaps/renderer.cjs');

// Tiles within twice this distance end up in one region; every region gets this margin.
const PADDING = 3;
const MAX_MAPS = 10;
const MAX_REGIONS_PER_MAP = 8;
// A region larger than this many tiles per side is cut to its middle part.
const MAX_REGION_SIDE = 64;
// A new map or one whose size changed is rendered whole only up to this size.
const MAX_WHOLE_MAP_SIDE = 96;
const MAX_LISTED_TILES = 12;

const [baseRef, outputDirectory] = process.argv.slice(2);
if (!baseRef || !outputDirectory) {
  console.error('Usage: map_diff.mjs <base ref> <output dir>');
  process.exit(2);
}

const git = (...args) => execFileSync('git', args, { encoding: 'utf-8', maxBuffer: 256 * 1024 * 1024 });
const work = path.join(outputDirectory, 'work');
const images = path.join(outputDirectory, 'images');
fs.rmSync(outputDirectory, { recursive: true, force: true });
fs.mkdirSync(work, { recursive: true });
fs.mkdirSync(images, { recursive: true });

const changes = git('diff', '--name-status', '--no-renames', baseRef, 'HEAD', '--', '_maps/*.dmm')
  .split('\n')
  .filter(Boolean)
  .map((line) => {
    const [status, file] = line.split('\t');
    return { status, file };
  });

const renderer = await ensureRenderer();
const mapSize = (file) => {
  const info = JSON.parse(execFileSync(renderer, ['map-info', '--json', file], { encoding: 'utf-8' }));
  return Object.values(info)[0].size;
};

/** Changed tiles per z-level, or null when the map changed its size. */
const changedTiles = (before, after) => {
  const output = execFileSync(renderer, ['diff-maps', before, after], { encoding: 'utf-8', maxBuffer: 64 * 1024 * 1024 });
  if (output.includes('different size')) {
    return null;
  }
  const tiles = new Map();
  for (const match of output.matchAll(/different tile: \((\d+), (\d+), (\d+)\)/g)) {
    const [x, y, z] = match.slice(1).map(Number);
    if (!tiles.has(z)) {
      tiles.set(z, []);
    }
    tiles.get(z).push([x, y]);
  }
  return tiles;
};

const overlaps = (a, b) => a.minX <= b.maxX + 1 && b.minX <= a.maxX + 1 && a.minY <= b.maxY + 1 && b.minY <= a.maxY + 1;

/** Padded boxes around the tiles, merged until no two of them touch. */
const regionsOf = (tiles, [width, height]) => {
  let boxes = tiles.map(([x, y]) => ({ minX: x - PADDING, minY: y - PADDING, maxX: x + PADDING, maxY: y + PADDING, changed: 1, tiles: [[x, y]] }));
  for (let merged = true; merged;) {
    merged = false;
    const next = [];
    for (const box of boxes) {
      const other = next.find((candidate) => overlaps(candidate, box));
      if (other) {
        other.minX = Math.min(other.minX, box.minX);
        other.minY = Math.min(other.minY, box.minY);
        other.maxX = Math.max(other.maxX, box.maxX);
        other.maxY = Math.max(other.maxY, box.maxY);
        other.changed += box.changed;
        other.tiles.push(...box.tiles);
        merged = true;
      }
      else {
        next.push({ ...box, tiles: [...box.tiles] });
      }
    }
    boxes = next;
  }
  return boxes.map((box) => {
    const region = {
      minX: Math.max(1, box.minX),
      minY: Math.max(1, box.minY),
      maxX: Math.min(width, box.maxX),
      maxY: Math.min(height, box.maxY),
      changed: box.changed,
      // A few coordinates help to find the change on the image.
      tiles: box.tiles.slice(0, MAX_LISTED_TILES),
      cropped: false,
    };
    for (const [min, max] of [['minX', 'maxX'], ['minY', 'maxY']]) {
      if (region[max] - region[min] + 1 > MAX_REGION_SIDE) {
        const middle = Math.floor((region[min] + region[max]) / 2);
        region[min] = middle - MAX_REGION_SIDE / 2 + 1;
        region[max] = middle + MAX_REGION_SIDE / 2;
        region.cropped = true;
      }
    }
    return region;
  });
};

const manifest = { maps: [] };
const renderFiles = [];
const pending = [];
changes.forEach(({ status, file }, index) => {
  const entry = { path: file, status, regions: [] };
  manifest.maps.push(entry);
  if (index >= MAX_MAPS) {
    entry.note = `не нарисована: больше ${MAX_MAPS} карт в одном PR`;
    return;
  }
  if (status === 'D') {
    entry.note = 'карта удалена';
    return;
  }
  const stem = `${index}-${path.basename(file, '.dmm').replace(/[^\w-]/g, '_')}`;
  const after = path.join(work, `${stem}.after.dmm`);
  fs.copyFileSync(file, after);
  const size = mapSize(after);
  let tiles = null;
  let before = null;
  if (status !== 'A') {
    before = path.join(work, `${stem}.before.dmm`);
    fs.writeFileSync(before, git('show', `${baseRef}:${file}`));
    tiles = changedTiles(before, after);
  }
  if (tiles === null) {
    // A new map, or one that changed its size: there is nothing to compare tile by tile.
    if (size[0] > MAX_WHOLE_MAP_SIDE || size[1] > MAX_WHOLE_MAP_SIDE) {
      entry.note = `${status === 'A' ? 'новая карта' : 'размер карты изменился'}, ${size[0]}x${size[1]} - слишком большая, чтобы рисовать целиком`;
      return;
    }
    entry.note = status === 'A' ? 'новая карта' : 'размер карты изменился, нарисована новая версия целиком';
    for (let z = 1; z <= size[2]; z++) {
      entry.regions.push({ z, minX: 1, minY: 1, maxX: size[0], maxY: size[1], changed: null, cropped: false });
    }
    before = null;
  }
  else {
    for (const [z, zTiles] of [...tiles].sort(([a], [b]) => a - b)) {
      entry.regions.push(...regionsOf(zTiles, size).map((region) => ({ z, ...region })));
    }
    entry.regions.sort((a, b) => b.changed - a.changed);
    if (entry.regions.length > MAX_REGIONS_PER_MAP) {
      entry.note = `нарисованы ${MAX_REGIONS_PER_MAP} участков из ${entry.regions.length}, с наибольшим числом изменений`;
      entry.regions.length = MAX_REGIONS_PER_MAP;
    }
    if (entry.regions.length === 0) {
      entry.note = 'клетки не изменились, только запись файла';
      return;
    }
  }
  const chunks = entry.regions.map(({ z, minX, minY, maxX, maxY }) => ({ z, min_x: minX, min_y: minY, max_x: maxX, max_y: maxY }));
  for (const [side, dmm] of [['after', after], ['before', before]]) {
    if (dmm) {
      renderFiles.push({ path: dmm, chunks });
      pending.push({ entry, side });
    }
  }
});

if (renderFiles.length > 0) {
  const command = JSON.stringify({ output_directory: work, files: renderFiles });
  const result = spawnSync(renderer, ['-e', 'tgstation.dme', 'render-many'], {
    input: command,
    encoding: 'utf-8',
    maxBuffer: 64 * 1024 * 1024,
    stdio: ['pipe', 'pipe', 'inherit'],
  });
  if (result.status !== 0) {
    console.error(`render-many failed with exit code ${result.status}`);
    process.exit(1);
  }
  // Warnings like "bad path: /obj/..." come first on stdout, the result is the last line.
  const resultLine = result.stdout.trim().split('\n').reverse().find((line) => line.startsWith('{'));
  JSON.parse(resultLine).files.forEach((file, fileIndex) => {
    const { entry, side } = pending[fileIndex];
    file.chunks.forEach((chunk, chunkIndex) => {
      const name = `${path.basename(String(chunk.filename), '.png').replace(/\.(before|after)_.*$/, '')}-z${entry.regions[chunkIndex].z}-${chunkIndex}-${side}.png`;
      fs.renameSync(path.join(work, String(chunk.filename)), path.join(images, name));
      entry.regions[chunkIndex][side] = `images/${name}`;
    });
  });
}
fs.rmSync(work, { recursive: true, force: true });
fs.writeFileSync(path.join(outputDirectory, 'manifest.json'), JSON.stringify(manifest, null, 1));

const summary = ['## Изменения карт', ''];
for (const entry of manifest.maps) {
  summary.push(`- \`${entry.path}\`: участков ${entry.regions.length}${entry.note ? `, ${entry.note}` : ''}`);
}
if (process.env.GITHUB_STEP_SUMMARY) {
  fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, summary.join('\n') + '\n\nКартинки появятся в комментарии к PR.\n');
}
console.log(summary.join('\n'));

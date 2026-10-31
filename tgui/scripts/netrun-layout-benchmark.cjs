/** Repeatable layout-only CPU benchmark; does not measure BYOND or WebGL. */
const assert = require('assert/strict');
const babel = require('@babel/core');
const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const { performance } = require('perf_hooks');
const root = path.resolve(__dirname, '../..');
const sourcePath = 'tgui/packages/tgui/interfaces/NetrunTerminal/graphLayout.ts';
const source = fs.readFileSync(path.join(root, sourcePath), 'utf8');
const baselineRef = process.argv[2] || 'HEAD';
const baseline = execFileSync('git', ['show', `${baselineRef}:${sourcePath}`], { cwd: root, encoding: 'utf8' });

function load(code) {
  const transformed = babel.transformSync(code, { filename: 'graphLayout.ts', configFile: false, babelrc: false,
    presets: [['@babel/preset-env', { targets: { node: 'current' } }], '@babel/preset-typescript'] }).code;
  const module = { exports: {} };
  new Function('module', 'exports', 'require', transformed)(module, module.exports, require);
  return module.exports;
}

function run(library, count, movers, iterations = 120) {
  const nodes = Array.from({ length: count }, (_, index) => ({ address: `N${String(index).padStart(6, '0')}`, type: 'implant',
    x: index % 100, y: Math.floor(index / 100), z: 1 }));
  const layout = new library.GraphLayout();
  const initial = layout.update(nodes, []);
  const samples = [];
  for (let step = 0; step < iterations + 15; step++) {
    for (let index = 0; index < movers; index++) {
      nodes[index] = { ...nodes[index], x: 120 + step % 20, y: 120 + Math.floor(index / 8) };
    }
    const start = performance.now();
    const points = layout.update(nodes, []);
    const elapsed = performance.now() - start;
    assert.equal(points.size, count);
    assert.equal(points.get(nodes[count - 1].address), initial.get(nodes[count - 1].address));
    if (step >= 15) { samples.push(elapsed); }
  }
  samples.sort((a, b) => a - b);
  return { mean_ms: samples.reduce((sum, value) => sum + value, 0) / samples.length,
    median_ms: samples[Math.floor(samples.length / 2)], p95_ms: samples[Math.floor(samples.length * .95)] };
}

const before = load(baseline), after = load(source);
for (const [nodes, movers] of [[6000, 3], [6000, 64], [20000, 128]]) {
  const previous = run(before, nodes, movers), current = run(after, nodes, movers);
  console.log(JSON.stringify({ nodes, movers, iterations: 120, baseline_ref: baselineRef, baseline: previous, current,
    mean_speedup: previous.mean_ms / current.mean_ms }));
}

#!/usr/bin/env node
/**
 * Statbrowser build script.
 *
 * Concatenates CSS and JS modules into a single html/statbrowser.html via
 * template.html. Each JS chunk is wrapped with a `// === src/foo.js ===`
 * banner and joined with `\n;\n` so accidental ASI hazards or trailing
 * line-comments in one source file cannot corrupt the next chunk.
 *
 * Pass --watch to rebuild on source changes.
 */

const fs = require('fs');
const path = require('path');

const ROOT = __dirname;
const OUTPUT = path.join(ROOT, '..', 'statbrowser.html');
const TEMPLATE = path.join(ROOT, 'template.html');

// CSS files in load order
const CSS_FILES = [
	'styles/base.css',
	'styles/tabs.css',
	'styles/search.css',
	'styles/content.css',
	'styles/settings.css',
];

// JS files in dependency order
const JS_FILES = [
	'src/constants.js',
	'src/bridge.js',
	'src/state.js',
	'src/dom-helpers.js',
	'src/tab-manager.js',
	'src/verb-manager.js',
	'src/theme-manager.js',
	'src/renderers.js',
	'src/sparkline.js',
	'src/renderers/status.js',
	'src/renderers/mc.js',
	'src/renderers/verbs.js',
	'src/renderers/favorites.js',
	'src/renderers/spells.js',
	'src/renderers/tickets.js',
	'src/renderers/sdql2.js',
	'src/renderers/debug.js',
	'src/renderers/turf.js',
	'src/zoom.js',
	'src/bridge-functions.js',
	'src/search.js',
	'src/settings-panel.js',
	'src/init.js',
];

function readFile(relPath) {
	const fullPath = path.join(ROOT, relPath);
	if (!fs.existsSync(fullPath)) {
		console.warn(`Warning: ${relPath} not found, skipping`);
		return '';
	}
	return fs.readFileSync(fullPath, 'utf8');
}

function buildJsBundle() {
	const chunks = [];
	for (const relPath of JS_FILES) {
		const body = readFile(relPath);
		if (!body) continue;
		chunks.push(`// === ${relPath.replace(/\\/g, '/')} ===\n${body}`);
	}
	// `\n;\n` defends against ASI quirks at chunk boundaries (an IIFE
	// after an expression-statement, an unterminated `// comment`, etc).
	return chunks.join('\n;\n');
}

function buildCssBundle() {
	return CSS_FILES.map(readFile).filter(Boolean).join('\n');
}

function build() {
	const template = fs.readFileSync(TEMPLATE, 'utf8');
	const css = buildCssBundle();
	const js = buildJsBundle();
	// Use function-form replace so `$&`, `$1`, `$$` in CSS/JS are not
	// reinterpreted by String.prototype.replace pattern semantics.
	let output = template.replace('/* __CSS_PLACEHOLDER__ */', () => css);
	output = output.replace('/* __JS_PLACEHOLDER__ */', () => js);
	fs.writeFileSync(OUTPUT, output, 'utf8');
	const lines = output.split('\n').length;
	console.log(`Built ${OUTPUT} (${lines} lines)`);
}

function watch() {
	build();
	const dirs = ['src', 'styles', '.'];
	const seen = new Set();
	let pending = null;
	const schedule = () => {
		if (pending) clearTimeout(pending);
		pending = setTimeout(() => {
			pending = null;
			try { build(); }
			catch (err) { console.error('[watch] build failed:', err.message); }
		}, 100);
	};
	for (const dir of dirs) {
		const full = path.join(ROOT, dir);
		if (!fs.existsSync(full)) continue;
		const watcher = fs.watch(full, { recursive: true }, (_event, filename) => {
			if (!filename) return;
			if (filename.endsWith('.html') && filename !== 'template.html') return;
			const key = path.join(dir, filename);
			if (seen.has(key)) return;
			seen.add(key);
			setTimeout(() => seen.delete(key), 50);
			schedule();
		});
		watcher.on('error', (err) => console.error('[watch]', err.message));
	}
	console.log('[watch] watching for changes (Ctrl+C to stop)');
}

if (process.argv.includes('--watch')) {
	watch();
} else {
	build();
}

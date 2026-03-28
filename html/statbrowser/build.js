#!/usr/bin/env node
/**
 * Statbrowser build script
 * Concatenates CSS and JS modules into a single html/statbrowser.html
 */

const fs = require('fs');
const path = require('path');

const ROOT = __dirname;
const OUTPUT = path.join(ROOT, '..', 'statbrowser.html');
const TEMPLATE = path.join(ROOT, 'template.html');

// CSS files in order
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

function build() {
	let template = fs.readFileSync(TEMPLATE, 'utf8');

	// Concatenate CSS
	const css = CSS_FILES.map(f => readFile(f)).filter(Boolean).join('\n');

	// Concatenate JS
	const js = JS_FILES.map(f => readFile(f)).filter(Boolean).join('\n');

	// Replace placeholders
	template = template.replace('/* __CSS_PLACEHOLDER__ */', css);
	template = template.replace('/* __JS_PLACEHOLDER__ */', js);

	fs.writeFileSync(OUTPUT, template, 'utf8');

	const lines = template.split('\n').length;
	console.log(`Built ${OUTPUT} (${lines} lines)`);
}

build();

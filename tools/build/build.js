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
import { DreamDaemon, DreamMaker } from './lib/byond.js';
import { yarn } from './lib/yarn.js';
import Juke from './juke/index.js';

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

export const DmTarget = new Juke.Target({
  dependsOn: ({ get }) => [
    get(DefineParameter).includes('ALL_MAPS') && DmMapsIncludeTarget,
  ],
  inputs: [
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
  parameters: [DefineParameter],
  executes: async ({ get }) => {
    const defines = get(DefineParameter);
    if (defines.length > 0) {
      Juke.logger.info('Using defines:', defines.join(', '));
    }
    await DreamMaker(`${DME_NAME}.dme`, {
      defines: ['CBT', ...defines],
    });
  },
});

export const DmTestTarget = new Juke.Target({
  dependsOn: ({ get }) => [
    get(DefineParameter).includes('ALL_MAPS') && DmMapsIncludeTarget,
  ],
  executes: async ({ get }) => {
    const defines = get(DefineParameter);
    if (defines.length > 0) {
      Juke.logger.info('Using defines:', defines.join(', '));
    }
    fs.copyFileSync(`${DME_NAME}.dme`, `${DME_NAME}.test.dme`);
    await DreamMaker(`${DME_NAME}.test.dme`, {
      defines: ['CBT', 'CIBUILDING', ...defines],
    });
    Juke.rm('data/logs/ci', { recursive: true });
    await DreamDaemon(
      `${DME_NAME}.test.dmb`,
      '-close', '-trusted', '-verbose',
      '-params', 'log-directory=ci'
    );
    Juke.rm('*.test.*');
    try {
      const cleanRun = fs.readFileSync('data/logs/ci/clean_run.lk', 'utf-8');
      console.log(cleanRun);
    }
    catch (err) {
      Juke.logger.error('Test run was not clean, exiting');
      throw new Juke.ExitCode(1);
    }
  },
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
  dependsOn: [YarnTarget],
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
  executes: async ({ args }) => {
    await yarn(
      'eslint', 'packages',
      '--fix', '--ext', '.js,.cjs,.ts,.tsx',
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
  dependsOn: [TguiTarget, TgFontTarget],
  executes: async () => {
    Juke.logger.info('Prepending TGS define');
    prependDefines('TGS');
  },
});

const TGS_MODE = process.env.CBT_BUILD_MODE === 'TGS';

export default TGS_MODE ? TgsTarget : BuildTarget;

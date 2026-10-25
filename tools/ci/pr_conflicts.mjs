#!/usr/bin/env node
// Finds merge conflicts of open PRs: with master (the Merge Conflict label) and with each other
// (a comment listing the PRs and files). Conflicts are computed by git merge-tree on fetched
// trees, no code of a PR runs. For two PRs, the second one is merged on top of master with the
// first one already merged, the way it happens when both get merged.
//
// Environment: GH_TOKEN, GITHUB_REPOSITORY, REMOTE (default origin), DRY_RUN=1 to only print.

import { spawnSync } from 'node:child_process';

const LABEL = 'Merge Conflict';
const MARKER = '<!-- pr-conflicts -->';
const REF_ROOT = 'refs/ci-conflicts';
const MAX_FILES_LISTED = 10;
// History is fetched shallow and deepened until every PR finds its merge base with master.
const FIRST_DEPTH = 300;
const DEEPEN_BY = 1000;
const MAX_DEEPENINGS = 5;

const { GH_TOKEN: token, GITHUB_REPOSITORY: repository, DRY_RUN: dryRun } = process.env;
const remote = process.env.REMOTE || 'origin';
if (!token || !repository) {
  console.error('GH_TOKEN and GITHUB_REPOSITORY are required');
  process.exit(2);
}

const git = (args, { allow = [0] } = {}) => {
  const result = spawnSync('git', args, { encoding: 'utf-8', maxBuffer: 256 * 1024 * 1024 });
  if (!allow.includes(result.status)) {
    throw new Error(`git ${args.join(' ')} exited with ${result.status}: ${result.stderr}`);
  }
  return result;
};

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

const write = async (description, method, url, body) => {
  console.log(`${dryRun ? '[dry run] ' : ''}${description}`);
  if (!dryRun) {
    await api(method, url, body);
  }
};

const pulls = (await paginate('/pulls?state=open')).filter((pull) => pull.base.ref === 'master');
console.log(`${pulls.length} open PRs into master`);

git(['config', `remote.${remote}.promisor`, 'true']);
git(['config', `remote.${remote}.partialclonefilter`, 'blob:none']);
const refspecs = [`+refs/heads/master:${REF_ROOT}/master`, ...pulls.map((pull) => `+refs/pull/${pull.number}/head:${REF_ROOT}/pr/${pull.number}`)];
git(['fetch', '--quiet', '--no-tags', '--filter=blob:none', `--depth=${FIRST_DEPTH}`, remote, ...refspecs]);
const master = `${REF_ROOT}/master`;
const head = (pull) => `${REF_ROOT}/pr/${pull.number}`;
const hasBase = (pull) => git(['merge-base', master, head(pull)], { allow: [0, 1] }).status === 0;
for (let attempt = 0; attempt < MAX_DEEPENINGS && !pulls.every(hasBase); attempt++) {
  git(['fetch', '--quiet', '--no-tags', '--filter=blob:none', `--deepen=${DEEPEN_BY}`, remote, ...refspecs]);
}

const mergeTree = (first, second) => {
  const result = git(['merge-tree', '--write-tree', '--name-only', '--no-messages', first, second], { allow: [0, 1] });
  const [tree, ...files] = result.stdout.trim().split('\n');
  return { clean: result.status === 0, tree, files: [...new Set(files.filter(Boolean))] };
};

const state = new Map();
for (const pull of pulls) {
  if (!hasBase(pull)) {
    console.log(`#${pull.number}: no merge base with master in the fetched history, skipped`);
    continue;
  }
  const merged = mergeTree(master, head(pull));
  const entry = { pull, masterConflict: !merged.clean, others: new Map() };
  if (merged.clean) {
    // The commit master would get after merging this PR.
    entry.merged = git(['commit-tree', merged.tree, '-p', master, '-p', head(pull), '-m', `merge #${pull.number}`]).stdout.trim();
    entry.files = new Set(git(['diff', '--name-only', `${master}...${head(pull)}`]).stdout.split('\n').filter(Boolean));
  }
  state.set(pull.number, entry);
}

// Only PRs that touch the same files can conflict with each other.
const clean = [...state.values()].filter((entry) => !entry.masterConflict);
for (let i = 0; i < clean.length; i++) {
  for (let j = i + 1; j < clean.length; j++) {
    const [first, second] = [clean[i], clean[j]];
    if (![...first.files].some((file) => second.files.has(file))) {
      continue;
    }
    const result = mergeTree(first.merged, head(second.pull));
    if (!result.clean) {
      first.others.set(second.pull.number, result.files);
      second.others.set(first.pull.number, result.files);
    }
  }
}

if (!dryRun) {
  try {
    await api('GET', `/labels/${encodeURIComponent(LABEL)}`);
  }
  catch {
    await api('POST', '/labels', { name: LABEL, color: 'b60205', description: 'Конфликтует с master' });
  }
}

const code = (file) => `\`${file.replace(/`/g, "'")}\``;
for (const entry of state.values()) {
  const { pull } = entry;
  const labeled = pull.labels.some((label) => label.name === LABEL);
  if (entry.masterConflict && !labeled) {
    await write(`#${pull.number}: conflicts with master, label added`, 'POST', `/issues/${pull.number}/labels`, { labels: [LABEL] });
  }
  else if (!entry.masterConflict && labeled) {
    await write(`#${pull.number}: no conflict with master any more, label removed`, 'DELETE', `/issues/${pull.number}/labels/${encodeURIComponent(LABEL)}`);
  }

  let body = null;
  if (entry.others.size > 0) {
    const lines = [...entry.others].sort(([a], [b]) => a - b).map(([number, files]) => {
      const listed = files.slice(0, MAX_FILES_LISTED).map(code).join(', ');
      const more = files.length > MAX_FILES_LISTED ? ` и ещё ${files.length - MAX_FILES_LISTED}` : '';
      return `- #${number}: ${listed}${more}`;
    });
    body = [MARKER, 'Этот PR конфликтует с другими открытыми PR: тому, кто вольётся вторым, придётся решать конфликт.', '', ...lines].join('\n');
  }
  const comments = await paginate(`/issues/${pull.number}/comments`);
  const previous = comments.find((comment) => comment.user?.type === 'Bot' && comment.body?.startsWith(MARKER));
  if (body && !previous) {
    await write(`#${pull.number}: conflicts with ${[...entry.others.keys()].map((n) => `#${n}`).join(', ')}, comment posted`, 'POST', `/issues/${pull.number}/comments`, { body });
  }
  else if (body && previous.body !== body) {
    await write(`#${pull.number}: conflicts changed, comment updated`, 'PATCH', `/issues/comments/${previous.id}`, { body });
  }
  else if (!body && previous) {
    await write(`#${pull.number}: no conflicts with other PRs any more, comment removed`, 'DELETE', `/issues/comments/${previous.id}`);
  }
}

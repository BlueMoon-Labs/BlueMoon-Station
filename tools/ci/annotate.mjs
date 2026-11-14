#!/usr/bin/env node
// Turns compiler output into GitHub annotations, so errors show up on the lines of the PR diff.
//
// Usage: node tools/ci/annotate.mjs dm|dreamchecker <log file>

import fs from 'node:fs';

const [format, logFile] = process.argv.slice(2);
// DreamChecker colors its output even into a file.
const lines = fs.readFileSync(logFile, 'utf-8').replace(/\x1b\[[0-9;]*m/g, '').split(/\r?\n/);

const escape = (text) => text.replace(/%/g, '%25').replace(/\r/g, '%0D').replace(/\n/g, '%0A');
const annotate = (severity, file, line, column, message) => {
  const level = severity === 'error' ? 'error' : 'warning';
  const position = [`file=${file.replace(/\\/g, '/')}`, `line=${line}`, column && `col=${column}`].filter(Boolean).join(',');
  console.log(`::${level} ${position}::${escape(message)}`);
};

let count = 0;
if (format === 'dm') {
  // code/foo.dm:12:error: message, code/foo.dm:12:warning (unused_var): message
  const pattern = /^(.+?\.dm[mei]?):(\d+):(error|warning)[^:]*: ?(.*)$/;
  for (const line of lines) {
    const match = pattern.exec(line);
    if (match) {
      annotate(match[3], match[1], match[2], null, match[4]);
      count++;
    }
  }
}
else if (format === 'dreamchecker') {
  // code/foo.dm, line 12, column 3:
  // error: message
  const location = /^(.+?), line (\d+), column (\d+):$/;
  const finding = /^(error|warning|hint|info): (.*)$/;
  for (let index = 0; index < lines.length - 1; index++) {
    const where = location.exec(lines[index]);
    const what = where && finding.exec(lines[index + 1]);
    if (what && (what[1] === 'error' || what[1] === 'warning')) {
      annotate(what[1], where[1], where[2], where[3], what[2]);
      count++;
    }
  }
}
else {
  console.error('Usage: annotate.mjs dm|dreamchecker <log file>');
  process.exit(2);
}
console.log(`${count} annotation(s) from ${logFile}`);

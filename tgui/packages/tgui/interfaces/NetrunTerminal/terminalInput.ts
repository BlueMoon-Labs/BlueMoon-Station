export type CompletionContext = {
  verb: string;
  argument: number;
  prefix: string;
  start: number;
  end: number;
};

/** Match the server's quotes and escapes, while allowing a quote still being typed. */
export const completionContext = (input: string, caret = input.length): CompletionContext => {
  const words: string[] = [];
  let token = '';
  let quote = '';
  let started = false;
  let start = 0;
  for (let index = 0; index < caret; index++) {
    const character = input[index];
    if (!started && !/\s/.test(character)) { start = index; started = true; }
    if (character === '\\') {
      if (index + 1 < caret) { token += input[++index]; }
    } else if (quote) {
      if (character === quote) { quote = ''; } else { token += character; }
    } else if (character === '"' || character === "'") {
      quote = character;
    } else if (/\s/.test(character)) {
      if (started) { words.push(token); token = ''; started = false; }
      start = index + 1;
    } else { token += character; }
  }
  let end = caret;
  // Replacing in the middle of a line preserves subsequent arguments, not stale token suffixes.
  for (; end < input.length; end++) {
    const character = input[end];
    if (character === '\\') { end++; }
    else if (quote) { if (character === quote) { quote = ''; } }
    else if (character === '"' || character === "'") { quote = character; }
    else if (/\s/.test(character)) { break; }
  }
  return { verb: (words[0] ?? token).toLowerCase(), argument: words.length,
    prefix: token, start, end: Math.min(end, input.length) };
};

export const quoteCliArgument = (value: string) => value && !/[\s"'\\]/.test(value)
  ? value : `"${value.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`;

export const matchingCompletions = (input: string, candidates: string[], caret = input.length) => {
  const context = completionContext(input, caret);
  return Array.from(new Set(candidates)).filter((candidate) => candidate.toLowerCase().startsWith(context.prefix.toLowerCase()));
};

export const insertCompletion = (input: string, candidate: string, caret = input.length) => {
  const context = completionContext(input, caret);
  const token = quoteCliArgument(candidate);
  const tail = input.slice(context.end);
  const separator = tail.startsWith(' ') ? '' : ' ';
  return { value: input.slice(0, context.start) + token + separator + tail,
    caret: context.start + token.length + separator.length };
};

export const commonCompletionPrefix = (values: string[]) => {
  let prefix = values[0] ?? '';
  for (const value of values) {
    while (prefix && !value.toLowerCase().startsWith(prefix.toLowerCase())) { prefix = prefix.slice(0, -1); }
  }
  return prefix;
};

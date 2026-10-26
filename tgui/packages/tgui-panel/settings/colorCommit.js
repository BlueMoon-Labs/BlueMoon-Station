// React's onChange fires continuously while dragging inside the color
// dialog; debounce so we do not rewrite stored settings on every tick.
// The value is taken at event time: a re-render resets the controlled input.
const colorCommitTimers = new WeakMap();

export const debouncedColorCommit = (input, commit) => {
  const value = input.value;
  clearTimeout(colorCommitTimers.get(input));
  colorCommitTimers.set(input, setTimeout(() => commit(value), 250));
};

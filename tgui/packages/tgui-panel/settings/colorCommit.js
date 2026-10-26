// React's onChange fires continuously while dragging inside the color
// dialog; debounce so we do not rewrite stored settings on every tick.
// The value is taken at event time: a re-render resets the controlled input.
const colorCommitTimers = new WeakMap();

export const debouncedColorCommit = (input, commit) => {
  const value = input.value;
  clearTimeout(colorCommitTimers.get(input));
  colorCommitTimers.set(input, setTimeout(() => commit(value), 250));
};

/**
 * Правки поверх последнего записанного значения, а не того, что захватил
 * рендер: запись цвета идёт с задержкой, и соседняя правка за это время
 * иначе теряется. sync - значение из стора на каждом рендере.
 */
export const createLatestEditor = commit => {
  let current;
  return {
    sync: value => {
      current = value;
    },
    update: change => {
      current = change(current);
      commit(current);
    },
  };
};

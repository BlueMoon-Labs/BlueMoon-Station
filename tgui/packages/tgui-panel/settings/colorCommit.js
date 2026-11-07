/**
 * Правки поверх последнего записанного значения, а не того, что захватил
 * рендер: до перерисовки из стора соседняя правка иначе затрёт предыдущую.
 * sync - значение из стора на каждом рендере.
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

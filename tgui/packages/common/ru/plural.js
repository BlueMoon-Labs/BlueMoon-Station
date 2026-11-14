/**
 * Функция для учёта множественных слов, для составления падежности в интерфейсах
 *
 */
export const plural = (n, one, few, many) => {
  if (!Number.isInteger(n)) {
    return few;
  }
  const mod100 = Math.abs(n) % 100;
  const mod10 = mod100 % 10;
  if (mod100 > 10 && mod100 < 20) {
    return many;
  }
  if (mod10 === 1) {
    return one;
  }
  return mod10 >= 2 && mod10 <= 4 ? few : many;
};

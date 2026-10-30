// Разделяю вкладки внешности, простите.
// https://www.youtube.com/shorts/RDu7GFQjHGY
export type AppearanceSubTab = 'body' | 'parts' | 'genitals';

let current: AppearanceSubTab = 'body';
const listeners = new Set<() => void>();

export const getAppearanceSubTab = (): AppearanceSubTab => current;

export const setAppearanceSubTab = (next: AppearanceSubTab) => {
  if (current === next) {
    return;
  }
  current = next;
  listeners.forEach((listener) => listener());
};

export const subscribeAppearanceSubTab = (listener: () => void) => {
  listeners.add(listener);
  return () => {
    listeners.delete(listener);
  };
};

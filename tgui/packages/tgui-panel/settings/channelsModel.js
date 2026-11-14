import { createLatestEditor } from './colorCommit';
import { RECOMMENDED_TYPE_OVERRIDES } from './constants';

// Пустые и выключенные поля не хранятся, пустая запись удаляется целиком.
export const patchTypeOverride = (overrides, type, patch) => {
  const merged = { ...(overrides?.[type] || {}), ...patch };
  const entry = {};
  for (const [key, value] of Object.entries(merged)) {
    if (value !== '' && value !== false && value !== undefined
      && value !== null) {
      entry[key] = value;
    }
  }
  // Подложка красится цветом полоски: без полоски ей не быть.
  if (!entry.border) {
    delete entry.tint;
  }
  const { [type]: _old, ...rest } = overrides || {};
  return Object.keys(entry).length > 0 ? { ...rest, [type]: entry } : rest;
};

/** Убирает подложку без полоски из старых сохранений и кодов. */
export const dropStrayTint = overrides => {
  let next = overrides;
  for (const [type, entry] of Object.entries(overrides || {})) {
    if (entry && typeof entry === 'object' && 'tint' in entry && !entry.border) {
      next = patchTypeOverride(next, type, {});
    }
  }
  return next;
};

export const resetTypeOverride = (overrides, type) => {
  const { [type]: _removed, ...rest } = overrides || {};
  return rest;
};

export const isEntryEdited = entry => !!entry
  && (!!entry.border || !!entry.anim || entry.flash === true);

export const applyRecommended = overrides => {
  let next = { ...overrides };
  for (const [type, patch] of Object.entries(RECOMMENDED_TYPE_OVERRIDES)) {
    next = patchTypeOverride(next, type, patch);
  }
  return next;
};

/** Редактор вкладки "Каналы" поверх createLatestEditor. */
export const createChannelEditor = commit => {
  const latest = createLatestEditor(commit);
  return {
    sync: overrides => latest.sync(overrides || {}),
    patch: (type, patch) => latest.update(
      current => patchTypeOverride(current, type, patch)),
    reset: type => latest.update(current => resetTypeOverride(current, type)),
    recommended: () => latest.update(applyRecommended),
    clear: () => latest.update(() => ({})),
  };
};

export const name_text_limits = {
  min : 2,
  max : 40,
} as const;

export const decs_text_limits = {
  min : 0,
  max : 8192,
} as const;

export const digestModeToColor = {
  Default: undefined,
  Hold: undefined,
  Digest: 'red',
  Absorb: 'purple',
  Unabsorb: 'purple',
  Shrink: 'teal',
  Grow: 'teal',
} as const;


export const my_belly_flags = {
  item_digest_logs : (1 << 1),
} as const;


export const statesUI = {
  STATE_UNSAVED_CHANGES : (1 << 1),
  STATE_SHOW_PICTURES : (1 << 2),
};
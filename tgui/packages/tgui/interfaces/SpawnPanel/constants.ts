export const SPAWN_LOCATIONS = [
  'Под существом',
  'Под существом дроп-подом',
  'Под существом телепортацией',
  'В ваших руках/лапах',
  'На маркированном объекте',
  'В маркированном объекте',
  'Таргетная локация',
  'Таргетная локация дроп-подом',
  'В руках/лапах выбранного существа',
  'В сумке выбранного существа',
] as const;

export const SPAWN_LOCATION_ICONS: Record<string, string> = {
  'Под существом': 'map-marker',
  'Под существом дроп-подом': 'box',
  'Под существом телепортацией': 'magic',
  'В ваших руках/лапах': 'hand-paper',
  'На маркированном объекте': 'bookmark',
  'В маркированном объекте': 'box-open',
  'Таргетная локация': 'crosshairs',
  'Таргетная локация дроп-подом': 'satellite',
  'В руках/лапах выбранного существа': 'user',
  'В сумке выбранного существа': 'backpack',
};

export const TAB_TYPES = ['Objects', 'Turfs', 'Mobs'] as const;

export const TAB_TYPE_COLORS: Record<string, string> = {
  Objects: '#4a9fd4',
  Turfs: '#7dba5e',
  Mobs: '#d47a4a',
};

export const TAB_TYPE_LETTERS: Record<string, string> = {
  Objects: 'O',
  Turfs: 'T',
  Mobs: 'M',
};

// BYOND direction constants (bitmask)
export const DIR_SOUTH = 1;
export const DIR_NORTH = 2;
export const DIR_EAST  = 4;
export const DIR_WEST  = 8;

// Order for slider: index 0=South, 1=North, 2=East, 3=West
export const DIR_SLIDER_ORDER = [DIR_SOUTH, DIR_NORTH, DIR_EAST, DIR_WEST];

export const DIR_NAMES: Record<number, string> = {
  [DIR_SOUTH]: 'South',
  [DIR_NORTH]: 'North',
  [DIR_EAST]:  'East',
  [DIR_WEST]:  'West',
};

export const DIR_ICONS: Record<number, string> = {
  [DIR_SOUTH]: 'arrow-down',
  [DIR_NORTH]: 'arrow-up',
  [DIR_EAST]:  'arrow-right',
  [DIR_WEST]:  'arrow-left',
};

export const PRECISE_MODE_OFF    = 'Off';
export const PRECISE_MODE_TARGET = 'Target';
export const PRECISE_MODE_COPY   = 'Copy';

export const OFFSET_ABSOLUTE = 'Absolute offset';
export const OFFSET_RELATIVE = 'Relative offset';

export const LOCATIONS_NEEDING_CLICK = [
  'Таргетная локация',
  'Таргетная локация дроп-подом',
  'В руках/лапах выбранного существа',
  'В сумке выбранного существа',
];

export const MAX_ATOM_DISPLAY = 200;

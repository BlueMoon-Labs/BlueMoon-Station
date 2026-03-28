export const name_text_limits = {
  min : 2,
  max : 40,
} as const;

export const decs_text_limits = {
  min : 0,
  max : 8192,
} as const;

export const damage_limits = {
  min : 0.1,
  max : 30,
} as const;

export const chance_limit = {
  min : 0,
  max : 100,
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
  STATE_SHOW_PICTURES   : (1 << 2),
} as const;

export const modifersFlags = {
   DM_FLAG_NUMBING      : (1<<0),
   DM_FLAG_STRIPPING    : (1<<1),
   DM_FLAG_LEAVEREMAINS	: (1<<2),
   DM_FLAG_THICKBELLY   : (1<<3),
   DM_FLAG_AFFECTWORN   : (1<<4),
   DM_FLAG_JAMSENSORS   : (1<<5),
   DM_FLAG_FORCEPSAY    : (1<<6),
   DM_FLAG_SPARELIMB    : (1<<7),
   DM_FLAG_SLOWBODY		  : (1<<8),
   DM_FLAG_MUFFLEITEMS	: (1<<9),
   DM_FLAG_TURBOMODE		: (1<<10),
   DM_FLAG_ABSORBEDVORE	: (1<<11),
   DM_FLAG_WETTENS			: (1<<12),
} as const;

export const dmModeToColor = {
  "Default"         : undefined,
  "Hold"            : undefined,
  "Hold Absorbed"   : "#6b187b",
  "Digest"          : "red",
  "Absorb"          : "purple",
  "Unabsorb"        : "purple",
};


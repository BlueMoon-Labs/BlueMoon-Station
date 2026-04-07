export type AtomData = {
  name: string;
  type: 'Objects' | 'Turfs' | 'Mobs';
  iconid: string | null;
};

export type SpawnPanelData = {
  selected_object: string | null;
  selected_icon: string | null; // base64 PNG of selected atom, generated server-side
  atom_name: string | null;
  atom_amount: number;
  atom_dir: number;
  offset: [number, number, number];
  offset_type: string;
  where_target_type: string;
  precise_mode: string;
};

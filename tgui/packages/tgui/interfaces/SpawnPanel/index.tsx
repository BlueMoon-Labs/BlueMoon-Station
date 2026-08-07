import { useState } from 'react';

import { resolveAsset } from '../../assets';
import { Box } from '../../components';
import { Window } from '../../layouts';
import { CreateObject } from './CreateObject';
import { CreateObjectSettings } from './CreateObjectSettings';
import { AtomData } from './types';

let cachedAtoms: Record<string, AtomData> | null = null;
let fetchInProgress = false;

export const SpawnPanel = (props: any) => {
  const [atoms, setAtoms] = useState<Record<string, AtomData> | null>(
    cachedAtoms
  );
  const [error, setError] = useState<string | null>(null);

  if (!atoms && !error) {
    if (cachedAtoms) {
      setAtoms(cachedAtoms);
    } else if (!fetchInProgress) {
      fetchInProgress = true;
      fetch(resolveAsset('spawnpanel_atom_data.json'))
        .then(r => {
          if (!r.ok) throw new Error(`HTTP ${r.status}`);
          return r.json();
        })
        .then(json => {
          cachedAtoms = json['atoms'] || {};
          fetchInProgress = false;
          setAtoms(cachedAtoms);
        })
        .catch(err => {
          fetchInProgress = false;
          setError(String(err));
        });
    }
  }

  return (
    <Window title="Сотворить хуйню" width={540} height={620} theme="admin">
      <Window.Content style={{ 'padding': '0', 'display': 'flex', flexDirection: 'column' }}>
        {error && (
          <Box color="bad" p={1} style={{ flexShrink: '0' }}>
            Failed to load atom list: {error}
          </Box>
        )}
        {!atoms && !error && (
          <Box
            style={{
              'flex': '1',
              'display': 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              'color': 'rgba(255,255,255,0.3)',
              fontSize: '13px',
            }}
          >
            Loading atom data...
          </Box>
        )}
        {atoms && (
          <Box style={{ 'display': 'flex', flexDirection: 'column', 'height': '100%' }}>
            <Box style={{ flexShrink: '0' }}>
              <CreateObjectSettings />
            </Box>
            <Box style={{ 'flex': '1', 'overflow': 'hidden' }}>
              <CreateObject atoms={atoms} />
            </Box>
          </Box>
        )}
      </Window.Content>
    </Window>
  );
};

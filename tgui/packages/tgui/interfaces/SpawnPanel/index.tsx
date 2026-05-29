import { resolveAsset } from '../../assets';
import { useLocalState } from '../../backend';
import { Box, Stack } from '../../components';
import { Window } from '../../layouts';

import { CreateObject } from './CreateObject';
import { CreateObjectSettings } from './CreateObjectSettings';
import { AtomData } from './types';

let cachedAtoms: Record<string, AtomData> | null = null;
let fetchInProgress = false;

export const SpawnPanel = (props: any, context: any) => {
  const [atoms, setAtoms] = useLocalState<Record<string, AtomData> | null>(
    context, 'sp_atoms', cachedAtoms
  );
  const [error, setError] = useLocalState<string | null>(
    context, 'sp_error', null
  );

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
      <Window.Content style={{ 'padding': '0', 'display': 'flex', 'flex-direction': 'column' }}>
        {error && (
          <Box color="bad" p={1} style={{ 'flex-shrink': '0' }}>
            Failed to load atom list: {error}
          </Box>
        )}
        {!atoms && !error && (
          <Box
            style={{
              'flex': '1',
              'display': 'flex',
              'align-items': 'center',
              'justify-content': 'center',
              'color': 'rgba(255,255,255,0.3)',
              'font-size': '13px',
            }}
          >
            Loading atom data...
          </Box>
        )}
        {atoms && (
          <Box style={{ 'display': 'flex', 'flex-direction': 'column', 'height': '100%' }}>
            <Box style={{ 'flex-shrink': '0' }}>
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

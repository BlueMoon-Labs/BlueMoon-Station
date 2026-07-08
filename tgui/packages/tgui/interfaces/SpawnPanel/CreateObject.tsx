import { classes } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../../backend';
import { Box, Button, Icon, Input, Stack } from '../../components';
import { LOCATIONS_NEEDING_CLICK, MAX_ATOM_DISPLAY, PRECISE_MODE_OFF, PRECISE_MODE_TARGET, TAB_TYPE_COLORS, TAB_TYPE_LETTERS, TAB_TYPES } from './constants';
import { AtomData, SpawnPanelData } from './types';

type CreateObjectProps = {
  atoms: Record<string, AtomData>;
};

export const CreateObject = (props: CreateObjectProps) => {
  const { act, data } = useBackend<SpawnPanelData>();
  const { selected_object, where_target_type = '', precise_mode = PRECISE_MODE_OFF } = data;
  const { atoms } = props;

  const [activeTab, setActiveTab] = useState<string>('Objects');
  const [searchText, setSearchText] = useState<string>('');
  const [searchByType, setSearchByType] = useState<boolean>(false);

  const hasSearch = searchText.length > 0;
  const lower = searchText.toLowerCase();

  let tabTotal = 0;
  const allEntries = Object.entries(atoms);
  for (let i = 0; i < allEntries.length; i++) {
    if (allEntries[i][1].type === activeTab) tabTotal++;
  }

  const filteredAtoms: Array<[string, AtomData]> = [];
  if (hasSearch) {
    for (let i = 0; i < allEntries.length && filteredAtoms.length < MAX_ATOM_DISPLAY; i++) {
      const [typepath, atom] = allEntries[i];
      if (atom.type !== activeTab) continue;
      const match = searchByType
        ? typepath.toLowerCase().includes(lower)
        : atom.name.toLowerCase().includes(lower) || typepath.toLowerCase().includes(lower);
      if (match) filteredAtoms.push([typepath, atom]);
    }
  }

  return (
    <Box
      style={{
        'display': 'flex',
        flexDirection: 'column',
        'height': '100%',
        'overflow': 'hidden',
      }}
    >
      {/* ─── Header: tabs + search ─── */}
      <Box
        style={{
          'background': 'rgba(0,0,0,0.2)',
          borderBottom: '1px solid rgba(255,255,255,0.07)',
          'padding': '4px 8px',
          flexShrink: '0',
        }}
      >
        <Stack align="center" spacing={1}>
          {/* Tabs */}
          <Stack.Item>
            <Stack spacing="2px" align="center">
              {TAB_TYPES.map(tab => {
                const active = activeTab === tab;
                return (
                  <Stack.Item key={tab}>
                    <Box
                      as="span"
                      style={{
                        'display': 'inline-flex',
                        alignItems: 'center',
                        'gap': '4px',
                        'padding': '3px 8px',
                        borderRadius: '4px',
                        'cursor': 'pointer',
                        fontSize: '12px',
                        fontWeight: active ? 'bold' : 'normal',
                        'background': active ? TAB_TYPE_COLORS[tab] : 'rgba(255,255,255,0.05)',
                        'color': active ? '#fff' : 'rgba(255,255,255,0.5)',
                        'border': active ? `1px solid ${TAB_TYPE_COLORS[tab]}` : '1px solid rgba(255,255,255,0.1)',
                        'transition': 'all 0.1s',
                        userSelect: 'none',
                      }}
                      onClick={() => { setActiveTab(tab); setSearchText(''); }}
                    >
                      <Box
                        as="span"
                        style={{
                          fontSize: '10px',
                          fontWeight: 'bold',
                          'opacity': active ? '1' : '0.7',
                        }}
                      >
                        {TAB_TYPE_LETTERS[tab]}
                      </Box>
                      {tab}
                    </Box>
                  </Stack.Item>
                );
              })}
            </Stack>
          </Stack.Item>

          <Stack.Item grow={1} />

          {/* Search mode toggle */}
          <Stack.Item>
            <Button
              compact
              selected={searchByType}
              tooltip={searchByType ? 'Searching by typepath' : 'Searching by name'}
              onClick={() => setSearchByType(!searchByType)}
              style={{ fontSize: '11px' }}
            >
              {searchByType ? 'Path' : 'Name'}
            </Button>
          </Stack.Item>

          {/* Search input */}
          <Stack.Item>
            <Input
              placeholder="Search..."
              value={searchText}
              width="140px"
              onInput={(_e: any, val: string) => setSearchText(val)}
            />
          </Stack.Item>
        </Stack>
      </Box>

      {/* ─── List body ─── */}
      <Box style={{ 'flex': '1', overflowY: 'auto', overflowX: 'hidden' }}>
        {!hasSearch && (
          <Box
            style={{
              textAlign: 'center',
              'padding': '24px 12px',
              'color': 'rgba(255,255,255,0.3)',
              fontSize: '12px',
              userSelect: 'none',
            }}
          >
            <Icon name="search" mb={1} style={{ fontSize: '18px', 'display': 'block' }} />
            {tabTotal.toLocaleString()} {activeTab.toLowerCase()} — begin typing to search
          </Box>
        )}

        {hasSearch && filteredAtoms.length === 0 && (
          <Box
            style={{
              textAlign: 'center',
              'padding': '24px 12px',
              'color': 'rgba(255,100,100,0.6)',
              fontSize: '12px',
            }}
          >
            <Icon name="times-circle" mb={1} style={{ fontSize: '18px', 'display': 'block' }} />
            No results for &quot;{searchText}&quot;
          </Box>
        )}

        {hasSearch && filteredAtoms.length > 0 && (
          <>
            {filteredAtoms.length >= MAX_ATOM_DISPLAY && (
              <Box
                style={{
                  'padding': '3px 10px',
                  fontSize: '10px',
                  'color': 'rgba(255,180,0,0.7)',
                  'background': 'rgba(255,180,0,0.05)',
                  borderBottom: '1px solid rgba(255,180,0,0.15)',
                }}
              >
                <Icon name="exclamation-triangle" mr={1} />
                Showing first {MAX_ATOM_DISPLAY} results — refine your search
              </Box>
            )}
            {filteredAtoms.map(([typepath, atom]) => (
              <AtomRow
                key={typepath}
                typepath={typepath}
                atom={atom}
                selected={selected_object === typepath}
                onSelect={() => act('selected-atom-changed', { newObj: typepath })}
                onSpawn={() => {
                  if (LOCATIONS_NEEDING_CLICK.includes(where_target_type)) {
                    act('toggle-precise-mode', {
                      newPreciseType: precise_mode === PRECISE_MODE_TARGET ? PRECISE_MODE_OFF : PRECISE_MODE_TARGET,
                    });
                  } else {
                    act('create-atom-action', { selected_atom: typepath });
                  }
                }}
              />
            ))}
          </>
        )}
      </Box>
    </Box>
  );
};

type AtomRowProps = {
  typepath: string;
  atom: AtomData;
  selected: boolean;
  onSelect: () => void;
  onSpawn: () => void;
};

const AtomRow = (props: AtomRowProps) => {
  const { typepath, atom, selected, onSelect, onSpawn } = props;
  const color = TAB_TYPE_COLORS[atom.type] ?? '#666';
  const letter = TAB_TYPE_LETTERS[atom.type] ?? '?';

  return (
    <Box
      style={{
        'display': 'flex',
        alignItems: 'center',
        'padding': '4px 8px',
        'cursor': 'pointer',
        'background': selected
          ? 'rgba(0,200,100,0.12)'
          : 'transparent',
        borderLeft: selected
          ? '3px solid #00c864'
          : `3px solid transparent`,
        borderBottom: '1px solid rgba(255,255,255,0.04)',
        'transition': 'background 0.08s',
        'gap': '8px',
      }}
      onClick={onSelect}
      onDoubleClick={onSpawn}
    >
      {/* Sprite or letter badge */}
      <Box
        style={{
          'width': '24px',
          'height': '24px',
          flexShrink: '0',
          'position': 'relative',
          'overflow': 'hidden',
          borderRadius: '3px',
          'background': atom.iconid ? 'transparent' : color,
          'display': 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        {atom.iconid ? (
          <span
            className={classes(['spawnpanel32x32', atom.iconid])}
            style={{
              'display': 'block',
              'transform': 'scale(0.75)',
              transformOrigin: 'top left',
              imageRendering: 'pixelated',
              'position': 'absolute',
              'top': '0',
              'left': '0',
            }}
          />
        ) : (
          <Box
            style={{
              fontSize: '11px',
              fontWeight: 'bold',
              'color': '#fff',
              lineHeight: '1',
            }}
          >
            {letter}
          </Box>
        )}
      </Box>

      {/* Name + path */}
      <Box style={{ 'flex': '1', 'overflow': 'hidden', minWidth: '0' }}>
        <Box
          style={{
            fontSize: '12px',
            fontWeight: selected ? 'bold' : 'normal',
            'color': selected ? '#00e87a' : 'rgba(255,255,255,0.9)',
            whiteSpace: 'nowrap',
            'overflow': 'hidden',
            textOverflow: 'ellipsis',
            lineHeight: '1.35',
          }}
        >
          {atom.name}
        </Box>
        <Box
          style={{
            fontSize: '10px',
            'color': 'rgba(255,255,255,0.3)',
            whiteSpace: 'nowrap',
            'overflow': 'hidden',
            textOverflow: 'ellipsis',
            lineHeight: '1.2',
          }}
        >
          {typepath}
        </Box>
      </Box>

      {/* Selected hint */}
      {selected && (
        <Box
          style={{
            flexShrink: '0',
            fontSize: '10px',
            'color': 'rgba(0,200,100,0.5)',
            whiteSpace: 'nowrap',
          }}
        >
          dbl=spawn
        </Box>
      )}
    </Box>
  );
};

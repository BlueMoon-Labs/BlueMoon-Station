import { classes } from 'common/react';
import { useBackend, useLocalState } from '../../backend';
import { Box, Button, Icon, Input, NoticeBox, Section, Stack, Tabs } from '../../components';

import { MAX_ATOM_DISPLAY, LOCATIONS_NEEDING_CLICK, PRECISE_MODE_OFF, PRECISE_MODE_TARGET, TAB_TYPE_COLORS, TAB_TYPE_LETTERS, TAB_TYPES } from './constants';
import { AtomData, SpawnPanelData } from './types';

type CreateObjectProps = {
  atoms: Record<string, AtomData>;
};

export const CreateObject = (props: CreateObjectProps, context: any) => {
  const { act, data } = useBackend<SpawnPanelData>(context);
  const { selected_object, where_target_type = '', precise_mode = PRECISE_MODE_OFF } = data;
  const { atoms } = props;

  const [activeTab, setActiveTab] = useLocalState<string>(context, 'sp_tab', 'Objects');
  const [searchText, setSearchText] = useLocalState<string>(context, 'sp_search', '');
  const [searchByType, setSearchByType] = useLocalState<boolean>(context, 'sp_bytype', false);

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
        'flex-direction': 'column',
        'height': '100%',
        'overflow': 'hidden',
      }}
    >
      {/* ─── Header: tabs + search ─── */}
      <Box
        style={{
          'background': 'rgba(0,0,0,0.2)',
          'border-bottom': '1px solid rgba(255,255,255,0.07)',
          'padding': '4px 8px',
          'flex-shrink': '0',
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
                        'align-items': 'center',
                        'gap': '4px',
                        'padding': '3px 8px',
                        'border-radius': '4px',
                        'cursor': 'pointer',
                        'font-size': '12px',
                        'font-weight': active ? 'bold' : 'normal',
                        'background': active ? TAB_TYPE_COLORS[tab] : 'rgba(255,255,255,0.05)',
                        'color': active ? '#fff' : 'rgba(255,255,255,0.5)',
                        'border': active ? `1px solid ${TAB_TYPE_COLORS[tab]}` : '1px solid rgba(255,255,255,0.1)',
                        'transition': 'all 0.1s',
                        'user-select': 'none',
                      }}
                      onClick={() => { setActiveTab(tab); setSearchText(''); }}
                    >
                      <Box
                        as="span"
                        style={{
                          'font-size': '10px',
                          'font-weight': 'bold',
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
              style={{ 'font-size': '11px' }}
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
      <Box style={{ 'flex': '1', 'overflow-y': 'auto', 'overflow-x': 'hidden' }}>
        {!hasSearch && (
          <Box
            style={{
              'text-align': 'center',
              'padding': '24px 12px',
              'color': 'rgba(255,255,255,0.3)',
              'font-size': '12px',
              'user-select': 'none',
            }}
          >
            <Icon name="search" mb={1} style={{ 'font-size': '18px', 'display': 'block' }} />
            {tabTotal.toLocaleString()} {activeTab.toLowerCase()} — begin typing to search
          </Box>
        )}

        {hasSearch && filteredAtoms.length === 0 && (
          <Box
            style={{
              'text-align': 'center',
              'padding': '24px 12px',
              'color': 'rgba(255,100,100,0.6)',
              'font-size': '12px',
            }}
          >
            <Icon name="times-circle" mb={1} style={{ 'font-size': '18px', 'display': 'block' }} />
            No results for &quot;{searchText}&quot;
          </Box>
        )}

        {hasSearch && filteredAtoms.length > 0 && (
          <>
            {filteredAtoms.length >= MAX_ATOM_DISPLAY && (
              <Box
                style={{
                  'padding': '3px 10px',
                  'font-size': '10px',
                  'color': 'rgba(255,180,0,0.7)',
                  'background': 'rgba(255,180,0,0.05)',
                  'border-bottom': '1px solid rgba(255,180,0,0.15)',
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
        'align-items': 'center',
        'padding': '4px 8px',
        'cursor': 'pointer',
        'background': selected
          ? 'rgba(0,200,100,0.12)'
          : 'transparent',
        'border-left': selected
          ? '3px solid #00c864'
          : `3px solid transparent`,
        'border-bottom': '1px solid rgba(255,255,255,0.04)',
        'transition': 'background 0.08s',
        'gap': '8px',
      }}
      onClick={onSelect}
      onDblClick={onSpawn}
    >
      {/* Sprite or letter badge */}
      <Box
        style={{
          'width': '24px',
          'height': '24px',
          'flex-shrink': '0',
          'position': 'relative',
          'overflow': 'hidden',
          'border-radius': '3px',
          'background': atom.iconid ? 'transparent' : color,
          'display': 'flex',
          'align-items': 'center',
          'justify-content': 'center',
        }}
      >
        {atom.iconid ? (
          <span
            className={classes(['spawnpanel32x32', atom.iconid])}
            style={{
              'display': 'block',
              'transform': 'scale(0.75)',
              'transform-origin': 'top left',
              'image-rendering': 'pixelated',
              'position': 'absolute',
              'top': '0',
              'left': '0',
            }}
          />
        ) : (
          <Box
            style={{
              'font-size': '11px',
              'font-weight': 'bold',
              'color': '#fff',
              'line-height': '1',
            }}
          >
            {letter}
          </Box>
        )}
      </Box>

      {/* Name + path */}
      <Box style={{ 'flex': '1', 'overflow': 'hidden', 'min-width': '0' }}>
        <Box
          style={{
            'font-size': '12px',
            'font-weight': selected ? 'bold' : 'normal',
            'color': selected ? '#00e87a' : 'rgba(255,255,255,0.9)',
            'white-space': 'nowrap',
            'overflow': 'hidden',
            'text-overflow': 'ellipsis',
            'line-height': '1.35',
          }}
        >
          {atom.name}
        </Box>
        <Box
          style={{
            'font-size': '10px',
            'color': 'rgba(255,255,255,0.3)',
            'white-space': 'nowrap',
            'overflow': 'hidden',
            'text-overflow': 'ellipsis',
            'line-height': '1.2',
          }}
        >
          {typepath}
        </Box>
      </Box>

      {/* Selected hint */}
      {selected && (
        <Box
          style={{
            'flex-shrink': '0',
            'font-size': '10px',
            'color': 'rgba(0,200,100,0.5)',
            'white-space': 'nowrap',
          }}
        >
          dbl=spawn
        </Box>
      )}
    </Box>
  );
};

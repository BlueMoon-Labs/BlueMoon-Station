import { useBackend } from '../../backend';
import { Box, Button, Dropdown, Icon, Input, NumberInput, Section, Slider, Stack, Table } from '../../components';

import {
  DIR_ICONS,
  DIR_NAMES,
  DIR_SLIDER_ORDER,
  LOCATIONS_NEEDING_CLICK,
  OFFSET_ABSOLUTE,
  OFFSET_RELATIVE,
  PRECISE_MODE_COPY,
  PRECISE_MODE_OFF,
  PRECISE_MODE_TARGET,
  SPAWN_LOCATION_ICONS,
  SPAWN_LOCATIONS,
  TAB_TYPE_COLORS,
} from './constants';
import { SpawnPanelData } from './types';

const PLACEHOLDER_ICON = 'data:image/gif;base64,R0lGODlhIAAgAIAAAAAAAP///yH5BAAAAAAALAAAAAAgACAAAAIxhI+py+0Po5y02oszNrz7D4biSJbmiabqyrbuC8fyTNf2jef6zvf+DwwKh8Si8YhKAAA7';

function dirToIdx(dir: number): number {
  const idx = DIR_SLIDER_ORDER.indexOf(dir);
  return idx >= 0 ? idx : 0;
}

function idxToDir(idx: number): number {
  return DIR_SLIDER_ORDER[idx] ?? DIR_SLIDER_ORDER[0];
}

export const CreateObjectSettings = (props: any, context: any) => {
  const { act, data } = useBackend<SpawnPanelData>(context);
  const {
    selected_object,
    selected_icon,
    atom_name,
    atom_desc,
    atom_amount = 1,
    atom_dir = 2,
    offset = [0, 0, 0],
    offset_type = OFFSET_RELATIVE,
    where_target_type = SPAWN_LOCATIONS[0],
    precise_mode = PRECISE_MODE_OFF,
  } = data;

  const ox: number = (offset as any)[0] ?? 0;
  const oy: number = (offset as any)[1] ?? 0;
  const oz: number = (offset as any)[2] ?? 0;

  const dirIdx = dirToIdx(atom_dir);
  const needsClick = LOCATIONS_NEEDING_CLICK.includes(where_target_type);
  const locationIcon = SPAWN_LOCATION_ICONS[where_target_type] ?? 'map-marker';

  const displayName = selected_object
    ? selected_object.split('/').filter(Boolean).pop() ?? selected_object
    : null;

  function send(partial: object) {
    act('update-settings', {
      where_target_type,
      atom_amount,
      atom_name,
      atom_desc,
      atom_dir,
      offset: [ox, oy, oz],
      offset_type,
      ...partial,
    });
  }

  function togglePrecise(mode: string) {
    act('toggle-precise-mode', {
      newPreciseType: precise_mode === mode ? PRECISE_MODE_OFF : mode,
    });
  }

  function handleOffsetInput(_e: any, val: string) {
    const parts = val.split(',').map(s => parseInt(s.trim(), 10));
    send({
      offset: [
        isNaN(parts[0]) ? 0 : parts[0],
        isNaN(parts[1]) ? 0 : parts[1],
        isNaN(parts[2]) ? 0 : parts[2],
      ],
    });
  }

  return (
    <Box
      style={{
        'background': 'rgba(0,0,0,0.25)',
        'border-bottom': '1px solid rgba(255,255,255,0.07)',
        'padding': '6px 8px',
      }}
    >
      {/* ─── Selected atom header ─── */}
      <Stack align="center" mb="6px" spacing={1}>
        {/* Icon preview */}
        <Stack.Item>
          <Box
            as="img"
            src={selected_icon || PLACEHOLDER_ICON}
            style={{
              'width': '48px',
              'height': '48px',
              'image-rendering': 'pixelated',
              'background': 'rgba(0,0,0,0.45)',
              'border-radius': '6px',
              'border': selected_object
                ? '2px solid rgba(0,200,100,0.7)'
                : '2px solid rgba(255,255,255,0.08)',
              'flex-shrink': '0',
            }}
          />
        </Stack.Item>

        {/* Name + path */}
        <Stack.Item grow={1} style={{ 'overflow': 'hidden', 'min-width': '0' }}>
          {selected_object ? (
            <>
              <Box
                bold
                fontSize="13px"
                color="#00e87a"
                style={{
                  'white-space': 'nowrap',
                  'overflow': 'hidden',
                  'text-overflow': 'ellipsis',
                  'line-height': '1.3',
                }}
              >
                {displayName}
              </Box>
              <Box
                color="label"
                fontSize="10px"
                style={{
                  'white-space': 'nowrap',
                  'overflow': 'hidden',
                  'text-overflow': 'ellipsis',
                  'opacity': '0.65',
                }}
              >
                {selected_object}
              </Box>
            </>
          ) : (
            <Box color="average" fontSize="12px" style={{ 'font-style': 'italic' }}>
              No atom selected
            </Box>
          )}
        </Stack.Item>

        {/* Precise mode buttons + clear */}
        <Stack.Item>
          <Stack spacing="2px" align="center">
            <Stack.Item>
              <Button
                compact
                icon="crosshairs"
                color={precise_mode === PRECISE_MODE_TARGET ? 'green' : 'transparent'}
                style={{
                  'border': precise_mode === PRECISE_MODE_TARGET
                    ? '1px solid #00c864'
                    : '1px solid rgba(255,255,255,0.15)',
                  'width': '24px',
                  'height': '24px',
                  'padding': '0',
                  'display': 'flex',
                  'align-items': 'center',
                  'justify-content': 'center',
                }}
                tooltip={needsClick
                  ? (precise_mode === PRECISE_MODE_TARGET ? 'Target mode active — click a tile' : 'Set target tile (needs targeted location)')
                  : 'Only usable with "Targeted location"'}
                disabled={!needsClick}
                onClick={() => togglePrecise(PRECISE_MODE_TARGET)}
              />
            </Stack.Item>
            <Stack.Item>
              <Button
                compact
                icon="copy"
                color={precise_mode === PRECISE_MODE_COPY ? 'green' : 'transparent'}
                style={{
                  'border': precise_mode === PRECISE_MODE_COPY
                    ? '1px solid #00c864'
                    : '1px solid rgba(255,255,255,0.15)',
                  'width': '24px',
                  'height': '24px',
                  'padding': '0',
                  'display': 'flex',
                  'align-items': 'center',
                  'justify-content': 'center',
                }}
                tooltip={precise_mode === PRECISE_MODE_COPY ? 'Copy mode active — click an atom' : 'Copy atom type by clicking'}
                onClick={() => togglePrecise(PRECISE_MODE_COPY)}
              />
            </Stack.Item>
            <Stack.Item>
              <Button
                compact
                icon="times"
                color="transparent"
                style={{
                  'border': '1px solid rgba(255,80,80,0.35)',
                  'width': '24px',
                  'height': '24px',
                  'padding': '0',
                  'display': 'flex',
                  'align-items': 'center',
                  'justify-content': 'center',
                  'color': 'rgba(255,100,100,0.7)',
                }}
                tooltip="Clear selection"
                disabled={!selected_object}
                onClick={() => act('selected-atom-changed', { newObj: null })}
              />
            </Stack.Item>
          </Stack>
        </Stack.Item>

        {/* SPAWN button */}
        <Stack.Item>
          <Button
            color={selected_object ? (needsClick && precise_mode === PRECISE_MODE_TARGET ? 'average' : 'good') : 'grey'}
            disabled={!selected_object}
            tooltip={selected_object
              ? (needsClick && precise_mode === PRECISE_MODE_OFF
                ? 'Активировать прицел'
                : needsClick && precise_mode === PRECISE_MODE_TARGET
                  ? 'Отменить прицел'
                  : `Сотворить ${atom_amount}× ${displayName}`)
              : 'Сначала выберите объект'}
            style={{
              'height': '48px',
              'min-width': '72px',
              'font-size': '15px',
              'font-weight': 'bold',
              'letter-spacing': '1px',
              'display': 'flex',
              'flex-direction': 'column',
              'align-items': 'center',
              'justify-content': 'center',
              'border-radius': '6px',
            }}
            onClick={() => {
              if (needsClick) {
                act('toggle-precise-mode', {
                  newPreciseType: precise_mode === PRECISE_MODE_TARGET ? PRECISE_MODE_OFF : PRECISE_MODE_TARGET,
                });
              } else {
                act('create-atom-action', {
                  selected_atom: selected_object,
                  where_target_type,
                  atom_amount,
                  atom_name,
                  atom_desc,
                  atom_dir,
                  offset: [ox, oy, oz],
                  offset_type,
                });
              }
            }}
          >
            <Box>SPAWN</Box>
            {atom_amount > 1 && (
              <Box style={{ 'font-size': '10px', 'opacity': '0.75', 'font-weight': 'normal', 'letter-spacing': '0' }}>
                ×{atom_amount}
              </Box>
            )}
          </Button>
        </Stack.Item>
      </Stack>

      {/* ─── Settings row ─── */}
      <Stack spacing={1} align="center" mb="4px">
        {/* Amt */}
        <Stack.Item>
          <Stack spacing="3px" align="center">
            <Stack.Item>
              <Box color="label" fontSize="11px" bold style={{ 'white-space': 'nowrap' }}>Amt</Box>
            </Stack.Item>
            <Stack.Item>
              <NumberInput
                value={atom_amount}
                minValue={1}
                maxValue={100}
                step={1}
                width="46px"
                onChange={(_e: any, val: number) => send({ atom_amount: val })}
              />
            </Stack.Item>
          </Stack>
        </Stack.Item>

        {/* Dir */}
        <Stack.Item grow={1}>
          <Stack spacing="3px" align="center">
            <Stack.Item>
              <Box color="label" fontSize="11px" bold style={{ 'white-space': 'nowrap' }}>Dir</Box>
            </Stack.Item>
            <Stack.Item>
              <Button
                compact
                icon={DIR_ICONS[atom_dir] ?? 'arrow-down'}
                tooltip={DIR_NAMES[atom_dir] ?? 'South'}
                onClick={() => send({ atom_dir: idxToDir((dirIdx + 1) % 4) })}
              />
            </Stack.Item>
            <Stack.Item grow={1}>
              <Slider
                value={dirIdx}
                minValue={0}
                maxValue={3}
                step={1}
                stepPixelSize={28}
                format={(i: number) => DIR_NAMES[idxToDir(i)]?.[0] ?? '?'}
                onChange={(_e: any, val: number) => send({ atom_dir: idxToDir(val) })}
              />
            </Stack.Item>
          </Stack>
        </Stack.Item>

        {/* Offset type toggle */}
        <Stack.Item>
          <Stack spacing="1px">
            <Stack.Item>
              <Button
                compact
                selected={offset_type === OFFSET_ABSOLUTE}
                tooltip="Absolute world coordinates"
                onClick={() => send({ offset_type: OFFSET_ABSOLUTE })}
              >A</Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                compact
                selected={offset_type === OFFSET_RELATIVE}
                tooltip="Relative to spawn position"
                onClick={() => send({ offset_type: OFFSET_RELATIVE })}
              >R</Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>

        {/* Offset XYZ */}
        <Stack.Item>
          <Input
            placeholder="X, Y, Z"
            value={`${ox}, ${oy}, ${oz}`}
            width="90px"
            onChange={handleOffsetInput}
            onEnter={handleOffsetInput}
          />
        </Stack.Item>
      </Stack>

      {/* ─── Name + Desc + Location row ─── */}
      <Stack spacing={1} align="center">
        <Stack.Item grow={1}>
          <Input
            placeholder="Name override..."
            value={atom_name ?? ''}
            fluid
            onChange={(_e: any, val: string) => send({ atom_name: val || null })}
            onEnter={(_e: any, val: string) => send({ atom_name: val || null })}
          />
        </Stack.Item>
        <Stack.Item grow={1}>
          <Input
            placeholder="Desc override..."
            value={atom_desc ?? ''}
            fluid
            onChange={(_e: any, val: string) => send({ atom_desc: val || null })}
            onEnter={(_e: any, val: string) => send({ atom_desc: val || null })}
          />
        </Stack.Item>
        <Stack.Item>
          <Dropdown
            icon={locationIcon}
            options={SPAWN_LOCATIONS as unknown as string[]}
            selected={where_target_type ?? SPAWN_LOCATIONS[0]}
            onSelected={(val: string) => send({ where_target_type: val })}
            style={{ 'min-width': '160px' }}
          />
        </Stack.Item>
      </Stack>

      {/* ─── Precise mode indicator ─── */}
      {precise_mode !== PRECISE_MODE_OFF && (
        <Box
          mt="4px"
          p="2px 8px"
          fontSize="11px"
          color="average"
          style={{
            'border-left': '3px solid rgba(255,180,0,0.7)',
            'background': 'rgba(255,180,0,0.06)',
            'border-radius': '0 3px 3px 0',
          }}
        >
          <Icon name="circle" color="average" mr={1} style={{ 'font-size': '7px', 'vertical-align': '1px' }} />
          {precise_mode === PRECISE_MODE_TARGET
            ? 'Target mode — click a tile in-game'
            : 'Copy mode — click an atom in-game'}
        </Box>
      )}
    </Box>
  );
};

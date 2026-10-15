import { useState } from 'react';

import { useBackend } from '../backend';
import { Button, Input, NoticeBox, Section, Stack, Tabs } from '../components';
import { Window } from '../layouts';

const CELL_SCREEN_W = 168;
const CELL_SCREEN_H = 40;
const PREVIEW_BOX_W = 250;
const PREVIEW_BOX_H = 300;
const PORTRAIT_BOX_H = 190;
const MODE_MIRROR = 2;
const MODE_SCISSORS = 3;
const MODE_RAZOR = 4;
const GOLD = '#ffdd55';
const DIR_SOUTH = 2;
const DIR_WEST = 8;
const DIR_NORTH = 1;
const DIR_EAST = 4;
const DIR_ORDER = [DIR_SOUTH, DIR_WEST, DIR_NORTH, DIR_EAST];

type HairPickerLabels = {
  tab_hair: string;
  tab_facial: string;
  tab_grad: string;
  title: string;
  apply: string;
  search: string;
  preview: string;
  portrait: string;
  full: string;
  page: string;
  selected: string;
  empty: string;
};

type HairPickerData = {
  error?: boolean;
  allowed_tabs?: string[];
  mode?: number;
  tab: string;
  dir: number;
  search: string;
  page: number;
  pages: number;
  total: number;
  names: string[];
  selected: string;
  sheet: string | null;
  cell_w: number;
  cell_h: number;
  cols: number;
  preview: string | null;
  preview_full: string | null;
  img_w: number;
  img_h: number;
  head_h: number;
  labels: HairPickerLabels;
};

export const HairStylePicker = (props) => {
  const { act, data } = useBackend<HairPickerData>();
  const labels = data.labels;
  const tabs = data.allowed_tabs || [];
  const names = data.names || [];

  if (data.error || !tabs.length) {
    return (
      <Window title={labels?.title || 'Hair Style'} width={420} height={160}>
        <Window.Content>
          <NoticeBox>{labels?.empty || 'Nothing found'}</NoticeBox>
        </Window.Content>
      </Window>
    );
  }

  const tabLabel = (tab: string) => {
    if (tab === 'hair') return labels.tab_hair;
    if (tab === 'facial') return labels.tab_facial;
    return labels.tab_grad;
  };

  return (
    <Window title={labels.title} width={860} height={560} resizable>
      <Window.Content scrollable={false}>
        <Stack vertical fill>
          <Stack.Item>
            <Stack align="center">
              <Stack.Item grow>
                <Tabs fluid textAlign="center">
                  {tabs.map((tab) => (
                    <Tabs.Tab
                      key={tab}
                      selected={data.tab === tab}
                      onClick={() => act('tab', { tab })}>
                      {tabLabel(tab)}
                    </Tabs.Tab>
                  ))}
                </Tabs>
              </Stack.Item>
              <Stack.Item width="200px">
                <Input
                  fluid
                  value={data.search}
                  placeholder={labels.search}
                  onInput={(e, value) => act('search', { search: value })}
                />
              </Stack.Item>
            </Stack>
          </Stack.Item>
          <Stack.Item grow>
            <Stack fill>
              <Stack.Item grow>
                <StyleGrid
                  data={data}
                  onSelect={(name) => act('select', { name })}
                />
              </Stack.Item>
              <Stack.Item width="270px" align="stretch">
                <PreviewPanel data={data} act={act} labels={labels} />
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const StyleGrid = (props: {
  data: HairPickerData;
  onSelect: (name: string) => void;
}) => {
  const { data, onSelect } = props;
  const names = data.names || [];
  const cols = data.cols || 4;
  const cellW = CELL_SCREEN_W;
  const cellH = Math.max(
    24,
    Math.round((CELL_SCREEN_W * (data.cell_h || 20)) / (data.cell_w || 40)),
  );
  const rows = Math.max(1, Math.ceil(names.length / cols));

  return (
    <Section fill scrollable title={`${names.length}/${data.total}`}>
      {names.length ? (
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: `repeat(${cols}, ${cellW}px)`,
            gridAutoRows: `${cellH}px`,
            gap: '4px',
            justifyContent: 'center',
          }}>
          {names.map((name, index) => (
            <StyleCell
              key={name}
              name={name}
              index={index}
              cols={cols}
              cellW={cellW}
              cellH={cellH}
              sheet={data.sheet}
              rows={rows}
              selected={name === data.selected}
              onClick={() => onSelect(name)}
            />
          ))}
        </div>
      ) : (
        data.labels.empty
      )}
    </Section>
  );
};

const StyleCell = (props: {
  name: string;
  index: number;
  cols: number;
  cellW: number;
  cellH: number;
  sheet: string | null;
  rows: number;
  selected: boolean;
  onClick: () => void;
}) => {
  const { name, index, cols, cellW, cellH, sheet, rows, selected, onClick } =
    props;
  const [hovered, setHovered] = useState(false);
  const col = index % cols;
  const row = Math.floor(index / cols);
  return (
    <div
      title={name}
      onClick={onClick}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        width: `${cellW}px`,
        height: `${cellH}px`,
        position: 'relative',
        cursor: 'pointer',
        borderRadius: '4px',
        overflow: 'hidden',
        background: selected
          ? 'rgba(255, 221, 85, 0.18)'
          : hovered
            ? 'rgba(255, 255, 255, 0.12)'
            : 'rgba(0, 0, 0, 0.3)',
        outline: selected
          ? `2px solid ${GOLD}`
          : hovered
            ? '2px solid rgba(255, 255, 255, 0.45)'
            : 'none',
        outlineOffset: '-2px',
      }}>
      {sheet ? (
        <div
          style={{
            position: 'absolute',
            inset: 0,
            backgroundImage: `url(data:image/png;base64,${sheet})`,
            backgroundSize: `${cols * cellW}px ${rows * cellH}px`,
            backgroundPosition: `-${col * cellW}px -${row * cellH}px`,
            backgroundRepeat: 'no-repeat',
            imageRendering: 'pixelated',
          }}
        />
      ) : null}
    </div>
  );
};

const PreviewPanel = (props: {
  data: HairPickerData;
  labels: HairPickerLabels;
  act: (type: string, payload?: Record<string, unknown>) => void;
}) => {
  const { data, labels, act } = props;
  const inRound =
    data.mode === MODE_MIRROR ||
    data.mode === MODE_SCISSORS ||
    data.mode === MODE_RAZOR;
  const [fullBody, setFullBody] = useState(false);
  const showFull = !inRound && fullBody;
  const src = showFull ? data.preview_full : data.preview;
  const boxH = showFull ? PREVIEW_BOX_H : PORTRAIT_BOX_H;
  const naturalW = data.img_w || 40;
  const naturalH = showFull ? data.img_h || 40 : data.head_h || 20;
  const fitScale = Math.min(PREVIEW_BOX_W / naturalW, boxH / naturalH);
  const imgW = Math.round(naturalW * fitScale);
  const imgH = Math.round(naturalH * fitScale);

  const rotate = (step: number) => {
    const current = DIR_ORDER.indexOf(data.dir);
    const next =
      (current + step + DIR_ORDER.length) % DIR_ORDER.length;
    act('dir', { dir: DIR_ORDER[next] });
  };

  return (
    <Stack vertical fill>
      <Stack.Item grow>
        <Section
          fill
          title={labels.preview}
          buttons={
            !inRound ? (
              <Button
                icon={fullBody ? 'user' : 'search'}
                content={fullBody ? labels.portrait : labels.full}
                onClick={() => setFullBody(!fullBody)}
              />
            ) : null
          }>
          <Stack vertical fill justify="space-around">
            <Stack.Item>
              <div
                style={{
                  width: `${PREVIEW_BOX_W}px`,
                  height: `${boxH}px`,
                  margin: '0 auto',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  overflow: 'hidden',
                  borderRadius: '6px',
                  background: 'rgba(0, 0, 0, 0.45)',
                }}>
                {src ? (
                  <img
                    src={`data:image/png;base64,${src}`}
                    style={{
                      width: `${imgW}px`,
                      height: `${imgH}px`,
                      imageRendering: 'pixelated',
                      display: 'block',
                    }}
                  />
                ) : null}
              </div>
            </Stack.Item>
            <Stack.Item>
              <Stack justify="center">
                <Stack.Item>
                  <Button
                    icon="undo"
                    tooltip="Повернуть влево"
                    onClick={() => rotate(-1)}
                  />
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="redo"
                    tooltip="Повернуть вправо"
                    onClick={() => rotate(1)}
                  />
                </Stack.Item>
              </Stack>
            </Stack.Item>
            <Stack.Item textAlign="center">
              <div style={{ color: GOLD, fontWeight: 'bold' }}>
                {data.selected || '—'}
              </div>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section>
          <Stack vertical>
            <Stack.Item>
              <Button
                fluid
                textAlign="center"
                icon="cut"
                color="good"
                content={labels.apply}
                disabled={!data.selected}
                onClick={() => act('apply')}
              />
            </Stack.Item>
            <Stack.Item>
              <Stack align="center">
                <Stack.Item>
                  <Button
                    icon="chevron-left"
                    disabled={data.page <= 1}
                    onClick={() => act('page', { page: data.page - 1 })}
                  />
                </Stack.Item>
                <Stack.Item grow textAlign="center">
                  {labels.page} {data.page}/{data.pages}
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="chevron-right"
                    disabled={data.page >= data.pages}
                    onClick={() => act('page', { page: data.page + 1 })}
                  />
                </Stack.Item>
              </Stack>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

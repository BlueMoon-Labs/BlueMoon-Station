import { useState } from 'react';

import { useBackend } from '../backend';
import { Button, Input, NoticeBox, Section, Stack, Tabs } from '../components';
import { Window } from '../layouts';

const PREVIEW_BOX_W = 350;
const PREVIEW_BOX_H = 420;
const PORTRAIT_BOX_W = 359;
const PORTRAIT_BOX_H = 274;
const FULL_BODY_ZOOM = 1.5;
const TAUR_FULL_BODY_ZOOM = 2.5;
const PORTRAIT_ZOOM = 1.4;
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
  color: string;
  color_requires_spray: string;
  search: string;
  favorites: string;
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
  can_preview_full: boolean;
  can_change_color: boolean;
  is_taur: boolean;
  tab: string;
  dir: number;
  search: string;
  favorites: string[];
  favorites_only: boolean;
  page: number;
  pages: number;
  total: number;
  names: string[];
  selected: string;
  sheet: string | null;
  cell_w: number;
  cell_h: number;
  cols: number;
  preview_portraits: Record<string, string>;
  preview_full: string | null;
  img_w: number;
  img_h: number;
  head_w: number;
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
    <Window title={labels.title} width={1060} height={700} resizable>
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
                  autoFocus
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
                  onApply={(name) => act('apply', { name, tab: data.tab })}
                  onToggleFavorite={(name) =>
                    act('toggle_favorite', { name, tab: data.tab })
                  }
                  onToggleFavoritesOnly={() => act('favorites_only')}
                  onPage={(page) => act('page', { page })}
                />
              </Stack.Item>
              <Stack.Item
                width={`${Math.max(PORTRAIT_BOX_W, PREVIEW_BOX_W) + 20}px`}
                align="stretch">
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
  onApply: (name: string) => void;
  onToggleFavorite: (name: string) => void;
  onToggleFavoritesOnly: () => void;
  onPage: (page: number) => void;
}) => {
  const {
    data,
    onSelect,
    onApply,
    onToggleFavorite,
    onToggleFavoritesOnly,
    onPage,
  } = props;
  const names = data.names || [];
  const favorites = data.favorites || [];
  const cols = data.cols || 4;
  const aspectRatio = (data.cell_w || 40) / (data.cell_h || 20);
  const rows = Math.max(1, Math.ceil(names.length / cols));
  const viewedCount =
    data.page < data.pages ? names.length * data.page : data.total;

  return (
    <Section
      fill
      scrollable
      title={`${viewedCount}/${data.total}`}
      buttons={
        <Stack align="center">
          <Stack.Item>
            <Button
              icon={data.favorites_only ? 'star' : 'star-o'}
              iconColor={data.favorites_only ? GOLD : 'label'}
              color="transparent"
              content={data.labels.favorites}
              onClick={onToggleFavoritesOnly}
            />
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="chevron-left"
              disabled={data.page <= 1}
              onClick={() => onPage(data.page - 1)}
            />
          </Stack.Item>
          <Stack.Item>
            {data.labels.page} {data.page}/{data.pages}
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="chevron-right"
              disabled={data.page >= data.pages}
              onClick={() => onPage(data.page + 1)}
            />
          </Stack.Item>
        </Stack>
      }>
      {names.length ? (
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: `repeat(${cols}, minmax(0, 1fr))`,
            gap: '4px',
          }}>
          {names.map((name, index) => (
            <StyleCell
              key={name}
              name={name}
              index={index}
              cols={cols}
              aspectRatio={aspectRatio}
              sheet={data.sheet}
              rows={rows}
              selected={name === data.selected}
              favorite={favorites.includes(name)}
              onToggleFavorite={() => onToggleFavorite(name)}
              onClick={() => onSelect(name)}
              onDoubleClick={() => onApply(name)}
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
  aspectRatio: number;
  sheet: string | null;
  rows: number;
  selected: boolean;
  favorite: boolean;
  onToggleFavorite: () => void;
  onClick: () => void;
  onDoubleClick: () => void;
}) => {
  const {
    name,
    index,
    cols,
    aspectRatio,
    sheet,
    rows,
    selected,
    favorite,
    onToggleFavorite,
    onClick,
    onDoubleClick,
  } = props;
  const [hovered, setHovered] = useState(false);
  const col = index % cols;
  const row = Math.floor(index / cols);
  return (
    <div
      title={name}
      onClick={onClick}
      onDoubleClick={onDoubleClick}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        width: '100%',
        aspectRatio,
        minHeight: '24px',
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
            backgroundSize: `${cols * 100}% ${rows * 100}%`,
            backgroundPosition: `${cols > 1 ? (col / (cols - 1)) * 100 : 0}% ${rows > 1 ? (row / (rows - 1)) * 100 : 0}%`,
            backgroundRepeat: 'no-repeat',
            imageRendering: 'pixelated',
          }}
        />
      ) : null}
      <div
        onClick={(event) => event.stopPropagation()}
        onDoubleClick={(event) => event.stopPropagation()}
        style={{
          position: 'absolute',
          top: '4px',
          right: '4px',
          zIndex: 1,
          borderRadius: '3px',
          background: 'rgba(0, 0, 0, 0.65)',
        }}>
        <Button
          compact
          m={0}
          icon={favorite ? 'star' : 'star-o'}
          iconColor={favorite ? GOLD : 'label'}
          color="transparent"
          onClick={onToggleFavorite}
        />
      </div>
    </div>
  );
};

const PreviewPanel = (props: {
  data: HairPickerData;
  labels: HairPickerLabels;
  act: (type: string, payload?: Record<string, unknown>) => void;
}) => {
  const { data, labels, act } = props;
  const canPreviewFull = Boolean(data.can_preview_full);
  const [fullBody, setFullBody] = useState(false);
  const showFull = canPreviewFull && fullBody;
  const fullBodyZoom = data.is_taur ? TAUR_FULL_BODY_ZOOM : FULL_BODY_ZOOM;
  const boxW = showFull ? PREVIEW_BOX_W : PORTRAIT_BOX_W;
  const boxH = showFull ? PREVIEW_BOX_H : PORTRAIT_BOX_H;
  const cellW = showFull ? boxW : boxW / 2;
  const cellH = showFull ? boxH : boxH / 2;
  const naturalW = showFull ? data.img_w || 40 : data.head_w || 40;
  const naturalH = showFull ? data.img_h || 40 : data.head_h || 20;
  const fitScale = Math.min(cellW / naturalW, cellH / naturalH);
  const imgW = Math.round(naturalW * fitScale);
  const imgH = Math.round(naturalH * fitScale);

  const rotate = (step: number) => {
    const current = DIR_ORDER.indexOf(data.dir);
    const next = (current + step + DIR_ORDER.length) % DIR_ORDER.length;
    act('dir', { dir: DIR_ORDER[next] });
  };

  return (
    <Stack vertical fill>
      <Stack.Item grow>
        <Section
          fill
          title={labels.preview}
          buttons={
            <>
              <Button
                icon="palette"
                color="good"
                content={labels.color}
                disabled={!data.can_change_color}
                tooltip={
                  !data.can_change_color ? labels.color_requires_spray : undefined
                }
                onClick={() => act('color')}
              />
              {canPreviewFull && (
                <Button
                  icon={fullBody ? 'person' : 'users'}
                  content={fullBody ? labels.full : labels.portrait}
                  onClick={() => setFullBody(!fullBody)}
                />
              )}
            </>
          }>
          <Stack vertical fill justify="space-around">
            <Stack.Item>
              <div
                onDoubleClick={() => {
                  if (data.selected) {
                    act('apply', { name: data.selected, tab: data.tab });
                  }
                }}
                style={{
                  width: `${boxW}px`,
                  height: `${boxH}px`,
                  margin: '0 auto',
                  display: 'grid',
                  gridTemplateColumns: `repeat(${showFull ? 1 : 2}, 1fr)`,
                  alignItems: 'center',
                  justifyItems: 'center',
                  overflow: 'hidden',
                  borderRadius: '6px',
                  background: 'rgba(0, 0, 0, 0.45)',
                  cursor: data.selected ? 'pointer' : 'default',
                }}>
                {(showFull ? [data.dir] : DIR_ORDER).map((dir) => {
                  const src = showFull
                    ? data.preview_full
                    : data.preview_portraits?.[dir];
                  return src ? (
                    <div
                      key={dir}
                      style={{
                        width: `${cellW}px`,
                        height: `${cellH}px`,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        overflow: 'hidden',
                      }}>
                      <img
                        src={`data:image/png;base64,${src}`}
                        style={{
                          width: `${imgW}px`,
                          height: `${imgH}px`,
                          imageRendering: 'pixelated',
                          display: 'block',
                          flexShrink: 0,
                          transform: `scale(${showFull ? fullBodyZoom : PORTRAIT_ZOOM})`,
                        }}
                      />
                    </div>
                  ) : null;
                })}
              </div>
            </Stack.Item>
            {showFull && (
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
            )}
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
          <Button
            fluid
            textAlign="center"
            icon="cut"
            color="good"
            content={labels.apply}
            disabled={!data.selected}
            onClick={() => act('apply')}
          />
        </Section>
      </Stack.Item>
    </Stack>
  );
};

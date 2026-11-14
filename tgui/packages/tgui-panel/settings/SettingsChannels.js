import { useDispatch, useSelector } from 'common/redux';
import { useEffect, useLayoutEffect, useRef, useState } from 'react';
import { Box, Button, Divider, Dropdown, Flex, Section, Table, Tooltip } from 'tgui/components';

import { updateSettings } from './actions';
import { createChannelEditor, isEntryEdited } from './channelsModel';
import { ChatPreview } from './ChatPreview';
import { CHANNEL_TYPES, CHAT_ANIMATIONS } from './constants';
import { selectSettings } from './selectors';
import { ColorInput } from './SettingsPanel';

const ANIM_OPTIONS = [
  { id: '', name: 'Как у чата' },
  ...CHAT_ANIMATIONS,
];

const COLUMNS = [
  { title: '' },
  { title: 'Цвет', tooltip: 'Цвет полоски слева от сообщения' },
  { title: 'Фон', tooltip: 'Лёгкая подложка цветом полоски' },
  { title: 'Появление', tooltip: 'Анимация появления сообщения' },
  { title: 'Вспышка', tooltip: 'Короткая вспышка, когда приходит сообщение' },
  { title: '' },
];

const CELL = { padding: '0 2px 4px' };

// Мягкий перенос в длинных названиях: колонка меток сужается в узком чате.
const LABEL_BREAKS = { warning: 'Предупре' };

const labelOf = channel => {
  const head = LABEL_BREAKS[channel.type];
  return head && channel.name.startsWith(head)
    ? head + '\u00AD' + channel.name.slice(head.length)
    : channel.name;
};

// Высота меню Dropdown: max-height 200px при базе 12px.
const DROPDOWN_MENU_EM = 200 / 12;

const findScrollParent = node => {
  for (let n = node?.parentElement; n; n = n.parentElement) {
    if (/auto|scroll/.test(getComputedStyle(n).overflowY)) {
      return n;
    }
  }
  return null;
};

// Непрозрачный цвет под узлом: полупрозрачные слои фона поверх белого.
const opaqueBackground = node => {
  const layers = [];
  for (let n = node; n; n = n.parentElement) {
    const rgba = getComputedStyle(n).backgroundColor.match(/[\d.]+/g);
    const alpha = rgba?.[3] === undefined ? 1 : Number(rgba[3]);
    if (rgba && alpha > 0) {
      layers.unshift([Number(rgba[0]), Number(rgba[1]), Number(rgba[2]), alpha]);
      if (alpha >= 1) {
        break;
      }
    }
  }
  let color = [255, 255, 255];
  for (const [r, g, b, a] of layers) {
    color = [r, g, b].map((c, i) => c * a + color[i] * (1 - a));
  }
  return 'rgb(' + color.map(Math.round).join(', ') + ')';
};

const stickyCell = {
  ...CELL,
  position: 'sticky',
  left: 0,
  zIndex: 1,
  backgroundColor: 'var(--channels-label-bg)',
};

const isMenuOpen = node => !!node?.querySelector(
  '.Dropdown__menu, .Dropdown__menu-noscroll');

// Меню открывается вверх, только если сверху оно помещается целиком,
// а снизу нет: вниз его всегда можно докрутить.
const AnimDropdown = props => {
  const { selected, onSelected } = props;
  const ref = useRef(null);
  const [over, setOver] = useState(false);
  useEffect(() => {
    const node = ref.current;
    const observer = new MutationObserver(() => {
      if (!isMenuOpen(node)) {
        setOver(false);
      }
    });
    observer.observe(node, { childList: true, subtree: true });
    return () => observer.disconnect();
  }, []);
  const pickDirection = event => {
    const node = ref.current;
    const scroller = findScrollParent(node);
    if (!node || !scroller || isMenuOpen(node)
      || !event.target.closest?.('.Dropdown__control')) {
      return;
    }
    const rect = node.getBoundingClientRect();
    const box = scroller.getBoundingClientRect();
    const menuHeight = parseFloat(getComputedStyle(node).fontSize)
      * DROPDOWN_MENU_EM;
    setOver(rect.top - box.top >= menuHeight
      && box.bottom - rect.bottom < menuHeight);
  };
  return (
    <div ref={ref} onMouseDown={pickDirection}>
      <Dropdown
        width="9.25em"
        over={over}
        selected={selected}
        options={ANIM_OPTIONS.map(a => a.name)}
        onSelected={onSelected}
      />
    </div>
  );
};

const ChannelRow = props => {
  const { channel, entry, onPatch, onReset } = props;
  const selectedAnim = ANIM_OPTIONS.find(a => a.id === (entry.anim || ''));
  return (
    <Table.Row>
      <Table.Cell verticalAlign="top" style={stickyCell}>
        <Box color="label" lineHeight="22px">
          {labelOf(channel)}
        </Box>
      </Table.Cell>
      <Table.Cell collapsing textAlign="center" style={CELL}>
        <ColorInput
          compact
          value={entry.border || ''}
          placeholder="Без полоски"
          onChange={v => onPatch({ border: v })}
          onClear={() => onPatch({ border: '' })}
        />
      </Table.Cell>
      <Table.Cell collapsing textAlign="center" style={CELL}>
        {!!entry.border && (
          <Button.Checkbox
            checked={!!entry.tint}
            tooltip="Лёгкая подложка цветом полоски"
            onClick={() => onPatch({ tint: !entry.tint })}
          />
        )}
      </Table.Cell>
      <Table.Cell collapsing style={CELL}>
        <AnimDropdown
          selected={selectedAnim?.name || ANIM_OPTIONS[0].name}
          onSelected={value => {
            const anim = ANIM_OPTIONS.find(a => a.name === value);
            onPatch({ anim: anim?.id || '' });
          }}
        />
      </Table.Cell>
      <Table.Cell collapsing textAlign="center" style={CELL}>
        <Button.Checkbox
          checked={!!entry.flash}
          tooltip="Короткая вспышка, когда приходит сообщение"
          onClick={() => onPatch({ flash: !entry.flash })}
        />
      </Table.Cell>
      <Table.Cell collapsing style={CELL}>
        <Button
          compact
          icon="undo"
          disabled={!isEntryEdited(entry)}
          tooltip="Вернуть как было"
          onClick={onReset}
        />
      </Table.Cell>
    </Table.Row>
  );
};

export const SettingsChannels = props => {
  const { typeOverrides, theme } = useSelector(selectSettings);
  const dispatch = useDispatch();
  const editorRef = useRef(null);
  const tableRef = useRef(null);
  if (!editorRef.current) {
    editorRef.current = createChannelEditor(
      next => dispatch(updateSettings({ typeOverrides: next })));
  }
  const editor = editorRef.current;
  editor.sync(typeOverrides);
  useLayoutEffect(() => {
    const node = tableRef.current;
    if (node) {
      node.style.setProperty('--channels-label-bg', opaqueBackground(node));
    }
  }, [theme]);
  return (
    <Section style={{ minWidth: 'min-content' }}>
      <Box color="label" mb={1}>
        Своё оформление для отдельных каналов: полоска слева, подложка,
        анимация появления и вспышка при новом сообщении. Пустое поле: как у
        остального чата.
      </Box>
      <div ref={tableRef}>
        <Table collapsing>
          <Table.Row header>
            {COLUMNS.map((column, i) => (
              <Table.Cell
                key={i}
                color="label"
                textAlign="center"
                fontSize="0.85em"
                style={{
                  ...(i === 0 ? stickyCell : CELL),
                  fontWeight: 'normal',
                }}>
                {column.tooltip ? (
                  <Tooltip content={column.tooltip}>
                    <span>{column.title}</span>
                  </Tooltip>
                ) : column.title}
              </Table.Cell>
            ))}
          </Table.Row>
          {CHANNEL_TYPES.map(channel => (
            <ChannelRow
              key={channel.type}
              channel={channel}
              entry={typeOverrides?.[channel.type] || {}}
              onPatch={patch => editor.patch(channel.type, patch)}
              onReset={() => editor.reset(channel.type)}
            />
          ))}
        </Table>
      </div>
      <Divider />
      <ChatPreview samples="channels" />
      <Divider />
      <Flex wrap style={{ gap: '0.5em 2em' }}>
        <Flex.Item>
          <Button
            icon="magic"
            tooltip="Цвета и вспышки для важных каналов поверх ваших настроек"
            onClick={() => editor.recommended()}>
            Рекомендуемый набор
          </Button>
        </Flex.Item>
        <Flex.Item>
          <Button
            icon="undo"
            onClick={() => editor.clear()}>
            Сбросить каналы
          </Button>
        </Flex.Item>
      </Flex>
    </Section>
  );
};

import { memo, useEffect, useRef, useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, ByondUi, Input, Section, Slider, Stack } from '../components';
import { Window } from '../layouts';

const RGB_MAX = 255;
const HUE_MAX = 360;
const WHEEL_SIZE = 200;
const WHEEL_RADIUS = WHEEL_SIZE / 2;
const WHEEL_STEPS = 120;
const HEX_COLOR = /^#[0-9a-f]{6}$/i;
const PREVIEW_INTERVAL = 75;

export const hexToHsv = (color) => {
  const values = [1, 3, 5].map((offset) => parseInt(color.slice(offset, offset + 2), 16) / RGB_MAX);
  const [red, green, blue] = values;
  const high = Math.max(...values);
  const delta = high - Math.min(...values);
  let hue = 0;
  if (delta) {
    if (high === red) hue = ((green - blue) / delta + 6) % 6;
    else if (high === green) hue = (blue - red) / delta + 2;
    else hue = (red - green) / delta + 4;
  }
  return [hue * HUE_MAX / 6, high ? delta / high : 0, high];
};

export const hsvToHex = (hue, saturation, value) => {
  const channel = (offset) => {
    const position = (offset + hue / (HUE_MAX / 6)) % 6;
    const component = value * (1 - saturation * Math.max(0, Math.min(position, 4 - position, 1)));
    return Math.round(component * RGB_MAX).toString(16).padStart(2, '0');
  };
  return `#${channel(5)}${channel(3)}${channel(1)}`;
};

const wheelWedges = Array.from({ length: WHEEL_STEPS }, (_, index) => {
  const angle = index * Math.PI * 2 / WHEEL_STEPS;
  const next = (index + 1) * Math.PI * 2 / WHEEL_STEPS;
  return {
    color: `hsl(${index * HUE_MAX / WHEEL_STEPS},100%,50%)`,
    path: `M ${WHEEL_RADIUS} ${WHEEL_RADIUS} L ${WHEEL_RADIUS * (1 + Math.cos(angle))} ${WHEEL_RADIUS * (1 + Math.sin(angle))} A ${WHEEL_RADIUS} ${WHEEL_RADIUS} 0 0 1 ${WHEEL_RADIUS * (1 + Math.cos(next))} ${WHEEL_RADIUS * (1 + Math.sin(next))} Z`,
  };
});

const ColorWheel = ({ color, onChange }) => {
  const [hue, saturation, value] = hexToHsv(color);
  const select = (event) => {
    const bounds = event.currentTarget.getBoundingClientRect();
    const x = (event.clientX - bounds.left) / bounds.width * 2 - 1;
    const y = (event.clientY - bounds.top) / bounds.height * 2 - 1;
    const nextHue = (Math.atan2(y, x) * HUE_MAX / (Math.PI * 2) + HUE_MAX) % HUE_MAX;
    onChange(hsvToHex(nextHue, Math.min(1, Math.hypot(x, y)), value));
  };
  const angle = hue * Math.PI * 2 / HUE_MAX;
  return (
    <>
      <svg
        role="slider"
        aria-label="Цветовое колесо"
        aria-valuetext={color}
        aria-valuemin={0}
        aria-valuemax={HUE_MAX}
        aria-valuenow={hue}
        tabIndex={0}
        viewBox={`0 0 ${WHEEL_SIZE} ${WHEEL_SIZE}`}
        width={WHEEL_SIZE}
        height={WHEEL_SIZE}
        style={{ cursor: 'crosshair', touchAction: 'none' }}
        onMouseDown={select}
        onMouseMove={(event) => { if (event.buttons === 1) select(event); }}
        onKeyDown={(event) => {
          if (!['ArrowLeft', 'ArrowRight'].includes(event.key)) return;
          event.preventDefault();
          onChange(hsvToHex((hue + (event.key === 'ArrowRight' ? 1 : HUE_MAX - 1)) % HUE_MAX, saturation || 1, value));
        }}>
        <defs>
          <radialGradient id="hardlight-wheel-white">
            <stop offset="0" stopColor="white" />
            <stop offset="1" stopColor="white" stopOpacity="0" />
          </radialGradient>
        </defs>
        {wheelWedges.map((wedge, index) => <path key={index} d={wedge.path} fill={wedge.color} />)}
        <circle cx={WHEEL_RADIUS} cy={WHEEL_RADIUS} r={WHEEL_RADIUS} fill="url(#hardlight-wheel-white)" />
        <circle cx={WHEEL_RADIUS} cy={WHEEL_RADIUS} r={WHEEL_RADIUS} fill="black" opacity={1 - value} />
        <circle cx={WHEEL_RADIUS * (1 + Math.cos(angle) * saturation)} cy={WHEEL_RADIUS * (1 + Math.sin(angle) * saturation)} r="4" fill="none" stroke="white" strokeWidth="2" />
      </svg>
      <Slider
        minValue={0} maxValue={1} step={0.01} value={value}
        format={(level) => `Яркость: ${Math.round(level * 100)}%`}
        onChange={(_, level) => onChange(hsvToHex(hue, saturation, level))}
        onDrag={(_, level) => onChange(hsvToHex(hue, saturation, level))} />
    </>
  );
};

const HardlightPreview = memo(({ mapRef }) => (
  <ByondUi height="440px" params={{ id: mapRef, type: 'map' }} />
));

const usePreview = (act, color, effect, direction, zoom) => {
  const latest = useRef();
  const sent = useRef(JSON.stringify({ color, effect, direction, zoom }));
  const timer = useRef();
  const send = useRef(act);
  send.current = act;
  useEffect(() => {
    latest.current = { color, effect, direction, zoom };
    if (timer.current || JSON.stringify(latest.current) === sent.current) return;
    timer.current = setTimeout(() => {
      timer.current = undefined;
      const key = JSON.stringify(latest.current);
      if (key === sent.current) return;
      sent.current = key;
      send.current('preview', latest.current);
    }, PREVIEW_INTERVAL);
  }, [color, effect, direction, zoom]);
  useEffect(() => () => clearTimeout(timer.current), []);
};

export const MODHardlight = () => {
  const { act, data } = useBackend();
  const { color: currentColor, effect: currentEffect, effects = [], mapRef, has_field } = data;
  const [color, setColor] = useState(HEX_COLOR.test(currentColor) ? currentColor : '#ffffff');
  const [effect, setEffect] = useState(currentEffect);
  const [direction, setDirection] = useState(2);
  const [zoom, setZoom] = useState(3);
  const selected = effects.find((entry) => entry.id === effect) || effects[0];
  usePreview(act, color, selected?.id, direction, zoom);
  return (
    <Window width={850} height={700}>
      <Window.Content scrollable>
        <Stack>
          <Stack.Item grow>
            <Section title="Предпросмотр">
              {!!mapRef && <HardlightPreview mapRef={mapRef} />}
              <Slider mt={1} minValue={1} maxValue={5} step={0.25} value={zoom} format={(level) => `Масштаб: ${level}×`} onChange={(_, level) => setZoom(level)} onDrag={(_, level) => setZoom(level)} />
              {!has_field && <Box mt={1} color="label">Включите поле для предпросмотра голограмм.</Box>}
            </Section>
          </Stack.Item>
          <Stack.Item basis="240px">
            <Section title="Эффект hardlight">
              {effects.map((entry) => (
                <Button fluid key={entry.id} selected={entry.id === selected?.id} onClick={() => setEffect(entry.id)}>{entry.name}</Button>
              ))}
            </Section>
            <Section title="Цвет">
              <ColorWheel color={color} onChange={setColor} />
              <Input aria-label="Цвет hardlight" value={color} onChange={(_, value) => { if (HEX_COLOR.test(value)) setColor(value); }} />
            </Section>
            <Button fluid icon="check" disabled={!selected} onClick={() => act('apply', { color, effect: selected.id })}>Применить</Button>
            <Button fluid icon="undo" onClick={() => { setColor(HEX_COLOR.test(currentColor) ? currentColor : '#ffffff'); setEffect(currentEffect); }}>Сбросить изменения</Button>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

import { memo, useEffect, useId, useRef, useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Dropdown, Input, NoticeBox, NumberInput, Section, Slider, Stack, Tabs } from '../components';
import { Window } from '../layouts';

const identity = [1, 0, 0, 0, 1, 0, 0, 0, 1];
const matrixLabels = ['R → R', 'R → G', 'R → B', 'G → R', 'G → G', 'G → B', 'B → R', 'B → G', 'B → B'];
const skinNames = { standard: 'Стандартный', civilian: 'Гражданский', lustwish: 'LustWish' };

const rgbMatrix = (color) => {
  if (!Array.isArray(color)) return [...identity];
  const matrix = color.length === 20
    ? [0, 1, 2, 4, 5, 6, 8, 9, 10].map(index => color[index])
    : color.slice(0, 9);
  return matrix.length === 9 && matrix.every(Number.isFinite) ? matrix : [...identity];
};

const paintFromColor = (color) => ({
  mode: Array.isArray(color) ? 'matrix' : 'tint',
  color: typeof color === 'string' && /^#[a-f\d]{6}([a-f\d]{2})?$/i.test(color) ? color.slice(0, 7) : '#ffffff',
  hue: 0,
  saturation: 1,
  value: 1,
  matrix: rgbMatrix(color),
});

const paintFromPreset = (preset) => {
  const paint = paintFromColor(preset.mode === 'matrix' ? preset.value : null);
  if (preset.mode === 'tint') return paintFromColor(preset.value);
  if (preset.mode === 'hsv') {
    const values = preset.value || {};
    return {
      ...paint, mode: 'hsv', hue: Number.isFinite(values.hue) ? values.hue : 0,
      saturation: Number.isFinite(values.sat) ? values.sat : 1,
      value: Number.isFinite(values.val) ? values.val : 1,
    };
  }
  return paint;
};

const expandMatrix = (values) => [
  ...values.slice(0, 3), 0, ...values.slice(3, 6), 0,
  ...values.slice(6, 9), 0, 0, 0, 0, 1, 0, 0, 0, 0,
];

const colorMatrix = (color) => {
  if (Array.isArray(color) && color.length === 20) return color;
  if (Array.isArray(color)) return expandMatrix(rgbMatrix(color));
  const matrix = expandMatrix(identity);
  if (typeof color === 'string' && /^#[a-f\d]{6}([a-f\d]{2})?$/i.test(color)) {
    [0, 5, 10].forEach((index, channel) => { matrix[index] = parseInt(color.slice(1 + channel * 2, 3 + channel * 2), 16) / 255; });
    if (color.length === 9) matrix[15] = parseInt(color.slice(7, 9), 16) / 255;
  }
  return matrix;
};

const paintMatrix = (paint, luma) => {
  if (paint.mode === 'tint') return colorMatrix(paint.color);
  if (paint.mode === 'matrix') return expandMatrix(paint.matrix);
  const angle = (360 - paint.hue) * Math.PI / 180;
  const cosine = Math.cos(angle);
  const sine = Math.sin(angle);
  const x = cosine + (1 - cosine) / 3;
  const y = (1 - cosine) / 3 - 0.5774 * sine;
  const z = (1 - cosine) / 3 + 0.5774 * sine;
  const rotations = [[x, y, z], [z, x, y], [y, z, x]];
  return expandMatrix(rotations.flatMap((row, channel) => row.map(rotation =>
    Math.round(((1 - paint.saturation) * luma[channel] + rotation * paint.saturation) * paint.value * 100) / 100)));
};

const colorWarning = (matrix, limits) => {
  if (!limits) return;
  const channels = [0, 1, 2].map(channel => matrix[channel] + matrix[channel + 4] + matrix[channel + 8]);
  if (channels.some(amount => amount < limits.channelMin || amount > limits.channelMax)) {
    return `Цветовой канал должен оставаться в пределах ${limits.channelMin * 100}–${limits.channelMax * 100}%.`;
  }
  const total = channels.reduce((sum, amount) => sum + amount, 0);
  if (total < limits.totalMin || total > limits.totalMax) {
    return `Общая интенсивность цвета должна оставаться в пределах ${limits.totalMin * 100}–${limits.totalMax * 100}%.`;
  }
};

const PaintPreview = memo(({ layers, skin, matrix, size = 128, thumbnail = false }) => {
  const id = useId().replace(/:/g, '');
  const colors = layers.map(layer => layer.selected && matrix ? matrix : colorMatrix(thumbnail ? null : layer.color));
  const svgOrder = [0, 4, 8, 12, 16, 1, 5, 9, 13, 17, 2, 6, 10, 14, 18, 3, 7, 11, 15, 19];
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" style={{ imageRendering: 'pixelated', display: 'block', margin: 'auto' }}>
      <defs>
        {colors.map((color, index) => (
          <filter key={index} id={`${id}-${index}`} x="0" y="0" width="100%" height="100%" colorInterpolationFilters="sRGB">
            <feColorMatrix type="matrix" values={svgOrder.map(channel => color[channel]).join(' ')} />
          </filter>
        ))}
      </defs>
      {layers.map((layer, index) => (
        <image
          key={index} width="32" height="32"
          href={`data:image/png;base64,${layer.sprites[layer.selected && skin ? skin : layer.skin]}`}
          filter={`url(#${id}-${index})`} opacity={layer.selected ? 1 : 40 / 255} />
      ))}
    </svg>
  );
});

const useContentHeight = () => {
  const content = useRef();
  const [height, setHeight] = useState(480);
  useEffect(() => {
    const element = content.current;
    let frame;
    const resize = () => {
      if (element.querySelector('input:focus, textarea:focus')) return;
      const zoom = parseFloat(getComputedStyle(document.body).zoom) || 1;
      const padding = parseFloat(getComputedStyle(element.parentElement).marginBottom) || 0;
      const top = element.closest('.Window').querySelector('.Window__titleBar').getBoundingClientRect().height;
      setHeight(Math.ceil((top + element.getBoundingClientRect().height + padding * zoom * 2) * (window.devicePixelRatio || 1)));
    };
    const afterInput = () => {
      cancelAnimationFrame(frame);
      frame = requestAnimationFrame(resize);
    };
    const observer = new ResizeObserver(resize);
    observer.observe(element);
    element.addEventListener('focusout', afterInput);
    return () => {
      observer.disconnect();
      element.removeEventListener('focusout', afterInput);
      cancelAnimationFrame(frame);
    };
  }, []);
  return [content, height];
};

export const MODpaint = () => {
  const { act, data } = useBackend();
  const { target, skin: currentSkin, color, skins = [], layers = [], limits, luma, message, presets: savedPresets = [] } = data;
  const [skin, setSkin] = useState(null);
  const [paint, setPaint] = useState(() => paintFromColor(color));
  const [paintChanged, setPaintChanged] = useState(false);
  const [selectedPreset, setSelectedPreset] = useState('');
  const [hex, setHex] = useState(paint.color);
  const [content, height] = useContentHeight();
  const style = { ...paint, skin, paint: paintChanged };
  const matrix = paintChanged ? paintMatrix(paint, luma) : null;
  const warning = matrix && colorWarning(matrix, limits);

  const updatePaint = (values) => {
    setPaint(previous => ({ ...previous, ...values }));
    setPaintChanged(true);
    setSelectedPreset('');
    if (values.color) setHex(values.color);
  };
  const selectPreset = (id) => {
    const preset = savedPresets[Number(id)];
    if (!preset) return;
    const nextPaint = paintFromPreset(preset);
    setPaint(nextPaint);
    setHex(nextPaint.color);
    setPaintChanged(true);
    setSelectedPreset(id);
  };

  return (
    <Window width={780} height={height}>
      <Window.Content scrollable>
        <div ref={content}>
          <Box bold mb={1}>{target}</Box>
          <Stack align="flex-start">
            <Stack.Item basis="42%" shrink={0}>
              <Section title="Предпросмотр" style={{ background: 'transparent' }}>
                <Stack>
                  <Stack.Item grow basis={0}>
                    <Box textAlign="center" color="label" mb={1}>Сейчас</Box>
                    <PaintPreview layers={layers} />
                  </Stack.Item>
                  <Stack.Item grow basis={0}>
                    <Box textAlign="center" color="label" mb={1}>После применения</Box>
                    <PaintPreview layers={layers} skin={skin} matrix={matrix} />
                  </Stack.Item>
                </Stack>
              </Section>
            </Stack.Item>
            <Stack.Item grow basis={0}>
              <Section title="Скин">
                <Box style={{ display: 'grid', gridTemplateColumns: 'repeat(3, minmax(0, 1fr))', gap: '6px' }}>
                  {skins.map(option => (
                    <Button
                      key={option.id}
                      fluid textAlign="center"
                      selected={option.id === (skin || currentSkin)}
                      tooltip={option.id}
                      onClick={() => setSkin(option.id)}>
                      <Box>
                        <PaintPreview layers={layers} skin={option.id} size={64} thumbnail />
                      </Box>
                      <Box style={{ whiteSpace: 'normal', overflowWrap: 'anywhere' }}>{skinNames[option.id] || option.id}</Box>
                    </Button>
                  ))}
                </Box>
              </Section>
              <Section title="Окраска">
                <Tabs fluid>
                  {[
                    ['tint', 'Цвет'], ['hsv', 'HSV'], ['matrix', 'Матрица'],
                  ].map(([mode, label]) => (
                    <Tabs.Tab key={mode} selected={paint.mode === mode} onClick={() => updatePaint({ mode })}>{label}</Tabs.Tab>
                  ))}
                </Tabs>
                {paint.mode === 'tint' && (
                  <Box mt={1} mb={1}>
                    <Box color="label" mb={1}>Оттенок</Box>
                    <Stack align="center">
                      <Stack.Item>
                        <input
                          aria-label="Цвет окраски" type="color" value={paint.color}
                          style={{ width: '48px', height: '32px', padding: '2px', background: 'transparent', border: 'none' }}
                          onInput={event => updatePaint({ color: event.target.value })}
                          onChange={event => updatePaint({ color: event.target.value })} />
                      </Stack.Item>
                      <Stack.Item grow>
                        <Input
                          aria-label="HEX цвета" value={hex}
                          onInput={(_, value) => {
                            setHex(value);
                            if (/^#[a-f\d]{6}$/i.test(value)) updatePaint({ color: value });
                          }} />
                      </Stack.Item>
                    </Stack>
                  </Box>
                )}
                {paint.mode === 'hsv' && (
                  <Box mt={1}>
                    <Box color="label">Тон</Box>
                    <Slider minValue={0} maxValue={360} step={1} value={paint.hue} format={value => `${value}°`} onDrag={(_, hue) => updatePaint({ hue })} onChange={(_, hue) => updatePaint({ hue })} />
                    <Box color="label" mt={1}>Насыщенность</Box>
                    <Slider minValue={0} maxValue={2} step={0.01} value={paint.saturation} format={value => `${Math.round(value * 100)}%`} onDrag={(_, saturation) => updatePaint({ saturation })} onChange={(_, saturation) => updatePaint({ saturation })} />
                    <Box color="label" mt={1}>Яркость</Box>
                    <Slider minValue={0.5} maxValue={1.25} step={0.01} value={paint.value} format={value => `${Math.round(value * 100)}%`} onDrag={(_, value) => updatePaint({ value })} onChange={(_, value) => updatePaint({ value })} />
                  </Box>
                )}
                {paint.mode === 'matrix' && (
                  <Box mt={1} style={{ display: 'grid', gridTemplateColumns: 'repeat(3, minmax(0, 1fr))', gap: '6px' }}>
                    {matrixLabels.map((label, index) => (
                      <Box key={label}>
                        <Box mb={0.5} color="label">{label}</Box>
                        <NumberInput
                          fluid minValue={0} maxValue={1.25} step={0.01} value={paint.matrix[index]}
                          onChange={(_, value) => {
                            const matrix = [...paint.matrix];
                            matrix[index] = value;
                            updatePaint({ matrix });
                          }} />
                      </Box>
                    ))}
                  </Box>
                )}
                <Box mt={1} mb={0.5} color="label">Пресет окраски</Box>
                <Stack>
                  <Stack.Item grow>
                    <Dropdown
                      width="100%" selected={selectedPreset} displayText="Выбрать пресет"
                      options={savedPresets.map((preset, index) => ({ value: String(index), displayText: preset.name }))}
                      onSelected={selectPreset} />
                  </Stack.Item>
                  <Stack.Item>
                    <Button icon="save" disabled={!!warning} onClick={() => act('save_preset', style)}>Сохранить</Button>
                  </Stack.Item>
                </Stack>
                <Button mt={1} icon="undo" onClick={() => updatePaint(paintFromColor(null))}>Сбросить цвет</Button>
              </Section>
            </Stack.Item>
          </Stack>
          {!!(warning || message) && <NoticeBox danger>{warning || message}</NoticeBox>}
          <Box textAlign="right" mt={1}>
            <Button onClick={() => act('cancel')}>Отмена</Button>
            <Button icon="check" color="good" disabled={!!warning || (skin === null && !paintChanged)} onClick={() => act('apply', style)}>Применить</Button>
          </Box>
        </div>
      </Window.Content>
    </Window>
  );
};

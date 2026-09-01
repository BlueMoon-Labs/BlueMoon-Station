import { useRef } from 'react';

import { useBackend, useLocalState } from '../../../backend';
import { Box, Button, Dropdown, Icon, Section, Slider, Stack } from '../../../components';

const MAX_SHIFT = 32;
const MAP_SIZE = 200;

const clampShift = (value) => Math.max(-MAX_SHIFT, Math.min(MAX_SHIFT, value));

type PixelShiftPrefs = {
  show_heart_over_self: boolean;

  interaction_effect: string;

  interaction_effects_list: Record<string, string>;
  block_partner_pixel_shift: boolean;
};

export const Pixelshift = (props) => {
  const { act, data } = useBackend<PixelShiftPrefs>();
  const {
    show_heart_over_self,

    interaction_effect,
    interaction_effects_list = {},
    block_partner_pixel_shift,
  } = data;
  const currentEffectLabel = interaction_effects_list[interaction_effect] || 'Сердечко';
  const [offsetX, setOffsetX] = useLocalState('pixelshift_offset_x', 0);
  const [offsetY, setOffsetY] = useLocalState('pixelshift_offset_y', 0);
  const [speed, setSpeed] = useLocalState('pixelshift_speed', 30);
  const [animateOnClick, setAnimateOnClick] = useLocalState('pixelshift_animate_on_click', false);
  const mapRef = useRef(null);

  const syncOffset = (x, y, newSpeed, playAnimation) => {
    act('pixel_shift', {
      type: 'set',
      dx: x,
      dy: y,
      speed: newSpeed,
      play_animation: playAnimation,
    });
  };

  const handleSpeed = (value) => {
    setSpeed(value);
    syncOffset(offsetX, offsetY, value, false);
  };

  const handleReset = () => {
    setOffsetX(0);
    setOffsetY(0);
    act('pixel_shift', { type: 'reset' });
  };

  const offsetLabel = (offsetX === 0 && offsetY === 0)
    ? '0 px / 0 px'
    : [
      `${Math.abs(offsetX)} px ${offsetX > 0 ? 'вправо' : offsetX < 0 ? 'влево' : ''}`.trim(),
      `${Math.abs(offsetY)} px ${offsetY > 0 ? 'вверх' : offsetY < 0 ? 'вниз' : ''}`.trim(),
    ].filter(part => !part.startsWith('0 px')).join(' / ') || '0 px / 0 px';

  const mapReach = MAP_SIZE / 2 - 10;
  const heartOffsetX = (offsetX / MAX_SHIFT) * mapReach;
  const heartOffsetY = (offsetY / MAX_SHIFT) * mapReach;

  const applyPointerPosition = (clientX, clientY, playAnimation = false) => {
    const rect = mapRef.current.getBoundingClientRect();
    const dx = clientX - (rect.left + rect.width / 2);
    const dy = clientY - (rect.top + rect.height / 2);
    const clampedDx = Math.max(-mapReach, Math.min(mapReach, dx));
    const clampedDy = Math.max(-mapReach, Math.min(mapReach, dy));
    const x = clampShift(Math.round((clampedDx / mapReach) * MAX_SHIFT));
    const y = clampShift(Math.round((-clampedDy / mapReach) * MAX_SHIFT));
    setOffsetX(x);
    setOffsetY(y);
    syncOffset(x, y, speed, playAnimation);
  };

  const handleMapMouseDown = (e) => {
    e.preventDefault();
    applyPointerPosition(e.clientX, e.clientY, animateOnClick);
    const handleMouseMove = (moveEvent) => {
      applyPointerPosition(moveEvent.clientX, moveEvent.clientY, false);
    };
    const handleMouseUp = () => {
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', handleMouseUp);
    };
    window.addEventListener('mousemove', handleMouseMove);
    window.addEventListener('mouseup', handleMouseUp);
  };

  return (
    <Section title="PixelShift Navigation">
      <Stack fill justify="space-between">
        <Stack.Item>
          <Box>
            <Box bold>Center Position</Box>
            <Box>{offsetLabel}</Box>
          </Box>
          <Box mt={1}>
            <Box bold>Playback Speed</Box>
            <Box mt={0.5}>
              <Slider
                fluid
                minValue={1}
                maxValue={60}
                step={1}
                value={speed}
                unit="px/s"
                stepPixelSize={3}
                onChange={(e, value) => handleSpeed(value)}
              />
            </Box>
            <Box color="label">
              Скорость воспроизведения анимации (px/s)
            </Box>
            <Button
              fluid
              mt={1}
              icon={animateOnClick ? 'toggle-on' : 'toggle-off'}
              selected={animateOnClick}
              color={animateOnClick ? 'green' : 'default'}
              content="Animate on LMB"
              onClick={() => setAnimateOnClick(!animateOnClick)}
            />
            <Button
              fluid
              mt={1}
              color="red"
              content="Reset"
              onClick={handleReset}
            />
          </Box>
        </Stack.Item>
        <Stack.Item mr={1}>
          <div
            ref={mapRef}
            onMouseDown={handleMapMouseDown}
            style={{
              position: 'relative',
              width: `${MAP_SIZE}px`,
              height: `${MAP_SIZE}px`,
              background: 'rgba(255, 255, 255, 0.03)',
              outline: '1px solid rgba(255, 255, 255, 0.15)',
              borderRadius: '0.4em',
              overflow: 'hidden',
              cursor: 'crosshair',
              backgroundImage:
                'linear-gradient(to right, rgba(255, 255, 255, 0.08) 1px, transparent 1px),'
                + 'linear-gradient(to bottom, rgba(255, 255, 255, 0.08) 1px, transparent 1px)',
              backgroundSize: '14px 14px',
            }}>
            <div
              style={{
                position: 'absolute',
                left: '50%',
                top: '0',
                width: '1px',
                height: '100%',
                transform: 'translateX(-50%)',
                background: 'rgba(147, 112, 219, 0.6)',
              }} />
            <div
              style={{
                position: 'absolute',
                left: '0',
                top: '50%',
                width: '100%',
                height: '1px',
                transform: 'translateY(-50%)',
                background: 'rgba(255, 105, 180, 0.6)',
              }} />
            <div
              style={{
                position: 'absolute',
                left: '50%',
                top: '50%',
                transform: `translate(calc(${heartOffsetX}px - 50%), calc(${-heartOffsetY}px - 50%))`,
                color: '#ff69b4',
                fontSize: '20px',
              }}>
              <Icon name="heart" />
            </div>
          </div>
        </Stack.Item>
      </Stack>
      <Section title="Interaction Effects" mt={2}>
        <Stack vertical>
          <Stack.Item>
            <Stack fill align="center">
              <Stack.Item grow>
                Показывать эффект над собой
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon={show_heart_over_self ? 'toggle-on' : 'toggle-off'}
                  color={show_heart_over_self ? 'green' : 'default'}
                  selected={show_heart_over_self}
                  onClick={() => act('pref', { pref: 'show_heart_over_self' })}
                />
              </Stack.Item>
            </Stack>
          </Stack.Item>

          <Stack.Item>
            <Stack fill align="center">
              <Stack.Item grow>
                Эффект взаимодействия
              </Stack.Item>
              <Stack.Item>
                <Dropdown
                  width="180px"
                  options={Object.keys(interaction_effects_list).map(key => interaction_effects_list[key])}
                  selected={currentEffectLabel}
                  displayText={currentEffectLabel}
                  onSelected={(label) => {
                    const key = Object.keys(interaction_effects_list).find(k => interaction_effects_list[k] === label);
                    if (key) {
                      act('pref', { pref: 'interaction_effect', effect: key });
                    }
                  }}
                />
              </Stack.Item>
            </Stack>
          </Stack.Item>

          <Stack.Item>
            <Stack fill align="center">
              <Stack.Item grow>
                Блокировать pixelshift-анимацию партнёра
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon={block_partner_pixel_shift ? 'toggle-on' : 'toggle-off'}
                  color={block_partner_pixel_shift ? 'red' : 'default'}
                  selected={block_partner_pixel_shift}
                  onClick={() => act('pref', { pref: 'block_partner_pixel_shift' })}
                />
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Section>
    </Section>
  );
};

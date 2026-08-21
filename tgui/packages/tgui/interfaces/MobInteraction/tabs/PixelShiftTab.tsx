import { useRef } from 'react';

import { useBackend, useLocalState } from '../../../backend';
import { Button, Dropdown, Icon, Knob, NumberInput, Section, Stack } from '../../../components';

const HoldButton = (props) => {
  const { onHold, holdInterval = 60, ...rest } = props;
  const timerRef = useRef(null);
  const onHoldRef = useRef(onHold);
  onHoldRef.current = onHold;

  const stopHolding = () => {
    if (timerRef.current) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }
  };

  const startHolding = () => {
    onHoldRef.current();
    stopHolding();
    timerRef.current = setInterval(() => onHoldRef.current(), holdInterval);
  };

  return (
    <Button
      {...rest}
      onMouseDown={(e) => {
        e.preventDefault();
        startHolding();
      }}
      onMouseUp={stopHolding}
      onMouseLeave={stopHolding}
    />
  );
};

const ROWS = [
  [
    { key: 'northwest', icon: 'arrow-up', iconRotation: -45, dx: -1, dy: 1 },
    { key: 'north', icon: 'arrow-up', iconRotation: 0, dx: 0, dy: 1 },
    { key: 'northeast', icon: 'arrow-up', iconRotation: 45, dx: 1, dy: 1 },
  ],
  [
    { key: 'west', icon: 'arrow-left', iconRotation: 0, dx: -1, dy: 0 },
    null,
    { key: 'east', icon: 'arrow-right', iconRotation: 0, dx: 1, dy: 0 },
  ],
  [
    { key: 'southwest', icon: 'arrow-down', iconRotation: 45, dx: -1, dy: -1 },
    { key: 'south', icon: 'arrow-down', iconRotation: 0, dx: 0, dy: -1 },
    { key: 'southeast', icon: 'arrow-down', iconRotation: -45, dx: 1, dy: -1 },
  ],
];

const MAX_SHIFT = 32;

const directionLabel = (dx, dy) => {
  const x = dx === 0 ? '' : dx > 0 ? 'East' : 'West';
  const y = dy === 0 ? '' : dy > 0 ? 'North' : 'South';
  return [y, x].filter(Boolean).join('-') || 'Center';
};

const clampShift = (value) => Math.max(-MAX_SHIFT, Math.min(MAX_SHIFT, value));

type PixelShiftPrefs = {
  show_heart_over_self: boolean;

  interaction_effect: string;

  interaction_effects_list: Record<string, string>;
  block_partner_pixel_shift: boolean;
};

const EFFECT_ICONS = {
  heart: 'heart',
};

export const Pixelshift = (props) => {
  const { act, data } = useBackend<PixelShiftPrefs>();
  const {
    show_heart_over_self,

    interaction_effect,
    interaction_effects_list = {},
    block_partner_pixel_shift,
  } = data;
  const effectIcon = EFFECT_ICONS[interaction_effect] || 'heart';
  const currentEffectLabel = interaction_effects_list[interaction_effect] || 'Сердечко';
  const [offsetX, setOffsetX] = useLocalState('pixelshift_offset_x', 0);
  const [offsetY, setOffsetY] = useLocalState('pixelshift_offset_y', 0);
  const [speed, setSpeed] = useLocalState('pixelshift_speed', 30);
  const [animateOnClick, setAnimateOnClick] = useLocalState('pixelshift_animate_on_click', false);

  const syncOffset = (x, y, newSpeed, playAnimation) => {
    act('pixel_shift', {
      type: 'set',
      dx: x,
      dy: y,
      speed: newSpeed,
      play_animation: playAnimation,
    });
  };

  const handleDirection = (direction) => {
    const x = clampShift(offsetX + direction.dx);
    const y = clampShift(offsetY + direction.dy);
    setOffsetX(x);
    setOffsetY(y);
    syncOffset(x, y, speed, animateOnClick);
  };

  const handleStop = () => {
    setOffsetX(0);
    setOffsetY(0);
    act('pixel_shift', { type: 'reset' });
  };

  const handleSpeed = (value) => {
    setSpeed(value);
    syncOffset(offsetX, offsetY, value, false);
  };

  return (
    <Section title="PixelShift Navigation">
      <Stack fill>
        <Stack.Item>
          {ROWS.map((row, rowIndex) => (
            <Stack key={rowIndex} mb={rowIndex < ROWS.length - 1 ? 1 : 0}>
              {row.map((direction) => (
                <Stack.Item mx={1} key={direction ? direction.key : 'stop'}>
                  {direction ? (
                    <HoldButton
                      icon={direction.icon}
                      iconRotation={direction.iconRotation}
                      tooltip={directionLabel(direction.dx, direction.dy)}
                      onHold={() => handleDirection(direction)}
                    />
                  ) : (
                    <Button
                      color="red"
                      icon="stop"
                      tooltip="Reset"
                      onClick={handleStop}
                    />
                  )}
                </Stack.Item>
              ))}
            </Stack>
          ))}
        </Stack.Item>
        <Stack.Item grow>
          <Stack fill>
            <Stack.Item grow>
              <div
                style={{
                  position: 'relative',
                  width: '64px',
                  height: '64px',
                  margin: '0 auto',
                  background: '#000000',
                  outline: '1px solid #ffffff',
                  backgroundImage:
                    'linear-gradient(to right, rgba(255, 255, 255, 0.6) 1px, transparent 1px),'
                    + 'linear-gradient(to bottom, rgba(255, 255, 255, 0.6) 1px, transparent 1px)',
                  backgroundSize: '8px 8px',
                }}>
                <div
                  style={{
                    position: 'absolute',
                    left: '50%',
                    top: '50%',
                    width: '1px',
                    height: '1px',
                    background: '#ffffff',
                  }} />
                <div
                  style={{
                    position: 'absolute',
                    left: '50%',
                    top: '0',
                    width: '2px',
                    height: '100%',
                    transform: 'translateX(-50%)',
                    background: '#0000ff',
                  }} />
                <div
                  style={{
                    position: 'absolute',
                    left: '0',
                    top: '50%',
                    width: '100%',
                    height: '2px',
                    transform: 'translateY(-50%)',
                    background: '#ff0000',
                  }} />
                <div
                  style={{
                    position: 'absolute',
                    left: '50%',
                    top: '50%',
                    transform: `translate(calc(${offsetX}px - 50%), calc(${offsetY * -1}px - 50%))`,
                    color: '#ff69b4',
                    fontSize: '16px',
                  }}>
                  <Icon name="heart" />
                </div>
              </div>
              <div>{directionLabel(offsetX, offsetY)}</div>
              <div>
                {Math.abs(offsetX)} px {offsetX < 0 ? 'left' : offsetX > 0 ? 'right' : ''}
                {' / '}
                {Math.abs(offsetY)} px {offsetY > 0 ? 'up' : offsetY < 0 ? 'down' : ''}
              </div>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
      <Stack fill mt={1} justify="space-between">
        <Stack.Item>
          <Stack align="center">
            <Stack.Item>
              <Knob
                animated
                size={1.4}
                value={speed}
                minValue={1}
                maxValue={60}
                step={1}
                onChange={(e, value) => handleSpeed(value)}
              />
            </Stack.Item>
            <Stack.Item>
              <NumberInput
                width="64px"
                value={speed}
                minValue={1}
                maxValue={60}
                step={1}
                unit="px/s"
                onChange={(e, value) => handleSpeed(value)}
              />
            </Stack.Item>
          </Stack>
          <div style={{ fontSize: '12px', color: '#ffffff' }}>
            Скорость воспроизведения анимации (px/s)
          </div>
        </Stack.Item>
        <Stack.Item align="center">
          <Button
            icon={animateOnClick ? 'toggle-on' : 'toggle-off'}
            color={animateOnClick ? 'green' : 'default'}
            content="Animate on arrow click"
            tooltip="Play the pixel shift animation when pressing a direction arrow"
            onClick={() => setAnimateOnClick(!animateOnClick)}
          />
        </Stack.Item>
      </Stack>
      <Section title="Interaction Effects" mt={1}>
        <Stack vertical>
          <Stack.Item>
            <Stack fill align="center">
              <Stack.Item>
                <Icon name={effectIcon} color="#ff69b4" />
              </Stack.Item>
              <Stack.Item grow>
                Показывать эффект над собой
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon={show_heart_over_self ? 'toggle-on' : 'toggle-off'}
                  color={show_heart_over_self ? 'green' : 'default'}
                  selected={show_heart_over_self}
                  tooltip="Показывать всплывающий эффект над собой при интеракциях"
                  onClick={() => act('pref', { pref: 'show_heart_over_self' })}
                />
              </Stack.Item>
            </Stack>
          </Stack.Item>

          <Stack.Item>
            <Stack fill align="center">
              <Stack.Item grow>
                Эффект интеракций
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
                  tooltip="Запретить партнёру проигрывать pixelshift-анимацию, когда он нажимает интеракции, направленные на вас"
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

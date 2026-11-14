import { useBackend } from '../../backend';
import { Button, Icon, ProgressBar, Slider, Stack, Tooltip } from '../../components';

type Flag = boolean | 0 | 1;

type HeaderInfo = {
  isTargetSelf: Flag;
  target: string | null;
  lust: number;
  maxLust: number;
  theirLust: number | null;
  theirMaxLust: number | null;
  use_arousal_multiplier: Flag;
  arousal_multiplier: number;
  use_moaning_multiplier: Flag;
  moaning_multiplier: number;
};

const EFFECT_PREFS = [
  {
    toggle: 'use_arousal_multiplier',
    value: 'arousal_multiplier',
    label: 'Множитель возбуждения',
    max: 300,
    stepPixelSize: 3,
    ranges: {
      bad: [-Infinity, 75],
      good: [76, 125],
      average: [126, Infinity],
    },
  },
  {
    toggle: 'use_moaning_multiplier',
    value: 'moaning_multiplier',
    label: 'Свой шанс стона',
    max: 100,
    stepPixelSize: undefined,
    ranges: undefined,
  },
] as const;

const LustBar = ({ value, max, label, showTooltip }: { value: number; max: number; label: string; showTooltip: boolean }) => {
  const bar = (
    <ProgressBar role="progressbar" aria-label={label} value={value} maxValue={Math.max(1, max)} color="purple">
      <Icon name="heart" />
    </ProgressBar>
  );
  return showTooltip ? <Tooltip content={label}><div>{bar}</div></Tooltip> : bar;
};

export const InfoSection = () => {
  const { act, data } = useBackend<HeaderInfo>();
  const hasPartner = !!data.target && !data.isTargetSelf;
  const { theirLust, theirMaxLust } = data;
  const showPartnerLust = hasPartner && typeof theirLust === 'number' && typeof theirMaxLust === 'number';

  return (
    <Stack vertical>
      {showPartnerLust && (
        <Stack.Item>
          <LustBar value={theirLust} max={theirMaxLust} label="Возбуждение партнёра" showTooltip />
        </Stack.Item>
      )}
      <Stack.Item>
        <LustBar value={data.lust ?? 0} max={data.maxLust ?? 1} label="Твоё возбуждение" showTooltip={showPartnerLust} />
      </Stack.Item>
      <Stack.Item>
        <Stack>
          <Stack.Item grow basis={0}>
            <Button fluid mb={0} content="Твои гениталии" color="pink" onClick={() => act('genitals_menu', { who: 'user' })} />
          </Stack.Item>
          {hasPartner && (
            <Stack.Item grow basis={0}>
              <Button fluid mb={0} content="Гениталии партнёра" color="pink" onClick={() => act('genitals_menu', { who: 'target' })} />
            </Stack.Item>
          )}
        </Stack>
      </Stack.Item>
      <Stack.Item>
        <Stack>
          {EFFECT_PREFS.map(({ toggle, value, label, max, stepPixelSize, ranges }) => {
            const enabled = !!data[toggle];
            return (
              <Stack.Item key={toggle} grow basis={0}>
                <Stack align="center">
                  <Stack.Item grow={!enabled}>
                    <Button
                      fluid
                      mb={0}
                      content={enabled ? undefined : label}
                      aria-label={label}
                      tooltip={label}
                      icon={enabled ? 'toggle-on' : 'toggle-off'}
                      selected={enabled}
                      onClick={() => act('pref', { pref: toggle })}
                    />
                  </Stack.Item>
                  {enabled && (
                    <Stack.Item grow basis={0}>
                      <Tooltip content={label}>
                        <Slider
                          minValue={0}
                          maxValue={max}
                          step={1}
                          stepPixelSize={stepPixelSize}
                          value={data[value]}
                          unit="%"
                          ranges={ranges}
                          onChange={(_, amount) => act('pref', { pref: value, amount })}
                        />
                      </Tooltip>
                    </Stack.Item>
                  )}
                </Stack>
              </Stack.Item>
            );
          })}
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

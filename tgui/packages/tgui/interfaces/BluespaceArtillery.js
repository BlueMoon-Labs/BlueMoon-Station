import { useBackend } from '../backend';
import { Box, Button, LabeledList, NoticeBox, NumberInput, ProgressBar, Section } from '../components';
import { Window } from '../layouts';

const formatPower = (x) => {
  if (x === null || x === undefined) return '—';
  if (x >= 1e9) return (x / 1e9).toFixed(1) + ' GW';
  if (x >= 1e6) return (x / 1e6).toFixed(1) + ' MW';
  if (x >= 1e3) return (x / 1e3).toFixed(1) + ' kW';
  return String(x) + ' W';
};

export const BluespaceArtillery = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    notice,
    connected,
    unlocked,
    target,
    status,
    capacitor_charge = 0,
    target_capacitor_charge = 0,
    max_capacitor_charge = 1,
    powernet_power,
    power_suck_cap,
  } = data;
  const canFire = connected && unlocked && target && status === 'SYSTEM READY';
  const chargePct = max_capacitor_charge > 0 ? Math.min(100, (capacitor_charge / max_capacitor_charge) * 100) : 0;
  return (
    <Window
      width={420}
      height={320}>
      <Window.Content>
        {!!notice && (
          <NoticeBox>
            {notice}
          </NoticeBox>
        )}
        {connected ? (
          <>
            <Section
              title="Target"
              buttons={(
                <Button
                  icon="crosshairs"
                  disabled={!unlocked}
                  onClick={() => act('recalibrate')} />
              )}>
              <Box
                color={target ? 'average' : 'bad'}
                fontSize="25px">
                {target || 'No Target Set'}
              </Box>
            </Section>
            <Section title="Capacitor (power scales with charge)">
              <LabeledList>
                <LabeledList.Item label="Status">
                  {status || '—'}
                </LabeledList.Item>
                <LabeledList.Item label="Charge">
                  <ProgressBar value={chargePct} color="blue" />
                  <Box inline ml={1}>
                    {formatPower(capacitor_charge)} / {formatPower(target_capacitor_charge)} (max {formatPower(max_capacitor_charge)})
                  </Box>
                </LabeledList.Item>
                <LabeledList.Item label="Powernet">
                  {formatPower(powernet_power)} (suck cap: {formatPower(power_suck_cap)})
                </LabeledList.Item>
                <LabeledList.Item label="Target charge (MW)">
                  <NumberInput
                    value={target_capacitor_charge / 1e6}
                    minValue={1}
                    maxValue={max_capacitor_charge / 1e6}
                    step={0.5}
                    stepPixelSize={30}
                    width="80px"
                    onChange={(e, val) => act('capacitor_target_change', { capacitor_target: Math.round((val || 1) * 1e6) })}
                  />
                </LabeledList.Item>
              </LabeledList>
              <Button
                mt={1}
                content="Charge from grid"
                icon="bolt"
                disabled={!unlocked || (status !== 'SYSTEM READY' && status !== 'SYSTEM POWER LOW')}
                onClick={() => act('charge')} />
            </Section>
            <Section>
              {unlocked ? (
                <Box style={{ margin: 'auto' }}>
                  <Button
                    fluid
                    content="FIRE"
                    color="bad"
                    disabled={!canFire}
                    fontSize="30px"
                    textAlign="center"
                    lineHeight="46px"
                    onClick={() => act('fire')} />
                </Box>
              ) : (
                <>
                  <Box
                    color="bad"
                    fontSize="18px">
                    Bluespace artillery is currently locked.
                  </Box>
                  <Box mt={1}>
                    Awaiting authorization via keycard reader from at minimum
                    two station heads.
                  </Box>
                </>
              )}
            </Section>
          </>
        ) : (
          <Section>
            <LabeledList>
              <LabeledList.Item label="Maintenance">
                <Button
                  icon="wrench"
                  content="Complete Deployment"
                  onClick={() => act('build')} />
              </LabeledList.Item>
            </LabeledList>
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};

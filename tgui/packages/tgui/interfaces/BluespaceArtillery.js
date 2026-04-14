import { useBackend } from '../backend';
import { Box, Button, LabeledList, NoticeBox, Section, Slider } from '../components';
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

  const maxCap = Math.max(1, Number(max_capacitor_charge) || 0);
  const targetCap = Math.min(maxCap, Math.max(0, Number(target_capacitor_charge) || 0));
  const capCharge = Math.max(0, Number(capacitor_charge) || 0);
  const powerStep = 1e6;

  const canFire = connected && unlocked && target && status === 'SYSTEM READY';
  return (
    <Window
      width={600}
      height={600}>
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
            <Section title="System Status">
              <Box
                color={
                status === 'SYSTEM READY'
                  ? 'green'
                  : status === 'SYSTEM CHARGING CAPACITORS'
                    ? 'average'
                    : 'bad'
                }
                fontSize="25px"
              >
                {status || '—'}
              </Box>
            </Section>
            <Section
              title="Capacitor (power scales with charge)"
              buttons={
                <Button
                  content="Charge Capacitors"
                  icon="bolt"
                  color="orange"
                  disabled={status !== 'SYSTEM READY' && status !== 'SYSTEM POWER LOW'}
                  onClick={() => act('charge')}
                />
              }
            >
              <LabeledList>
                <LabeledList.Item label="Capacitor Charge">
                  {formatPower(capCharge)}
                </LabeledList.Item>
                <LabeledList.Item label="Powernet">
                  {formatPower(powernet_power != null ? Number(powernet_power) : null)}
                  {' '}(suck cap:{' '}
                  {formatPower(power_suck_cap != null ? Number(power_suck_cap) : null)})
                </LabeledList.Item>
                <LabeledList.Item label="Target charge">
                  <Slider
                    value={targetCap}
                    fillValue={Math.min(capCharge, maxCap)}
                    minValue={0}
                    maxValue={maxCap}
                    step={powerStep}
                    stepPixelSize={2}
                    suppressFlicker={500}
                    format={(value) => formatPower(value)}
                    onChange={(e, value) => {
                      const v = Math.round(Number(value) / powerStep) * powerStep;
                      act('capacitor_target_change', {
                        capacitor_target: Math.min(maxCap, Math.max(0, v)),
                      });
                    }}
                  />
                </LabeledList.Item>
              </LabeledList>
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

import { useState } from 'react';

import { useBackend } from '../backend';
import { Button, Grid, Section, Stack, Tooltip } from '../components';
import { Window } from '../layouts';

export const LewdDeprivationContent = (props) => {
  const { act, data } = useBackend();
  const { mute, levels } = data;

  return (
    <Section scrollable>
      <Stack vertical fill>
        <Stack.Item grow basis={0}>
          <Section title="Депривация" fill>
            <Grid mt={0.6}>
              <Grid.Column>
                <b>Голос</b>
              </Grid.Column>
            </Grid>

            {levels.map((level) => (
              <Grid mt={0.2}>
                <Stack>
                  <Stack.Item grow>
                    <Tooltip content={`${level.desc || `${level.value}% речи неразборчиво`}`}>
                      <Button
                        fluid
                        icon={"check"}
                        color={mute === level.value ? "green" : "default"}
                        onClick={() => act('set_mute', { level: level.value })}>
                        {level.label}
                      </Button>
                    </Tooltip>
                  </Stack.Item>
                </Stack>
              </Grid>
            ))}
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const BASE_HEIGHT = 230;
const HEIGHT_PER_BUTTON = 20;

export const LewdDeprivation = (props) => {
  const { act, data, windowTitle } = useBackend();
  const [height] = useState(() => {
    if (!data.dynamic_window_size) {
      return BASE_HEIGHT;
    }
    // Высота на основе количества опций
    const enabledButtonsCount = Array.isArray(data.levels) ? data.levels.length : 4;
    return BASE_HEIGHT + enabledButtonsCount * HEIGHT_PER_BUTTON;
  });

  return (
    <Window width={200} height={height} title={windowTitle}>
      <Window.Content>
        <LewdDeprivationContent />
      </Window.Content>
    </Window>
  );
};

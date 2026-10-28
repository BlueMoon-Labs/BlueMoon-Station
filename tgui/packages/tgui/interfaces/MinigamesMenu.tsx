import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import { Box, Button, Divider, Section, Stack } from '../components';
import { Window } from '../layouts';

type Data = {
  mafia_running: BooleanLike;
};

export function MinigamesMenu(props) {
  const { act, data } = useBackend<Data>();

  return (
    <Window title="Minigames Menu" width={420} height={300}>
      <Window.Content>
        <Section title="Select Minigame" textAlign="center" fill>
          <Stack>
            <Stack.Item grow>
              <Button
                content="Mafia"
                fluid
                fontSize={3}
                textAlign="center"
                lineHeight="3"
                disabled={!!data.mafia_running}
                tooltip={
                  data.mafia_running
                    ? 'A mafia game is already running.'
                    : 'Start or join a game of Mafia.'
                }
                onClick={() => act('mafia')}
              />
            </Stack.Item>
            <Stack.Item grow>
              <Button
                content="Deathmatch"
                fluid
                fontSize={3}
                textAlign="center"
                lineHeight="3"
                tooltip="Browse open deathmatch lobbies or spectate a running game."
                onClick={() => act('deathmatch')}
              />
            </Stack.Item>
          </Stack>
          <Divider />
          <Box color="label" textAlign="center">
            More minigames coming soon.
          </Box>
        </Section>
      </Window.Content>
    </Window>
  );
}

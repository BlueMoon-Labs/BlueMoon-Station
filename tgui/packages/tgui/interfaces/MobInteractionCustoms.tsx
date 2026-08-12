import { Box, Section, Stack } from '../components';
import { Window } from '../layouts';
import { CustomInteractionsTab } from './MobInteraction/tabs/CustomInteractionsTab';

export const MobInteractionCustoms = () => {
  return (
    <Window width={600} height={800} resizable>
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item grow>
            <Section scrollable fill>
              <CustomInteractionsTab />
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Box color="gray" align="center" fontSize="0.8rem" opacity={0.6} py={0.5}>
              Сделал Pe4henika &lt;3
            </Box>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

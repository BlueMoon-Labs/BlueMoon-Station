import { useBackend } from '../backend';
import { Button, Flex, Section } from '../components';
import { Window } from '../layouts';

export const AdminJumpTo = (props) => {
  const { act } = useBackend();
  return (
    <Window title="Admin Jump To" width={220} height={280}>
      <Window.Content>
        <Section fill>
          <Flex direction="column">
            <Button
              content="Jump to Mob"
              icon="user"
              mb="0.5rem"
              onClick={() => act('jump_mob')}
            />
            <Button
              content="Jump to Key"
              icon="key"
              mb="0.5rem"
              onClick={() => act('jump_key')}
            />
            <Button
              content="Jump to Area"
              icon="map-marker-alt"
              mb="0.5rem"
              onClick={() => act('jump_area')}
            />
            <Button
              content="Jump to Turf"
              icon="cube"
              mb="0.5rem"
              onClick={() => act('jump_turf')}
            />
            <Button
              content="Jump to Coordinate"
              icon="compass"
              onClick={() => act('jump_coord')}
            />
          </Flex>
        </Section>
      </Window.Content>
    </Window>
  );
};

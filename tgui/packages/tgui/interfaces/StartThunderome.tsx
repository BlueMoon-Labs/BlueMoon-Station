import { useBackend } from '../backend';
import { Box, Button, Flex, NumberInput, Section } from '../components';
import { Window } from '../layouts';

const DEFAULT_TEAMSIZE = 3;

export const StartThunderome = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Window
      title={"Start Thunderome"}
      width={600}
      height={500}>
      <Window.Content>
        <Flex direction="row">
          <Flex.Item grow><TeamSection teamNumber={1} /></Flex.Item>
          <Flex.Item grow><TeamSection teamNumber={2} /></Flex.Item>
        </Flex>
        <Flex>
        <Flex.Item grow>
          <Button
            fluid
            textAlign="center"
            content="Начать Тандер!"
            color="red"
            fontSize={2}
            py={1.5}
            mt={2}
            icon="rocket"
            onClick={(e) => act("start-thunderome")} />
        </Flex.Item>
        </Flex>
      </Window.Content>
    </Window>
  );
};

const TeamSection = (props, context) => {
  const { data, act } = useBackend(context);
  const { teamNumber } = props;
  return (
    <Section title={`Команда ${teamNumber}`} textAlign="center">
      <Box
        as="img"
        m={0}
        mb={1}
        src={`data:image/jpeg;base64,${data[`team_${teamNumber}`]["icon64"]}`}
        width="100%"
        style={{
          '-ms-interpolation-mode': 'nearest-neighbor',
        }} />
      <Flex textAlign="right" align="center">
        <Flex.Item grow>
          Игроки:&nbsp;
        </Flex.Item>
        <Flex.Item>
          <NumberInput
            value={data[`team_${teamNumber}`]["players"]}
            width="35px"
            minValue={1}
            maxValue={16}
            onChange={(e, players) => act('team-set-players', { team: teamNumber, players })} />
        </Flex.Item>
      </Flex>
      <Button fluid icon="tshirt" content="Выбрать эквип" onClick={() => act('select-equip', { team: teamNumber })} mt={1} />
    </Section>
  );
};

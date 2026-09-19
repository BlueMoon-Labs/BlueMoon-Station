import { useBackend } from '../backend';
import { Box, Button, Divider, Section } from '../components';
import { Window } from '../layouts';

export const Objective = (props) => {
  const { act, data } = useBackend();
  const {
    possible_objectives = [],
    selected_objective = null,
  } = data;
  return (
    <Window
      width={400}
      height={500}
      resizable>
      <Window.Content
        scrollable>
        <Section
          title="Контроль исполнения"
          key="645">
          <Button
            icon="trash"
            content="Отказаться"
            disabled={!selected_objective}
            onClick={() => act('remove')} />
        </Section>
        {!selected_objective || <SelectedObjective
          objective={selected_objective} />}
        {possible_objectives.map(objective => (
          <Section
            title={objective.name}
            key={objective.id}>
            <Box mb={1}>
              Payout: {objective.payout}
            </Box>
            <Box mb={1}>
              {objective.description}
            </Box>
            <Button
              content="Принять"
              icon="check"
              onClick={e => act("assign", {
                "id": objective.id,
              })}
              disabled={selected_objective !== null} />
          </Section>
        ))}
      </Window.Content>
    </Window>
  );
};

export const SelectedObjective = (props) => {
  const {
    objective = [],
  } = props;
  return (
    <>
      <Section
        title={objective.name}>
        <Box>
          Награда: {objective.payout}
        </Box>
        <Box>
          {objective.description}
        </Box>
      </Section>
      <Divider />
    </>
  );
};

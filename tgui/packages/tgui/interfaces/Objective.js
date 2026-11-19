import { useBackend } from '../backend';
import { Box, Button, Divider, Section } from '../components';
import { Window } from '../layouts';

export const Objective = (props) => {
  const { act, data } = useBackend();
  const {
    possible_objectives = [],
    selected_objective = null,
    shift_cap = 0,
    shift_left = null,
    payable = {},
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
          {!!shift_cap && (
            <Box mt={1} color={shift_left > 0 ? 'label' : 'average'}>
              {shift_left > 0
                ? `NT тратит на задания до ${shift_cap} кр. за смену вместе с долей снабжения, осталось ${shift_left} кр.`
                : `Лимит оплаты заданий на смену (${shift_cap} кр.) исчерпан: дальше только очки Авангарда участникам вылета.`}
            </Box>
          )}
        </Section>
        {!selected_objective || <SelectedObjective
          objective={selected_objective}
          paid={shift_cap ? payable[selected_objective.id] : undefined} />}
        {possible_objectives.map(objective => (
          <Section
            title={objective.name}
            key={objective.id}>
            <Box mb={1}>
              <Payout
                payout={objective.payout}
                paid={shift_cap ? payable[objective.id] : undefined} />
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

const Payout = (props) => {
  const { payout, paid } = props;
  if (paid === undefined || paid === null) {
    return `Награда: ${payout}`;
  }
  return `Награда: ${payout}, оплатится ${paid} из ${payout} кр.`;
};

export const SelectedObjective = (props) => {
  const {
    objective = [],
    paid,
  } = props;
  return (
    <>
      <Section
        title={objective.name}>
        <Box>
          <Payout payout={objective.payout} paid={paid} />
        </Box>
        <Box>
          {objective.description}
        </Box>
      </Section>
      <Divider />
    </>
  );
};

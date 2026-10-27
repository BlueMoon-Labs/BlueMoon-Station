import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Dropdown, Section, Stack } from '../components';

export type GoalOption = { value: string; name: string };
export type GoalParam = { key: string; label: string; options: GoalOption[] };
export type GoalKind = { id: string; name: string; params: GoalParam[] };
export type GoalSpec = { name: string; side: string; side_name: string };
type GoalScenario = {
  leader: unknown;
  sides: { id: string; name: string }[];
  objective_specs?: GoalSpec[];
  objective_library?: GoalKind[] | null;
};

/** Цели своей сборки: список по сторонам, лидер добавляет из библиотеки и убирает. */
export const ScenarioGoals = (props: { scenario: GoalScenario; colorOf: (side: string) => string }) => {
  const { act } = useBackend();
  const { scenario, colorOf } = props;
  const leader = !!scenario.leader;
  const specs = scenario.objective_specs || [];
  return (
    <Section title="Цели сторон">
      {!specs.length && (
        <Box color="label" mb={1}>
          Целей нет: партия идёт, пока лидер не подведёт итог.{leader ? ' Добавьте цели ниже: сторона, выполнившая все свои цели, побеждает.' : ''}
        </Box>
      )}
      {specs.map((spec, index) => (
        <Stack key={index} align="center" mb={0.5}>
          <Stack.Item grow>
            <Box as="span" bold color={colorOf(spec.side)}>{spec.side_name}</Box> · {spec.name}
          </Stack.Item>
          {leader && (
            <Stack.Item>
              <Button icon="xmark" color="transparent" tooltip="Убрать цель" onClick={() => act('scenario_objective_remove', { index: index + 1 })} />
            </Stack.Item>
          )}
        </Stack>
      ))}
      {leader && <GoalAdd scenario={scenario} />}
    </Section>
  );
};

const GoalAdd = ({ scenario }: { scenario: GoalScenario }) => {
  const { act } = useBackend();
  const library = scenario.objective_library || [];
  const [kindId, setKindId] = useState(library[0]?.id || '');
  const [side, setSide] = useState(scenario.sides[0]?.id || '');
  const [values, setValues] = useState<Record<string, string>>({});
  const kind = library.find((entry) => entry.id === kindId) || library[0];
  if (!kind) {
    return <Box color="label" mt={1}>Место ещё загружается: цели появятся, когда оно будет готово.</Box>;
  }
  const optionsFor = (param: GoalParam) => (param.key === 'target' ? param.options.filter((option) => option.value !== side) : param.options);
  const valueOf = (param: GoalParam) => {
    const options = optionsFor(param);
    return options.some((option) => option.value === values[param.key]) ? values[param.key] : options[0]?.value || '';
  };
  const ready = kind.params.every((param) => !!valueOf(param));
  const send = () => {
    const payload: Record<string, string> = { kind: kind.id, side };
    kind.params.forEach((param) => {
      payload[param.key] = valueOf(param);
    });
    act('scenario_objective_add', payload);
  };
  return (
    <Box mt={1}>
      <Box bold mb={0.5}>Новая цель</Box>
      <Stack align="end" wrap>
        <Stack.Item>
          <Box color="label" mb={0.5}>Сторона</Box>
          <Dropdown width={12} selected={side} options={scenario.sides.map((entry) => ({ value: entry.id, displayText: entry.name }))} onSelected={setSide} />
        </Stack.Item>
        <Stack.Item>
          <Box color="label" mb={0.5}>Цель</Box>
          <Dropdown width={20} selected={kind.id} options={library.map((entry) => ({ value: entry.id, displayText: entry.name }))} onSelected={setKindId} />
        </Stack.Item>
        {kind.params.map((param) => (
          <Stack.Item key={param.key}>
            <Box color="label" mb={0.5}>{param.label}</Box>
            <Dropdown
              width={13}
              selected={valueOf(param)}
              options={optionsFor(param).map((option) => ({ value: option.value, displayText: option.name }))}
              onSelected={(value) => setValues({ ...values, [param.key]: value })}
            />
          </Stack.Item>
        ))}
        <Stack.Item>
          <Button icon="plus" disabled={!ready} onClick={send}>Добавить цель</Button>
        </Stack.Item>
      </Stack>
      <Box color="label" mt={0.5}>Места - метки выбранного сектора или площадки. Сторона, выполнившая все свои цели, побеждает; цель без участников на своей стороне не даст начать.</Box>
    </Box>
  );
};

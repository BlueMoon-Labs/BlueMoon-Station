import { useBackend } from '../backend';
import { Box, Button, NoticeBox, Section, Table } from '../components';
import { getGasLabel } from '../constants';
import { Window } from '../layouts';

type AlertEntry = {
  zone: string;
  cause?: string;
  cause_gas?: string;
  source?: string;
  clock?: string;
  age?: string;
};

type AtmosAlertData = {
  priority: AlertEntry[];
  minor: AlertEntry[];
};

const CAUSE_LABEL: Record<string, string> = {
  pressure: 'Давление',
  temperature: 'Температура',
  manual: 'Объявлена вручную',
};

const describeCause = (entry: AlertEntry): string => {
  if (entry.cause === 'gas') {
    return entry.cause_gas
      ? `Газ: ${getGasLabel(entry.cause_gas, entry.cause_gas)}`
      : 'Состав воздуха';
  }
  return CAUSE_LABEL[entry.cause] || 'Не указана';
};

const AlertRow = (props: {
  readonly entry: AlertEntry;
  readonly color: string;
}) => {
  const { entry, color } = props;
  const { act } = useBackend();
  return (
    <Table.Row>
      <Table.Cell color={color}>{entry.zone}</Table.Cell>
      <Table.Cell>{describeCause(entry)}</Table.Cell>
      <Table.Cell collapsing>
        {entry.age ? `${entry.age} назад` : '—'}
        {entry.clock && (
          <Box as="span" color="label">
            {' '}
            ({entry.clock})
          </Box>
        )}
      </Table.Cell>
      <Table.Cell collapsing>
        <Button
          icon="times"
          color={color}
          tooltip={entry.source ? `Источник: ${entry.source}` : undefined}
          content="Снять"
          onClick={() => act('clear', { zone: entry.zone })}
        />
      </Table.Cell>
    </Table.Row>
  );
};

export const AtmosAlertConsole = () => {
  const { act, data } = useBackend<AtmosAlertData>();
  const priorityAlerts = data.priority || [];
  const minorAlerts = data.minor || [];
  const total = priorityAlerts.length + minorAlerts.length;
  return (
    <Window width={520} height={400}>
      <Window.Content scrollable>
        <Section
          title={`Атмосферные тревоги (${total})`}
          buttons={
            <Button
              icon="broom"
              content="Снять все"
              disabled={total === 0}
              onClick={() => act('clear_all')}
            />
          }>
          {total === 0 ? (
            <NoticeBox success>Активных тревог нет.</NoticeBox>
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell>Зона</Table.Cell>
                <Table.Cell>Причина</Table.Cell>
                <Table.Cell collapsing>Когда</Table.Cell>
                <Table.Cell collapsing />
              </Table.Row>
              {priorityAlerts.map((entry) => (
                <AlertRow key={entry.zone} entry={entry} color="bad" />
              ))}
              {minorAlerts.map((entry) => (
                <AlertRow key={entry.zone} entry={entry} color="average" />
              ))}
            </Table>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};

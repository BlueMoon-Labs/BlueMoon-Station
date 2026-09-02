import { useBackend } from '../backend';
import { Box, Button, LabeledList, Section, Table } from '../components';
import { Window } from '../layouts';

export const ContrabandExchange = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    pad,
    sending,
    status_report,
    efficiency_multiplier,
    user_has_id,
    user_points,
    total_value,
    items_on_pad,
  } = data;

  return (
    <Window width={450} height={550}>
      <Window.Content>
        <Section title="Contraband Exchange Terminal">
          <LabeledList>
            <LabeledList.Item label="Status">
              {status_report}
            </LabeledList.Item>
            <LabeledList.Item label="Pad Linked">
              {pad ? (
                <Box color="good">Connected</Box>
              ) : (
                <Box color="bad">No pad linked (use multitool)</Box>
              )}
            </LabeledList.Item>
            <LabeledList.Item label="Efficiency">
              <Box color={efficiency_multiplier > 1 ? 'good' : 'label'}>
                {efficiency_multiplier.toFixed(2)}x
              </Box>
            </LabeledList.Item>
            <LabeledList.Item label="Your ID">
              {user_has_id ? (
                <Box color="good">
                  Detected | Points: {user_points}
                </Box>
              ) : (
                <Box color="bad">No ID detected</Box>
              )}
            </LabeledList.Item>
          </LabeledList>
        </Section>

        <Section title="Items on Pad">
          {items_on_pad && items_on_pad.length > 0 ? (
            <Table>
              <Table.Row header>
                <Table.Cell>Item</Table.Cell>
                <Table.Cell>Base</Table.Cell>
                <Table.Cell>Adjusted</Table.Cell>
              </Table.Row>
              {items_on_pad.map((item, i) => (
                <Table.Row key={i}>
                  <Table.Cell>{item.name}</Table.Cell>
                  <Table.Cell>{item.base_value}</Table.Cell>
                  <Table.Cell color="good">{item.adjusted_value}</Table.Cell>
                </Table.Row>
              ))}
              <Table.Row>
                <Table.Cell bold>Total:</Table.Cell>
                <Table.Cell />
                <Table.Cell bold color="good">{total_value} pts</Table.Cell>
              </Table.Row>
            </Table>
          ) : (
            <Box color="label">No contraband detected on pad.</Box>
          )}
        </Section>

        <Section>
          <Button
            icon="sync"
            content="Scan Items"
            disabled={!pad}
            onClick={() => act('recalc')}
          />
          <Button
            icon="paper-plane"
            content={sending ? 'Sending...' : 'Send Contraband'}
            disabled={!pad || sending || total_value === 0 || !user_has_id}
            color="good"
            onClick={() => act(sending ? 'stop' : 'send')}
          />
        </Section>

        {!user_has_id && (
          <Section title="Warning">
            <Box color="bad">
              Hold your ID card or wear it to receive bounty points!
            </Box>
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};

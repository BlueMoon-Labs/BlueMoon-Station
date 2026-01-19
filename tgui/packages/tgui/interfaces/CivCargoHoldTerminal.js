import { useBackend } from '../backend';
import { Box, Button, Flex, LabeledList, NoticeBox, Section } from '../components';
import { Window } from '../layouts';

export const CivCargoHoldTerminal = (props, context) => {
  const { act, data } = useBackend(context);
  const { pad, sending, status_report, id_inserted, id_bounty_info, picking }
    = data;
  const in_text = 'Welcome valued employee.';
  const out_text = 'To begin, insert your ID into the console.';
  return (
    <Window width={580} height={375}>
      <Window.Content overflow="auto">
        <Flex>
          <Flex.Item>
            <NoticeBox color={!id_inserted ? 'default' : 'blue'}>
              {id_inserted ? in_text : out_text}
            </NoticeBox>
            <Section
              title="Cargo Pad"
              buttons={
                <>
                  <Button
                    icon={'sync'}
                    tooltip={'Check Contents'}
                    disabled={!pad || !id_inserted}
                    onClick={() => act('recalc')}
                  />
                  <Button
                    icon={sending ? 'times' : 'arrow-up'}
                    tooltip={sending ? 'Stop Sending' : 'Send Goods'}
                    selected={sending}
                    disabled={!pad || !id_inserted}
                    onClick={() => act(sending ? 'stop' : 'send')}
                  />
                  <Button
                    icon={id_bounty_info ? 'recycle' : 'pen'}
                    color={id_bounty_info ? 'green' : 'default'}
                    tooltip={id_bounty_info ? 'Replace Bounty' : 'New Bounty'}
                    disabled={!id_inserted}
                    onClick={() => act('bounty')}
                  />
                  <Button
                    icon={'download'}
                    content={'Eject ID'}
                    disabled={!id_inserted}
                    onClick={() => act('eject')}
                  />
                </>
              }>
              <LabeledList>
                <LabeledList.Item label="Status" color={pad ? 'good' : 'bad'}>
                  {pad ? 'Online' : 'Not Found'}
                </LabeledList.Item>
                <LabeledList.Item label="Cargo Report">
                  {status_report}
                </LabeledList.Item>
              </LabeledList>
            </Section>
            {picking ? <BountyPickBox /> : <BountyTextBox />}
          </Flex.Item>
        </Flex>
      </Window.Content>
    </Window>
  );
};

const BountyTextBox = (props, context) => {
  const { data } = useBackend(context);
  const { id_bounty_name, id_bounty_info, id_bounty_value, id_bounty_num } = data;
  const na_text = 'N/A, please add a new bounty.';
  return (
    <Section title="Bounty Info">
      <LabeledList>
        <LabeledList.Item label="Name">
          {id_bounty_info ? id_bounty_name : na_text}
        </LabeledList.Item>
        <LabeledList.Item label="Description">
          {id_bounty_info ? id_bounty_info : 'N/A'}
        </LabeledList.Item>
        <LabeledList.Item label="Quantity">
          {id_bounty_info ? id_bounty_num : 'N/A'}
        </LabeledList.Item>
        <LabeledList.Item label="Value">
          {id_bounty_info ? id_bounty_value : 'N/A'}
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};

const BountyPickBox = (props, context) => {
  const { act, data } = useBackend(context);
  const { id_bounty_names, id_bounty_values } = data;
  return (
    <Section title="Please Select a Bounty:" textAlign="center">
      <Flex width="100%" wrap justify="center">
        {id_bounty_names.map((name, i) => (
          <Flex.Item
            key={i}
            basis="30%" // Три кнопки в ряд
            grow={0}
            shrink={0}
            px={0.5}
            mb={1}
          >
            <Button
              fluid
              color="green"
              content={name}
              onClick={() => act('pick', { value: i + 1 })}
            >
              <Box fontSize="14px">
                Payout: {id_bounty_values[i]} cr
              </Box>
            </Button>
          </Flex.Item>
        ))}
      </Flex>
    </Section>
  );
};

import { useBackend } from '../backend';
import { Button, Input, NoticeBox, Section, Stack } from '../components';
import { NtosWindow } from '../layouts';

export const NtosBanking = (props) => {
  const { act, data } = useBackend();
  const { has_account, balance, currency } = data;

  return (
    <NtosWindow width={400} height={350}>
      <NtosWindow.Content>
        {!has_account && (
          <NoticeBox danger>
            No client connection. Unable to access metadollar account.
          </NoticeBox>
        )}
        {has_account && (
          <>
            <Section title="Metadollar Account">
              <Stack vertical>
                <Stack.Item>
                  Balance: <b>{balance} {currency}</b>
                </Stack.Item>
              </Stack>
            </Section>
            <Section title="Withdraw Metadollars">
              <Input
                fluid
                placeholder="Amount"
                onEnter={(e, v) => act('withdraw', { amount: v })}
              />
            </Section>
            <Section title="Deposit Metadollars">
              <NoticeBox info>
                Hold a metadollar stack in your active hand, then press Deposit.
              </NoticeBox>
              <Button
                fluid
                icon="hand-holding-usd"
                content="Deposit Held Stack"
                onClick={() => act('deposit')}
              />
            </Section>
          </>
        )}
      </NtosWindow.Content>
    </NtosWindow>
  );
};

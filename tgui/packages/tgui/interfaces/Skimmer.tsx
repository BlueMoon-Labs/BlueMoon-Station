import { BooleanLike } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Input, LabeledList, NoticeBox, RestrictedInput, Section, Stack, Table } from '../components';
import { Window } from '../layouts';
import { Credits, formatCredits } from './common/Economy';

type StolenAccount = {
  ref: string;
  holder: string | null;
  number: number | null;
  balance: number;
  left: number;
  state: 'ok' | 'frozen' | 'blocked' | 'closed';
};

export type SkimmerData = {
  knows: BooleanLike;
  stolen?: StolenAccount[];
  rate?: number;
  slots?: number;
  transfer_max?: number;
  last_target?: number | null;
  message?: string;
};

const STATE_TEXT = {
  frozen: 'заморожен аудитом',
  blocked: 'заблокирован',
  closed: 'счёт закрыт',
};

const StolenRow = (props: { account: StolenAccount; target: string; amount: number }) => {
  const { act } = useBackend<SkimmerData>();
  const { account, target, amount } = props;
  const usable = account.state === 'ok';
  return (
    <Table.Row className="candystripe">
      <Table.Cell>
        {account.state === 'closed' ? (
          <Box color="label">{STATE_TEXT.closed}</Box>
        ) : (
          <>
            {account.holder} <Box inline color="label">№{account.number}</Box>
            <Box color="label">
              <Credits amount={account.balance} />
              {usable ? `, сейчас можно ещё ${formatCredits(account.left)}` : `, ${STATE_TEXT[account.state]}`}
            </Box>
          </>
        )}
      </Table.Cell>
      <Table.Cell collapsing nowrap>
        <Button
          icon="exchange-alt"
          content="Перевести"
          disabled={!usable || !target.trim() || amount < 1}
          onClick={() => act('siphon', { ref: account.ref, target: target.trim(), amount })}
        />
        <Button icon="eraser" tooltip="Стереть из памяти" onClick={() => act('forget', { ref: account.ref })} />
      </Table.Cell>
    </Table.Row>
  );
};

const SkimmerScreen = () => {
  const { data } = useBackend<SkimmerData>();
  const { stolen = [], rate = 0, slots = 0, transfer_max = 0, last_target, message } = data;
  const [target, setTarget] = useState(last_target ? String(last_target) : '');
  const [amount, setAmount] = useState(rate);
  return (
    <>
      {!!message && <NoticeBox>{message}</NoticeBox>}
      <Section title="Перевод">
        <LabeledList>
          <LabeledList.Item label="Счёт получателя">
            <Input fluid value={target} placeholder="Номер личного счёта" onInput={(_, value) => setTarget(value)} />
          </LabeledList.Item>
          <LabeledList.Item label="Сумма">
            <RestrictedInput
              width="6em"
              value={amount}
              minValue={1}
              maxValue={Math.min(rate, transfer_max)}
              onChange={(_, value) => setAmount(value)}
            />{' '}
            кр.
          </LabeledList.Item>
        </LabeledList>
      </Section>
      <Section title={`Скопированные счета: ${stolen.length}/${slots}`}>
        {stolen.length === 0 ? (
          <Box color="label">Память пуста: приложите скиммер к ID-карте или к человеку с картой.</Box>
        ) : (
          <Table>
            {stolen.map((account) => (
              <StolenRow key={account.ref} account={account} target={target} amount={amount} />
            ))}
          </Table>
        )}
      </Section>
      <Section title="Памятка">
        <Stack vertical>
          <Stack.Item color="label">
            С одного счёта - не больше {formatCredits(rate)} за любую минуту, общий лимит для всех скиммеров. Переводить
            можно только на личный счёт.
          </Stack.Item>
          <Stack.Item color="label">
            Новый скопированный счёт вытесняет самый старый, если память полна.
          </Stack.Item>
          <Stack.Item color="label">
            Каждое списание попадает в финансовый аудит как «неопознанное устройство» без вашего имени, а владелец счёта
            увидит его в истории операций.
          </Stack.Item>
        </Stack>
      </Section>
    </>
  );
};

/** Скиммер: предатель видит скопированные счета и переводит с них; постороннему - обычный считыватель. */
export const SkimmerContent = () => {
  const { data } = useBackend<SkimmerData>();
  if (!data.knows) {
    return (
      <Section title="Считыватель">
        <Box color="label">Бесконтактный считыватель платежей. Готов к работе.</Box>
      </Section>
    );
  }
  return <SkimmerScreen />;
};

export const Skimmer = () => {
  const { data } = useBackend<SkimmerData>();
  return (
    <Window width={420} height={520} theme={data.knows ? 'syndicate' : undefined}>
      <Window.Content scrollable>
        <SkimmerContent />
      </Window.Content>
    </Window>
  );
};

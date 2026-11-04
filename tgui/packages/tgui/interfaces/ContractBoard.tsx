import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import { AnimatedNumber, Box, Button, Collapsible, LabeledList, NoticeBox, Section } from '../components';
import { Window } from '../layouts';
import { ContractTable } from './common/ContractTable';
import { formatCredits } from './common/Economy';

type ContractBoardData = {
  mode: 'pad' | 'console';
  contracts_help?: string;
  my_name?: string | null;
  pad?: BooleanLike;
  pad_on_station?: BooleanLike;
  sending?: BooleanLike;
  status_report?: string;
  stored_cash?: number;
};

const PadSection = (props) => {
  const { act, data } = useBackend<ContractBoardData>();
  const { pad, pad_on_station, sending, status_report } = data;
  return (
    <Section
      title="Пад подработки"
      buttons={
        <>
          <Button icon="sync" content="Проверить" disabled={!pad} onClick={() => act('recalc')} />
          <Button
            icon={sending ? 'times' : 'arrow-up'}
            content={sending ? 'Отменить' : 'Отправить'}
            selected={sending}
            disabled={!pad}
            onClick={() => act(sending ? 'stop' : 'send')}
          />
        </>
      }>
      <LabeledList>
        <LabeledList.Item label="Пад" color={pad && pad_on_station ? 'good' : 'bad'}>
          {!pad ? 'Не найден' : pad_on_station ? 'На связи' : 'Вне станции'}
        </LabeledList.Item>
        <LabeledList.Item label="Отчёт">{status_report}</LabeledList.Item>
      </LabeledList>
      <Box color="label" mt={1}>
        Положите на пад то, что просят контракты поставки, и отправьте: подходящее уйдёт ЦК, остальное останется на
        месте.
      </Box>
    </Section>
  );
};

/** Доска контрактов NT: пункт подработки с падом и консоль контрактов снабжения. */
export const ContractBoardContent = (props) => {
  const { act, data } = useBackend<ContractBoardData>();
  const { mode, contracts_help, my_name, stored_cash } = data;
  return (
    <>
      <NoticeBox color={my_name ? 'blue' : 'default'}>
        {my_name ? `Счёт: ${my_name}` : 'Банковский счёт не найден: контракт не взять.'}
      </NoticeBox>
      {!!contracts_help && (
        <Collapsible title="Как работают контракты">
          <NoticeBox info>{contracts_help}</NoticeBox>
        </Collapsible>
      )}
      {mode === 'pad' && <PadSection />}
      <Section
        title="Контракты NT"
        buttons={
          mode === 'console' && (
            <>
              <Box inline bold mr={1}>
                {'Бюджет снабжения: '}
                <AnimatedNumber value={stored_cash ?? 0} format={(value) => formatCredits(value)} />
              </Box>
              <Button icon="print" content="Распечатать" onClick={() => act('Print')} />
            </>
          )
        }>
        <ContractTable />
      </Section>
    </>
  );
};

export const ContractBoard = (props) => {
  return (
    <Window width={760} height={600} resizable>
      <Window.Content scrollable>
        <ContractBoardContent />
      </Window.Content>
    </Window>
  );
};

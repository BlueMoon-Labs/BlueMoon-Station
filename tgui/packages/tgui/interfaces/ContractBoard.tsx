import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import { AnimatedNumber, Button } from '../components';
import { Window } from '../layouts';
import { ContractTable } from './common/ContractTable';
import { formatCredits } from './common/Economy';
import { NtFrame, NtHelpTopic, NtHelpTopics, NtLine, NtReadout, NtScreen } from './common/NtTerminal';

type ContractBoardData = {
  mode: 'pad' | 'console';
  contracts_help_topics?: NtHelpTopic[];
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
    <NtFrame
      title="Пад подработки"
      help="Положите на пад то, что просят контракты поставки, и отправьте: подходящее уйдёт ЦК, остальное останется на месте. Награда сразу зачисляется на счёт взявшего и отдела, ничего сдавать в снабжение не нужно."
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
      <NtLine label="Пад" tone={pad && pad_on_station ? 'good' : 'bad'}>
        {!pad ? 'Не найден' : pad_on_station ? 'На связи' : 'Вне станции'}
      </NtLine>
      <NtLine label="Отчёт">{status_report || '-'}</NtLine>
    </NtFrame>
  );
};

/** Доска контрактов NT: пункт подработки с падом и консоль контрактов снабжения. */
export const ContractBoardContent = (props) => {
  const { act, data } = useBackend<ContractBoardData>();
  const { mode, contracts_help_topics, my_name, stored_cash } = data;
  return (
    <NtScreen
      tone="contracts"
      device={mode === 'pad' ? 'Пункт подработки' : 'Доска контрактов'}
      status={my_name ? `Счёт: ${my_name}` : 'Банковский счёт не найден: контракт не взять.'}
      readout={
        mode === 'console' ? (
          <NtReadout label="Бюджет снабжения">
            <AnimatedNumber value={stored_cash ?? 0} format={(value) => formatCredits(value)} />
          </NtReadout>
        ) : undefined
      }>
      {mode === 'pad' && <PadSection />}
      <NtFrame
        title="Контракты NT"
        help={contracts_help_topics?.length ? <NtHelpTopics topics={contracts_help_topics} /> : undefined}
        buttons={mode === 'console' && <Button icon="print" content="Распечатать" onClick={() => act('Print')} />}>
        <ContractTable />
      </NtFrame>
    </NtScreen>
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

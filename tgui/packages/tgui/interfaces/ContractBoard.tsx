import { BooleanLike } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../backend';
import { AnimatedNumber, Box, Button, NoticeBox } from '../components';
import { Window } from '../layouts';
import { ContractTable } from './common/ContractTable';
import { formatCredits } from './common/Economy';
import { NtFrame, NtLine, NtMenu, NtMenuItem, NtReadout, NtScreen } from './common/NtTerminal';

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
    <NtFrame
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
      <NtLine label="Пад" tone={pad && pad_on_station ? 'good' : 'bad'}>
        {!pad ? 'Не найден' : pad_on_station ? 'На связи' : 'Вне станции'}
      </NtLine>
      <NtLine label="Отчёт">{status_report || '-'}</NtLine>
      <Box className="NtTerm__hint" mt={1}>
        Положите на пад то, что просят контракты поставки, и отправьте: подходящее уйдёт ЦК, остальное останется на
        месте.
      </Box>
    </NtFrame>
  );
};

type BoardPage = 'board' | 'help';

/** Доска контрактов NT: пункт подработки с падом и консоль контрактов снабжения. */
export const ContractBoardContent = (props) => {
  const { act, data } = useBackend<ContractBoardData>();
  const { mode, contracts_help, my_name, stored_cash } = data;
  const [page, setPage] = useState<BoardPage>('board');
  const pages: NtMenuItem<BoardPage>[] = [
    { key: 'board', label: 'Контракты' },
    ...(contracts_help ? [{ key: 'help' as BoardPage, label: 'Как работают контракты' }] : []),
  ];
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
      }
      menu={<NtMenu<BoardPage> items={pages} selected={page} onSelect={setPage} />}>
      {page === 'help' && !!contracts_help && <NoticeBox info>{contracts_help}</NoticeBox>}
      {page === 'board' && (
        <>
          {mode === 'pad' && <PadSection />}
          <NtFrame
            title="Контракты NT"
            buttons={mode === 'console' && <Button icon="print" content="Распечатать" onClick={() => act('Print')} />}>
            <ContractTable />
          </NtFrame>
        </>
      )}
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

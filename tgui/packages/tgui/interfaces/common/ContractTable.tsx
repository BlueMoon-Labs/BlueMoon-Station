import { useState } from 'react';

import { useBackend } from '../../backend';
import { Box, Button, NoticeBox } from '../../components';
import { ContractEntry, formatCredits } from './Economy';

type ContractBoardData = {
  contracts?: ContractEntry[];
  my_account?: number | null;
  performer_share?: number;
};

const formatTimeLeft = (seconds: number) => {
  const minutes = Math.floor(seconds / 60);
  const rest = String(seconds % 60).padStart(2, '0');
  return `${minutes}:${rest}`;
};

/** "12 из 30" и подобное: доля для полоски прогресса, если её можно прочитать. */
const progressShare = (progress?: string | null) => {
  const match = /(\d+(?:[.,]\d+)?)\D+(\d+(?:[.,]\d+)?)/.exec(progress || '');
  if (!match) {
    return null;
  }
  const done = Number(match[1].replace(',', '.'));
  const total = Number(match[2].replace(',', '.'));
  return total > 0 ? Math.min(done / total, 1) : null;
};

const ContractAction = (props: { contract: ContractEntry; myAccount?: number | null; readOnly?: boolean }) => {
  const { act } = useBackend();
  const { contract, myAccount, readOnly } = props;
  if (contract.taken_by) {
    return contract.taker_id === myAccount ? (
      <Box color="good">Ваш контракт</Box>
    ) : (
      <Box color="label">Взял: {contract.taken_by}</Box>
    );
  }
  if (!contract.takeable) {
    return <Box color="label">Выполняет отдел</Box>;
  }
  if (readOnly) {
    return <Box color="good">Свободен</Box>;
  }
  return (
    <Button
      color="good"
      disabled={!myAccount}
      tooltip={myAccount ? null : 'Нужен банковский счёт'}
      onClick={() => act('take', { uid: contract.uid })}>
      Взять
    </Button>
  );
};

type Filter = 'all' | 'free' | 'mine' | string;

const ContractRow = (props: { contract: ContractEntry; myAccount?: number | null; readOnly?: boolean }) => {
  const { contract, myAccount, readOnly } = props;
  const share = progressShare(contract.progress);
  const mine = !!contract.taken_by && contract.taker_id === myAccount;
  return (
    <div className={mine ? 'NtTerm__contract NtTerm__contract--mine' : 'NtTerm__contract'}>
      <div className="NtTerm__contractMain">
        <div className="NtTerm__contractTitle">
          <span className="NtTerm__tag NtTerm__tag--lead">{contract.department_name}</span>
          {contract.title}
          {contract.special ? ' (заказ ЦК)' : ''}
          {!!contract.urgent && <span className="NtTerm__contractUrgent">Срочный</span>}
        </div>
        <div className="NtTerm__hint">{contract.desc}</div>
        {!!contract.progress && (
          <div className="NtTerm__contractProgress">
            {share !== null && (
              <span className="NtTerm__bar">
                <span className="NtTerm__barFill" style={{ width: `${Math.round(share * 100)}%` }} />
              </span>
            )}
            <span>{contract.progress}</span>
          </div>
        )}
      </div>
      <div className="NtTerm__contractSide">
        <div className="NtTerm__contractReward">{formatCredits(contract.reward)}</div>
        {contract.time_left !== null && contract.time_left !== undefined && (
          <div className="NtTerm__hint">Осталось {formatTimeLeft(contract.time_left)}</div>
        )}
        {contract.rotates_in !== null && contract.rotates_in !== undefined && (
          <div className={contract.started ? 'color-average' : 'NtTerm__hint'}>
            {contract.started
              ? `Снимется через ${formatTimeLeft(contract.rotates_in)}, отгруженное не вернётся`
              : `Смена через ${formatTimeLeft(contract.rotates_in)}`}
          </div>
        )}
        <Box mt={0.5}>
          <ContractAction contract={contract} myAccount={myAccount} readOnly={readOnly} />
        </Box>
      </div>
    </div>
  );
};

/** Доска контрактов NT: кнопка "Взять" шлёт act('take', { uid }); readOnly - только просмотр. */
export const ContractTable = (props: { showShare?: boolean; readOnly?: boolean }) => {
  const { showShare = true, readOnly = false } = props;
  const { data } = useBackend<ContractBoardData>();
  const { contracts = [], my_account, performer_share } = data;
  const [filter, setFilter] = useState<Filter>('all');
  if (!contracts.length) {
    return <NoticeBox>Контрактов сейчас нет.</NoticeBox>;
  }
  const departments = contracts
    .map((contract) => contract.department_name)
    .filter((name, index, all) => all.indexOf(name) === index);
  const mineCount = contracts.filter((contract) => contract.taken_by && contract.taker_id === my_account).length;
  const filters: [Filter, string][] = [
    ['all', `Все (${contracts.length})`],
    ...(readOnly ? [] : ([['free', 'Свободные']] as [Filter, string][])),
    ...(mineCount ? ([['mine', `Мои (${mineCount})`]] as [Filter, string][]) : []),
    ...(departments.length > 1 ? departments.map((name) => [`dep:${name}`, name] as [Filter, string]) : []),
  ];
  const shown = contracts.filter((contract) => {
    if (filter === 'free') {
      return !contract.taken_by && !!contract.takeable;
    }
    if (filter === 'mine') {
      return !!contract.taken_by && contract.taker_id === my_account;
    }
    if (filter.startsWith('dep:')) {
      return contract.department_name === filter.slice(4);
    }
    return true;
  });
  return (
    <>
      {showShare && (
        <Box className="NtTerm__hint" mb={1}>
          Взявший контракт получает {performer_share}% награды, остальное - отделу.
        </Box>
      )}
      {filters.length > 1 && (
        <div className="NtTerm__chips">
          {filters.map(([key, label]) => (
            <span key={key} className={filter === key ? 'NtTerm__chip NtTerm__chip--active' : 'NtTerm__chip'} onClick={() => setFilter(key)}>
              {label}
            </span>
          ))}
        </div>
      )}
      {shown.length === 0 && <Box className="NtTerm__hint">Под этот фильтр контрактов нет.</Box>}
      {shown.map((contract) => (
        <ContractRow key={contract.uid} contract={contract} myAccount={my_account} readOnly={readOnly} />
      ))}
    </>
  );
};

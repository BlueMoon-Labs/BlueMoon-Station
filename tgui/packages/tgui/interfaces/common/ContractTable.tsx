import { useBackend } from '../../backend';
import { Box, Button, NoticeBox, Table } from '../../components';
import { ContractEntry, Credits } from './Economy';

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
      disabled={!myAccount}
      tooltip={myAccount ? null : 'Нужен банковский счёт'}
      onClick={() => act('take', { uid: contract.uid })}>
      Взять
    </Button>
  );
};

/** Доска контрактов NT: кнопка «Взять» шлёт act('take', { uid }); readOnly - только просмотр. */
export const ContractTable = (props: { showShare?: boolean; readOnly?: boolean }) => {
  const { showShare = true, readOnly = false } = props;
  const { data } = useBackend<ContractBoardData>();
  const { contracts = [], my_account, performer_share } = data;
  if (!contracts.length) {
    return <NoticeBox>Контрактов сейчас нет.</NoticeBox>;
  }
  return (
    <>
      {showShare && (
        <Box color="label" mb={1}>
          Взявший контракт получает {performer_share}% награды, остальное - отделу.
        </Box>
      )}
      <Table>
        <Table.Row header>
          <Table.Cell>Отдел</Table.Cell>
          <Table.Cell>Контракт</Table.Cell>
          <Table.Cell>Прогресс</Table.Cell>
          <Table.Cell>Награда</Table.Cell>
          <Table.Cell />
        </Table.Row>
        {contracts.map((contract) => (
          <Table.Row key={contract.uid} className="candystripe">
            <Table.Cell>{contract.department_name}</Table.Cell>
            <Table.Cell>
              <Box bold>
                {contract.title}
                {contract.special ? ' (заказ ЦК)' : ''}
              </Box>
              <Box italic color="label">
                {contract.desc}
              </Box>
            </Table.Cell>
            <Table.Cell>{contract.progress || '-'}</Table.Cell>
            <Table.Cell>
              <Box nowrap>
                <Credits amount={contract.reward} />
              </Box>
              {contract.urgent ? <Box color="average">Срочный</Box> : null}
              {contract.time_left !== null && contract.time_left !== undefined ? (
                <Box color="label">Осталось {formatTimeLeft(contract.time_left)}</Box>
              ) : null}
              {contract.rotates_in !== null && contract.rotates_in !== undefined ? (
                <Box color={contract.started ? 'average' : 'label'}>
                  {contract.started
                    ? `Снимется через ${formatTimeLeft(contract.rotates_in)}, отгруженное не вернётся`
                    : `Смена через ${formatTimeLeft(contract.rotates_in)}`}
                </Box>
              ) : null}
            </Table.Cell>
            <Table.Cell>
              <ContractAction contract={contract} myAccount={my_account} readOnly={readOnly} />
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
    </>
  );
};

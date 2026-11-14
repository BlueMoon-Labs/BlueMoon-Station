import { BooleanLike } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  Dropdown,
  Input,
  LabeledList,
  NoticeBox,
  RestrictedInput,
  Section,
  Stack,
  Table,
  Tabs,
} from '../components';
import { NtosWindow, Window } from '../layouts';
import {
  Credits,
  formatCredits,
  HistoryTable,
  RequestStatus,
  Sparkline,
  TransactionEntry,
  TreasuryRequestEntry,
} from './common/Economy';

type Grade = { id: string; name: string; wage: number };

type DepartmentRow = {
  id: string;
  name: string;
  balance: number;
  owed: number;
  owed_wages: number;
  staff_on_shift: number;
  threshold?: number;
  headroom?: number;
  return_due?: number;
};

type AccountStatus = 'active' | 'blocked' | 'frozen' | 'dormant';

type AccountRow = {
  number: number;
  holder: string;
  grade: string | null;
  department: string | null;
  balance: number;
  status: AccountStatus;
  crew: BooleanLike;
  anonymous: BooleanLike;
  flagged: BooleanLike;
};

type AccountDetails = {
  number: number;
  holder: string;
  balance: number;
  grade: string | null;
  department: string | null;
  wage: number;
  bonus: number;
  owed: number;
  floor_only?: BooleanLike;
  status: AccountStatus;
  frozen_by: string | null;
  freeze_reason: string | null;
  case: string | null;
  history: TransactionEntry[];
};

type StallRow = {
  name: string;
  area: string;
  renter: string | null;
  until: string | null;
  active: BooleanLike;
  goods: number;
};

type EconomyState = 'poor' | 'normal' | 'rich';

export type TreasuryData = {
  tax_max: number;
  grades: Grade[];
  holder_max: number;
  economy_minutes: number;
  wage_minutes: number;
  wage_floor: number;
  owed_cap: number;
  treasury_grant: number;
  tax_nt_share?: number;
  treasury_cap?: number;
  treasury_return_due?: number;
  cap_share?: number;
  grace_minutes?: number;
  treasury_max: number;
  treasury_pending_max: number;
  unowned_max: number;
  stall_fee: number;
  stall_minutes: number;
  rich_per_capita: number;
  poor_per_capita: number;
  audit_rights: string;
  message: string;
  can_manage: BooleanLike;
  treasury: number;
  tax_rate: number;
  ledger: { minted: number; burned: number; state: EconomyState; money_history: number[] };
  departments: DepartmentRow[];
  requests: (TreasuryRequestEntry & { department_name: string })[];
  my_account?: number | null;
  can_audit?: BooleanLike;
  accounts?: AccountRow[];
  account?: AccountDetails | null;
  stalls?: StallRow[];
};

type Tab = 'treasury' | 'requests' | 'accounts' | 'stalls' | 'ledger';

const REQUEST_STATUS: Record<RequestStatus, [string, string]> = {
  pending: ['ждёт решения', 'average'],
  approved: ['одобрен', 'good'],
  denied: ['отклонён', 'bad'],
};

const ACCOUNT_STATUS: Record<AccountStatus, [string, string | undefined]> = {
  active: ['активен', undefined],
  blocked: ['заблокирован казной', 'bad'],
  frozen: ['заморожен аудитом', 'bad'],
  dormant: ['владелец не на смене', 'label'],
};

const ECONOMY_STATE: Record<EconomyState, [string, string]> = {
  poor: ['Станция бедна', 'bad'],
  normal: ['Станция в норме', 'average'],
  rich: ['Станция богата', 'good'],
};

export const NtosTreasury = () => (
  <NtosWindow width={720} height={660}>
    <NtosWindow.Content scrollable>
      <NtosTreasuryContent />
    </NtosWindow.Content>
  </NtosWindow>
);

export const TreasuryConsole = () => (
  <Window width={720} height={660}>
    <Window.Content scrollable>
      <NtosTreasuryContent />
    </Window.Content>
  </Window>
);

export const NtosTreasuryContent = () => {
  const { data } = useBackend<TreasuryData>();
  const [tab, setTab] = useState<Tab>('treasury');
  const pending = data.requests.filter((request) => request.status === 'pending').length;
  const tabs: [Tab, string, string][] = [
    ['treasury', 'Казна', 'landmark'],
    ['requests', pending ? `Запросы (${pending})` : 'Запросы', 'hand-holding-usd'],
  ];
  if (data.can_manage) {
    tabs.push(['accounts', 'Счета экипажа', 'users'], ['stalls', 'Прилавки', 'store']);
  }
  tabs.push(['ledger', 'Журнал NT', 'book']);
  return (
    <>
      {!!data.message && <NoticeBox info>{data.message}</NoticeBox>}
      {!data.can_manage && (
        <NoticeBox>
          Управлять казной могут капитан (по ID-карте) и глава персонала (по должности и доступу ГП на ID-карте).
        </NoticeBox>
      )}
      <Tabs>
        {tabs.map(([id, label, icon]) => (
          <Tabs.Tab key={id} icon={icon} selected={tab === id} onClick={() => setTab(id)}>
            {label}
          </Tabs.Tab>
        ))}
      </Tabs>
      {tab === 'treasury' && <TreasuryTab />}
      {tab === 'requests' && <RequestsTab />}
      {tab === 'accounts' && !!data.can_manage && <AccountsTab />}
      {tab === 'stalls' && !!data.can_manage && <StallsTab />}
      {tab === 'ledger' && <LedgerTab />}
    </>
  );
};

const TreasuryTab = () => {
  const { act, data } = useBackend<TreasuryData>();
  const [rate, setRate] = useState(data.tax_rate);
  return (
    <>
      <Section title="Казна станции">
        <LabeledList>
          <LabeledList.Item label="Баланс">
            <Credits amount={data.treasury} />
          </LabeledList.Item>
          <LabeledList.Item label="Налог">
            {data.tax_rate}%
            {!!data.can_manage && (
              <>
                {' '}
                <RestrictedInput
                  width="4em"
                  value={rate}
                  minValue={0}
                  maxValue={data.tax_max}
                  onChange={(_, value) => setRate(value)}
                />
                % <Button onClick={() => act('set_tax', { rate })}>Установить</Button>
              </>
            )}
          </LabeledList.Item>
        </LabeledList>
        <Box color="label" mt={1}>
          Налог удерживается с зарплаты, премий, оплаты работы и наград контрактов, не выше {data.tax_max}%:{' '}
          {data.tax_nt_share ?? 0}% налога забирает NT, остальное получает казна. Минимум NT, переводы, чаевые, касса и
          выручка прилавков налогом не облагаются.
        </Box>
        <Box color="label" mt={1}>
          Казна получает налог, аренду прилавков и грант NT <Credits amount={data.treasury_grant} /> раз в{' '}
          {data.economy_minutes} мин. Из казны пополняются бюджеты отделов и открываются счета. Акциями из казны
          торгует только капитан в приложении биржи.
        </Box>
        <Box color="label" mt={1}>
          Сверх <Credits amount={data.treasury_cap ?? 0} /> казна раз в {data.economy_minutes} мин. возвращает NT{' '}
          {data.cap_share ?? 0}% излишка. Бюджеты отделов тоже, пороги - в таблице ниже. Перевод из казны в бюджет первые{' '}
          {data.grace_minutes ?? 0} мин. излишком не считается, перевод между отделами такой защиты не получает.
        </Box>
        {!!data.treasury_return_due && (
          <NoticeBox warning mt={1}>
            Казна выше порога: через несколько минут NT заберёт <Credits amount={data.treasury_return_due} />
          </NoticeBox>
        )}
      </Section>
      <DepartmentsSection />
      {!!data.can_manage && <MoveBudgetSection />}
    </>
  );
};

const FundCell = (props: { department: DepartmentRow }) => {
  const { act, data } = useBackend<TreasuryData>();
  const [amount, setAmount] = useState(0);
  return (
    <Table.Cell collapsing nowrap>
      <RestrictedInput
        width="5em"
        value={amount}
        minValue={0}
        maxValue={Math.max(data.treasury, 0)}
        onChange={(_, value) => setAmount(value)}
      />{' '}
      <Button
        icon="arrow-right"
        disabled={amount < 1}
        onClick={() => act('fund', { department: props.department.id, amount })}>
        Из казны
      </Button>
    </Table.Cell>
  );
};

const DepartmentsSection = () => {
  const { data } = useBackend<TreasuryData>();
  return (
    <Section title="Бюджеты отделов">
      <Box color="label" mb={1}>
        Отделы платят зарплату своим сотрудникам из бюджета раз в {data.wage_minutes} мин. Если денег не хватает, отдел
        остаётся должен (не больше {data.owed_cap} окладов на человека), а NT доплачивает каждому до минимума{' '}
        <Credits amount={data.wage_floor} />. Долг перед NT - штрафы отдела, они гасятся из бюджета.
      </Box>
      <Table>
        <Table.Row header>
          <Table.Cell>Отдел</Table.Cell>
          <Table.Cell>Баланс</Table.Cell>
          <Table.Cell>На смене</Table.Cell>
          <Table.Cell>Долг по зарплате</Table.Cell>
          <Table.Cell>Долг перед NT</Table.Cell>
          <Table.Cell>Порог</Table.Cell>
          <Table.Cell>До порога</Table.Cell>
          {!!data.can_manage && <Table.Cell>Пополнить</Table.Cell>}
        </Table.Row>
        {data.departments.map((department) => (
          <Table.Row key={department.id} className="candystripe">
            <Table.Cell>{department.name}</Table.Cell>
            <Table.Cell>
              <Credits amount={department.balance} />
            </Table.Cell>
            <Table.Cell>{department.staff_on_shift}</Table.Cell>
            <Table.Cell color={department.owed_wages > 0 ? 'average' : undefined}>
              <Credits amount={department.owed_wages} />
            </Table.Cell>
            <Table.Cell color={department.owed > 0 ? 'bad' : undefined}>
              <Credits amount={department.owed} />
            </Table.Cell>
            <Table.Cell>
              <Credits amount={department.threshold ?? 0} />
            </Table.Cell>
            <Table.Cell color={department.return_due ? 'average' : undefined}>
              {department.return_due ? (
                <>
                  излишек, NT заберёт <Credits amount={department.return_due} />
                </>
              ) : (
                <Credits amount={Math.max(department.headroom ?? 0, 0)} />
              )}
            </Table.Cell>
            {!!data.can_manage && <FundCell department={department} />}
          </Table.Row>
        ))}
      </Table>
    </Section>
  );
};

const departmentOptions = (departments: DepartmentRow[]) =>
  departments.map((department) => ({ value: department.id, displayText: department.name }));

const MoveBudgetSection = () => {
  const { act, data } = useBackend<TreasuryData>();
  const [from, setFrom] = useState(data.departments[0]?.id);
  const [to, setTo] = useState(data.departments[1]?.id);
  const [amount, setAmount] = useState(0);
  const options = departmentOptions(data.departments);
  return (
    <Section title="Перевод между отделами">
      <Stack align="center">
        <Stack.Item>
          <Dropdown width={12} selected={from} options={options} onSelected={setFrom} />
        </Stack.Item>
        <Stack.Item>в</Stack.Item>
        <Stack.Item>
          <Dropdown width={12} selected={to} options={options} onSelected={setTo} />
        </Stack.Item>
        <Stack.Item>
          <RestrictedInput width="6em" value={amount} minValue={0} onChange={(_, value) => setAmount(value)} /> кр.
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="exchange-alt"
            disabled={amount < 1 || from === to}
            onClick={() => act('move_budget', { from, to, amount })}>
            Перевести
          </Button>
        </Stack.Item>
      </Stack>
      <Box color="label" mt={1}>
        Переведённое между отделами от возврата NT не защищено: если бюджет получателя выше порога, излишек уйдёт на
        ближайшем тике.
      </Box>
    </Section>
  );
};

const RequestsTab = () => {
  const { act, data } = useBackend<TreasuryData>();
  const requests = [...data.requests].reverse();
  return (
    <Section title="Запросы глав отделов">
      <Box color="label" mb={1}>
        Глава отдела просит до <Credits amount={data.treasury_max} /> за раз, у отдела ждут решения не больше{' '}
        {data.treasury_pending_max} запросов. Одобренная сумма сразу уходит из казны в бюджет отдела; если в казне
        не хватает денег, запрос ждёт.
      </Box>
      {requests.length ? (
        <Table>
          <Table.Row header>
            <Table.Cell>№</Table.Cell>
            <Table.Cell>Отдел</Table.Cell>
            <Table.Cell>Сумма</Table.Cell>
            <Table.Cell>Кто и зачем</Table.Cell>
            <Table.Cell>Решение</Table.Cell>
          </Table.Row>
          {requests.map((request) => (
            <Table.Row key={request.uid} className="candystripe">
              <Table.Cell>{request.uid}</Table.Cell>
              <Table.Cell>{request.department_name}</Table.Cell>
              <Table.Cell>
                <Credits amount={request.amount} />
              </Table.Cell>
              <Table.Cell>
                {request.requester}
                <Box italic color="label">
                  {request.reason || 'без причины'}
                </Box>
              </Table.Cell>
              <Table.Cell collapsing>
                {request.status === 'pending' && !!data.can_manage ? (
                  <>
                    <Button color="good" onClick={() => act('resolve_request', { uid: request.uid, approve: true })}>
                      Одобрить
                    </Button>
                    <Button color="bad" onClick={() => act('resolve_request', { uid: request.uid, approve: false })}>
                      Отклонить
                    </Button>
                  </>
                ) : (
                  <Box color={REQUEST_STATUS[request.status][1]}>{REQUEST_STATUS[request.status][0]}</Box>
                )}
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      ) : (
        <Box color="label">Запросов нет.</Box>
      )}
    </Section>
  );
};

const AccountsTab = () => {
  const { data } = useBackend<TreasuryData>();
  return (
    <>
      <OpenAccountSection />
      {!!data.account && <AccountDetailsSection account={data.account} />}
      <AccountListSection />
    </>
  );
};

const OpenAccountSection = () => {
  const { act, data } = useBackend<TreasuryData>();
  const [holder, setHolder] = useState('');
  const [funds, setFunds] = useState(0);
  return (
    <Section title="Новый счёт">
      <Stack align="center">
        <Stack.Item grow>
          <Input
            fluid
            value={holder}
            maxLength={data.holder_max}
            placeholder="Имя владельца"
            onInput={(_, value) => setHolder(value)}
          />
        </Stack.Item>
        <Stack.Item>
          <RestrictedInput
            width="6em"
            value={funds}
            minValue={0}
            maxValue={Math.max(data.treasury, 0)}
            onChange={(_, value) => setFunds(value)}
          />{' '}
          кр.
        </Stack.Item>
        <Stack.Item>
          <Button icon="plus" disabled={!holder.trim()} onClick={() => act('open_account', { holder, funds })}>
            Открыть счёт
          </Button>
        </Stack.Item>
      </Stack>
      <Box color="label" mt={1}>
        Начальный взнос списывается из казны, номер счёта печатается на бумаге. Новый счёт привязывают к ID-карте без
        счёта: Alt+клик по карте и ввести номер. Счетов, не принадлежащих никому из экипажа, казна держит не больше{' '}
        {data.unowned_max}.
      </Box>
      <NoticeBox mt={1}>
        Крупные или частые выплаты из казны одному человеку открывают дело финансового аудита. Взносы на новые
        счета без владельца аудит считает вместе, как выплаты одному получателю. Аудит ведут:{' '}
        {data.audit_rights}.
      </NoticeBox>
    </Section>
  );
};

const AccountListSection = () => {
  const { act, data } = useBackend<TreasuryData>();
  const accounts = data.accounts || [];
  return (
    <Section
      title="Личные счета"
      buttons={
        <Button icon="print" onClick={() => act('print_summary')}>
          Сводный отчёт
        </Button>
      }>
      <Table>
        <Table.Row header>
          <Table.Cell>Владелец</Table.Cell>
          <Table.Cell>Номер</Table.Cell>
          <Table.Cell>Баланс</Table.Cell>
          <Table.Cell>Состояние</Table.Cell>
          <Table.Cell />
        </Table.Row>
        {accounts.map((account) => (
          <Table.Row key={account.number} className="candystripe">
            <Table.Cell>
              {account.holder}
              {account.number === data.my_account ? ' (вы)' : ''}
              {!!account.anonymous && (
                <>
                  {' '}
                  <Box inline color="label">
                    анонимный
                  </Box>
                </>
              )}
              {!account.crew && !account.anonymous && (
                <>
                  {' '}
                  <Box inline color="label">
                    не член экипажа
                  </Box>
                </>
              )}
              {!!account.flagged && (
                <>
                  {' '}
                  <Box inline color="bad">
                    дело аудита
                  </Box>
                </>
              )}
            </Table.Cell>
            <Table.Cell>{account.number}</Table.Cell>
            <Table.Cell>
              <Credits amount={account.balance} />
            </Table.Cell>
            <Table.Cell color={ACCOUNT_STATUS[account.status][1]}>{ACCOUNT_STATUS[account.status][0]}</Table.Cell>
            <Table.Cell collapsing>
              <Button
                selected={data.account?.number === account.number}
                onClick={() => act('select_account', { number: account.number })}>
                Открыть
              </Button>
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
    </Section>
  );
};

const AccountDetailsSection = (props: { account: AccountDetails }) => {
  const { act, data } = useBackend<TreasuryData>();
  const { account } = props;
  const row = (data.accounts || []).find((entry) => entry.number === account.number);
  const isSelf = account.number === data.my_account;
  const editable = !!row?.crew && !isSelf;
  const blocked = account.status === 'blocked';
  return (
    <Section
      title={`Счёт №${account.number}: ${account.holder}`}
      buttons={
        <>
          <Button icon="print" onClick={() => act('print_account', { number: account.number })}>
            Выписка
          </Button>
          <Button icon="times" onClick={() => act('select_account', { number: 0 })}>
            Закрыть
          </Button>
        </>
      }>
      <LabeledList>
        <LabeledList.Item label="Баланс">
          <Credits amount={account.balance} />
        </LabeledList.Item>
        <LabeledList.Item label="Состояние" color={ACCOUNT_STATUS[account.status][1]}>
          {ACCOUNT_STATUS[account.status][0]}
          {account.status === 'frozen' && !!account.frozen_by && ` (${account.frozen_by}): ${account.freeze_reason}`}
        </LabeledList.Item>
        {!!account.case && (
          <LabeledList.Item label="Аудит" color="bad">
            {account.case}
          </LabeledList.Item>
        )}
        <LabeledList.Item label="Оклад">
          {account.grade ? (
            <>
              <Credits amount={account.wage} /> ({account.grade}
              {account.bonus > 0 ? `, надбавка ${account.bonus}%` : ''})
            </>
          ) : (
            'не назначен'
          )}
          {account.owed > 0 && (
            <Box color="average">
              Отдел должен: <Credits amount={account.owed} />
            </Box>
          )}
        </LabeledList.Item>
        <LabeledList.Item label="Платит отдел">{account.department || 'нет'}</LabeledList.Item>
      </LabeledList>
      {!!account.floor_only && (
        <Box color="average" mt={1}>
          {account.grade ? 'Отдел не назначен' : 'Грейд не назначен'}: оклад не платится, NT платит только минимум{' '}
          <Credits amount={data.wage_floor} />.
        </Box>
      )}
      {editable ? (
        <Stack mt={1} align="center">
          <Stack.Item>Грейд:</Stack.Item>
          <Stack.Item>
            <Dropdown
              width={12}
              selected={row?.grade || ''}
              options={data.grades.map((grade) => ({ value: grade.id, displayText: grade.name }))}
              onSelected={(grade) => act('set_grade', { number: account.number, grade })}
            />
          </Stack.Item>
          <Stack.Item>Отдел:</Stack.Item>
          <Stack.Item>
            <Dropdown
              width={12}
              selected={row?.department || ''}
              options={departmentOptions(data.departments)}
              onSelected={(department) => act('set_department', { number: account.number, department })}
            />
          </Stack.Item>
        </Stack>
      ) : (
        <Box color="label" mt={1}>
          {isSelf
            ? 'Свой оклад, отдел и блокировку менять нельзя.'
            : 'Оклад назначается только счетам членов экипажа.'}
        </Box>
      )}
      <Box color="label" mt={1}>
        Грейды: {data.grades.map((grade) => `${grade.name} ${formatCredits(grade.wage)}`).join(', ')}. Оклад платит бюджет отдела
        счёта; при смене отдела долг прежнего отдела и надбавка главы сбрасываются. Владелец получает сообщение на
        карту.
      </Box>
      {!isSelf && (
        <Box mt={1}>
          <Button
            icon={blocked ? 'unlock' : 'lock'}
            color={blocked ? undefined : 'bad'}
            onClick={() => act('toggle_block', { number: account.number })}>
            {blocked ? 'Разблокировать' : 'Заблокировать'}
          </Button>
          <Box inline color="label" ml={1}>
            Блокировка закрывает платежи со счёта и на счёт. Заморозку по делу ставит и снимает аудит, не казна.
          </Box>
        </Box>
      )}
      <Box bold mt={1} mb={0.5}>
        Последние операции
      </Box>
      <HistoryTable entries={account.history} />
    </Section>
  );
};

const StallsTab = () => {
  const { data } = useBackend<TreasuryData>();
  const stalls = data.stalls || [];
  return (
    <Section title="Прилавки станции">
      <Box color="label" mb={1}>
        Станционные прилавки продают только в аренду: <Credits amount={data.stall_fee} /> на {data.stall_minutes} мин.,
        плата идёт в казну, выручка - арендатору без налога. Арендуют сами, двумя свайпами ID-карты у прилавка. Если
        аренда кончилась, а товары остались, ГП или капитан освобождают прилавок двумя свайпами своей карты - товары
        выпадут наружу.
      </Box>
      {stalls.length ? (
        <Table>
          <Table.Row header>
            <Table.Cell>Прилавок</Table.Cell>
            <Table.Cell>Где</Table.Cell>
            <Table.Cell>Арендатор</Table.Cell>
            <Table.Cell>Товаров</Table.Cell>
          </Table.Row>
          {stalls.map((stall, index) => (
            <Table.Row key={index} className="candystripe">
              <Table.Cell>{stall.name}</Table.Cell>
              <Table.Cell>{stall.area}</Table.Cell>
              <Table.Cell>
                {stall.renter ? (
                  <Box color={stall.active ? undefined : 'average'}>
                    {stall.renter}, {stall.active ? `до ${stall.until}` : `аренда кончилась в ${stall.until}`}
                  </Box>
                ) : (
                  <Box color="good">свободен</Box>
                )}
              </Table.Cell>
              <Table.Cell>{stall.goods}</Table.Cell>
            </Table.Row>
          ))}
        </Table>
      ) : (
        <Box color="label">На станции нет прилавков в аренду.</Box>
      )}
    </Section>
  );
};

const LedgerTab = () => {
  const { data } = useBackend<TreasuryData>();
  const { ledger } = data;
  const [stateText, stateColor] = ECONOMY_STATE[ledger.state];
  return (
    <Section title="Журнал NT">
      <LabeledList>
        <LabeledList.Item label="Состояние" color={stateColor}>
          {stateText}
        </LabeledList.Item>
        <LabeledList.Item label="Эмиссия">
          <Credits amount={ledger.minted} />
        </LabeledList.Item>
        <LabeledList.Item label="Стоки">
          <Credits amount={ledger.burned} />
        </LabeledList.Item>
        <LabeledList.Item label="Итог смены">
          <Credits amount={ledger.minted - ledger.burned} signed />
        </LabeledList.Item>
        {ledger.money_history.length > 1 && (
          <LabeledList.Item label="Деньги на счетах">
            <Sparkline values={ledger.money_history} width="12em" />
          </LabeledList.Item>
        )}
      </LabeledList>
      <Box color="label" mt={1}>
        Эмиссия - деньги, которые NT начислила станции за смену: гранты, минимум зарплаты, оплата работы, награды
        контрактов, экспорт. Стоки - деньги, ушедшие из экономики станции к NT и партнёрам: закупки, штрафы и прочие
        траты. Налог, переводы и аренда только перекладывают деньги внутри станции.
      </Box>
      <Box color="label" mt={1}>
        Состояние пересчитывается раз в {data.economy_minutes} мин. по всем деньгам станции - на любых личных счетах,
        включая спящие и анонимные, в бюджетах, акциях и снятых наличных - на одного человека экипажа на смене: от{' '}
        <Credits amount={data.rich_per_capita} /> - богата, до <Credits amount={data.poor_per_capita} /> - бедна. Богатую
        станцию чаще навещают пираты, обвал рынка и эмбарго партнёров. Бедной NT присылает помощь и гранты, у неё
        чаще бум спроса и реже обвал рынка.
      </Box>
    </Section>
  );
};

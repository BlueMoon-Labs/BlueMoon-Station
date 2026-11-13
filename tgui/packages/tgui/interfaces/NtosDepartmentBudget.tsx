import { BooleanLike } from 'common/react';
import { useEffect, useState } from 'react';

import { useBackend } from '../backend';
import { AnimatedNumber, Box, Button, Input, LabeledList, NoticeBox, RestrictedInput, Stack, Table } from '../components';
import { NtosWindow, Window } from '../layouts';
import { ContractTable } from './common/ContractTable';
import { ContractEntry, Credits, formatCredits, RequestEntry, RequestStatus, TreasuryRequestEntry } from './common/Economy';
import { DEPARTMENT_TONES, NtFrame, NtHelpTopic, NtHelpTopics, NtLine, NtMenu, NtMenuItem, NtReadout, NtScreen } from './common/NtTerminal';

type DepartmentInfo = {
  id: string;
  name: string;
  balance: number;
  owed: number;
  staff_on_shift: number;
  grant: number;
  grant_has_base?: BooleanLike;
  threshold?: number;
  threshold_floor?: number;
  return_due?: number;
  shielded?: number;
  goal_cooldown?: number;
  express_ready_in?: number;
  goal?: { id: string; name: string; amount: number; minutes_left: number } | null;
};

type StaffEntry = {
  number: number;
  holder: string;
  wage: number;
  bonus: number;
  bonus_left: number;
  owed: number;
  frozen: BooleanLike;
  away: BooleanLike;
};

type CatalogEntry = {
  type: string;
  name: string;
  desc: string;
};

type PriceEntry = {
  price: number;
  available: BooleanLike;
};

type WorkLogEntry = {
  time: string;
  type: string;
  amount: number;
  performer: string;
};

type WorkPrice = {
  name: string;
  price: number;
  unit: string;
};

export type BudgetData = {
  departments: { id: string; name: string }[];
  catalog: CatalogEntry[];
  work_prices: WorkPrice[];
  reason_max: number;
  grant_base: number;
  grant_payroll_share: number;
  cap_paydays?: number;
  cap_share?: number;
  grace_minutes?: number;
  goal_minutes?: number;
  goal_cooldown_minutes?: number;
  express_markup?: number;
  express_cooldown?: number;
  economy_minutes: number;
  wage_minutes: number;
  owed_cap: number;
  wage_floor: number;
  dormant_minutes: number;
  max_wage_bonus: number;
  bonus_cap_hour: number;
  bonus_self_cap_hour: number;
  treasury_max: number;
  treasury_pending_max: number;
  auto_approve_limit: number;
  auto_approve_cooldown: number;
  auto_approve_wait: number;
  pending_per_requester: number;
  handling_fee: number;
  work_share: number;
  work_cap: number;
  performer_share: number;
  contracts_help_topics?: NtHelpTopic[];
  audit_rights: string;
  grant_price: number;
  grant_cap: number;
  message: string;
  can_switch: BooleanLike;
  has_department: BooleanLike;
  my_account: number | null;
  manifest_department: string | null;
  can_manage?: BooleanLike;
  is_staff?: BooleanLike;
  department?: DepartmentInfo;
  prices?: Record<string, PriceEntry>;
  requests?: RequestEntry[];
  treasury_requests?: TreasuryRequestEntry[];
  contracts?: ContractEntry[];
  work_log?: WorkLogEntry[];
  register_share?: number;
  staff?: StaffEntry[];
  owed_wages?: number;
  is_science?: BooleanLike;
  grant_left?: number;
  grant_resets_in?: number;
};

type Tab = 'overview' | 'catalog' | 'requests' | 'contracts' | 'work' | 'register' | 'grant';

const STATUS_NAMES: Record<RequestStatus, string> = {
  pending: 'ждёт решения',
  approved: 'одобрена',
  denied: 'отклонена',
};

const STATUS_COLORS: Record<RequestStatus, string> = {
  pending: 'average',
  approved: 'good',
  denied: 'bad',
};

export const NtosDepartmentBudget = () => (
  <NtosWindow width={680} height={640}>
    <NtosWindow.Content scrollable>
      <NtosDepartmentBudgetContent />
    </NtosWindow.Content>
  </NtosWindow>
);

export const DepartmentConsole = () => (
  <Window width={680} height={640}>
    <Window.Content scrollable>
      <NtosDepartmentBudgetContent />
    </Window.Content>
  </Window>
);

export const NtosDepartmentBudgetContent = () => {
  const { data } = useBackend<BudgetData>();
  const [tab, setTab] = useState<Tab>('overview');
  const department = data.department;
  const requests = (data.requests || []).filter((request) => request.status === 'pending').length;
  const tabs: NtMenuItem<Tab>[] = [
    { key: 'overview', label: 'Обзор' },
    { key: 'catalog', label: 'Каталог' },
    { key: 'requests', label: 'Заявки', count: requests },
    { key: 'contracts', label: 'Контракты' },
    { key: 'work', label: 'Работа' },
    { key: 'register', label: 'Касса' },
  ];
  if (data.is_science) {
    tabs.push({ key: 'grant', label: 'Грант' });
  }
  const hasDepartment = !!data.has_department && !!department;
  return (
    <NtScreen
      tone={(department && DEPARTMENT_TONES[department.id]) || 'civil'}
      device="Бюджет отдела"
      status={hasDepartment ? `${department.name}, на смене ${department.staff_on_shift} чел.` : 'Отдел не выбран'}
      readout={
        hasDepartment ? (
          <>
            <NtReadout label="Грант NT">{formatCredits(department.grant)}</NtReadout>
            <NtReadout label="Баланс" tone={department.balance < 0 ? 'bad' : undefined}>
              <AnimatedNumber value={department.balance} format={(value) => formatCredits(value)} />
            </NtReadout>
          </>
        ) : undefined
      }
      menu={hasDepartment ? <NtMenu<Tab> items={tabs} selected={tab} onSelect={setTab} /> : undefined}>
      <DepartmentSwitch />
      {!!data.message && <NoticeBox info>{data.message}</NoticeBox>}
      {hasDepartment ? (
        <>
          {tab === 'overview' && <OverviewTab />}
          {tab === 'catalog' && <CatalogTab />}
          {tab === 'requests' && <RequestsTab />}
          {tab === 'contracts' && <ContractsTab />}
          {tab === 'work' && <WorkTab />}
          {tab === 'register' && <RegisterTab />}
          {tab === 'grant' && !!data.is_science && <GrantTab />}
        </>
      ) : (
        <NoticeBox>
          {data.can_switch
            ? 'Выберите отдел выше. Казна станции - в окне казны.'
            : 'Отдел не определён: окно показывает отдел по вашему счёту сотрудника. Казна станции - в окне казны.'}
        </NoticeBox>
      )}
    </NtScreen>
  );
};

const DepartmentSwitch = () => {
  const { act, data } = useBackend<BudgetData>();
  if (!data.can_switch) {
    return null;
  }
  return (
    <Box mb={1.5}>
      <div className="NtTerm__chips">
        {data.departments.map((department) => (
          <span
            key={department.id}
            className={data.department?.id === department.id ? 'NtTerm__chip NtTerm__chip--active' : 'NtTerm__chip'}
            onClick={() => act('select_department', { id: department.id })}>
            {department.name}
          </span>
        ))}
      </div>
      <Box className="NtTerm__hint">ГП и капитан открывают бюджет любого отдела и управляют им, как глава.</Box>
    </Box>
  );
};

/** Шкала бюджета до порога: заполнение - баланс, за порогом шкала жёлтая - излишек заберёт NT. */
const BudgetGauge = (props: { balance: number; threshold: number }) => {
  const { balance, threshold } = props;
  const share = threshold > 0 ? Math.max(0, Math.min(balance / threshold, 1)) : 0;
  const over = threshold > 0 && balance > threshold;
  return (
    <Box mb={1.5}>
      <div className="NtTerm__alloc" style={{ height: '12px' }}>
        <div
          className="NtTerm__allocPart"
          style={{ width: `${share * 100}%`, backgroundColor: over ? '#d2b46a' : 'var(--nt-accent)' }}
        />
      </div>
      <Stack>
        <Stack.Item grow className="NtTerm__hint">
          Баланс <span className="NtTerm__num">{formatCredits(balance)}</span>
        </Stack.Item>
        <Stack.Item className={over ? 'color-average' : 'NtTerm__hint'}>
          порог <span className="NtTerm__num">{formatCredits(threshold)}</span>
        </Stack.Item>
      </Stack>
    </Box>
  );
};

const OverviewTab = () => {
  const { data } = useBackend<BudgetData>();
  const department = data.department as DepartmentInfo;
  return (
    <>
      <NtFrame title={`Бюджет: ${department.name}`} help={<BudgetHelp />}>
        <BudgetGauge balance={department.balance} threshold={department.threshold ?? 0} />
        {!!department.return_due && (
          <NoticeBox warning>
            Бюджет выше порога: через несколько минут NT заберёт <Credits amount={department.return_due} /> Потратьте
            излишек на закупки или назначьте цель накопления в каталоге.
          </NoticeBox>
        )}
        <NtLine label="На смене">{department.staff_on_shift} чел.</NtLine>
        <NtLine label="Грант NT">
          {formatCredits(department.grant)} / {data.economy_minutes} мин.
        </NtLine>
        <NtLine label="Долг по зарплате" tone={data.owed_wages ? 'warn' : 'dim'}>
          {formatCredits(data.owed_wages ?? 0)}
        </NtLine>
        {department.owed > 0 && (
          <NtLine label="Долг перед NT (штрафы)" tone="bad">
            {formatCredits(department.owed)}
          </NtLine>
        )}
        {!!department.goal && (
          <NtLine label="Цель накопления">
            {department.goal.name}, {formatCredits(department.goal.amount)}, ещё {department.goal.minutes_left} мин.
          </NtLine>
        )}
        {(!!department.shielded || !!department.goal || !!department.goal_cooldown) && (
          <Box className="NtTerm__hint" mt={0.5}>
            {!!department.shielded && <Box>{formatCredits(department.shielded)} недавних поступлений пока не считаются излишком.</Box>}
            {!!department.goal && <Box>Цель уже выбрана: чтобы выбрать другую, снимите эту в каталоге.</Box>}
            {!!department.goal_cooldown && <Box>Новую цель можно поставить через {department.goal_cooldown} мин.</Box>}
          </Box>
        )}
        {!!data.manifest_department && <ManifestButton />}
      </NtFrame>
      {!!data.can_manage && <StaffSection />}
      {!!data.can_manage && <TreasurySection />}
      {!data.can_manage && (data.treasury_requests || []).length > 0 && <TreasurySection />}
    </>
  );
};

/** Как считаются грант, порог и зарплаты: под кнопкой ? у бюджета. */
const BudgetHelp = () => {
  const { data } = useBackend<BudgetData>();
  const department = data.department as DepartmentInfo;
  return (
    <>
      <Box>
          Грант NT: <Credits amount={department.grant} /> раз в {data.economy_minutes} мин.: {data.grant_payroll_share}%
          окладов сотрудников на смене
          {department.grant_has_base ? (
            <>
              {' '}и <Credits amount={data.grant_base} /> на закупки из каталога.
            </>
          ) : (
            '.'
          )}
      </Box>
        <Box>
          Порог бюджета <Credits amount={department.threshold ?? 0} />: {data.cap_paydays} окладов сотрудников на смене, не
          ниже <Credits amount={department.threshold_floor ?? 0} />. Раз в {data.economy_minutes} мин. {data.cap_share}% излишка сверх порога возвращается NT.
          Излишком не считаются долги и следующая зарплата сотрудникам, переводы из казны, события и доля контрактов первые{' '}
          {data.grace_minutes} мин., а также цена пака - цели накопления ({data.goal_minutes} мин., ставится в каталоге;
          после её истечения или снятия новая - через {data.goal_cooldown_minutes} мин.).
        </Box>
        <Box>
          Зарплаты сотрудникам платятся из этого бюджета раз в {data.wage_minutes} мин. Если денег не хватает, отдел платит
          сколько может, а остаток становится долгом перед сотрудником (не больше {data.owed_cap} базовых окладов); долг
          гасится частями с каждой следующей зарплатой. Если сотрудник получил меньше <Credits amount={data.wage_floor} />,
          NT доплачивает до этого минимума. Кто дольше {data.dormant_minutes} мин. мёртв или не на смене, зарплату не
          получает, и долг ему не копится. Штрафы - долг перед NT, гасятся из бюджета раз в {data.economy_minutes} мин.
        </Box>
    </>
  );
};

const ManifestButton = () => {
  const { act, data } = useBackend<BudgetData>();
  return (
    <Box mt={1}>
      <Button
        icon="print"
        tooltip={`Положите накладную в ящик перед отгрузкой шаттлом снабжения: выручка за ящик уйдёт вашему отделу за вычетом сбора снабжения ${data.handling_fee}%.`}
        onClick={() => act('print_manifest')}>
        Накладная: {data.manifest_department}
      </Button>
    </Box>
  );
};

const departmentBalance = (data: BudgetData) => Math.max(data.department?.balance || 0, 0);

const StaffRow = (props: { member: StaffEntry }) => {
  const { act, data } = useBackend<BudgetData>();
  const { member } = props;
  const [amount, setAmount] = useState(0);
  const [percent, setPercent] = useState(member.bonus);
  useEffect(() => setPercent(member.bonus), [member.bonus]);
  const isSelf = member.number === data.my_account;
  return (
    <Table.Row className="candystripe">
      <Table.Cell>
        {member.holder}
        {isSelf ? ' (вы)' : ''}
        {member.frozen ? <Box color="bad">Счёт заморожен аудитом</Box> : null}
        {member.away ? <Box color="label">Не на смене</Box> : null}
      </Table.Cell>
      <Table.Cell>
        <Credits amount={member.wage} />
      </Table.Cell>
      <Table.Cell>
        <Credits amount={member.owed} />
      </Table.Cell>
      <Table.Cell>
        <RestrictedInput
          width="4em"
          value={percent}
          minValue={0}
          maxValue={data.max_wage_bonus}
          onChange={(_, value) => setPercent(value)}
        />
        %{' '}
        <Button
          disabled={isSelf}
          tooltip={isSelf ? 'Свою надбавку менять нельзя' : undefined}
          onClick={() => act('wage_bonus', { number: member.number, percent })}>
          Надбавка
        </Button>
      </Table.Cell>
      <Table.Cell>
        <RestrictedInput
          width="5em"
          value={amount}
          minValue={0}
          maxValue={Math.min(departmentBalance(data), member.bonus_left)}
          onChange={(_, value) => setAmount(value)}
        />{' '}
        <Button
          disabled={amount < 1 || amount > member.bonus_left || !!member.frozen}
          color={isSelf ? 'average' : undefined}
          tooltip={
            isSelf
              ? `Премия себе открывает дело финансового аудита. В этом часе можно ещё ${member.bonus_left} кр.`
              : `В этом часе можно ещё ${member.bonus_left} кр.`
          }
          onClick={() => act('bonus', { number: member.number, amount })}>
          Премия
        </Button>
      </Table.Cell>
    </Table.Row>
  );
};

const StaffSection = () => {
  const { data } = useBackend<BudgetData>();
  const staff = data.staff || [];
  return (
    <NtFrame
      title="Сотрудники"
      help={
        <NtHelpTopics
          topics={[
            {
              lines: [
                'Премия - разовая выплата из бюджета, облагается налогом. На замороженный аудитом счёт премии не идут.',
                `Надбавка - процент к окладу с каждой зарплаты, до ${data.max_wage_bonus}%. При переходе в другой отдел сбрасывается, свою надбавку менять нельзя.`,
                `От глав один человек получает не больше ${data.bonus_cap_hour} кр. премий в час. Себе глава выписывает отдельно, не больше ${data.bonus_self_cap_hour} кр. в час.`,
              ],
            },
          ]}
        />
      }>
      <Box className="NtTerm__hint" mb={1}>
        Премия себе и крупные или частые выплаты одному человеку открывают дело финансового аудита. Аудит ведут:{' '}
        {data.audit_rights}.
      </Box>
      {staff.length ? (
        <Table>
          <Table.Row header>
            <Table.Cell>Сотрудник</Table.Cell>
            <Table.Cell>Оклад</Table.Cell>
            <Table.Cell>Долг отдела</Table.Cell>
            <Table.Cell>Надбавка</Table.Cell>
            <Table.Cell>Премия</Table.Cell>
          </Table.Row>
          {staff.map((member) => (
            <StaffRow key={member.number} member={member} />
          ))}
        </Table>
      ) : (
        <Box color="label">В отделе нет сотрудников со счетами.</Box>
      )}
    </NtFrame>
  );
};

const TreasurySection = () => {
  const { act, data } = useBackend<BudgetData>();
  const [amount, setAmount] = useState(0);
  const [reason, setReason] = useState('');
  const requests = data.treasury_requests || [];
  return (
    <NtFrame
      title="Запрос в казну"
      help={`Деньги из казны станции переводят капитан или ГП в окне казны. До ${formatCredits(data.treasury_max)} за запрос, решения ждут не больше ${data.treasury_pending_max} запросов отдела.`}>
      {!!data.can_manage && (
        <Stack mb={1}>
          <Stack.Item>
            <RestrictedInput
              width="6em"
              value={amount}
              minValue={0}
              maxValue={data.treasury_max}
              onChange={(_, value) => setAmount(value)}
            />{' '}
            кр.
          </Stack.Item>
          <Stack.Item grow>
            <Input
              fluid
              value={reason}
              maxLength={data.reason_max}
              placeholder="На что нужны деньги"
              onInput={(_, value) => setReason(value)}
            />
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="hand-holding-usd"
              disabled={amount < 1}
              onClick={() => act('treasury_request', { amount, reason })}>
              Запросить
            </Button>
          </Stack.Item>
        </Stack>
      )}
      {requests.map((request) => (
        <Box key={request.uid}>
          №{request.uid}: <Credits amount={request.amount} /> - {request.reason || 'без причины'} (
          <Box inline color={STATUS_COLORS[request.status]}>
            {STATUS_NAMES[request.status]}
          </Box>
          )
        </Box>
      ))}
    </NtFrame>
  );
};

const CatalogTab = () => {
  const { act, data } = useBackend<BudgetData>();
  const [reason, setReason] = useState('');
  const prices = data.prices || {};
  const canOrder = !!data.can_manage;
  const canRequest = canOrder || !!data.is_staff;
  const expressWait = data.department?.express_ready_in || 0;
  return (
    <NtFrame
      title="Каталог отдела"
      help={
        <NtHelpTopics
          topics={[
            {
              lines: [
                ...(canOrder
                  ? [
                      'Заказ сразу списывает цену из бюджета и уходит в очередь снабжения уже оплаченным.',
                      `"Капсулой" - сразу, мимо шаттла: дороже на ${data.express_markup}%, садится рядом с вами в том же помещении, не чаще раза в ${data.express_cooldown} мин. на отдел.`,
                      '"Копить" ставит цель накопления: цена пака не считается излишком бюджета.',
                    ]
                  : [
                      'Заявку одобряет глава отдела, ГП или капитан - тогда цена спишется из бюджета.',
                      'Пак каталога можно подать и с консоли заявок снабжения: такую заявку тоже оплатит бюджет отдела. Если одобрить некому, пак дороже лимита с консоли уходит заявкой снабжению.',
                      `Если на смене некому одобрить, заявка до ${data.auto_approve_limit} кр. одобряется сама, не чаще раза в ${data.auto_approve_cooldown} мин. на сотрудника.`,
                      ...(data.auto_approve_wait > 0
                        ? [`Если ответа нет ${data.auto_approve_wait} мин., такая заявка одобряется сама и при начальстве на смене.`]
                        : []),
                      `Решения могут ждать до ${data.pending_per_requester} ваших заявок.`,
                    ]),
                'Цены зависят от рынка и партнёров снабжения и меняются по ходу смены.',
              ],
            },
          ]}
        />
      }>
      {!canRequest && <NoticeBox>Заявки подают только сотрудники отдела.</NoticeBox>}
      {canRequest && !canOrder && (
        <Input
          fluid
          mb={1}
          value={reason}
          maxLength={data.reason_max}
          placeholder="Причина заявки"
          onInput={(_, value) => setReason(value)}
        />
      )}
      {data.catalog.length ? (
        <Table>
          {data.catalog.map((pack) => {
            const price = prices[pack.type];
            const available = !!price?.available;
            return (
              <Table.Row key={pack.type} className="candystripe">
                <Table.Cell>
                  <Box bold>{pack.name}</Box>
                  <Box italic color="label">
                    {pack.desc}
                  </Box>
                </Table.Cell>
                <Table.Cell collapsing>
                  {available ? <Credits amount={price.price} /> : <Box color="bad">нет в наличии</Box>}
                </Table.Cell>
                <Table.Cell collapsing>
                  {canOrder && (
                    <Button disabled={!available} onClick={() => act('order', { pack: pack.type })}>
                      Заказать
                    </Button>
                  )}
                  {canOrder && (
                    <Button
                      disabled={!available || expressWait > 0}
                      tooltip={
                        expressWait > 0
                          ? `Следующая капсула через ${Math.ceil(expressWait / 60)} мин.`
                          : `Капсула сядет рядом с вами за ${Math.round(((price?.price || 0) * (100 + (data.express_markup || 0))) / 100)} кр.`
                      }
                      onClick={() => act('express', { pack: pack.type })}>
                      Капсулой
                    </Button>
                  )}
                  {canOrder &&
                    (data.department?.goal?.id === pack.type ? (
                      <Button selected onClick={() => act('clear_goal')}>
                        Цель
                      </Button>
                    ) : (
                      <Button
                        disabled={!available || !!data.department?.goal_cooldown || !!data.department?.goal}
                        tooltip={
                          data.department?.goal
                            ? 'Цель уже выбрана: снимите её, чтобы выбрать другую'
                            : 'Цена этого пака не будет считаться излишком бюджета'
                        }
                        onClick={() => act('set_goal', { pack: pack.type })}>
                        Копить
                      </Button>
                    ))}
                  {canRequest && !canOrder && (
                    <Button disabled={!available} onClick={() => act('request', { pack: pack.type, reason })}>
                      Заявка
                    </Button>
                  )}
                </Table.Cell>
              </Table.Row>
            );
          })}
        </Table>
      ) : (
        <Box color="label">У отдела нет своего каталога.</Box>
      )}
    </NtFrame>
  );
};

const RequestsTab = () => {
  const { act, data } = useBackend<BudgetData>();
  const requests = [...(data.requests || [])].reverse();
  return (
    <NtFrame title="Заявки" help="Заявки сотрудников приходят отсюда, с консоли заявок снабжения и из приложения «Заказы снабжения». О новой ждущей заявке, откуда бы её ни подали, слышат канал отдела и карты начальства на смене.">
      {requests.length ? (
        <Table>
          <Table.Row header>
            <Table.Cell>№</Table.Cell>
            <Table.Cell>Пак</Table.Cell>
            <Table.Cell>Цена</Table.Cell>
            <Table.Cell>Кто и зачем</Table.Cell>
            <Table.Cell>Статус</Table.Cell>
          </Table.Row>
          {requests.map((request) => (
            <Table.Row key={request.uid} className="candystripe">
              <Table.Cell>{request.uid}</Table.Cell>
              <Table.Cell>{request.pack}</Table.Cell>
              <Table.Cell>
                <Credits amount={request.price} />
              </Table.Cell>
              <Table.Cell>
                {request.requester}
                <Box italic color="label">
                  {request.reason || 'без причины'}
                </Box>
              </Table.Cell>
              <Table.Cell>
                {request.status === 'pending' && !!data.can_manage ? (
                  <>
                    <Button color="good" onClick={() => act('approve', { uid: request.uid })}>
                      Одобрить
                    </Button>
                    <Button color="bad" onClick={() => act('deny', { uid: request.uid })}>
                      Отклонить
                    </Button>
                  </>
                ) : (
                  <Box color={STATUS_COLORS[request.status]}>{STATUS_NAMES[request.status]}</Box>
                )}
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      ) : (
        <Box color="label">Заявок нет.</Box>
      )}
    </NtFrame>
  );
};

const ContractsTab = () => {
  const { data } = useBackend<BudgetData>();
  return (
    <NtFrame
      title="Контракты отдела"
      help={data.contracts_help_topics?.length ? <NtHelpTopics topics={data.contracts_help_topics} /> : undefined}>
      <ContractTable showShare={false} />
    </NtFrame>
  );
};

const WorkTab = () => {
  const { data } = useBackend<BudgetData>();
  const log = [...(data.work_log || [])].reverse();
  return (
    <>
      <NtFrame
        title="Оплата работы"
        help={`NT платит отделу за сделанную работу, а исполнитель получает ещё ${data.work_share}% сверху личной премией (до ${formatCredits(data.work_cap)} в час).`}>
        {data.work_prices.length ? (
          <Table>
            {data.work_prices.map((work) => (
              <Table.Row key={work.name}>
                <Table.Cell>{work.name}</Table.Cell>
                <Table.Cell collapsing>
                  <Credits amount={work.price} />
                </Table.Cell>
                <Table.Cell color="label">{work.unit}</Table.Cell>
              </Table.Row>
            ))}
          </Table>
        ) : (
          <Box color="label">Отделу не платят за отдельные виды работы - только грант и контракты.</Box>
        )}
      </NtFrame>
      <NtFrame title="Журнал работы">
        {log.length ? (
          <Table>
            {log.map((entry, index) => (
              <Table.Row key={index} className="candystripe">
                <Table.Cell collapsing color="label">
                  {entry.time}
                </Table.Cell>
                <Table.Cell>{entry.type}</Table.Cell>
                <Table.Cell>{entry.performer || '-'}</Table.Cell>
                <Table.Cell collapsing>
                  <Credits amount={entry.amount} signed />
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        ) : (
          <Box color="label">Оплаченной работы пока нет.</Box>
        )}
      </NtFrame>
    </>
  );
};

const RegisterTab = () => {
  const { act, data } = useBackend<BudgetData>();
  const [share, setShare] = useState(data.register_share || 0);
  useEffect(() => setShare(data.register_share || 0), [data.register_share]);
  return (
    <NtFrame
      title="Кассы отдела"
      help="Оплата на кассе, за которой стоит сотрудник отдела, делится: доля кассира идёт ему лично, остальное - в бюджет отдела. Налога с продаж нет, чаевые целиком достаются кассиру.">
      <LabeledList>
        <LabeledList.Item label="Доля кассира">{data.register_share}%</LabeledList.Item>
      </LabeledList>
      {!!data.can_manage && (
        <Box mt={1}>
          <RestrictedInput width="4em" value={share} minValue={0} maxValue={100} onChange={(_, value) => setShare(value)} />
          %{' '}
          <Button onClick={() => act('register_share', { percent: share })}>Сохранить</Button>
        </Box>
      )}
    </NtFrame>
  );
};

const GrantTab = () => {
  const { act, data } = useBackend<BudgetData>();
  const [points, setPoints] = useState(0);
  const left = data.grant_left || 0;
  return (
    <NtFrame
      title="Грант на исследования"
      help={`Наука покупает очки исследований за деньги бюджета: ${data.grant_price} кр. за очко, не больше ${data.grant_cap} очков в час. Очки начисляются сразу.`}>
      <LabeledList>
        <LabeledList.Item label="Осталось в этом часе">
          {left} очков
          {data.grant_resets_in ? `, лимит обновится через ${data.grant_resets_in} мин.` : ''}
        </LabeledList.Item>
      </LabeledList>
      {!!data.can_manage && (
        <Box mt={1}>
          <RestrictedInput width="6em" value={points} minValue={0} maxValue={left} onChange={(_, value) => setPoints(value)} />{' '}
          очков за <Credits amount={Math.ceil(points * data.grant_price)} />{' '}
          <Button disabled={points < 1} onClick={() => act('research_grant', { points })}>
            Купить
          </Button>
        </Box>
      )}
    </NtFrame>
  );
};

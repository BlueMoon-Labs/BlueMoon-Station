import { BooleanLike } from 'common/react';
import { useEffect, useState } from 'react';

import { useBackend } from '../backend';
import { AnimatedNumber, Box, Button, Input, LabeledList, NoticeBox, ProgressBar, RestrictedInput, Stack, Table } from '../components';
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
  /** Через сколько минут ближайший цикл экономики, на котором NT заберёт излишек */
  return_in?: number;
  shielded?: number;
  goal_cooldown?: number;
  express_ready_in?: number;
  goal?: {
    id: string;
    name: string;
    amount: number;
    is_ert?: BooleanLike;
    off_catalog?: BooleanLike;
    minutes_left?: number | null;
    collect_minutes_left?: number | null;
  } | null;
  emergency?: BooleanLike;
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
  /** Расходник: сотрудник заказывает без одобрения в пределах часового лимита */
  staple?: BooleanLike;
};

type PriceEntry = {
  price: number;
  available: BooleanLike;
};

type GoalPack = {
  type: string;
  name: string;
  group: string;
  price: number;
  available: BooleanLike;
};

type GoalErt = {
  id: number;
  name: string;
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
  goal_collect_minutes?: number;
  goal_packs?: GoalPack[];
  goal_max?: number;
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
  staple_cap?: number;
  handoff_minutes?: number;
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
  /** Зритель - ИИ: решает заявки, кроме заявок СБ */
  is_ai?: BooleanLike;
  ai_decides?: BooleanLike;
  /** Сколько расходников зритель ещё закажет без одобрения в этом часе; null - не сотрудник отдела */
  staple_left?: number | null;
  /** Кто сейчас на смене решает заявки отдела; null - никто */
  deciders?: string | null;
  /** Заявки других отделов, переданные снабжению: начальнику снабжения */
  handoff_requests?: RequestEntry[] | null;
  department?: DepartmentInfo;
  prices?: Record<string, PriceEntry>;
  goal_erts?: GoalErt[] | null;
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
      <Box className="NtTerm__hint">
        {data.is_ai
          ? 'ИИ открывает бюджет любого отдела и решает заявки сотрудников, кроме заявок СБ. Заказывать самому, выписывать премии и тратить бюджет иначе ИИ не может.'
          : 'ГП и капитан открывают бюджет любого отдела и управляют им, как глава.'}
      </Box>
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

type SavingGoal = NonNullable<DepartmentInfo['goal']>;

/** Как распорядиться набранной целью: пак каталога заказывают, пак консоли снабжения отгружают, отряд ОБР вызывает капитан. */
const goalOrderHint = (goal: SavingGoal, minutes: number) => {
  if (goal.is_ert) {
    return `отряд вызывает капитан с консоли связи, осталось ${minutes} мин.`;
  }
  if (goal.off_catalog) {
    return `отгрузите шаттлом снабжения или закажите с экспресс-консоли за ${minutes} мин.`;
  }
  return `заказать за ${minutes} мин.`;
};

const GoalLine = (props: { goal: SavingGoal; balance: number }) => {
  const { goal, balance } = props;
  const collected = Math.min(Math.max(balance, 0), goal.amount);
  const collectLeft = goal.collect_minutes_left;
  return (
    <>
      <NtLine label="Цель накопления">
        {goal.name}, {formatCredits(goal.amount)},{' '}
        {goal.minutes_left
          ? `набрано, ${goalOrderHint(goal, goal.minutes_left)}`
          : `копим${collectLeft !== null && collectLeft !== undefined ? `: набрать за ${collectLeft} мин., иначе цель снимется` : ''}; срок на ${goal.is_ert ? 'вызов' : 'заказ'} пойдёт, когда бюджет наберёт цену`}
      </NtLine>
      <ProgressBar value={goal.amount > 0 ? collected / goal.amount : 1} color={goal.minutes_left ? 'good' : 'average'} mb={0.5}>
        {formatCredits(collected)} из {formatCredits(goal.amount)}
      </ProgressBar>
    </>
  );
};

const OverviewTab = () => {
  const { data } = useBackend<BudgetData>();
  const department = data.department as DepartmentInfo;
  return (
    <>
      <NtFrame title={`Бюджет: ${department.name}`} help={<BudgetHelp />}>
        <BudgetGauge balance={department.balance} threshold={department.threshold ?? 0} />
        {!!department.emergency && (
          <NoticeBox info>Красный код: пока его не снимут, NT не забирает излишек бюджета.</NoticeBox>
        )}
        {!!department.return_due && (
          <NoticeBox warning>
            Бюджет выше порога: через {department.return_in ? `${department.return_in} мин.` : 'несколько минут'} NT заберёт{' '}
            <Credits amount={department.return_due} /> Потратьте излишек на закупки, одобрите ждущие заявки или назначьте цель
            накопления в каталоге.
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
        {!!department.goal && <GoalLine goal={department.goal} balance={department.balance} />}
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
          {data.grace_minutes} мин., а также цена пака - цели накопления (ставится в каталоге
          {data.goal_erts
            ? ', у снабжения - и на любой пак, который оно заказывает за свой бюджет, или на отряд ОБР, его вызывает капитан с консоли связи'
            : ''}
          ; набрать её цену нужно за {data.goal_collect_minutes} мин., иначе цель снимется; набрали - {data.goal_minutes} мин. на
          заказ; после её истечения или снятия новая - через {data.goal_cooldown_minutes} мин.). При красном коде и выше NT
          излишек не забирает.
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
                      `Заявку одобряет глава отдела, ГП или капитан${data.ai_decides ? ', а ещё ИИ' : ''} - тогда цена спишется из бюджета.`,
                      `Расходник (пометка "расходник") вы заказываете сами, без одобрения: до ${formatCredits(data.staple_cap ?? 0)} за час${data.staple_left !== null && data.staple_left !== undefined ? `, осталось ${formatCredits(data.staple_left)}` : ''}. Дороже остатка - обычная заявка.`,
                      'Пак каталога можно подать и с консоли заявок снабжения: такую заявку тоже оплатит бюджет отдела. Если одобрить некому, пак дороже лимита с консоли уходит заявкой снабжению.',
                      `Если на смене некому одобрить, заявка до ${data.auto_approve_limit} кр. одобряется сама, не чаще раза в ${data.auto_approve_cooldown} мин. на сотрудника.`,
                      ...(data.auto_approve_wait > 0
                        ? [`Если ответа нет ${data.auto_approve_wait} мин., такая заявка одобряется сама и при начальстве на смене.`]
                        : []),
                      ...(data.handoff_minutes && data.department?.id !== 'SEC' && data.department?.id !== 'CAR'
                        ? [`Заявку без решения ${data.handoff_minutes} мин. может решить и начальник снабжения, оплатит бюджет отдела.`]
                        : []),
                      `Решения могут ждать до ${data.pending_per_requester} ваших заявок.`,
                    ]),
                'Цены зависят от рынка и партнёров снабжения и меняются по ходу смены.',
              ],
            },
          ]}
        />
      }>
      {!canRequest && (
        <NoticeBox>
          {data.is_ai
            ? 'Заявки подают сотрудники отдела, ИИ решает их во вкладке "Заявки".'
            : 'Заявки подают только сотрудники отдела.'}
        </NoticeBox>
      )}
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
            const selfOrder = !canOrder && canRequest && !!pack.staple && (price?.price || 0) <= (data.staple_left ?? 0);
            return (
              <Table.Row key={pack.type} className="candystripe">
                <Table.Cell>
                  <Box bold>
                    {pack.name}
                    {!!pack.staple && (
                      <span className="NtTerm__tag" style={{ marginLeft: '6px' }}>
                        расходник
                      </span>
                    )}
                  </Box>
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
                    <Button
                      disabled={!available}
                      tooltip={selfOrder ? 'Расходник: бюджет отдела оплатит сразу, без одобрения' : undefined}
                      onClick={() => act('request', { pack: pack.type, reason })}>
                      {selfOrder ? 'Заказать' : 'Заявка'}
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
      {canOrder && !!data.goal_erts && <CargoGoalSection />}
    </NtFrame>
  );
};

const GOAL_PACKS_SHOWN = 12;

/** Цели снабжения вне каталога: отряды ОБР с консоли связи и паки, которые снабжение заказывает за свой бюджет. */
const CargoGoalSection = () => {
  const { act, data } = useBackend<BudgetData>();
  const [search, setSearch] = useState('');
  const goal = data.department?.goal;
  const locked = !!goal || !!data.department?.goal_cooldown;
  const query = search.trim().toLowerCase();
  const packs = (data.goal_packs || [])
    .filter((pack) => !query || pack.name.toLowerCase().includes(query) || pack.group.toLowerCase().includes(query))
    .sort((a, b) => b.price - a.price);
  const shown = packs.slice(0, GOAL_PACKS_SHOWN);
  const goalButton = (id: string, available: boolean, params: Record<string, string | number>) =>
    goal?.id === id ? (
      <Button selected onClick={() => act('clear_goal')}>
        Цель
      </Button>
    ) : (
      <Button
        disabled={!available || locked}
        tooltip={goal ? 'Цель уже выбрана: снимите её, чтобы выбрать другую' : 'Эта сумма не будет считаться излишком бюджета'}
        onClick={() => act('set_goal', params)}>
        Копить
      </Button>
    );
  return (
    <Box mt={1.5}>
      <Box bold mb={0.5}>
        Копить на дорогое
        {!!goal && (
          <Button ml={1} icon="times" onClick={() => act('clear_goal')}>
            Снять цель
          </Button>
        )}
      </Box>
      <Box className="NtTerm__hint" mb={1}>
        Снабжение может копить на отряд ОБР (его вызывает капитан с консоли связи за бюджет снабжения) или на любой пак,
        который оно заказывает за свой бюджет, до {formatCredits(data.goal_max ?? 0)}. Цель снимется, когда пак отгрузят
        шаттлом снабжения или закажут с экспресс-консоли за бюджет снабжения либо капитан вызовет отряд. Цены паков - на
        момент открытия окна.
      </Box>
      <Table>
        {(data.goal_erts || []).map((ert) => (
          <Table.Row key={`ert:${ert.id}`} className="candystripe">
            <Table.Cell>
              <Box bold>{ert.name}</Box>
              <Box italic color="label">
                Отряд ОБР, вызывает капитан с консоли связи
              </Box>
            </Table.Cell>
            <Table.Cell collapsing>
              {ert.available ? <Credits amount={ert.price} /> : <Box color="bad">уже вызван</Box>}
            </Table.Cell>
            <Table.Cell collapsing>{goalButton(`ert:${ert.id}`, !!ert.available, { ert: ert.id })}</Table.Cell>
          </Table.Row>
        ))}
      </Table>
      <Input fluid my={1} value={search} placeholder="Найти пак снабжения" onInput={(_, value) => setSearch(value)} />
      <Table>
        {shown.map((pack) => (
          <Table.Row key={pack.type} className="candystripe">
            <Table.Cell>
              <Box bold>{pack.name}</Box>
              <Box italic color="label">
                {pack.group}
              </Box>
            </Table.Cell>
            <Table.Cell collapsing>
              {pack.available ? <Credits amount={pack.price} /> : <Box color="bad">нет в наличии</Box>}
            </Table.Cell>
            <Table.Cell collapsing>{goalButton(pack.type, !!pack.available, { pack: pack.type })}</Table.Cell>
          </Table.Row>
        ))}
      </Table>
      {packs.length > shown.length && (
        <Box className="NtTerm__hint">Ещё {packs.length - shown.length}: уточните поиск.</Box>
      )}
      {!packs.length && <Box color="label">Ничего не нашлось.</Box>}
    </Box>
  );
};

/** Решить заявку может зритель: поле с сервера, у старых данных - по правам главы. */
const canDecide = (request: RequestEntry, canManage?: BooleanLike) =>
  request.status === 'pending' && !!(request.can_decide ?? canManage);

const RequestRow = (props: { request: RequestEntry; balance?: number; foreign?: boolean }) => {
  const { act, data } = useBackend<BudgetData>();
  const { request, balance, foreign } = props;
  const department = data.department;
  const params = foreign ? { uid: request.uid, department: request.department_id } : { uid: request.uid };
  const savable =
    !foreign &&
    !!data.can_manage &&
    request.status === 'pending' &&
    !!request.pack_type &&
    balance !== undefined &&
    balance < request.price &&
    !department?.goal &&
    !department?.goal_cooldown;
  return (
    <Table.Row className="candystripe">
      <Table.Cell>{request.uid}</Table.Cell>
      <Table.Cell>
        {request.pack}
        {!!foreign && (
          <Box italic color="label">
            {request.department}, в бюджете {formatCredits(request.balance ?? 0)}
          </Box>
        )}
      </Table.Cell>
      <Table.Cell>
        <Credits amount={request.price} />
      </Table.Cell>
      <Table.Cell>
        {request.requester}
        <Box italic color="label">
          {request.reason || 'без причины'}
        </Box>
        {request.status === 'pending' && (
          <Box className="NtTerm__hint">
            {request.waited !== undefined && `Ждёт ${request.waited} мин. `}
            {request.outlook}
          </Box>
        )}
      </Table.Cell>
      <Table.Cell>
        {canDecide(request, data.can_manage) ? (
          <>
            <Button color="good" onClick={() => act('approve', params)}>
              Одобрить
            </Button>
            <Button color="bad" onClick={() => act('deny', params)}>
              Отклонить
            </Button>
            {savable && (
              <Button
                tooltip="Денег не хватает: цена пака не будет считаться излишком, пока бюджет её копит"
                onClick={() => act('set_goal', { pack: request.pack_type })}>
                Копить
              </Button>
            )}
          </>
        ) : (
          <Box color={STATUS_COLORS[request.status]}>{STATUS_NAMES[request.status]}</Box>
        )}
      </Table.Cell>
    </Table.Row>
  );
};

const RequestsHeader = () => (
  <Table.Row header>
    <Table.Cell>№</Table.Cell>
    <Table.Cell>Пак</Table.Cell>
    <Table.Cell>Цена</Table.Cell>
    <Table.Cell>Кто и зачем</Table.Cell>
    <Table.Cell>Статус</Table.Cell>
  </Table.Row>
);

const RequestsTab = () => {
  const { data } = useBackend<BudgetData>();
  const requests = [...(data.requests || [])].reverse();
  const handoff = data.handoff_requests || [];
  return (
    <>
      <NtFrame
        title="Заявки"
        help={`Заявки сотрудников приходят отсюда, с консоли заявок снабжения и из приложения «Заказы снабжения». О новой ждущей заявке, откуда бы её ни подали, слышат канал отдела и карты начальства на смене. Решают глава отдела, ГП и капитан${data.ai_decides ? ', а ещё ИИ' : ''}${data.handoff_minutes && data.department?.id !== 'SEC' && data.department?.id !== 'CAR' ? `; заявку без решения ${data.handoff_minutes} мин. может решить и начальник снабжения` : ''}.`}>
        <NtLine label="Решает сейчас" tone={data.deciders ? undefined : 'warn'}>
          {data.deciders || 'никого нет на смене'}
        </NtLine>
        {requests.length ? (
          <Table>
            <RequestsHeader />
            {requests.map((request) => (
              <RequestRow key={request.uid} request={request} balance={data.department?.balance} />
            ))}
          </Table>
        ) : (
          <Box color="label">Заявок нет.</Box>
        )}
      </NtFrame>
      {!!data.handoff_requests && (
        <NtFrame
          title="Заявки отделов, переданные снабжению"
          help={`Заявки других отделов, кроме СБ, которые ждут решения дольше ${data.handoff_minutes} мин. Одобренную оплатит бюджет отдела заявки, не снабжения.`}>
          {handoff.length ? (
            <Table>
              <RequestsHeader />
              {handoff.map((request) => (
                <RequestRow key={`${request.department_id}:${request.uid}`} request={request} foreign />
              ))}
            </Table>
          ) : (
            <Box color="label">Переданных заявок нет.</Box>
          )}
        </NtFrame>
      )}
    </>
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

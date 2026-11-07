import { BooleanLike } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  Collapsible,
  Input,
  LabeledList,
  NoticeBox,
  RestrictedInput,
  Section,
  Stack,
  Table,
  Tabs,
} from '../components';
import { NtosWindow } from '../layouts';
import { Credits, formatCredits, HistoryTable, TransactionEntry } from './common/Economy';

type AuditRules = {
  siphon_threshold: number;
  siphon_minutes: number;
  structuring_count: number;
  structuring_minutes: number;
  insider_threshold: number;
  insider_minutes: number;
  event_eta_min: number;
  event_eta_max: number;
  refute_minutes: number;
  trace_minutes: number;
  trace_depth: number;
  fee_percent: number;
  owed_cap: number;
  reason_max: number;
  search_max: number;
};

type CaseKind =
  | 'budget_siphon'
  | 'self_bonus'
  | 'structuring'
  | 'unknown_device'
  | 'insider'
  | 'anon_cashout'
  | 'cryptominer';

export type PooledRecipient = {
  number: number;
  holder: string;
  amount: number;
  left: number;
  frozen: BooleanLike;
  balance: number;
};

type RefundTarget = {
  number: number;
  frozen: BooleanLike;
  balance: number;
  left: number;
};

export type AuditCase = {
  uid: number;
  kind: CaseKind;
  text: string;
  amount: number;
  time: string;
  source: number;
  source_holder: string;
  recipient: number | null;
  recipient_holder: string | null;
  recipient_frozen: BooleanLike;
  recipient_balance: number;
  pooled: BooleanLike;
  mine: BooleanLike;
  recipients: PooledRecipient[];
  closed: BooleanLike;
  closed_by: string | null;
  close_reason: string | null;
  refunded: number;
};

type AccountKind = 'personal' | 'anonymous' | 'budget' | 'system';

type AccountStatus = 'active' | 'blocked' | 'frozen' | 'dormant';

type AccountRow = {
  number: number;
  holder: string;
  balance: number;
  kind: AccountKind;
  status: AccountStatus;
};

type AccountCard = AccountRow & {
  frozen_by: string | null;
  freeze_reason: string | null;
  freeze_locked?: string | null;
  cases: number[];
  history: TransactionEntry[];
};

export type TraceNodeData = {
  holder: string;
  number: number;
  amount: number;
  children: TraceNodeData[];
};

type TraceData = {
  number: number;
  holder: string;
  time: string;
  tree: TraceNodeData[];
};

export type FinancialAuditData = {
  message: string;
  can_audit: BooleanLike;
  audit_rights: string;
  rules?: AuditRules;
  my_account?: number | null;
  cases?: AuditCase[];
  query?: string;
  results?: AccountRow[];
  selected?: AccountCard | null;
  trace?: TraceData | null;
};

type Tab = 'cases' | 'accounts' | 'rules';

const CASE_KIND: Record<CaseKind, string> = {
  budget_siphon: 'Отток бюджета',
  self_bonus: 'Премия себе',
  structuring: 'Дробление переводов',
  unknown_device: 'Неопознанное устройство',
  insider: 'Инсайд на бирже',
  anon_cashout: 'Наличные с анонимного счёта',
  cryptominer: 'Криптомайнер на личный счёт',
};

const ACCOUNT_KIND: Record<AccountKind, string> = {
  personal: 'личный',
  anonymous: 'анонимный',
  budget: 'бюджет отдела',
  system: 'служебный',
};

const ACCOUNT_STATUS: Record<AccountStatus, [string, string | undefined]> = {
  active: ['активен', undefined],
  blocked: ['заблокирован казной', 'bad'],
  frozen: ['заморожен аудитом', 'bad'],
  dormant: ['владелец не на смене', 'label'],
};

const caseFee = (amount: number, rules: AuditRules) => Math.floor((amount * rules.fee_percent) / 100);

export const NtosFinancialAudit = () => (
  <NtosWindow width={760} height={680}>
    <NtosWindow.Content scrollable>
      <NtosFinancialAuditContent />
    </NtosWindow.Content>
  </NtosWindow>
);

export const NtosFinancialAuditContent = () => {
  const { data } = useBackend<FinancialAuditData>();
  const [tab, setTab] = useState<Tab>('cases');
  const [caseUid, setCaseUid] = useState<number | null>(null);
  if (!data.can_audit || !data.rules) {
    return <NoAccess />;
  }
  const open = (data.cases || []).filter((entry) => !entry.closed).length;
  return (
    <>
      {!!data.message && <NoticeBox info>{data.message}</NoticeBox>}
      <Tabs>
        <Tabs.Tab icon="folder-open" selected={tab === 'cases'} onClick={() => setTab('cases')}>
          {open ? `Дела (${open})` : 'Дела'}
        </Tabs.Tab>
        <Tabs.Tab icon="search-dollar" selected={tab === 'accounts'} onClick={() => setTab('accounts')}>
          Счета
        </Tabs.Tab>
        <Tabs.Tab icon="book" selected={tab === 'rules'} onClick={() => setTab('rules')}>
          Правила
        </Tabs.Tab>
      </Tabs>
      {tab === 'cases' && (
        <CasesTab rules={data.rules} caseUid={caseUid} setCaseUid={setCaseUid} openAccounts={() => setTab('accounts')} />
      )}
      {tab === 'accounts' && <AccountsTab rules={data.rules} />}
      {tab === 'rules' && <RulesTab rules={data.rules} />}
    </>
  );
};

const NoAccess = () => {
  const { data } = useBackend<FinancialAuditData>();
  return (
    <>
      {!!data.message && <NoticeBox info>{data.message}</NoticeBox>}
      <Section title="Финансовый аудит">
        <NoticeBox>Дела, счета и след денег открыты только тем, кто ведёт аудит: {data.audit_rights}.</NoticeBox>
        <Box color="label">
          Аудит замечает подозрительные движения денег: крупные выплаты из бюджетов одному человеку, серии переводов
          одному получателю, списания чужими устройствами, сделки на бирже перед новостями и обналичивание анонимных
          счетов. Аудитор может заморозить личный счёт, вернуть украденное пострадавшему или закрыть дело с причиной.
        </Box>
      </Section>
    </>
  );
};

type CasesProps = {
  rules: AuditRules;
  caseUid: number | null;
  setCaseUid: (uid: number | null) => void;
  openAccounts: () => void;
};

const CasesTab = (props: CasesProps) => {
  const { data } = useBackend<FinancialAuditData>();
  const { rules, caseUid, setCaseUid, openAccounts } = props;
  const cases = [...(data.cases || [])].reverse();
  const open = cases.filter((entry) => !entry.closed);
  const closed = cases.filter((entry) => !!entry.closed);
  const current = cases.find((entry) => entry.uid === caseUid);
  return (
    <>
      {!!current && (
        <CaseDetails entry={current} rules={rules} onClose={() => setCaseUid(null)} openAccounts={openAccounts} />
      )}
      <Section title="Открытые дела">
        {open.length ? (
          <CaseTable entries={open} selected={caseUid} onPick={setCaseUid} />
        ) : (
          <Box color="label">Открытых дел нет.</Box>
        )}
      </Section>
      <Section title="Закрытые дела">
        {closed.length ? (
          <Collapsible title={`Показать (${closed.length})`}>
            <CaseTable entries={closed} selected={caseUid} onPick={setCaseUid} />
          </Collapsible>
        ) : (
          <Box color="label">Закрытых дел нет.</Box>
        )}
      </Section>
    </>
  );
};

const caseOutcome = (entry: AuditCase) => {
  if (!entry.closed) {
    return null;
  }
  const by = entry.closed_by ? ` (${entry.closed_by})` : '';
  return entry.close_reason
    ? `Закрыто без возврата${by}: ${entry.close_reason}`
    : `Закрыто возвратом ${formatCredits(entry.refunded)}${by}`;
};

const CaseTable = (props: { entries: AuditCase[]; selected: number | null; onPick: (uid: number) => void }) => (
  <Table>
    <Table.Row header>
      <Table.Cell>№</Table.Cell>
      <Table.Cell>Время</Table.Cell>
      <Table.Cell>Вид</Table.Cell>
      <Table.Cell>Откуда и куда</Table.Cell>
      <Table.Cell>Сумма</Table.Cell>
      <Table.Cell />
    </Table.Row>
    {props.entries.map((entry) => (
      <Table.Row key={entry.uid} className="candystripe">
        <Table.Cell collapsing>{entry.uid}</Table.Cell>
        <Table.Cell collapsing>{entry.time}</Table.Cell>
        <Table.Cell>
          {CASE_KIND[entry.kind] || entry.kind}
          {!!entry.closed && (
            <Box color="label" italic>
              {caseOutcome(entry)}
            </Box>
          )}
        </Table.Cell>
        <Table.Cell>
          {entry.source_holder} №{entry.source}
          {entry.recipient !== null && (
            <>
              {' → '}
              {entry.recipient_holder} №{entry.recipient}
            </>
          )}
          {!!entry.pooled && ` → счета без владельца: ${entry.recipients.length}`}
        </Table.Cell>
        <Table.Cell collapsing nowrap>
          <Credits amount={entry.amount} />
        </Table.Cell>
        <Table.Cell collapsing>
          <Button selected={props.selected === entry.uid} onClick={() => props.onPick(entry.uid)}>
            Разобрать
          </Button>
        </Table.Cell>
      </Table.Row>
    ))}
  </Table>
);

type CaseDetailsProps = {
  entry: AuditCase;
  rules: AuditRules;
  onClose: () => void;
  openAccounts: () => void;
};

const CaseDetails = (props: CaseDetailsProps) => {
  const { act } = useBackend<FinancialAuditData>();
  const { entry, rules, onClose, openAccounts } = props;
  const mine = !!entry.mine;
  const showAccount = (number: number) => {
    act('select', { number });
    openAccounts();
  };
  return (
    <Section
      title={`Дело №${entry.uid}: ${CASE_KIND[entry.kind] || entry.kind}`}
      buttons={
        <Button icon="times" onClick={onClose}>
          Свернуть
        </Button>
      }>
      <LabeledList>
        <LabeledList.Item label="Что замечено">{entry.text}</LabeledList.Item>
        <LabeledList.Item label="Сумма">
          <Credits amount={entry.amount} />
        </LabeledList.Item>
        <LabeledList.Item label="Открыто">{entry.time}</LabeledList.Item>
        <LabeledList.Item
          label="Откуда"
          buttons={
            <Button icon="search" onClick={() => showAccount(entry.source)}>
              Счёт
            </Button>
          }>
          {entry.source_holder} №{entry.source}
        </LabeledList.Item>
        {entry.recipient !== null && (
          <LabeledList.Item
            label="Куда"
            buttons={
              <Button icon="search" onClick={() => showAccount(entry.recipient as number)}>
                Счёт
              </Button>
            }>
            {entry.recipient_holder} №{entry.recipient}
            {!!entry.recipient_frozen && (
              <Box inline color="bad" ml={1}>
                заморожен
              </Box>
            )}
          </LabeledList.Item>
        )}
        {!!entry.closed && <LabeledList.Item label="Итог">{caseOutcome(entry)}</LabeledList.Item>}
      </LabeledList>
      {!!entry.pooled && <PooledRecipients entry={entry} rules={rules} showAccount={showAccount} locked={mine} />}
      {!entry.closed && mine && (
        <Box color="average" mt={1}>
          В деле ваш счёт или ваши платежи: возврат и закрытие ведёт другой аудитор.
        </Box>
      )}
      {!entry.closed && !mine && (
        <>
          {entry.recipient !== null ? (
            <RefundForm
              key={`refund-${entry.uid}`}
              entry={entry}
              rules={rules}
              target={{
                number: entry.recipient,
                frozen: entry.recipient_frozen,
                balance: entry.recipient_balance,
                left: entry.amount,
              }}
            />
          ) : entry.pooled ? null : (
            <Box color="label" mt={1}>
              У дела нет счёта-получателя, вернуть деньги нельзя: деньги ушли наличными. Дело закрывается с причиной.
            </Box>
          )}
          <CloseCaseForm key={`close-${entry.uid}`} entry={entry} rules={rules} />
        </>
      )}
    </Section>
  );
};

type PooledRecipientsProps = {
  entry: AuditCase;
  rules: AuditRules;
  showAccount: (number: number) => void;
  locked: boolean;
};

const PooledRecipients = (props: PooledRecipientsProps) => {
  const { entry, rules, showAccount, locked } = props;
  const [picked, setPicked] = useState<number | null>(null);
  const target = entry.recipients.find((recipient) => recipient.number === picked);
  return (
    <Box mt={1}>
      <Box color="label" mb={0.5}>
        Выплаты из бюджета на счета без владельца собраны в одно дело. Вернуть можно с любого получателя из списка, не
        больше того, что ушло на его счёт; дело закрывается, когда возвращено всё или его закрыли с причиной.
      </Box>
      <Table>
        <Table.Row header>
          <Table.Cell>Получатель</Table.Cell>
          <Table.Cell>Ушло</Table.Cell>
          <Table.Cell>Осталось вернуть</Table.Cell>
          <Table.Cell />
        </Table.Row>
        {entry.recipients.map((recipient) => (
          <Table.Row key={recipient.number} className="candystripe">
            <Table.Cell>
              {recipient.holder} №{recipient.number}
              {!!recipient.frozen && (
                <Box inline color="bad" ml={1}>
                  заморожен
                </Box>
              )}
            </Table.Cell>
            <Table.Cell>
              <Credits amount={recipient.amount} />
            </Table.Cell>
            <Table.Cell>
              <Credits amount={recipient.left} />
            </Table.Cell>
            <Table.Cell collapsing>
              <Button icon="search" onClick={() => showAccount(recipient.number)}>
                Счёт
              </Button>
              {!entry.closed && !locked && recipient.left > 0 && (
                <Button selected={picked === recipient.number} onClick={() => setPicked(recipient.number)}>
                  Возврат
                </Button>
              )}
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
      {!entry.closed && !locked && !!target && (
        <RefundForm key={`refund-${entry.uid}-${target.number}`} entry={entry} rules={rules} target={target} pooled />
      )}
    </Box>
  );
};

const RefundForm = (props: { entry: AuditCase; rules: AuditRules; target: RefundTarget; pooled?: boolean }) => {
  const { act } = useBackend<FinancialAuditData>();
  const { entry, rules, target, pooled } = props;
  const limit = Math.max(0, Math.min(target.left, target.balance));
  const [amount, setAmount] = useState(limit);
  const fee = caseFee(amount, rules);
  return (
    <Box mt={1}>
      <Box bold mb={0.5}>
        {pooled ? `Возврат со счёта №${target.number}` : 'Возврат по делу'}
      </Box>
      <Stack align="center">
        <Stack.Item>
          <RestrictedInput
            width="6em"
            value={amount}
            minValue={0}
            maxValue={target.left}
            onChange={(_, value) => setAmount(value)}
          />{' '}
          кр.
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="undo"
            disabled={!target.frozen || amount < 1}
            onClick={() =>
              act('refund', pooled ? { uid: entry.uid, amount, recipient: target.number } : { uid: entry.uid, amount })
            }>
            Вернуть средства
          </Button>
        </Stack.Item>
      </Stack>
      <Box color="label" mt={0.5}>
        Пострадавшему вернётся {formatCredits(amount - fee)}, сбор отдела безопасности - {formatCredits(fee)} (
        {rules.fee_percent}% суммы). Деньги списываются с замороженного счёта получателя, не больше{' '}
        {pooled ? 'остатка по этому получателю' : 'суммы дела'} ({formatCredits(target.left)}) и его баланса (сейчас{' '}
        {formatCredits(target.balance)}). NT за дела не доплачивает.{' '}
        {pooled
          ? 'Остаток по получателю уменьшается с каждым возвратом.'
          : 'После возврата дело закрыто, второго возврата нет.'}
      </Box>
      {!target.frozen && (
        <Box color="average" mt={0.5}>
          Сначала заморозьте счёт получателя: кнопка &quot;Счёт&quot; у получателя.
        </Box>
      )}
    </Box>
  );
};

const CloseCaseForm = (props: { entry: AuditCase; rules: AuditRules }) => {
  const { act } = useBackend<FinancialAuditData>();
  const { entry, rules } = props;
  const [reason, setReason] = useState('');
  return (
    <Box mt={1}>
      <Box bold mb={0.5}>
        Закрыть без возврата
      </Box>
      <Stack align="center">
        <Stack.Item grow>
          <Input
            fluid
            value={reason}
            maxLength={rules.reason_max}
            placeholder="Причина закрытия"
            onInput={(_, value) => setReason(value)}
          />
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="folder"
            disabled={!reason.trim()}
            onClick={() => act('close_case', { uid: entry.uid, reason })}>
            Закрыть дело
          </Button>
        </Stack.Item>
      </Stack>
      <Box color="label" mt={0.5}>
        Деньги не двигаются. Владельцы обоих счетов дела получат сообщение на карту с вашим именем и причиной. Дело,
        где замешан ваш счёт, закрывает другой аудитор.
      </Box>
    </Box>
  );
};

const AccountsTab = (props: { rules: AuditRules }) => {
  const { act, data } = useBackend<FinancialAuditData>();
  const { rules } = props;
  const [query, setQuery] = useState(data.query || '');
  const results = data.results || [];
  return (
    <>
      <Section title="Поиск счёта">
        <Stack align="center">
          <Stack.Item grow>
            <Input
              fluid
              value={query}
              placeholder="Имя владельца или номер счёта"
              onInput={(_, value) => setQuery(value)}
              onEnter={(_, value) => act('search', { query: value })}
            />
          </Stack.Item>
          <Stack.Item>
            <Button icon="search" onClick={() => act('search', { query })}>
              Найти
            </Button>
          </Stack.Item>
        </Stack>
        <Box color="label" mt={0.5}>
          Ищется часть имени среди личных счетов без учёта регистра (не больше {rules.search_max}) и точный номер
          любого счёта, включая бюджеты отделов.
        </Box>
        {results.length > 0 && (
          <Box mt={1}>
            <Table>
              {results.map((account) => (
                <Table.Row key={account.number} className="candystripe">
                  <Table.Cell>{account.holder}</Table.Cell>
                  <Table.Cell collapsing>№{account.number}</Table.Cell>
                  <Table.Cell collapsing color="label">
                    {ACCOUNT_KIND[account.kind]}
                  </Table.Cell>
                  <Table.Cell collapsing color={ACCOUNT_STATUS[account.status][1]}>
                    {ACCOUNT_STATUS[account.status][0]}
                  </Table.Cell>
                  <Table.Cell collapsing>
                    <Button
                      selected={data.selected?.number === account.number}
                      onClick={() => act('select', { number: account.number })}>
                      Открыть
                    </Button>
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          </Box>
        )}
      </Section>
      {!!data.selected && <AccountSection key={data.selected.number} account={data.selected} rules={rules} />}
      {!!data.trace && <TraceSection trace={data.trace} rules={rules} />}
    </>
  );
};

const AccountSection = (props: { account: AccountCard; rules: AuditRules }) => {
  const { act, data } = useBackend<FinancialAuditData>();
  const { account, rules } = props;
  const [reason, setReason] = useState('');
  const isSelf = account.number === data.my_account;
  const freezable = account.kind === 'personal' || account.kind === 'anonymous';
  const frozen = account.status === 'frozen';
  return (
    <Section
      title={`Счёт №${account.number}: ${account.holder}`}
      buttons={
        <>
          <Button icon="project-diagram" onClick={() => act('trace', { number: account.number })}>
            Проследить
          </Button>
          <Button icon="times" onClick={() => act('select', { number: 0 })}>
            Закрыть
          </Button>
        </>
      }>
      <LabeledList>
        <LabeledList.Item label="Баланс">
          <Credits amount={account.balance} />
        </LabeledList.Item>
        <LabeledList.Item label="Тип">{ACCOUNT_KIND[account.kind]}</LabeledList.Item>
        <LabeledList.Item label="Состояние" color={ACCOUNT_STATUS[account.status][1]}>
          {ACCOUNT_STATUS[account.status][0]}
          {frozen && !!account.frozen_by && ` (${account.frozen_by}): ${account.freeze_reason}`}
        </LabeledList.Item>
        <LabeledList.Item label="Дела">
          {account.cases.length ? account.cases.map((uid) => `№${uid}`).join(', ') : 'нет'}
        </LabeledList.Item>
      </LabeledList>
      {isSelf && (
        <Box color="label" mt={1}>
          Это ваш счёт: заморозить его или вести по нему дело может только другой аудитор.
        </Box>
      )}
      {!isSelf && freezable && frozen && !!account.freeze_locked && (
        <Box mt={1} color="average">
          {account.freeze_locked}
        </Box>
      )}
      {!isSelf && freezable && frozen && !account.freeze_locked && (
        <Box mt={1}>
          <Button icon="unlock" onClick={() => act('unfreeze', { number: account.number })}>
            Разморозить
          </Button>
        </Box>
      )}
      {!isSelf && freezable && !frozen && (
        <Stack mt={1} align="center">
          <Stack.Item grow>
            <Input
              fluid
              value={reason}
              maxLength={rules.reason_max}
              placeholder="Причина заморозки"
              onInput={(_, value) => setReason(value)}
            />
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="snowflake"
              color="bad"
              disabled={!reason.trim()}
              onClick={() => act('freeze', { number: account.number, reason })}>
              Заморозить
            </Button>
          </Stack.Item>
        </Stack>
      )}
      <Box color="label" mt={1}>
        {freezable ? (
          <>
            Заморозка закрывает переводы, покупки, снятие наличных и биржу. Счёт по-прежнему принимает деньги и
            отдаёт возвраты по делу, зарплата копится долгом отдела (до {rules.owed_cap} выплат) до разморозки.
            Владелец получает сообщение на карту с вашим именем и причиной.
          </>
        ) : (
          'Замораживаются только личные и анонимные счета; бюджеты и служебные счета - нет.'
        )}
      </Box>
      <Box bold mt={1} mb={0.5}>
        Последние операции
      </Box>
      <HistoryTable entries={account.history} />
    </Section>
  );
};

const TraceNode = (props: { node: TraceNodeData; depth: number }) => {
  const { node, depth } = props;
  return (
    <Box ml={depth * 2}>
      <Box>
        {depth > 0 ? '└ ' : ''}
        {node.holder} №{node.number}:{' '}
        <Box inline bold>
          {formatCredits(node.amount)}
        </Box>
      </Box>
      {node.children.map((child) => (
        <TraceNode key={child.number} node={child} depth={depth + 1} />
      ))}
    </Box>
  );
};

const TraceSection = (props: { trace: TraceData; rules: AuditRules }) => {
  const { trace, rules } = props;
  return (
    <Section title={`След денег со счёта №${trace.number}: ${trace.holder} (на ${trace.time})`}>
      {trace.tree.length ? (
        trace.tree.map((node) => <TraceNode key={node.number} node={node} depth={0} />)
      ) : (
        <Box color="label">За последние {rules.trace_minutes} мин. деньги со счёта никуда не уходили.</Box>
      )}
      <Box color="label" mt={1}>
        Куда уходили деньги за последние {rules.trace_minutes} мин., до {rules.trace_depth} шагов вглубь. Дальше
        раскрываются только личные счета: бюджеты, касса и наличные - конечные точки. Зарплата, налог и правки
        Центрального командования в след не входят. След - снимок на момент нажатия кнопки Проследить.
      </Box>
    </Section>
  );
};

const RulesTab = (props: { rules: AuditRules }) => {
  const { data } = useBackend<FinancialAuditData>();
  const { rules } = props;
  return (
    <Section title="Когда открывается дело">
      <LabeledList>
        <LabeledList.Item label={CASE_KIND.budget_siphon}>
          Выплаты из бюджета отдела одному человеку (кроме зарплаты) на <Credits amount={rules.siphon_threshold} /> и
          больше за {rules.siphon_minutes} мин. Выплаты на счета без владельца считаются вместе, как одному
          получателю.
        </LabeledList.Item>
        <LabeledList.Item label={CASE_KIND.self_bonus}>
          Глава выписал премию на свой счёт, на любую сумму.
        </LabeledList.Item>
        <LabeledList.Item label={CASE_KIND.structuring}>
          {rules.structuring_count} и больше личных переводов одному получателю за {rules.structuring_minutes} мин.
        </LabeledList.Item>
        <LabeledList.Item label={CASE_KIND.unknown_device}>
          Списание с личного счёта чужим устройством. Владелец устройства неизвестен: след ведёт к счёту, куда ушли
          деньги.
        </LabeledList.Item>
        <LabeledList.Item label={CASE_KIND.insider}>
          Сделки с акциями на <Credits amount={rules.insider_threshold} /> и больше в сторону новости компании. Для
          настоящей новости считаются сделки после того, как она встала в очередь: она выходит через{' '}
          {rules.event_eta_min}-{rules.event_eta_max} мин. Для фальшивого пресс-релиза - сделки за{' '}
          {rules.insider_minutes} мин. до его выхода, а после выхода - сделки в сторону опровержения, которое выходит
          через {rules.refute_minutes} мин.
        </LabeledList.Item>
        <LabeledList.Item label={CASE_KIND.anon_cashout}>
          Каждое снятие наличных с анонимного счёта, с местом снятия. Получателя нет, вернуть деньги нельзя.
        </LabeledList.Item>
        <LabeledList.Item label={CASE_KIND.cryptominer}>
          Криптомайнер платит на личный счёт, а не в бюджет снабжения, с местом майнера. Вернуть деньги можно в бюджет
          снабжения.
        </LabeledList.Item>
      </LabeledList>
      <Box color="label" mt={1}>
        Повторы по той же паре счетов добавляются в открытое дело, если с последнего движения по нему прошло меньше{' '}
        {rules.trace_minutes} мин.; позже открывается новое дело. Зарплата, налог, оплата работы,
        контракты, касса и чаевые дел не открывают. Открытые дела не пропадают, пока их не закроют.
      </Box>
      <Box color="label" mt={1}>
        Возврат: только по открытому делу, с замороженного счёта получателя на счёт, откуда ушли деньги.{' '}
        {rules.fee_percent}% суммы уходит сбором в бюджет отдела безопасности, остальное - пострадавшему. Закрыть
        дело без возврата можно с причиной; владельцы обоих счетов получат сообщение. Ведут аудит:{' '}
        {data.audit_rights}.
      </Box>
    </Section>
  );
};

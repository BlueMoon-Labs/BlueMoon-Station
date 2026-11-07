import { BooleanLike } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  Chart,
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
import { Window } from '../layouts';
import { ChangeBadge, Credits, formatCredits, Sparkline, StockEntry } from './common/Economy';

type Reason = { id: string; name: string; amount: number };
type Category = { id: string; name: string; amount: number; reasons: Reason[] };

type Snapshot = { minute: number; minted: number; burned: number; in_accounts: number; cash: number };

type Department = {
  id: string;
  name: string;
  number: number | null;
  balance: number | null;
  owed: number;
  staff: number;
  threshold?: number;
  return_due?: number;
  purchases?: number;
  purchases_per_hour?: number;
  purchase_amount?: number;
  returned?: number;
};

type AdminAccount = {
  number: number;
  holder: string;
  budget: BooleanLike;
  department: string | null;
  balance: number;
  state: number;
  frozen_by?: string | null;
  freeze_reason?: string | null;
};

type AuditFlag = {
  uid: number;
  time: string;
  text: string;
  amount: number;
  account: number;
  counterparty: number | null;
  closed: BooleanLike;
  refunded: number;
  closed_by: string | null;
};

type Commodity = {
  id: string;
  name: string;
  factor: number;
  sell: number;
  hot: number;
  demand: number;
  history: number[];
  buyer: string | null;
};

type Partner = {
  id: string;
  name: string;
  unlocked: BooleanLike;
  tier: number;
  reputation: number;
  discount: number;
  markup: number;
  wealth: number;
  next_unlock: string | null;
  buys: string;
  sells: string;
};

type Company = StockEntry & { base_price: number; event_mult: number; queued: number };

export type EconomyAdminData = {
  message: string;
  tax_rate: number;
  state: string;
  minted: number;
  burned: number;
  price_index: number;
  ledger: {
    minted: number;
    burned: number;
    total: number;
    by_category: Category[];
    department_kept?: number;
    department_burned?: number;
    department_sink?: number;
    department_sink_min?: number;
    department_sink_max?: number;
    department_sink_no_return?: number;
    department_sink_no_command?: number;
    department_sink_bare?: number;
    tax_nt_burned?: number;
    budget_returned?: number;
    crew?: { count: number; median_balance: number; median_start: number; median_growth: number };
  };
  snapshots: Snapshot[];
  departments: Department[];
  accounts: AdminAccount[];
  flags: AuditFlag[];
  commodities: Commodity[];
  partners: Partner[];
  companies: Company[];
  config_errors: string[];
  config_reloaded_at: string | null;
  tax_max: number;
  adjust_max: number;
  comment_max: number;
  freeze_reason_max: number;
  headline_max: number;
  effect_min: number;
  effect_max: number;
  event_mult_max: number;
  price_max_ratio: number;
  reset_phrase: string;
  persist_decay: number;
  station_event_cooldown: number;
  snapshot_minutes: number;
};

const ACCOUNT_FROZEN = 1;

const STATE_NAMES: Record<string, string> = {
  rich: 'богатая',
  normal: 'обычная',
  poor: 'бедная',
};

const ACCOUNT_STATES: Record<number, string> = {
  0: 'активен',
  1: 'заморожен',
  2: 'спит',
};

const TABS = [
  { id: 'money', name: 'Деньги', icon: 'coins' },
  { id: 'accounts', name: 'Счета', icon: 'id-card' },
  { id: 'departments', name: 'Отделы', icon: 'building' },
  { id: 'market', name: 'Рынок', icon: 'chart-line' },
  { id: 'partners', name: 'Партнёры', icon: 'handshake' },
  { id: 'exchange', name: 'Биржа', icon: 'chart-area' },
  { id: 'audit', name: 'Аудит', icon: 'search-dollar' },
  { id: 'config', name: 'Конфиг', icon: 'cog' },
];

export const EconomyAdmin = () => {
  const { act, data } = useBackend<EconomyAdminData>();
  const [tab, setTab] = useState('money');
  const [comment, setComment] = useState('');
  const send = (action: string, params: Record<string, unknown> = {}) => act(action, { ...params, comment });
  return (
    <Window title="Экономика" width={920} height={720}>
      <Window.Content scrollable>
        <Section
          title="Действие"
          buttons={
            <Button icon="sync" onClick={() => act('refresh')}>
              Обновить
            </Button>
          }>
          <Stack align="center">
            <Stack.Item grow>
              <Input
                fluid
                maxLength={data.comment_max}
                value={comment}
                placeholder="Комментарий для админ-лога: обязателен для всех действий, кроме перечитки конфига"
                onInput={(_, value) => setComment(value)}
              />
            </Stack.Item>
          </Stack>
          {!!data.message && (
            <NoticeBox info mt={1} mb={0}>
              {data.message}
            </NoticeBox>
          )}
        </Section>
        <Tabs>
          {TABS.map(({ id, name, icon }) => (
            <Tabs.Tab key={id} icon={icon} selected={tab === id} onClick={() => setTab(id)}>
              {name}
            </Tabs.Tab>
          ))}
        </Tabs>
        {tab === 'money' && <MoneyTab data={data} />}
        {tab === 'accounts' && <AccountsTab data={data} send={send} />}
        {tab === 'departments' && <DepartmentsTab data={data} />}
        {tab === 'market' && <MarketTab data={data} send={send} />}
        {tab === 'partners' && <PartnersTab data={data} />}
        {tab === 'exchange' && <ExchangeTab data={data} send={send} />}
        {tab === 'audit' && <AuditTab data={data} />}
        {tab === 'config' && <ConfigTab data={data} send={send} />}
      </Window.Content>
    </Window>
  );
};

type Send = (action: string, params?: Record<string, unknown>) => void;

const SnapshotChart = (props: { snapshots: Snapshot[]; minutes: number }) => {
  const { snapshots, minutes } = props;
  if (snapshots.length < 2) {
    return (
      <Box color="label">
        Журнал делает снимок раз в {minutes} мин.; график появится после двух снимков.
      </Box>
    );
  }
  const first = snapshots[0].minute;
  const last = snapshots[snapshots.length - 1].minute;
  const top = Math.max(1, ...snapshots.map((snapshot) => Math.max(snapshot.minted, snapshot.burned)));
  return (
    <>
      <Box className="EconomyAdmin__chart" position="relative" height="8em">
        <Chart.Line
          fillPositionedParent
          data={snapshots.map((snapshot) => [snapshot.minute, snapshot.minted])}
          rangeX={[first, last]}
          rangeY={[0, top]}
          strokeColor="#5baa27"
          fillColor="none"
        />
        <Chart.Line
          fillPositionedParent
          data={snapshots.map((snapshot) => [snapshot.minute, snapshot.burned])}
          rangeX={[first, last]}
          rangeY={[0, top]}
          strokeColor="#db2828"
          fillColor="none"
        />
      </Box>
      <Box color="label" mt={0.5}>
        <Box inline color="good">
          эмиссия
        </Box>{' '}
        и{' '}
        <Box inline color="bad">
          стоки
        </Box>{' '}
        за каждые {minutes} мин., с {first} по {last} мин. мира; пик {formatCredits(top)}.
      </Box>
    </>
  );
};

const CalibrationSection = (props: { data: EconomyAdminData }) => {
  const { ledger } = props.data;
  const crew = ledger.crew;
  return (
    <Section title="Калибровка">
      <LabeledList>
        <LabeledList.Item label="Стоки отделов">
          {ledger.department_sink ?? 0}%; без возврата излишка {ledger.department_sink_no_return ?? 0}%, без казны{' '}
          {ledger.department_sink_no_command ?? 0}%, без обоих {ledger.department_sink_bare ?? 0}%
        </LabeledList.Item>
        <LabeledList.Item label="Возврат излишков NT">
          <Credits amount={ledger.budget_returned ?? 0} />
        </LabeledList.Item>
        <LabeledList.Item label="Доля NT с налога">
          <Credits amount={ledger.tax_nt_burned ?? 0} />
        </LabeledList.Item>
        {!!crew && (
          <LabeledList.Item label="Личные деньги экипажа">
            медиана <Credits amount={crew.median_balance} /> при подъёмных <Credits amount={crew.median_start} />,
            рост x{crew.median_growth} ({crew.count} чел. на смене)
          </LabeledList.Item>
        )}
      </LabeledList>
      <Box color="label" mt={1}>
        Закупки и возвраты по отделам - на вкладке &quot;Отделы&quot;.
      </Box>
    </Section>
  );
};

const MoneyTab = (props: { data: EconomyAdminData }) => {
  const { data } = props;
  const { ledger } = data;
  return (
    <>
      <Section title="Журнал NT за раунд">
        <LabeledList>
          <LabeledList.Item label="На счетах и наличными">
            <Credits amount={ledger.total} />
          </LabeledList.Item>
          <LabeledList.Item label="Эмиссия">
            <Credits amount={data.minted} />
          </LabeledList.Item>
          <LabeledList.Item label="Стоки">
            <Credits amount={data.burned} />
          </LabeledList.Item>
          <LabeledList.Item label="Сальдо">
            <Credits amount={data.minted - data.burned} signed />
          </LabeledList.Item>
          <LabeledList.Item label="Стоки отделов">
            {ledger.department_sink ?? 0}% (цель {ledger.department_sink_min}-{ledger.department_sink_max}%): сожжено{' '}
            <Credits amount={ledger.department_burned ?? 0} /> из <Credits amount={ledger.department_kept ?? 0} />,
            оставшихся у отделов - эмиссия в бюджеты и пришедшее со счетов минус зарплаты и другие выплаты на счета.
            Личные деньги в эту долю не входят: они не переходят в следующую смену.
          </LabeledList.Item>
          <LabeledList.Item label="Состояние экономики">{STATE_NAMES[data.state] || data.state}</LabeledList.Item>
          <LabeledList.Item label="Налог">{data.tax_rate}%</LabeledList.Item>
        </LabeledList>
      </Section>
      <CalibrationSection data={data} />
      <Section title="Эмиссия против стоков">
        <SnapshotChart snapshots={data.snapshots} minutes={data.snapshot_minutes} />
      </Section>
      <Section title="Обороты по категориям">
        {ledger.by_category.length ? (
          <Table>
            {ledger.by_category.map((category) => (
              <Table.Row key={category.id}>
                <Table.Cell>
                  {category.name}
                  <Box color="label" fontSize="0.9em">
                    {category.reasons.map((reason) => `${reason.name}: ${formatCredits(reason.amount)}`).join('; ')}
                  </Box>
                </Table.Cell>
                <Table.Cell collapsing textAlign="right" nowrap>
                  <Credits amount={category.amount} />
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        ) : (
          <Box color="label">Движений денег пока не было.</Box>
        )}
        <Box color="label" mt={1}>
          Обороты - сумма всех движений по причине, без знака: переводы и покупки не меняют денег в секторе, их
          меняют только эмиссия и стоки.
        </Box>
      </Section>
    </>
  );
};

const AccountsTab = (props: { data: EconomyAdminData; send: Send }) => {
  const { data, send } = props;
  const [query, setQuery] = useState('');
  const [number, setNumber] = useState(0);
  const [amount, setAmount] = useState(0);
  const [reason, setReason] = useState('');
  const needle = query.trim().toLowerCase();
  const shown = data.accounts.filter(
    (account) => !needle || account.holder.toLowerCase().includes(needle) || String(account.number).includes(needle),
  );
  return (
    <>
      <Section title="Корректировка счёта">
        <Stack align="center">
          <Stack.Item>Счёт №</Stack.Item>
          <Stack.Item>
            <RestrictedInput width="7em" value={number} minValue={0} onChange={(_, value) => setNumber(value)} />
          </Stack.Item>
          <Stack.Item>Сумма</Stack.Item>
          <Stack.Item>
            <RestrictedInput
              width="8em"
              value={amount}
              minValue={-data.adjust_max}
              maxValue={data.adjust_max}
              onChange={(_, value) => setAmount(value)}
            />
          </Stack.Item>
          <Stack.Item>кр.</Stack.Item>
          <Stack.Item>
            <Button icon="check" disabled={!number || !amount} onClick={() => send('adjust', { number, amount })}>
              Провести
            </Button>
          </Stack.Item>
        </Stack>
        <Box color="label" mt={1}>
          Плюс - эмиссия NT, минус - сток, не больше {formatCredits(data.adjust_max)} за раз. Причина в журнале -
          &quot;Корректировка NT&quot;, она проходит и через заморозку; владелец видит её в истории без вашего комментария.
          Корректируются личные счета и бюджеты; бюджеты TAR и DS - счета внестанционных ролей, вне экономики
          станции.
        </Box>
      </Section>
      <Section title={`Счета (${data.accounts.length})`}>
        <Input fluid placeholder="Имя или номер" value={query} onInput={(_, value) => setQuery(value)} mb={1} />
        <Input
          fluid
          maxLength={data.freeze_reason_max}
          placeholder="Причина заморозки для владельца: уйдёт на его карту"
          value={reason}
          onInput={(_, value) => setReason(value)}
          mb={1}
        />
        <Table>
          <Table.Row header>
            <Table.Cell>№</Table.Cell>
            <Table.Cell>Владелец</Table.Cell>
            <Table.Cell>Отдел</Table.Cell>
            <Table.Cell textAlign="right">Баланс</Table.Cell>
            <Table.Cell>Статус</Table.Cell>
            <Table.Cell />
          </Table.Row>
          {shown.map((account) => (
            <Table.Row key={account.number}>
              <Table.Cell collapsing>{account.number}</Table.Cell>
              <Table.Cell>{account.holder}</Table.Cell>
              <Table.Cell collapsing color="label">
                {account.budget ? 'бюджет' : account.department || '-'}
              </Table.Cell>
              <Table.Cell collapsing textAlign="right" nowrap>
                <Credits amount={account.balance} />
              </Table.Cell>
              <Table.Cell color={account.state === ACCOUNT_FROZEN ? 'bad' : undefined}>
                {ACCOUNT_STATES[account.state] ?? account.state}
                {account.state === ACCOUNT_FROZEN && !!account.frozen_by && ` (${account.frozen_by}: ${account.freeze_reason})`}
              </Table.Cell>
              <Table.Cell collapsing nowrap>
                <Button onClick={() => setNumber(account.number)}>Выбрать</Button>
                {!account.budget &&
                  (account.state === ACCOUNT_FROZEN ? (
                    <Button icon="unlock" onClick={() => send('unfreeze', { number: account.number })}>
                      Разморозить
                    </Button>
                  ) : (
                    <Button
                      icon="lock"
                      color="bad"
                      disabled={!reason.trim()}
                      onClick={() => send('freeze', { number: account.number, reason })}>
                      Заморозить
                    </Button>
                  ))}
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
        <Box color="label" mt={1}>
          Заморозка закрывает переводы, покупки и снятие наличных, зарплата копится долгом отдела. Владелец получит
          на карту причину из поля выше от &quot;Центрального командования NT&quot;, комментарий остаётся в админ-логе.
          Заморозку ЦК аудиторы станции не снимают. Морозятся только личные счета.
        </Box>
      </Section>
    </>
  );
};

const DepartmentsTab = (props: { data: EconomyAdminData }) => (
  <Section title="Бюджеты отделов">
    <Table>
      <Table.Row header>
        <Table.Cell>Отдел</Table.Cell>
        <Table.Cell>№ счёта</Table.Cell>
        <Table.Cell textAlign="right">Бюджет</Table.Cell>
        <Table.Cell textAlign="right">Долг NT</Table.Cell>
        <Table.Cell textAlign="right">На смене</Table.Cell>
        <Table.Cell textAlign="right">Порог</Table.Cell>
        <Table.Cell textAlign="right">Возврат NT</Table.Cell>
        <Table.Cell textAlign="right">Закупок (в час)</Table.Cell>
        <Table.Cell textAlign="right">Вернули NT</Table.Cell>
      </Table.Row>
      {props.data.departments.map((department) => (
        <Table.Row key={department.id}>
          <Table.Cell>{department.name}</Table.Cell>
          <Table.Cell collapsing>{department.number ?? '-'}</Table.Cell>
          <Table.Cell textAlign="right" nowrap>
            <Credits amount={department.balance} />
          </Table.Cell>
          <Table.Cell textAlign="right" nowrap color={department.owed > 0 ? 'bad' : undefined}>
            <Credits amount={department.owed} />
          </Table.Cell>
          <Table.Cell textAlign="right">{department.staff}</Table.Cell>
          <Table.Cell textAlign="right" nowrap>
            <Credits amount={department.threshold ?? 0} />
          </Table.Cell>
          <Table.Cell textAlign="right" nowrap color={department.return_due ? 'average' : undefined}>
            <Credits amount={department.return_due ?? 0} />
          </Table.Cell>
          <Table.Cell textAlign="right" nowrap>
            {department.purchases ?? 0} ({department.purchases_per_hour ?? 0}) на <Credits amount={department.purchase_amount ?? 0} />
          </Table.Cell>
          <Table.Cell textAlign="right" nowrap>
            <Credits amount={department.returned ?? 0} />
          </Table.Cell>
        </Table.Row>
      ))}
    </Table>
    <Box color="label" mt={1}>
      Порог бюджета - оклады сотрудников на смене за несколько выплат, не ниже стартового бюджета; у казны - стартовая
      казна и по наибольшему запросу на каждый отдел. Каждый тик экономики NT забирает долю излишка сверх порога. Излишком
      не считаются долги и следующая зарплата сотрудникам, переводы из казны, события и доля контрактов на время
      защиты, а также цена пака - цели накопления главы.
    </Box>
  </Section>
);

const MarketTab = (props: { data: EconomyAdminData; send: Send }) => {
  const { data, send } = props;
  const [confirm, setConfirm] = useState('');
  return (
    <>
      <Section title={`Рынок сектора, индекс цен ${data.price_index}`}>
        <Stack wrap>
          <Stack.Item>
            <Button icon="random" onClick={() => send('market_event', { kind: 'shift' })}>
              Сдвиг рынка
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button icon="arrow-down" color="bad" onClick={() => send('market_event', { kind: 'crash' })}>
              Обвал
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button icon="arrow-up" color="good" onClick={() => send('market_event', { kind: 'boom' })}>
              Бум
            </Button>
          </Stack.Item>
        </Stack>
        <Box color="label" mt={1}>
          Сдвиг - внеочередной шаг цен товаров, как по таймеру. Обвал и бум - события станции из конфига: скачок цен
          всех акций и новость в сводке; каждое не чаще раза в {data.station_event_cooldown} мин., потолки биржи
          действуют как обычно.
        </Box>
        <Table mt={1}>
          <Table.Row header>
            <Table.Cell>Товар</Table.Cell>
            <Table.Cell textAlign="right">Закупка</Table.Cell>
            <Table.Cell textAlign="right">Продажа</Table.Cell>
            <Table.Cell textAlign="right">Спрос</Table.Cell>
            <Table.Cell>Лучший покупатель</Table.Cell>
            <Table.Cell />
          </Table.Row>
          {data.commodities.map((commodity) => (
            <Table.Row key={commodity.id}>
              <Table.Cell>
                {commodity.name}
                {commodity.hot > 0 && (
                  <Box inline color="average" ml={1}>
                    горячий x{commodity.hot}
                  </Box>
                )}
              </Table.Cell>
              <Table.Cell textAlign="right">x{commodity.factor}</Table.Cell>
              <Table.Cell textAlign="right">x{commodity.sell}</Table.Cell>
              <Table.Cell textAlign="right">{commodity.demand}%</Table.Cell>
              <Table.Cell color="label">{commodity.buyer || '-'}</Table.Cell>
              <Table.Cell collapsing>
                <Sparkline values={commodity.history} />
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      </Section>
      <Section title="Сброс сектора">
        <Box mb={1}>
          Возвращает товары, акции и партнёров к базе и удаляет файл состояния сектора. В конце раунда файл запишется
          заново: следующая смена унаследует рынок, каким он станет после сброса, с обычным затуханием{' '}
          {data.persist_decay}%. Позиции держателей акций сохраняют стоимость. Отменить нельзя.
        </Box>
        <Stack align="center">
          <Stack.Item>Введите &quot;{data.reset_phrase}&quot;:</Stack.Item>
          <Stack.Item>
            <Input value={confirm} onInput={(_, value) => setConfirm(value)} />
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="trash"
              color="bad"
              disabled={confirm.trim() !== data.reset_phrase}
              onClick={() => send('reset_sector', { confirm })}>
              Сбросить сектор
            </Button>
          </Stack.Item>
        </Stack>
      </Section>
    </>
  );
};

const PartnersTab = (props: { data: EconomyAdminData }) => (
  <Section title="Торговые партнёры">
    <Table>
      <Table.Row header>
        <Table.Cell>Партнёр</Table.Cell>
        <Table.Cell>Статус</Table.Cell>
        <Table.Cell textAlign="right">Репутация</Table.Cell>
        <Table.Cell textAlign="right">Скидка</Table.Cell>
        <Table.Cell textAlign="right">Наценка</Table.Cell>
        <Table.Cell textAlign="right">Капитал</Table.Cell>
      </Table.Row>
      {props.data.partners.map((partner) => (
        <Table.Row key={partner.id}>
          <Table.Cell>
            {partner.name}
            <Box color="label" fontSize="0.9em">
              Покупает: {partner.buys || '-'}. Продаёт: {partner.sells || '-'}.
            </Box>
          </Table.Cell>
          <Table.Cell color={partner.unlocked ? 'good' : 'label'}>
            {partner.unlocked ? `открыт, ступень ${partner.tier}` : partner.next_unlock || 'закрыт'}
          </Table.Cell>
          <Table.Cell textAlign="right">{partner.reputation}</Table.Cell>
          <Table.Cell textAlign="right">{partner.discount}%</Table.Cell>
          <Table.Cell textAlign="right">x{partner.markup}</Table.Cell>
          <Table.Cell textAlign="right" nowrap>
            <Credits amount={partner.wealth} />
          </Table.Cell>
        </Table.Row>
      ))}
    </Table>
  </Section>
);

const ExchangeTab = (props: { data: EconomyAdminData; send: Send }) => {
  const { data, send } = props;
  const [ticker, setTicker] = useState(data.companies[0]?.ticker || '');
  const [effect, setEffect] = useState(0);
  const [headline, setHeadline] = useState('');
  return (
    <>
      <Section title="Событие компании">
        <Stack align="center" wrap>
          <Stack.Item>
            <Dropdown
              width="8em"
              selected={ticker}
              options={data.companies.map((company) => company.ticker)}
              onSelected={(value) => setTicker(value)}
            />
          </Stack.Item>
          <Stack.Item>Шок</Stack.Item>
          <Stack.Item>
            <RestrictedInput
              width="5em"
              value={effect}
              minValue={data.effect_min}
              maxValue={data.effect_max}
              onChange={(_, value) => setEffect(value)}
            />
          </Stack.Item>
          <Stack.Item>%</Stack.Item>
          <Stack.Item grow>
            <Input
              fluid
              maxLength={data.headline_max}
              placeholder="Заголовок новости"
              value={headline}
              onInput={(_, value) => setHeadline(value)}
            />
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="newspaper"
              disabled={!ticker || !effect || !headline.trim()}
              onClick={() => send('market_event', { kind: 'company_event', ticker, effect, headline })}>
              Поставить событие
            </Button>
          </Stack.Item>
        </Stack>
        <Box color="label" mt={1}>
          Шок от {data.effect_min}% до +{data.effect_max}%. Событие выходит на ближайшем тике биржи, до минуты, с
          заголовком в сводке сектора и проверкой инсайда, как обычное. Множитель событий компании не выше x
          {data.event_mult_max}, цена не выше {data.price_max_ratio} базовых.
        </Box>
      </Section>
      <Section title="Компании">
        <Table>
          <Table.Row header>
            <Table.Cell>Тикер</Table.Cell>
            <Table.Cell>Компания</Table.Cell>
            <Table.Cell textAlign="right">Цена</Table.Cell>
            <Table.Cell textAlign="right">База</Table.Cell>
            <Table.Cell textAlign="right">Изменение</Table.Cell>
            <Table.Cell textAlign="right">Множитель событий</Table.Cell>
            <Table.Cell textAlign="right">В очереди</Table.Cell>
            <Table.Cell />
          </Table.Row>
          {data.companies.map((company) => (
            <Table.Row key={company.ticker}>
              <Table.Cell collapsing bold>
                {company.ticker}
              </Table.Cell>
              <Table.Cell>
                {company.name}
                {!!company.halted && (
                  <Box inline color="bad" ml={1}>
                    торги остановлены
                  </Box>
                )}
              </Table.Cell>
              <Table.Cell textAlign="right" nowrap>
                {formatCredits(company.price, { decimals: 2 })}
              </Table.Cell>
              <Table.Cell textAlign="right" nowrap color="label">
                {formatCredits(company.base_price)}
              </Table.Cell>
              <Table.Cell textAlign="right">
                <ChangeBadge percent={company.change} />
              </Table.Cell>
              <Table.Cell textAlign="right">x{company.event_mult}</Table.Cell>
              <Table.Cell textAlign="right">{company.queued}</Table.Cell>
              <Table.Cell collapsing>
                <Sparkline values={company.history} />
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      </Section>
    </>
  );
};

const AuditTab = (props: { data: EconomyAdminData }) => {
  const flags = props.data.flags;
  const open = flags.filter((flag) => !flag.closed).length;
  return (
    <Section title={`Дела финансового аудита: открыто ${open} из ${flags.length}`}>
      {flags.length ? (
        <Table>
          <Table.Row header>
            <Table.Cell>№</Table.Cell>
            <Table.Cell>Время</Table.Cell>
            <Table.Cell>Что</Table.Cell>
            <Table.Cell>Счета</Table.Cell>
            <Table.Cell textAlign="right">Сумма</Table.Cell>
            <Table.Cell>Статус</Table.Cell>
          </Table.Row>
          {[...flags].reverse().map((flag) => (
            <Table.Row key={flag.uid}>
              <Table.Cell collapsing>{flag.uid}</Table.Cell>
              <Table.Cell collapsing>{flag.time}</Table.Cell>
              <Table.Cell>{flag.text}</Table.Cell>
              <Table.Cell collapsing nowrap>
                №{flag.account}
                {flag.counterparty ? ` -> №${flag.counterparty}` : ''}
              </Table.Cell>
              <Table.Cell textAlign="right" nowrap>
                <Credits amount={flag.amount} />
              </Table.Cell>
              <Table.Cell color={flag.closed ? 'label' : 'average'}>
                {flag.closed
                  ? `закрыто${flag.closed_by ? ` (${flag.closed_by})` : ''}${flag.refunded ? `, возвращено ${formatCredits(flag.refunded)}` : ''}`
                  : 'открыто'}
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      ) : (
        <Box color="label">Дел аудита в этом раунде нет.</Box>
      )}
      <Box color="label" mt={1}>
        Дела ведут аудиторы станции в &quot;Финансовом аудите&quot;; отсюда счёт можно заморозить на вкладке &quot;Счета&quot;.
      </Box>
    </Section>
  );
};

const ConfigTab = (props: { data: EconomyAdminData; send: Send }) => {
  const { data, send } = props;
  const [rate, setRate] = useState(data.tax_rate);
  return (
    <>
      <Section title="Налог">
        <Stack align="center">
          <Stack.Item>
            <RestrictedInput width="5em" value={rate} minValue={0} maxValue={data.tax_max} onChange={(_, value) => setRate(value)} />
          </Stack.Item>
          <Stack.Item>%</Stack.Item>
          <Stack.Item>
            <Button onClick={() => send('set_tax', { rate })}>Установить налог</Button>
          </Stack.Item>
        </Stack>
        <Box color="label" mt={1}>
          Сейчас {data.tax_rate}%, не выше {data.tax_max}% из economy.json. Налог берётся с зарплат, оплаты работы и
          контрактов и идёт в казну.
        </Box>
      </Section>
      <Section
        title="economy.json"
        buttons={
          <Button icon="redo" onClick={() => send('reload_config')}>
            Перечитать economy.json
          </Button>
        }>
        <Box color="label" mb={1}>
          Перечитка применяет настройки экономики и рынка без перезапуска. Файл с ошибками в настройках не применяется
          целиком; ошибочные значения рынка остаются встроенными. Состояние рынка, акций и репутация партнёров
          сохраняются.
          {data.config_reloaded_at ? ` Последняя перечитка: ${data.config_reloaded_at}.` : ' В этом раунде не перечитывался.'}
        </Box>
        {data.config_errors.length > 0 ? (
          <NoticeBox danger>
            {data.config_errors.map((error) => (
              <Box key={error}>{error}</Box>
            ))}
          </NoticeBox>
        ) : (
          !!data.config_reloaded_at && <NoticeBox success>Ошибок нет.</NoticeBox>
        )}
      </Section>
    </>
  );
};

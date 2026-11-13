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
import { NtosWindow } from '../layouts';
import { ContractTable, freeCrewRequests } from './common/ContractTable';
import { ContractEntry, Credits, formatCredits, HistoryTable, TransactionEntry } from './common/Economy';
import { NtHelpTopic, NtHelpTopics } from './common/NtTerminal';

type Wage = {
  grade: string | null;
  department: string | null;
  base: number;
  bonus: number;
  amount: number;
  floor_only?: BooleanLike;
  tax_rate: number;
  owed: number;
};

type Lottery = {
  price: number;
  house_share: number;
  per_account: number;
  sold: number;
  prize: number;
  minutes_left: number;
  mine: number;
};

type ShareEntry = {
  ticker: string;
  name: string;
  count: number;
  value: number;
};

type PersonalPack = {
  id: string;
  name: string;
  desc?: string;
  contents: string[];
  /** Сколько случайных предметов из описи кладёт пак; 0 - всё. */
  random?: number;
};

type PersonalSection = {
  name: string;
  packs: PersonalPack[];
};

type PersonalOrder = {
  id: number;
  name: string;
  price: number;
  /** Подарок: кому едет посылка. */
  gift_to?: string | null;
};

type ShuttleState = 'station' | 'centcom' | 'to_station' | 'to_centcom' | 'recharging' | 'loaned' | 'away';

type AuctionLot = {
  uid: number;
  name: string;
  desc?: string | null;
  /** Оценка лота сектора; у лота экипажа 0. */
  value?: number;
  bid: number;
  bidder: string | null;
  /** Ведёт ставка этого счёта. */
  mine: BooleanLike;
  /** Этот счёт ставил, но его перебили. */
  outbid?: BooleanLike;
  min_bid: number;
  increment: number;
  left: number;
  rivals?: number;
  history: { who: string; amount: number }[];
  /** Лот экипажа: имя продавца или "аноним". */
  seller?: string | null;
  my_lot?: BooleanLike;
  /** Лот экипажа можно купить сразу за столько; 0 - только торги. */
  buyout?: number;
  /** Что продавец написал на вещи ручкой или этикеткой. */
  inscription?: string | null;
};

export type WalletData = {
  message: string;
  metadollars_available: BooleanLike;
  metadollars: number;
  transfer_max: number;
  transfer_cooldown: number;
  memo_max: number;
  name_max: number;
  audit_rights: string;
  owed_cap: number;
  wage_floor: number;
  tax_nt_share?: number;
  wage_interval: number;
  dormant_minutes: number;
  performer_share: number;
  contracts_help_topics?: NtHelpTopic[];
  crew: string[];
  has_account: BooleanLike;
  lottery?: Lottery | null;
  from_card?: BooleanLike;
  holder?: string;
  number?: number;
  balance?: number;
  state?: 'active' | 'frozen' | 'dormant';
  blocked?: BooleanLike;
  anonymous?: BooleanLike;
  personal?: BooleanLike;
  frozen_by?: string | null;
  freeze_reason?: string | null;
  freeze_source?: string | null;
  cooldown_left?: number;
  wage?: Wage;
  history?: TransactionEntry[];
  contracts?: ContractEntry[];
  my_account?: number;
  shares?: ShareEntry[];
  portfolio?: number;
  personal_catalog?: PersonalSection[];
  personal_order_limit?: number;
  /** "тип пака" -> [цена для этого счёта, есть ли у партнёров]. */
  personal_prices?: Record<string, [number, BooleanLike]>;
  personal_orders?: PersonalOrder[];
  personal_in_transit?: string[];
  shuttle?: { state: ShuttleState; eta: number };
  auction?: AuctionLot | null;
  crew_lots?: AuctionLot[];
  /** Секунд до следующего лота сектора, 0 - лот идёт. */
  auction_next?: number;
  auction_fee?: number;
  auction_lots_per_account?: number;
};

type Tab = 'account' | 'transfer' | 'orders' | 'jobs' | 'shares' | 'meta';

const TABS: [Tab, string, string][] = [
  ['account', 'Счёт', 'wallet'],
  ['transfer', 'Перевод', 'paper-plane'],
  ['orders', 'Заказы', 'box-open'],
  ['jobs', 'Подработка', 'briefcase'],
  ['shares', 'Акции', 'chart-line'],
  ['meta', 'Метадоллары', 'coins'],
];

export const NtosWallet = () => (
  <NtosWindow width={640} height={640}>
    <NtosWindow.Content scrollable>
      <NtosWalletContent />
    </NtosWindow.Content>
  </NtosWindow>
);

export const NtosWalletContent = () => {
  const { data } = useBackend<WalletData>();
  const [tab, setTab] = useState<Tab>('account');
  const needsAccount = tab !== 'meta' && !data.has_account;
  const crewOpen = freeCrewRequests(data.contracts || [], data.my_account);
  return (
    <>
      <Tabs>
        {TABS.map(([id, label, icon]) => (
          <Tabs.Tab key={id} icon={icon} selected={tab === id} onClick={() => setTab(id)}>
            {id === 'jobs' && crewOpen > 0 ? `${label} (${crewOpen})` : label}
          </Tabs.Tab>
        ))}
      </Tabs>
      {!!data.message && <NoticeBox info>{data.message}</NoticeBox>}
      {needsAccount ? (
        <NoticeBox>Счёт не найден: вставьте в КПК ID-карту со счётом.</NoticeBox>
      ) : (
        <>
          {tab === 'account' && <AccountTab />}
          {tab === 'transfer' && <TransferTab />}
          {tab === 'orders' && <OrdersTab />}
          {tab === 'jobs' && <JobsTab />}
          {tab === 'shares' && <SharesTab />}
          {tab === 'meta' && <MetaTab />}
        </>
      )}
    </>
  );
};

const AccountNotices = () => {
  const { data } = useBackend<WalletData>();
  return (
    <>
      {data.state === 'frozen' && (
        <NoticeBox danger>
          Счёт заморожен {data.freeze_source || 'финансовым аудитом'}
          {data.freeze_reason ? `: ${data.freeze_reason}` : ''}. Переводы, чаевые, покупки, снятие наличных и сделки
          с акциями закрыты. Поступления принимаются, налоги, долги и возвраты по делам аудита списываются. Зарплата не
          выплачивается, а копится долгом отдела (до {data.owed_cap} базовых окладов) и придёт с первой зарплатой
          после разморозки.
        </NoticeBox>
      )}
      {!!data.blocked && (
        <NoticeBox danger>Счёт заблокирован в базе счетов: личные платежи с него и на него не проходят.</NoticeBox>
      )}
      {data.state === 'dormant' && (
        <NoticeBox warning>
          Счёт спит: владелец дольше {data.dormant_minutes} мин. мёртв или не на смене. Зарплата не начисляется и в долг не
          копится, по имени счёт не находится - переводы на него только по номеру. Неотгруженные личные заказы на это
          имя сняты с корзины, деньги вернулись тем, кто платил.
        </NoticeBox>
      )}
      {!!data.anonymous && (
        <NoticeBox>
          Анонимный счёт: без зарплаты и контрактов. Аудит видит движения по нему и след денег, каждое снятие наличных
          открывает дело с местом снятия.
        </NoticeBox>
      )}
      {!data.anonymous && !data.personal && (
        <NoticeBox warning>Это не личный счёт: переводы и чаевые с него и на него не проходят.</NoticeBox>
      )}
    </>
  );
};

const WageSection = () => {
  const { data } = useBackend<WalletData>();
  const wage = data.wage;
  if (!wage) {
    return null;
  }
  return (
    <Section title="Зарплата">
      <LabeledList>
        {wage.floor_only ? (
          <LabeledList.Item label="Выплата">
            {wage.grade ? `Грейд ${wage.grade}, но отдел не назначен` : 'Оклада нет'}: отдел не платит, NT платит
            минимум <Credits amount={data.wage_floor} /> раз в {data.wage_interval} мин.
          </LabeledList.Item>
        ) : wage.grade ? (
          <>
            <LabeledList.Item label="Грейд">
              {wage.grade}
              {wage.department ? `, отдел: ${wage.department}` : ''}
            </LabeledList.Item>
            <LabeledList.Item label="Выплата">
              <Credits amount={wage.base} /> + надбавка {wage.bonus}% = <Credits amount={wage.amount} /> раз в{' '}
              {data.wage_interval} мин.
            </LabeledList.Item>
          </>
        ) : (
          <LabeledList.Item label="Выплата">Не начисляется: у должности нет оклада.</LabeledList.Item>
        )}
        <LabeledList.Item label="Налог">
          Налог {wage.tax_rate}% удерживается с зарплаты, премий (от главы и за работу) и доли контрактов,{' '}
          {data.tax_nt_share ?? 0}% налога забирает NT, остальное получает казна. Без налога: доплата NT до минимума,
          переводы и чаевые. Казна - общий счёт станции: из неё капитан и ГП пополняют бюджеты отделов, из которых и
          платятся зарплаты, и закрывают расходы станции на чрезвычайные события.
        </LabeledList.Item>
        {wage.owed > 0 && (
          <LabeledList.Item label="Отдел должен" color="average">
            <Credits amount={wage.owed} />
          </LabeledList.Item>
        )}
      </LabeledList>
      <Box color="label" mt={1}>
        Зарплату платит бюджет отдела. Если денег в нём не хватает, недоплата копится долгом отдела (до {data.owed_cap}{' '}
        базовых окладов) и выплачивается со следующей зарплатой. Если отдел заплатил меньше{' '}
        <Credits amount={data.wage_floor} />, NT доплачивает до этой суммы без налога.
      </Box>
    </Section>
  );
};

const LotterySection = () => {
  const { act, data } = useBackend<WalletData>();
  const { lottery } = data;
  if (!lottery) {
    return null;
  }
  const left = lottery.per_account - lottery.mine;
  return (
    <Section title="Лотерея сектора">
      <LabeledList>
        <LabeledList.Item label="Билет">
          <Credits amount={lottery.price} />, ваших {lottery.mine} из {lottery.per_account}
        </LabeledList.Item>
        <LabeledList.Item label="Продано">{lottery.sold}</LabeledList.Item>
        <LabeledList.Item label="Выигрыш сейчас">
          <Credits amount={lottery.prize} />
        </LabeledList.Item>
        <LabeledList.Item label="Розыгрыш">через {lottery.minutes_left} мин.</LabeledList.Item>
      </LabeledList>
      <Box color="label" my={1}>
        Один билет выигрывает {100 - lottery.house_share}% всех продаж, {lottery.house_share}% забирает NT. Шанс
        растёт с числом ваших билетов.
      </Box>
      <Button icon="ticket-alt" disabled={left < 1} onClick={() => act('lottery_buy', { count: 1 })}>
        Купить билет
      </Button>
      <Button icon="ticket-alt" disabled={left < 5} onClick={() => act('lottery_buy', { count: 5 })}>
        Купить 5
      </Button>
    </Section>
  );
};

const AccountTab = () => {
  const { data } = useBackend<WalletData>();
  return (
    <>
      <AccountNotices />
      <Section title={`${data.holder}, счёт №${data.number}`}>
        <LabeledList>
          <LabeledList.Item label="Баланс">
            <Box bold fontSize={1.4}>
              <Credits amount={data.balance} />
            </Box>
          </LabeledList.Item>
          <LabeledList.Item label="Источник">
            {data.from_card ? 'ID-карта в КПК' : 'Ваш личный счёт (карта в КПК не вставлена)'}
          </LabeledList.Item>
        </LabeledList>
      </Section>
      <LotterySection />
      <WageSection />
      <Section title="История">
        <HistoryTable entries={data.history || []} />
      </Section>
      <Box color="label">
        Финансовый аудит ({data.audit_rights}) видит движения по счёту и след денег. Дело открывают: серия частых
        переводов одному человеку, списания с неопознанных устройств, крупные выплаты из бюджета отдела одному
        человеку, премия главы самому себе, снятие наличных с анонимного счёта, сделки с акциями перед новостью о
        компании. Зарплата, налоги, чаевые, оплата работы и контрактов, единичные переводы дел не открывают.
      </Box>
    </>
  );
};

const TransferTab = () => {
  const { act, data } = useBackend<WalletData>();
  const [target, setTarget] = useState('');
  const [amount, setAmount] = useState(10);
  const [memo, setMemo] = useState('');
  const cooldown = data.cooldown_left || 0;
  const ready = target.trim().length > 0 && amount >= 1;
  return (
    <>
      <AccountNotices />
      <Section title="Перевод и чаевые">
        <Box color="label" mb={1}>
          Только с личного счёта на личный: бюджеты отделов и системные счета не принимают. Без налога, до{' '}
          <Credits amount={data.transfer_max} /> за раз, не чаще раза в {data.transfer_cooldown} с - переводы и чаевые
          делят этот кулдаун. По имени - только если владелец с таким именем один, иначе укажите номер счёта.
        </Box>
        <LabeledList>
          <LabeledList.Item label="Кому">
            <Stack>
              <Stack.Item grow>
                <Input
                  fluid
                  value={target}
                  maxLength={data.name_max}
                  placeholder="Имя или номер счёта"
                  onInput={(_, value) => setTarget(value)}
                />
              </Stack.Item>
              {data.crew.length > 0 && (
                <Stack.Item>
                  <Dropdown
                    width="12em"
                    options={data.crew}
                    selected={null}
                    displayText="Из манифеста"
                    onSelected={(value) => setTarget(value)}
                  />
                </Stack.Item>
              )}
            </Stack>
          </LabeledList.Item>
          <LabeledList.Item label="Сумма">
            <RestrictedInput
              value={amount}
              minValue={1}
              maxValue={data.transfer_max}
              onChange={(_, value) => setAmount(value)}
            />{' '}
            кр.
          </LabeledList.Item>
          <LabeledList.Item label="Назначение">
            <Input
              fluid
              value={memo}
              maxLength={data.memo_max}
              placeholder="Необязательно, только для перевода"
              onInput={(_, value) => setMemo(value)}
            />
          </LabeledList.Item>
        </LabeledList>
        {cooldown > 0 && (
          <Box color="average" mt={1}>
            Следующий платёж через {cooldown} с.
          </Box>
        )}
        <Stack mt={1}>
          <Stack.Item>
            <Button
              icon="paper-plane"
              disabled={!ready}
              onClick={() => act('transfer', { target: target.trim(), amount, memo })}>
              Перевести
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="hand-holding-usd"
              disabled={!ready}
              onClick={() => act('tip', { target: target.trim(), amount })}>
              Чаевые
            </Button>
          </Stack.Item>
        </Stack>
      </Section>
    </>
  );
};

const SHUTTLE_NOTES: Record<ShuttleState, string> = {
  centcom: 'Шаттл снабжения у ЦК: заказ погрузят, когда снабжение вызовет его на станцию.',
  to_station: 'Шаттл снабжения уже летит на станцию: новый заказ полетит следующим рейсом.',
  station: 'Шаттл снабжения на станции: заказ полетит, когда снабжение слетает к ЦК и обратно.',
  to_centcom: 'Шаттл снабжения летит к ЦК: заказ погрузят, когда его вызовут обратно.',
  recharging: 'Шаттл снабжения готовится к рейсу.',
  loaned: 'Шаттл снабжения одолжен ЦК: заказ подождёт его возвращения.',
  away: 'Шаттл снабжения сейчас недоступен: заказ подождёт.',
};

const shuttleEta = (state: ShuttleState, eta: number) => {
  const minutes = Math.ceil(eta / 60);
  if (eta <= 0) {
    return '';
  }
  switch (state) {
    case 'to_station':
      return ` До посадки на станции: ${minutes} мин.`;
    case 'to_centcom':
      return ` До ЦК: ${minutes} мин.`;
    case 'recharging':
      return ` Будет готов через ${minutes} мин.`;
    default:
      return '';
  }
};

const MyOrders = () => {
  const { act, data } = useBackend<WalletData>();
  const orders = data.personal_orders || [];
  const inTransit = data.personal_in_transit || [];
  if (!orders.length && !inTransit.length) {
    return null;
  }
  return (
    <Section title="Мои заказы">
      {orders.length > 0 && (
        <Table>
          {orders.map((order) => (
            <Table.Row key={order.id} className="candystripe">
              <Table.Cell py={0.5}>
                №{order.id} {order.name}
                {!!order.gift_to && (
                  <Box as="span" color="label">
                    {' '}
                    - подарок для {order.gift_to}
                  </Box>
                )}
              </Table.Cell>
              <Table.Cell collapsing py={0.5} textAlign="right">
                <Credits amount={order.price} />
              </Table.Cell>
              <Table.Cell collapsing py={0.5}>
                <Button.Confirm
                  icon="times"
                  content="Отменить"
                  confirmContent="Отменить и вернуть деньги?"
                  tooltip={
                    order.gift_to
                      ? 'Подарок ещё ждёт шаттла: деньги вернутся вам, получатель узнает, что он не приедет.'
                      : 'Заказ ещё ждёт шаттла: деньги вернутся на счёт.'
                  }
                  onClick={() => act('personal_cancel', { id: order.id })}
                />
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      )}
      {inTransit.length > 0 && (
        <Box color="good" mt={orders.length ? 1 : 0}>
          Уже летит на станцию: {inTransit.join(', ')}. Посылку на ваше имя заберёте в отделе снабжения.
        </Box>
      )}
    </Section>
  );
};

const formatLeft = (seconds: number) => `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`;

const lotStatus = (lot: AuctionLot) => {
  if (!lot.bid) {
    return `ставок нет, старт ${formatCredits(lot.min_bid)}`;
  }
  return `ставка ${formatCredits(lot.bid)} - ${lot.mine ? 'ваша' : lot.bidder}`;
};

const AuctionRow = (props: { lot: AuctionLot }) => {
  const { act, data } = useBackend<WalletData>();
  const { lot } = props;
  const [open, setOpen] = useState(false);
  const [amount, setAmount] = useState<number | null>(null);
  const bid = Math.max(amount ?? lot.min_bid, lot.min_bid);
  const crew = lot.seller !== undefined;
  const buyout = crew && !lot.my_lot ? lot.buyout || 0 : 0;
  const biddable = !lot.my_lot && (!buyout || lot.min_bid < buyout);
  const needed = (minimum: number) => minimum - (lot.mine ? lot.bid : 0);
  const shortOf = (minimum: number) => (data.balance || 0) < needed(minimum);
  return (
    <Table.Row className="candystripe">
      <Table.Cell py={0.5}>
        <Box as="span" style={{ cursor: 'pointer' }} onClick={() => setOpen(!open)}>
          <Box as="span" color="label" mr={0.5}>
            {open ? '▾' : '▸'}
          </Box>
          {lot.name}
        </Box>
        <Box as="span" color="label" ml={1}>
          {!crew ? 'аукцион сектора' : lot.my_lot ? 'ваш лот' : `продаёт ${lot.seller}`}
        </Box>
        <Box color={lot.outbid ? 'average' : lot.mine ? 'good' : 'label'}>
          {lotStatus(lot)}
          {lot.outbid ? '; вашу ставку перебили' : ''}
        </Box>
        {open && (
          <Box color="label" mt={0.5}>
            {!!lot.desc && <Box>{lot.desc}</Box>}
            {!!lot.inscription && <Box mt={0.5}>На вещи надпись: {lot.inscription}</Box>}
            {!!lot.buyout && <Box mt={0.5}>Купить сразу, без торгов: {formatCredits(lot.buyout)}.</Box>}
            {!crew && (
              <Box mt={0.5}>
                Оценка лота <Credits amount={lot.value} />, торгуются ещё {lot.rivals} станции сектора.
              </Box>
            )}
            {lot.history.length > 0 && (
              <Box mt={0.5}>
                Ставки: {lot.history.map((entry) => `${entry.who} ${formatCredits(entry.amount)}`).join(', ')}.
              </Box>
            )}
            {biddable && (
              <Stack align="center" mt={0.5}>
                <Stack.Item>
                  <RestrictedInput
                    width="7em"
                    value={bid}
                    minValue={lot.min_bid}
                    maxValue={buyout ? buyout - 1 : 100000}
                    onChange={(_, value) => setAmount(value)}
                  />{' '}
                  кр.
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="gavel"
                    disabled={shortOf(bid)}
                    onClick={() => act('auction_bid', { uid: lot.uid, amount: bid })}>
                    {`Поставить ${formatCredits(bid)}`}
                  </Button>
                </Stack.Item>
              </Stack>
            )}
          </Box>
        )}
      </Table.Cell>
      <Table.Cell collapsing py={0.5} textAlign="right" color={lot.left < 60 ? 'average' : 'label'}>
        {formatLeft(lot.left)}
      </Table.Cell>
      <Table.Cell collapsing py={0.5}>
        {lot.my_lot ? (
          !lot.bid && (
            <Button.Confirm
              icon="times"
              content="Снять"
              confirmContent="Снять лот?"
              tooltip="Ставок ещё нет: вещь вернётся к вам посылкой."
              onClick={() => act('auction_cancel', { uid: lot.uid })}
            />
          )
        ) : (
          <>
            {biddable && (
              <Button.Confirm
                icon="gavel"
                color="good"
                content={`${lot.mine ? 'Поднять до' : 'Ставка'} ${formatCredits(lot.min_bid)}`}
                confirmContent={`Поставить ${formatCredits(lot.min_bid)}?`}
                confirmColor="good"
                disabled={shortOf(lot.min_bid)}
                tooltip={shortOf(lot.min_bid) ? 'Не хватает денег на счёте.' : null}
                onClick={() => act('auction_bid', { uid: lot.uid, amount: lot.min_bid })}
              />
            )}
            {!!buyout && (
              <Button.Confirm
                icon="shopping-cart"
                content={`Купить за ${formatCredits(buyout)}`}
                confirmContent={`Купить сразу за ${formatCredits(buyout)}?`}
                confirmColor="good"
                disabled={shortOf(buyout)}
                tooltip={shortOf(buyout) ? 'Не хватает денег на счёте.' : 'Торги закончатся сразу, лот ваш.'}
                onClick={() => act('auction_buyout', { uid: lot.uid })}
              />
            )}
          </>
        )}
      </Table.Cell>
    </Table.Row>
  );
};

const AuctionSection = () => {
  const { data } = useBackend<WalletData>();
  const lots = [...(data.auction ? [data.auction] : []), ...(data.crew_lots || [])];
  return (
    <Section title="Аукцион">
      <Box color="label" mb={1}>
        Ставка списывается сразу и ждёт конца торгов. Перебьют - деньги сразу вернутся, а незадолго до конца карта
        напомнит о лоте; ставка в последнюю минуту продлевает торги. Лоты экипажа бывают с ценой «купить сразу» -
        тогда торги кончаются на месте. Выигрыш приходит запертой посылкой на ваше имя: лот сектора прилетит капсулой на
        склад снабжения, лот экипажа встанет на пад подработки, с которого его выставили. Свою вещь можно выставить с пада
        подработки: старт, срок и цену «купить сразу» выбираете сами, имя можно скрыть, NT берёт {data.auction_fee ?? 0}% с
        продажи; лотов сразу - до {data.auction_lots_per_account ?? 0} на человека.
      </Box>
      {lots.length > 0 ? (
        <Table>
          {lots.map((lot) => (
            <AuctionRow key={lot.uid} lot={lot} />
          ))}
        </Table>
      ) : (
        <Box color="label">
          Лотов сейчас нет.
          {data.auction_next ? ` Следующий лот сектора - примерно через ${Math.ceil(data.auction_next / 60)} мин.` : ''}
        </Box>
      )}
    </Section>
  );
};

type CatalogRowProps = {
  pack: PersonalPack;
  full: boolean;
  /** Получатель подарка, '' - себе. */
  recipient: string;
  signed: boolean;
};

const CatalogRow = (props: CatalogRowProps) => {
  const { act, data } = useBackend<WalletData>();
  const { pack, full, recipient, signed } = props;
  const gift = recipient !== '';
  const [open, setOpen] = useState(false);
  const [price, inStock] = data.personal_prices?.[pack.id] || [0, 0];
  const balance = data.balance || 0;
  let refusal: string | null = null;
  if (!inStock) {
    refusal = 'Сейчас нет у партнёров, загляните позже.';
  } else if (full) {
    refusal = `Больше заказов сразу не принять, шаттла ждут уже ${data.personal_order_limit}: дождитесь отгрузки или отмените один.`;
  } else if (balance < price) {
    refusal = 'Не хватает денег на счёте.';
  }
  return (
    <Table.Row className="candystripe">
      <Table.Cell py={0.5}>
        <Box as="span" style={{ cursor: 'pointer' }} onClick={() => setOpen(!open)}>
          <Box as="span" color="label" mr={0.5}>
            {open ? '▾' : '▸'}
          </Box>
          {pack.name}
        </Box>
        {open && (
          <Box color="label" mt={0.5}>
            {!!pack.desc && <Box>{pack.desc}</Box>}
            {pack.contents.length > 0 && (
              <Box mt={0.5}>
                {pack.random ? `Случайные ${pack.random} шт. из набора: ` : 'Внутри: '}
                {pack.contents.join(', ')}.
              </Box>
            )}
          </Box>
        )}
      </Table.Cell>
      <Table.Cell collapsing py={0.5} textAlign="right" color={inStock ? undefined : 'label'}>
        <Credits amount={price} />
      </Table.Cell>
      <Table.Cell collapsing py={0.5}>
        <Button.Confirm
          icon={gift ? 'gift' : 'shopping-cart'}
          color="good"
          content={gift ? 'Подарить' : 'Заказать'}
          confirmContent={gift ? `Подарить за ${formatCredits(price)}?` : `Оплатить ${formatCredits(price)}?`}
          confirmColor="good"
          disabled={!!refusal}
          tooltip={refusal}
          onClick={() =>
            act(
              'personal_order',
              gift ? { id: pack.id, price, recipient, hide_name: !signed } : { id: pack.id, price },
            )
          }
        />
      </Table.Cell>
    </Table.Row>
  );
};

const OrdersTab = () => {
  const { data } = useBackend<WalletData>();
  const sections = data.personal_catalog || [];
  const [shown, setShown] = useState<string | null>(null);
  const [recipient, setRecipient] = useState('');
  const [signed, setSigned] = useState(true);
  const full = (data.personal_orders || []).length >= (data.personal_order_limit || 0);
  const shuttle = data.shuttle;
  const visible = sections.filter((section) => !shown || section.name === shown);
  const crew = (data.crew || []).filter((name) => name !== data.holder);
  return (
    <>
      <AccountNotices />
      <AuctionSection />
      <MyOrders />
      <Section title="Личный каталог">
        <Box color="label" mb={1}>
          Питомцы, наряды, угощение для праздника, музыка и уют за свой счёт - себе или в подарок. Цена партнёра без
          наценки частного заказа списывается сразу. Заказ привезёт ближайший шаттл снабжения: запертая посылка на имя
          получателя будет ждать в отделе снабжения, открыть её можно его ID-картой. Пока шаттл не вылетел, заказ можно
          отменить - деньги вернутся вам; если получатель уйдёт со смены раньше, заказ снимется сам. Ждать шаттла могут
          до {data.personal_order_limit} ваших заказов сразу.
        </Box>
        {!!shuttle && (
          <Box mb={1}>
            {SHUTTLE_NOTES[shuttle.state]}
            {shuttleEta(shuttle.state, shuttle.eta)}
          </Box>
        )}
        <LabeledList>
          <LabeledList.Item label="Кому">
            <Stack align="center">
              <Stack.Item>
                <Dropdown
                  width="16em"
                  options={[{ value: '', displayText: 'Себе' }, ...crew]}
                  selected={recipient}
                  onSelected={(value: string) => setRecipient(value)}
                />
              </Stack.Item>
              {!!recipient && (
                <Stack.Item>
                  <Button.Checkbox checked={signed} onClick={() => setSigned(!signed)}>
                    Подписать моим именем
                  </Button.Checkbox>
                </Stack.Item>
              )}
            </Stack>
          </LabeledList.Item>
        </LabeledList>
        {!!recipient && (
          <Box color="label" mt={0.5}>
            Подарок для {recipient}: платите вы, посылку откроет карта получателя, а его карта сразу скажет, что ему едет
            посылка{signed ? ' от вас' : ' - без вашего имени'}.
          </Box>
        )}
        <Box mt={1} />
        <Box mb={1}>
          <Button selected={!shown} onClick={() => setShown(null)}>
            Всё
          </Button>
          {sections.map((section) => (
            <Button key={section.name} selected={shown === section.name} onClick={() => setShown(section.name)}>
              {section.name}
            </Button>
          ))}
        </Box>
        {visible.map((section) => (
          <Box key={section.name} mb={1}>
            <Box bold mb={0.5}>
              {section.name}
            </Box>
            <Table>
              {section.packs.map((pack) => (
                <CatalogRow key={pack.id} pack={pack} full={full} recipient={recipient} signed={signed} />
              ))}
            </Table>
          </Box>
        ))}
      </Section>
    </>
  );
};

const JobsTab = () => {
  const { data } = useBackend<WalletData>();
  const [helpOpen, setHelpOpen] = useState(false);
  const topics = data.contracts_help_topics || [];
  return (
    <Section
      title="Контракты NT и объявления экипажа"
      buttons={
        topics.length > 0 && (
          <Button icon="question" selected={helpOpen} onClick={() => setHelpOpen(!helpOpen)}>
            Как это работает
          </Button>
        )
      }>
      {helpOpen && (
        <div className="NtTerm__help">
          <NtHelpTopics topics={topics} />
        </div>
      )}
      <ContractTable showShare={false} />
    </Section>
  );
};

const SharesTab = () => {
  const { data } = useBackend<WalletData>();
  const shares = data.shares || [];
  return (
    <Section title="Портфель" buttons={<Credits amount={data.portfolio} />}>
      <Box color="label" mb={1}>
        Стоимость по текущей цене, без спреда и комиссии. Купить и продать акции можно в приложении &quot;Биржа&quot;.
      </Box>
      {shares.length === 0 ? (
        <Box color="label">Акций нет.</Box>
      ) : (
        <Table>
          {shares.map((share) => (
            <Table.Row key={share.ticker}>
              <Table.Cell bold collapsing>
                {share.ticker}
              </Table.Cell>
              <Table.Cell color="label">{share.name}</Table.Cell>
              <Table.Cell collapsing>{share.count} шт.</Table.Cell>
              <Table.Cell collapsing textAlign="right">
                <Credits amount={share.value} />
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      )}
    </Section>
  );
};

const MetaTab = () => {
  const { act, data } = useBackend<WalletData>();
  const [amount, setAmount] = useState(1);
  return (
    <Section title="Метадоллары">
      <Box color="label" mb={1}>
        Метадоллары (M$) - ваш постоянный счёт между сменами, отдельный от кредитов станции. Кредиты в M$ и обратно не
        обмениваются.
      </Box>
      {!data.metadollars_available ? (
        <NoticeBox danger>Нет связи с вашим счётом метадолларов.</NoticeBox>
      ) : (
        <LabeledList>
          <LabeledList.Item label="Баланс">
            <Box bold>{data.metadollars} M$</Box>
          </LabeledList.Item>
          <LabeledList.Item label="Снять наличными">
            <RestrictedInput
              value={amount}
              minValue={1}
              maxValue={Math.max(data.metadollars, 1)}
              onChange={(_, value) => setAmount(value)}
            />{' '}
            <Button icon="money-bill-wave" disabled={amount < 1} onClick={() => act('md_withdraw', { amount })}>
              Снять
            </Button>
          </LabeledList.Item>
          <LabeledList.Item label="Зачислить">
            <Button icon="hand-holding-usd" onClick={() => act('md_deposit')}>
              Зачислить стопку из руки
            </Button>
            <Box color="label">Возьмите стопку метадолларов в активную руку.</Box>
          </LabeledList.Item>
        </LabeledList>
      )}
    </Section>
  );
};

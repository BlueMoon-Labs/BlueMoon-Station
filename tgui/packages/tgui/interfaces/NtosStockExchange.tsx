import { BooleanLike, classes } from 'common/react';
import { plural } from 'common/ru/plural';
import { useState } from 'react';

import { useBackend } from '../backend';
import { AnimatedNumber, Box, Button, Dropdown, NoticeBox, RestrictedInput, Stack, Table } from '../components';
import { NtosWindow, Window } from '../layouts';
import { ChangeBadge, Credits, EconomyLogo, formatCredits, StockEntry } from './common/Economy';
import { NtChart, NtEmpty, NtFrame, NtLine, NtMenu, NtMenuItem, NtPulse, NtReadout, NtScreen } from './common/NtTerminal';

type CompanyEntry = Omit<StockEntry, 'history'> & {
  base_price: number;
  max_buy?: number;
  /** Индекс сектора: цена - среднее по остальным компаниям, логотипа нет */
  index?: BooleanLike;
  dividend_pool?: number;
  dividend_per_share?: number;
};

export type OrderSide = 'buy_below' | 'sell_below' | 'sell_above';

export type StockOrder = {
  id: number;
  ticker: string;
  side: OrderSide;
  count: number;
  price: number;
};

/** Сноска: что двигает цену компании; effect - сдвиг в процентах, upto - потолок, а не разовый скачок. */
export type PriceDriver = {
  label: string;
  effect: number | null;
  upto?: BooleanLike;
  note?: string;
};

/** Скачок цены из ленты причин: что случилось, сдвиг в процентах (null - строка без сдвига, вроде остановки торгов) и станционное время. */
export type PriceMove = {
  text: string;
  effect: number | null;
  time: string;
};

export type StockExchangeData = {
  companies: CompanyEntry[];
  history: Record<string, number[]>;
  drivers: Record<string, PriceDriver[]>;
  moves: Record<string, PriceMove[]>;
  /** Потолок сдвига цены от работы отделов за смену, % */
  work_cap: number;
  common_drivers: PriceDriver[];
  event_min: number;
  event_max: number;
  station_event_cooldown: number;
  has_account: BooleanLike;
  account_name: string | null;
  holdings: Record<string, number>;
  cooldowns: Record<string, number>;
  balance: number;
  portfolio: number;
  realized: number;
  frozen: BooleanLike;
  can_treasury: BooleanLike;
  using_treasury: BooleanLike;
  message: string;
  fee: number;
  spread: number;
  cooldown: number;
  position_cap: number;
  personal_cap: number;
  treasury_cap_mult: number;
  halt_ratio: number;
  halt_minutes: number;
  relist_ratio: number;
  news_channel: string;
  news_delay: number;
  refute_minutes: number;
  persist_decay: number;
  orders: StockOrder[];
  orders_max: number;
  dividend_share: number;
  payroll_minutes: number;
};

/** Над разделами: переключатель казны, заморозка и ответ на последнюю сделку. */
const AccountNotices = () => {
  const { act, data } = useBackend<StockExchangeData>();
  return (
    <>
      {!!data.can_treasury && (
        <Box mb={1}>
          <Button.Checkbox
            checked={!!data.using_treasury}
            onClick={() => act('use_treasury', { value: !data.using_treasury })}>
            Торговать из казны
          </Button.Checkbox>
        </Box>
      )}
      {!data.has_account && <NoticeBox>Нет банковского счёта: торговать нечем.</NoticeBox>}
      {!!data.frozen && <NoticeBox danger>Счёт заморожен финансовым аудитом: сделки недоступны.</NoticeBox>}
      {!!data.message && <NoticeBox info>{data.message}</NoticeBox>}
    </>
  );
};

const TradeButtons = (props: { company: CompanyEntry; held: number; wait: number }) => {
  const { act, data } = useBackend<StockExchangeData>();
  const { company, held, wait } = props;
  const locked = !data.has_account || !!data.frozen;
  if (company.halted) {
    return <Box color="bad">Торги остановлены</Box>;
  }
  if (wait > 0) {
    return <Box color="label">Следующая сделка через {wait} с</Box>;
  }
  return (
    <>
      <Button disabled={locked} onClick={() => act('buy', { ticker: company.ticker, count: 1 })}>
        Купить
      </Button>
      <Button disabled={locked} onClick={() => act('buy', { ticker: company.ticker, count: 10 })}>
        ×10
      </Button>
      <Button
        disabled={locked || !company.max_buy}
        tooltip="Купить сразу столько, сколько позволяют лимит позиции и деньги на счёте"
        onClick={() => act('buy', { ticker: company.ticker, count: 'max' })}>
        Макс{company.max_buy ? ` (${company.max_buy})` : ''}
      </Button>
      <Button disabled={locked || held < 1} onClick={() => act('sell', { ticker: company.ticker, count: 1 })}>
        Продать
      </Button>
      <Button disabled={locked || held < 1} onClick={() => act('sell', { ticker: company.ticker, count: 'max' })}>
        Продать всё
      </Button>
    </>
  );
};

const signedPercent = (value: number) => `${value > 0 ? '+' : value < 0 ? '−' : ''}${Math.abs(value)}%`;

const DriverList = (props: { drivers: PriceDriver[] }) => (
  <>
    {props.drivers.map((driver) => (
      <Box key={driver.label}>
        {driver.label}
        {driver.effect !== null && (
          <>
            {': '}
            <Box inline nowrap color={driver.effect > 0 ? 'good' : driver.effect < 0 ? 'bad' : undefined}>
              {driver.upto ? 'до ' : ''}
              {signedPercent(driver.effect)}
            </Box>
          </>
        )}
        {!!driver.note && (
          <>
            {driver.effect !== null ? ' ' : ': '}
            <Box inline color="label">
              {driver.effect !== null ? `(${driver.note})` : driver.note}
            </Box>
          </>
        )}
      </Box>
    ))}
  </>
);

/** Лента причин: последние скачки цены компании, новые сверху. */
const MoveList = (props: { company: CompanyEntry; moves: PriceMove[] }) => {
  const { company, moves } = props;
  if (company.index) {
    return <Box className="NtTerm__hint">Индекс движется вместе с компаниями сектора: смотрите их ленты.</Box>;
  }
  if (!moves.length) {
    return <Box className="NtTerm__hint">Скачков пока не было: цену двигают только случайные колебания.</Box>;
  }
  return (
    <>
      {moves.map((move, index) => (
        <NtLine
          key={`${move.time}-${index}`}
          label={
            <>
              <span className="NtTerm__hint">{move.time}</span> {move.text}
            </>
          }
          tone={move.effect === null ? undefined : move.effect > 0 ? 'good' : move.effect < 0 ? 'bad' : undefined}>
          {move.effect === null ? '' : signedPercent(move.effect)}
        </NtLine>
      ))}
    </>
  );
};

/** Подсветка плитки: зелёная при росте, красная при падении, тем гуще, чем сильнее движение. */
const tileTint = (change: number) => {
  const strength = Math.min(Math.abs(change) / 20, 1) * 0.16;
  if (!strength) {
    return undefined;
  }
  return change > 0 ? `rgba(140, 191, 150, ${strength})` : `rgba(212, 134, 124, ${strength})`;
};

const QuoteTile = (props: { company: CompanyEntry; held: number; selected: boolean; onSelect: () => void }) => {
  const { company, held, selected, onSelect } = props;
  return (
    <div
      className={classes(['NtTerm__tile', selected && 'NtTerm__tile--selected', held > 0 && 'NtTerm__tile--held'])}
      style={{ backgroundColor: tileTint(company.change) }}
      onClick={onSelect}>
      <div className="NtTerm__tileHead">
        <b>{company.ticker}</b>
        {company.halted ? <span className="color-bad">стоп</span> : <ChangeBadge percent={company.change} />}
      </div>
      <div className="NtTerm__tileName">{company.name}</div>
      <div className="NtTerm__tilePrice">
        <NtPulse value={company.price}>{company.price.toFixed(2)}</NtPulse>
      </div>
    </div>
  );
};

/** Котировки: плитки всех компаний и крупно - выбранная, с графиком, сносками и сделками. */
const QuotesSection = () => {
  const { data } = useBackend<StockExchangeData>();
  const firstHeld = data.companies.find((company) => (data.holdings[company.ticker] || 0) > 0);
  const [selectedTicker, setSelectedTicker] = useState<string | null>(null);
  const company =
    data.companies.find((entry) => entry.ticker === selectedTicker) || firstHeld || data.companies[0];
  if (!company) {
    return <NtEmpty>Биржа закрыта.</NtEmpty>;
  }
  const held = data.holdings[company.ticker] || 0;
  const wait = data.cooldowns[company.ticker] || 0;
  const drivers = data.drivers?.[company.ticker] || [];
  return (
    <>
      <div className="NtTerm__tiles">
        {data.companies.map((entry) => (
          <QuoteTile
            key={entry.ticker}
            company={entry}
            held={data.holdings[entry.ticker] || 0}
            selected={entry.ticker === company.ticker}
            onSelect={() => setSelectedTicker(entry.ticker)}
          />
        ))}
      </div>
      <NtFrame
        title={
          <>
            {!company.index && <EconomyLogo id={company.ticker} />}
            {company.ticker} {company.name}
          </>
        }>
        <Stack align="flex-end" mb={0.5} wrap>
          <Stack.Item grow>
            <Box className="NtTerm__num" fontSize={1.9} lineHeight={1.1}>
              <NtPulse value={company.price}>{company.price.toFixed(2)}</NtPulse>
            </Box>
            <Box>
              <ChangeBadge percent={company.change} />
              <span className="NtTerm__hint"> за час, база {company.base_price.toFixed(2)}</span>
            </Box>
          </Stack.Item>
          <Stack.Item textAlign="right">
            <Box>
              У вас: <b>{held} шт.</b>
              {held > 0 && <span className="NtTerm__hint"> на {formatCredits(held * company.price)}</span>}
            </Box>
            {(company.dividend_pool || 0) >= 1 && (
              <Box className="NtTerm__hint">
                фонд дивидендов {formatCredits(company.dividend_pool)}, ≈{(company.dividend_per_share || 0).toFixed(2)} кр./акция
              </Box>
            )}
          </Stack.Item>
        </Stack>
        <NtChart values={data.history[company.ticker] || []} base={company.base_price} />
        <Box mb={1.5}>
          <TradeButtons company={company} held={held} wait={wait} />
        </Box>
        <Box className="NtTerm__hint" mb={0.5}>
          Почему менялась цена:
        </Box>
        <Box mb={1.5}>
          <MoveList company={company} moves={data.moves?.[company.ticker] || []} />
        </Box>
        {drivers.length > 0 && (
          <>
            <Box className="NtTerm__hint" mb={0.5}>
              Что двигает цену:
            </Box>
            <DriverList drivers={drivers} />
          </>
        )}
      </NtFrame>
    </>
  );
};

const DriversSection = () => {
  const { data } = useBackend<StockExchangeData>();
  return (
    <NtFrame title="От чего зависит цена">
      <Box mb={1}>
        <Box color="label">У всех компаний:</Box>
        <DriverList
          drivers={[
            {
              label: 'Новости компании',
              effect: null,
              note: `от ${signedPercent(data.event_min)} до ${signedPercent(data.event_max)}`,
            },
            ...(data.common_drivers || []),
          ]}
        />
        <Box color="label">
          Одно и то же событие на станции двигает цену не чаще раза в {data.station_event_cooldown} мин.
        </Box>
        {data.work_cap > 0 && (
          <Box color="label">
            Работа отделов станции двигает связанную компанию не больше чем на {data.work_cap}% за смену в каждую
            сторону; в следующую смену этот сдвиг не переходит.
          </Box>
        )}
      </Box>
      <Table>
        {data.companies.map((company) => (
          <Table.Row key={company.ticker} className="candystripe">
            <Table.Cell bold collapsing verticalAlign="top" py={0.5}>
              {company.ticker}
            </Table.Cell>
            <Table.Cell py={0.5}>
              <DriverList drivers={data.drivers?.[company.ticker] || []} />
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
    </NtFrame>
  );
};

const RulesSection = () => {
  const { data } = useBackend<StockExchangeData>();
  const work = data.work_cap > 0;
  return (
    <NtFrame title="Как работает биржа">
      <Box mb={1}>
        Цены меняются раз в минуту. События компаний, события на станции{work ? ', работа отделов' : ''} и продажи
        станции партнёрам двигают цену скачком, и он остаётся. Последние скачки с причиной видны у компании в котировках.
      </Box>
      <Box mb={1}>
        {work ? 'Работа отделов и беды станции' : 'События на станции'} двигают акции связанных компаний: одни вверх,
        другие вниз. Что двигает какую компанию, написано на странице &quot;От чего зависит цена&quot;.
        {work &&
          ` От работы цена сдвигается не больше чем на ${data.work_cap}% за смену, и в следующую смену этот сдвиг не переходит.`}
      </Box>
      <Box mb={1}>
        Новость о событии компании выходит в канале &quot;{data.news_channel}&quot; на ньюскастерах не сразу, а в течение
        примерно {data.news_delay} мин. после скачка цены: котировка и причина в окне биржи меняются раньше новости.
      </Box>
      <Box mb={1}>
        Бывают фальшивые пресс-релизы. Через {data.refute_minutes} мин. после выхода NT публикует опровержение, и цена
        возвращается.
      </Box>
      <Box mb={1}>
        Покупка идёт по цене плюс спред {data.spread}%, продажа - по цене минус спред {data.spread}%, с каждой сделки
        берётся комиссия {data.fee}%. Купить и сразу продать - всегда убыток.
      </Box>
      <Box mb={1}>Сделка по одной компании - не чаще раза в {data.cooldown} с.</Box>
      <Box mb={1}>О резком скачке цены ваших акций и об остановке торгов по ним сообщает ID-карта.</Box>
      <Box mb={1}>
        Акций одной компании - не больше чем на <Credits amount={data.position_cap} />; акции считаются по цене не ниже
        базовой. У казны лимит в {data.treasury_cap_mult} {plural(data.treasury_cap_mult, 'раз', 'раза', 'раз')} больше личного (<Credits amount={data.personal_cap} />).
      </Box>
      <Box mb={1}>
        Если цена падает ниже {data.halt_ratio}% базовой, торги останавливаются на {data.halt_minutes} мин., затем
        компания снова выходит на биржу по {data.relist_ratio}% базовой. Акции держателей обмениваются на меньшее число
        новых по цене остановки: стоимость позиции сохраняется, количество - нет.
      </Box>
      <Box mb={1}>
        Цены переносятся в следующую смену, сдвигаясь на {data.persist_decay}% к базовой. Акции на счетах смену не
        переживают.
      </Box>
      <Box mb={1}>
        Дивиденды: {data.dividend_share}% каждой закупки станции у партнёра компании идёт в её фонд. С каждой
        зарплатой фонд делится между держателями по числу акций, целыми кредитами; остаток ждёт следующей выплаты.
        Фонд смену не переживает.
      </Box>
      <Box mb={1}>
        Индекс сектора стоит 100 × среднюю долю базовой цены всех компаний: 100 - когда все по базовой цене. Своих
        новостей и остановок торгов у него нет, торгуется по тем же правилам.
      </Box>
      <Box mb={1}>
        Заявки в портфеле покупают или продают сами, когда цена дойдёт до порога: не больше {data.orders_max} на
        счёт, смену не переживают.
      </Box>
      <Box mb={1}>Из казны станции торгует только капитан - по доступу капитана на ID-карте.</Box>
      <Box color="average">
        Инсайд: крупные сделки с акциями компании перед новостью о ней или до опровержения фальшивки финансовый аудит
        видит.
      </Box>
    </NtFrame>
  );
};

type ExchangePage = 'quotes' | 'portfolio' | 'drivers' | 'rules';

export const NtosStockExchangeContent = () => {
  const { data } = useBackend<StockExchangeData>();
  const [page, setPage] = useState<ExchangePage>('quotes');
  const held = Object.keys(data.holdings || {}).filter((ticker) => data.holdings[ticker] > 0).length;
  const pages: NtMenuItem<ExchangePage>[] = [
    { key: 'quotes', label: 'Котировки' },
    { key: 'portfolio', label: 'Портфель', count: held },
    { key: 'drivers', label: 'От чего зависит цена' },
    { key: 'rules', label: 'Правила' },
  ];
  return (
    <NtScreen
      tone="exchange"
      device="Биржа сектора"
      status={data.has_account ? (data.using_treasury ? 'Казна станции' : `Личный счёт: ${data.account_name}`) : 'Счёт не найден'}
      readout={
        data.has_account ? (
          <>
            <NtReadout label="Доступно">
              <AnimatedNumber value={data.balance} format={(value) => formatCredits(value)} />
            </NtReadout>
            <NtReadout label="Акции">
              <AnimatedNumber value={data.portfolio} format={(value) => formatCredits(value)} />
            </NtReadout>
            <NtReadout label="Прибыль за смену" tone={data.realized > 0 ? 'good' : data.realized < 0 ? 'bad' : undefined}>
              {formatCredits(data.realized, { signed: true })}
            </NtReadout>
          </>
        ) : undefined
      }
      menu={
        <NtMenu<ExchangePage> items={pages} selected={page} onSelect={setPage} />
      }>
      <AccountNotices />
      {page === 'quotes' && <QuotesSection />}
      {page === 'portfolio' && (
        <>
          <PortfolioSection />
          <DividendsSection />
          <OrdersSection />
        </>
      )}
      {page === 'drivers' && <DriversSection />}
      {page === 'rules' && <RulesSection />}
    </NtScreen>
  );
};

/** Цвета долей портфеля: спокойные, различимые на тёмном. */
const ALLOC_COLORS = ['#84b598', '#8aa6c6', '#c4ad72', '#a395c4', '#c99a6e', '#7fb0bd', '#c48a86', '#a2adbb', '#8db58f', '#b893b8', '#c9d3df'];

/** Акции на счёте: полоса долей, сколько, почём и на сколько сейчас. */
const PortfolioSection = () => {
  const { data } = useBackend<StockExchangeData>();
  const rows = data.companies
    .filter((company) => (data.holdings[company.ticker] || 0) > 0)
    .map((company) => ({ company, held: data.holdings[company.ticker], value: data.holdings[company.ticker] * company.price }))
    .sort((left, right) => right.value - left.value);
  const total = rows.reduce((sum, row) => sum + row.value, 0);
  return (
    <NtFrame title="Портфель">
      {rows.length === 0 && <NtEmpty>Акций на счёте нет.</NtEmpty>}
      {rows.length > 0 && (
        <div className="NtTerm__alloc">
          {rows.map((row, index) => (
            <div
              key={row.company.ticker}
              className="NtTerm__allocPart"
              title={`${row.company.ticker}: ${Math.round((row.value / total) * 100)}%`}
              style={{ width: `${(row.value / total) * 100}%`, backgroundColor: ALLOC_COLORS[index % ALLOC_COLORS.length] }}
            />
          ))}
        </div>
      )}
      {rows.map((row, index) => (
        <NtLine
          key={row.company.ticker}
          label={
            <>
              <span className="NtTerm__allocKey" style={{ backgroundColor: ALLOC_COLORS[index % ALLOC_COLORS.length] }} />
              {`${row.company.ticker} ${row.company.name}, ${row.held} шт. по ${row.company.price.toFixed(2)}`}
            </>
          }>
          {formatCredits(row.value)}
          <span className="NtTerm__hint"> ({Math.round((row.value / total) * 100)}%)</span>
        </NtLine>
      ))}
      {rows.length > 0 && (
        <Box mt={1}>
          <NtLine label="Всего по текущей цене">{formatCredits(data.portfolio)}</NtLine>
          <NtLine label="Прибыль с продаж за смену" tone={data.realized > 0 ? 'good' : data.realized < 0 ? 'bad' : undefined}>
            {formatCredits(data.realized, { signed: true })}
          </NtLine>
        </Box>
      )}
    </NtFrame>
  );
};

/** Фонды дивидендов: сколько накопили закупки станции и сколько из них придётся на акцию. */
const DividendsSection = () => {
  const { data } = useBackend<StockExchangeData>();
  const rows = data.companies.filter((company) => (company.dividend_pool || 0) >= 1);
  return (
    <NtFrame
      title="Дивиденды"
      help={`${data.dividend_share}% закупок станции у партнёра компании идёт в её фонд. Раз в ${data.payroll_minutes} мин., с зарплатой, фонд делится между держателями по числу акций.`}>
      {rows.length === 0 && <NtEmpty>Фонды пока пусты: станция ещё ничего не закупала у партнёров.</NtEmpty>}
      {rows.map((company) => {
        const held = data.holdings[company.ticker] || 0;
        const perShare = company.dividend_per_share || 0;
        return (
          <NtLine
            key={company.ticker}
            label={`${company.ticker}: фонд ${formatCredits(company.dividend_pool)}, около ${perShare.toFixed(2)} кр. на акцию`}
            tone={held > 0 ? undefined : 'dim'}>
            {held > 0 ? `вам ≈ ${formatCredits(Math.floor(held * perShare))}` : 'нет акций'}
          </NtLine>
        );
      })}
    </NtFrame>
  );
};

const SIDE_OPTIONS: { value: OrderSide; displayText: string }[] = [
  { value: 'buy_below', displayText: 'Купить, если цена ≤' },
  { value: 'sell_below', displayText: 'Продать, если цена ≤ (стоп)' },
  { value: 'sell_above', displayText: 'Продать, если цена ≥ (фиксация)' },
];

export const orderText = (order: StockOrder) => {
  const price = order.price.toFixed(2);
  switch (order.side) {
    case 'buy_below':
      return `купить ${order.count} шт., если цена ≤ ${price}`;
    case 'sell_below':
      return `продать ${order.count} шт., если цена ≤ ${price} (стоп)`;
    default:
      return `продать ${order.count} шт., если цена ≥ ${price} (фиксация)`;
  }
};

/** Заявки: форма новой и список стоящих с отменой. */
const OrdersSection = () => {
  const { act, data } = useBackend<StockExchangeData>();
  const orders = data.orders || [];
  const [ticker, setTicker] = useState(data.companies[0]?.ticker || '');
  const company = data.companies.find((entry) => entry.ticker === ticker);
  const [side, setSide] = useState<OrderSide>('buy_below');
  const [count, setCount] = useState(1);
  const [price, setPrice] = useState(() => Math.round((company?.price || 0) * 100) / 100);
  const locked = !data.has_account || !!data.frozen;
  const full = orders.length >= data.orders_max;
  return (
    <NtFrame
      title={`Заявки ${orders.length}/${data.orders_max}`}
      help="Заявка проверяется раз в минуту после смены цен и исполняется как обычная сделка: со спредом, комиссией и лимитом позиции. Если сделка не проходит, заявка снимается и ID-карта говорит почему; кулдаун по компании и остановленные торги она пережидает.">
      <Stack align="center" mb={1}>
        <Stack.Item>
          <Dropdown
            width={7}
            selected={ticker}
            options={data.companies.map((entry) => entry.ticker)}
            onSelected={(value: string) => setTicker(value)}
          />
        </Stack.Item>
        <Stack.Item>
          <Dropdown width={17} selected={side} options={SIDE_OPTIONS} onSelected={(value: OrderSide) => setSide(value)} />
        </Stack.Item>
        <Stack.Item>
          <RestrictedInput
            width="5em"
            value={price}
            minValue={0.01}
            maxValue={(company?.base_price || 100) * 5}
            onChange={(_, value: number) => setPrice(value)}
          />{' '}
          кр.
        </Stack.Item>
        <Stack.Item>
          <RestrictedInput
            width="4em"
            value={count}
            minValue={1}
            maxValue={100000}
            onChange={(_, value: number) => setCount(Math.floor(value))}
          />{' '}
          шт.
        </Stack.Item>
        <Stack.Item>
          <Button
            disabled={locked || full || !company || count < 1 || price <= 0}
            tooltip={full ? `Не больше ${data.orders_max} заявок: снимите одну из старых` : undefined}
            onClick={() => act('add_order', { ticker, side, count, price })}>
            Поставить
          </Button>
        </Stack.Item>
      </Stack>
      {orders.length === 0 && <NtEmpty>Заявок нет.</NtEmpty>}
      {orders.map((order) => (
        <NtLine key={order.id} label={`${order.ticker}: ${orderText(order)}`}>
          <Button disabled={locked} onClick={() => act('cancel_order', { id: order.id })}>
            Отменить
          </Button>
        </NtLine>
      ))}
    </NtFrame>
  );
};

export const NtosStockExchange = () => (
  <NtosWindow width={760} height={640}>
    <NtosWindow.Content scrollable>
      <NtosStockExchangeContent />
    </NtosWindow.Content>
  </NtosWindow>
);

export const StockTerminal = () => (
  <Window width={760} height={640}>
    <Window.Content scrollable>
      <NtosStockExchangeContent />
    </Window.Content>
  </Window>
);

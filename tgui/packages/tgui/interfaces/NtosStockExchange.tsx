import { BooleanLike } from 'common/react';
import { plural } from 'common/ru/plural';

import { useBackend } from '../backend';
import { Box, Button, NoticeBox, Section, Table, Tooltip } from '../components';
import { NtosWindow, Window } from '../layouts';
import { ChangeBadge, Credits, EconomyLogo, formatCredits, Sparkline, StockEntry } from './common/Economy';

type CompanyEntry = Omit<StockEntry, 'history'> & { base_price: number; max_buy?: number };

/** Сноска: что двигает цену компании; effect - сдвиг в процентах, upto - потолок, а не разовый скачок. */
export type PriceDriver = {
  label: string;
  effect: number | null;
  upto?: BooleanLike;
  note?: string;
};

export type StockExchangeData = {
  companies: CompanyEntry[];
  history: Record<string, number[]>;
  drivers: Record<string, PriceDriver[]>;
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
};

const AccountSection = () => {
  const { act, data } = useBackend<StockExchangeData>();
  return (
    <Section
      title={data.using_treasury ? 'Казна станции' : 'Личный счёт'}
      buttons={
        !!data.can_treasury && (
          <Button.Checkbox
            checked={!!data.using_treasury}
            onClick={() => act('use_treasury', { value: !data.using_treasury })}>
            Торговать из казны
          </Button.Checkbox>
        )
      }>
      {data.has_account ? (
        <Table>
          <Table.Row>
            <Table.Cell color="label">Счёт</Table.Cell>
            <Table.Cell>{data.account_name}</Table.Cell>
          </Table.Row>
          <Table.Row>
            <Table.Cell color="label">Доступно</Table.Cell>
            <Table.Cell>
              <Credits amount={data.balance} />
            </Table.Cell>
          </Table.Row>
          <Table.Row>
            <Table.Cell color="label">Акции по текущей цене</Table.Cell>
            <Table.Cell>
              <Credits amount={data.portfolio} />
            </Table.Cell>
          </Table.Row>
          <Table.Row>
            <Table.Cell color="label">Прибыль с продаж за смену</Table.Cell>
            <Table.Cell color={data.realized > 0 ? 'good' : data.realized < 0 ? 'bad' : undefined}>
              <Credits amount={data.realized} signed />
            </Table.Cell>
          </Table.Row>
        </Table>
      ) : (
        <NoticeBox>Нет банковского счёта: торговать нечем.</NoticeBox>
      )}
      {!!data.frozen && <NoticeBox danger>Счёт заморожен финансовым аудитом: сделки недоступны.</NoticeBox>}
      {!!data.message && <NoticeBox info>{data.message}</NoticeBox>}
    </Section>
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

const QuotesSection = () => {
  const { data } = useBackend<StockExchangeData>();
  return (
    <Section title="Котировки">
      <Table>
        <Table.Row header>
          <Table.Cell>Тикер</Table.Cell>
          <Table.Cell>Компания</Table.Cell>
          <Table.Cell collapsing>За час</Table.Cell>
          <Table.Cell collapsing textAlign="right">
            Цена
          </Table.Cell>
          <Table.Cell collapsing>Изменение</Table.Cell>
          <Table.Cell collapsing>У вас</Table.Cell>
          <Table.Cell collapsing />
        </Table.Row>
        {data.companies.map((company) => {
          const held = data.holdings[company.ticker] || 0;
          return (
            <Table.Row key={company.ticker} className="candystripe">
              <Table.Cell bold collapsing>
                <EconomyLogo id={company.ticker} />
                {company.ticker}
              </Table.Cell>
              <Table.Cell>
                <Tooltip content={<DriverList drivers={data.drivers?.[company.ticker] || []} />}>
                  <Box inline style={{ borderBottom: '1px dotted', cursor: 'help' }}>
                    {company.name}
                  </Box>
                </Tooltip>
              </Table.Cell>
              <Table.Cell collapsing>
                <Sparkline values={data.history[company.ticker] || []} />
              </Table.Cell>
              <Table.Cell collapsing textAlign="right" nowrap>
                {company.price.toFixed(2)}
              </Table.Cell>
              <Table.Cell collapsing>
                <ChangeBadge percent={company.change} />
              </Table.Cell>
              <Table.Cell collapsing nowrap>
                {held} шт.{held > 0 && ` · ${formatCredits(held * company.price)}`}
              </Table.Cell>
              <Table.Cell collapsing nowrap>
                <TradeButtons company={company} held={held} wait={data.cooldowns[company.ticker] || 0} />
              </Table.Cell>
            </Table.Row>
          );
        })}
      </Table>
    </Section>
  );
};

const DriversSection = () => {
  const { data } = useBackend<StockExchangeData>();
  return (
    <Section title="От чего зависит цена">
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
    </Section>
  );
};

const RulesSection = () => {
  const { data } = useBackend<StockExchangeData>();
  return (
    <Section title="Как работает биржа">
      <Box mb={1}>
        Цены меняются раз в минуту. События компаний, события на станции и продажи станции партнёрам двигают цену
        скачком, и он остаётся.
      </Box>
      <Box mb={1}>
        Новость о событии компании выходит в канале «{data.news_channel}» на ньюскастерах не сразу, а в течение
        примерно {data.news_delay} мин. после скачка цены: котировка меняется раньше новости.
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
      <Box mb={1}>Из казны станции торгует только капитан - по доступу капитана на ID-карте.</Box>
      <Box color="average">
        Инсайд: крупные сделки с акциями компании перед новостью о ней или до опровержения фальшивки финансовый аудит
        видит.
      </Box>
    </Section>
  );
};

export const NtosStockExchangeContent = () => (
  <>
    <AccountSection />
    <QuotesSection />
    <DriversSection />
    <RulesSection />
  </>
);

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

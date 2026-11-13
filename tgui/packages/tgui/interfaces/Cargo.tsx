import { toArray } from 'common/collections';
import { BooleanLike } from 'common/react';
import { plural } from 'common/ru/plural';
import { storage } from 'common/storage';
import { createSearch } from 'common/string';
import { useEffect, useMemo, useRef, useState } from 'react';

import { useBackend } from '../backend';
import {
  AnimatedNumber,
  Box,
  Button,
  Icon,
  Input,
  LabeledList,
  NoticeBox,
  ProgressBar,
  RestrictedInput,
  Stack,
  Table,
  Tooltip,
} from '../components';
import { Window } from '../layouts';
import { ContractTable } from './common/ContractTable';
import { ContractEntry, Credits, EconomyLogo, formatCredits, OfferEntry, Sparkline } from './common/Economy';
import { NtEmpty, NtFrame, NtHelpTopic, NtHelpTopics, NtLine, NtMenu, NtMenuItem, NtPulse, NtReadout, NtScreen } from './common/NtTerminal';

type Pack = {
  name: string;
  id: string;
  /** Описание и опись не приходят каталогом: карточка запрашивает их через pack_info */
  desc?: string;
  cost?: number;
  goody?: BooleanLike;
  access?: BooleanLike;
  private_goody?: BooleanLike;
  can_private_buy?: BooleanLike;
  personal?: BooleanLike;
  commodity?: string | null;
  contents?: string[];
  /** Эксклюзив партнёра: [имя партнёра, ступень, с которой он его везёт] */
  exclusive?: [string, number] | null;
  /** Все открытые партнёры, у которых пак есть: [id, цена]; только когда их больше одного */
  choices?: [string, number][] | null;
  supplier?: string | null;
  in_stock?: BooleanLike;
  /** id отдела, в каталог которого входит пак */
  budget?: string;
};

/** Чей бюджет оплатит заявку зрителя на пак каталога отдела; any - ГП и капитан, им платит отдел пака. */
type BudgetRequest = {
  id?: string | null;
  name?: string | null;
  balance?: number | null;
  manager: BooleanLike;
  any: BooleanLike;
  /** Есть кому одобрить заявку: без него паки дороже auto_limit уходят снабжению */
  approver?: BooleanLike;
  auto_limit: number;
};

/** Цена, id поставщика и наличие пака: приходят отдельно от каталога и обновляются после пересчёта цен. */
type PackPrice = [number, string | null, BooleanLike, ([string, number][] | null)?];

const withPrice = (pack: Pack, prices?: Record<string, PackPrice>, partnerNames?: Record<string, string>): Pack => {
  const price = prices?.[pack.id];
  if (!price) {
    return pack;
  }
  const supplier = price[1] && (partnerNames?.[price[1]] || price[1]);
  return { ...pack, cost: price[0], supplier, in_stock: price[2], choices: price[3] || null };
};

type PackInfo = { id: string; desc: string; contents: string[] };

type SupplyGroup = {
  name: string;
  packs: Pack[];
};

type CartEntry = {
  id: number;
  object: string;
  cost: number;
  orderer: string;
  paid: BooleanLike;
  /** Уже оплачен: бюджетом отдела или с КПК покупателя. */
  prepaid?: BooleanLike;
  pack?: string;
  department?: string | null;
  supplier?: string | null;
};

type RequestRow = {
  id: number;
  object: string;
  cost: number;
  orderer: string;
  reason: string;
};

type DepartmentOrder = {
  id: number;
  object: string;
  department: string;
  orderer: string;
  reason: string;
  prepaid: number;
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
  desc: string;
  unlocked: BooleanLike;
  tier: number;
  reputation: number;
  discount: number;
  markup: number;
  wealth: number;
  next_unlock: string | null;
  embargo_minutes?: number;
  buys: string;
  sells: string;
};

type HelpTopic = {
  title: string;
  icon: string;
  lines: string[];
};

type AuctionLot = {
  uid: number;
  name: string;
  desc: string;
  value: number;
  bid: number;
  bidder: string | null;
  mine: BooleanLike;
  min_bid: number;
  increment: number;
  left: number;
  rivals: number;
  history: { who: string; amount: number }[];
};

type BundleOffer = {
  uid: number;
  partner: string;
  partner_id: string;
  items: string[];
  full_value: number;
  price: number;
  discount: number;
  left: number;
};

type AuctionResult = { name: string; winner: string | null; price: number; ours: BooleanLike };

type ShuttleState = 'station' | 'centcom' | 'to_station' | 'to_centcom' | 'recharging' | 'loaned' | 'away';

type CargoData = {
  location: string;
  shuttle?: { state: ShuttleState; eta: number };
  points: number;
  away: BooleanLike;
  docked: BooleanLike;
  loan: BooleanLike;
  loan_dispatched: BooleanLike;
  message: string;
  requestonly: BooleanLike;
  can_send: BooleanLike;
  can_edit_cart?: BooleanLike;
  can_approve_requests: BooleanLike;
  can_take_offers?: BooleanLike;
  self_paid: BooleanLike;
  is_app?: BooleanLike;
  budget_request?: BudgetRequest | null;
  manifest_department?: string | null;
  manifest_fee?: number;
  market_help?: string;
  help_topics?: HelpTopic[];
  contracts_help_topics?: NtHelpTopic[];
  private_markup?: number;
  reason_max?: number;
  add_max?: number;
  reputation_per_credit?: number;
  tier_step?: number;
  tier_max?: number;
  supplies: Record<string, SupplyGroup> | SupplyGroup[];
  prices?: Record<string, PackPrice>;
  cart?: CartEntry[];
  requests?: RequestRow[];
  department_requests?: DepartmentOrder[];
  special_offers?: OfferEntry[];
  market?: { commodities: Commodity[]; price_index: number };
  partners?: Partner[];
  contracts?: ContractEntry[];
  auction?: AuctionLot | null;
  bundles?: BundleOffer[];
  auction_next?: number;
  auction_results?: AuctionResult[];
  my_balance?: number | null;
  pack_info?: PackInfo | null;
  search?: string;
  search_hits?: string[];
  search_total?: number;
};

const formatTime = (seconds: number) => `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`;

const canEditCart = (data: CargoData) => !!(data.can_edit_cart ?? data.can_send);

/** Платит ли бюджет снабжения: не частный заказ и не оплаченный отделом. */
const paidByCargo = (entry: CartEntry) => !entry.paid && !entry.department;

const cargoTotal = (cart: CartEntry[]) => cart.filter(paidByCargo).reduce((sum, entry) => sum + entry.cost, 0);

const FAVORITES_KEY = 'cargo-favorites';

/** Избранные паки - у каждого игрока свои, хранятся в клиенте. */
const useFavorites = () => {
  const [favorites, setFavorites] = useState<string[]>([]);
  useEffect(() => {
    let alive = true;
    Promise.resolve(storage.get(FAVORITES_KEY))
      .then((saved: unknown) => {
        if (alive && Array.isArray(saved)) {
          setFavorites(saved.filter((id) => typeof id === 'string'));
        }
      })
      .catch(() => {});
    return () => {
      alive = false;
    };
  }, []);
  const toggle = (id: string) => {
    const next = favorites.includes(id) ? favorites.filter((other) => other !== id) : [...favorites, id];
    setFavorites(next);
    Promise.resolve(storage.set(FAVORITES_KEY, next)).catch(() => {});
  };
  return [favorites, toggle] as const;
};

export const Cargo = (props) => {
  return (
    <Window width={980} height={680} resizable>
      <Window.Content scrollable>
        <CargoContent />
      </Window.Content>
    </Window>
  );
};

type Page = 'catalog' | 'cart' | 'requests' | 'offers' | 'bundles' | 'auction' | 'market' | 'partners' | 'contracts' | 'help';

export const CargoContent = (props) => {
  const { data } = useBackend<CargoData>();
  const [page, setPage] = useState<Page>('catalog');
  const { requestonly } = data;
  const cart = data.cart || [];
  const requests = data.requests || [];
  const departmentOrders = data.department_requests || [];
  const offers = data.special_offers || [];
  const pages: NtMenuItem<Page>[] = [
    { key: 'catalog', label: 'Каталог' },
    ...(requestonly ? [] : [{ key: 'cart' as Page, label: 'Корзина', count: cart.length }]),
    { key: 'requests', label: 'Заявки', count: requests.length },
    { key: 'offers', label: 'Спецзаказы', count: offers.length },
    { key: 'bundles', label: 'Скупка', count: (data.bundles || []).length },
    { key: 'auction', label: 'Аукцион', count: data.auction ? 1 : 0 },
    { key: 'market', label: 'Рынок' },
    { key: 'partners', label: 'Партнёры' },
    { key: 'contracts', label: 'Контракты' },
    { key: 'help', label: 'Справка' },
  ];
  const total = cargoTotal(cart);
  const shuttle = shuttleOf(data);
  const inTransit = shuttle.state === 'to_station' || shuttle.state === 'to_centcom' || shuttle.state === 'recharging';
  return (
    <NtScreen
      tone="supply"
      device={data.is_app ? 'Заказы снабжения' : requestonly ? 'Консоль заявок' : 'Консоль снабжения'}
      status={
        <>
          <Box>
            Шаттл {SHUTTLE_TEXT[shuttle.state]}
            {inTransit && shuttle.eta > 0 && (
              <span className="NtTerm__num" style={{ marginLeft: '8px' }}>
                {formatTime(shuttle.eta)}
              </span>
            )}
          </Box>
          <Box>{data.message}</Box>
        </>
      }
      readout={
        <>
          {!requestonly && (
            <NtReadout label="В корзине">
              {cart.length}
              {total > 0 && <span className="NtTerm__hint"> на {formatCredits(total)}</span>}
            </NtReadout>
          )}
          <NtReadout label="Бюджет снабжения">
            <AnimatedNumber value={data.points} format={(value) => formatCredits(value)} />
          </NtReadout>
        </>
      }
      menu={<NtMenu<Page> items={pages} selected={page} onSelect={setPage} />}>
      <CargoCommands />
      {page === 'catalog' && <CargoCatalog />}
      {page === 'cart' && <CargoCart />}
      {page === 'requests' && <CargoRequests />}
      {page === 'offers' && <SpecialOffers />}
      {page === 'bundles' && <Bundles />}
      {page === 'auction' && <Auction />}
      {page === 'market' && <Market />}
      {page === 'partners' && <Partners />}
      {page === 'contracts' && <Contracts />}
      {page === 'help' && <CargoHelp />}
    </NtScreen>
  );
};

const SHUTTLE_TEXT: Record<ShuttleState, string> = {
  station: 'на станции',
  centcom: 'у ЦК',
  to_station: 'летит на станцию',
  to_centcom: 'летит к ЦК',
  recharging: 'перезаряжается',
  loaned: 'передан ЦК',
  away: 'вне станции',
};

/** Состояние шаттла: из данных сервера, а у старых данных - по away/docked. */
const shuttleOf = (data: CargoData): { state: ShuttleState; eta: number } =>
  data.shuttle || { state: data.docked ? (data.away ? 'centcom' : 'station') : 'to_station', eta: 0 };

const ShuttleButton = (props: { inCart?: boolean }) => {
  const { act, data } = useBackend<CargoData>();
  const { requestonly, can_send, is_app } = data;
  const cart = data.cart || [];
  if (requestonly || !can_send || is_app) {
    return null;
  }
  const { state } = shuttleOf(data);
  if (state === 'centcom') {
    return (
      <Button icon="rocket" color="good" onClick={() => act('send')}>
        {cart.length ? 'Вызвать шаттл с заказом' : 'Вызвать шаттл'}
      </Button>
    );
  }
  if (state === 'station' && !props.inCart) {
    return (
      <Button icon="plane-departure" onClick={() => act('send')}>
        Отправить шаттл к ЦК
      </Button>
    );
  }
  return null;
};

/** Команды консоли над разделом: шаттл, накладная, аренда; пусто - строки нет. */
const CargoCommands = (props) => {
  const { act, data } = useBackend<CargoData>();
  const { loan, loan_dispatched, requestonly, manifest_department, manifest_fee, is_app } = data;
  const shuttle = shuttleOf(data);
  const showLoan = !!loan && !requestonly && !is_app;
  return (
    <Stack align="center" wrap mb={1.5}>
      <Stack.Item>
        <ShuttleButton />
      </Stack.Item>
      {!!manifest_department && (
        <Stack.Item>
          <Button
            icon="file-invoice"
            tooltip={`Положите накладную в ящик перед отгрузкой: выручка за ящик уйдёт отделу за вычетом сбора снабжения (${manifest_fee}%).`}
            onClick={() => act('print_manifest')}>
            {`Накладная: ${manifest_department}`}
          </Button>
        </Stack.Item>
      )}
      {showLoan && (
        <Stack.Item>
          {loan_dispatched ? (
            <Box color="bad">Шаттл у ЦК по аренде</Box>
          ) : (
            <Button
              icon="handshake"
              disabled={shuttle.state !== 'centcom'}
              tooltip="ЦК просит шаттл на время; доступно, пока он стоит у ЦК."
              onClick={() => act('loan')}>
              Сдать шаттл ЦК
            </Button>
          )}
        </Stack.Item>
      )}
      {!!is_app && (
        <Stack.Item grow color="label" textAlign="right">
          Шаттл, его аренда и спецзаказы - только с консоли снабжения.
        </Stack.Item>
      )}
    </Stack>
  );
};

const packTags = (pack: Pack) => {
  const tags: { text: string }[] = [];
  if (pack.goody) {
    tags.push({ text: 'Малый кейс' });
  }
  if (pack.access) {
    tags.push({ text: 'Доступ' });
  }
  if (pack.personal) {
    tags.push({ text: 'Без наценки' });
  }
  if (pack.exclusive) {
    tags.push({ text: `эксклюзив ${pack.exclusive[0]}` });
  }
  return tags;
};

/** Заявку на этот пак оплатит бюджет отдела зрителя, а не снабжение. Без начальства на смене пак дороже лимита автоодобрения уходит снабжению. */
const paidByBudget = (pack: Pack, budget?: BudgetRequest | null) => {
  if (!budget || !pack.budget || (!budget.any && pack.budget !== budget.id)) {
    return false;
  }
  return !!budget.manager || !!budget.approver || (pack.cost || 0) <= budget.auto_limit;
};

const BudgetNotice = (props: { budget: BudgetRequest }) => {
  const { budget } = props;
  const own = budget.name && !budget.any ? `отдела "${budget.name}" (сейчас ${formatCredits(budget.balance || 0)})` : 'отдела пака';
  let text = `Паки с пометкой "бюджет отдела" оплатит бюджет ${own}. Заявку одобряет глава отдела, ГП или капитан в программе "Бюджет отдела" на КПК; если ответа долго нет, заявка до ${formatCredits(budget.auto_limit)} одобряется сама.`;
  if (budget.manager) {
    text = `Паки с пометкой "бюджет отдела" вы заказываете сразу за бюджет ${own}: заказ уходит в снабжение оплаченным.`;
  } else if (!budget.approver) {
    text = `Начальства отдела на смене нет: пак своего каталога до ${formatCredits(budget.auto_limit)} оплатит бюджет ${own}, заявка одобрится сама. Пак дороже уйдёт заявкой снабжению.`;
  }
  return (
    <NoticeBox info>
      {text} Остальные паки - заявкой снабжению, за его бюджет.
    </NoticeBox>
  );
};

const PackDetails = (props: {
  pack: Pack;
  cost: number;
  outOfStock: boolean;
  onOrder: (amount: number, partner?: string) => void;
  express?: boolean;
  payer?: string;
  /** Заказ отдела везёт самый дешёвый партнёр: выбора нет */
  cheapestOnly?: boolean;
  /** Начальство заказывает за бюджет отдела сразу, без заявки */
  orderNow?: boolean;
}) => {
  const { act, data } = useBackend<CargoData>();
  const { pack, outOfStock, onOrder, express, payer, cheapestOnly, orderNow } = props;
  const addMax = data.add_max || 10;
  const [amount, setAmount] = useState(1);
  const [partner, setPartner] = useState<string | null>(null);
  useEffect(() => {
    act('pack_info', { id: pack.id });
  }, [pack.id]);
  const info = data.pack_info?.id === pack.id ? data.pack_info : null;
  const contents = info?.contents || pack.contents || [];
  const desc = info?.desc || pack.desc;
  // Цена в окне уже с наценкой частного заказа: та же доля ложится на цены других партнёров
  const ratio = pack.cost ? props.cost / pack.cost : 1;
  const choices = !express && !cheapestOnly && pack.choices ? pack.choices : null;
  const chosen = choices?.find(([id]) => id === partner);
  const cost = chosen ? Math.round(chosen[1] * ratio) : props.cost;
  const partnerName = (id: string) => data.partners?.find((entry) => entry.id === id)?.name || id;
  const repPerCredit = data.reputation_per_credit || 0;
  return (
    <Box className="NtTerm__detail">
      <Box mb={1} color={desc ? undefined : 'label'}>
        {desc || 'Загружаю описание...'}
      </Box>
      {contents.length > 0 && (
        <Box mb={1}>
          <Box color="label" mb={0.5}>
            Внутри по описи:
          </Box>
          <Box>{contents.join(', ')}</Box>
        </Box>
      )}
      <LabeledList>
        <LabeledList.Item label="Поставщик">
          {outOfStock ? (
            <Box color="bad">
              {pack.exclusive
                ? `эксклюзив ${pack.exclusive[0]}, откроется на ${pack.exclusive[1]}-й ступени репутации`
                : 'ни у кого нет на складе'}
            </Box>
          ) : choices ? (
            choices.map(([id, price]) => {
              const selected = chosen ? chosen[0] === id : partnerName(id) === pack.supplier;
              return (
                <Box key={id} className={selected ? 'NtTerm__chip NtTerm__chip--active' : 'NtTerm__chip'} onClick={() => setPartner(id)}>
                                    {partnerName(id)} - {formatCredits(Math.round(price * ratio))}
                  {repPerCredit > 0 && <span className="NtTerm__hint">, +{Math.round((price * repPerCredit) / 2)} репутации</span>}
                </Box>
              );
            })
          ) : (
            pack.supplier || 'NT напрямую'
          )}
        </LabeledList.Item>
        {!!pack.commodity && <LabeledList.Item label="Товар рынка">{pack.commodity}, цена идёт за ним (вкладка Рынок)</LabeledList.Item>}
        {!!payer && <LabeledList.Item label="Оплатит">{payer}</LabeledList.Item>}
      </LabeledList>
      {!outOfStock && (
        <Stack align="center" mt={1}>
          {!express && (
            <>
              <Stack.Item>
                <Button icon="minus" disabled={amount <= 1} onClick={() => setAmount(amount - 1)} />
              </Stack.Item>
              <Stack.Item>
                <Box bold width="2em" textAlign="center">
                  {amount}
                </Box>
              </Stack.Item>
              <Stack.Item>
                <Button icon="plus" disabled={amount >= addMax} onClick={() => setAmount(amount + 1)} />
              </Stack.Item>
            </>
          )}
          <Stack.Item>
            <Button icon="cart-plus" color="good" onClick={() => onOrder(amount, chosen ? chosen[0] : undefined)}>
              {`${express || orderNow ? 'Заказать' : payer ? 'Подать заявку' : 'В корзину'} за ${formatCredits(cost * amount)}`}
            </Button>
          </Stack.Item>
        </Stack>
      )}
    </Box>
  );
};

export const CargoCatalog = (props: { express?: boolean }) => {
  const { express } = props;
  const { act, data } = useBackend<CargoData>();
  const { self_paid, private_markup = 1, requestonly, reason_max } = data;
  const supplies = toArray(data.supplies) as SupplyGroup[];
  const [favorites, toggleFavorite] = useFavorites();
  const [activeSupplyName, setActiveSupplyName] = useState<string | null>(supplies[0]?.name ?? null);
  const [searchText, setSearchText] = useState('');
  const [openId, setOpenId] = useState<string | null>(null);
  const [reason, setReason] = useState('');
  const allPacks = useMemo(() => {
    const seen = new Set<string>();
    return supplies
      .flatMap((supply) => supply.packs)
      .filter((pack) => {
        if (seen.has(pack.id)) {
          return false;
        }
        seen.add(pack.id);
        return true;
      });
  }, [data.supplies]);
  const partnerNames = useMemo(
    () => Object.fromEntries((data.partners || []).map((entry) => [entry.id, entry.name])),
    [data.partners],
  );
  const query = searchText.trim();
  const isSearching = query.length >= 2;
  useEffect(() => {
    if (!isSearching) {
      return;
    }
    const timer = setTimeout(() => act('search', { text: query }), 300);
    return () => clearTimeout(timer);
  }, [query]);
  // Пока сервер не ответил на эту строку, ищем по названию: описания и описи у окна нет
  const serverHits = isSearching && data.search === query ? data.search_hits : null;
  const displayedPacks = useMemo(() => {
    if (isSearching) {
      if (serverHits) {
        const hits = new Set(serverHits);
        return allPacks.filter((pack) => hits.has(pack.id));
      }
      return allPacks.filter(createSearch(query, (pack: Pack) => pack.name));
    }
    if (activeSupplyName === null) {
      return allPacks.filter((pack) => favorites.includes(pack.id));
    }
    return supplies.find((supply) => supply.name === activeSupplyName)?.packs || [];
  }, [allPacks, isSearching, serverHits, query, activeSupplyName, favorites, data.supplies]);
  const showFavorites = !isSearching && activeSupplyName === null;
  const foundTotal = serverHits ? data.search_total || serverHits.length : displayedPacks.length;
  const markupPercent = Math.round((private_markup - 1) * 100);
  const privateHint = express
    ? 'Оплата с вашего счёта сразу при заказе, без наценки частного заказа.'
    : 'Оплата с вашего счёта при доставке.' +
      (markupPercent > 0 ? ` Частный заказ дороже на ${markupPercent}%, наценка идёт снабжению; малые кейсы и личный каталог - без наценки.` : '');
  const asRequest = !!requestonly && !self_paid;
  const budget = asRequest && !express ? data.budget_request : null;
  const payerOf = (pack: Pack) => {
    if (!asRequest || express) {
      return undefined;
    }
    if (!paidByBudget(pack, budget)) {
      return 'бюджет снабжения, если снабжение одобрит заявку';
    }
    return budget?.name && !budget.any ? `бюджет отдела "${budget.name}"` : 'бюджет отдела пака';
  };
  const requestTitle = !budget ? 'Каталог: заявка снабжению' : budget.manager ? 'Каталог: заказ за бюджет отдела или заявка снабжению' : 'Каталог: заявка отделу или снабжению';
  const order = (pack: Pack, amount = 1, partner?: string) => {
    const payload: Record<string, unknown> = { id: pack.id };
    if (partner) {
      payload.partner = partner;
    }
    if (asRequest && reason.trim()) {
      payload.reason = reason.trim();
    }
    if (amount > 1) {
      payload.amount = amount;
    }
    act('add', payload);
  };
  return (
    <NtFrame
      title={express ? 'Каталог' : asRequest ? requestTitle : 'Каталог'}
      buttons={
        <Button.Checkbox checked={self_paid} tooltip={privateHint} onClick={() => act('toggleprivate')}>
          Купить лично
        </Button.Checkbox>
      }>
      <Stack align="center" mb={1}>
        <Stack.Item grow>
          <Input
            fluid
            placeholder="Поиск по названию, описанию и описи"
            value={searchText}
            onInput={(e, value) => setSearchText(value)}
          />
        </Stack.Item>
      </Stack>
      <div className="NtTerm__chips">
        <span
          className={showFavorites ? 'NtTerm__chip NtTerm__chip--active' : 'NtTerm__chip'}
          onClick={() => {
            setActiveSupplyName(null);
            setSearchText('');
          }}>
          {`Избранное (${favorites.length})`}
        </span>
        {supplies.map((supply) => (
          <span
            key={supply.name}
            className={!isSearching && supply.name === activeSupplyName ? 'NtTerm__chip NtTerm__chip--active' : 'NtTerm__chip'}
            onClick={() => {
              setActiveSupplyName(supply.name);
              setSearchText('');
            }}>
            {`${supply.name} (${supply.packs.length})`}
          </span>
        ))}
      </div>
      {!!budget && <BudgetNotice budget={budget} />}
      {asRequest && (
        <Stack align="center" mb={1}>
          <Stack.Item color="label">Причина заявки:</Stack.Item>
          <Stack.Item grow>
            <Input
              fluid
              maxLength={reason_max}
              placeholder="Если оставить пустой, консоль спросит при заказе"
              value={reason}
              onInput={(e, value) => setReason(value)}
            />
          </Stack.Item>
        </Stack>
      )}
      {isSearching && (
        <Box color="label" mb={1}>
          Найдено: {foundTotal}
          {foundTotal > displayedPacks.length ? `, показаны первые ${displayedPacks.length} - уточните запрос` : ''}
          {serverHits ? '' : ' (пока только по названию)'}
        </Box>
      )}
      {showFavorites && displayedPacks.length === 0 && (
        <Box color="label" my={2} textAlign="center">
          Отметьте звёздочкой паки, которые заказываете часто, - они соберутся здесь.
        </Box>
      )}
      <Table>
        {displayedPacks.map((listed) => {
          const pack = withPrice(listed, data.prices, partnerNames);
          const priced = typeof pack.cost === 'number';
          const outOfStock = !priced || (pack.in_stock !== undefined && !pack.in_stock);
          const cost = self_paid && !express && !pack.goody && !pack.personal ? Math.round((pack.cost || 0) * private_markup) : pack.cost || 0;
          const open = openId === pack.id;
          const favorite = favorites.includes(pack.id);
          const byBudget = paidByBudget(pack, budget);
          return [
            <Table.Row key={pack.id} className={open ? 'NtTerm__row NtTerm__row--open' : 'NtTerm__row'}>
              <Table.Cell collapsing py={0.5}>
                <Button
                  icon="star"
                  color="transparent"
                  textColor={favorite ? 'yellow' : 'label'}
                  tooltip={favorite ? 'Убрать из избранного' : 'В избранное'}
                  onClick={() => toggleFavorite(pack.id)}
                />
              </Table.Cell>
              <Table.Cell py={0.5} onClick={() => setOpenId(open ? null : pack.id)}>
                <Icon name={open ? 'chevron-down' : 'chevron-right'} color="label" mr={1} />
                {pack.name}
                {packTags(pack).map((tag) => (
                  <span key={tag.text} className="NtTerm__tag">
                    {tag.text}
                  </span>
                ))}
                {byBudget && <span className="NtTerm__tag">бюджет отдела</span>}
              </Table.Cell>
              <Table.Cell collapsing py={0.5} color={outOfStock ? 'bad' : 'label'} pr={1}>
                {outOfStock ? (pack.exclusive ? `ступень ${pack.exclusive[1]} у ${pack.exclusive[0]}` : 'нет в наличии') : pack.supplier || '-'}
              </Table.Cell>
              <Table.Cell collapsing py={0.5} textAlign="right">
                <Button
                  fluid
                  disabled={outOfStock}
                  tooltip={
                    outOfStock
                      ? 'Ни у одного открытого партнёра нет на складе: ждите пополнения.'
                      : byBudget
                        ? budget?.manager
                          ? 'Заказать за бюджет отдела'
                          : 'Подать заявку отделу: оплатит бюджет отдела'
                        : asRequest
                          ? 'Подать заявку снабжению'
                          : 'Добавить один'
                  }
                  tooltipPosition="left"
                  onClick={() => order(pack)}>
                  {priced ? formatCredits(cost) : '-'}
                </Button>
              </Table.Cell>
            </Table.Row>,
            open && (
              <Table.Row key={`${pack.id}-details`}>
                <Table.Cell />
                <Table.Cell colSpan={3}>
                  <PackDetails
                    pack={pack}
                    cost={cost}
                    outOfStock={outOfStock}
                    express={express}
                    payer={payerOf(pack)}
                    cheapestOnly={byBudget}
                    orderNow={byBudget && !!budget?.manager}
                    onOrder={(amount, partner) => order(pack, amount, partner)}
                  />
                </Table.Cell>
              </Table.Row>
            ),
          ];
        })}
      </Table>
    </NtFrame>
  );
};

const CargoRequests = (props) => {
  const { act, data } = useBackend<CargoData>();
  const { requestonly, can_send, can_approve_requests } = data;
  const requests = data.requests || [];
  const canDecide = (!requestonly || !!can_send) && !!can_approve_requests;
  return (
    <NtFrame
      title="Заявки экипажа"
      help='Одобренная заявка уходит в корзину и оплачивается из бюджета снабжения. Заявки сотрудников отделов на паки каталога своего отдела сюда не попадают: их оплачивает бюджет отдела, а решает глава в "Бюджете отдела".'
      buttons={
        !requestonly &&
        requests.length > 0 && (
          <Button icon="times" color="transparent" onClick={() => act('denyall')}>
            Отклонить все
          </Button>
        )
      }>
      {requests.length === 0 && <NtEmpty>Заявок нет.</NtEmpty>}
      {requests.length > 0 && (
        <Table>
          <Table.Row header>
            <Table.Cell collapsing>№</Table.Cell>
            <Table.Cell>Пак</Table.Cell>
            <Table.Cell>Кто</Table.Cell>
            <Table.Cell>Зачем</Table.Cell>
            <Table.Cell collapsing textAlign="right">
              Цена
            </Table.Cell>
            {canDecide && <Table.Cell collapsing />}
          </Table.Row>
          {requests.map((request) => (
            <Table.Row key={request.id} className="candystripe">
              <Table.Cell collapsing color="label" py={0.5}>
                #{request.id}
              </Table.Cell>
              <Table.Cell py={0.5}>{request.object}</Table.Cell>
              <Table.Cell py={0.5}>
                <b>{request.orderer}</b>
              </Table.Cell>
              <Table.Cell py={0.5}>
                <i>{request.reason}</i>
              </Table.Cell>
              <Table.Cell collapsing textAlign="right" py={0.5}>
                <Credits amount={request.cost} />
              </Table.Cell>
              {canDecide && (
                <Table.Cell collapsing py={0.5}>
                  <Button icon="check" color="good" onClick={() => act('approve', { id: request.id })}>
                    Одобрить
                  </Button>
                  <Button icon="times" color="bad" onClick={() => act('deny', { id: request.id })}>
                    Отклонить
                  </Button>
                </Table.Cell>
              )}
            </Table.Row>
          ))}
        </Table>
      )}
    </NtFrame>
  );
};

type CartGroup = {
  key: string;
  object: string;
  pack?: string;
  payer: string;
  supplier?: string | null;
  byCargo: boolean;
  prepaid: boolean;
  ids: number[];
  cost: number;
};

/** Одинаковые паки с одним плательщиком - одной строкой с количеством. */
const groupCart = (cart: CartEntry[]): CartGroup[] => {
  const groups: CartGroup[] = [];
  for (const entry of cart) {
    const byCargo = paidByCargo(entry);
    const payer = entry.department ? `Отдел: ${entry.department}` : entry.paid ? `Лично: ${entry.orderer}` : 'Снабжение';
    const key = `${entry.pack || entry.object}|${payer}|${entry.supplier || ''}|${entry.prepaid ? 1 : 0}`;
    const group = groups.find((other) => other.key === key);
    if (group) {
      group.ids.push(entry.id);
      group.cost += entry.cost;
    } else {
      groups.push({
        key,
        object: entry.object,
        pack: entry.pack,
        payer,
        supplier: entry.supplier,
        byCargo,
        prepaid: !!entry.prepaid || !!entry.department,
        ids: [entry.id],
        cost: entry.cost,
      });
    }
  }
  return groups;
};

const CargoCart = (props) => {
  const { act, data } = useBackend<CargoData>();
  const { requestonly, can_approve_requests, points, self_paid } = data;
  const cart = data.cart || [];
  const editable = canEditCart(data) && !!can_approve_requests && !requestonly;
  const groups = groupCart(cart);
  const total = cargoTotal(cart);
  const left = points - total;
  return (
    <NtFrame
      title="Корзина"
      buttons={
        editable &&
        cart.length > 0 && (
          <Button icon="trash" color="transparent" onClick={() => act('clear')}>
            Очистить
          </Button>
        )
      }>
      {cart.length === 0 && (
        <Box color="label" my={2} textAlign="center">
          Корзина пуста: добавьте паки из каталога или одобрите заявки.
        </Box>
      )}
      {cart.length > 0 && (
        <Table>
          <Table.Row header>
            <Table.Cell>Пак</Table.Cell>
            <Table.Cell>Платит</Table.Cell>
            <Table.Cell collapsing textAlign="center">
              Штук
            </Table.Cell>
            <Table.Cell collapsing textAlign="right">
              Сумма
            </Table.Cell>
          </Table.Row>
          {groups.map((group) => (
            <Table.Row key={group.key} className="candystripe">
              <Table.Cell py={0.5}>
                {group.object}
                {!!group.supplier && <span className="NtTerm__tag">{group.supplier}</span>}
              </Table.Cell>
              <Table.Cell py={0.5} color={group.byCargo ? undefined : 'label'}>
                {group.payer}
              </Table.Cell>
              <Table.Cell collapsing py={0.5} textAlign="center" nowrap>
                {editable && (
                  <Button
                    icon="minus"
                    tooltip={group.ids.length > 1 ? 'Снять один' : 'Снять с корзины'}
                    onClick={() => act('remove', { id: group.ids[group.ids.length - 1] })}
                  />
                )}
                <Box inline bold mx={1}>
                  {group.ids.length}
                </Box>
                {editable && group.byCargo && !self_paid && !!group.pack && (
                  <Button icon="plus" tooltip="Ещё один" onClick={() => act('add', { id: group.pack })} />
                )}
              </Table.Cell>
              <Table.Cell collapsing py={0.5} textAlign="right">
                {group.byCargo ? <Credits amount={group.cost} /> : <Box color="label">{group.prepaid ? 'оплачено' : 'при доставке'}</Box>}
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      )}
      {cart.length > 0 && (
        <Box mt={2}>
          <LabeledList>
            <LabeledList.Item label="С бюджета снабжения">
              <Credits amount={total} />
            </LabeledList.Item>
            <LabeledList.Item label="Останется" color={left < 0 ? 'bad' : 'good'}>
              <Credits amount={left} />
            </LabeledList.Item>
          </LabeledList>
          {left < 0 && (
            <NoticeBox warning mt={1}>
              Бюджета не хватает на всё: неоплаченные заказы останутся в корзине до следующего рейса.
            </NoticeBox>
          )}
          <Box mt={1}>
            <ShuttleButton inCart />
          </Box>
        </Box>
      )}
    </NtFrame>
  );
};

const SpecialOffers = (props) => {
  const { act, data } = useBackend<CargoData>();
  const { can_take_offers } = data;
  const offers = data.special_offers || [];
  return (
    <NtFrame
      title="Спецзаказы партнёров"
      help="Спецзаказ платит цену заказа за каждую принятую штуку сразу при отгрузке, а всё сверх неё - маржой при выполнении тому, кто сдал эти штуки: за отгруженное шаттлом - снабжению. Положите накладную спецзаказа в ящик с товаром и отгрузите шаттлом до конца срока. Спецзаказ без пометки контрабанды экипаж может сдать и на паде подработки: тогда оплата и маржа за сданные штуки идут отделу сдавшего. Аванпосты Таркова и Deep Space сдают такие спецзаказы сканером продажи в свой бюджет.">
      {!can_take_offers && (
        <Box className="NtTerm__hint" mb={1}>
          Брать спецзаказы и печатать накладные можно только на консоли снабжения станции.
        </Box>
      )}
      {offers.length === 0 && <NtEmpty>Спецзаказов сейчас нет.</NtEmpty>}
      <Stack vertical>
        {offers.map((offer) => (
          <Stack.Item key={offer.uid}>
            <NtFrame
              minor
              title={`${offer.partner}: ${offer.item}`}
              buttons={
                !!can_take_offers &&
                (offer.accepted ? (
                  <Button icon="print" onClick={() => act('print_offer_manifest', { uid: offer.uid })}>
                    Накладная
                  </Button>
                ) : offer.embargoed ? (
                  <Box inline color="bad">
                    Эмбарго
                  </Box>
                ) : (
                  <Button icon="check" color="good" onClick={() => act('accept_offer', { uid: offer.uid })}>
                    Принять
                  </Button>
                ))
              }>
              <LabeledList>
                <LabeledList.Item label="Нужно">{offer.requirement}</LabeledList.Item>
                <LabeledList.Item label="Принято">
                  <ProgressBar value={offer.delivered} maxValue={offer.quantity}>
                    {offer.delivered} из {offer.quantity}
                  </ProgressBar>
                </LabeledList.Item>
                <LabeledList.Item label="Оплата">
                  <Credits amount={offer.unit_price} /> за штуку при отгрузке, маржа при выполнении до{' '}
                  <Credits amount={offer.premium} /> (сдавшим по штукам), всего <Credits amount={offer.reward} />
                </LabeledList.Item>
                {offer.paid > 0 && (
                  <LabeledList.Item label="Уже выплачено">
                    <Credits amount={offer.paid} />
                  </LabeledList.Item>
                )}
                <LabeledList.Item label={offer.accepted ? 'Срок' : 'Снимут через'}>
                  <Box color={offer.accepted ? 'average' : 'label'}>
                    {formatTime(offer.time_left)}
                    {offer.accepted
                      ? offer.station_involved
                        ? ' - взят, провал отнимет репутацию'
                        : ' - взят аванпостом: провал без штрафа, пока станция не сдавала'
                      : ''}
                  </Box>
                </LabeledList.Item>
                {!!offer.embargoed && (
                  <LabeledList.Item label="Эмбарго">
                    <Box color="bad">
                      {offer.accepted
                        ? 'Партнёр под эмбарго, но взятый спецзаказ можно выполнить.'
                        : 'Партнёр под эмбарго: взять спецзаказ нельзя, пока эмбарго не снимут.'}
                    </Box>
                  </LabeledList.Item>
                )}
                {!!offer.contraband && (
                  <LabeledList.Item label="Отгрузка">
                    <Box color="bad">Только шаттлом с допуском контрабанды</Box>
                  </LabeledList.Item>
                )}
              </LabeledList>
            </NtFrame>
          </Stack.Item>
        ))}
      </Stack>
    </NtFrame>
  );
};

const Bundles = (props) => {
  const { act, data } = useBackend<CargoData>();
  const bundles = data.bundles || [];
  const { self_paid, private_markup = 1, requestonly, can_send } = data;
  const forCargo = !!can_send && !requestonly;
  return (
    <NtFrame
      title="Скупка"
      help="Партнёры распродают пачки разных предметов дешевле, чем по отдельности, но только целиком. Взятая пачка уходит в корзину и из скупки пропадает. Новые пачки появляются раз в 8-15 минут."
      buttons={
        <Button.Checkbox checked={self_paid} onClick={() => act('toggleprivate')}>
          Купить лично
        </Button.Checkbox>
      }>
      {!forCargo && (
        <Box className="NtTerm__hint" mb={1}>
          За бюджет снабжения скупку берёт снабжение с консоли; вы можете купить пачку лично.
        </Box>
      )}
      {bundles.length === 0 && <NtEmpty>Сейчас партнёры ничего не распродают.</NtEmpty>}
      {bundles.map((bundle) => {
        const price = self_paid ? Math.round(bundle.price * private_markup) : bundle.price;
        const canBuy = !!self_paid || forCargo;
        return (
          <Box key={bundle.uid} className="NtTerm__contract">
            <Box className="NtTerm__contractMain">
              <Box className="NtTerm__contractTitle">
                <span className="NtTerm__tag NtTerm__tag--lead">{bundle.partner}</span>
                {bundle.items.length} {plural(bundle.items.length, 'предмет', 'предмета', 'предметов')}, только вместе
              </Box>
              <Box className="NtTerm__hint" mt={0.5}>
                {bundle.items.join(', ')}
              </Box>
            </Box>
            <Box className="NtTerm__contractSide">
              <Box className="NtTerm__hint">
                <s>{formatCredits(bundle.full_value)}</s> −{bundle.discount}%
              </Box>
              <Box className="NtTerm__contractReward">{formatCredits(price)}</Box>
              <Box className={bundle.left < 120 ? 'color-average' : 'NtTerm__hint'}>ещё {formatTime(bundle.left)}</Box>
              <Box mt={0.5}>
                <Button color="good" disabled={!canBuy} onClick={() => act('buy_bundle', { uid: bundle.uid })}>
                  Купить пачкой
                </Button>
              </Box>
            </Box>
          </Box>
        );
      })}
    </NtFrame>
  );
};

/** Ставку игрока перебили, пока окно открыто: сказать об этом, пока он не поставит снова. */
const useOutbid = (lot: AuctionLot | null | undefined) => {
  const previous = useRef<{ uid: number; mine: boolean } | null>(null);
  const [outbid, setOutbid] = useState<string | null>(null);
  useEffect(() => {
    const was = previous.current;
    previous.current = lot ? { uid: lot.uid, mine: !!lot.mine } : null;
    if (!lot || lot.mine || (was && was.uid !== lot.uid)) {
      setOutbid(null);
    } else if (was?.mine) {
      setOutbid(`Вашу ставку перебили: ${lot.bidder}, ${formatCredits(lot.bid)}; ваши деньги вернулись на счёт.`);
    }
  }, [lot?.uid, lot?.mine, lot?.bid]);
  return outbid;
};

const Auction = (props) => {
  const { act, data } = useBackend<CargoData>();
  const lot = data.auction;
  const results = data.auction_results || [];
  const [amount, setAmount] = useState<number | null>(null);
  const outbid = useOutbid(lot);
  const minBid = lot?.min_bid || 0;
  const bid = Math.max(amount ?? minBid, minBid);
  return (
    <>
      {lot ? (
        <NtFrame
          title={`Лот: ${lot.name}`}
          help="Ставка идёт с личного счёта и замораживается до конца торгов; если её перебьют, деньги сразу вернутся. Ставка в последнюю минуту продлевает торги до минуты. Выигранный лот прилетит капсулой на склад снабжения."
          buttons={
            <Box inline className="NtTerm__num" color={lot.left < 60 ? 'average' : 'label'}>
              осталось {formatTime(lot.left)}
            </Box>
          }>
          <Box className="NtTerm__hint" mb={1}>
            {lot.desc}
          </Box>
          <NtLine label="Оценка лота">{formatCredits(lot.value)}</NtLine>
          {!!outbid && <NoticeBox warning>{outbid}</NoticeBox>}
          <NtLine label="Текущая ставка" tone={lot.mine ? 'good' : lot.bid ? 'warn' : 'dim'}>
            <NtPulse value={lot.bid} neutral>
              {lot.bid ? `${formatCredits(lot.bid)} - ${lot.mine ? 'ваша' : lot.bidder}` : `ставок нет, старт ${formatCredits(lot.min_bid)}`}
            </NtPulse>
          </NtLine>
          <NtLine label="Торгуются ещё">{lot.rivals} станции сектора</NtLine>
          <Stack align="center" mt={1.5} wrap>
            <Stack.Item>
              <RestrictedInput width="7em" value={bid} minValue={minBid} maxValue={100000} onChange={(_, value) => setAmount(value)} /> кр.
            </Stack.Item>
            <Stack.Item>
              <Button onClick={() => setAmount(minBid)}>Минимум</Button>
              <Button onClick={() => setAmount(minBid + lot.increment * 2)}>+2 шага</Button>
            </Stack.Item>
            <Stack.Item>
              <Button color="good" icon="gavel" onClick={() => act('auction_bid', { uid: lot.uid, amount: bid })}>
                {`Поставить ${formatCredits(bid)}`}
              </Button>
            </Stack.Item>
            {data.my_balance !== null && data.my_balance !== undefined && (
              <Stack.Item className="NtTerm__hint">на счёте {formatCredits(data.my_balance)}</Stack.Item>
            )}
          </Stack>
          {lot.history.length > 0 && (
            <Box mt={1.5}>
              <Box className="NtTerm__hint" mb={0.5}>
                Ставки:
              </Box>
              {lot.history.map((entry, index) => (
                <NtLine key={`${entry.who}-${entry.amount}-${index}`} label={entry.who} tone={index === 0 ? undefined : 'dim'}>
                  {formatCredits(entry.amount)}
                </NtLine>
              ))}
            </Box>
          )}
        </NtFrame>
      ) : (
        <NtFrame title="Аукцион сектора">
          <NtEmpty>
            Сейчас лотов нет.{!!data.auction_next && ` Следующий - примерно через ${formatTime(data.auction_next)}.`} О новом лоте
            сообщит канал Сводка сектора на ньюскастерах.
          </NtEmpty>
        </NtFrame>
      )}
      {results.length > 0 && (
        <NtFrame title="Прошлые лоты">
          {results.map((result, index) => (
            <NtLine key={`${result.name}-${index}`} label={result.name} tone={result.ours ? 'good' : 'dim'}>
              {result.winner ? `${result.ours ? 'наша станция: ' : ''}${result.winner}, ${formatCredits(result.price)}` : 'снят без ставок'}
            </NtLine>
          ))}
        </NtFrame>
      )}
    </>
  );
};

const factorColor = (factor: number) => (factor > 1 ? 'good' : factor < 1 ? 'bad' : undefined);

const Market = (props) => {
  const { data } = useBackend<CargoData>();
  const market = data.market || { commodities: [], price_index: 1 };
  return (
    <NtFrame
      title="Рынок товаров"
      help="Закупка - во сколько раз паки товара дороже базы. Продажа - во сколько раз NT и лучший покупатель платят за груз против базы, с учётом спроса: продажи выбивают спрос, сдвиги рынка его восстанавливают. Горячий товар продаётся дороже, пока не остынет. Индекс цен двигает цены торговых автоматов."
      buttons={<Box inline>Индекс цен: ×{market.price_index}</Box>}>
      <Table>
        <Table.Row header>
          <Table.Cell>Товар</Table.Cell>
          <Table.Cell collapsing>Тренд</Table.Cell>
          <Table.Cell collapsing textAlign="right">
            Закупка
          </Table.Cell>
          <Table.Cell collapsing textAlign="right">
            Продажа
          </Table.Cell>
          <Table.Cell collapsing textAlign="right">
            Спрос
          </Table.Cell>
          <Table.Cell pl={1}>Покупатель</Table.Cell>
        </Table.Row>
        {market.commodities.map((commodity) => (
          <Table.Row key={commodity.id} className="candystripe">
            <Table.Cell py={0.5}>
              {commodity.name}
              {commodity.hot > 0 && (
                <Box inline ml={1} color="average">
                  горячий ×{commodity.hot}
                </Box>
              )}
            </Table.Cell>
            <Table.Cell collapsing py={0.5}>
              {commodity.history.length > 1 ? (
                <Sparkline values={commodity.history} />
              ) : (
                <Tooltip content="Тренд появится после первого сдвига рынка, примерно через 5 минут смены.">
                  <Box inline color="label">
                    —
                  </Box>
                </Tooltip>
              )}
            </Table.Cell>
            <Table.Cell collapsing textAlign="right" py={0.5}>
              ×{commodity.factor}
            </Table.Cell>
            <Table.Cell collapsing textAlign="right" py={0.5} color={factorColor(commodity.sell)}>
              ×{commodity.sell}
            </Table.Cell>
            <Table.Cell collapsing textAlign="right" py={0.5}>
              {commodity.demand}%
            </Table.Cell>
            <Table.Cell py={0.5} pl={1} color={commodity.buyer ? undefined : 'bad'}>
              {commodity.buyer || 'нет покупателя, груз вернётся'}
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
    </NtFrame>
  );
};

const Partners = (props) => {
  const { data } = useBackend<CargoData>();
  const { tier_step = 1, tier_max = 1 } = data;
  const partners = data.partners || [];
  return (
    <NtFrame
      title="Торговые партнёры"
      help={`Паки везёт самый дешёвый открытый партнёр, у которого они есть на складе. Репутация растёт от продаж и закупок, каждые ${tier_step} очков - новая ступень и скидка; репутация у одних партнёров открывает других.`}>
      <Stack vertical>
        {partners.map((partner) => {
          const maxed = partner.tier >= tier_max;
          const progress = maxed ? tier_step : partner.reputation - partner.tier * tier_step;
          const trades = !!partner.buys || !!partner.sells;
          return (
            <Stack.Item key={partner.id}>
              <NtFrame
                minor
                title={
                  <>
                    <EconomyLogo id={partner.id} />
                    {partner.name}
                  </>
                }
                buttons={
                  !trades ? (
                    <Box inline color="label">
                      только спецзаказы
                    </Box>
                  ) : (
                    <Box inline color={partner.unlocked ? 'good' : 'label'}>
                      {partner.unlocked ? `Ступень ${partner.tier} из ${tier_max}` : 'Закрыт'}
                    </Box>
                  )
                }>
                <Box className="NtTerm__hint" mb={1}>
                  {partner.desc}
                </Box>
                {!!partner.embargo_minutes && (
                  <NoticeBox danger>Эмбарго: ещё {partner.embargo_minutes} мин. партнёр не покупает и не продаёт.</NoticeBox>
                )}
                {!!partner.next_unlock && <NoticeBox>{partner.next_unlock}</NoticeBox>}
                {trades && (
                  <LabeledList>
                    {!partner.next_unlock && (
                      <>
                        <LabeledList.Item label="Репутация">
                          <ProgressBar value={progress} maxValue={tier_step}>
                            {maxed
                              ? `${partner.reputation} - высшая ступень`
                              : `${partner.reputation}, до ступени ${partner.tier + 1}: ${tier_step - progress}`}
                          </ProgressBar>
                        </LabeledList.Item>
                        <LabeledList.Item label="Цены">
                          наценка ×{partner.markup}, скидка за репутацию {partner.discount}%
                        </LabeledList.Item>
                        <LabeledList.Item label="Капитал">
                          <Credits amount={partner.wealth} /> - из него пополняется склад
                        </LabeledList.Item>
                      </>
                    )}
                    <LabeledList.Item label="Покупает">{partner.buys || '-'}</LabeledList.Item>
                    <LabeledList.Item label="Продаёт">{partner.sells || '-'}</LabeledList.Item>
                  </LabeledList>
                )}
              </NtFrame>
            </Stack.Item>
          );
        })}
      </Stack>
    </NtFrame>
  );
};

const Contracts = (props) => {
  const { data } = useBackend<CargoData>();
  return (
    <NtFrame
      title="Контракты NT"
      help={
        data.contracts_help_topics?.length ? (
          <NtHelpTopics
            topics={[
              { title: 'Где взять', lines: ['На консоли контрактов, в пункте подработки или в приложении "Бюджет отдела".'] },
              ...data.contracts_help_topics,
            ]}
          />
        ) : undefined
      }>
      <ContractTable readOnly />
    </NtFrame>
  );
};

const CargoHelp = (props) => {
  const { data } = useBackend<CargoData>();
  const topics = data.help_topics || (data.market_help ? [{ title: 'Как работает рынок', icon: 'info-circle', lines: [data.market_help] }] : []);
  if (!topics.length) {
    return (
      <NtFrame title="Справка">
        <Box color="label">Справки для этой консоли нет.</Box>
      </NtFrame>
    );
  }
  return (
    <Stack vertical>
      {topics.map((topic) => (
        <Stack.Item key={topic.title}>
          <NtFrame title={topic.title} buttons={<Icon name={topic.icon} color="label" />}>
            {topic.lines.map((line) => (
              <Box key={line} mb={0.75}>
                {line}
              </Box>
            ))}
          </NtFrame>
        </Stack.Item>
      ))}
    </Stack>
  );
};

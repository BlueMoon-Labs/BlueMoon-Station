import { toArray } from 'common/collections';
import { BooleanLike } from 'common/react';
import { createSearch } from 'common/string';
import { useState } from 'react';

import { useBackend } from '../backend';
import {
  AnimatedNumber,
  Box,
  Button,
  Collapsible,
  Flex,
  Input,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
  Table,
  Tabs,
} from '../components';
import { Window } from '../layouts';
import { ContractTable } from './common/ContractTable';
import { ContractEntry, Credits, EconomyLogo, formatCredits, OfferEntry, Sparkline } from './common/Economy';

type Pack = {
  name: string;
  id: string;
  desc: string;
  cost?: number;
  goody?: BooleanLike;
  access?: BooleanLike;
  private_goody?: BooleanLike;
  can_private_buy?: BooleanLike;
  personal?: BooleanLike;
  commodity?: string | null;
  supplier?: string | null;
  in_stock?: BooleanLike;
};

/** Цена, id поставщика и наличие пака: приходят отдельно от каталога и обновляются после пересчёта цен. */
type PackPrice = [number, string | null, BooleanLike];

const withPrice = (pack: Pack, prices?: Record<string, PackPrice>, partners?: Partner[]): Pack => {
  const price = prices?.[pack.id];
  if (!price) {
    return pack;
  }
  const supplier = price[1] && (partners?.find((partner) => partner.id === price[1])?.name || price[1]);
  return { ...pack, cost: price[0], supplier, in_stock: price[2] };
};

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

type CargoData = {
  location: string;
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
  manifest_department?: string | null;
  manifest_fee?: number;
  market_help?: string;
  contracts_help?: string;
  private_markup?: number;
  reason_max?: number;
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
};

const formatTime = (seconds: number) => `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`;

const canEditCart = (data: CargoData) => !!(data.can_edit_cart ?? data.can_send);

export const Cargo = (props) => {
  return (
    <Window width={860} height={760} resizable>
      <Window.Content scrollable>
        <CargoContent />
      </Window.Content>
    </Window>
  );
};

export const CargoContent = (props) => {
  const { data } = useBackend<CargoData>();
  const [tab, setTab] = useState('catalog');
  const { requestonly, market_help } = data;
  const cart = data.cart || [];
  const requests = data.requests || [];
  const departmentOrders = data.department_requests || [];
  const offers = data.special_offers || [];
  const tabs: [string, string, string][] = [
    ['catalog', 'list', 'Каталог'],
    ['requests', 'envelope', `Заявки (${requests.length})`],
    ...(requestonly ? [] : [['cart', 'shopping-cart', `Корзина (${cart.length})`] as [string, string, string]]),
    ['departments', 'building', `Заказы отделов (${departmentOrders.length})`],
    ['offers', 'handshake', `Спецзаказы (${offers.length})`],
    ['market', 'chart-line', 'Рынок'],
    ['partners', 'users', 'Партнёры'],
    ['contracts', 'file-signature', 'Контракты'],
  ];
  return (
    <Box>
      <CargoStatus />
      {!!market_help && (
        <Collapsible title="Как работают цены, партнёры и спецзаказы">
          <NoticeBox info>{market_help}</NoticeBox>
        </Collapsible>
      )}
      <Section fitted>
        <Tabs>
          {tabs.map(([key, icon, label]) => (
            <Tabs.Tab key={key} icon={icon} selected={tab === key} onClick={() => setTab(key)}>
              {label}
            </Tabs.Tab>
          ))}
        </Tabs>
      </Section>
      {tab === 'catalog' && <CargoCatalog />}
      {tab === 'requests' && <CargoRequests />}
      {tab === 'cart' && <CargoCart />}
      {tab === 'departments' && <DepartmentOrders />}
      {tab === 'offers' && <SpecialOffers />}
      {tab === 'market' && <Market />}
      {tab === 'partners' && <Partners />}
      {tab === 'contracts' && <Contracts />}
    </Box>
  );
};

const CargoStatus = (props) => {
  const { act, data } = useBackend<CargoData>();
  const {
    away,
    docked,
    loan,
    loan_dispatched,
    location,
    message,
    points,
    requestonly,
    can_send,
    manifest_department,
    manifest_fee,
    is_app,
  } = data;
  return (
    <Section
      title="Снабжение"
      buttons={
        <Box inline bold>
          {'Бюджет снабжения: '}
          <AnimatedNumber value={points} format={(value) => formatCredits(value)} />
        </Box>
      }>
      <LabeledList>
        <LabeledList.Item label="Шаттл">
          {docked && !requestonly && can_send ? <Button content={location} onClick={() => act('send')} /> : location}
          {!!is_app && (
            <Box color="label">Шаттл, его аренда и спецзаказы - только с консоли снабжения.</Box>
          )}
        </LabeledList.Item>
        {!!manifest_department && (
          <LabeledList.Item label="Экспорт">
            <Button
              icon="file-invoice"
              content={`Накладная: ${manifest_department}`}
              tooltip={`Положите накладную в ящик перед отгрузкой: выручка за ящик уйдёт отделу за вычетом сбора снабжения (${manifest_fee}%).`}
              onClick={() => act('print_manifest')}
            />
          </LabeledList.Item>
        )}
        <LabeledList.Item label="Сообщение ЦК">{message}</LabeledList.Item>
        {!!loan && !requestonly && !is_app && (
          <LabeledList.Item label="Аренда шаттла">
            {loan_dispatched ? (
              <Box color="bad">Шаттл у ЦК</Box>
            ) : (
              <Button content="Сдать шаттл ЦК" disabled={!(away && docked)} onClick={() => act('loan')} />
            )}
          </LabeledList.Item>
        )}
      </LabeledList>
    </Section>
  );
};

export const CargoCatalog = (props: { express?: boolean }) => {
  const { express } = props;
  const { act, data } = useBackend<CargoData>();
  const { self_paid, private_markup = 1, requestonly, reason_max } = data;
  const supplies = toArray(data.supplies) as SupplyGroup[];
  const [activeSupplyName, setActiveSupplyName] = useState(supplies[0]?.name);
  const [searchText, setSearchText] = useState('');
  const activeSupply = supplies.find((supply) => supply.name === activeSupplyName);
  const searchFn = createSearch(searchText, (pack: Pack) => pack.name + ' ' + pack.desc);
  const isSearching = searchText.length >= 2;
  const displayedPacks = isSearching
    ? supplies
        .flatMap((supply) => supply.packs)
        .filter((pack, index, all) => all.findIndex((other) => other.id === pack.id) === index)
        .filter(searchFn)
    : activeSupply?.packs || [];
  const [reason, setReason] = useState('');
  const markupPercent = Math.round((private_markup - 1) * 100);
  const privateHint = express
    ? 'Оплата с вашего счёта сразу при заказе, без наценки частного заказа.'
    : 'Оплата с вашего счёта при доставке.' +
      (markupPercent > 0 ? ` Частный заказ дороже на ${markupPercent}%, наценка идёт снабжению; малые кейсы и личный каталог - без наценки.` : '');
  const asRequest = !!requestonly && !self_paid;
  const order = (pack: Pack) =>
    act('add', asRequest && reason.trim() ? { id: pack.id, reason: reason.trim() } : { id: pack.id });
  return (
    <Section
      title="Каталог"
      buttons={
        <>
          {!express && <CargoCartButtons />}
          <Input
            placeholder="Поиск..."
            value={searchText}
            onInput={(e, value) => setSearchText(value)}
            mx={1}
          />
          <Button.Checkbox
            ml={1}
            content="Купить лично"
            checked={self_paid}
            tooltip={privateHint}
            onClick={() => act('toggleprivate')}
          />
        </>
      }>
      <Flex>
        <Flex.Item ml={-1} mr={1}>
          <Tabs vertical>
            {supplies.map((supply) => (
              <Tabs.Tab
                key={supply.name}
                selected={!isSearching && supply.name === activeSupplyName}
                onClick={() => {
                  setActiveSupplyName(supply.name);
                  setSearchText('');
                }}>
                {supply.name} ({supply.packs.length})
              </Tabs.Tab>
            ))}
          </Tabs>
        </Flex.Item>
        <Flex.Item grow={1} basis={0}>
          {asRequest && (
            <Box mb={1}>
              <Box inline color="label" mr={1}>
                Причина заявки:
              </Box>
              <Input
                width="60%"
                maxLength={reason_max}
                placeholder="Если оставить пустой, консоль спросит при заказе"
                value={reason}
                onInput={(e, value) => setReason(value)}
              />
            </Box>
          )}
          {isSearching && (
            <Box color="label" mb={1}>
              Найдено: {displayedPacks.length}
            </Box>
          )}
          <Table>
            <Table.Row header>
              <Table.Cell>Пак</Table.Cell>
              <Table.Cell collapsing />
              <Table.Cell collapsing>Поставщик</Table.Cell>
              <Table.Cell collapsing textAlign="right">
                Цена
              </Table.Cell>
            </Table.Row>
            {displayedPacks.map((listed) => {
              const pack = withPrice(listed, data.prices, data.partners);
              const tags: string[] = [];
              if (pack.goody) {
                tags.push('Малый кейс');
              }
              if (pack.access) {
                tags.push('Доступ');
              }
              if (pack.personal) {
                tags.push('Без наценки');
              }
              const priced = typeof pack.cost === 'number';
              const outOfStock = !priced || (pack.in_stock !== undefined && !pack.in_stock);
              const cost = self_paid && !pack.goody && !pack.personal ? Math.round((pack.cost || 0) * private_markup) : pack.cost || 0;
              return (
                <Table.Row key={pack.id} className="candystripe">
                  <Table.Cell>
                    {pack.name}
                    {!!pack.commodity && (
                      <Box inline color="label" ml={1}>
                        ({pack.commodity})
                      </Box>
                    )}
                  </Table.Cell>
                  <Table.Cell collapsing color="label" textAlign="right">
                    {tags.join(', ')}
                  </Table.Cell>
                  <Table.Cell collapsing>
                    {outOfStock ? <Box color="bad">нет в наличии</Box> : pack.supplier || '-'}
                  </Table.Cell>
                  <Table.Cell collapsing textAlign="right">
                    <Button
                      fluid
                      disabled={outOfStock}
                      tooltip={outOfStock ? 'Ни у одного открытого партнёра нет на складе: ждите пополнения.' : pack.desc}
                      tooltipPosition="left"
                      onClick={() => order(pack)}>
                      {priced ? formatCredits(cost) : '-'}
                    </Button>
                  </Table.Cell>
                </Table.Row>
              );
            })}
          </Table>
        </Flex.Item>
      </Flex>
    </Section>
  );
};

const CargoRequests = (props) => {
  const { act, data } = useBackend<CargoData>();
  const { requestonly, can_send, can_approve_requests } = data;
  const requests = data.requests || [];
  return (
    <Section
      title="Заявки в снабжение"
      buttons={
        !requestonly && (
          <Button icon="times" content="Отклонить все" color="transparent" onClick={() => act('denyall')} />
        )
      }>
      {requests.length === 0 && <Box color="good">Заявок нет.</Box>}
      {requests.length > 0 && (
        <Table>
          {requests.map((request) => (
            <Table.Row key={request.id} className="candystripe">
              <Table.Cell collapsing color="label">
                #{request.id}
              </Table.Cell>
              <Table.Cell>{request.object}</Table.Cell>
              <Table.Cell>
                <b>{request.orderer}</b>
              </Table.Cell>
              <Table.Cell width="25%">
                <i>{request.reason}</i>
              </Table.Cell>
              <Table.Cell collapsing textAlign="right">
                <Credits amount={request.cost} />
              </Table.Cell>
              {(!requestonly || !!can_send) && !!can_approve_requests && (
                <Table.Cell collapsing>
                  <Button icon="check" color="good" content="Одобрить" onClick={() => act('approve', { id: request.id })} />
                  <Button icon="times" color="bad" content="Отклонить" onClick={() => act('deny', { id: request.id })} />
                </Table.Cell>
              )}
            </Table.Row>
          ))}
        </Table>
      )}
    </Section>
  );
};

const CargoCartButtons = (props) => {
  const { act, data } = useBackend<CargoData>();
  const { requestonly, can_approve_requests } = data;
  const cart = data.cart || [];
  const total = cart.reduce((sum, entry) => sum + entry.cost, 0);
  if (requestonly || !canEditCart(data) || !can_approve_requests) {
    return null;
  }
  return (
    <>
      <Box inline mx={1}>
        {cart.length === 0 ? 'Корзина пуста' : `В корзине: ${cart.length}`}
        {total > 0 && ` (${formatCredits(total)})`}
      </Box>
      <Button icon="times" color="transparent" content="Очистить" onClick={() => act('clear')} />
    </>
  );
};

const CargoCart = (props) => {
  const { act, data } = useBackend<CargoData>();
  const { requestonly, away, docked, location, can_send } = data;
  const cart = data.cart || [];
  return (
    <Section title="Корзина" buttons={<CargoCartButtons />}>
      {cart.length === 0 && <Box color="label">Корзина пуста.</Box>}
      {cart.length > 0 && (
        <Table>
          {cart.map((entry) => (
            <Table.Row key={entry.id} className="candystripe">
              <Table.Cell collapsing color="label">
                #{entry.id}
              </Table.Cell>
              <Table.Cell>{entry.object}</Table.Cell>
              <Table.Cell collapsing>{!!entry.paid && <b>[Частный заказ]</b>}</Table.Cell>
              <Table.Cell collapsing textAlign="right">
                <Credits amount={entry.cost} />
              </Table.Cell>
              <Table.Cell collapsing>
                {canEditCart(data) && (
                  <Button icon="minus" tooltip="Снять с корзины" onClick={() => act('remove', { id: entry.id })} />
                )}
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      )}
      {cart.length > 0 && !requestonly && !!can_send && (
        <Box mt={2}>
          {away && docked ? (
            <Button color="green" content="Вызвать шаттл с заказом" onClick={() => act('send')} />
          ) : (
            <Box opacity={0.5}>Шаттл: {location}.</Box>
          )}
        </Box>
      )}
    </Section>
  );
};

const DepartmentOrders = (props) => {
  const { act, data } = useBackend<CargoData>();
  const orders = data.department_requests || [];
  return (
    <Section title="Заказы отделов">
      <Box color="label" mb={1}>
        Отделы оплатили эти заказы из своего бюджета по заявкам, одобренным главой. Снабжение их только везёт: они уйдут
        со следующим шаттлом, а снятие с корзины вернёт деньги отделу.
      </Box>
      {orders.length === 0 && <Box color="good">Заказов отделов в очереди нет.</Box>}
      {orders.length > 0 && (
        <Table>
          <Table.Row header>
            <Table.Cell>Отдел</Table.Cell>
            <Table.Cell>Пак</Table.Cell>
            <Table.Cell>Заказал</Table.Cell>
            <Table.Cell>Причина</Table.Cell>
            <Table.Cell collapsing textAlign="right">
              Оплачено
            </Table.Cell>
            <Table.Cell collapsing />
          </Table.Row>
          {orders.map((order) => (
            <Table.Row key={order.id} className="candystripe">
              <Table.Cell>{order.department}</Table.Cell>
              <Table.Cell>{order.object}</Table.Cell>
              <Table.Cell>{order.orderer}</Table.Cell>
              <Table.Cell>
                <i>{order.reason}</i>
              </Table.Cell>
              <Table.Cell collapsing textAlign="right">
                <Credits amount={order.prepaid} />
              </Table.Cell>
              <Table.Cell collapsing>
                {canEditCart(data) && (
                  <Button icon="undo" tooltip="Снять и вернуть деньги отделу" onClick={() => act('remove', { id: order.id })} />
                )}
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      )}
    </Section>
  );
};

const SpecialOffers = (props) => {
  const { act, data } = useBackend<CargoData>();
  const { can_take_offers } = data;
  const offers = data.special_offers || [];
  return (
    <Section title="Спецзаказы партнёров">
      <Box color="label" mb={1}>
        Спецзаказ платит цену заказа за каждую принятую штуку сразу при отгрузке, а всё сверх неё - снабжению маржой при
        выполнении. Положите накладную спецзаказа в ящик с товаром и отгрузите шаттлом до конца срока.
        {!can_take_offers && ' Брать спецзаказы и печатать накладные можно только на консоли снабжения станции.'}
      </Box>
      {offers.length === 0 && <Box color="label">Спецзаказов сейчас нет.</Box>}
      <Stack vertical>
        {offers.map((offer) => (
          <Stack.Item key={offer.uid}>
            <Section
              title={`${offer.partner}: ${offer.item}`}
              buttons={
                !!can_take_offers &&
                (offer.accepted ? (
                  <Button icon="print" content="Накладная" onClick={() => act('print_offer_manifest', { uid: offer.uid })} />
                ) : offer.embargoed ? (
                  <Box inline color="bad">
                    Эмбарго
                  </Box>
                ) : (
                  <Button icon="check" color="good" content="Принять" onClick={() => act('accept_offer', { uid: offer.uid })} />
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
                  <Credits amount={offer.unit_price} /> за штуку при отгрузке, маржа снабжению{' '}
                  <Credits amount={offer.premium} />, всего <Credits amount={offer.reward} />
                </LabeledList.Item>
                {offer.paid > 0 && (
                  <LabeledList.Item label="Уже выплачено">
                    <Credits amount={offer.paid} />
                  </LabeledList.Item>
                )}
                <LabeledList.Item label={offer.accepted ? 'Срок' : 'Снимут через'}>
                  <Box color={offer.accepted ? 'average' : 'label'}>
                    {formatTime(offer.time_left)}
                    {offer.accepted ? ' - взят, провал отнимет репутацию' : ''}
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
            </Section>
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

const factorColor = (factor: number) => (factor > 1 ? 'good' : factor < 1 ? 'bad' : undefined);

const Market = (props) => {
  const { data } = useBackend<CargoData>();
  const market = data.market || { commodities: [], price_index: 1 };
  return (
    <Section title="Рынок товаров" buttons={<Box inline>Индекс цен: ×{market.price_index}</Box>}>
      <Box color="label" mb={1}>
        Закупка - во сколько раз паки товара дороже базы. Продажа - во сколько раз NT и лучший покупатель платят за груз
        против базы, с учётом спроса: продажи выбивают спрос, сдвиги рынка его восстанавливают. Горячий товар продаётся
        дороже, пока не остынет. Индекс цен двигает цены торговых автоматов.
      </Box>
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
          <Table.Cell>Покупатель</Table.Cell>
        </Table.Row>
        {market.commodities.map((commodity) => (
          <Table.Row key={commodity.id} className="candystripe">
            <Table.Cell>
              {commodity.name}
              {commodity.hot > 0 && (
                <Box inline ml={1} bold color="orange">
                  горячий ×{commodity.hot}
                </Box>
              )}
            </Table.Cell>
            <Table.Cell collapsing>
              <Sparkline values={commodity.history} />
            </Table.Cell>
            <Table.Cell collapsing textAlign="right">
              ×{commodity.factor}
            </Table.Cell>
            <Table.Cell collapsing textAlign="right" color={factorColor(commodity.sell)}>
              ×{commodity.sell}
            </Table.Cell>
            <Table.Cell collapsing textAlign="right">
              {commodity.demand}%
            </Table.Cell>
            <Table.Cell color={commodity.buyer ? undefined : 'bad'}>
              {commodity.buyer || 'нет покупателя, груз вернётся'}
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
    </Section>
  );
};

const Partners = (props) => {
  const { data } = useBackend<CargoData>();
  const { tier_step = 1, tier_max = 1 } = data;
  const partners = data.partners || [];
  return (
    <Section title="Торговые партнёры">
      <Box color="label" mb={1}>
        Паки везёт самый дешёвый открытый партнёр, у которого они есть на складе. Репутация растёт от продаж и закупок,
        каждые {tier_step} очков - новая ступень и скидка; репутация у одних партнёров открывает других.
      </Box>
      <Stack vertical>
        {partners.map((partner) => {
          const maxed = partner.tier >= tier_max;
          const progress = maxed ? tier_step : partner.reputation - partner.tier * tier_step;
          return (
            <Stack.Item key={partner.id}>
              <Section
                title={partner.name}
                buttons={
                  <Box inline color={partner.unlocked ? 'good' : 'label'}>
                    {partner.unlocked ? `Ступень ${partner.tier} из ${tier_max}` : 'Закрыт'}
                  </Box>
                }>
                <Box italic color="label" mb={1}>
                  <EconomyLogo id={partner.id} />
                  {partner.desc}
                </Box>
                {!!partner.embargo_minutes && (
                  <NoticeBox danger>
                    Эмбарго: ещё {partner.embargo_minutes} мин. партнёр не покупает и не продаёт.
                  </NoticeBox>
                )}
                {partner.next_unlock ? (
                  <NoticeBox>{partner.next_unlock}</NoticeBox>
                ) : (
                  <LabeledList>
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
                  </LabeledList>
                )}
                <LabeledList>
                  <LabeledList.Item label="Покупает">{partner.buys || '-'}</LabeledList.Item>
                  <LabeledList.Item label="Продаёт">{partner.sells || '-'}</LabeledList.Item>
                </LabeledList>
              </Section>
            </Stack.Item>
          );
        })}
      </Stack>
    </Section>
  );
};

const Contracts = (props) => {
  const { data } = useBackend<CargoData>();
  return (
    <Section title="Контракты NT">
      {!!data.contracts_help && (
        <Box color="label" mb={1}>
          {data.contracts_help} Взять контракт можно на консоли контрактов, в пункте подработки или в приложении «Бюджет отдела».
        </Box>
      )}
      <ContractTable readOnly />
    </Section>
  );
};

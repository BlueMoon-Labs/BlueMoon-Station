import { BooleanLike } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../backend';
import { AnimatedNumber, Box, Button, Stack } from '../components';
import { Window } from '../layouts';
import { formatCredits } from './common/Economy';
import { NtEmpty, NtFrame, NtHelpTopics, NtLine, NtMenu, NtReadout, NtScreen } from './common/NtTerminal';

type Kind = 'food' | 'drink';

type MenuEntry = {
  id: string;
  name: string;
  kind: Kind;
  price: number;
};

type DecorSet = {
  id: string;
  name: string;
  desc: string;
  price: number;
  max: number;
};

type Order = {
  uid: number;
  name: string;
  kind: Kind;
  count: number;
  total: number;
  minutes_left: number;
  taken: BooleanLike;
  mine: BooleanLike;
};

type TipOffer = {
  uid: number;
  name: string;
  staff: string;
};

export type RoomServiceData = {
  menu: MenuEntry[];
  decor: DecorSet[];
  catering_mult: number;
  wait_minutes: number;
  claim_minutes: number;
  tip_amounts: number[];
  count_max: number;
  orders_max: number;
  room: number;
  open: BooleanLike;
  account_problem: string | null;
  has_account: BooleanLike;
  balance: number;
  staff: Record<Kind, BooleanLike>;
  catering: Record<Kind, BooleanLike>;
  /** Блюдо дня от шефа: только заказом повару */
  special: MenuEntry | null;
  orders: Order[];
  tips: TipOffer[];
  /** Пустой список приходит из DM массивом */
  decor_bought: Record<string, number> | [];
};

type Tab = Kind | 'decor';

const STAFF: Record<Kind, string> = { food: 'Повар', drink: 'Бармен' };

const lineName = (name: string, count: number) => (count > 1 ? `${name} x${count}` : name);

const Orders = () => {
  const { act, data } = useBackend<RoomServiceData>();
  if (!data.orders.length) {
    return null;
  }
  return (
    <NtFrame title="Ждут доставки">
      {data.orders.map((order) => (
        <Stack key={order.uid} align="center" className="NtTerm__line">
          <Stack.Item grow>
            №{order.uid}: {lineName(order.name, order.count)}
          </Stack.Item>
          <Stack.Item className="NtTerm__hint">{order.taken ? `${STAFF[order.kind]} принял заказ, ` : 'ждёт сервис, '}ещё {order.minutes_left} мин.</Stack.Item>
          <Stack.Item shrink={0} width="5.5em" textAlign="right">
            {formatCredits(order.total)}
          </Stack.Item>
          {!!order.mine && (
            <Stack.Item>
              <Button icon="times" color="transparent" tooltip="Отменить, деньги вернутся" onClick={() => act('cancel', { uid: order.uid })}>
                Отменить
              </Button>
            </Stack.Item>
          )}
        </Stack>
      ))}
    </NtFrame>
  );
};

const Tips = () => {
  const { act, data } = useBackend<RoomServiceData>();
  if (!data.tips.length) {
    return null;
  }
  return (
    <NtFrame title="Чаевые за доставку">
      {data.tips.map((tip) => (
        <Stack key={tip.uid} align="center" className="NtTerm__line">
          <Stack.Item grow>
            №{tip.uid}: {tip.name}, доставка - {tip.staff}
          </Stack.Item>
          {data.tip_amounts.map((amount) => (
            <Stack.Item key={amount}>
              <Button icon="heart" disabled={!!data.account_problem} onClick={() => act('tip', { uid: tip.uid, amount })}>
                {formatCredits(amount)}
              </Button>
            </Stack.Item>
          ))}
        </Stack>
      ))}
    </NtFrame>
  );
};

const routeText = (data: RoomServiceData, kind: Kind) => {
  const staff = STAFF[kind];
  if (!data.staff[kind]) {
    return `${staff}а нет на смене: NT пришлёт готовое сразу, в ${data.catering_mult} раза дороже.`;
  }
  const text = `${staff} на смене: заказ уйдёт ему, он возьмёт его, приготовит и пришлёт в номер. Деньги спишутся сразу и вернутся, если заказ никто не возьмёт за ${data.claim_minutes} мин. или не доставят за ${data.wait_minutes} мин.`;
  return data.catering[kind] ? `${text} Сервис уже не успел с прошлым заказом, поэтому можно взять и готовое у NT, в ${data.catering_mult} раза дороже.` : text;
};

const MenuTab = (props: { kind: Kind }) => {
  const { act, data } = useBackend<RoomServiceData>();
  const { kind } = props;
  const [count, setCount] = useState(1);
  const staff = !!data.staff[kind];
  const catering = !!data.catering[kind];
  const full = data.orders.length >= data.orders_max;
  const blocked = !!data.account_problem;
  const special = kind === 'food' && staff ? data.special : null;
  return (
    <>
      <div className="NtTerm__help">{routeText(data, kind)}</div>
      {staff && full && (
        <Box color="average" mb={1}>
          Доставки уже ждут {data.orders_max} заказа номера: новый - когда привезут или отмените один.
        </Box>
      )}
      <Stack align="center" mb={1}>
        <Stack.Item grow>Сколько штук</Stack.Item>
        <Stack.Item>
          <Button icon="minus" disabled={count <= 1} onClick={() => setCount(count - 1)} />
          <Box inline bold width="2em" textAlign="center">
            {count}
          </Box>
          <Button icon="plus" disabled={count >= data.count_max} onClick={() => setCount(count + 1)} />
        </Stack.Item>
      </Stack>
      {special && (
        <Stack align="center" className="NtTerm__line">
          <Stack.Item grow bold>
            {lineName(special.name, count)}
          </Stack.Item>
          <Stack.Item>
            <Button icon="star" disabled={blocked || full} onClick={() => act('order', { id: special.id, count, route: 'staff' })}>
              {`Заказать за ${formatCredits(special.price * count)}`}
            </Button>
          </Stack.Item>
        </Stack>
      )}
      {data.menu
        .filter((entry) => entry.kind === kind)
        .map((entry) => (
          <Stack key={entry.id} align="center" className="NtTerm__line">
            <Stack.Item grow>{lineName(entry.name, count)}</Stack.Item>
            {staff && (
              <Stack.Item>
                <Button icon="concierge-bell" disabled={blocked || full} onClick={() => act('order', { id: entry.id, count, route: 'staff' })}>
                  {`Заказать за ${formatCredits(entry.price * count)}`}
                </Button>
              </Stack.Item>
            )}
            {catering && (
              <Stack.Item>
                <Button icon="bolt" color="average" disabled={blocked} onClick={() => act('order', { id: entry.id, count, route: 'catering' })}>
                  {`От NT за ${formatCredits(entry.price * data.catering_mult * count)}`}
                </Button>
              </Stack.Item>
            )}
          </Stack>
        ))}
    </>
  );
};

const DecorTab = () => {
  const { act, data } = useBackend<RoomServiceData>();
  const bought = data.decor_bought as Record<string, number>;
  return (
    <>
      <div className="NtTerm__help">Декор появляется у терминала и хранится вместе с номером, как другие вещи. Деньги уходят NT.</div>
      {data.decor.map((decor) => {
        const owned = bought[decor.id] || 0;
        const soldOut = owned >= decor.max;
        return (
          <NtFrame
            key={decor.id}
            minor
            title={decor.name}
            buttons={
              <Button icon="shopping-cart" disabled={!!data.account_problem || soldOut} onClick={() => act('decor', { id: decor.id })}>
                {soldOut ? 'Уже в номере' : `Купить за ${formatCredits(decor.price)}`}
              </Button>
            }>
            <div>{decor.desc}</div>
            {decor.max > 1 && <NtLine label="Куплено в номер">{`${owned} из ${decor.max}`}</NtLine>}
          </NtFrame>
        );
      })}
    </>
  );
};

const HELP = [
  {
    title: 'Еда и напитки',
    lines: [
      'Если повар или бармен на смене, заказ уходит ему: он берёт заказ, готовит и отправляет его в номер подносом обслуживания номеров.',
      'Деньги списываются сразу. Никто не взял заказ или не доставил вовремя - они вернутся, а пока вы в номере, ему откроется кейтеринг NT.',
      'Кейтеринг NT присылает готовое сразу, но дороже, и деньги уходят NT, а не сервису.',
      'Блюдо дня от шефа готовит только повар станции, оно дороже обычного.',
      'После доставки здесь можно оставить чаевые тому, кто прислал заказ.',
    ],
  },
  {
    title: 'Номер',
    lines: ['Декор остаётся в номере, пока номер хранится, даже если вы ушли.'],
  },
];

/** Терминал номера отеля: заказ с кухни и бара станции, кейтеринг NT и декор номера. */
export const RoomServiceContent = () => {
  const { data } = useBackend<RoomServiceData>();
  const [tab, setTab] = useState<Tab>('food');
  return (
    <NtScreen
      tone="service"
      device="Обслуживание номеров"
      status={`Номер ${data.room}`}
      readout={
        <NtReadout label="Ваш счёт">
          {data.account_problem ? data.has_account ? 'недоступен' : 'нет счёта' : <AnimatedNumber value={data.balance} format={(value) => formatCredits(value)} />}
        </NtReadout>
      }
      menu={
        <NtMenu<Tab>
          items={[
            { key: 'food', label: 'Кухня' },
            { key: 'drink', label: 'Бар' },
            { key: 'decor', label: 'Номер' },
          ]}
          selected={tab}
          onSelect={setTab}
        />
      }>
      {!data.open ? (
        <NtEmpty>Терминал работает только в номере отеля.</NtEmpty>
      ) : (
        <NtFrame title={tab === 'decor' ? 'Декор номера' : 'Меню'} help={<NtHelpTopics topics={HELP} />}>
          {!!data.account_problem && (
            <Box color="bad" mb={1}>
              {data.account_problem}
            </Box>
          )}
          <Orders />
          <Tips />
          {tab === 'decor' ? <DecorTab /> : <MenuTab key={tab} kind={tab} />}
        </NtFrame>
      )}
    </NtScreen>
  );
};

export const RoomService = () => {
  return (
    <Window width={460} height={600}>
      <Window.Content scrollable>
        <RoomServiceContent />
      </Window.Content>
    </Window>
  );
};

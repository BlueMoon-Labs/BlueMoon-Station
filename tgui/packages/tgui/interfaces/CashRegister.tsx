import { BooleanLike, classes } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Input, RestrictedInput, Stack } from '../components';
import { Window } from '../layouts';
import { formatCredits } from './common/Economy';
import { NtEmpty, NtFrame, NtLine, NtReadout, NtScreen } from './common/NtTerminal';

type MenuItem = {
  id: number;
  name: string;
  price: number;
};

type OrderLine = MenuItem & { count: number };

type Cashier = {
  /** Номер счёта кассира: по нему окно платит и оставляет чаевые */
  id: number;
  name: string;
  present: BooleanLike;
  mine: BooleanLike;
  order: OrderLine[];
  total: number;
  /** Ревизия счёта: оплата проходит, только если клиент видел этот же счёт */
  rev: number;
  department: string | null;
  share: number;
  pay_problem: string | null;
};

export type CashRegisterData = {
  skin: string;
  skin_name: string;
  price_max: number;
  menu_max: number;
  name_max: number;
  count_max: number;
  cashiers_max: number;
  tip_max: number;
  transfer_cooldown: number;
  cashiers: Cashier[];
  is_cashier: BooleanLike;
  can_join: BooleanLike;
  menu: MenuItem[];
  total_sales: number | null;
  has_account: BooleanLike;
  balance: number;
  cooldown_left: number;
  receipt: BooleanLike;
};

const shareText = (cashier: Cashier) =>
  cashier.department ? `${cashier.share}% кассиру, остальное отделу "${cashier.department}"` : 'вся сумма кассиру';

const OrderLines = (props: { lines: OrderLine[] }) => (
  <>
    {props.lines.map((line) => (
      <NtLine key={line.id} label={line.count > 1 ? `${line.name} x${line.count}` : line.name}>
        {formatCredits(line.price * line.count)}
      </NtLine>
    ))}
  </>
);

/** Счёт кассира для клиента: что набрано, итог и оплата картой. */
const Bill = (props: { cashier: Cashier; titled: boolean }) => {
  const { act, data } = useBackend<CashRegisterData>();
  const { cashier, titled } = props;
  const empty = cashier.order.length === 0;
  return (
    <div className="NtTerm__lcd">
      <Stack align="baseline">
        <Stack.Item grow className="NtTerm__lcdLabel">
          {titled ? `Счёт: ${cashier.name}` : 'К оплате'}
          {!cashier.present && <span className="color-average"> (отошёл)</span>}
        </Stack.Item>
        {!empty && <Stack.Item className="NtTerm__lcdValue">{formatCredits(cashier.total)}</Stack.Item>}
      </Stack>
      {empty ? (
        <Box className="NtTerm__hint" mt={0.5}>
          Кассир ещё не набрал счёт.
        </Box>
      ) : (
        <>
          <Box className="NtTerm__receipt" my={0.5}>
            <OrderLines lines={cashier.order} />
          </Box>
          <Stack align="center" wrap>
            <Stack.Item>
              <Button
                icon="credit-card"
                color="good"
                disabled={!data.has_account || !!cashier.pay_problem}
                onClick={() => act('pay', { cashier: cashier.id, rev: cashier.rev, total: cashier.total })}>
                {`Оплатить картой ${formatCredits(cashier.total)}`}
              </Button>
            </Stack.Item>
            {!!cashier.pay_problem && (
              <Stack.Item grow color="bad">
                {cashier.pay_problem}
              </Stack.Item>
            )}
          </Stack>
        </>
      )}
      <Box className="NtTerm__hint" mt={0.5}>
        Получатель {cashier.name}: {shareText(cashier)}.
      </Box>
    </div>
  );
};

const ReceiptButton = () => {
  const { act } = useBackend<CashRegisterData>();
  return <Button icon="receipt" content="Распечатать чек" tooltip="Чек последней оплаты с вашего счёта" onClick={() => act('receipt')} />;
};

const JoinButton = () => {
  const { act, data } = useBackend<CashRegisterData>();
  if (!data.can_join) {
    return null;
  }
  return <Button icon="cash-register" content="Встать за кассу" onClick={() => act('join')} />;
};

const Tips = () => {
  const { act, data } = useBackend<CashRegisterData>();
  const { cashiers, has_account, cooldown_left, tip_max, transfer_cooldown } = data;
  const [tip, setTip] = useState(10);
  const [targetId, setTargetId] = useState<number | null>(null);
  const target = cashiers.find((cashier) => cashier.id === targetId) || cashiers[0];
  return (
    <NtFrame
      title="Чаевые"
      help={`Чаевые целиком уходят кассиру, без налога. Чаевые и личные переводы делят один кулдаун: не чаще раза в ${transfer_cooldown} с.`}>
      {cashiers.length > 1 && (
        <div className="NtTerm__chips">
          {cashiers.map((cashier) => (
            <span
              key={cashier.id}
              className={classes(['NtTerm__chip', cashier.id === target.id && 'NtTerm__chip--active'])}
              onClick={() => setTargetId(cashier.id)}>
              {cashier.name}
            </span>
          ))}
        </div>
      )}
      <Stack align="center">
        <Stack.Item>
          <RestrictedInput width="5em" value={tip} minValue={1} maxValue={tip_max} onChange={(_, value) => setTip(value)} /> кр.
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="hand-holding-usd"
            disabled={!has_account || cooldown_left > 0}
            onClick={() => act('tip', { cashier: target.id, amount: tip })}>
            {cashiers.length > 1 ? `Оставить: ${target.name}` : 'Оставить чаевые'}
          </Button>
        </Stack.Item>
        {cooldown_left > 0 && <Stack.Item color="average">ещё {cooldown_left} с.</Stack.Item>}
      </Stack>
    </NtFrame>
  );
};

const CustomerView = () => {
  const { data } = useBackend<CashRegisterData>();
  const { cashiers, menu, receipt, has_account } = data;
  if (!cashiers.length) {
    return (
      <>
        <NtEmpty>Касса свободна: встаньте за неё кнопкой ниже или свайпом своей ID-карты.</NtEmpty>
        <Stack justify="center" mb={1}>
          <Stack.Item>
            <JoinButton />
          </Stack.Item>
          {!!receipt && (
            <Stack.Item>
              <ReceiptButton />
            </Stack.Item>
          )}
        </Stack>
      </>
    );
  }
  return (
    <>
      {cashiers.map((cashier) => (
        <Bill key={cashier.id} cashier={cashier} titled={cashiers.length > 1} />
      ))}
      <Box className="NtTerm__hint" mb={1}>
        {has_account ? 'Платят только с личного счёта, без налога; карту можно просто провести по кассе.' : 'Нужна ID-карта с личным счётом.'}{' '}
        Наличные приложите к кассе: сдачу она выдаст голочипом.
      </Box>
      {(!!receipt || !!data.can_join) && (
        <Stack mb={1.5}>
          {!!receipt && (
            <Stack.Item>
              <ReceiptButton />
            </Stack.Item>
          )}
          <Stack.Item>
            <JoinButton />
          </Stack.Item>
        </Stack>
      )}
      <Tips />
      {menu.length > 0 && (
        <NtFrame title="Меню" className="NtTerm__receipt">
          {menu.map((item) => (
            <NtLine key={item.id} label={item.name}>
              {formatCredits(item.price)}
            </NtLine>
          ))}
        </NtFrame>
      )}
    </>
  );
};

/** Свой счёт кассира: штуки каждой позиции правятся тут же. */
const MyOrder = (props: { cashier: Cashier }) => {
  const { act, data } = useBackend<CashRegisterData>();
  const { cashier } = props;
  return (
    <NtFrame
      title="Ваш счёт"
      buttons={
        cashier.order.length > 0 && (
          <Button icon="times" color="transparent" onClick={() => act('clear')}>
            Очистить
          </Button>
        )
      }>
      {cashier.order.length === 0 && <NtEmpty>Пусто: добавьте позиции из меню.</NtEmpty>}
      {cashier.order.map((line) => (
        <Stack key={line.id} align="center" className="NtTerm__line">
          <Stack.Item grow>{line.name}</Stack.Item>
          <Stack.Item shrink={0}>
            <Button icon="minus" onClick={() => act('order', { id: line.id, delta: -1 })} />
            <Box inline bold width="2em" textAlign="center">
              {line.count}
            </Box>
            <Button icon="plus" disabled={line.count >= data.count_max} onClick={() => act('order', { id: line.id, delta: 1 })} />
          </Stack.Item>
          <Stack.Item shrink={0} width="6em" textAlign="right">
            {formatCredits(line.price * line.count)}
          </Stack.Item>
        </Stack>
      ))}
      {cashier.order.length > 0 && (
        <Box mt={0.5}>
          <NtLine label="Итого">
            <b>{formatCredits(cashier.total)}</b>
          </NtLine>
        </Box>
      )}
      <Box className="NtTerm__hint" mt={1}>
        Клиент платит этот счёт картой, из окна кассы или наличными. Ваша доля: {shareText(cashier)}.
      </Box>
    </NtFrame>
  );
};

const MenuEditor = (props: { cashier: Cashier }) => {
  const { act, data } = useBackend<CashRegisterData>();
  const { menu, menu_max, price_max, name_max, count_max } = data;
  const { cashier } = props;
  const [itemName, setItemName] = useState('');
  const [price, setPrice] = useState(1);
  const full = menu.length >= menu_max;
  const counts = Object.fromEntries(cashier.order.map((line) => [line.id, line.count]));
  return (
    <NtFrame
      title={`Меню ${menu.length}/${menu_max}`}
      help={`Меню общее для обоих кассиров: убранная позиция пропадает и из всех счетов. Цена от 1 до ${formatCredits(price_max)}, до ${count_max} шт. одной позиции в счёте.`}>
      {menu.length === 0 && <NtEmpty>Меню пустое: добавьте первую позицию.</NtEmpty>}
      {menu.map((item) => (
        <Stack key={item.id} align="center" className="NtTerm__line">
          <Stack.Item grow>{item.name}</Stack.Item>
          <Stack.Item shrink={0}>{formatCredits(item.price)}</Stack.Item>
          <Stack.Item shrink={0} style={{ whiteSpace: 'nowrap' }}>
            <Button
              icon="plus"
              disabled={(counts[item.id] || 0) >= count_max}
              onClick={() => act('order', { id: item.id, delta: 1 })}>
              В счёт
            </Button>
            <Button icon="trash" color="bad" tooltip="Убрать из меню" onClick={() => act('remove_item', { id: item.id })} />
          </Stack.Item>
        </Stack>
      ))}
      <Stack align="center" mt={1}>
        <Stack.Item grow>
          <Input fluid value={itemName} maxLength={name_max} placeholder="Новая позиция" onInput={(_, value) => setItemName(value)} />
        </Stack.Item>
        <Stack.Item>
          <RestrictedInput width="5em" value={price} minValue={1} maxValue={price_max} onChange={(_, value) => setPrice(value)} /> кр.
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="plus"
            content="Добавить"
            disabled={full || !itemName.trim()}
            onClick={() => {
              act('add_item', { name: itemName.trim(), price });
              setItemName('');
            }}
          />
        </Stack.Item>
      </Stack>
    </NtFrame>
  );
};

const CashierView = () => {
  const { act, data } = useBackend<CashRegisterData>();
  const mine = data.cashiers.find((cashier) => cashier.mine);
  const other = data.cashiers.find((cashier) => !cashier.mine);
  if (!mine) {
    return null;
  }
  return (
    <>
      <Stack align="center" mb={1.5}>
        <Stack.Item grow className="NtTerm__hint">
          {other
            ? `Второй кассир: ${other.name}${other.present ? '' : ' (отошёл)'}${other.total ? `, счёт ${formatCredits(other.total)}` : ''}.`
            : data.cashiers_max > 1
              ? 'Второе место за кассой свободно.'
              : null}
        </Stack.Item>
        {!!data.receipt && (
          <Stack.Item>
            <ReceiptButton />
          </Stack.Item>
        )}
        <Stack.Item>
          <Button icon="sign-out-alt" content="Отойти от кассы" onClick={() => act('logout')} />
        </Stack.Item>
      </Stack>
      <MyOrder cashier={mine} />
      <MenuEditor cashier={mine} />
    </>
  );
};

/** Касса: до двух кассиров набирают каждый свой счёт по общему меню, клиент платит картой или наличными. */
export const CashRegisterContent = () => {
  const { data } = useBackend<CashRegisterData>();
  const { cashiers, is_cashier, has_account, balance, total_sales } = data;
  return (
    <NtScreen
      tone="register"
      device={`Касса: ${data.skin_name}`}
      status={cashiers.length ? `За кассой: ${cashiers.map((cashier) => cashier.name).join(', ')}` : 'Касса свободна'}
      readout={
        is_cashier ? (
          <NtReadout label="Выручка кассы">{formatCredits(total_sales ?? 0)}</NtReadout>
        ) : (
          <NtReadout label="Ваш счёт">{has_account ? formatCredits(balance) : 'нет карты'}</NtReadout>
        )
      }>
      {is_cashier ? <CashierView /> : <CustomerView />}
    </NtScreen>
  );
};

export const CashRegister = () => {
  return (
    <Window width={460} height={600}>
      <Window.Content scrollable>
        <CashRegisterContent />
      </Window.Content>
    </Window>
  );
};

import { BooleanLike } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Input, NoticeBox, RestrictedInput, Stack } from '../components';
import { Window } from '../layouts';
import { formatCredits } from './common/Economy';
import { NtEmpty, NtFrame, NtLine, NtReadout, NtScreen } from './common/NtTerminal';

type MenuItem = {
  id: number;
  name: string;
  price: number;
};

export type CashRegisterData = {
  skin: string;
  skin_name: string;
  price_max: number;
  menu_max: number;
  name_max: number;
  tip_max: number;
  transfer_cooldown: number;
  cashier: string | null;
  cashier_present: BooleanLike;
  session: number;
  is_cashier: BooleanLike;
  menu: MenuItem[];
  selected: number;
  total_sales: number | null;
  department: string | null;
  cashier_share: number;
  has_account: BooleanLike;
  balance: number;
  pay_problem: string | null;
  cooldown_left: number;
  receipt: BooleanLike;
};

/** Табло покупателя: что выбрано к оплате и сколько. */
const Display = () => {
  const { data } = useBackend<CashRegisterData>();
  const item = data.menu.find((entry) => entry.id === data.selected);
  return (
    <div className="NtTerm__lcd">
      <div className="NtTerm__lcdLabel">К оплате</div>
      <div key={item ? `${item.id}-${item.price}` : 'none'} className="NtTerm__lcdValue NtTerm__flash">
        {item ? formatCredits(item.price) : '- - -'}
      </div>
      <div className="NtTerm__lcdItem">
        {item ? `${item.name} · получатель: ${data.cashier}` : data.cashier ? 'Кассир ещё не выбрал позицию.' : 'Касса свободна'}
      </div>
    </div>
  );
};

const shareText = (data: CashRegisterData) =>
  data.department
    ? `${data.cashier_share}% кассиру, ${100 - data.cashier_share}% в бюджет отдела «${data.department}». Долю задаёт глава отдела.`
    : 'Выручка целиком кассиру.';

const CashierMenu = () => {
  const { act, data } = useBackend<CashRegisterData>();
  const { menu, selected, menu_max, price_max, name_max } = data;
  const [itemName, setItemName] = useState('');
  const [price, setPrice] = useState(1);
  const full = menu.length >= menu_max;
  return (
    <>
      <NtFrame
        title={`Меню ${menu.length}/${menu_max}`}
        buttons={<Button icon="sign-out-alt" content="Отойти от кассы" onClick={() => act('logout')} />}>
        {menu.length === 0 && <NtEmpty>Меню пустое: добавьте позиции ниже.</NtEmpty>}
        {menu.map((item) => (
          <Stack key={item.id} align="center" className={item.id === selected ? 'NtTerm__row NtTerm__row--open' : 'NtTerm__row'}>
            <Stack.Item grow>
              <NtLine label={item.id === selected ? `▶ ${item.name}` : item.name}>{formatCredits(item.price)}</NtLine>
            </Stack.Item>
            <Stack.Item>
              <Button
                icon={item.id === selected ? 'times' : 'check'}
                selected={item.id === selected}
                content={item.id === selected ? 'Снять' : 'К оплате'}
                onClick={() => act('select', { id: item.id === selected ? 0 : item.id })}
              />
              <Button icon="trash" color="bad" tooltip="Убрать из меню" onClick={() => act('remove_item', { id: item.id })} />
            </Stack.Item>
          </Stack>
        ))}
      </NtFrame>
      <NtFrame title="Новая позиция">
        <Stack align="center">
          <Stack.Item grow>
            <Input fluid value={itemName} maxLength={name_max} placeholder="Название позиции" onInput={(_, value) => setItemName(value)} />
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
        <Box className="NtTerm__hint" mt={1}>
          Цена позиции от 1 до {formatCredits(price_max)}, в меню до {menu_max} позиций. Клиент платит ту позицию, которую
          вы выбрали к оплате.
        </Box>
      </NtFrame>
    </>
  );
};

const ReceiptButton = () => {
  const { act } = useBackend<CashRegisterData>();
  return <Button icon="receipt" content="Распечатать чек последней оплаты" onClick={() => act('receipt')} />;
};

const CustomerPanel = () => {
  const { act, data } = useBackend<CashRegisterData>();
  const { cashier, menu, selected, session, has_account, pay_problem, cooldown_left, tip_max, transfer_cooldown, receipt } = data;
  const [tip, setTip] = useState(10);
  if (!cashier) {
    return (
      <>
        <NoticeBox>Касса свободна: проведите своей ID-картой по кассе, чтобы встать за неё.</NoticeBox>
        {!!receipt && <ReceiptButton />}
      </>
    );
  }
  const item = menu.find((entry) => entry.id === selected);
  return (
    <>
      {item && (
        <Stack align="center" mb={1.5}>
          <Stack.Item>
            <Button
              icon="credit-card"
              color="good"
              disabled={!!pay_problem}
              content={`Оплатить ${formatCredits(item.price)}`}
              onClick={() => act('pay', { id: item.id, price: item.price, session })}
            />
          </Stack.Item>
          {!!pay_problem && (
            <Stack.Item grow color="bad">
              {pay_problem}
            </Stack.Item>
          )}
        </Stack>
      )}
      {!!receipt && (
        <Box mb={1.5}>
          <ReceiptButton />
        </Box>
      )}
      <NtFrame title="Чаевые кассиру">
        <Stack align="center">
          <Stack.Item>
            <RestrictedInput width="5em" value={tip} minValue={1} maxValue={tip_max} onChange={(_, value) => setTip(value)} /> кр.
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="hand-holding-usd"
              content="Оставить чаевые"
              disabled={!has_account || cooldown_left > 0}
              onClick={() => act('tip', { amount: tip, session })}
            />
          </Stack.Item>
          {cooldown_left > 0 && (
            <Stack.Item color="average">Следующий платёж через {cooldown_left} с.</Stack.Item>
          )}
        </Stack>
        <Box className="NtTerm__hint" mt={1}>
          Чаевые целиком уходят кассиру, без налога. Чаевые и личные переводы делят один кулдаун: не чаще раза в{' '}
          {transfer_cooldown} с.
        </Box>
      </NtFrame>
      {menu.length > 0 && (
        <NtFrame title="Меню">
          {menu.map((entry) => (
            <NtLine key={entry.id} label={entry.id === selected ? `▶ ${entry.name}` : entry.name}>
              {formatCredits(entry.price)}
            </NtLine>
          ))}
        </NtFrame>
      )}
    </>
  );
};

/** Касса: кассир составляет меню и выбирает позицию, клиент платит её своей картой и оставляет чаевые. */
export const CashRegisterContent = () => {
  const { data } = useBackend<CashRegisterData>();
  const { cashier, cashier_present, is_cashier, has_account, balance, total_sales } = data;
  return (
    <NtScreen
      tone="register"
      device={data.skin_name}
      status={
        cashier ? (
          <>
            <Box>
              Кассир: {cashier}
              {!cashier_present && <span className="color-average"> - отошёл, кассу может занять другой</span>}
            </Box>
            <Box>{shareText(data)}</Box>
          </>
        ) : (
          'Касса свободна'
        )
      }
      readout={
        is_cashier ? (
          <NtReadout label="Выручка за смену">{formatCredits(total_sales ?? 0)}</NtReadout>
        ) : (
          <NtReadout label="Ваш счёт">{has_account ? formatCredits(balance) : 'нет карты'}</NtReadout>
        )
      }>
      {!is_cashier && <Display />}
      {is_cashier ? <CashierMenu /> : <CustomerPanel />}
      {!is_cashier && !has_account && <NoticeBox>Счёт не найден: нужна ID-карта с личным счётом.</NoticeBox>}
      <Box className="NtTerm__hint" mt={1}>
        Платят только с личного счёта, без налога; бюджетные карты отделов касса не принимает. Оплатить можно и свайпом
        карты по кассе.
      </Box>
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

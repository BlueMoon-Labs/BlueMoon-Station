import { BooleanLike } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Input, LabeledList, NoticeBox, RestrictedInput, Section, Stack, Table } from '../components';
import { Window } from '../layouts';
import { Credits, formatCredits } from './common/Economy';

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

const CashierInfo = () => {
  const { data } = useBackend<CashRegisterData>();
  const { cashier, cashier_present, department, cashier_share } = data;
  if (!cashier) {
    return <NoticeBox>Касса свободна: проведите своей ID-картой по кассе, чтобы встать за неё.</NoticeBox>;
  }
  return (
    <LabeledList>
      <LabeledList.Item label="Кассир">
        {cashier}
        {!cashier_present && (
          <Box inline color="average" ml={1}>
            (отошёл - кассу может занять другой)
          </Box>
        )}
      </LabeledList.Item>
      <LabeledList.Item label="Выручка">
        {department
          ? `${cashier_share}% кассиру, ${100 - cashier_share}% в бюджет отдела «${department}». Долю задаёт глава отдела.`
          : 'Целиком кассиру.'}
      </LabeledList.Item>
    </LabeledList>
  );
};

const CashierMenu = () => {
  const { act, data } = useBackend<CashRegisterData>();
  const { menu, selected, menu_max, price_max, name_max, total_sales } = data;
  const [itemName, setItemName] = useState('');
  const [price, setPrice] = useState(1);
  const full = menu.length >= menu_max;
  return (
    <>
      <Section
        title={`Меню (${menu.length}/${menu_max})`}
        buttons={<Button icon="sign-out-alt" content="Отойти от кассы" onClick={() => act('logout')} />}>
        {menu.length === 0 ? (
          <Box color="label">Меню пустое: добавьте позиции ниже.</Box>
        ) : (
          <Table>
            {menu.map((item) => (
              <Table.Row key={item.id} className="candystripe">
                <Table.Cell bold={item.id === selected}>{item.name}</Table.Cell>
                <Table.Cell collapsing textAlign="right" nowrap>
                  <Credits amount={item.price} />
                </Table.Cell>
                <Table.Cell collapsing nowrap>
                  <Button
                    icon={item.id === selected ? 'times' : 'check'}
                    selected={item.id === selected}
                    content={item.id === selected ? 'Снять' : 'К оплате'}
                    onClick={() => act('select', { id: item.id === selected ? 0 : item.id })}
                  />
                  <Button
                    icon="trash"
                    color="bad"
                    tooltip="Убрать из меню"
                    onClick={() => act('remove_item', { id: item.id })}
                  />
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        )}
        <Stack mt={1}>
          <Stack.Item grow>
            <Input
              fluid
              value={itemName}
              maxLength={name_max}
              placeholder="Название позиции"
              onInput={(_, value) => setItemName(value)}
            />
          </Stack.Item>
          <Stack.Item>
            <RestrictedInput
              width="5em"
              value={price}
              minValue={1}
              maxValue={price_max}
              onChange={(_, value) => setPrice(value)}
            />{' '}
            кр.
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
        <Box color="label" mt={1}>
          Цена позиции от 1 до {formatCredits(price_max)}, в меню до {menu_max} позиций. Клиент платит ту позицию,
          которую вы выбрали к оплате.
        </Box>
      </Section>
      <Section title="Выручка за смену">
        <Credits amount={total_sales ?? 0} />
      </Section>
    </>
  );
};

const ReceiptButton = () => {
  const { act } = useBackend<CashRegisterData>();
  return (
    <Box mt={1}>
      <Button icon="receipt" content="Распечатать чек последней оплаты" onClick={() => act('receipt')} />
    </Box>
  );
};

const CustomerPanel = () => {
  const { act, data } = useBackend<CashRegisterData>();
  const {
    cashier,
    menu,
    selected,
    session,
    has_account,
    balance,
    pay_problem,
    cooldown_left,
    tip_max,
    transfer_cooldown,
    receipt,
  } = data;
  const [tip, setTip] = useState(10);
  if (!cashier) {
    return receipt ? (
      <Section title="Чек">
        <ReceiptButton />
      </Section>
    ) : null;
  }
  const item = menu.find((entry) => entry.id === selected);
  return (
    <>
      <Section title="Оплата">
        <LabeledList>
          <LabeledList.Item label="Ваш счёт">
            {has_account ? <Credits amount={balance} /> : 'Не найден: нужна ID-карта с личным счётом.'}
          </LabeledList.Item>
          <LabeledList.Item label="К оплате">
            {item ? `${item.name} - ${formatCredits(item.price)}, получатель: ${cashier}` : 'Кассир ещё не выбрал позицию.'}
          </LabeledList.Item>
        </LabeledList>
        {item && (
          <Box mt={1}>
            <Button
              icon="credit-card"
              disabled={!!pay_problem}
              content={`Оплатить ${formatCredits(item.price)}`}
              onClick={() => act('pay', { id: item.id, price: item.price, session })}
            />
            {!!pay_problem && (
              <Box inline color="bad" ml={1}>
                {pay_problem}
              </Box>
            )}
          </Box>
        )}
        {!!receipt && <ReceiptButton />}
      </Section>
      <Section title="Чаевые">
        <Stack align="center">
          <Stack.Item>
            <RestrictedInput
              width="5em"
              value={tip}
              minValue={1}
              maxValue={tip_max}
              onChange={(_, value) => setTip(value)}
            />{' '}
            кр.
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="hand-holding-usd"
              content="Оставить чаевые"
              disabled={!has_account || cooldown_left > 0}
              onClick={() => act('tip', { amount: tip, session })}
            />
          </Stack.Item>
        </Stack>
        <Box color="label" mt={1}>
          Чаевые целиком уходят кассиру, без налога. Чаевые и личные переводы делят один кулдаун: не чаще раза в{' '}
          {transfer_cooldown} с.
        </Box>
        {cooldown_left > 0 && (
          <Box color="average" mt={1}>
            Следующий платёж через {cooldown_left} с.
          </Box>
        )}
      </Section>
      {menu.length > 0 && (
        <Section title="Меню">
          <Table>
            {menu.map((entry) => (
              <Table.Row key={entry.id}>
                <Table.Cell bold={entry.id === selected}>{entry.name}</Table.Cell>
                <Table.Cell collapsing textAlign="right" nowrap>
                  <Credits amount={entry.price} />
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>
      )}
    </>
  );
};

/** Касса: кассир составляет меню и выбирает позицию, клиент платит её своей картой и оставляет чаевые. */
export const CashRegisterContent = () => {
  const { data } = useBackend<CashRegisterData>();
  return (
    <>
      <Section title={`Касса: ${data.skin_name}`}>
        <CashierInfo />
      </Section>
      {data.is_cashier ? <CashierMenu /> : <CustomerPanel />}
      <Box color="label" px={1}>
        Платят только с личного счёта, без налога; бюджетные карты отделов касса не принимает. Оплатить можно и
        свайпом карты по кассе.
      </Box>
    </>
  );
};

export const CashRegister = () => {
  return (
    <Window width={440} height={560}>
      <Window.Content scrollable>
        <CashRegisterContent />
      </Window.Content>
    </Window>
  );
};

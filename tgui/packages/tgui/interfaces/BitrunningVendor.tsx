import { useState } from 'react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  Dimmer,
  Icon,
  Input,
  NumberInput,
  Section,
  Stack,
  Table,
  Tabs,
  Tooltip,
} from '../components';
import { Window } from '../layouts';

type OrderDatum = {
  cat: string;
  cost: number;
  desc: string;
  icon: string;
  name: string;
  ref: string;
};

type CartItem = {
  name: string;
  amt: number;
};

type Data = {
  cargo_cost_multiplier: number;
  credit_type: string;
  express_cost_multiplier: number;
  express_tooltip: string;
  has_card: boolean;
  item_amts: CartItem[];
  off_cooldown: number;
  order_categories: string[];
  order_datums: OrderDatum[];
  points: number;
  purchase_tooltip: string;
  total_cost: number;
};

const findAmount = (item_amts: CartItem[], name: string): number => {
  const entry = item_amts.find((item) => item.name === name);
  return entry?.amt || 0;
};

const ShoppingTab = () => {
  const { act, data } = useBackend<Data>();
  const { credit_type, order_categories = [], order_datums = [] } = data;
  const [shopCategory, setShopCategory] = useState(order_categories[0] || '');
  const [searchItem, setSearchItem] = useState('');

  const search = searchItem.trim().toLowerCase();
  const goods = search
    ? order_datums.filter((item) => item.name.toLowerCase().includes(search))
    : order_datums.filter((item) => item.cat === shopCategory);

  return (
    <Stack fill vertical>
      <Section mb={-1}>
        <Stack align="center">
          <Stack.Item grow>
            <Tabs fluid textAlign="center">
              {order_categories.map((category) => (
                <Tabs.Tab
                  key={category}
                  selected={category === shopCategory}
                  onClick={() => {
                    setShopCategory(category);
                    setSearchItem('');
                  }}
                >
                  {category}
                </Tabs.Tab>
              ))}
            </Tabs>
          </Stack.Item>
          <Stack.Item>
            <Input
              width="140px"
              placeholder="Поиск предмета..."
              value={searchItem}
              onInput={(_, value) => setSearchItem(value)}
            />
          </Stack.Item>
        </Stack>
      </Section>
      <Stack.Item grow>
        <Section fill scrollable>
          <Table>
            {goods.map((item) => (
              <Table.Row
                key={item.ref}
                style={{ borderBottom: 'thin solid #333' }}
              >
                <Table.Cell collapsing verticalAlign="middle">
                  <Box
                    width="32px"
                    height="32px"
                    dangerouslySetInnerHTML={{ __html: item.icon }}
                  />
                </Table.Cell>
                <Table.Cell color="label" verticalAlign="middle">
                  {item.name}
                </Table.Cell>
                <Table.Cell color="label" fontSize="10px" collapsing>
                  {!!item.desc && (
                    <Button
                      color="transparent"
                      icon="info"
                      tooltipPosition="top"
                      tooltip={item.desc}
                    />
                  )}
                </Table.Cell>
                <Table.Cell fontSize="10px" collapsing textAlign="right">
                  <Tooltip
                    content={`Стоимость: ${item.cost} ${credit_type} за заказ`}
                    position="top"
                  >
                    {item.cost} {credit_type}
                  </Tooltip>
                </Table.Cell>
                <Table.Cell collapsing>
                  <Button
                    icon="minus"
                    onClick={() => act('remove_one', { target: item.ref })}
                  />
                  <Button
                    icon="plus"
                    onClick={() => act('add_one', { target: item.ref })}
                  />
                  <NumberInput
                    value={findAmount(data.item_amts, item.name)}
                    width="41px"
                    minValue={0}
                    maxValue={20}
                    step={1}
                    onChange={(e, value) =>
                      act('cart_set', { target: item.ref, amt: value })
                    }
                  />
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const CheckoutTab = () => {
  const { act, data } = useBackend<Data>();
  const {
    cargo_cost_multiplier,
    credit_type,
    express_cost_multiplier,
    express_tooltip,
    has_card,
    item_amts = [],
    order_datums = [],
    points,
    purchase_tooltip,
    total_cost = 0,
  } = data;

  const cart = order_datums.filter((item) => findAmount(item_amts, item.name));
  const totalCargoCost = Math.floor(total_cost * cargo_cost_multiplier);
  const totalExpressCost = Math.floor(total_cost * express_cost_multiplier);

  return (
    <Stack vertical fill>
      <Stack.Item grow>
        <Section fill scrollable>
          <Box bold textAlign="center" color="label">
            Корзина:
          </Box>
          <Table>
            {!cart.length && (
              <>
                <Box align="center" mt="15%" fontSize="40px">
                  Пусто!
                </Box>
                <br />
                <Box align="center" mt={2} fontSize="15px">
                  (Ну сходите что-нибудь закажите, а?)
                </Box>
              </>
            )}
            {cart.map((item) => (
              <Table.Row
                key={item.ref}
                style={{ borderBottom: 'thin solid #333' }}
              >
                <Table.Cell collapsing>{item.name}</Table.Cell>
                <Table.Cell color="label" fontSize="10px">
                  {item.desc}
                </Table.Cell>
                <Table.Cell fontSize="10px" collapsing textAlign="right">
                  <Tooltip
                    content={`Стоимость: ${item.cost} ${credit_type} за заказ`}
                    position="top"
                  >
                    {item.cost} {credit_type}
                  </Tooltip>
                </Table.Cell>
                <Table.Cell collapsing>
                  <NumberInput
                    value={findAmount(item_amts, item.name)}
                    width="41px"
                    minValue={0}
                    maxValue={20}
                    step={1}
                    onChange={(e, value) =>
                      act('cart_set', { target: item.ref, amt: value })
                    }
                  />
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section fill>
          <Stack fill align="center">
            <Stack.Item grow textAlign="center">
              <Button
                fluid
                icon="plane-departure"
                disabled={!has_card || totalCargoCost <= 0}
                tooltip={
                  !has_card
                    ? 'ID-карта не обнаружена'
                    : purchase_tooltip
                }
                tooltipPosition="top"
                onClick={() => act('purchase')}
              >
                Купить: {totalCargoCost} {credit_type}
              </Button>
            </Stack.Item>
            <Stack.Item grow textAlign="center">
              <Button
                fluid
                icon="parachute-box"
                color="yellow"
                disabled={!has_card || total_cost <= 0}
                tooltip={!has_card ? 'ID-карта не обнаружена' : express_tooltip}
                tooltipPosition="top-start"
                onClick={() => act('express')}
              >
                Экспресс: {totalExpressCost} {credit_type}
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Box color="label">
                {points} {credit_type}
              </Box>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const OrderSent = () => (
  <Dimmer>
    <Stack vertical>
      <Stack.Item>
        <Icon ml="28%" color="green" name="plane-arrival" size={10} />
      </Stack.Item>
      <Stack.Item fontSize="18px" color="green">
        Заказ отправлен! Автомат перезаряжается...
      </Stack.Item>
    </Stack>
  </Dimmer>
);

enum Tab {
  Shopping,
  Checkout,
}

export const BitrunningVendor = () => {
  const { data } = useBackend<Data>();
  const {
    credit_type,
    has_card,
    off_cooldown,
    order_categories = [],
    points = 0,
  } = data;

  const [tabIndex, setTabIndex] = useState(Tab.Shopping);

  return (
    <Window
      title="NexaCache"
      width={Math.max(order_categories.length * 140, 540)}
      height={520}
    >
      <Window.Content>
        {!off_cooldown && <OrderSent />}
        <Stack vertical fill>
          <Stack.Item>
            <Section fill>
              <Stack fill vertical>
                <Stack.Item>
                  <Stack textAlign="center">
                    <Stack.Item grow={3}>
                      <Button
                        fluid
                        color="green"
                        lineHeight={2}
                        icon="cart-plus"
                        onClick={() => setTabIndex(Tab.Shopping)}
                      >
                        Покупки
                      </Button>
                    </Stack.Item>
                    <Stack.Item grow>
                      <Button
                        fluid
                        color="green"
                        lineHeight={2}
                        icon="dollar-sign"
                        onClick={() => setTabIndex(Tab.Checkout)}
                      >
                        Корзина
                      </Button>
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
                <Stack.Item>
                  <Stack justify="space-between">
                    <Stack.Item>
                      <Box color="label">
                        Битраннинг-очки: {points} {credit_type}
                      </Box>
                    </Stack.Item>
                    <Stack.Item>
                      {!has_card && (
                        <Box color="bad">ID-карта не обнаружена</Box>
                      )}
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            {tabIndex === Tab.Shopping && <ShoppingTab />}
            {tabIndex === Tab.Checkout && <CheckoutTab />}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

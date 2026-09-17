import { useState } from 'react';
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
} from '../../components';
import { useBackend, useSharedState } from '../../backend';
import { createSearch, capitalize } from '../../common/string';
import { SearchBar } from '../common/SearchBar';

type BooleanLike = boolean | 0 | 1;

type OrderDatum = {
  name: string;
  cost: number;
  cat: string;
};

type Item = {
  name: string;
  amt: number;
};

type Data = {
  cargo_cost_multiplier: number;
  cargo_value: number;
  credit_type: string;
  express_cost_multiplier: number;
  express_tooltip: string;
  forced_express: string;
  item_amts: Item[];
  off_cooldown: BooleanLike;
  order_categories: string[];
  order_datums: OrderDatum[];
  points: number;
  purchase_tooltip: string;
  total_cost: number;
};

const buttonWidth = 2;

const creditIcons = {
  credit: 'coins',
} as const;

type CreditIconProps = {
  credit_type: string;
  color?: string;
};

function CreditIcon(props: CreditIconProps) {
  const { credit_type, color = 'gold' } = props;

  const foundIcon = creditIcons[credit_type];
  if (!foundIcon) return credit_type;

  return <Icon name={foundIcon} color={color} />;
}

function findAmount(item_amts: Item[], name: string): number {
  const amount = item_amts.find((item) => item.name === name);
  return amount?.amt || 0;
}

function ShoppingTab(props) {
  const { data, act } = useBackend<Data>();
  const { credit_type, order_categories, order_datums, item_amts } = data;

  const [shopCategory, setShopCategory] = useState(order_categories[0]);
  const [condensed, setCondensed] = useSharedState('condensed', false);
  const [searchItem, setSearchItem] = useState('');

  const search = createSearch<OrderDatum>(
    searchItem,
    (order_datums) => order_datums.name,
  );

  const goods =
    searchItem.length > 0
      ? order_datums.filter((item) => search(item))
      : order_datums.filter((item) => item && item.cat === shopCategory);

  return (
    <Stack fill vertical>
      <Section mb={-1}>
        <Stack.Item>
          <Tabs fluid textAlign="center">
            {order_categories.map((category) => (
              <Tabs.Tab
                key={category}
                selected={category === shopCategory}
                onClick={() => {
                  setShopCategory(category);
                  if (searchItem.length > 0) {
                    setSearchItem('');
                  }
                }}
              >
                {category}
              </Tabs.Tab>
            ))}
            <Stack.Item>
              <Input
                autoFocus
                mt={0.5}
                width="150px"
                placeholder="Search item..."
                value={searchItem}
                onChange={setSearchItem}
              />
            </Stack.Item>
          </Tabs>
        </Stack.Item>
      </Section>
      <Stack.Item grow>
        <Section fill scrollable>
          <Stack.Item>
            <Table>
              <Table.Row header>
                <Table.Cell width={`${buttonWidth}em`} />
                <Table.Cell>Name</Table.Cell>
                <Table.Cell textAlign="right">Amount</Table.Cell>
                <Table.Cell textAlign="right">Cost</Table.Cell>
                <Table.Cell width={`${buttonWidth}em`} />
              </Table.Row>
              {goods.map((item) => {
                const amount = findAmount(item_amts, item.name);
                const noStock = item.cost <= 0;
                return (
                  <Table.Row key={item.name} style={{ 'border-bottom': '1px solid #333' }}>
                    <Table.Cell>
                      <Button
                        width="10em"
                        onClick={() => act('produce_item', { item: item.name })}
                      >
                        Produce
                      </Button>
                    </Table.Cell>
                    <Table.Cell>
                      {item.name} {item.cat}
                    </Table.Cell>
                    <Table.Cell textAlign="right">{amount}</Table.Cell>
                    <Table.Cell textAlign="right">
                      {item.cost}
                    </Table.Cell>
                    <Table.Cell>
                      <Button
                        width={`${buttonWidth}em`}
                        onClick={() => act('remove_item', { item: item.name })}
                        disabled={amount === 0}
                      >
                        -{buttonWidth}
                      </Button>
                    </Table.Cell>
                  </Table.Row>
                );
              })}
            </Table>
          </Stack.Item>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section>
          <Stack>
            <Stack.Item grow>
              <Stack>
                <Stack.Item>
                  <Icon name="coins" color="gold" />
                </Stack.Item>
                <Stack.Item>
                  <b>{capitalize(data.credit_type)} balance:</b>{' '}
                  {data.points}
                </Stack.Item>
              </Stack>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
    </Stack>
  );
}

function CondensedAtom(props) {
  const { children, ...rest } = props;

  return <Box {...rest}>{children}</Box>;
}

function OrdersTab(props) {
  const { data, act } = useBackend<Data>();
  const {
    credit_type,
    express_cost_multiplier,
    express_tooltip,
    forced_express,
    off_cooldown,
    purchase_tooltip,
    order_datums,
  } = data;

  const [express, setExpress] = useSharedState('express', false);
  const [customName, setCustomName] = useState(props.initial_text || '');
  const [amount, setAmount] = useState(1);
  const [totalCost, setTotalCost] = useState(data.total_cost || 0);

  return (
    <Section title="Orders">
      <Stack fill>
        <Stack.Item mt={0}>
          <Stack vertical>
            <Stack.Item>
              <Button.Checkbox
                checked={express}
                tooltip={express_tooltip}
                onClick={() => setExpress(!express)}
              >
                Express
              </Button.Checkbox>
            </Stack.Item>
            <Stack.Item>
              <Button
                disabled={!express}
                tooltip={express_tooltip}
                onClick={() => act('send_order', { name: customName })}
              >
                Send
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
        <Stack.Item grow>
          <Section fill scrollable>
            <Table>
              <Table.Row header>
                <Table.Cell>Name</Table.Cell>
                <Table.Cell textAlign="right">Cost</Table.Cell>
              </Table.Row>
              {order_datums.map((item) => (
                <Table.Row key={item.name}>
                  <Table.Cell
                    onClick={() => {
                      setCustomName(item.name);
                      setTotalCost(Math.round(item.cost * (express ? express_cost_multiplier : 1)));
                    }}
                  >
                    {item.name}
                  </Table.Cell>
                  <Table.Cell textAlign="right">{item.cost}</Table.Cell>
                </Table.Row>
              ))}
            </Table>
          </Section>
        </Stack.Item>
        <Stack.Item mt={0}>
          <Section>
            <Stack vertical>
              <Stack.Item>
                <b>Name:</b>
              </Stack.Item>
              <Stack.Item>
                <Input
                  width="170px"
                  value={customName}
                  onChange={setCustomName}
                />
              </Stack.Item>
              <Stack.Item>
                <b>Amount:</b>
              </Stack.Item>
              <Stack.Item>
                <NumberInput
                  width="70px"
                  value={amount}
                  minValue={1}
                  maxValue={10}
                  onChange={setAmount}
                />
              </Stack.Item>
              <Stack.Item>
                <b>Total:</b> {totalCost}
              </Stack.Item>
              <Stack.Item>
                <Button
                  width="100%"
                  tooltip={purchase_tooltip}
                  disabled={!off_cooldown}
                  onClick={() =>
                    act('purchase', {
                      name: customName,
                      amount: amount,
                    })
                  }
                >
                  Purchase
                </Button>
              </Stack.Item>
            </Stack>
          </Section>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

export function ProduceConsole(props) {
  const { data, act } = useBackend<Data>();
  const { credit_type, order_categories } = data => data;

  return (
    <Window width={620} height={600}>
      <Window.Content scrollable>
        <Tabs>
          <Tabs.Tab
            selected
            onClick={() => setTab('shopping')}
            icon="shopping-cart"
          >
            Shopping
          </Tabs.Tab>
          <Tabs.Tab onClick={() => setTab('orders')} icon="clipboard-list">
            Orders
          </Tabs.Tab>
        </Tabs>
        {tab === 'shopping' && <ShoppingTab />}
        {tab === 'orders' && <OrdersTab />}
      </Window.Content>
    </Window>
  );
}

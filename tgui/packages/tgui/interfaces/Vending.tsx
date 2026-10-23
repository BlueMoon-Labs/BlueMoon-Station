import { BooleanLike } from 'common/react';
import { capitalizeAll, createSearch } from 'common/string';
import { useState } from 'react';

import { useBackend } from '../backend';
import { Button, Icon, ImageButton, Input, NoticeBox, Section, Stack } from '../components';
import { Window } from '../layouts';
import { LayoutToggle, VendingLayout } from './common/LayoutToggle';

type Category = { icon: string };

type ProductRecord = {
  path: string;
  name: string;
  price: number;
  max_amount: number;
  ref: string;
  category: string;
  premium?: BooleanLike;
};

type CustomInput = {
  name: string;
  price: number;
  img: string;
  amount: number;
};

type Product = ProductRecord | CustomInput;

type VendingData = {
  onstation: BooleanLike;
  department: string;
  jobDiscount: number;
  product_records: ProductRecord[];
  coin_records: ProductRecord[];
  hidden_records: ProductRecord[];
  user?: {
    name: string;
    cash: number;
    job: string;
    department: string;
  };
  stock: Record<string, number>;
  free_stock: Record<string, BooleanLike>;
  extended_inventory: BooleanLike;
  access: BooleanLike;
  vending_machine_input?: CustomInput[];
  categories?: Record<string, Category>;
  vending_layout: VendingLayout;
};

export const Vending = () => {
  const { data } = useBackend<VendingData>();
  const {
    onstation,
    product_records = [],
    coin_records = [],
    hidden_records = [],
    categories = {},
    vending_machine_input,
    extended_inventory,
  } = data;
  const [selectedCategory, setSelectedCategory] = useState(
    Object.keys(categories)[0]
  );
  const [stockSearch, setStockSearch] = useState('');
  const searching = stockSearch.length >= 2;
  const search = createSearch(stockSearch, (product: Product) => product.name);
  const custom = !!vending_machine_input;
  const inventory: Product[] = (
    vending_machine_input || [
      ...product_records,
      ...coin_records,
      ...(extended_inventory ? hidden_records : []),
    ]
  ).filter(Boolean);
  const filteredCategories = Object.fromEntries(
    Object.entries(categories).filter(([name]) =>
      inventory.some((product) => 'category' in product && product.category === name)
    )
  );
  const effectiveCategory = selectedCategory in filteredCategories
    ? selectedCategory
    : Object.keys(filteredCategories)[0];
  const products = searching
    ? inventory.filter(search)
    : inventory.filter((product) =>
      !effectiveCategory || !('category' in product) || product.category === effectiveCategory
    );

  return (
    <Window width={440} height={635}>
      <Window.Content>
        <Stack fill vertical>
          {!!onstation && (
            <Stack.Item>
              <UserDetails />
            </Stack.Item>
          )}
          <Stack.Item grow>
            <Section
              fill
              scrollable
              title="Ассортимент"
              buttons={
                <Stack align="center">
                  {!!onstation && data.user && (
                    <Stack.Item color="green">
                      {data.user.cash || 0} кр. <Icon name="coins" color="gold" />
                    </Stack.Item>
                  )}
                  <Stack.Item>
                    <Input
                      width="110px"
                      onInput={(_, value) => setStockSearch(value)}
                      placeholder="Поиск..."
                      value={stockSearch}
                    />
                  </Stack.Item>
                  <LayoutToggle />
                </Stack>
              }>
              {!products.length && <NoticeBox>Ничего не найдено.</NoticeBox>}
              {products.map((product) => (
                <VendingProduct
                  key={'ref' in product ? product.ref : product.name}
                  custom={custom}
                  product={product}
                />
              ))}
            </Section>
          </Stack.Item>
          {!searching && Object.keys(filteredCategories).length > 1 && (
            <Stack.Item>
              <Section>
                {Object.entries(filteredCategories).map(([name, category]) => (
                  <Button
                    key={name}
                    selected={name === effectiveCategory}
                    color={CATEGORY_COLORS[name]}
                    icon={category.icon}
                    onClick={() => setSelectedCategory(name)}>
                    {name}
                  </Button>
                ))}
              </Section>
            </Stack.Item>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};

export const UserDetails = () => {
  const { data } = useBackend<VendingData>();
  const { user } = data;
  return (
    <NoticeBox m={0} color={user ? 'blue' : undefined}>
      <Stack align="center">
        <Stack.Item><Icon name="id-card" size={1.5} /></Stack.Item>
        <Stack.Item>
          {user
            ? `${user.name || 'Неизвестно'} | ${user.job || 'БЕЗ РАБОТЫ'}`
            : 'Не обнаружена ID-карта! Свяжитесь с Главой Персонала.'}
        </Stack.Item>
      </Stack>
    </NoticeBox>
  );
};

const VendingProduct = (props: { custom: boolean; product: Product }) => {
  const { act, data } = useBackend<VendingData>();
  const { custom, product } = props;
  const { access, department, jobDiscount, onstation, user, stock = {}, free_stock = {} } = data;
  const record = 'ref' in product ? product : undefined;
  // Остатки привязаны к записи: одинаковые названия и пути не объединяют товары.
  const remaining = 'amount' in product ? product.amount : stock[product.ref] ?? 0;
  const free = custom
    ? !!access || product.price === 0
    : !onstation || product.price === 0 || !!(record && free_stock[record.ref]);
  const discount = !custom && !record?.premium && !!user && department === user.department;
  const price = discount ? Math.max(Math.round(product.price * jobDiscount), 1) : product.price;
  const disabled = remaining <= 0
    || (!!onstation && !user)
    || (!free && price > (user?.cash ?? 0));
  const fluid = data.vending_layout === 'list';
  const priceLabel = free ? 'Бесплатно' : `${price} кр.`;
  const displayName = capitalizeAll(product.name);

  return (
    <ImageButton
      fluid={fluid}
      imageSize={fluid ? 32 : 64}
      base64={'img' in product ? product.img : undefined}
      asset={record ? ['vending32x32', record.path] : undefined}
      disabled={disabled}
      tooltip={`${displayName} — ${priceLabel}, ${remaining} шт.`}
      tooltipPosition="bottom"
      buttonsAlt={!fluid && (
        <Stack fontSize={0.8}>
          <Stack.Item grow minWidth={0} textAlign="left" color="gold" style={{ overflow: 'hidden', textOverflow: 'ellipsis' }}>{priceLabel}</Stack.Item>
          <Stack.Item shrink={0} color="lightgray">x{remaining}</Stack.Item>
        </Stack>
      )}
      onClick={() => custom
        ? act('dispense', { item: product.name })
        : act('vend', { ref: record?.ref })}>
      {fluid ? (
        <Stack align="center" textAlign="right">
          <Stack.Item grow textAlign="left">{displayName}</Stack.Item>
          <Stack.Item color="label" fontSize={0.8}>{remaining} шт.</Stack.Item>
          <Stack.Item color="gold" fontSize={0.85}>{priceLabel}</Stack.Item>
        </Stack>
      ) : displayName}
    </ImageButton>
  );
};

const CATEGORY_COLORS = {
  'Контрабанда': 'red',
  'Премиум': 'yellow',
};

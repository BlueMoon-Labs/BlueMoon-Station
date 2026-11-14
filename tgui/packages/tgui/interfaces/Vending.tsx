import { BooleanLike } from 'common/react';
import { capitalizeAll, createSearch } from 'common/string';
import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Icon, ImageButton, Input, NoticeBox, Section, Stack } from '../components';
import { Window } from '../layouts';
import { LayoutToggle, useLayoutScroll, VendingLayout } from './common/LayoutToggle';

type Category = { icon: string; name?: string };

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
  point_vendor?: BooleanLike;
  point_label?: string;
  discount?: number;
};

export const Vending = () => {
  const { data } = useBackend<VendingData>();
  const { scrollableRef, onScroll } = useLayoutScroll(data.vending_layout);
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
  const searching = stockSearch.trim().length > 0;
  const search = createSearch(stockSearch, (product: Product) => product.name);
  const custom = !!vending_machine_input;
  const inventory: Product[] = (
    vending_machine_input || [
      ...product_records,
      ...coin_records,
      ...(extended_inventory ? hidden_records : []),
    ]
  ).filter(Boolean);
  if (data.point_vendor) {
    inventory.sort((a, b) => a.price - b.price);
  }
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
              scrollableRef={scrollableRef}
              onScroll={onScroll}
              title="Ассортимент"
              buttons={
                <Stack align="center">
                  {!!onstation && data.user && (
                    <Stack.Item color="green">
                      <Box title={data.point_label}>
                        {data.user.cash || 0} {data.point_vendor ? 'оч.' : 'кр.'} <Icon name="coins" color="gold" />
                      </Box>
                    </Stack.Item>
                  )}
                  <Stack.Item>
                    <Input
                      width="110px"
                      onInput={(_, value) => setStockSearch(value)}
                      placeholder="Поиск..."
                      value={stockSearch}
                      onKeyDown={(event) => {
                        if (event.key === 'Escape') {
                          setStockSearch('');
                        }
                      }}
                    />
                  </Stack.Item>
                  {!!stockSearch && (
                    <Stack.Item>
                      <Button icon="times" tooltip="Очистить поиск" onClick={() => setStockSearch('')} />
                    </Stack.Item>
                  )}
                  <LayoutToggle />
                </Stack>
              }>
              <Stack mb={1} fontSize={0.9}>
                <Stack.Item grow color="label">{searching ? 'Найдено' : 'Позиций'}: {products.length}</Stack.Item>
                {!!data.point_vendor && (
                  <Stack.Item color="good">Скидка: {Math.round((data.discount || 0) * 1000) / 10}%</Stack.Item>
                )}
              </Stack>
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
                    {category.name || name}
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
  const { access, department, jobDiscount, onstation, user, stock = {}, free_stock = {}, point_vendor } = data;
  const record = 'ref' in product ? product : undefined;
  // Остатки привязаны к записи: одинаковые названия и пути не объединяют товары.
  const remaining = point_vendor ? Infinity : 'amount' in product ? product.amount : stock[product.ref] ?? 0;
  const free = custom
    ? !!access || product.price === 0
    : !onstation || product.price === 0 || !!(record && free_stock[record.ref]);
  const discount = !point_vendor && !custom && !record?.premium && !!user && department === user.department;
  const price = discount ? Math.max(Math.round(product.price * jobDiscount), 1) : product.price;
  const insufficientFunds = !free && price > (user?.cash ?? 0);
  const priceColor = free ? 'green' : insufficientFunds ? 'red' : 'gold';
  const disabledReason = remaining <= 0 ? 'Закончился'
    : onstation && !user ? point_vendor ? 'Нужна ID-карта' : 'Нужна ID-карта с банковским счётом'
    : insufficientFunds ? 'Недостаточно средств'
    : '';
  const disabled = !!disabledReason;
  const fluid = data.vending_layout === 'list';
  const priceLabel = free ? 'Бесплатно' : `${price} ${point_vendor ? 'оч.' : 'кр.'}`;
  const displayName = capitalizeAll(product.name);

  return (
    <ImageButton
      data-product-key={record?.ref || product.name}
      fluid={fluid}
      imageSize={fluid ? 32 : 64}
      base64={'img' in product ? product.img : undefined}
      asset={record ? ['vending32x32', record.path] : undefined}
      disabled={disabled}
      tooltip={`${displayName} — ${priceLabel}${point_vendor ? '' : `, ${remaining} шт.`}${disabledReason ? ` — ${disabledReason}` : ''}`}
      tooltipPosition="bottom"
      buttonsAlt={!fluid && (
        <Stack fontSize={0.8}>
          <Stack.Item grow minWidth={0} textAlign="left" color={priceColor} style={{ overflow: 'hidden', textOverflow: 'ellipsis' }}>
            {free ? <Icon name="gift" /> : priceLabel}
          </Stack.Item>
          {!point_vendor && <Stack.Item shrink={0} color={remaining <= 0 ? 'red' : 'lightgray'}>x{remaining}</Stack.Item>}
        </Stack>
      )}
      onClick={() => custom
        ? act('dispense', { item: product.name })
        : act(point_vendor ? 'purchase' : 'vend', { ref: record?.ref })}>
      {fluid ? (
        <Stack align="center" textAlign="right">
          <Stack.Item grow textAlign="left">{displayName}</Stack.Item>
          {!point_vendor && <Stack.Item color={remaining <= 0 ? 'red' : 'label'} fontSize={0.8}>{remaining} шт.</Stack.Item>}
          <Stack.Item color={priceColor} fontSize={0.85}>{free ? <Icon name="gift" /> : priceLabel}</Stack.Item>
        </Stack>
      ) : displayName}
    </ImageButton>
  );
};

const CATEGORY_COLORS = {
  'Контрабанда': 'red',
  'Премиум': 'yellow',
};

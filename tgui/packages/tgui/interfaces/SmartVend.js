import { createSearch } from 'common/string';
import { useState } from 'react';

import { useBackend } from '../backend';
import { Button, ImageButton, Input, NoticeBox, NumberInput, Section, Stack } from '../components';
import { Window } from '../layouts';
import { LayoutToggle, useLayoutScroll } from './common/LayoutToggle';

export const SmartVend = () => {
  const { act, data } = useBackend();
  const { scrollableRef, onScroll } = useLayoutScroll(data.vending_layout);
  const [searchQuery, setSearchQuery] = useState('');
  const contentEntries = Object.entries(data.contents || {});
  const search = createSearch(searchQuery, ([, item]) => item.name);
  const filteredEntries = contentEntries.filter(search);

  return (
    <Window width={440} height={575}>
      <Window.Content>
        <Section
          fill
          scrollable
          scrollableRef={scrollableRef}
          onScroll={onScroll}
          title="Хранилище"
          buttons={
            <Stack>
              {!!data.isdryer && (
                <Stack.Item>
                  <Button
                    icon={data.drying ? 'stop' : 'tint'}
                    onClick={() => act('Dry')}>
                    {data.drying ? 'Остановить сушку' : 'Сушить'}
                  </Button>
                </Stack.Item>
              )}
              {!!data.vending_layout && <LayoutToggle />}
              <Stack.Item>
                <Button
                  icon="question"
                  tooltip={<>ЛКМ — выдать один предмет.<br />ПКМ — выдать все.<br />Введите количество больше одного для выдачи.<br />Esc — отменить ввод.</>}
                  tooltipPosition="bottom-end"
                />
              </Stack.Item>
            </Stack>
          }>
          <Stack align="center" mb={1}>
            <Stack.Item grow>
              <Input
                fluid
                placeholder="Поиск по названию..."
                value={searchQuery}
                onInput={(_, value) => setSearchQuery(value)}
                onKeyDown={(event) => {
                  if (event.key === 'Escape') {
                    setSearchQuery('');
                  }
                }}
              />
            </Stack.Item>
            {!!searchQuery && (
              <Stack.Item>
                <Button icon="times" tooltip="Очистить поиск" onClick={() => setSearchQuery('')} />
              </Stack.Item>
            )}
            <Stack.Item color="label" fontSize={0.9}>{searchQuery.trim() ? 'Найдено' : 'Позиций'}: {filteredEntries.length}</Stack.Item>
          </Stack>
          {!contentEntries.length ? (
            <NoticeBox>К несчастью, внутри {data.name} пусто.</NoticeBox>
          ) : !filteredEntries.length ? (
            <NoticeBox>Ничего не найдено.</NoticeBox>
          ) : filteredEntries.map(([key, item]) => (
            <FridgeItem
              key={key}
              item={item}
              fluid={data.vending_layout !== 'grid'}
            />
          ))}
        </Section>
      </Window.Content>
    </Window>
  );
};

const FridgeItem = ({ item, fluid }) => {
  const { act } = useBackend();
  const release = (amount) => act('Release', {
    path: item.path,
    name: item.name,
    amount,
  });
  return (
    <ImageButton
      data-product-key={item.path || item.name}
      fluid={fluid}
      imageSize={fluid ? 32 : 64}
      base64={item.img}
      imageSrc={item.image}
      disabled={item.amount < 1}
      tooltip={item.name}
      tooltipPosition="bottom"
      buttons={item.amount > 1 && (
        <NumberInput
          width={fluid ? '40px' : '28px'}
          minValue={1}
          maxValue={item.amount}
          step={1}
          value={1}
          onChange={(_, value) => {
            if (value > 1) {
              release(Math.floor(value));
            }
          }}
        />
      )}
      buttonsAlt={!fluid && (
        <Stack bold color="lightgray" fontSize={0.8}>
          <Stack.Item grow />
          <Stack.Item>x{item.amount}</Stack.Item>
        </Stack>
      )}
      onClick={() => release(1)}
      onRightClick={() => release(item.amount)}>
      {fluid ? (
        <Stack align="center">
          <Stack.Item grow textAlign="left">{item.name}</Stack.Item>
          <Stack.Item opacity={0.5} fontSize={0.8}>x{item.amount}</Stack.Item>
        </Stack>
      ) : item.name}
    </ImageButton>
  );
};

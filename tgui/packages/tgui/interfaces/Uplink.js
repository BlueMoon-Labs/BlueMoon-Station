import { createSearch, decodeHtmlEntities } from 'common/string';
import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Icon, Input, NoticeBox, Section, Stack, Tabs, Tooltip } from '../components';
import { formatMoney } from '../format';
import { Window } from '../layouts';

const MAX_SEARCH_RESULTS = 25;

const ItemIcon = (props) => {
  const { icon, size = 64 } = props;
  if (!icon) {
    return null;
  }
  const scale = size / 32;
  return (
    <Box
      width={size + 'px'}
      height={size + 'px'}
      style={{ overflow: 'hidden' }}>
      <span
        style={{
          display: 'inline-block',
          imageRendering: 'pixelated',
          transform: `scale(${scale})`,
          transformOrigin: 'top left',
        }}
        dangerouslySetInnerHTML={{ __html: icon }} />
    </Box>
  );
};

const ItemPlaceholder = (props) => {
  const { size } = props;
  return (
    <Box
      width={size}
      height={size}
      opacity={0.3}
      style={{ textAlign: 'center' }}>
      —
    </Box>
  );
};

export const Uplink = (props, context) => {
  const { data } = useBackend(context);
  const { telecrystals, uplink_type } = data;

  const theme = uplink_type === 'PACT Uplink' ? 'pact' : 'syndicate';

  return (
    <Window
      width={620}
      height={580}
      theme={theme}>
      <Window.Content overflow="auto">
        <GenericUplink
          currencyAmount={telecrystals}
          currencySymbol="TC" />
      </Window.Content>
    </Window>
  );
};

export const GenericUplink = (props) => {
  const {
    currencyAmount = 0,
    currencySymbol = 'cr',
  } = props;
  const { act, data } = useBackend();
  const {
    compactMode,
    lockable,
    categories = [],
  } = data;
  const [
    searchText,
    setSearchText,
  ] = useState('');
  const [
    selectedCategory,
    setSelectedCategory,
  ] = useState(categories[0]?.name);
  const testSearch = createSearch(searchText, item => {
    return item.name + item.desc;
  });
  const items = searchText.length > 0
    // Flatten all categories and apply search to it
    && categories
      .flatMap(category => category.items || [])
      .filter(testSearch)
      .filter((item, i) => i < MAX_SEARCH_RESULTS)
    // Select a category and show all items in it
    || categories
      .find(category => category.name === selectedCategory)
      ?.items
    // If none of that results in a list, return an empty list
    || [];
  return (
    <Stack fill>
      <Stack.Item width="160px">
        <Stack vertical fill>
          <Stack.Item>
            <Stack>
              <Stack.Item grow>
                <Button
                  bold
                  fluid
                  lineHeight={2}
                  color={currencyAmount > 0 ? 'good' : 'bad'}
                  tooltip="Buy raw TC"
                  onClick={() => act('buy_raw_tc')}
                  style={{
                    overflow: 'hidden',
                    whiteSpace: 'nowrap',
                    textOverflow: 'ellipsis',
                    textAlign: 'center',
                  }}
                  content={formatMoney(currencyAmount) + ' ' + currencySymbol} />
              </Stack.Item>
              <Stack.Item>
                <Button
                  fluid
                  lineHeight={2}
                  icon={compactMode ? 'maximize' : 'minimize'}
                  tooltip={compactMode ? 'Detailed view' : 'Compact view'}
                  onClick={() => act('compact_toggle')} />
              </Stack.Item>
              {!!lockable && (
                <Stack.Item>
                  <Button
                    fluid
                    lineHeight={2}
                    icon="lock"
                    tooltip="Lock"
                    onClick={() => act('lock')} />
                </Stack.Item>
              )}
            </Stack>
          </Stack.Item>
          <Stack.Item>
            <Input
              autoFocus
              value={searchText}
              placeholder="Search..."
              onInput={(e, value) => setSearchText(value)}
              fluid />
          </Stack.Item>
          <Stack.Item grow>
            <Tabs vertical fill>
              {categories.map(category => (
                <Tabs.Tab
                  py={0.8}
                  key={category.name}
                  selected={category.name === selectedCategory}
                  onClick={() => {
                    setSelectedCategory(category.name);
                    if (searchText.length > 0) {
                      setSearchText('');
                    }
                  }}>
                  {category.name}
                </Tabs.Tab>
              ))}
            </Tabs>
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item grow>
        <Box height="100%" pr={1} mr={-1}>
          {items.length === 0 ? (
            <NoticeBox>
              {searchText.length === 0
                ? 'No items in this category.'
                : 'No results found.'}
            </NoticeBox>
          ) : (
            <ItemList
              compactMode={searchText.length > 0 || compactMode}
              currencyAmount={currencyAmount}
              currencySymbol={currencySymbol}
              items={items} />
          )}
        </Box>
      </Stack.Item>
    </Stack>
  );
};

const ItemList = (props) => {
  const {
    compactMode,
    currencyAmount,
    currencySymbol,
  } = props;
  const { act } = useBackend();
  const [
    hoveredItem,
    setHoveredItem,
  ] = useState({});
  const hoveredCost = hoveredItem && hoveredItem.cost || 0;
  // Append extra hover data to items
  const items = props.items.map(item => {
    const notSameItem = hoveredItem && hoveredItem.name !== item.name;
    const notEnoughHovered = currencyAmount - hoveredCost < item.cost;
    const disabledDueToHovered = notSameItem && notEnoughHovered;
    const disabled = currencyAmount < item.cost || disabledDueToHovered;
    return {
      ...item,
      disabled,
    };
  });
  const buyButton = (item) => (
    <Button
      width="50px"
      textAlign="center"
      content={formatMoney(item.cost) + ' ' + currencySymbol}
      disabled={item.disabled}
      tooltip={item.desc}
      tooltipPosition="left"
      onMouseOver={() => setHoveredItem(item)}
      onMouseOut={() => setHoveredItem({})}
      onClick={() => act('buy', {
        name: item.name,
      })} />
  );
  if (compactMode) {
    return (
      <Section fill scrollable>
        <Stack vertical>
          {items.map(item => (
            <Stack.Item key={item.name} mt={0.5}>
              <Section fitted>
                <Stack align="center">
                  <Stack.Item>
                    <Box width="32px" height="32px" m="2px" mr={1}>
                      {item.icon ? (
                        <ItemIcon icon={item.icon} size={32} />
                      ) : (
                        <ItemPlaceholder size="32px" />
                      )}
                    </Box>
                  </Stack.Item>
                  <Stack.Item
                    bold
                    grow
                    lineHeight="36px"
                    style={{
                      overflow: 'hidden',
                      whiteSpace: 'nowrap',
                      textOverflow: 'ellipsis',
                    }}>
                    {decodeHtmlEntities(item.name)}
                  </Stack.Item>
                  <Stack.Item>
                    <Tooltip content={item.desc}>
                      <Box lineHeight="36px">
                        <Icon name="info-circle" />
                      </Box>
                    </Tooltip>
                  </Stack.Item>
                  <Stack.Item>
                    {buyButton(item)}
                  </Stack.Item>
                </Stack>
              </Section>
            </Stack.Item>
          ))}
        </Stack>
      </Section>
    );
  }
  return (
    <Section fill scrollable>
      <Stack vertical mt={-1}>
        {items.map(item => (
          <Stack.Item key={item.name} mt={1}>
            <Section>
              <Stack>
                <Stack.Item>
                  <Box width="64px" height="64px" mr={1}>
                    {item.icon ? (
                      <ItemIcon icon={item.icon} size={64} />
                    ) : (
                      <ItemPlaceholder size="64px" />
                    )}
                  </Box>
                </Stack.Item>
                <Stack.Item grow>
                  <Section
                    title={decodeHtmlEntities(item.name)}
                    level={2}
                    buttons={buyButton(item)}>
                    <Box style={{ opacity: '0.75' }}>
                      {decodeHtmlEntities(item.desc)}
                    </Box>
                  </Section>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

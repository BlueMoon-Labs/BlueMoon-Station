import { useState } from 'react';

import { resolveAsset } from '../assets';
import { useBackend } from '../backend';
import { Button, Flex, Input, NoticeBox, PixelArtImage, Section, Stack, Tabs } from '../components';
import { NtosWindow } from '../layouts';

export const NtosPortraitPrinter = (props) => {
  const { act, data } = useBackend();
  const [selectedTabIndex, setTabIndex] = useState(null);
  const [listIndex, setListIndex] = useState(0);
  const [query, setQuery] = useState('');
  const { is_admin = false } = data;
  const library = Array.isArray(data.library) ? data.library : [];
  const library_secure = Array.isArray(data.library_secure)
    ? data.library_secure
    : [];
  const library_private = Array.isArray(data.library_private)
    ? data.library_private
    : [];
  const library_large = Array.isArray(data.library_large)
    ? data.library_large
    : [];
  const library_large_private = Array.isArray(data.library_large_private)
    ? data.library_large_private
    : [];
  // null из DM не подхватывается дефолтом деструктуризации - приводим явно.
  const favorite_paintings_md5 = Array.isArray(data.favorite_paintings_md5)
    ? data.favorite_paintings_md5
    : [];

  const allPortraits = [
    ...library.map(p => ({ ...p, asset_prefix: 'library' })),
    ...library_secure.map(p => ({ ...p, asset_prefix: 'library_secure' })),
    ...library_private.map(p => ({ ...p, asset_prefix: 'library_private' })),
    ...library_large.map(p => ({ ...p, asset_prefix: 'library_large' })),
    ...library_large_private.map(p => ({ ...p, asset_prefix: 'library_large_private' })),
  ];

  const favoritesList = allPortraits.filter(p => favorite_paintings_md5.includes(p.md5));

  const TABS = [
    {
      name: 'Common',
      asset_prefix: "library",
      list: library,
    },
    {
      name: 'Secure',
      asset_prefix: "library_secure",
      list: library_secure,
    },
    {
      name: 'Private',
      asset_prefix: "library_private",
      list: library_private,
    },
    {
      name: 'Large',
      asset_prefix: "library_large",
      list: library_large,
    },
    {
      name: 'Large Private',
      asset_prefix: "library_large_private",
      list: library_large_private,
    },
    {
      name: 'Favorite',
      asset_prefix: null, // префикс берём из самих портретов
      list: favoritesList,
    },
  ];
  const tabIndex = selectedTabIndex ?? Math.max(0, TABS.findIndex(tab => tab.list.length > 0));
  const baseList = TABS[tabIndex].list;
  const normalizedQuery = query.toLowerCase();
  const filteredList = normalizedQuery
    ? baseList.filter(portrait => String(portrait.title).toLowerCase().includes(normalizedQuery))
    : baseList;

  const hasPortraits = filteredList.length > 0;
  const safeIndex = hasPortraits
    ? Math.min(listIndex, filteredList.length - 1)
    : 0;

  // СНАЧАЛА вычисляем currentPortrait
  const currentPortrait = hasPortraits ? filteredList[safeIndex] : null;

  // Потом всё, что от него зависит
  const isFavorite = !!currentPortrait
    && favorite_paintings_md5.includes(currentPortrait.md5);

  const current_portrait_title = currentPortrait
    ? currentPortrait.title
    : 'Картин не найдено';

  const current_portrait_asset_prefix = currentPortrait
    ? (TABS[tabIndex].asset_prefix || currentPortrait.asset_prefix)
    : '';

  const current_portrait_asset_name = currentPortrait
    ? current_portrait_asset_prefix + '_' + currentPortrait.md5
    : '';

  return (
    <NtosWindow
      title="Art Galaxy"
      width={400}
      height={420}>
      <NtosWindow.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Section fitted>
              <Tabs fluid textAlign="center">
                {TABS.map((tabObj, i) => (
                  <Tabs.Tab
                    key={i}
                    selected={i === tabIndex}
                    onClick={() => {
                      setListIndex(0);
                      setTabIndex(i);
                    }}>
                    {tabObj.name}
                  </Tabs.Tab>
                ))}
              </Tabs>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Section>
              <Stack>
                <Stack.Item grow>
                  <Input
                    fluid
                    placeholder="Поиск картин..."
                    value={query}
                    onInput={(_e, value) => {
                      if (query === "" && value !== "") {
                        setListIndex(0);
                      }
                      setQuery(value);
                    }}
                  />
                </Stack.Item>
                <Stack.Item>
                  {hasPortraits && (
                    <Button
                      icon="star"
                      color="transparent"
                      selected={isFavorite}
                      onClick={() => act('toggle_favorite', {
                        md5: currentPortrait.md5,
                      })}
                    />
                  )}
                  {hasPortraits && !!is_admin && (
                    <Button.Confirm
                      icon="trash"
                      color="bad"
                      tooltip="Удалить картину из галереи"
                      tooltipPosition="bottom"
                      confirmContent="Вы уверены?"
                      onClick={() => act('delete_painting', {
                        md5: currentPortrait.md5,
                        asset_prefix: current_portrait_asset_prefix,
                      })}
                    />
                  )}
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
          <Stack.Item grow={2}>
            <Section fill>
              <Flex
                height="100%"
                align="center"
                justify="center"
                direction="column">
                {hasPortraits && (
                  <Flex.Item>
                    <PixelArtImage
                      src={resolveAsset(current_portrait_asset_name)}
                      fit="contain"
                      maxHeight={128}
                      maxWidth={128}
                      containerStyle={{
                        width: '128px',
                      }} />
                  </Flex.Item>
                )}
                <Flex.Item className="Section__titleText">
                  {current_portrait_title}
                </Flex.Item>
              </Flex>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Stack>
              <Stack.Item grow={3}>
                <Section height="100%">
                  <Stack justify="space-between">
                    <Stack.Item grow={1}>
                      <Button
                        icon="angle-double-left"
                        disabled={!hasPortraits || safeIndex === 0}
                        onClick={() => setListIndex(0)}
                      />
                    </Stack.Item>
                    <Stack.Item grow={3}>
                      <Button
                        disabled={!hasPortraits || safeIndex === 0}
                        icon="chevron-left"
                        onClick={() => setListIndex(safeIndex - 1)}
                      />
                    </Stack.Item>
                    <Stack.Item grow={3}>
                      <Button
                        icon="check"
                        disabled={!hasPortraits}
                        content="Распечатать картину"
                        onClick={() => act("select", {
                          md5: currentPortrait.md5,
                          asset_prefix: current_portrait_asset_prefix,
                        })}
                      />
                    </Stack.Item>
                    <Stack.Item grow={1}>
                      <Button
                        icon="chevron-right"
                        disabled={!hasPortraits || safeIndex === filteredList.length - 1}
                        onClick={() => setListIndex(safeIndex + 1)}
                      />
                    </Stack.Item>
                    <Stack.Item>
                      <Button
                        icon="angle-double-right"
                        disabled={!hasPortraits || safeIndex === filteredList.length - 1}
                        onClick={() => setListIndex(filteredList.length - 1)}
                      />
                    </Stack.Item>
                  </Stack>
                </Section>
              </Stack.Item>
            </Stack>
            <Stack.Item mt={1} mb={-1}>
              <NoticeBox info>
                Printing a canvas costs 5 paper from
                the printer installed in your machine.
              </NoticeBox>
            </Stack.Item>
          </Stack.Item>
        </Stack>
      </NtosWindow.Content>
    </NtosWindow>
  );
};

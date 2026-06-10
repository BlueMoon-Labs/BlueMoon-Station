import { createSearch } from 'common/string';
import { useState } from 'react';

import { useBackend } from '../backend';
import { Button, Input, NoticeBox, Section, Table } from '../components';
import { Window } from '../layouts';

export const SmartVend = (props) => {
  const { act, data } = useBackend();
  const [searchQuery, setSearchQuery] = useState('');
  const rawContents = data.contents || {};
  const contentEntries = Object.entries(rawContents);
  const searchable = !!data.searchable;
  const testSearch = searchable
    ? createSearch(searchQuery, ([, row]) => row.name + (row?.type ?? ''))
    : null;
  const filteredEntries = searchable && searchQuery.length
    ? contentEntries.filter((entry) => testSearch(entry))
    : contentEntries;
  const empty = contentEntries.length === 0;
  const searchEmpty = searchable && !!searchQuery && filteredEntries.length === 0 && !empty;
  const windowWidth = searchable ? 480 : 440;
  return (
    <Window
      width={windowWidth}
      height={560}>
      <Window.Content overflow="auto">
        <Section
          title="Хранилище"
          buttons={!!data.isdryer && (
            <Button
              icon={data.drying ? 'stop' : 'tint'}
              onClick={() => act('Dry')}>
              {data.drying ? 'Stop drying' : 'Dry'}
            </Button>
          )}>
          {searchable && (
            <Input
              fluid
              placeholder="Поиск по названию или типу..."
              value={searchQuery}
              onInput={(e, val) => setSearchQuery(val)}
              mb={1}
            />
          )}
          {empty ? (
            <NoticeBox>
              К несчастью, внутри {data.name} пусто.
            </NoticeBox>
          ) : (
            <>
              {searchEmpty && (
                <NoticeBox>
                  Ничего не найдено.
                </NoticeBox>
              )}
              {(searchEmpty ? [] : filteredEntries).length > 0 && (
                <Table>
                  <Table.Row header>
                    <Table.Cell>
                      Содержимое:
                    </Table.Cell>
                    <Table.Cell collapsing />
                    <Table.Cell collapsing textAlign="center">
                      {data.verb ? data.verb : 'Выдать'}
                    </Table.Cell>
                  </Table.Row>
                  {(searchEmpty ? [] : filteredEntries).map(([key, value]) => (
                    <Table.Row key={key}>
                      <Table.Cell>
                        {value.name}
                      </Table.Cell>
                      <Table.Cell collapsing textAlign="right">
                        {value.amount}
                      </Table.Cell>
                      <Table.Cell collapsing>
                        <Button
                          content="Одно"
                          disabled={value.amount < 1}
                          onClick={() => act('Release', {
                            name: value.name,
                            amount: 1,
                          })} />
                        <Button
                          content="Неск."
                          disabled={value.amount <= 1}
                          onClick={() => act('Release', {
                            name: value.name,
                          })} />
                      </Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              )}
            </>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};

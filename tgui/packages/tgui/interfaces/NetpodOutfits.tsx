import { Fragment, useState } from 'react';

import { createSearch } from '../../common/string';
import { useBackend } from '../backend';
import {
  Button,
  Divider,
  Input,
  NoticeBox,
  Section,
  Stack,
  Tabs,
} from '../components';
import { Window } from '../layouts';

type Data = {
  netsuit: string;
  collections: Collection[];
  types: string[];
};

type Collection = {
  name: string;
  outfits: Outfit[];
};

type Outfit = {
  path: string;
  name: string;
  type: string;
};

export const NetpodOutfits = (props) => {
  const { act, data } = useBackend<Data>();
  const { netsuit, collections = [] } = data;
  const [selectedCollection, setSelectedCollection] = useState<string | null>(
    null
  );
  const [search, setSearch] = useState('');

  const selectedType =
    collections.find((collection) => collection.name === selectedCollection) ||
    collections[0];

  const searchFn = createSearch(search, (outfit: Outfit) => outfit.name);

  const filtered = selectedType?.outfits
    ?.filter(searchFn)
    .sort((a, b) => a.name.localeCompare(b.name));

  const selected =
    selectedType?.outfits?.find((outfit) => outfit.path === netsuit)?.name ??
    'Нет';

  return (
    <Window title="Net Pod" height={300} width={400}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item grow>
            <Section
              fill
              title="Выберите экипировку"
              buttons={
                <Input
                  autoFocus
                  onInput={(_, value) => setSearch(value)}
                  placeholder="Поиск"
                  value={search}
                />
              }
            >
              <Stack fill>
                <Stack.Item grow>
                  <Tabs vertical>
                    {collections.map((collection, index) => (
                      <Fragment key={collection.name}>
                        <Tabs.Tab
                          onClick={() => setSelectedCollection(collection.name)}
                          selected={selectedType?.name === collection.name}
                        >
                          {collection.name}
                        </Tabs.Tab>
                        {index > 0 && <Divider />}
                      </Fragment>
                    ))}
                  </Tabs>
                </Stack.Item>
                <Stack.Divider />
                <Stack.Item grow={5}>
                  <Section fill scrollable>
                    {(filtered || []).map(({ path, name }) => (
                      <Stack.Item className="candystripe" key={path}>
                        <Button
                          selected={netsuit === path}
                          color="transparent"
                          onClick={() => act('select_outfit', { outfit: path })}
                        >
                          {name}
                        </Button>
                      </Stack.Item>
                    ))}
                  </Section>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <NoticeBox info align="right">
              {selected}
            </NoticeBox>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

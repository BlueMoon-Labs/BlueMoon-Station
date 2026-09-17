import { sortBy } from 'common/collections';
import { Dispatch, SetStateAction, useEffect, useMemo, useState } from 'react';
import {
  BlockQuote,
  Button,
  Icon,
  ImageButton,
  Modal,
  Section,
  Stack,
  Tabs,
  Tooltip,
} from '../../components';
import { formatMoney } from '../../format';

import { useBackend, useSharedState } from '../../backend';
import { SearchBar } from '../common/SearchBar';
import { searchForSupplies } from './helpers';
import {
  CargoData,
  InventoryInfo,
  Supply,
  SupplyCategory,
} from './types';

type Props = {
  express?: boolean;
};

export function CargoCatalog(props: Props) {
  const { act, data } = useBackend<CargoData>();
  const { inventory_updates, supplies: suppliesMap, max_order } = data;
  const { express } = props;

  const supplies = Object.values(suppliesMap || {});
  const [showContents, setShowContents] = useState('');
  const [searchText, setSearchText] = useSharedState('search_text', '');
  const [inventory, setInventory] = useState<Record<string, InventoryInfo>>(
    {},
  );
  const [activeSupplyName, setActiveSupplyName] = useSharedState(
    'supply',
    supplies[0]?.name,
  );

  // Иконки/содержимое приходят отдельным пушем после act('get_inventory').
  useEffect(() => {
    if (inventory_updates && Object.keys(inventory_updates).length > 0) {
      setInventory((prev) => ({ ...prev, ...inventory_updates }));
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [inventory_updates]);

  const packs = useMemo(() => {
    let fetched: Supply[] | undefined;

    if (activeSupplyName === 'search_results') {
      fetched = searchForSupplies(supplies, searchText);
    } else {
      fetched = supplies.find(
        (supply) => supply.name === activeSupplyName,
      )?.packs;
    }

    if (!fetched) {
      return [];
    }

    fetched = sortBy(fetched, (pack: Supply) => pack.name);

    return fetched;
  }, [activeSupplyName, supplies, searchText]);

  // Запрашиваем иконки/содержимое паков текущей вкладки.
  useEffect(() => {
    const fetchedIds: Record<string, boolean> = {};
    for (const id in inventory) {
      fetchedIds[id] = true;
    }
    const ids = packs
      .filter((pack) => !fetchedIds[pack.id])
      .map((pack) => pack.id);
    if (ids.length > 0) {
      act('get_inventory', { ids });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeSupplyName, searchText, act]);

  return (
    <>
      {showContents && (
        <CatalogPackInfo
          packs={packs}
          inventory={inventory}
          name={showContents}
          closeContents={setShowContents}
        />
      )}
      <Stack fill g={0}>
        <Stack.Item grow mr={-0.33}>
          <Section fill>
            <CatalogTabs
              express={express}
              activeSupplyName={activeSupplyName}
              categories={supplies}
              searchText={searchText}
              setActiveSupplyName={setActiveSupplyName}
              setSearchText={setSearchText}
            />
          </Section>
        </Stack.Item>
        <Stack.Divider />
        <Stack.Item grow={express ? 2 : 3}>
          <Section fill scrollable>
            <CatalogList
              packs={packs}
              inventory={inventory}
              openContents={setShowContents}
            />
          </Section>
        </Stack.Item>
      </Stack>
    </>
  );
}

type CatalogTabsProps = {
  activeSupplyName: string;
  categories: SupplyCategory[];
  searchText: string;
  setActiveSupplyName: (name: string) => void;
  setSearchText: (text: string) => void;
};

function CatalogTabs(props: CatalogTabsProps & Props) {
  const { act, data } = useBackend<CargoData>();
  const {
    activeSupplyName,
    categories,
    searchText,
    setActiveSupplyName,
    setSearchText,
    express,
  } = props;
  const { self_paid } = data;

  const sorted = sortBy(categories, (supply) => supply.name);

  return (
    <Stack fill vertical>
      <Stack.Item>
        <SearchBar
          query={searchText}
          onSearch={(value) => {
            if (value === searchText) {
              return;
            }

            if (value.length) {
              // Start showing results
              setActiveSupplyName('search_results');
            } else if (activeSupplyName === 'search_results') {
              // return to normal category
              setActiveSupplyName(sorted[0]?.name);
            }
            setSearchText(value);
          }}
        />
      </Stack.Item>
      <Stack.Item grow p={1} m={-1} mt={1} overflowY="auto">
        <Tabs vertical>
          <Tabs.Tab
            key="search_results"
            selected={activeSupplyName === 'search_results'}
            style={{ display: 'none' }}
          />

          {sorted.map((supply) => (
            <Tabs.Tab
              className="candystripe"
              color={supply.name === activeSupplyName ? 'green' : undefined}
              key={supply.name}
              selected={supply.name === activeSupplyName}
              onClick={() => {
                setActiveSupplyName(supply.name);
                setSearchText('');
              }}
            >
              <Stack justify="space-between">
                <span>{supply.name}</span>
                <span> {supply.packs.length}</span>
              </Stack>
            </Tabs.Tab>
          ))}
        </Tabs>
      </Stack.Item>
      <Stack.Item>
        {!express && (
          <Button
            fluid
            color={self_paid ? 'caution' : 'transparent'}
            icon={self_paid ? 'check-square-o' : 'square-o'}
            onClick={() => act('toggleprivate')}
            tooltip="Use your own funds to purchase items."
            tooltipPosition="top"
          >
            Buy Privately
          </Button>
        )}
      </Stack.Item>
    </Stack>
  );
}

type CatalogListProps = {
  packs: SupplyCategory['packs'];
  inventory: Record<string, InventoryInfo>;
  openContents: Dispatch<SetStateAction<string>>;
};

function CatalogList(props: CatalogListProps) {
  const { act, data } = useBackend<CargoData>();
  const { amount_by_name = {}, max_order, self_paid } = data;
  const { packs = [], inventory = {}, openContents } = props;

  return (
    <>
      {packs.map((pack) => {
        let color = '';
        const digits = Math.floor(Math.log10(pack.cost) + 1);
        if (self_paid) {
          color = 'yellow';
        } else if (digits >= 5 && digits <= 6) {
          color = 'orange';
        } else if (digits > 6) {
          color = 'bad';
        }

        const privateBuy = self_paid && !pack.goody;
        const tooltipIcon = (content: string, icon: string, color: string) => (
          <Stack.Item>
            <Tooltip content={content}>
              <Icon color={color} name={icon} />
            </Tooltip>
          </Stack.Item>
        );

        return (
          <ImageButton
            key={pack.id}
            fluid
            img={inventory[pack.id]?.icon}
            imageSize={32}
            color={color}
            disabled={(amount_by_name[pack.name] || 0) >= max_order}
            buttonsAlt={
              <Button
                color="transparent"
                icon="info"
                onClick={() => openContents(pack.name)}
              />
            }
            onClick={() =>
              act('add', {
                id: pack.id,
              })
            }
          >
            <Stack fill textAlign="right">
              <Stack.Item grow textAlign="left">
                {pack.name}
              </Stack.Item>
              {(!!pack.small_item || !!pack.access || !!pack.contraband) && (
                <Stack.Item>
                  <Stack>
                    {!!pack.small_item &&
                      tooltipIcon('Small Item', 'compress-alt', 'purple')}
                    {!!pack.access &&
                      tooltipIcon('Restricted', 'lock', 'average')}
                    {!!pack.contraband &&
                      tooltipIcon('Contraband', 'pastafarianism', 'bad')}
                  </Stack>
                </Stack.Item>
              )}
              <Stack.Item align="center" width={5.5} mt={-0.75} mb={-0.75}>
                <Stack vertical color="gold" lineHeight={0.75} fontSize={0.85}>
                  <Stack.Item
                    opacity={privateBuy && 0.75}
                    style={{ textDecoration: privateBuy && 'red line-through' }}
                  >
                    {formatMoney(pack.cost)} cr
                  </Stack.Item>
                  {!!privateBuy && (
                    <Stack.Item>
                      {formatMoney(Math.round(pack.cost * 1.1))} cr
                    </Stack.Item>
                  )}
                </Stack>
              </Stack.Item>
            </Stack>
          </ImageButton>
        );
      })}
    </>
  );
}

type CatalogContentsProps = {
  name: string;
  closeContents: Dispatch<SetStateAction<string>>;
  packs: SupplyCategory['packs'];
  inventory: Record<string, InventoryInfo>;
};

function CatalogPackInfo(props: CatalogContentsProps) {
  const { name, packs, inventory = {}, closeContents } = props;
  const pack = packs.find((pack) => pack.name === name);
  const contains = pack && inventory[pack.id];

  return (
    <Modal p={1} width="50vw" height="50vh">
      <Stack fill vertical>
        <Stack.Item>
          <Section
            fill
            title={name}
            buttons={
              <Button
                icon="close"
                color="bad"
                onClick={() => closeContents('')}
              />
            }
          >
            <BlockQuote>{pack?.desc || 'No description available.'}</BlockQuote>
          </Section>
        </Stack.Item>
        <Stack.Item m={0} grow>
          <Section fill scrollable>
            {contains && contains.contents && contains.contents.length > 0 ? (
              contains.contents.map((item) => (
                <ImageButton key={item.name} fluid imageSize={32}>
                  <Stack fill>
                    <Stack.Item textAlign="left">{item.name}</Stack.Item>
                    <Stack.Item textAlign="right" width={3}>
                      {!!item.amount && `x${item.amount}`}
                    </Stack.Item>
                  </Stack>
                </ImageButton>
              ))
            ) : (
              <Stack fill vertical align="center" justify="center">
                <Stack.Item>
                  <Icon
                    name="triangle-exclamation"
                    size={6}
                    color="orange"
                  />
                </Stack.Item>
                <Stack.Item mt={2} color="label" textAlign="center">
                  {`We can't find information about even the approximate contents
                  of this order.`}
                </Stack.Item>
              </Stack>
            )}
          </Section>
        </Stack.Item>
      </Stack>
    </Modal>
  );
}

import { classes } from 'common/react';
import { createSearch } from 'common/string';

import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Dimmer,
  Flex,
  Icon,
  Input,
  NoticeBox,
  Section,
  Table,
  Tabs,
  Collapsible,
} from '../components';
import { Window } from '../layouts';

import { Materials, MaterialAmount, MaterialFormatting } from './common/Materials';

const COLOR_NONE = 0;
const COLOR_AVERAGE = 1;
const COLOR_BAD = 2;

const COLOR_KEYS = {
  [COLOR_NONE]: false,
  [COLOR_AVERAGE]: 'average',
  [COLOR_BAD]: 'bad',
};

// need/have -> BAD если не хватает
const partBuildColor = (need, have) => {
  if (need > have) {
    return { color: COLOR_BAD, deficit: (need - have) };
  }
  return { color: COLOR_NONE, deficit: 0 };
};

const mulCost = (costObj, mult) => {
  const out = {};
  if (!costObj) return out;
  const m = mult ?? 1;
  for (const k of Object.keys(costObj)) {
    out[k] = (costObj[k] ?? 0) * m;
  }
  return out;
};

const materialArrayToObj = (materials) => {
  const obj = {};
  (materials || []).forEach((m) => {
    if (!m?.name) return;
    obj[m.name] = Number(m.amount) || 0;
  });
  return obj;
};

// Map reagent id -> amount available
const chemsArrayToAmountById = (chems) => {
  const obj = {};
  (chems || []).forEach((c) => {
    if (!c?.id) return;
    obj[c.id] = Number(c.amount) || 0;
  });
  return obj;
};

// Map reagent id -> display name
const chemsArrayToNameById = (chems) => {
  const obj = {};
  (chems || []).forEach((c) => {
    if (!c?.id) return;
    obj[c.id] = c.name || String(c.id);
  });
  return obj;
};

// Цвет по материалам + химии (для amount)
const calcTextColor = (materialsObj, chemsHaveById, item, amount = 1) => {
  let textColor = COLOR_NONE;
  const mult = amount ?? 1;

  // материалы: item.cost = { iron: 2000, ... }
  const matCost = item?.cost || {};
  for (const mat of Object.keys(matCost)) {
    const have = materialsObj?.[mat] ?? 0;
    const need = (Number(matCost[mat]) || 0) * mult;
    const { color } = partBuildColor(need, have);
    if (color > textColor) textColor = color;
  }

  // химия: item.cost_chem = [{name,id,amount}, ...]
  const chemList = item?.cost_chem;
  if (Array.isArray(chemList)) {
    for (const chem of chemList) {
      const id = chem?.id;
      if (!id) continue;
      const have = chemsHaveById?.[id] ?? 0;
      const need = (Number(chem.amount) || 0) * mult;
      const { color } = partBuildColor(need, have);
      if (color > textColor) textColor = color;
    }
  }

  return textColor;
};

const clampInt = (n, min, max) => Math.max(min, Math.min(max, Math.floor(n)));

const calcMaxBuild = (materialsObj, chemsHaveById, item, limit = 60) => {
  let maxByMats = Infinity;
  const matCost = item?.cost || {};
  for (const mat of Object.keys(matCost)) {
    const needOne = Number(matCost[mat]) || 0;
    if (needOne <= 0) continue;
    const have = Number(materialsObj?.[mat]) || 0;
    maxByMats = Math.min(maxByMats, Math.floor(have / needOne));
  }

  let maxByChems = Infinity;
  const chemList = item?.cost_chem;
  if (Array.isArray(chemList)) {
    for (const chem of chemList) {
      const id = chem?.id;
      if (!id) continue;
      const needOne = Number(chem.amount) || 0;
      if (needOne <= 0) continue;
      const have = Number(chemsHaveById?.[id]) || 0;
      maxByChems = Math.min(maxByChems, Math.floor(have / needOne));
    }
  }

  // если вообще нет затрат ни в матах, ни в химии — считаем что можно limit
  const hasAnyCost = Object.keys(matCost).length > 0 || (Array.isArray(chemList) && chemList.length > 0);
  let maxBuild = hasAnyCost ? Math.min(maxByMats, maxByChems) : limit;

  if (!Number.isFinite(maxBuild)) maxBuild = limit;
  return clampInt(maxBuild, 0, limit);
};

const costTooltipNode = (item, amt, materialsObj, chemsHaveById, chemsNameById) => {
  const mult = amt ?? 1;

  const matCost = item?.cost || {};
  const matKeys = Object.keys(matCost);

  const chemList = item?.cost_chem;
  const hasChems = Array.isArray(chemList) && chemList.length > 0;

  if (!matKeys.length && !hasChems) return '';

  const scaledMats = mulCost(matCost, mult);

  return (
    <div>
      {!!matKeys.length && matKeys.map((mat) => {
        const need = Number(scaledMats?.[mat]) || 0;
        const have = Number(materialsObj?.[mat]) || 0;
        const bad = need > have;

        return (
          <div
            key={mat}
            style={{
              display: 'inline-block',
              margin: '2px',
            }}
          >
            <MaterialAmount
              formatting={MaterialFormatting.Sheets}
              color={bad ? COLOR_KEYS[COLOR_BAD] : false}
              style={{
                transform: 'scale(0.75) translate(0%, 10%)',
              }}
              name={mat}
              amount={need}
            />
          </div>
        );
      })}

      {hasChems && (
        <Section title="Chemicals">
          {chemList.map((chem) => {
            const id = chem?.id;
            if (!id) return null;

            const name = chem?.name || chemsNameById?.[id] || String(id);
            const need = (Number(chem.amount) || 0) * mult;
            const have = Number(chemsHaveById?.[id]) || 0;

            const bad = need > have;
            return (
              <Box
                key={String(id)}
                color={bad ? COLOR_KEYS[COLOR_BAD] : false}
              >
                <Icon name="flask" mr={0.5} />{name}: {need}u
              </Box>
            );
          })}
        </Section>
      )}
    </div>
  );
};

export const Fabricator = (props, context) => {
  const { data } = useBackend(context);
  const { busy } = data;

  return (
    <Window width={900} height={800}>
      {!!busy && (
        <Dimmer fontSize="32px">
          <Icon name="cog" spin={1} />
          {' Production...'}
        </Dimmer>
      )}
      <Window.Content overflow="auto">
        <FabricatorContent />
      </Window.Content>
    </Window>
  );
};

export const FabricatorContent = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    categories = [],
    materials = [],
    materials_text,
    chems = [],
    chems_maximum,
    chems_total_volume,
    hacked,
    current_sec_level,
    onHold,
    maxBuildButtonAmount,
  } = data;

  const chems_sorted = (chems || []).slice().sort((a, b) => {
    const descA = (a.name || '').toLowerCase();
    const descB = (b.name || '').toLowerCase();
    if (descA < descB) return -1;
    if (descA > descB) return 1;
    return 0;
  });

  const [searchText, setSearchText] = useLocalState(context, 'searchText', '');
  const [selectedCategory, setSelectedCategory] = useLocalState(
    context,
    'category',
    categories[0]?.name,
  );

  const testSearch = createSearch(searchText, (item) => item.name);
  const MAX_SEARCH_RESULTS = 80;
  const searchIsActive = searchText.length > 1

  const items = (searchIsActive
    ? categories
      .flatMap((c) => c.items || [])
      .filter(testSearch)
      .filter((_, i) => i < MAX_SEARCH_RESULTS)
    : categories.find((c) => c.name === selectedCategory)?.items) || [];

  const materialsObj = materialArrayToObj(materials);
  const chemsHaveById = chemsArrayToAmountById(chems);
  const chemsNameById = chemsArrayToNameById(chems);

  return (
    <Section>
      <Flex direction="column">
        <Flex.Item>
          <Collapsible
            open
            title={materials_text
              ? `Materials: ${materials_text}${onHold ? " (RESOURCES ON HOLD)" : ""}`
              : 'No material storage connected, please contact the quartermaster.'
            }
            color="transparent"
          >
            <Materials
              formatting={MaterialFormatting.Sheets}
              materials={materials || []}
              onEject={(ref, amount) => {
                act('remove_mat', { ref, amount });
              }}
            />
          </Collapsible>
        </Flex.Item>

        <Flex.Item mb={2.5}>
          <Collapsible title="Chemicals" color="transparent">
            <Section
              title={`Stored Chemicals: ${chems_total_volume}u / ${chems_maximum}u`}
              buttons={(
                <Button.Confirm
                  color="bad"
                  icon="trash"
                  content="Purge all"
                  confirmIcon="trash"
                  confirmContent="Confirm?"
                  disabled={!chems_sorted.length}
                  onClick={() => act('purge_chem', { chem: 'all' })}
                />
              )}
            >
              {chems_sorted.map((chem) => (
                <Button.Confirm
                  key={chem.name}
                  color="label"
                  icon="flask"
                  content={`${chem.name}: ${chem.amount}u`}
                  confirmIcon="trash"
                  confirmContent="Purge?"
                  onClick={() => act('purge_chem', { chem: chem.id })}
                />
              ))}
            </Section>
          </Collapsible>
        </Flex.Item>

        <Flex.Item>
          <Section
            title={hacked ? 'Designs (Safety protocols: DISABLED)' : 'Designs'}
            buttons={(
              <>
                Search:
                <Input
                  autoFocus
                  value={searchText}
                  onInput={(e, value) => setSearchText(value)}
                  mx={1}
                />
                <Button
                  icon="rotate"
                  content="Sync Research"
                  onClick={() => act('sync_research')}
                />
              </>
            )}
          >
            <Flex>
              {!searchIsActive && (
                <Flex.Item>
                  <Tabs vertical>
                    {categories
                      .filter((c) => c.items?.length)
                      .map((category) => (
                        <Tabs.Tab
                          mr={1.5}
                          key={category.name}
                          selected={category.name === selectedCategory}
                          onClick={() => {
                            setSelectedCategory(category.name);
                            const ae = document.activeElement;
                            ae?.blur?.();
                          }}
                        >
                          {category.name} ({category.items.length})
                        </Tabs.Tab>
                      ))}
                  </Tabs>
                </Flex.Item>
              )}

              <Flex.Item grow={1} basis={0}>
                {items.length === 0 && (
                  <NoticeBox>
                    {!searchIsActive
                      ? 'No items in this category.'
                      : 'No results found.'}
                  </NoticeBox>
                )}

                <Table>
                  <ItemList
                    items={items}
                    materialsObj={materialsObj}
                    chemsHaveById={chemsHaveById}
                    chemsNameById={chemsNameById}
                    curSecLevel={current_sec_level}
                    maxBuildButtonAmount={maxBuildButtonAmount}
                  />
                </Table>
              </Flex.Item>
            </Flex>
          </Section>
        </Flex.Item>
      </Flex>
    </Section>
  );
};

const ItemList = (props, context) => {
  const { act } = useBackend(context);
  const {
    items,
    materialsObj,
    chemsHaveById,
    chemsNameById,
    curSecLevel,
    maxBuildButtonAmount = 60,
  } = props;

  const button_amounts = [5, 20];
  const ROW_BTN_HEIGHT = '32px';

  return (items || []).map((item) => {
    const color1 = calcTextColor(materialsObj, chemsHaveById, item, 1);
    const secLevelAllow = curSecLevel >= item.min_sec_level && curSecLevel <= item.max_sec_level
    const maxBuild = calcMaxBuild(materialsObj, chemsHaveById, item, maxBuildButtonAmount);

    return (
      <Table.Row key={item.id}>
        <Table.Cell collapsing>
          <Flex align="center">
            <Flex.Item>
              <Button
                color="transparent"
                tooltip={item.desc}
                style={{
                  padding: 0,
                  height: ROW_BTN_HEIGHT,
                }}
              >
                <Icon mt={1.35} ml={0.7} name="circle-question" />
              </Button>
            </Flex.Item>
            {item.sec_desc && (
              <Flex.Item>
                <Button
                  color="transparent"
                  tooltip={<Box color="yellow">{item.sec_desc}</Box>}
                  style={{
                    padding: 0,
                    height: ROW_BTN_HEIGHT,
                  }}
                >
                  <Icon mt={1.35} ml={0.7} name="triangle-exclamation" color={!secLevelAllow && "orange"} />
                </Button>
              </Flex.Item>
            )}
          </Flex>
        </Table.Cell>

        <Table.Cell>
          <Button
            fluid
            color="transparent"
            tooltip={costTooltipNode(item, 1, materialsObj, chemsHaveById, chemsNameById)}
            tooltipPosition="bottom-start"
            style={{
              padding: 0,
              height: ROW_BTN_HEIGHT,
              display: 'flex',
            }}
            onClick={() => act('build', { id: item.id, amount: 1 })}
          >
            <Flex align="center">
              <Flex.Item mr={1}>
                <span className={classes(['design32x32', item.id])} />
              </Flex.Item>
              <Flex.Item color={COLOR_KEYS[color1]}>
                <b style={{ lineHeight: ROW_BTN_HEIGHT }}>{item.name}</b>
              </Flex.Item>
            </Flex>
          </Button>
        </Table.Cell>

        <Table.Cell collapsing>
          <Flex align="center">
            {button_amounts.map((amt) => {
              const colorN = calcTextColor(materialsObj, chemsHaveById, item, amt);
              return (
                <Flex.Item key={amt}>
                  <Button
                    color="transparent"
                    tooltip={costTooltipNode(item, amt, materialsObj, chemsHaveById, chemsNameById)}
                    tooltipPosition="left"
                    style={{
                      height: ROW_BTN_HEIGHT,
                    }}
                    onClick={() => act('build', { id: item.id, amount: amt })}
                    content={
                      <Box mt={1} color={COLOR_KEYS[colorN]}>
                        {`x${amt}`}
                      </Box>
                    }
                  />

                </Flex.Item>
              );
            })}
            <Flex.Item>
              <Button.Input
                color="transparent"
                style={{ height: ROW_BTN_HEIGHT }}
                content={
                  <Box mt={1} color={maxBuild <= 0 && 'bad'}>
                    {`Max: x${maxBuild}`}
                  </Box>
                }
                onCommit={(e, value) => {
                  // value приходит строкой
                  const raw = Number(value);
                  act('build', { id: item.id, amount: raw });
                }}
              />
            </Flex.Item>
          </Flex>
        </Table.Cell>
      </Table.Row>
    );
  });
};

import { BooleanLike } from 'common/react';
import { useBackend, useSharedState } from "../backend";
import { Button, Tabs, NoticeBox, Section, Input, Box, Stack, Flex, Icon, ProgressBar } from "../components";
import { Window } from "../layouts";
import { Fragment } from 'inferno';
import { createSearch } from 'common/string';

const Upgrades = {
  advanced: 1 << 0,
  fast_cloning: 1 << 1,
};

type CircuitData = {
  name: string;
  desc: string;
  request_adv: BooleanLike;
  cost: number;
  path: string;
  icon?: string;
};

type CategoryInfo = {
  cirrcusts?: CircuitData[];
  name: string;
};

type IntegratedPrinterData = {
  categories: CategoryInfo[];
  metal_amount: number;
  max_metal: number;
  debug_status: BooleanLike;
  cloning_status: BooleanLike;
  upgrades: number;
  clone_config_status: BooleanLike;
};

// Поиск по всем схемам
const HardSearch = (categories: CategoryInfo[], search_text: string = ''): CircuitData[] | null => {
  if (!search_text || categories.length === 0) return null;
  const allCircuits = categories.flatMap(cat => cat.cirrcusts || []);
  const testSearch = createSearch<CircuitData>(search_text, cir => cir.name);
  return allCircuits.filter(testSearch);
};

// Компонент статуса принтера (металл + апгрейды)
const PrinterStatus = (props, context) => {
  const { data } = useBackend<IntegratedPrinterData>(context);
  const { metal_amount, max_metal, upgrades, debug_status, cloning_status, clone_config_status } = data;

  return (
    <Section title="Состояние принтера">
      <Stack vertical>
        <Stack.Item>
          <Stack align="center">
            <Stack.Item minWidth="70px">Металл:</Stack.Item>
            <Stack.Item grow>
              <ProgressBar
                value={metal_amount / max_metal}
                ranges={{
                  good: [0.6, Infinity],
                  average: [0.3, 0.6],
                  bad: [0, 0.3],
                }}
              >
                {metal_amount} / {max_metal}
              </ProgressBar>
            </Stack.Item>
          </Stack>
        </Stack.Item>
        <Stack.Item>
          <Stack align="center">
            <Stack.Item minWidth="70px">Улучшения:</Stack.Item>
            <Stack.Item>
              <Flex spacing={1}>
                <Flex.Item>
                  <Button
                    icon="microchip"
                    selected={!!(upgrades & Upgrades.advanced)}
                    tooltip="Продвинутые схемы"
                    tooltipPosition="top"
                    color="transparent"
                  />
                </Flex.Item>
                <Flex.Item>
                  <Button
                    icon="dna"
                    selected={!!(upgrades & Upgrades.fast_cloning)}
                    tooltip="Быстрое клонирование"
                    tooltipPosition="top"
                    color="transparent"
                  />
                </Flex.Item>
                <Flex.Item>
                  <Button
                    icon="clone"
                    selected={clone_config_status}
                    tooltip="Настройка клонов"
                    tooltipPosition="top"
                    color="transparent"
                  />
                </Flex.Item>
                {debug_status && (
                  <Flex.Item>
                    <Button icon="bug" selected tooltip="Режим отладки" color="transparent" />
                  </Flex.Item>
                )}
              </Flex>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

// Компонент сетки схем
const CircuitsGrid = (props: { circuits?: CircuitData[] }, context) => {
  const { act, data } = useBackend<IntegratedPrinterData>(context);
  const { metal_amount } = data;
  const circuits = props.circuits || [];

  if (circuits.length === 0) {
    return <NoticeBox info>Нет схем для отображения</NoticeBox>;
  }

  return (
    <Flex wrap="wrap" spacing={1}>
      {circuits.map((circuit, index) => {
        const canAfford = data.debug_status || (metal_amount >= circuit.cost) ;
        return (
          <Flex.Item key={index} basis="calc(33.33% - 8px)" grow={1}>
            <Box
              backgroundColor="rgba(0, 0, 0, 0.3)"
              p={1}
              style={{
                borderRadius: '4px',
                border: '1px solid rgba(255, 255, 255, 0.1)',
                transition: 'all 0.1s',
              }}
            >
              <Stack vertical height="100%">
                <Stack.Item>
                  <Stack align="center">
                    <Stack.Item>
                      <Button
                        icon="question-circle"
                        tooltip={circuit.desc}
                        tooltipPosition="top"
                        color="transparent"
                        style={{ padding: 0 }}
                      />
                    </Stack.Item>
                    <Stack.Item>
                      {circuit.icon ? (
                        <img
                          src={`data:image/png;base64, ${circuit.icon}`}
                          style={{ width: '32px', height: '32px'}}
                        />
                      ) : (
                        <Icon name="microchip" size={2} />
                      )}
                    </Stack.Item>
                    <Stack.Item grow>
                      <Box bold>{circuit.name}</Box>
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
                <Stack.Item>
                  <Flex justify="space-between" align="center">
                    <Flex.Item>
                      <Box fontSize="12px" color="label">
                        Цена: <b>{circuit.cost}</b> металла
                      </Box>
                    </Flex.Item>
                    <Flex.Item>
                      <Button
                        content="Печать"
                        icon="print"
                        disabled={!canAfford}
                        onClick={() => act("build", { build: circuit.path })}
                        tooltip={!canAfford ? "Недостаточно металла" : ""}
                        tooltipPosition="top"
                      />
                    </Flex.Item>
                  </Flex>
                </Stack.Item>
              </Stack>
            </Box>
          </Flex.Item>
        );
      })}
    </Flex>
  );
};

// Основной компонент просмотра компонентов
export const ComponentsViewer = (props, context) => {
  const { act, data } = useBackend<IntegratedPrinterData>(context);
  const [searchText, setSearchText] = useSharedState(context, 'searchText', "");
  const [tabID, setTabID] = useSharedState(context, 'tabIndex', 0);

  // Определяем, какие схемы показывать
  const searchResults = HardSearch(data.categories, searchText);
  let circuitsToShow: CircuitData[] = [];
  if (searchText && searchResults) {
    circuitsToShow = searchResults;
  } else if (data.categories[tabID]) {
    circuitsToShow = data.categories[tabID].cirrcusts || [];
  }

  // Сброс поиска при смене категории
  const handleCategoryChange = (index: number) => {
    setTabID(index);
    setSearchText("");
  };

  return (
    <>
      <PrinterStatus />
      <Section
        title="Компоненты"
        fill
        buttons={
          <Stack>
            <Stack.Item>
              <Input
                placeholder="Поиск по названию или описанию"
                value={searchText}
                onChange={(e, value) => setSearchText(value)}
                width="250px"
              />
            </Stack.Item>
            {searchText && (
              <Stack.Item>
                <Button icon="times" onClick={() => setSearchText("")} tooltip="Сбросить поиск" />
              </Stack.Item>
            )}
          </Stack>
        }
      >
        <Stack fill>
          <Stack.Item minWidth="150px">
            <Tabs vertical scrollable>
              {data.categories.map((catInfo, index) => (
                <Tabs.Tab
                  key={catInfo.name}
                  selected={index === tabID && !searchText}
                  onClick={() => handleCategoryChange(index)}
                >
                  <Icon name="folder" mr={1} />
                  {catInfo.name}
                </Tabs.Tab>
              ))}
            </Tabs>
          </Stack.Item>
          <Stack.Item grow>
            <Box height="100%" style={{ overflowY: 'auto', maxHeight: '450px' }}>
              {searchText && searchResults?.length === 0 && (
                <NoticeBox warning>По запросу "{searchText}" ничего не найдено</NoticeBox>
              )}
              <CircuitsGrid circuits={circuitsToShow} />
            </Box>
          </Stack.Item>
        </Stack>
      </Section>
    </>
  );
};

// Главное окно
export const CircuitPrinterUI = (props, context) => {
  const { data } = useBackend<IntegratedPrinterData>(context);
  return (
    <Window width={900} height={700}>
      <Window.Content>
        {data.debug_status && <NoticeBox info>Принтер в дебаг режиме!</NoticeBox>}
        <ComponentsViewer />
      </Window.Content>
    </Window>
  );
};
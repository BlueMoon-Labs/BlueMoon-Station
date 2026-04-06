import { BooleanLike } from 'common/react';
import { createSearch } from 'common/string';
import { Fragment } from 'inferno';

import { useBackend, useSharedState } from "../backend";
import { Box, Button, Flex, Icon, Input, NoticeBox, ProgressBar, Section, Stack, Table, Tabs } from "../components";
import { Window } from "../layouts";

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
  const { data, act } = useBackend<IntegratedPrinterData>(context);
  const [load_status, setLoadStatus] = useSharedState<BooleanLike>(context, 'loadStatus', 0);
  const { metal_amount, max_metal, upgrades, debug_status, cloning_status, clone_config_status } = data;

  return (
    <Section title="Состояние принтера">
      <Stack vertical>
        <Stack.Item>
          <Stack align="center">
            <Stack.Item minWidth="70px">Металл:</Stack.Item>
            <Stack.Item grow>
              <ProgressBar
                value={data.debug_status ? max_metal : metal_amount / max_metal}
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
            <Stack.Item minWidth="70px">Статусы:</Stack.Item>
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
                    tooltip={clone_config_status ? "Клонирование включено" : "Клонирование запрещено конфигурацией сервера"}
                    tooltipPosition="top"
                    color={clone_config_status ? "transparent" : "red"}
                  />
                </Flex.Item>
                {debug_status && (
                  <Flex.Item>
                    <Button icon="bug" selected tooltip="Этот принтер принадлежит федерации магов." color="transparent" />
                  </Flex.Item>
                )}
              </Flex>
            </Stack.Item>
                <Stack.Item right>
              <Button content={"Загрузить схему"} onClick={() => { setLoadStatus(1); act("print", { print: "load" }); }} />
                </Stack.Item>
            <Stack.Item right>
              <Button disabled={!load_status} content={"Печать устройтсва."} onClick={() => { act("print", { print: "print" }); }} />
            </Stack.Item >
                {load_status ? (
                <Stack.Item right>
                  <Button icon="times" color={"red"} tooltip="Сбрасывает загруженную схему!" onClick={() => { setLoadStatus(0); act("print", { print: "cancel" }); }} />
                </Stack.Item>
                ) : null}
          </Stack>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

// Компонент сетки схем (переписан на Table)
const CircuitsGrid = (props: { circuits?: CircuitData[] }, context) => {
  const { act, data } = useBackend<IntegratedPrinterData>(context);
  const { metal_amount } = data;
  const circuits = props.circuits || [];

  if (circuits.length === 0) {
    return <NoticeBox info>Нет схем для отображения</NoticeBox>;
  }

  // Разбиваем схемы на строки по 3 элемента
  const rows: CircuitData[][] = [];
  for (let i = 0; i < circuits.length; i += 3) {
    rows.push(circuits.slice(i, i + 3));
  }

  return (
    <Table scrollable>
        {rows.map((row, rowIndex) => (
          <Table.Row key={rowIndex}>
            {row.map((circuit, colIndex) => {
              const canAfford =
                (circuit.request_adv ? data.upgrades & Upgrades.advanced : true) &&
                (data.debug_status || metal_amount >= circuit.cost);
              let tooltip_msg = "";
              if (circuit.request_adv && !(data.upgrades & Upgrades.advanced)) {
                tooltip_msg = "Нет улучшения!";
              } else if (!(data.debug_status || metal_amount >= circuit.cost)) {
                tooltip_msg = "Недостаточно металла!";
              }

              return (
                <Table.Cell
                  key={colIndex}
                  style={{
                    width: "33.33%",
                    padding: "1px",
                    verticalAlign: "top",
                  }}
                >
                  <Box
                    backgroundColor={
                      canAfford ? "rgba(0, 0, 0, 0.3)" : "rgba(79, 74, 74, 0.5)"
                    }
                    p={1}
                    style={{
                      borderRadius: "4px",
                      border: canAfford
                        ? "1px solid rgba(255, 255, 255, 0.1)"
                        : "1px solid rgba(252, 56, 56, 0.64)",
                      transition: "all 0.1s",
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
                                style={{ width: "32px", height: "32px" }}
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
                              tooltip={tooltip_msg}
                              tooltipPosition="top"
                            />
                          </Flex.Item>
                        </Flex>
                      </Stack.Item>
                    </Stack>
                  </Box>
                </Table.Cell>
              );
            })}
            {/* Заполняем пустые ячейки в последней строке, чтобы сохранить сетку */}
            {row.length < 3 &&
              Array.from({ length: 3 - row.length }).map((_, emptyIndex) => (
                <Table.Cell
                  key={`empty-${emptyIndex}`}
                  style={{
                    width: "33.33%",
                    padding: "1px",
                    verticalAlign: "top",
                  }}
                >
                  <div style={{ visibility: "hidden" }} />
                </Table.Cell>
              ))}
          </Table.Row>
        ))}
    </Table>
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

  const handleCategoryChange = (index: number) => {
    setTabID(index);
    setSearchText("");
  };

  return (
    <>
      <PrinterStatus />

      <Flex fill grow>
        <Flex.Item minWidth="150px">
          <Section title={"Категории"}>
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
          </Section>
        </Flex.Item>

        <Flex.Item grow scrollable>
          <Section
            scrollable
            title="Компоненты"
            fill
            buttons={
              <Stack>
                <Stack.Item>
                  <Input
                    placeholder="Поиск по названию"
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
            {searchText && searchResults?.length === 0 && (
              <NoticeBox warning>По запросу {"'"}{searchText}{"'"} ничего не найдено</NoticeBox>
            )}
            <CircuitsGrid circuits={circuitsToShow} />
          </Section>
        </Flex.Item>
      </Flex>
    </>
  );
};
// Главное окно
export const CircuitPrinterUI = (props, context) => {
  const { data } = useBackend<IntegratedPrinterData>(context);
  return (
    <Window width={900} height={700} title={"Интегральный принтер"}>
      <Window.Content>
        {data.debug_status && <NoticeBox info>Принтер в дебаг режиме! Количество металла не ограничено!</NoticeBox>}
        {data.cloning_status ? <ComponentsViewer /> : <CloneNotice />}
      </Window.Content>
    </Window>
  );
};


export const CloneNotice = (props, context) => {
  const { data, act } = useBackend<IntegratedPrinterData>(context);
  return (
    <NoticeBox center warning>
        <h3>В процессе печати</h3>
        <Icon name="sync" mr={1} />
        <Button color={"red"} content={"Прервать"} tooltip={"Прерывает печать и возвращает ресурсы"} onClick={() => { act("print", { print: "cancel" }); }} />
    </NoticeBox>
  );
};

import { BooleanLike } from 'common/react';
import { createSearch } from 'common/string';

import { useBackend, useLocalState, useSharedState } from "../backend";
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
  extended_desc? : string;
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
  has_programm: BooleanLike;
  print_end_time?: number;
  print_start_time?: number;
  world_time?: number;
  // vorecrimes
  used_space? : number;
  complexity? : number;
  metal_cost? : number;
  max_complexity? : number;
  max_space? : number;
};

// Поиск по всем схемам
const HardSearch = (categories: CategoryInfo[], search_text: string = ''): CircuitData[] | null => {
  if (!search_text || categories.length === 0) return null;
  const allCircuits = categories.flatMap(cat => cat.cirrcusts || []);
  const testSearch = createSearch<CircuitData>(search_text, cir => cir.name);
  return allCircuits.filter(testSearch);
};


const CheckPrint = (data : IntegratedPrinterData) : BooleanLike => {
  if(data.metal_amount < data.metal_cost) { return false; }
  if(data.max_complexity < data.complexity) { return false; }
  if(data.max_space < data.used_space) { return false; }

  return true;
};


// Компонент статуса принтера (металл + апгрейды)
const PrinterStatus = (props, context) => {
  const { data, act } = useBackend<IntegratedPrinterData>(context);
  const { metal_amount, max_metal, upgrades, debug_status, clone_config_status } = data;

  return (
    <Section title="Состояние принтера">
      <Stack vertical>
        <Stack.Item>
          <Stack align="center">
            <Stack.Item minWidth="70px">Металл:</Stack.Item>
            <Stack.Item grow>
              <ProgressBar
                value={data.debug_status ? 1 : metal_amount / max_metal}
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
          <Stack align="center" fill>
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
                    tooltip="Быстрая печать"
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
                ) || null}
              </Flex>
            </Stack.Item>
                {(clone_config_status || debug_status) && (
                  <Stack.Item right>
                    <Button content={"Загрузить схему"} onClick={() => { act("print", { print: "load" }); }} />
                  </Stack.Item>
                ) || null}
				{((data.has_programm && clone_config_status) || (data.has_programm && debug_status)) && (
					<Stack.Item right>
						<Button disabled={!data.has_programm || (!CheckPrint(data))} content={"Печать устройства"} onClick={() => { act("print", { print: "print" }); }} />
					</Stack.Item >
            	) || null}
				{((data.has_programm && clone_config_status) || (data.has_programm && debug_status)) && (
				<Stack.Item right>
					<Button icon="times" color={"red"} tooltip="Сбрасывает загруженную схему!" onClick={() => { act("print", { print: "cancel" }); }} />
				</Stack.Item>
				) || null}
				{((data.has_programm && clone_config_status) || (data.has_programm && debug_status)) && (
				<Stack.Item ml={2}> {/* добавлен отступ слева */}
					<Flex grow>
					<Flex.Item>
						<Box fontSize="11px" color="label">
						Стоимость: <b>{data.metal_cost}</b> металла Сложность: <b>{data.complexity}</b> Количество модулей: <b>{data.used_space}</b>
						</Box>
					</Flex.Item>
					</Flex>
				</Stack.Item>
				) || null}
          </Stack>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

// Компонент сетки схем
const CircuitsGrid = (props: { circuits?: CircuitData[], big_desc? : BooleanLike, rows? : number}, context) => {
  const { act, data } = useBackend<IntegratedPrinterData>(context);
  const { metal_amount } = data;
  const circuits = props.circuits || [];

  if (circuits.length === 0) {
    return <NoticeBox info>Нет схем для отображения</NoticeBox>;
  }
  const rows_in_line = props.rows ? props.rows : 3;
  const rows: CircuitData[][] = [];
  for (let i = 0; i < circuits.length; i += rows_in_line) {
    rows.push(circuits.slice(i, i + rows_in_line));
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
                        <Stack align="flex-start"> {/* Выравнивание по верхнему краю */}
                          <Stack.Item>
                            <Button
                              icon="question-circle"
                              tooltip={props.big_desc ? circuit.extended_desc : circuit.desc}
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
                            <Stack vertical>
                              <Stack.Item>
                                <Box bold>{circuit.name}</Box>
                              </Stack.Item>
                              {props.big_desc && (
                                <Stack.Item>
                                  <Box fontSize="12px" color="label">
                                    {circuit.desc}
                                  </Box>
                                </Stack.Item>
                              )}
                            </Stack>
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
            {row.length < rows_in_line &&
              Array.from({ length: rows_in_line - row.length }).map((_, emptyIndex) => (
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

export const ComponentsViewer = (props, context) => {
  const { act, data } = useBackend<IntegratedPrinterData>(context);
  const [searchText, setSearchText] = useSharedState(context, 'searchText', "");
  const [tabID, setTabID] = useSharedState(context, 'tabIndex', 0);
  const [fullComp, setCompMode] = useLocalState<boolean>(context, "setCompMode", false);

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
                  <Button tooltip={"Переключение вида"} icon="sticky-note" selected={fullComp} onClick={() => { setCompMode(!fullComp); }} />
                </Stack.Item>
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
                ) || null}
              </Stack>
            }
          >
            {searchText && searchResults?.length === 0 && (
              <NoticeBox warning>По запросу {"'"}{searchText}{"'"} ничего не найдено</NoticeBox>
            )}
            <CircuitsGrid circuits={circuitsToShow} rows={fullComp ? 1 : 3} big_desc={fullComp} />
          </Section>
        </Flex.Item>
      </Flex>
    </>
  );
};

export const CircuitPrinterUI = (props, context) => {
  const { data } = useBackend<IntegratedPrinterData>(context);
  return (
    <Window width={900} height={700} title={"Интегральный принтер"}>
      <Window.Content>
        {data.debug_status && <NoticeBox info>Принтер в дебаг режиме! Количество металла не ограничено!</NoticeBox> || null}
        {data.cloning_status ? <CloneNotice /> : <ComponentsViewer /> }
      </Window.Content>
    </Window>
  );
};

const formatTimeLeft = (seconds: number): string => {
  if (seconds <= 0) return '0:00';
  const mins = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${mins}:${secs.toString().padStart(2, '0')}`;
};

export const CloneNotice = (props, context) => {
  const { data, act } = useBackend<IntegratedPrinterData>(context);
  const { print_end_time, print_start_time, world_time } = data;


  let progress = 0;
  let timeLeftSeconds = 0;

  if (print_end_time && print_start_time && world_time && print_end_time > print_start_time) {
    const totalDuration = print_end_time - print_start_time;
    const elapsed = world_time - print_start_time;
    progress = Math.min(1, Math.max(0, elapsed / totalDuration));

    const remainingTicks = print_end_time - world_time;
    timeLeftSeconds = Math.max(0, remainingTicks / 10);
  }

  const percent = Math.round(progress * 100);
  const timeText = timeLeftSeconds > 0
    ? `${percent}% (осталось ${formatTimeLeft(timeLeftSeconds)})`
    : `${percent}%`;

  return (
    <Box
      style={{
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        height: '30%',
        width: '100%',
      }}
    >
      <NoticeBox
        warning
        style={{
          maxWidth: '450px',
          width: '100%',
          textAlign: 'center',
          borderRadius: '12px',
          boxShadow: '0 4px 12px rgba(0,0,0,0.2)',
        }}
      >
        <Stack vertical align="center">
          <Stack.Item>
            <h3 style={{ margin: '0 0 0.5rem 0', display: 'flex', "align-items": 'center', gap: '8px' }}>
              В процессе печати
              <Icon name="sync" spin size={1.5} />
            </h3>
          </Stack.Item>

          <Stack.Item style={{ width: '100%' }}>
            <ProgressBar
              value={progress}
              ranges={{
                good: [0.7, 1],
                average: [0.4, 0.7],
                bad: [0, 0.4],
              }}
            >
              {timeText}
            </ProgressBar>
          </Stack.Item>

          <Stack.Item>
            <Button
              color="red"
              content="Прервать"
              tooltip="Прерывает печать и возвращает ресурсы"
              onClick={() => act('print', { print: 'cancel' })}
              icon="ban"
            />
          </Stack.Item>
        </Stack>
      </NoticeBox>
    </Box>
  );
};

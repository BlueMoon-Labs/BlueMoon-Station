import { plural } from 'common/ru/plural';

import { useBackend } from '../backend';
import { Box, Button, LabeledList, Section, Stack, Table, Tooltip } from '../components';
import { Window } from '../layouts';

export const ContrabandExchange = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    pad,
    sending,
    status_report,
    efficiency_multiplier,
    user_has_id,
    user_points,
    total_value,
    items_on_pad,
    blackbox_ready,
  } = data;

  const grouped = [];
  const rows_by_key = {};
  for (const item of items_on_pad || []) {
    const key = `${item.name}|${item.base_value}|${item.adjusted_value}`;
    if (rows_by_key[key]) {
      rows_by_key[key].count += 1;
    } else {
      const row = { ...item, key, count: 1 };
      rows_by_key[key] = row;
      grouped.push(row);
    }
  }

  return (
    <Window width={450} height={550} title="Терминал обмена контрабанды">
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Section title="Статус-меню">
              <LabeledList>
                <LabeledList.Item label="Статус">
                  {status_report}
                </LabeledList.Item>
                <LabeledList.Item label="Приёмник">
                  {pad ? (
                    <Box color="good">подключен</Box>
                  ) : (
                    <Box color="bad">не подключён (используйте мультитул)</Box>
                  )}
                </LabeledList.Item>
                <LabeledList.Item label="Продуктивность">
                  <Box color={efficiency_multiplier > 1 ? 'good' : 'label'}>
                    {efficiency_multiplier.toFixed(2)}x
                  </Box>
                </LabeledList.Item>
                <LabeledList.Item label="Ваша ID-карта">
                  {user_has_id ? (
                    <Box color="good">
                      обнаружена. Ваш счёт: {user_points} {plural(user_points, 'очко', 'очка', 'очков')}
                    </Box>
                  ) : (
                    <Box color="bad">ID-карты не обнаружено</Box>
                  )}
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>

          <Stack.Item grow>
            <Section fill title="Предметы на приёмнике">
              <Stack fill vertical>
                {!!blackbox_ready && (
                  <Stack.Item>
                    <Box color="good">
                      Обнаружен самописец данных! Отправка чёрного ящика завершит миссию.
                    </Box>
                  </Stack.Item>
                )}
                <Stack.Item grow basis={0}>
                  <Section fill scrollable>
                    {grouped.length > 0 ? (
                      <Table>
                        <Table.Row header>
                          <Table.Cell>Контрабанда</Table.Cell>
                          <Table.Cell collapsing textAlign="center">Количество</Table.Cell>
                          <Table.Cell collapsing textAlign="right">Цена</Table.Cell>
                          <Table.Cell collapsing textAlign="right">Суммарно</Table.Cell>
                        </Table.Row>
                        {grouped.map(item => {
                          const isMission = item.adjusted_value === 'Mission';
                          const hasAdjusted = item.adjusted_value !== undefined
                            && item.adjusted_value !== null;
                          const unit = hasAdjusted
                            ? item.adjusted_value
                            : item.base_value;
                          return (
                            <Table.Row key={item.key}>
                              <Table.Cell>{item.name}</Table.Cell>
                              <Table.Cell collapsing textAlign="center">
                                {item.count}
                              </Table.Cell>
                              <Table.Cell collapsing textAlign="right">
                                {isMission ? (
                                  <Box as="span" color="good">Предмет задания</Box>
                                ) : hasAdjusted ? (
                                  <Tooltip
                                    content={`Базовая цена: ${item.base_value}`}
                                    position="left">
                                    <Box
                                      as="span"
                                      color="blue"
                                      style={{
                                        borderBottom: '1px dotted currentColor',
                                        cursor: 'help',
                                      }}>
                                      {unit}
                                    </Box>
                                  </Tooltip>
                                ) : (
                                  <Box as="span" color="white">{unit}</Box>
                                )}
                              </Table.Cell>
                              <Table.Cell
                                collapsing
                                textAlign="right"
                                color="good">
                                {isMission ? '—' : unit * item.count}
                              </Table.Cell>
                            </Table.Row>
                          );
                        })}
                      </Table>
                    ) : (
                      <Box color="label">Приёмник не обнаружил контрабанды.</Box>
                    )}
                  </Section>
                </Stack.Item>
                {grouped.length > 0 && (
                  <Stack.Item>
                    <Box bold textAlign="right">
                      Всего:{' '}
                      <Box inline color="good">
                        {total_value} {plural(total_value, 'очко', 'очка', 'очков')}
                      </Box>
                    </Box>
                  </Stack.Item>
                )}
              </Stack>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section>
              <Button
                icon="sync"
                content="Просканировать предметы"
                disabled={!pad}
                onClick={() => act('recalc')}
              />
              <Button
                icon="paper-plane"
                content={sending ? 'Отправляется...' : 'Отправка контрабанды'}
                disabled={!pad || sending || (total_value === 0 && !blackbox_ready) || !user_has_id}
                color="good"
                onClick={() => act(sending ? 'stop' : 'send')}
              />
            </Section>
          </Stack.Item>

          {!user_has_id && (
            <Stack.Item>
              <Section title="Внимание">
                <Box color="bad">
                  Держите или носите свою ID-карту, чтобы получить очки награды!
                </Box>
              </Section>
            </Stack.Item>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};


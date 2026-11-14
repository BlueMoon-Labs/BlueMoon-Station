import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Input, LabeledList, NoticeBox, NumberInput, Section, Stack, Tabs, Tooltip } from '../components';
import { Window } from '../layouts';

type ComponentKey = 'cell' | 'scanmod' | 'capacitor';

type MaintenanceData = {
  name: string;
  card_name: string;
  card_assignment: string | null;
  maintenance_allowed: boolean;
  access_edit_allowed: boolean;
  one_access: boolean;
  maintenance_active: boolean;
  can_toggle_maintenance: boolean;
  hatch_open: boolean;
  state_name: string;
  state_hint: string;
  has_tank: boolean;
  pressure: number;
  cabin_pressure: number;
  cell: string | null;
  scanmod: string | null;
  capacitor: string | null;
  accesses: { id: number | string; name: string; required: boolean; on_card: boolean }[];
};

const components: { key: ComponentKey; name: string }[] = [
  { key: 'cell', name: 'Батарея' },
  { key: 'scanmod', name: 'Сканер' },
  { key: 'capacitor', name: 'Конденсатор' },
];

export const MechaMaintenance = () => {
  const { act, data } = useBackend<MaintenanceData>();
  const [tab, setTab] = useState('maintenance');
  const [search, setSearch] = useState('');
  const activeTab = data.access_edit_allowed ? tab : 'maintenance';
  const accesses = data.accesses
    .filter(access => access.name.toLocaleLowerCase().includes(search.toLocaleLowerCase()))
    .sort((a, b) => Number(b.required) - Number(a.required) || a.name.localeCompare(b.name));
  return (
    <Window width={520} height={500}>
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Section title={data.name}>
              <Box color="label">ID: {data.card_name}</Box>
              <Box color="label">Должность: {data.card_assignment || 'Не указана'}</Box>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Tabs>
              <Tabs.Tab
                icon="wrench"
                selected={activeTab === 'maintenance'}
                onClick={() => setTab('maintenance')}>
                Обслуживание
              </Tabs.Tab>
              <Tooltip content={data.access_edit_allowed
                ? 'Требования к доступу для управления мехом.'
                : 'Разблокируйте изменение доступа из кабины меха в панели пилота.'}>
                <Tabs.Tab
                  icon={data.access_edit_allowed ? 'id-card' : 'lock'}
                  opacity={data.access_edit_allowed ? 1 : 0.5}
                  aria-disabled={!data.access_edit_allowed}
                  selected={activeTab === 'access'}
                  onClick={() => data.access_edit_allowed && setTab('access')}>
                  Доступ
                </Tabs.Tab>
              </Tooltip>
            </Tabs>
          </Stack.Item>
          <Stack.Item grow minHeight="0px">
            {activeTab === 'maintenance' ? (
              <Section fill scrollable>
                <Section
                  title="Техобслуживание"
                  buttons={(
                    <Button
                      color={data.maintenance_active ? 'orange' : 'good'}
                      icon={data.maintenance_active ? 'lock' : 'unlock'}
                      content={data.maintenance_active ? 'Завершить' : 'Начать'}
                      disabled={!data.maintenance_allowed || !data.can_toggle_maintenance}
                      onClick={() => act('toggle_maintenance')} />
                  )}>
                  <Box bold color={data.maintenance_active ? 'average' : 'label'} mb={1}>
                    {data.state_name}
                  </Box>
                  <Box color="label">{data.state_hint}</Box>
                  {!data.maintenance_allowed && (
                    <NoticeBox mt={1}>Техобслуживание запрещено оператором.</NoticeBox>
                  )}
                </Section>
                {data.has_tank && (
                  <Section title="Воздух в кабине">
                    <LabeledList>
                      <LabeledList.Item label="Давление">
                        {data.cabin_pressure} кПа
                      </LabeledList.Item>
                      <LabeledList.Item label="Регулятор">
                        {data.maintenance_active ? (
                          <NumberInput
                            value={data.pressure}
                            unit="кПа"
                            minValue={0}
                            maxValue={Infinity}
                            step={1}
                            width="120px"
                            onChange={(_, value) => act('set_pressure', { pressure: value })} />
                        ) : (
                          <Tooltip content="Для изменения давления начните техобслуживание.">
                            <Box color="label">{data.pressure} кПа</Box>
                          </Tooltip>
                        )}
                      </LabeledList.Item>
                    </LabeledList>
                  </Section>
                )}
                <Section title="Компоненты">
                  <LabeledList>
                    {components.map(component => (
                      <LabeledList.Item key={component.key} label={component.name}>
                        <Stack align="center">
                          <Stack.Item grow minWidth="0px">
                            <Box color={data[component.key] ? undefined : 'label'}>
                              {data[component.key] || 'Отсутствует'}
                            </Box>
                          </Stack.Item>
                          <Stack.Item shrink={0}>
                            <Button
                              icon="eject"
                              content="Извлечь"
                              disabled={!data.hatch_open || !data[component.key]}
                              onClick={() => act('eject_component', { component: component.key })} />
                          </Stack.Item>
                        </Stack>
                      </LabeledList.Item>
                    ))}
                  </LabeledList>
                </Section>
              </Section>
            ) : (
              <Stack vertical fill>
                <Stack.Item shrink={0}>
                  <Section
                    title="Доступ к управлению"
                    buttons={(
                      <Button.Confirm
                        icon="lock"
                        content="Заблокировать"
                        confirmIcon="lock"
                        confirmContent="Заблокировать?"
                        tooltip="Снова разрешить изменение доступа можно из панели пилота."
                        onClick={() => act('lock_access')} />
                    )}>
                    <Button.Checkbox
                      content="Один из"
                      checked={data.one_access}
                      tooltip="Когда включено, достаточно любого отмеченного доступа. Когда выключено, нужны все отмеченные доступы."
                      onClick={() => act('toggle_one_access')} />
                    <Box color="label" mb={1}>
                      {data.one_access
                        ? 'Для управления достаточно любого отмеченного доступа.'
                        : 'Для управления нужны все отмеченные доступы.'}
                      {' '}Добавлять можно только доступы с предъявленной карты.
                    </Box>
                    <Input
                      fluid
                      value={search}
                      placeholder="Поиск доступа…"
                      onInput={(_, value) => setSearch(value)} />
                  </Section>
                </Stack.Item>
                <Stack.Item grow minHeight="0px">
                  <Section fill scrollable>
                    {accesses.map(access => (
                      <Button.Checkbox
                        key={access.id}
                        fluid
                        checked={access.required}
                        disabled={!access.required && !access.on_card}
                        content={access.name}
                        onClick={() => act('toggle_access', { access: access.id })} />
                    ))}
                    {!accesses.length && <Box color="label">Доступы не найдены.</Box>}
                  </Section>
                </Stack.Item>
              </Stack>
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

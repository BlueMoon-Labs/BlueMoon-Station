import { map } from 'common/collections';

import { useBackend, useLocalState } from '../backend';
import { Box, Button, Dropdown, Flex, LabeledList, Section, Table, Tabs } from '../components';
import { Window } from '../layouts';

export const ShuttleManipulator = (props, context) => {
  const [tab, setTab] = useLocalState(context, 'tab', 1);
  return (
    <Window
      title="Shuttle Manipulator"
      width={800}
      height={600}>
      <Window.Content overflow="auto">
        <Tabs>
          <Tabs.Tab
            selected={tab === 1}
            onClick={() => setTab(1)}>
            Status
          </Tabs.Tab>
          <Tabs.Tab
            selected={tab === 2}
            onClick={() => setTab(2)}>
            Templates
          </Tabs.Tab>
          <Tabs.Tab
            selected={tab === 3}
            onClick={() => setTab(3)}>
            Modification
          </Tabs.Tab>
          <Tabs.Tab
            selected={tab === 4}
            onClick={() => setTab(4)}>
            Гиперпространство
          </Tabs.Tab>
        </Tabs>
        {tab === 1 && (
          <ShuttleManipulatorStatus />
        )}
        {tab === 2 && (
          <ShuttleManipulatorTemplates />
        )}
        {tab === 3 && (
          <ShuttleManipulatorModification />
        )}
        {tab === 4 && (
          <ShuttleManipulatorHyperspace />
        )}
      </Window.Content>
    </Window>
  );
};

export const ShuttleManipulatorStatus = (props, context) => {
  const { act, data } = useBackend(context);
  const shuttles = data.shuttles || [];
  return (
    <Section>
      <Table>
        {shuttles.map(shuttle => (
          <Table.Row key={shuttle.shuttle_id}>
            <Table.Cell>
              <Button
                content="JMP"
                key={shuttle.shuttle_id}
                onClick={() => act('jump_to', {
                  type: 'mobile',
                  shuttle_id: shuttle.shuttle_id,
                })} />
            </Table.Cell>
            <Table.Cell>
              <Button
                content="Fly"
                key={shuttle.shuttle_id}
                disabled={!shuttle.can_fly}
                onClick={() => act('fly', {
                  shuttle_id: shuttle.shuttle_id,
                })} />
            </Table.Cell>
            <Table.Cell>
              {shuttle.name}
            </Table.Cell>
            <Table.Cell>
              {shuttle.shuttle_id}
            </Table.Cell>
            <Table.Cell>
              {shuttle.status}
            </Table.Cell>
            <Table.Cell>
              {shuttle.mode}
              {!!shuttle.timer && (
                <>
                  ({shuttle.timeleft})
                  <Button
                    content="Fast Travel"
                    key={shuttle.shuttle_id}
                    disabled={!shuttle.can_fast_travel}
                    onClick={() => act('fast_travel', {
                      shuttle_id: shuttle.shuttle_id,
                    })} />
                </>
              )}
            </Table.Cell>
            <Table.Cell>
              <Box color="label" title="Очередь и форс — вкладка «Гиперпространство»">
                {shuttle.can_queue_hyperspace_event ? 'см. вкладку' : '—'}
              </Box>
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
    </Section>
  );
};

export const ShuttleManipulatorHyperspace = (props, context) => {
  const { act, data } = useBackend(context);
  const shuttles = (data.shuttles || []).filter(
    s => s.can_queue_hyperspace_event,
  );
  return (
    <Section
      title="Ивенты гиперпространства (эвакуационный шаттл)"
      buttons={(
        <Box color="label" fontSize="0.9rem">
          Очередь срабатывает при уходе шаттла в транзит. Форс — только пока в транзите.
        </Box>
      )}>
      {!shuttles.length ? (
        <Box color="label">Нет эвакуационного шаттла в манипуляторе.</Box>
      ) : (
        shuttles.map(shuttle => {
          const opts = shuttle.hyperspace_event_options || [];
          return (
            <Section
              key={shuttle.shuttle_id}
              level={2}
              title={shuttle.name + ' (' + shuttle.shuttle_id + ')'}>
              <LabeledList>
                <LabeledList.Item label="В очереди на полёт">
                  {shuttle.queued_event_name || '—'}
                </LabeledList.Item>
                <LabeledList.Item label="Поставить в очередь">
                  <Flex align="center" wrap>
                    <Flex.Item>
                      <Dropdown
                        width="20rem"
                        noscroll
                        displayText="Выберите тип…"
                        options={opts.map(o => o.label)}
                        onSelected={label => {
                          const opt = opts.find(o => o.label === label);
                          if (opt?.path) {
                            act('queue_hyperspace_event', {
                              shuttle_id: shuttle.shuttle_id,
                              event_path: opt.path,
                            });
                          }
                        }}
                      />
                    </Flex.Item>
                    <Flex.Item ml={1}>
                      <Button
                        icon="trash"
                        color="bad"
                        content="Сбросить"
                        onClick={() => act('clear_queued_hyperspace_event', {
                          shuttle_id: shuttle.shuttle_id,
                        })} />
                    </Flex.Item>
                  </Flex>
                </LabeledList.Item>
                <LabeledList.Item
                  label="Форс сейчас"
                  color={shuttle.can_force_hyperspace_event ? 'normal' : 'label'}>
                  {shuttle.can_force_hyperspace_event ? (
                    <Dropdown
                      width="20rem"
                      noscroll
                      displayText="Ивент в текущем транзите…"
                      options={opts.map(o => o.label)}
                      onSelected={label => {
                        const opt = opts.find(o => o.label === label);
                        if (opt?.path) {
                          act('force_hyperspace_event', {
                            shuttle_id: shuttle.shuttle_id,
                            event_path: opt.path,
                          });
                        }
                      }}
                    />
                  ) : (
                    'Только вне станции, в тайле-транзите.'
                  )}
                </LabeledList.Item>
                <LabeledList.Item>
                  <Button
                    content="JMP"
                    onClick={() => act('jump_to', {
                      type: 'mobile',
                      shuttle_id: shuttle.shuttle_id,
                    })} />
                </LabeledList.Item>
              </LabeledList>
            </Section>
          );
        })
      )}
    </Section>
  );
};

export const ShuttleManipulatorTemplates = (props, context) => {
  const { act, data } = useBackend(context);
  const templateObject = data.templates || {};
  const selected = data.selected || {};
  const [
    selectedTemplateId,
    setSelectedTemplateId,
  ] = useLocalState(context, 'templateId', Object.keys(templateObject)[0]);
  const actualTemplates = templateObject[selectedTemplateId]?.templates || [];
  return (
    <Section>
      <Flex>
        <Flex.Item>
          <Tabs vertical>
            {map((template, templateId) => (
              <Tabs.Tab
                key={templateId}
                selected={selectedTemplateId === templateId}
                onClick={() => setSelectedTemplateId(templateId)}>
                {template.port_id}
              </Tabs.Tab>
            ))(templateObject)}
          </Tabs>
        </Flex.Item>
        <Flex.Item grow={1} basis={0}>
          {actualTemplates.map(actualTemplate => {
            const isSelected = (
              actualTemplate.shuttle_id === selected.shuttle_id
            );
            // Whoever made the structure being sent is an asshole
            return (
              <Section
                title={actualTemplate.name}
                level={2}
                key={actualTemplate.shuttle_id}
                buttons={(
                  <Button
                    content={isSelected ? 'Selected' : 'Select'}
                    selected={isSelected}
                    onClick={() => act('select_template', {
                      shuttle_id: actualTemplate.shuttle_id,
                    })} />
                )}>
                {(!!actualTemplate.description
                  || !!actualTemplate.admin_notes
                ) && (
                  <LabeledList>
                    {!!actualTemplate.description && (
                      <LabeledList.Item label="Description">
                        {actualTemplate.description}
                      </LabeledList.Item>
                    )}
                    {!!actualTemplate.admin_notes && (
                      <LabeledList.Item label="Admin Notes">
                        {actualTemplate.admin_notes}
                      </LabeledList.Item>
                    )}
                  </LabeledList>
                )}
              </Section>
            );
          })}
        </Flex.Item>
      </Flex>
    </Section>
  );
};

export const ShuttleManipulatorModification = (props, context) => {
  const { act, data } = useBackend(context);
  const selected = data.selected || {};
  const existingShuttle = data.existing_shuttle || {};
  return (
    <Section>
      {selected ? (
        <>
          <Section
            level={2}
            title={selected.name}>
            {(!!selected.description || !!selected.admin_notes) && (
              <LabeledList>
                {!!selected.description && (
                  <LabeledList.Item label="Description">
                    {selected.description}
                  </LabeledList.Item>
                )}
                {!!selected.admin_notes && (
                  <LabeledList.Item label="Admin Notes">
                    {selected.admin_notes}
                  </LabeledList.Item>
                )}
              </LabeledList>
            )}
          </Section>
          {existingShuttle ? (
            <Section
              level={2}
              title={'Existing Shuttle: ' + existingShuttle.name}>
              <LabeledList>
                <LabeledList.Item
                  label="Status"
                  buttons={(
                    <Button
                      content="Jump To"
                      onClick={() => act('jump_to', {
                        type: 'mobile',
                        shuttle_id: existingShuttle.shuttle_id,
                      })} />
                  )}>
                  {existingShuttle.status}
                  {!!existingShuttle.timer && (
                    <>
                      ({existingShuttle.timeleft})
                    </>
                  )}
                </LabeledList.Item>
              </LabeledList>
            </Section>
          ) : (
            <Section
              level={2}
              title="Existing Shuttle: None" />
          )}
          <Section
            level={2}
            title="Status">
            <Button
              content="Load"
              color="good"
              onClick={() => act('load', {
                shuttle_id: selected.shuttle_id,
              })} />
            <Button
              content="Preview"
              onClick={() => act('preview', {
                shuttle_id: selected.shuttle_id,
              })} />
            <Button
              content="Replace"
              color="bad"
              onClick={() => act('replace', {
                shuttle_id: selected.shuttle_id,
              })} />
          </Section>
        </>
      ) : 'No shuttle selected'}
    </Section>
  );
};

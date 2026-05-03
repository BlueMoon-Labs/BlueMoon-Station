import { Fragment } from 'inferno';

import { useBackend, useLocalState } from '../backend';
import { Box, Button, Collapsible, Flex, Input, NoticeBox, NumberInput, Section, Tabs } from '../components';
import { Window } from '../layouts';

const TABS = {
  ACTIVE: 0,
  ADD_ANTAG: 1,
  MIND: 2,
};

export const TraitorPanel = (props, context) => {
  const { act, data } = useBackend(context);
  const [currentTab, setCurrentTab] = useLocalState(context, 'tab', TABS.ACTIVE);

  const {
    mind_name, mind_key, mind_active, assigned_role,
    special_role, has_body, active_antags,
  } = data;

  return (
    <Window
      title={`${mind_name} - Traitor Panel`}
      width={700}
      height={650}
    >
      <Window.Content scrollable>
        <Section>
          <Flex align="center">
            <Flex.Item grow={1}>
              <Box bold fontSize="1.2rem">{mind_name}</Box>
              <Box color="label" mt={0.5}>
                Key: {mind_key} {mind_active
                  ? <Box inline color="green">(synced)</Box>
                  : <Box inline color="red">(not synced)</Box>}
              </Box>
              <Box color="label">
                Role: <Box inline color="white">{assigned_role}</Box>
                {!!special_role && (
                  <Box inline ml={1}>
                    Special: <Box inline color="red" bold>{special_role}</Box>
                  </Box>
                )}
              </Box>
            </Flex.Item>
            <Flex.Item>
              <StatusBadges />
            </Flex.Item>
          </Flex>
        </Section>
        <Flex mb={1}>
          <Flex.Item grow={1}>
            <Tabs>
              <Tabs.Tab
                selected={currentTab === TABS.ACTIVE}
                icon="skull-crossbones"
                onClick={() => setCurrentTab(TABS.ACTIVE)}
              >
                Active Antags ({active_antags ? active_antags.length : 0})
              </Tabs.Tab>
              <Tabs.Tab
                selected={currentTab === TABS.ADD_ANTAG}
                icon="plus-circle"
                color="green"
                onClick={() => setCurrentTab(TABS.ADD_ANTAG)}
              >
                Add Antagonist
              </Tabs.Tab>
              <Tabs.Tab
                selected={currentTab === TABS.MIND}
                icon="brain"
                onClick={() => setCurrentTab(TABS.MIND)}
              >
                Mind & Uplink
              </Tabs.Tab>
            </Tabs>
          </Flex.Item>
        </Flex>
        {currentTab === TABS.ACTIVE && <ActiveAntags />}
        {currentTab === TABS.ADD_ANTAG && <AddAntagPanel />}
        {currentTab === TABS.MIND && <MindPanel />}
      </Window.Content>
    </Window>
  );
};

const StatusBadges = (props, context) => {
  const { data } = useBackend(context);
  const { has_body, is_mindshielded, is_emagged, is_silicon } = data;

  return (
    <Flex wrap="wrap" justify="flex-end">
      {!has_body && (
        <Box px={1} py={0.5} mr={0.5} mb={0.5} backgroundColor="red" color="white" bold>
          No Body
        </Box>
      )}
      {!!is_mindshielded && (
        <Box px={1} py={0.5} mr={0.5} mb={0.5} backgroundColor="green" color="white" bold>
          Mindshielded
        </Box>
      )}
      {!!is_emagged && (
        <Box px={1} py={0.5} mr={0.5} mb={0.5} backgroundColor="red" color="white" bold>
          Emagged
        </Box>
      )}
    </Flex>
  );
};

const ActiveAntags = (props, context) => {
  const { act, data } = useBackend(context);
  const { active_antags } = data;

  if (!active_antags || active_antags.length === 0) {
    return (
      <Section>
        <NoticeBox>
          This mind has no active antagonist datums.
        </NoticeBox>
      </Section>
    );
  }

  return (
    <Section>
      {active_antags.map((antag) => (
        <Section
          key={antag.ref}
          title={(
            <Flex align="center" inline width="100%">
              <Flex.Item grow={1}>
                <Box inline bold color="red" fontSize="1.1rem">
                  {antag.name}
                </Box>
                <Box inline color="label" ml={1} fontSize="0.9rem">
                  [{antag.category}]
                </Box>
              </Flex.Item>
            </Flex>
          )}
          buttons={(
            <Fragment>
              {antag.commands && antag.commands.map((cmd) => (
                <Button
                  key={cmd}
                  icon="terminal"
                  content={cmd}
                  color="purple"
                  onClick={() => act("antag_command", { antag_ref: antag.ref, command: cmd })}
                />
              ))}
              <Button
                icon="edit"
                content="Memory"
                color="blue"
                onClick={() => act("edit_antag_memory", { antag_ref: antag.ref })}
              />
              <Button.Confirm
                icon="trash"
                content="Remove"
                color="red"
                onClick={() => act("remove_antag", { antag_ref: antag.ref })}
              />
            </Fragment>
          )}
        >
          {/* Objectives */}
          <Box mb={1}>
            <Box bold mb={0.5}>Objectives:</Box>
            {(!antag.objectives || antag.objectives.length === 0) ? (
              <Box color="label" italic>No objectives</Box>
            ) : (
              antag.objectives.map((obj, idx) => (
                <Flex key={obj.ref} align="center" mb={0.5}>
                  <Flex.Item width="2rem" textAlign="center" bold>
                    {idx + 1}.
                  </Flex.Item>
                  <Flex.Item grow={1}>
                    <Box inline>{obj.text}</Box>
                  </Flex.Item>
                  <Flex.Item shrink={0}>
                    <Button
                      icon={obj.completed ? "check-circle" : "times-circle"}
                      color={obj.completed ? "green" : "red"}
                      tooltip={obj.completed ? "Completed - Click to toggle" : "Incomplete - Click to toggle"}
                      onClick={() => act("toggle_objective", { obj_ref: obj.ref })}
                    />
                    <Button
                      icon="trash"
                      color="red"
                      tooltip="Delete objective"
                      onClick={() => act("delete_objective", { obj_ref: obj.ref })}
                    />
                  </Flex.Item>
                </Flex>
              ))
            )}
            <Flex mt={1}>
              <Button
                icon="plus"
                content="Add Objective"
                color="green"
                onClick={() => act("add_objective", { antag_ref: antag.ref })}
              />
              <Button
                icon="bullhorn"
                content="Announce"
                color="blue"
                ml={0.5}
                onClick={() => act("announce_objectives")}
              />
            </Flex>
          </Box>
          {/* Antag Memory */}
          {!!antag.antag_memory && (
            <Box mt={1}>
              <Box bold mb={0.5}>Antag Memory:</Box>
              <Box color="label" preserveWhitespace>{antag.antag_memory}</Box>
            </Box>
          )}
        </Section>
      ))}
    </Section>
  );
};

const AddAntagPanel = (props, context) => {
  const { act, data } = useBackend(context);
  const { available_categories } = data;
  const [antagSearch, setAntagSearch] = useLocalState(context, 'antagSearch', '');

  const filteredCategories = (available_categories || [])
    .map(cat => {
      const filteredAntags = cat.antags.filter(a =>
        a.name.toLowerCase().includes(antagSearch.toLowerCase()) ||
        cat.category.toLowerCase().includes(antagSearch.toLowerCase())
      );
      return { ...cat, antags: filteredAntags };
    })
    .filter(cat => cat.antags.length > 0)
    .sort((a, b) => {
      const aSingle = a.antags.length === 1;
      const bSingle = b.antags.length === 1;

      // single вверх, multi вниз
      if (aSingle && !bSingle) return -1;
      if (!aSingle && bSingle) return 1;
      return 0;
    });

  const renderAntagButton = (antag) => {
    if (antag.is_active) {
      return (
        <Button
          width="100%"
          icon="skull-crossbones"
          color="red"
          bold
          content={antag.name + " ✓"}
          tooltip="Already active"
          disabled
        />
      );
    }

    return (
      <Button
        width="100%"
        icon={antag.can_add ? "plus" : "ban"}
        color={
          antag.can_add
            ? (antag.pref_enabled ? "green" : "yellow")
            : "transparent"
        }
        content={antag.name}
        tooltip={
          !antag.can_add
            ? "Cannot be added (blacklisted or duplicate)"
            : (!antag.pref_enabled
              ? "Disabled in player preferences"
              : "Click to add")
        }
        disabled={!antag.can_add}
        onClick={() => act("add_antag", { antag_type: antag.type_path })}
      />
    );
  };

  const renderCategory = (cat) => {
    // если один элемент - сразу кнопка
    if (cat.antags.length === 1) {
      const antag = cat.antags[0];

      return (
        <Flex.Item key={antag.type_path} width="100%" mb=".25rem">
          {renderAntagButton(antag)}
        </Flex.Item>
      );
    }

    // если несколько - collapsible
    return (
      <Collapsible
        key={cat.category}
        title={`${cat.category} (${cat.antags.length})`}
        open={cat.antags.some(a => a.is_active)}
      >
        <Flex wrap="wrap" justify="space-between">
          {cat.antags.map((antag) => (
            <Flex.Item key={antag.type_path} width="49%" mb=".25rem">
              {renderAntagButton(antag)}
            </Flex.Item>
          ))}
        </Flex>
      </Collapsible>
    );
  };

  return (
    <Section>
      <Input
        value={antagSearch}
        placeholder="Search antagonists..."
        width="100%"
        mb={1}
        onInput={(e, value) => setAntagSearch(value)}
      />

      {filteredCategories.map(renderCategory)}
    </Section>
  );
};

const MindPanel = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    assigned_role, memory, has_uplink, uplink_tc,
    is_human, activity_level, activity_idle_time,
  } = data;

  return (
    <Section>
      <Section title="Role & Memory">
        <Flex mb={1} align="center">
          <Flex.Item width="120px" color="label">Assigned Role:</Flex.Item>
          <Flex.Item grow={1} bold>{assigned_role}</Flex.Item>
          <Button
            icon="edit"
            content="Change"
            onClick={() => act("edit_role")}
          />
        </Flex>
        <Box mb={1}>
          <Box color="label" mb={0.5}>Common Memory:</Box>
          <Box
            backgroundColor="rgba(0,0,0,0.3)"
            p={1}
            preserveWhitespace
            style={{ minHeight: '50px' }}
          >
            {memory || <Box color="label" italic>Empty</Box>}
          </Box>
        </Box>
        <Button
          icon="edit"
          content="Edit Memory"
          onClick={() => act("edit_memory")}
        />
      </Section>

      <Section title="Uplink">
        {has_uplink ? (
          <Flex align="center">
            <Flex.Item grow={1}>
              <Box>
                Telecrystals:
                <NumberInput
                  ml={1}
                  value={uplink_tc}
                  minValue={0}
                  maxValue={999}
                  step={1}
                  width="80px"
                  onChange={(e, value) => act("set_tc", { tc_amount: value })}
                />
              </Box>
            </Flex.Item>
            <Button.Confirm
              icon="times"
              content="Take Uplink"
              color="red"
              onClick={() => act("take_uplink")}
            />
          </Flex>
        ) : (
          <Flex align="center">
            <Flex.Item grow={1}>
              <Box color="label">No uplink found</Box>
            </Flex.Item>
            <Button
              icon="plus"
              content="Give Uplink"
              color="green"
              disabled={!is_human}
              onClick={() => act("give_uplink")}
            />
          </Flex>
        )}
      </Section>

      {(activity_level !== undefined) && (
        <Section title="Activity">
          <Box>Activity Level: <Box inline bold>{activity_level}</Box></Box>
          <Box>Idle Time: <Box inline bold>{activity_idle_time}s</Box></Box>
        </Section>
      )}

      <Section title="Quick Actions">
        <Button.Confirm
          icon="tshirt"
          content="Undress"
          color="orange"
          onClick={() => act("undress")}
        />
      </Section>
    </Section>
  );
};

import { Fragment, useState } from 'react';

import { useBackend, useLocalState } from '../backend';
import { Box, Button, Collapsible, Dropdown, Flex, Input, LabeledList, NoticeBox, NumberInput, Section, Slider, Stack, Tabs } from '../components';
import { Window } from '../layouts';

const PAGES = [
  {
    title: 'Основное',
    component: () => GeneralActions,
    color: "green",
    icon: "tools",
  },
  {
    title: 'Смайты',
    component: () => SmiteActions,
    color: "orange",
    icon: "hammer",
    canAccess: data => {
      return !!data.mob_type.includes("/mob/living");
    },
  },
  {
    title: 'Настройки моба',
    component: () => PhysicalActions,
    color: "yellow",
    icon: "bolt",
    canAccess: data => {
      return !!data.mob_type.includes("/mob/living");
    },
  },
  {
    title: 'Трансформация',
    component: () => TransformActions,
    color: "orange",
    icon: "exchange-alt",
  },
  {
    title: 'Наказания & Логи',
    component: () => PunishmentActions,
    color: "red",
    icon: "gavel",
  },
  {
    title: 'Банлисты',
    component: () => FeatureBanTabs,
    color: "red",
    icon: "gavel",
    canAccess: data => {
      return data.client_ckey;
    },
  },
  {
    title: 'Веселье',
    component: () => FunActions,
    color: "blue",
    icon: "laugh",
  },
  {
    title: 'Антаг & Прочее',
    component: () => OtherActions,
    color: "purple",
    icon: "user-secret",
  },
];

export const PlayerPanel2 = (props) => {
  const { act, data } = useBackend();
  const [pageIndex, setPageIndex] = useState(0);
  const PageComponent = PAGES[pageIndex].component();

  const { mob_name, mob_type, client_ckey, client_rank, playtimes_enabled,
    playtime, has_live_client } = data;

  return (
    <Window
      title={`Панель игрока: ${mob_name}`}
      width={700}
      height={600}
    >
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Section md={1}>
              <Flex>
                <Flex.Item width="80px" color="label" align="center">Имя:</Flex.Item>
                <Flex.Item grow={1}>
                  <Input width="100%" value={mob_name} onChange={(e, value) => act("set_name", { name: value })} />
                </Flex.Item>
                {!!client_ckey && !!client_rank && (
                  <Flex.Item>
                    <Box inline ml=".75rem" mr=".5rem" color="label">Роль:</Box>
                    <Flex.Item inline>
                      <Button
                        minWidth="11rem" textAlign="center"
                        content={client_rank}
                        onClick={() => act("edit_rank")}
                      />
                    </Flex.Item>
                  </Flex.Item>
                )}
              </Flex>
              <Flex mt={1} align="center" wrap="wrap" justify="flex-end">
                <Flex.Item width="80px" color="label">Тип моба:</Flex.Item>
                <Flex.Item grow={1} align="right">{mob_type}</Flex.Item>
                <Flex.Item align="right">
                  <Button
                    minWidth="11rem" textAlign="center"
                    ml=".5rem"
                    icon="window-restore"
                    content="Окно VV"
                    onClick={() => act("access_variables")}
                  />
                </Flex.Item>
                {!!client_ckey && (
                  <Flex.Item>
                    <Button
                      minWidth="11rem" textAlign="center"
                      ml=".5rem"
                      icon="window-restore"
                      content={playtimes_enabled ? playtime : "Время игры"}
                      disabled={!playtimes_enabled}
                      onClick={() => act("access_playtimes")}
                    />
                  </Flex.Item>
                )}
              </Flex>
              {!!client_ckey && (
                <Flex mt={1} align="center">
                  <Flex.Item width="80px" color="label">Клиент:</Flex.Item>
                  <Flex.Item grow={1}>{client_ckey}</Flex.Item>

                  <Flex.Item align="right">
                    <Button
                      minWidth="11rem" textAlign="center"
                      mx=".5rem"
                      icon="comment-dots"
                      disabled={!has_live_client}
                      onClick={() => act("private_message")}
                      content="Админ-PM"
                    />
                    <Button
                      minWidth="11rem" textAlign="center"
                      icon="phone-alt"
                      disabled={!has_live_client}
                      onClick={() => act("subtle_message")}
                      content="IC-сообщение"
                    />
                  </Flex.Item>
                </Flex>
              )}
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Stack fill>
              <Stack.Item>
                <Section fitted fill>
                  <Tabs vertical>
                    {PAGES.map((page, i) => {
                      if (page.canAccess && !page.canAccess(data)) {
                        return;
                      }

                      return (
                        <Tabs.Tab
                          key={i}
                          color={page.color}
                          selected={i === pageIndex}
                          icon={page.icon}
                          onClick={() => setPageIndex(i)}>
                          {page.title}
                        </Tabs.Tab>
                      );
                    })}
                  </Tabs>

                </Section>
              </Stack.Item>
              <Stack.Item grow>
                <Section fill scrollable>
                  <PageComponent />
                </Section>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const PhysicalActions = (props) => {
  const { act, data } = useBackend();
  const { glob_limbs, godmode, mob_type, initial_scale, active_martial_art,
    martial_arts_list, active_quirks, quirks_list, has_loadout,
    current_organs, organ_slots, current_implants, implants_list,
    mob_weight, weight_options, can_toggle_dextrous, is_dextrous } = data;
  const [mobScale, setMobScale] = useLocalState('mobScale', initial_scale);
  const limbs = Object.keys(glob_limbs);
  const limb_flags = limbs.map((_, i) => (1<<i));
  const [delimbOption, setDelimbOption] = useState(0);
  const [maSearch, setMaSearch] = useState('');
  const [quirkSearch, setQuirkSearch] = useState('');
  const [organSearch, setOrganSearch] = useState('');
  const [implantSearch, setImplantSearch] = useState('');

  const filteredArts = (martial_arts_list || []).filter(art =>
    art.name.toLowerCase().includes(maSearch.toLowerCase())
  );

  // Group quirks by type
  const positiveQuirks = (quirks_list || []).filter(q =>
    q.value_type === 'Positive'
    && q.name.toLowerCase().includes(quirkSearch.toLowerCase())
  );
  const negativeQuirks = (quirks_list || []).filter(q =>
    q.value_type === 'Negative'
    && q.name.toLowerCase().includes(quirkSearch.toLowerCase())
  );
  const neutralQuirks = (quirks_list || []).filter(q =>
    q.value_type !== 'Positive' && q.value_type !== 'Negative'
    && q.name.toLowerCase().includes(quirkSearch.toLowerCase())
  );

  // Build organ slot map for current organs
  const currentOrganMap = {};
  (current_organs || []).forEach(o => { currentOrganMap[o.slot] = o; });

  // All slot names from organ_slots
  const slotNames = organ_slots ? Object.keys(organ_slots) : [];

  // Filter organ slots by search
  const filteredSlots = slotNames.filter(slot =>
    slot.toLowerCase().includes(organSearch.toLowerCase())
    || (organ_slots[slot] || []).some(o =>
      o.name.toLowerCase().includes(organSearch.toLowerCase())
    )
  );

  return (
    <Section fill>
      <Section title="Настройки цели" buttons={
        <Button
          icon={godmode ? 'check-square-o' : 'square-o'}
          color={godmode ? 'green' : 'transparent'}
          content="God Mode"
          onClick={() => act("toggle_godmode")}
        />
      }>
        <Flex>
          <Button
            width="100%"
            icon="paw"
            content="Вид"
            tooltip="Изменить биологический вид цели"
            disabled={!mob_type.includes("/mob/living/carbon/human")}
            onClick={() => act("species")}
          />
          <Button
            width="100%"
            icon="magic"
            content="Заклинания"
            tooltip="Добавить/убрать заклинания"
            onClick={() => act("spell")}
          />
          <Button.Confirm
            width="100%"
            icon="suitcase"
            content="Лодаут"
            color="teal"
            disabled={!mob_type.includes("/mob/living/carbon/human") || !has_loadout}
            tooltip={!has_loadout ? "Отсутствует loadout data игрока" : "Применить loadout настройки игрока"}
            onClick={() => act("apply_loadout")}
          />
          <Button
            width="100%"
            icon="user-cog"
            content="Внешность"
            disabled={!mob_type.includes("/mob/living/carbon/human")}
            tooltip="Обновить name, desc и icon игрока"
            onClick={() => act("update_appearance")}
          />
        </Flex>
      </Section>

      {!!can_toggle_dextrous && (
        <Section title="Настройки Simple Mob">
          <Flex>
            <Button.Confirm
              width="100%"
              icon="hand-paper"
              content={is_dextrous ? "Забрать слоты рук" : "Дать слоты рук"}
              color={is_dextrous ? 'red' : 'green'}
              tooltip={is_dextrous
                ? "Забирает \"ловкость\" (Уронит взятые предметы)"
                : "Дать \"ловкость\" цели для возможности держать предметы"}
              onClick={() => act("toggle_dextrous")}
            />
          </Flex>
        </Section>
      )}

      <Section
        title={"Боевые искусства (" + (active_martial_art || "Отсутствуют") + ")"}
        buttons={active_martial_art ? (
          <Button
            icon="times"
            color="red"
            content="Убрать"
            onClick={() => act("remove_martial_art")}
          />
        ) : null}
      >
        <Input
          placeholder="Поиск боевых искусств..."
          width="100%"
          mb={1}
          onInput={(e, value) => setMaSearch(value)}
        />
        <Box style={{ maxHeight: '150px', overflowY: 'auto' }}>
          <Flex wrap="wrap" justify="space-between">
            {filteredArts.map((art) => (
              <Flex.Item key={art.name} width="49%" mb=".25rem">
                <Button.Checkbox
                  width="100%"
                  checked={art.name === active_martial_art}
                  content={art.name}
                  disabled={!mob_type.includes("/mob/living/carbon/human")}
                  onClick={() => {
                    if (art.name === active_martial_art) {
                      act("remove_martial_art");
                    } else {
                      act("set_martial_art", { ma_name: art.name });
                    }
                  }}
                />
              </Flex.Item>
            ))}
          </Flex>
        </Box>
      </Section>

      <Section
        title={"Квирки (Активных: " + (active_quirks ? active_quirks.length : 0) + ")"}
        buttons={(
          <Button.Confirm
            icon="trash"
            color="red"
            content="Убрать все"
            disabled={!active_quirks || !active_quirks.length}
            onClick={() => act("clear_quirks")}
          />
        )}
      >
        <Input
          placeholder="Поиск квирков..."
          width="100%"
          mb={1}
          onInput={(e, value) => setQuirkSearch(value)}
        />
        <QuirkCategory
          title="Положительные"
          color="green"
          icon="plus-circle"
          quirks={positiveQuirks}
          active_quirks={active_quirks}
          mob_type={mob_type}
          act={act}
        />
        <QuirkCategory
          title="Негативные"
          color="red"
          icon="minus-circle"
          quirks={negativeQuirks}
          active_quirks={active_quirks}
          mob_type={mob_type}
          act={act}
        />
        <QuirkCategory
          title="Нейтральные"
          color="grey"
          icon="circle"
          quirks={neutralQuirks}
          active_quirks={active_quirks}
          mob_type={mob_type}
          act={act}
        />
      </Section>

      <Section title="Конечности" buttons={(
        <Flex>
          {limbs.map((val, index) => (
            <Button.Checkbox
              key={index}
              content={val}
              height="100%"
              checked={delimbOption & limb_flags[index]}
              disabled={!mob_type.includes("/mob/living/carbon/human")}
              onClick={() => setDelimbOption(
                (delimbOption & limb_flags[index])
                  ? delimbOption & ~limb_flags[index]
                  : delimbOption|limb_flags[index]
              )}
            />
          ))}
        </Flex>
      )}>
        <Flex>
          <Button.Confirm
            width="100%"
            icon="unlink"
            content="Delimb"
            tooltip="Оторвать ВЫБРАННЫЕ конечности цели"
            color="red"
            disabled={!mob_type.includes("/mob/living/carbon/human")}
            onClick={() => act("limb", {
              limbs: limb_flags.map((val, index) =>
                !!(delimbOption & val) && glob_limbs[limbs[index]]
              ),
              delimb_mode: true,
            })}
          />
          <Button.Confirm
            width="100%"
            height="100%"
            icon="link"
            content="Relimb"
            tooltip="Восстановить ВЫБРАННЫЕ конечности цели"
            color="green"
            disabled={!mob_type.includes("/mob/living/carbon/human")}
            onClick={() => act("limb", {
              limbs: limb_flags.map((val, index) =>
                !!(delimbOption & val) && glob_limbs[limbs[index]]
              ),
            })}
          />
        </Flex>
      </Section>

      <Section title={"Органы (Установлено: " + (current_organs ? current_organs.length : 0) + ")"}>
        <Collapsible title="Слоты органов" color="green">
          <Input
            placeholder="Поиск слотов органов..."
            width="100%"
            mb={1}
            onInput={(e, value) => setOrganSearch(value)}
          />
          <Box style={{ maxHeight: '300px', overflowY: 'auto' }}>
            {filteredSlots.map((slot) => {
              const cur = currentOrganMap[slot];
              const available = organ_slots[slot] || [];
              return (
                <OrganSlotRow
                  key={slot}
                  slot={slot}
                  current={cur}
                  available={available}
                  mob_type={mob_type}
                  act={act}
                />
              );
            })}
          </Box>
        </Collapsible>
      </Section>

      <ImplantSection
        current_implants={current_implants}
        implants_list={implants_list}
        implantSearch={implantSearch}
        setImplantSearch={setImplantSearch}
        mob_type={mob_type}
        act={act}
      />

      <Section title="Размеры (Scale)" buttons={
        <Button
          icon="sync"
          content="Сбросить"
          tooltip="Задать размеры цели по сохранённому игроком body size"
          onClick={() => {
            setMobScale(initial_scale);
            act("scale", { new_scale: initial_scale });
          }}
        />
      }>
        <Flex
          mt={1}
        >
          <Slider
            minValue={.25}
            maxValue={8}
            value={mobScale}
            stepPixelSize={12}
            step={.25}
            onChange={(e, value) => {
              setMobScale(value); // Update slider value
              act("scale", { new_scale: value }); // Update mob's value
            }}
            unit="x"
          />
        </Flex>
      </Section>
      <Section title="Вес">
        <Flex wrap="wrap" justify="space-between">
          {(weight_options || []).map((opt) => (
            <Flex.Item key={opt.value} width="49%" mb=".25rem">
              <Button
                width="100%"
                selected={mob_weight === opt.value}
                content={opt.name}
                onClick={() => act("set_weight", { weight: opt.value })}
              />
            </Flex.Item>
          ))}
        </Flex>
      </Section>
      <Section title="Коммуникация">
        <Flex mt={1}>
          <Flex.Item width="100px" color="label">Force Say:</Flex.Item>
          <Flex.Item grow={1}>
            <Input
              width="100%"
              onEnter={(e, value) => act("force_say", { to_say: value })}
            />
          </Flex.Item>
        </Flex>
        <Flex mt={2}>
          <Flex.Item width="100px" color="label">Force Emote:</Flex.Item>
          <Flex.Item grow={1}>
            <Input
              width="100%"
              onEnter={(e, value) => act("force_emote", { to_emote: value })}
            />
          </Flex.Item>
        </Flex>
      </Section>
    </Section>
  );
};

const QuirkCategory = (props) => {
  const { title, color, icon, quirks, active_quirks, mob_type, act } = props;
  if (!quirks || quirks.length === 0) {
    return null;
  }
  const activeCount = quirks.filter(q =>
    active_quirks && active_quirks.includes(q.name)
  ).length;
  return (
    <Collapsible
      title={title + " (" + activeCount + "/" + quirks.length + ")"}
      color={color}
    >
      <Flex wrap="wrap" justify="space-between">
        {quirks.map((quirk) => (
          <Flex.Item key={quirk.name} width="49%" mb=".25rem">
            <Button.Checkbox
              width="100%"
              checked={active_quirks && active_quirks.includes(quirk.name)}
              content={quirk.name}
              tooltip={quirk.desc}
              color={active_quirks?.includes(quirk.name) ? color : null}
              disabled={!mob_type.includes("/mob/living/carbon/human")}
              onClick={() => act("toggle_quirk_direct", { quirk_name: quirk.name })}
            />
          </Flex.Item>
        ))}
      </Flex>
    </Collapsible>
  );
};

const OrganSlotRow = (props) => {
  const { slot, current, available, mob_type, act } = props;
  const [expanded, setExpanded] = useState(false);
  const [organFilter, setOrganFilter] = useState('');

  const filtered = available.filter(o =>
    o.name.toLowerCase().includes(organFilter.toLowerCase())
  );

  return (
    <Box
      mb={0.5}
      style={{
        border: '1px solid rgba(255,255,255,0.1)',
        borderRadius: '3px',
        padding: '4px 6px',
        background: current
          ? 'rgba(80,200,120,0.08)'
          : 'rgba(255,255,255,0.02)',
      }}
    >
      <Flex align="center">
        <Flex.Item shrink={0} width="20px">
          <Button
            icon={expanded ? "chevron-down" : "chevron-right"}
            color="transparent"
            compact
            onClick={() => setExpanded(!expanded)}
          />
        </Flex.Item>
        <Flex.Item width="130px">
          <Box bold color="label">{slot}</Box>
        </Flex.Item>
        <Flex.Item grow={1}>
          {current ? (
            <Box inline color="green" bold>
              {current.name}
            </Box>
          ) : (
            <Box inline color="grey" italic>
              — Empty —
            </Box>
          )}
        </Flex.Item>
        <Flex.Item shrink={0}>
          {current && (
            <Button
              icon="trash"
              color="red"
              tooltip={"Убрать " + current.name}
              disabled={!mob_type.includes("/mob/living/carbon")}
              onClick={() => act("remove_organ", { organ_slot: slot })}
            />
          )}
        </Flex.Item>
      </Flex>
      {expanded && (
        <Box ml={2} mt={0.5} mb={0.5}>
          <Input
            placeholder={"Search " + slot + "..."}
            width="100%"
            mb={0.5}
            onInput={(e, value) => setOrganFilter(value)}
          />
          <Box style={{ maxHeight: '150px', overflowY: 'auto' }}>
            <Flex wrap="wrap" justify="space-between">
              {filtered.map((organ) => (
                <Flex.Item key={organ.path} width="49%" mb=".25rem">
                  <Button
                    width="100%"
                    icon={current && current.type_path === organ.path ? "check" : "plus"}
                    color={current && current.type_path === organ.path ? "green" : null}
                    content={organ.name}
                    disabled={!mob_type.includes("/mob/living/carbon")}
                    onClick={() => act("set_organ", { organ_path: organ.path })}
                  />
                </Flex.Item>
              ))}
            </Flex>
          </Box>
        </Box>
      )}
    </Box>
  );
};

const ImplantSection = (props) => {
  const { current_implants, implants_list, implantSearch, setImplantSearch,
    mob_type, act } = props;
  const [showAdd, setShowAdd] = useState(false);

  const filteredImplants = (implants_list || []).filter(imp =>
    imp.name.toLowerCase().includes(implantSearch.toLowerCase())
  );

  return (
    <Section
      title={"Импланты (Установлено: " + (current_implants ? current_implants.length : 0) + ")"}
      buttons={
        <Button
          icon={showAdd ? "minus" : "plus"}
          color={showAdd ? "red" : "green"}
          content={showAdd ? "Спрятать список" : "Добавить имплант"}
          onClick={() => setShowAdd(!showAdd)}
        />
      }
    >
      {current_implants && current_implants.length > 0 ? (
        <Box mb={showAdd ? 1 : 0}>
          {current_implants.map((imp) => (
            <Box
              key={imp.ref}
              mb={0.5}
              style={{
                border: '1px solid rgba(255,255,255,0.1)',
                borderRadius: '3px',
                padding: '4px 6px',
                background: 'rgba(80,200,120,0.08)',
              }}
            >
              <Flex align="center">
                <Flex.Item grow={1}>
                  <Box inline color="green" bold>
                    {imp.name}
                  </Box>
                </Flex.Item>
                <Flex.Item shrink={0}>
                  <Button
                    icon="trash"
                    color="red"
                    tooltip={"Убрать " + imp.name}
                    onClick={() => act("remove_implant", { implant_ref: imp.ref })}
                  />
                </Flex.Item>
              </Flex>
            </Box>
          ))}
        </Box>
      ) : (
        <Box color="grey" italic mb={showAdd ? 1 : 0}>
          Нет установленных имплантов.
        </Box>
      )}
      {showAdd && (
        <Box>
          <Input
            placeholder="Поиск имплантов..."
            width="100%"
            mb={1}
            onInput={(e, value) => setImplantSearch(value)}
          />
          <Box style={{ maxHeight: '200px', overflowY: 'auto' }}>
            <Flex wrap="wrap" justify="space-between">
              {filteredImplants.map((imp) => (
                <Flex.Item key={imp.name} width="49%" mb=".25rem">
                  <Button
                    width="100%"
                    icon="syringe"
                    content={imp.name}
                    disabled={!mob_type.includes("/mob/living")}
                    onClick={() => act("set_implant", { implant_name: imp.name })}
                  />
                </Flex.Item>
              ))}
            </Flex>
          </Box>
        </Box>
      )}
    </Section>
  );
};


const FeatureBanTabs = (props) => {
  const { data } = useBackend();
  const [jobbanTab, setJobbanTab] = useLocalState('jobbanTab', 0);
  const { roles } = data;
  return (
    <Stack fill>
      <Stack.Item>
        <Section fill minWidth="8rem">
          <Tabs vertical>
            {roles.map((role_category, i) => { return (
              <Tabs.Tab
                key={role_category.category_name}
                color={role_category.category_color}
                py=".5rem"
                selected={jobbanTab === i}
                onClick={() => setJobbanTab(i)}>
                {role_category.category_name}
              </Tabs.Tab>
            ); })}
          </Tabs>
        </Section>
      </Stack.Item>
      <Stack.Divider />
      <Stack.Item grow>
          <Section fill>
            <FeatureBans />
          </Section>
      </Stack.Item>
    </Stack>
  );
};

const FeatureBans = (props) => {
  const { act, data } = useBackend();
  const [jobbanTab] = useLocalState('jobbanTab', 0);
  const { roles, antag_ban_reason } = data;
  return (
    <Section fill>
      <Section
        title={roles[jobbanTab].category_name}
        buttons={(
          <>
            <Button
              content="Снять все баны"
              color="good"
              icon="lock-open"
              minWidth="8rem"
              textAlign="center"
              onClick={() => act("job_ban", {
                selected_role: roles[jobbanTab].category_name,
                is_category: true,
              })} />
            <Button
              content="Выдать все баны"
              tooltip="Пробанить позиции в открытой категории"
              color="bad"
              icon="lock"
              minWidth="8rem"
              textAlign="center"
              onClick={() => act("job_ban", {
                selected_role: roles[jobbanTab].category_name,
                is_category: true,
                want_to_ban: true,
              })} />
          </>
        )}
      >
        <Flex wrap="wrap" justify="space-between">
          {roles[jobbanTab].category_name === "Antagonists" && (
            <NoticeBox
              width="100%"
              danger={antag_ban_reason ? true : false}
            >
              <Flex justify="space-between" align="center">
                <Flex.Item width="100%">
                  This player is {antag_ban_reason ? "" : "not"} antagonist banned
                </Flex.Item>
                <Flex.Item>
                  <Button
                    align="right"
                    ml=".5rem"
                    px="2rem"
                    py=".5rem"
                    color={antag_ban_reason ? "orange" : ""}
                    tooltip={antag_ban_reason ? "Reason: " + antag_ban_reason : ""}
                    content={antag_ban_reason ? "Unban" : "Ban"}
                    onClick={() => act("job_ban", {
                      selected_role: "Syndicate",
                      want_to_ban: (antag_ban_reason ? false : true),
                    })}
                  />
                </Flex.Item>
              </Flex>
            </NoticeBox>
          )}

          {roles[jobbanTab].category_roles.map((role) => { return (
            <Flex.Item
              key={0}
              width="49%"
            >

              <Button
                width="100%"
                py=".5rem"
                mb=".5rem"
                icon={role.ban_reason ? "lock" : "lock-open"}
                color={role.ban_reason ? "bad" : "transparent"}
                tooltip={role.ban_reason ? "Reason: " + role.ban_reason : ""}
                content={role.name}
                onClick={() => act("job_ban", {
                  selected_role: role.name,
                  want_to_ban: (role.ban_reason ? false : true),
                })} />
            </Flex.Item>
          ); })}

        </Flex>
      </Section>
    </Section>
  );
};

const GeneralActions = (props) => {
  const { act, data } = useBackend();
  const { client_ckey, client_hearted, mob_type, admin_mob_type } = data;
  return (
    <Section>
      <Section title="Повреждения">
        <Flex>
          <Button
            width="100%"
            icon="heart"
            color="green"
            content="Восстановить"
            tooltip="Полностью восстановить здоровье и увечья цели проком Rejuvenate"
            disabled={!mob_type.includes("/mob/living")}
            onClick={() => act("heal")}
          />
          <Button
            width="100%"
            height="100%"
            icon="band-aid"
            color="teal"
            content="Исцелить"
            tooltip="Вылечить все типы урона цели на 20 единиц"
            disabled={!mob_type.includes("/mob/living")}
            onClick={() => act("light_heal")}
          />
        </Flex>
      </Section>

      <Section title="Перемещение">
        <Flex>
          <Button.Confirm
            width="100%"
            icon="reply"
            content="На себя"
            tooltip="Переместить цель на себя"
            onClick={() => act("bring")}
          />
          <Button
            width="100%"
            content="Кружить над целью"
            tooltip="Телепортироваться к цели как призрак"
            onClick={() => act("orbit")}
          />
          <Button.Confirm
            width="100%"
            height="100%"
            icon="share"
            content="К цели"
            tooltip="Телепортироваться к цели физически"
            onClick={() => act("jump_to")}
          />
        </Flex>
      </Section>

      <Section title="Прочее">
        <Flex>
          <Button
            width="100%"
            content="Выбрать снаряжение"
            tooltip="Выбрать снаряжение в специальном меню"
            icon="user-tie"
            disabled={!mob_type.includes("/mob/living/carbon/human")}
            onClick={() => act("select_equipment")}
          />
          <Button.Confirm
            content="Снять все предметы"
            tooltip="Снять с цели все слоты инвентаря"
            icon="trash-alt"
            width="100%"
            height="100%"
            disabled={!mob_type.includes("/mob/living/carbon/human")}
            onClick={() => act("strip")}
          />
        </Flex>
        <Flex mt={1}>
          <Button
            width="100%"
            icon="heart"
            color={client_hearted ? 'pink' : 'default'}
            content={client_hearted ? 'Сердечко активно' : 'Выдать сердечко'}
            disabled={!client_ckey}
            tooltip={client_hearted
              ? 'У цели уже есть активное OOC-сердечко'
              : 'Выдать OOC-сердечко на 24 часа'}
            onClick={() => act('commend')}
          />
        </Flex>
      </Section>
      <Section title="Контроль над целью">
        <Flex>
          <Button.Confirm
            width="100%"
            icon="ghost"
            content="Извлечь из тела"
            tooltip="Вытащить игрока из тела цели и сделать призраком"
            confirmColor="bad"
            disabled={!client_ckey || !mob_type.includes("/mob/living")}
            onClick={() => act("ghost")}
          />
          <Button.Confirm
            width="100%"
            content="Взять контроль"
            tooltip="Взять контроль над телом цели"
            confirmColor="bad"
            disabled={mob_type.includes("/mob/dead/observer") || !admin_mob_type.includes("/mob/dead/observer")}
            onClick={() => act("take_control")}
          />
          <Button.Confirm
            width="100%"
            height="100%" // weird ass bug here, so height set to 100%
            icon="ghost"
            content="Предложить контроль"
            tooltip="Предложить игрокам-призракам контроль над телом цели"
            disabled={!mob_type.includes("/mob/living")}
            onClick={() => act("offer_control")}
          />
        </Flex>
        <Flex>
          <Button.Confirm
            content="Отправить в криосон"
            tooltip="Убрать цель из раунда через криосон"
            icon="snowflake"
            width="100%"
            color="orange"
            disabled={!mob_type.includes("/mob/living/carbon/human")}
            onClick={() => act("cryo")}
          />
          <Button.Confirm
            width="100%"
            height="100%"
            content="Отправить в лобби"
            color="orange"
            icon="undo"
            disabled={!mob_type.includes("/mob/dead/observer")}
            tooltip={mob_type !== "/mob/dead/observer" ? "Можно использовать только на призраках" : ""}
            onClick={() => act("lobby")}
          />
        </Flex>
      </Section>
    </Section>
  );
};

const PunishmentActions = (props) => {
  const { act, data } = useBackend();
  const { client_ckey, mob_type, is_frozen, is_slept, glob_mute_bits,
    client_muted, data_related_cid, data_related_ip, data_cid, data_byond_version,
    data_player_join_date, data_account_join_date, active_role_ban_count,
    current_time, has_live_client } = data;
  return (
    <Section>
      <Flex>
        <Button
          width="50%"
          py=".5rem"
          icon="clipboard-list"
          color="orange"
          content="Заметки"
          tooltip="Открыть заметки игрока"
          textAlign="center"
          disabled={!client_ckey}
          onClick={() => act("notes")}
        />
        <Button
          width="50%"
          height="100%"
          py=".5rem"
          icon="clipboard-list"
          color="orange"
          content="Логи"
          tooltip="Открыть логи раунда игрока"
          textAlign="center"
          onClick={() => act("logs")}
        />
      </Flex>
      <Section title="Сдерживание">
        <Flex>
          <Button
            width="100%"
            content="Заморозить"
            tooltip="Заморозить цель в пространстве"
            color={is_frozen ? "orange" : ""}
            icon={is_frozen ? 'check-square-o' : 'square-o'}
            disabled={!mob_type.includes("/mob/living")}
            onClick={() => act("freeze")}
          />
          <Button
            width="100%"
            content="Усыпить"
            tooltip="Ввести цель в вечный сон"
            color={is_slept ? "orange" : ""}
            icon={is_slept ? 'check-square-o' : 'square-o'}
            disabled={!mob_type.includes("/mob/living")}
            onClick={() => act("sleep")}
          />
          <Button.Confirm
            width="100%"
            height="100%"
            content="Admin Prison"
            tooltip="Отправить цель в камеру под Thunderdome"
            icon="share"
            color="bad"
            disabled={!mob_type.includes("/mob/living")}
            onClick={() => act("prison")}
          />
        </Flex>
      </Section>

      <Section title="Блокировки">
        <Flex>
          <Button.Confirm
            width="100%"
            icon="ban"
            color="red"
            content="Кикнуть"
            tooltip="Кикнуть игрока с сервера"
            disabled={!has_live_client}
            onClick={() => act("kick")}
          />
          <Button
            width="100%"
            icon="gavel"
            color="red"
            content="Забанить"
            tooltip="Выдать серверный бан игроку"
            disabled={!client_ckey}
            onClick={() => act("ban")}
          />
          <Button
            width="100%"
            height="100%"
            icon="gavel"
            color="red"
            content="Стики-бан"
            tooltip="Выдать бан по CID/железу (HWID)"
            disabled={!client_ckey}
            onClick={() => act("sticky_ban")}
          />
        </Flex>
      </Section>

      <Section title="Мут-панель" buttons={
        <>
          <Button
            icon="lock-open"
            color="green"
            content="Снять все муты"
            tooltip=""
            disabled={!has_live_client || !client_ckey}
            onClick={() => act("unmute_all")}
          />
          <Button
            icon="lock"
            color="red"
            content="Выдать все муты"
            disabled={!has_live_client || !client_ckey}
            onClick={() => act("mute_all")}
          />
        </>
      }>
        <Flex>
          {glob_mute_bits.map((bit, i) => {
            const isMuted = (client_muted && (client_muted & bit.bitflag));
            return (
              <Button
                key={i}
                width="100%"
                height="100%"
                icon={isMuted ? 'check-square-o' : 'square-o'}
                color={isMuted? "bad" : ""}
                content={bit.name}
                disabled={!has_live_client || !client_ckey}
                onClick={() => act("mute", { "mute_flag": !isMuted? client_muted | bit.bitflag : client_muted & ~bit.bitflag })}
              />
            );
          }) }
        </Flex>
      </Section>
      <Section title="Подробности"
        buttons={(
          <Flex>
            <Flex.Item align="center" mr=".5rem" color="label">
              Причастные аккаунты, по:
            </Flex.Item>
            <Button
              minWidth="5rem"
              color="orange"
              content="CID"
              textAlign="center"
              mr=".5rem"
              disabled={!data_related_cid}
              onClick={() => act("related_accounts", { related_thing: "CID" })}
            />
            <Button
              minWidth="5rem"
              height="100%"
              color="orange"
              textAlign="center"
              content="IP"
              disabled={!data_related_ip}
              onClick={() => act("related_accounts", { related_thing: "IP" })}
            />
          </Flex>
        )}>
        <Collapsible
          width="100%"
          color="orange"
          content="Детали"
          disabled={!client_ckey}
        >
          <LabeledList >
            <LabeledList.Item label="Текущее время" color="label">{current_time}</LabeledList.Item>
            <LabeledList.Item label="Аккаунт создан">{data_account_join_date}</LabeledList.Item>
            <LabeledList.Item label="Впервые зашёл">{data_player_join_date}</LabeledList.Item>
            <LabeledList.Item label="Версия Byond">{data_byond_version}</LabeledList.Item>
            <LabeledList.Item label="CID">{data_cid || "N/A"}</LabeledList.Item>
            <LabeledList.Item label="Активных банов">{active_role_ban_count}</LabeledList.Item>
          </LabeledList>
        </Collapsible>
      </Section>
    </Section>
  );
};

const TransformActions = (props) => {
  const { act, data } = useBackend();
  const { transformables, mob_type } = data;
  return (
    <Section>

      <Button
        width="100%"
        content="Найти и превратить по mob type"
        py=".5rem"
        textAlign="center"
        onClick={() => act("transform", { newType: "/mob/living" })}
      />

      {transformables.map((transformables_category) => { return (
        <Section
          title={transformables_category.name}
          key={0}>
          <Flex wrap="wrap" justify="space-between">
            {transformables_category.types.map((transformables_type) => {
              return (
                <Flex.Item key={0} width="calc(33.3% - .125rem)" mb=".25rem">
                  <Button.Confirm
                    width="100%"
                    height="100%"
                    color={transformables_category.color}
                    content={transformables_type.name}
                    disabled={mob_type === transformables_type.key}
                    onClick={() => act("transform", { newType: transformables_type.key, newTypeName: transformables_type.name })}
                  />
                </Flex.Item>
              ); })}
          </Flex>
        </Section>
      ); })}
    </Section>
  );
};

const FunActions = (props) => {
  const { act } = useBackend();

  const colours = {
    'White': '#a4bad6',
    'Dark': '#42474D',
    'Red': '#c51e1e',
    'Red Bright': '#FF0000',
    'Velvet': '#660015',
    'Green': '#059223',
    'Blue': '#6685f5',
    'Purple': '#800080',
    'Purple Dark': '#5000A0',
    'Narsie': '#973e3b',
    'Ratvar': '#BE8700',
  };

  const [lockExplode, setLockExplode] = useState(true);
  const [empMode, setEmpMode] = useState(false);
  const [extinguishMode, setExtinguishMode] = useState(false);
  const [expPower, setExpPower] = useState(8);
  const [narrateSize, setNarrateSize] = useLocalState("narrateSize", 1);
  const [narrateMessage, setNarrateMessage] = useLocalState("narrateMessage", "");
  const [narrateColour, setNarrateColour] = useLocalState("narrateColour", Object.keys(colours)[0]);
  const [narrateFont, setNarrateFont] = useLocalState("narrateFont", "Verdana");
  const [narrateBold, setNarrateBold] = useLocalState("narrateBold", false);
  const [narrateItalic, setNarrateItalic] = useLocalState("narrateItalic", false);
  const [narrateGlobal, setNarrateGlobal] = useLocalState("narrateGlobal", false);
  const [narrateRange, setNarrateRange] = useLocalState("narrateRange", 7);



  const narrateStyles = {
    'color': colours[narrateColour],
    fontSize: narrateSize + 'rem',
    fontWeight: (narrateBold ? 'bold' : ''),
    fontFamily: narrateFont,
    fontStyle: (narrateItalic ? 'italic' : ''),
  };

  return (
    <Section fill>
      <NoticeBox info textAlign="center">
        Действие этих эффектов центрировано от ВАШЕЙ локации
      </NoticeBox>

      <Section title="Сгенерировать взрыв" buttons={(
        <>
          <Button.Checkbox
            checked={extinguishMode}
            color="transparent"
            content="Огнетушение"
            onClick={() => setExtinguishMode(!extinguishMode)}
          />
          <Button.Checkbox
            checked={empMode}
            color="transparent"
            content="EMP-режим"
            onClick={() => setEmpMode(!empMode)}
          />
          <Button
            icon={lockExplode? "lock" : "lock-open"}
            content={lockExplode? "Locked" : "Unlocked"}
            onClick={() => setLockExplode(!lockExplode)}
            color={lockExplode? "green" : "bad"}
          />
        </>
      )}>
        <Flex
          align="right"
          grow={1}
          mt={1}
        >
          <Flex.Item>
            <Button
              width="100%"
              height="100%"
              color="red"
              disabled={lockExplode}
              onClick={() => act("explode", { power: expPower, emp_mode: empMode, extinguish_mode: extinguishMode })}
            >
              <Box height="100%" pt={2} pb={2} textAlign="center">Взорвать</Box>
            </Button>
          </Flex.Item>
          <Flex.Item
            ml={1}
            grow={1}
          >
            <Slider
              unit="м. радиуса"
              value={expPower}
              stepPixelSize={15}
              onDrag={(e, value) => setExpPower(value)}
              ranges={{
                green: [0, 8],
                orange: [8, 15],
                red: [15, 30],
              }}
              minValue={1}
              maxValue={30}
              height="100%"
            />
          </Flex.Item>
        </Flex>
      </Section>
      <Section title="Создать лог повествования (Narrate)"
        buttons={
          <Button
            content="Global Narrate"
            value={narrateGlobal}
            icon={narrateGlobal? 'check-square-o' : 'square-o'}
            color={narrateGlobal? 'red' : 'transparent'}
            onClick={() => setNarrateGlobal(!narrateGlobal)}
          />
        }>
        <Flex width="100%">
          <Flex width="100%" wrap>
            <Flex.Item width="52%">
              <LabeledList>
                <LabeledList.Item label="Цвет">
                  <Dropdown
                    width="calc(100% - 1rem)"
                    displayText={narrateColour}
                    options={Object.keys(colours)}
                    onSelected={(value) => setNarrateColour(value)}
                  />
                </LabeledList.Item>
                <LabeledList.Item label="Шрифт">
                  <Dropdown
                    width="calc(100% - 1rem)"
                    displayText={narrateFont}
                    options={["Verdana", "Consolas", "Trebuchet MS", "Comic Sans MS", "Times New Roman"]}
                    onSelected={(value) => setNarrateFont(value)} />
                </LabeledList.Item>
              </LabeledList>
            </Flex.Item>
            <Flex.Item width="20%">
              <LabeledList>
                <LabeledList.Item label="Жирность">
                  <Button.Checkbox
                    checked={narrateBold}
                    height="100%"
                    color="transparent"
                    onClick={() => setNarrateBold(!narrateBold)}
                  />
                </LabeledList.Item>
                <LabeledList.Item label="Курсив">
                  <Button.Checkbox
                    checked={narrateItalic}
                    height="100%"
                    color="transparent"
                    onClick={() => setNarrateItalic(!narrateItalic)}
                  />
                </LabeledList.Item>
              </LabeledList>
            </Flex.Item>
            <Flex.Item width="28%">
              <LabeledList>
                <LabeledList.Item label="Размер">
                  <NumberInput
                    width="100%"
                    value={narrateSize}
                    minValue={1}
                    maxValue={6}
                    unit="rem"
                    align="center"
                    stepPixelSize="25"
                    onDrag={(e, value) => setNarrateSize(value)} />
                </LabeledList.Item>
                {!narrateGlobal && (
                  <LabeledList.Item label="Дальность">
                    <NumberInput
                      width="100%"
                      value={narrateRange}
                      minValue={1}
                      maxValue={14}
                      unit="м."
                      align="center"
                      stepPixelSize="25"
                      onDrag={(e, value) => setNarrateRange(value)} />
                  </LabeledList.Item>
                )}
              </LabeledList>
            </Flex.Item>
          </Flex>
        </Flex>

        <Flex mt="1rem">
          <Flex.Item width="100%" mr="1rem">
            <Input
              width="100%"
              my=".5rem"
              onInput={(e, value) => setNarrateMessage(value)}
            />
          </Flex.Item>

          <Button
            content="Вещать"
            color="green"
            p=".5rem"
            textAlign="center"
            disabled={!narrateMessage}
            onClick={(e) => act("narrate", { message: narrateMessage, classes: narrateStyles, range: narrateRange, mode_global: narrateGlobal })}
          />
        </Flex>

        <Box
          style={narrateStyles}
          mt="1rem"
          pl=".5rem"
          width="37rem"
          maxWidth="37rem"
        >{narrateMessage}
        </Box>
      </Section>
    </Section>
  );
};

const SmiteActions = (props) => {
  const { act, data } = useBackend();
  const { smites_list } = data;
  const [smiteSearch, setSmiteSearch] = useState('');

  const filteredSmites = (smites_list || []).filter(name =>
    name.toLowerCase().includes(smiteSearch.toLowerCase())
  );

  return (
    <Section title="Смайты (Наказания)" fill>
      <Input
        placeholder="Сломать колени..."
        width="100%"
        mb={1}
        onInput={(e, value) => setSmiteSearch(value)}
      />
      <Flex wrap="wrap" justify="space-between">
        {filteredSmites.map((name) => (
          <Flex.Item key={name} width="49%" mb=".25rem">
            <Button
              width="100%"
              icon="bolt"
              color="orange"
              content={name}
              onClick={() => act("smite_direct", { smite_name: name })}
            />
          </Flex.Item>
        ))}
      </Flex>
    </Section>
  );
};

const OtherActions = (props) => {
  const { act, data } = useBackend();
  const { mob_type, client_ckey } = data;

  return (
    <Section fill>
      <Section title="Антагонизм">
        <Button
          width="100%"
          content="Панель антагониста (TP)"
          icon="user-secret"
          color="purple"
          p=".5rem"
          mb=".5rem"
          textAlign="center"
          disabled={!client_ckey}
          onClick={(e) => act("traitor_panel")}
        />
        <Button
          width="100%"
          content="Цели / Амбиции"
          icon="bullseye"
          p=".5rem"
          textAlign="center"
          disabled={!client_ckey}
          onClick={(e) => act("ambitions")}
        />
      </Section>
      <Section title="Прочее">
        <Button
          width="100%"
          content="Языки"
          icon="language"
          p=".5rem"
          mb=".5rem"
          textAlign="center"
          disabled={!mob_type.includes("/mob/living")}
          onClick={(e) => act("languages")}
        />
        <Flex>
          <Button
            width="100%"
            minHeight="2.5rem"
            content="Дать права ментора"
            icon="graduation-cap"
            color="green"
            p=".5rem"
            textAlign="center"
            disabled={!client_ckey}
            onClick={(e) => act('makementor')}
          />
          <Button
            width="100%"
            minHeight="2.5rem"
            content="Убрать права ментора"
            icon="user-minus"
            color="red"
            p=".5rem"
            textAlign="center"
            disabled={!client_ckey}
            onClick={(e) => act('removementor')}
          />
        </Flex>
      </Section>
    </Section>
  );
};

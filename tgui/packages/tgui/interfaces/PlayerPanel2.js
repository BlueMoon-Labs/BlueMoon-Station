import { Fragment } from "inferno";

import { useBackend, useLocalState } from '../backend';
import { Box, Button, Collapsible, Dropdown, Flex, Input, LabeledList, NoticeBox, NumberInput, Section, Slider, Tabs } from '../components';
import { Window } from '../layouts';

const PAGES = [
  {
    title: 'General',
    component: () => GeneralActions,
    color: "green",
    icon: "tools",
  },
  {
    title: 'Smites',
    component: () => SmiteActions,
    color: "orange",
    icon: "hammer",
    canAccess: data => {
      return !!data.mob_type.includes("/mob/living");
    },
  },
  {
    title: 'Mob',
    component: () => PhysicalActions,
    color: "yellow",
    icon: "bolt",
    canAccess: data => {
      return !!data.mob_type.includes("/mob/living");
    },
  },
  {
    title: 'Transform',
    component: () => TransformActions,
    color: "orange",
    icon: "exchange-alt",
  },
  {
    title: 'Punish',
    component: () => PunishmentActions,
    color: "red",
    icon: "gavel",
  },
  {
    title: 'Feature Bans',
    component: () => FeatureBanTabs,
    color: "red",
    icon: "gavel",
    canAccess: data => {
      return data.client_ckey;
    },
  },
  {
    title: 'Fun',
    component: () => FunActions,
    color: "blue",
    icon: "laugh",
  },
  {
    title: 'Antag & Other',
    component: () => OtherActions,
    color: "purple",
    icon: "user-secret",
  },
];

export const PlayerPanel2 = (props, context) => {
  const { act, data } = useBackend(context);
  const [pageIndex, setPageIndex] = useLocalState(context, 'pageIndex', 0);
  const PageComponent = PAGES[pageIndex].component();

  const { mob_name, mob_type, client_ckey, client_rank, playtimes_enabled,
    playtime, has_live_client } = data;

  return (
    <Window
      title={`${mob_name} Player Panel`}
      width={700}
      height={600}
    >
      <Window.Content scrollable>
        <Section md={1}>
          <Flex>
            <Flex.Item width="80px" color="label" align="center">Name:</Flex.Item>
            <Flex.Item grow={1}>
              <Input width="100%" value={mob_name} onChange={(e, value) => act("set_name", { name: value })} />
            </Flex.Item>
            {!!client_ckey && !!client_rank && (
              <Flex.Item>
                <Box inline ml=".75rem" mr=".5rem" color="label">Rank:</Box>
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
            <Flex.Item width="80px" color="label">Mob Type:</Flex.Item>
            <Flex.Item grow={1} align="right">{mob_type}</Flex.Item>
            <Flex.Item align="right">
              <Button
                minWidth="11rem" textAlign="center"
                ml=".5rem"
                icon="window-restore"
                content="Access Variables"
                onClick={() => act("access_variables")}
              />
            </Flex.Item>
            {!!client_ckey && (
              <Flex.Item>
                <Button
                  minWidth="11rem" textAlign="center"
                  ml=".5rem"
                  icon="window-restore"
                  content={playtimes_enabled ? playtime : "Playtimes"}
                  disabled={!playtimes_enabled}
                  onClick={() => act("access_playtimes")}
                />
              </Flex.Item>
            )}
          </Flex>
          {!!client_ckey && (
            <Flex mt={1} align="center">
              <Flex.Item width="80px" color="label">Client:</Flex.Item>
              <Flex.Item grow={1}>{client_ckey}</Flex.Item>

              <Flex.Item align="right">
                <Button
                  minWidth="11rem" textAlign="center"
                  mx=".5rem"
                  icon="comment-dots"
                  disabled={!has_live_client}
                  onClick={() => act("private_message")}
                  content="Private Message"
                />
                <Button
                  minWidth="11rem" textAlign="center"
                  icon="phone-alt"
                  disabled={!has_live_client}
                  onClick={() => act("subtle_message")}
                  content="Subtle Message"
                />
              </Flex.Item>
            </Flex>
          )}
        </Section>
        <Flex grow>
          <Flex.Item>
            <Section fitted>
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
          </Flex.Item>
          <Flex.Item grow>
            <PageComponent />
          </Flex.Item>
        </Flex>
      </Window.Content>
    </Window>
  );
};

const PhysicalActions = (props, context) => {
  const { act, data } = useBackend(context);
  const { glob_limbs, godmode, mob_type, initial_scale, active_martial_art,
    martial_arts_list, active_quirks, quirks_list, has_loadout,
    current_organs, organ_slots, current_implants, implants_list,
    mob_weight, weight_options } = data;
  const [mobScale, setMobScale] = useLocalState(context, 'mobScale', initial_scale);
  const limbs = Object.keys(glob_limbs);
  const limb_flags = limbs.map((_, i) => (1<<i));
  const [delimbOption, setDelimbOption] = useLocalState(context, "delimb_flags", 0);
  const [maSearch, setMaSearch] = useLocalState(context, 'maSearch', '');
  const [quirkSearch, setQuirkSearch] = useLocalState(context, 'quirkSearch', '');
  const [organSearch, setOrganSearch] = useLocalState(context, 'organSearch', '');
  const [implantSearch, setImplantSearch] = useLocalState(context, 'implantSearch', '');

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
      <Section title="Quick Actions" buttons={
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
            content="Species"
            disabled={!mob_type.includes("/mob/living/carbon/human")}
            onClick={() => act("species")}
          />
          <Button
            width="100%"
            icon="magic"
            content="Spells"
            onClick={() => act("spell")}
          />
          <Button.Confirm
            width="100%"
            icon="suitcase"
            content="Loadout"
            color="teal"
            disabled={!mob_type.includes("/mob/living/carbon/human") || !has_loadout}
            tooltip={!has_loadout ? "Player has no loadout data" : "Apply player's loadout"}
            onClick={() => act("apply_loadout")}
          />
        </Flex>
      </Section>

      <Section
        title={"Martial Art (" + (active_martial_art || "None") + ")"}
        buttons={active_martial_art ? (
          <Button
            icon="times"
            color="red"
            content="Remove"
            onClick={() => act("remove_martial_art")}
          />
        ) : null}
      >
        <Input
          placeholder="Search martial arts..."
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
        title={"Quirks (" + (active_quirks ? active_quirks.length : 0) + " active)"}
        buttons={(
          <Button.Confirm
            icon="trash"
            color="red"
            content="Clear All"
            disabled={!active_quirks || !active_quirks.length}
            onClick={() => act("clear_quirks")}
          />
        )}
      >
        <Input
          placeholder="Search quirks..."
          width="100%"
          mb={1}
          onInput={(e, value) => setQuirkSearch(value)}
        />
        <QuirkCategory
          title="Positive"
          color="green"
          icon="plus-circle"
          quirks={positiveQuirks}
          active_quirks={active_quirks}
          mob_type={mob_type}
          act={act}
        />
        <QuirkCategory
          title="Negative"
          color="red"
          icon="minus-circle"
          quirks={negativeQuirks}
          active_quirks={active_quirks}
          mob_type={mob_type}
          act={act}
        />
        <QuirkCategory
          title="Neutral"
          color="grey"
          icon="circle"
          quirks={neutralQuirks}
          active_quirks={active_quirks}
          mob_type={mob_type}
          act={act}
        />
      </Section>

      <Section title="Limbs" buttons={(
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

      <Section title={"Organs (" + (current_organs ? current_organs.length : 0) + " installed)"}>
        <Collapsible title="Organ Slots" color="green">
          <Input
            placeholder="Search organ slots..."
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

      <Section title="Scale" buttons={
        <Button
          icon="sync"
          content="Reset"
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
      <Section title="Weight">
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
      <Section title="Speak">
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
              color={color}
              disabled={!mob_type.includes("/mob/living/carbon/human")}
              onClick={() => act("toggle_quirk_direct", { quirk_name: quirk.name })}
            />
          </Flex.Item>
        ))}
      </Flex>
    </Collapsible>
  );
};

const OrganSlotRow = (props, context) => {
  const { slot, current, available, mob_type, act } = props;
  const [expanded, setExpanded] = useLocalState(context, 'organ_' + slot, false);
  const [organFilter, setOrganFilter] = useLocalState(context, 'organ_filter_' + slot, '');

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
              tooltip={"Remove " + current.name}
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

const ImplantSection = (props, context) => {
  const { current_implants, implants_list, implantSearch, setImplantSearch,
    mob_type, act } = props;
  const [showAdd, setShowAdd] = useLocalState(context, 'implant_showAdd', false);

  const filteredImplants = (implants_list || []).filter(imp =>
    imp.name.toLowerCase().includes(implantSearch.toLowerCase())
  );

  return (
    <Section
      title={"Implants (" + (current_implants ? current_implants.length : 0) + " installed)"}
      buttons={
        <Button
          icon={showAdd ? "minus" : "plus"}
          color={showAdd ? "red" : "green"}
          content={showAdd ? "Hide List" : "Add Implant"}
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
                    tooltip={"Remove " + imp.name}
                    onClick={() => act("remove_implant", { implant_ref: imp.ref })}
                  />
                </Flex.Item>
              </Flex>
            </Box>
          ))}
        </Box>
      ) : (
        <Box color="grey" italic mb={showAdd ? 1 : 0}>
          No implants installed.
        </Box>
      )}
      {showAdd && (
        <Box>
          <Input
            placeholder="Search implants..."
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


const FeatureBanTabs = (props, context) => {
  const { data } = useBackend(context);
  const [jobbanTab, setJobbanTab] = useLocalState(context, 'jobbanTab', 0);
  const { roles } = data;
  return (
    <Flex>
      <Flex.Item>
        <Section fitted>
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
      </Flex.Item>

      <Flex.Item grow>
        <FeatureBans />
      </Flex.Item>
    </Flex>
  );
};

const FeatureBans = (props, context) => {
  const { act, data } = useBackend(context);
  const [jobbanTab] = useLocalState(context, 'jobbanTab', 0);
  const { roles, antag_ban_reason } = data;
  return (
    <Section fill>
      <Section
        title={roles[jobbanTab].category_name}
        buttons={(
          <Fragment>
            <Button
              content="Unban All"
              color="good"
              icon="lock-open"
              minWidth="8rem"
              textAlign="center"
              onClick={() => act("job_ban", {
                selected_role: roles[jobbanTab].category_name,
                is_category: true,
              })} />
            <Button
              content="Ban All"
              color="bad"
              icon="lock"
              minWidth="8rem"
              textAlign="center"
              onClick={() => act("job_ban", {
                selected_role: roles[jobbanTab].category_name,
                is_category: true,
                want_to_ban: true,
              })} />
          </Fragment>
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

const GeneralActions = (props, context) => {
  const { act, data } = useBackend(context);
  const { client_ckey, mob_type, admin_mob_type } = data;
  return (
    <Section>
      <Section title="Damage">
        <Flex>
          <Button
            width="100%"
            icon="heart"
            color="green"
            content="Rejuvenate"
            disabled={!mob_type.includes("/mob/living")}
            onClick={() => act("heal")}
          />
          <Button
            width="100%"
            height="100%"
            icon="band-aid"
            color="teal"
            content="Light Heal"
            disabled={!mob_type.includes("/mob/living")}
            onClick={() => act("light_heal")}
          />
        </Flex>
      </Section>

      <Section title="Teleportation">
        <Flex>
          <Button.Confirm
            width="100%"
            icon="reply"
            content="Bring"
            onClick={() => act("bring")}
          />
          <Button
            width="100%"
            content="Orbit"
            onClick={() => act("orbit")}
          />
          <Button.Confirm
            width="100%"
            height="100%"
            icon="share"
            content="Jump To"
            onClick={() => act("jump_to")}
          />
        </Flex>
      </Section>

      <Section title="Miscellaneous">
        <Flex>
          <Button
            width="100%"
            content="Select Equipment"
            icon="user-tie"
            disabled={!mob_type.includes("/mob/living/carbon/human")}
            onClick={() => act("select_equipment")}
          />
          <Button.Confirm
            content="Drop All Items"
            icon="trash-alt"
            width="100%"
            height="100%"
            disabled={!mob_type.includes("/mob/living/carbon/human")}
            onClick={() => act("strip")}
          />
        </Flex>
        <Flex>
          <Button.Confirm
            content="Send To Cryo"
            icon="snowflake"
            width="100%"
            color="orange"
            disabled={!mob_type.includes("/mob/living/carbon/human")}
            onClick={() => act("cryo")}
          />
          <Button.Confirm
            width="100%"
            height="100%"
            content="Send To Lobby"
            color="orange"
            icon="undo"
            disabled={!mob_type.includes("/mob/dead/observer")}
            tooltip={mob_type !== "/mob/dead/observer" ? "Can only be used on ghosts" : ""}
            onClick={() => act("lobby")}
          />
        </Flex>
      </Section>
      <Section title="Control">
        <Flex>
          <Button.Confirm
            width="100%"
            icon="ghost"
            content="Eject Ghost"
            confirmColor="bad"
            disabled={!client_ckey || !mob_type.includes("/mob/living")}
            onClick={() => act("ghost")}
          />
          <Button.Confirm
            width="100%"
            content="Take Control"
            confirmColor="bad"
            disabled={mob_type.includes("/mob/dead/observer") || !admin_mob_type.includes("/mob/dead/observer")}
            onClick={() => act("take_control")}
          />
          <Button.Confirm
            width="100%"
            height="100%" // weird ass bug here, so height set to 100%
            icon="ghost"
            content="Offer Control"
            tooltip="Offers control to ghosts"
            disabled={!mob_type.includes("/mob/living")}
            onClick={() => act("offer_control")}
          />
        </Flex>
      </Section>
    </Section>
  );
};

const PunishmentActions = (props, context) => {
  const { act, data } = useBackend(context);
  const { client_ckey, mob_type, is_frozen, is_slept, glob_mute_bits,
    client_muted, data_related_cid, data_related_ip, data_byond_version,
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
          content="Notes"
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
          content="Logs"
          textAlign="center"
          onClick={() => act("logs")}
        />
      </Flex>
      <Section title="Contain">
        <Flex>
          <Button
            width="100%"
            content="Freeze"
            color={is_frozen ? "orange" : ""}
            icon={is_frozen ? 'check-square-o' : 'square-o'}
            disabled={!mob_type.includes("/mob/living")}
            onClick={() => act("freeze")}
          />
          <Button
            width="100%"
            content="Sleep"
            color={is_slept ? "orange" : ""}
            icon={is_slept ? 'check-square-o' : 'square-o'}
            disabled={!mob_type.includes("/mob/living")}
            onClick={() => act("sleep")}
          />
          <Button.Confirm
            width="100%"
            height="100%"
            content="Admin Prison"
            icon="share"
            color="bad"
            disabled={!mob_type.includes("/mob/living")}
            onClick={() => act("prison")}
          />
        </Flex>
      </Section>

      <Section title="Banishment">
        <Flex>
          <Button.Confirm
            width="100%"
            icon="ban"
            color="red"
            content="Kick"
            disabled={!has_live_client}
            onClick={() => act("kick")}
          />
          <Button
            width="100%"
            icon="gavel"
            color="red"
            content="Ban"
            disabled={!client_ckey}
            onClick={() => act("ban")}
          />
          <Button
            width="100%"
            height="100%"
            icon="gavel"
            color="red"
            content="Sticky Ban"
            disabled={!client_ckey}
            onClick={() => act("sticky_ban")}
          />
        </Flex>
      </Section>

      <Section title="Mute" buttons={
        <Fragment>
          <Button
            icon="lock-open"
            color="green"
            content="Unmute All"
            disabled={!has_live_client || !client_ckey}
            onClick={() => act("unmute_all")}
          />
          <Button
            icon="lock"
            color="red"
            content="Mute All"
            disabled={!has_live_client || !client_ckey}
            onClick={() => act("mute_all")}
          />
        </Fragment>
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
      <Section title="Investigate"
        buttons={(
          <Flex>
            <Flex.Item align="center" mr=".5rem" color="label">
              Related accounts by:
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
          content="Details"
          disabled={!client_ckey}
        >
          <LabeledList >
            <LabeledList.Item label="NOW" color="label">{current_time}</LabeledList.Item>
            <LabeledList.Item label="Account made">{data_account_join_date}</LabeledList.Item>
            <LabeledList.Item label="First joined server">{data_player_join_date}</LabeledList.Item>
            <LabeledList.Item label="Byond version">{data_byond_version}</LabeledList.Item>
            <LabeledList.Item label="Active bans">{active_role_ban_count}</LabeledList.Item>
          </LabeledList>
        </Collapsible>
      </Section>
    </Section>
  );
};

const TransformActions = (props, context) => {
  const { act, data } = useBackend(context);
  const { transformables, mob_type } = data;
  return (
    <Section>

      <Button
        width="100%"
        content="Custom"
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

const FunActions = (props, context) => {
  const { act } = useBackend(context);

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

  const [lockExplode, setLockExplode] = useLocalState(context, "explode_lock_toggle", true);
  const [empMode, setEmpMode] = useLocalState(context, "empMode", false);
  const [extinguishMode, setExtinguishMode] = useLocalState(context, "extinguishMode", false);
  const [expPower, setExpPower] = useLocalState(context, "exp_power", 8);
  const [narrateSize, setNarrateSize] = useLocalState(context, "narrateSize", 1);
  const [narrateMessage, setNarrateMessage] = useLocalState(context, "narrateMessage", "");
  const [narrateColour, setNarrateColour] = useLocalState(context, "narrateColour", Object.keys(colours)[0]);
  const [narrateFont, setNarrateFont] = useLocalState(context, "narrateFont", "Verdana");
  const [narrateBold, setNarrateBold] = useLocalState(context, "narrateBold", false);
  const [narrateItalic, setNarrateItalic] = useLocalState(context, "narrateItalic", false);
  const [narrateGlobal, setNarrateGlobal] = useLocalState(context, "narrateGlobal", false);
  const [narrateRange, setNarrateRange] = useLocalState(context, "narrateRange", 7);



  const narrateStyles = {
    'color': colours[narrateColour],
    'font-size': narrateSize + 'rem',
    'font-weight': (narrateBold ? 'bold' : ''),
    'font-family': narrateFont,
    'font-style': (narrateItalic ? 'italic' : ''),
  };

  return (
    <Section fill>
      <NoticeBox info textAlign="center">
        These features are centred on YOUR viewport
      </NoticeBox>

      <Section title="Explosion" buttons={(
        <Fragment>
          <Button.Checkbox
            checked={extinguishMode}
            color="transparent"
            content="Extinguish Mode"
            onClick={() => setExtinguishMode(!extinguishMode)}
          />
          <Button.Checkbox
            checked={empMode}
            color="transparent"
            content="EMP Mode"
            onClick={() => setEmpMode(!empMode)}
          />
          <Button
            icon={lockExplode? "lock" : "lock-open"}
            content={lockExplode? "Locked" : "Unlocked"}
            onClick={() => setLockExplode(!lockExplode)}
            color={lockExplode? "green" : "bad"}
          />
        </Fragment>
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
              <Box height="100%" pt={2} pb={2} textAlign="center">Detonate</Box>
            </Button>
          </Flex.Item>
          <Flex.Item
            ml={1}
            grow={1}
          >
            <Slider
              unit="Range"
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
      <Section title="Narrate"
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
                <LabeledList.Item label="Colour">
                  <Dropdown
                    width="calc(100% - 1rem)"
                    displayText={narrateColour}
                    options={Object.keys(colours)}
                    onSelected={(value) => setNarrateColour(value)}
                  />
                </LabeledList.Item>
                <LabeledList.Item label="Font">
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
                <LabeledList.Item label="Bold">
                  <Button.Checkbox
                    checked={narrateBold}
                    height="100%"
                    color="transparent"
                    onClick={() => setNarrateBold(!narrateBold)}
                  />
                </LabeledList.Item>
                <LabeledList.Item label="Italic">
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
                <LabeledList.Item label="Size">
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
                  <LabeledList.Item label="Range">
                    <NumberInput
                      width="100%"
                      value={narrateRange}
                      minValue={1}
                      maxValue={14}
                      unit="Tiles"
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
            content="Broadcast"
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

const SmiteActions = (props, context) => {
  const { act, data } = useBackend(context);
  const { smites_list } = data;
  const [smiteSearch, setSmiteSearch] = useLocalState(context, 'smiteSearch', '');

  const filteredSmites = (smites_list || []).filter(name =>
    name.toLowerCase().includes(smiteSearch.toLowerCase())
  );

  return (
    <Section title="Smites" fill>
      <Input
        placeholder="Search smites..."
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

const OtherActions = (props, context) => {
  const { act, data } = useBackend(context);
  const { mob_type, client_ckey } = data;

  return (
    <Section fill>
      <Section title="Antagonist">
        <Button
          width="100%"
          content="Traitor Panel"
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
          content="Objectives / Ambitions"
          icon="bullseye"
          p=".5rem"
          textAlign="center"
          disabled={!client_ckey}
          onClick={(e) => act("ambitions")}
        />
      </Section>
      <Section title="Miscellaneous">
        <Button
          width="100%"
          content="Languages"
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
            content="Make Mentor"
            icon="graduation-cap"
            color="green"
            p=".5rem"
            textAlign="center"
            disabled={!client_ckey}
            onClick={(e) => act('makementor')}
          />
          <Button
            width="100%"
            content="Remove Mentor"
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

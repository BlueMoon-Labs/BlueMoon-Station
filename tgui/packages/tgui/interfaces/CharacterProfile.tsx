import { Section, Flex, Collapsible, Box, Tooltip, LabeledList, ByondUi, Button } from "../components";
import { Window } from "../layouts";
import { useBackend, useLocalState } from "../backend";

const getTagColor = (erptag) => {
  switch (erptag) {
    case "Yes":
      return "green";
    case "Allowed": // BLUEMOON - mechanical_erp_verbs_examine
      return "green"; // BLUEMOON - mechanical_erp_verbs_examine
    case "Text Only": // BLUEMOON - mechanical_erp_verbs_examine
      return "blue"; // BLUEMOON - mechanical_erp_verbs_examine
    case "Ask":
      return "blue";
    case "No":
      return "red";
  }
};

// I am aware that the following context with
// all these vars is messy, but this isn't particularly
// 'hot' code given it's static data.

interface CharacterProfileContext {
  directory_visible: boolean;
  is_unknown: boolean;
  headshot_links?: (string | null)[];
  headshot_naked_links?: (string | null)[]; // BLUEMOON ADD
  character_ref: any,
  flavortext: string;
  flavortext_naked: string;
  silicon_flavor_text: string;
  erp_verbs: string; // BLUEMOON - mechanical_erp_verbs_examine
  oocnotes: string;
  species_name: string;
  custom_species_lore: string;
  security_records?: string;
  medical_records?: string;
  vore_tag: string;
  erp_tag: string;
  mob_tag: string;
  hornyantags_tag: string;
  nc_tag: string;
  unholy_tag: string;
  extreme_tag: string;
  very_extreme_tag: string;
}

export const CharacterProfile = (props, context) => {
  const { data } = useBackend<CharacterProfileContext>(context);

  const tags = [
    { name: "ERP Verbs", title: "ЕРП механики", value: data.erp_verbs },  // BLUEMOON - mechanical_erp_verbs_examine
    { name: "ERP", title: "Эротический отыгрыш", value: data.erp_tag },
    { name: "Non-Con", title: "Изнасилование", value: data.nc_tag },
    { name: "Vore", title: "Поедание/Проглатывание", value: data.vore_tag },
    { name: "Mob-Sex", title: "Совокупление с Мобами", value: data.mob_tag },
    { name: "Horny Antags", title: "Жертва хорни антагов", value: data.hornyantags_tag },
    { name: "Unholy", title: "Грязный секс", value: data.unholy_tag },
    { name: "Extreme", title: "Жестокий секс", value: data.extreme_tag },
    { name: "Extreme Harm", title: "Очень жестокий секс", value: data.very_extreme_tag },
  ];

  return (
    <Window resizable width={950} height={740}>
      <Window.Content scrollable>
        <Flex>
          <Flex.Item>
            <CharacterProfileImageElement />
            <CharacterModelImageElement />
          </Flex.Item>
          <Flex.Item pl="10px" grow>
            <Collapsible title="Описание Персонажа" open>
              <Section style={{ "white-space": "pre-line" }}>
                {data.flavortext || "———"}
              </Section>
            </Collapsible>

            {data.flavortext_naked ? (
               <Collapsible title="Описание Голого Тела Персонажа" open>
                <Section style={{ "white-space": "pre-line" }}>
                  {data.flavortext_naked || "———"}
                </Section>
              </Collapsible>
            ) : (<Box />)}

            {data.security_records ? (
              <Collapsible title="База Данных Службы Безопасности" open>
                <Section style={{ "white-space": "pre-line" }}>
                  {data.security_records || "———"}
                </Section>
              </Collapsible>
            ) : (<Box />)}

            {data.medical_records ? (
              <Collapsible title="База Данных Медицинского Отдела" open>
                <Section style={{ "white-space": "pre-line" }}>
                  {data.medical_records || "———"}
                </Section>
              </Collapsible>
            ) : (<Box />)}

            <Collapsible title={`Раса - ${data.species_name}`} open>
              <Section style={{ "white-space": "pre-line" }}>
                {data.custom_species_lore || "———"}
              </Section>
            </Collapsible>
            <Collapsible title="Внеигровые заметки" open>
              <Section style={{ "white-space": "pre-line" }}>
                {data.oocnotes || "———"}
              </Section>
            </Collapsible>
            <Section title="Предпочтения персонажа" width="100%">
              <LabeledList>
                {tags.map(tag => (
                  <LabeledList.Item
                    key={tag.name}
                    color={getTagColor(tag.value)}
                    label={tag.title}>
                    <Tooltip content={tag.name}>{tag.value}</Tooltip>
                  </LabeledList.Item>
                ))}
              </LabeledList>
            </Section>
          </Flex.Item>
        </Flex>
      </Window.Content>
    </Window>
  );
};

const CharacterProfileImageElement = (props, context) => {
  const { data } = useBackend<CharacterProfileContext>(context);

  const headshot_links =
    [
      ...(data.headshot_links || []),
      ...(data.headshot_naked_links || [])
    ].filter(link => link?.length) || [];

  const [
    selectedHeadshot,
    selectHeadshot
  ] = useLocalState(context, 'selectedHeadshot', 0);

  const prevHeadshot = () => selectHeadshot(
    (selectedHeadshot + headshot_links.length - 1) % headshot_links.length
  );
  const nextHeadshot = () => selectHeadshot(
    (selectedHeadshot + 1) % headshot_links.length
  );

  if (headshot_links.length) return (
    <Section title="Арт персонажа" pb="12" textAlign="center">
      <Box mb={1}>
        <img src={headshot_links[selectedHeadshot]} height="256px" width="256px" />
      </Box>
      {headshot_links.length > 1 ? (
        <Box>
          <Button onClick={prevHeadshot} icon="arrow-left" />
          <span style={{margin: "0 8px"}}><b>{selectedHeadshot + 1} / {headshot_links.length}</b></span>
          <Button onClick={nextHeadshot} icon="arrow-right" />
        </Box>
      ) : (<Box />)}
    </Section>
  );
  return (<Box />);
};

const CharacterModelImageElement = (props, context) => {
  const { act, data } = useBackend<CharacterProfileContext>(context);

    const { config } = useBackend(context);
  if(config.status < 2)
    return
  return (
    <Section title="Модель персонажа" pb="12" textAlign="center">
      <Box mb={1}>
        <ByondUi
          height="256px" width="256px"
          params={{ id: data.character_ref, type: 'map' }}
        />
      </Box>
      <Box>
        <Button onClick={() => act("char_left")} icon="undo" />
        <Button onClick={() => act("change_background")}>Сменить фон</Button>
        <Button onClick={() => act("char_right")} icon="redo" />
        <Button onClick={() => act("character_directory")}>
          Библиотека Персонажей
        </Button>
      </Box>
    </Section>
  );
};

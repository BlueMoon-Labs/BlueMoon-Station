// BLUEMOON ADDED
import { useBackend } from "../backend";
import { Collapsible, Flex, LabeledList, Section, Tooltip } from "../components";
import { Window } from "../layouts";

const getTagColor = (erptag) => {
  switch (erptag) {
    case "Yes":
      return "green";
    case "Ask":
      return "blue";
    case "No":
      return "red";
  }
};

// Ненавижу, блин, боргов
// Когда-нибудь это можно будет переделать в что-то крутое

interface CyborgProfileContext {

  silicon_flavor_text: string;
  oocnotes: string;
  tempflavor: string;
  vore_tag: string;
  erp_tag: string;
  mob_tag: string;
  nc_tag: string;
  unholy_tag: string;
  extreme_tag: string;
  very_extreme_tag: string;
}

export const CyborgProfile = (props, context) => {
  const { act, data } = useBackend<CyborgProfileContext>(context);

  const tags = [
    { name: "ERP", title: "Эротический отыгрыш", value: data.erp_tag },
    { name: "Non-Con", title: "Изнасилование", value: data.nc_tag },
    { name: "Vore", title: "Поедание/Проглатывание", value: data.vore_tag },
    { name: "Mob-Sex", title: "Совокупление с Мобами", value: data.mob_tag },
    { name: "Unholy", title: "Грязный секс", value: data.unholy_tag },
    { name: "Extreme", title: "Жестокий секс", value: data.extreme_tag },
    { name: "Extreme Harm", title: "Очень жестокий секс", value: data.very_extreme_tag },
  ];

  return (
    <Window resizable width={600} height={600}>
      <Window.Content scrollable>
        <Flex>
          <Flex.Item pl="10px" grow>
            <Collapsible title="Описание Юнита" open>
              <Section style={{ "white-space": "pre-line" }}>
                {data.silicon_flavor_text || "———"}
              </Section>
            </Collapsible>
            <Collapsible title="Внеигровые заметки" open>
              <Section style={{ "white-space": "pre-line" }}>
                {data.oocnotes || "Отсутствуют"}
              </Section>
            </Collapsible>
              <Section title="Преференсы киборга" width="100%">
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

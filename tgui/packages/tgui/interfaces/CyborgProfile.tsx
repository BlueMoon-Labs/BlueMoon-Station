// BLUEMOON ADDED
import { useState } from "react";

import { useBackend } from "../backend";
import { Box, Button, Collapsible, Flex, LabeledList, Section, Tooltip } from "../components";
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
  headshot_links?: (string | null)[];
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

export const CyborgProfile = (props) => {
  const { data } = useBackend<CyborgProfileContext>();

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
    <Window resizable width={860} height={600}>
      <Window.Content scrollable>
        <Flex>
          <Flex.Item width="276px" shrink={0} style={{ overflow: 'hidden' }}>
            <CyborgProfileImageElement />
          </Flex.Item>
          <Flex.Item pl="10px" grow>
            <Collapsible title="Описание Юнита" open>
              <Section style={{ whiteSpace: "pre-line" }}>
                {data.silicon_flavor_text || "———"}
              </Section>
            </Collapsible>
            <Collapsible title="Внеигровые заметки" open>
              <Section style={{ whiteSpace: "pre-line" }}>
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

const CyborgProfileImageElement = (props) => {
  const { data } = useBackend<CyborgProfileContext>();

  const headshotLinks = (data.headshot_links || []).filter(link => link?.length);
  const [selectedHeadshot, setSelectedHeadshot] = useState(0);
  const safeSelectedHeadshot = headshotLinks.length > 0
    ? selectedHeadshot % headshotLinks.length
    : 0;

  if (!headshotLinks.length) {
    return null;
  }

  return (
    <Section title="Изображение" pb="12" textAlign="center">
      <Box mb={1}>
        <img
          src={headshotLinks[safeSelectedHeadshot]}
          style={{
            width: '256px',
            height: '256px',
            maxWidth: '256px',
            maxHeight: '256px',
            objectFit: 'contain',
          }}
        />
      </Box>
      {headshotLinks.length > 1 && (
        <Box>
          <Button
            icon="arrow-left"
            onClick={() => setSelectedHeadshot((safeSelectedHeadshot + headshotLinks.length - 1) % headshotLinks.length)}
          />
          <Box inline mx={1} bold>{safeSelectedHeadshot + 1} / {headshotLinks.length}</Box>
          <Button
            icon="arrow-right"
            onClick={() => setSelectedHeadshot((safeSelectedHeadshot + 1) % headshotLinks.length)}
          />
        </Box>
      )}
    </Section>
  );
};

import { useBackend } from '../backend';
import { Box, Button, Dropdown, LabeledList, Section } from '../components';
import { Window } from '../layouts';

export const ShuttleConsole = (props) => {
  const { type = "shuttle", blind_drop } = props;
  return (
    <Window
      width={350}
      height={230}>
      <Window.Content>
        <ShuttleConsoleContent
          type={type}
          blind_drop={blind_drop} />
      </Window.Content>
    </Window>
  );
};

const getLocationNameById = (locations, id) => {
  return locations?.find(location => location.id === id)?.name;
};

const getLocationIdByName = (locations, name) => {
  return locations?.find(location => location.name === name)?.id;
};

const STATUS_COLOR_KEYS = {
  "In Transit": "good",
  "Idle": "average",
  "Igniting": "average",
  "Recharging": "average",
  "Missing": "bad",
  "Locked": "bad",
};

export const ShuttleConsoleContent = (props) => {
  const { act, data } = useBackend();
  const { type, blind_drop } = props;
  const {
    status,
    locked,
    destination,
    docked_location,
    timer_str,
    locations = [],
    pod_depart_locked,
  } = data;
  return (
    <Section>
      <Box
        bold
        fontSize="26px"
        textAlign="center"
        fontFamily="monospace">
        {timer_str || "00:00"}
      </Box>
      <Box
        textAlign="center"
        fontSize="14px"
        mb={1}>
        <Box
          inline
          bold>
          STATUS:
        </Box>
        <Box
          inline
          color={STATUS_COLOR_KEYS[status] || "bad"}
          ml={1}>
          {status || "Not Available"}
        </Box>
      </Box>
      <Section
        title={type === "shuttle" ? "Shuttle Controls" : "Base Launch Controls"}
        level={2}>
        <LabeledList>
          <LabeledList.Item label="Location">
            {docked_location || "Not Available"}
          </LabeledList.Item>
          <LabeledList.Item
            label="Destination"
            buttons={(
              type !== "shuttle" && locations.length===0 && !!blind_drop && (
                <Button
                  color="bad"
                  icon="exclamation-triangle"
                  disabled={!blind_drop}
                  content={"Blind Drop"}
                  onClick={() => act('random')} />
              ))} >
            {locations.length===0 && (
              <Box
                mb={1.7}
                color="bad">
                Not Available
              </Box>
            ) || locations.length===1 &&(
              <Box
                mb={1.7}
                color="average">
                {getLocationNameById(locations, destination)}
              </Box>
            ) || (
              <Dropdown
                mb={1.7}
                over
                width="240px"
                options={locations.map(location => location.name)}
                disabled={locked}
                selected={getLocationNameById(locations, destination) || "Select a Destination"}
                onSelected={value => act('set_destination', {
                  destination: getLocationIdByName(locations, value),
                })} />)}
          </LabeledList.Item>
        </LabeledList>
        {!!pod_depart_locked && (
          <Box color="bad" mb={1} textAlign="center" fontSize="12px">
            Security lock: Code Red alert required.
          </Box>
        )}
        <Button
          fluid
          content="Depart"
          disabled={!getLocationNameById(locations, destination)
            || locked || !!pod_depart_locked}
          icon="arrow-up"
          textAlign="center"
          onClick={() => act('move', {
            shuttle_id: destination,
          })} />
      </Section>
    </Section>
  );
};

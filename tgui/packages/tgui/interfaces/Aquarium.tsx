import { useBackend } from '../backend';
import {
  Box,
  Button,
  Flex,
  Icon,
  Knob,
  LabeledList,
  Section,
  Stack,
  Tooltip,
} from '../components';
import { Window } from '../layouts';

type FishData = {
  fish_ref: string;
  fish_name: string;
  fish_happiness: number;
  fish_icon: string;
  fish_alive: number;
  fish_health: number;
  fish_size: number;
  fish_weight: number;
  fish_beauty: number;
};

type PropData = {
  prop_ref: string;
  prop_name: string;
  prop_icon: string;
};

type Data = {
  fluidType: string;
  temperature: number;
  minTemperature: number;
  maxTemperature: number;
  fluidTypes: string[];
  allowBreeding: number;
  autoMode: number;
  beauty: number;
  capacity: number;
  fishCount: number;
  fishData: FishData[];
  propData: PropData[];
};

const capitalizeFirst = (input: string) =>
  input ? input.charAt(0).toUpperCase() + input.slice(1) : input;

export const Aquarium = (props) => {
  const { data } = useBackend<Data>();
  const { fishData } = data;

  return (
    <Window width={765} height={520} theme="ntos">
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Settings />
          </Stack.Item>
          <Stack.Item grow>
            <Flex>
              <Flex.Item height="320px" width="72%">
                <Section fill title={'Fish (' + fishData.length + ' / ' + data.capacity + ')'} scrollable>
                  <Stack wrap>
                    {fishData.map((fish) => (
                      <Stack.Item
                        width="48%"
                        height="112px"
                        mb={1}
                        key={fish.fish_ref}
                        style={{
                          background: 'rgba(36, 50, 67, 0.5)',
                          padding: '5px',
                          borderRadius: '1em',
                          border: '2px solid #574e82',
                        }}>
                        <FishInfo fish={fish} />
                      </Stack.Item>
                    ))}
                  </Stack>
                  {!fishData.length && (
                    <Box color="average" italic>
                      The aquarium is empty.
                    </Box>
                  )}
                </Section>
              </Flex.Item>
              <Flex.Item ml={1} grow>
                <PropTypes />
              </Flex.Item>
            </Flex>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const FishInfo = (props: { fish: FishData }) => {
  const { act } = useBackend<Data>();
  const { fish } = props;

  return (
    <Stack vertical>
      <Stack.Item>
        <Flex>
          <Flex.Item width="42px">
            {fish.fish_icon ? (
              <img
                src={fish.fish_icon}
                style={{
                  width: '40px',
                  height: '40px',
                  imageRendering: 'pixelated',
                  borderRadius: '0.5em',
                  background: '#151326',
                }}
              />
            ) : (
              <Icon name="water" size={2} />
            )}
          </Flex.Item>
          <Flex.Item grow>
            <Stack vertical>
              <Stack.Item
                ml={1}
                style={{ fontSize: '13px', fontWeight: 'bold' }}>
                {fish.fish_name}
              </Stack.Item>
              <Stack.Item mt={1}>
                {fish.fish_alive ? (
                  <CalculateHappiness happiness={fish.fish_happiness} />
                ) : (
                  <Icon ml={1} name="skull-crossbones" color="white" />
                )}
              </Stack.Item>
            </Stack>
          </Flex.Item>
          <Flex.Item>
            <Button
              icon="arrow-up"
              color="transparent"
              tooltip="Take out"
              onClick={() =>
                act('remove_item', {
                  item_reference: fish.fish_ref,
                })
              }
            />
          </Flex.Item>
        </Flex>
      </Stack.Item>
      <Stack.Item>
        <Flex>
          <Flex.Item width="50%">
            <Button
              fluid
              icon="paw"
              color="transparent"
              content="Pet"
              disabled={!fish.fish_alive}
              tooltip={
                'Health: ' +
                fish.fish_health +
                '% | ' +
                fish.fish_size +
                ' cm | ' +
                fish.fish_weight +
                ' g'
              }
              onClick={() =>
                act('pet_fish', {
                  fish_reference: fish.fish_ref,
                })
              }
            />
          </Flex.Item>
          <Flex.Item width="50%" ml={1}>
            <Button.Input
              fluid
              icon="keyboard"
              content="Rename"
              currentValue={fish.fish_name}
              onCommit={(e, value) =>
                act('rename_fish', {
                  fish_reference: fish.fish_ref,
                  chosen_name: value,
                })
              }
            />
          </Flex.Item>
        </Flex>
      </Stack.Item>
    </Stack>
  );
};

const CalculateHappiness = (props: { happiness: number }) => {
  return (
    <Box>
      {Array.from({ length: 5 }, (_, index) => (
        <Icon
          key={index}
          name="heart"
          color={props.happiness >= index ? 'red' : 'gray'}
          ml={index === 0 ? 1 : 0.3}
        />
      ))}
    </Box>
  );
};

const PropTypes = () => {
  const { act, data } = useBackend<Data>();
  const { propData } = data;

  return (
    <Section fill title="Props" scrollable>
      <Stack vertical>
        {propData.map((prop) => (
          <Stack.Item key={prop.prop_ref}>
            <Button
              fluid
              color="transparent"
              onClick={() =>
                act('remove_item', {
                  item_reference: prop.prop_ref,
                })
              }>
              <Flex align="center">
                <Flex.Item>
                  {prop.prop_icon ? (
                    <img
                      src={prop.prop_icon}
                      style={{
                        width: '32px',
                        height: '32px',
                        imageRendering: 'pixelated',
                      }}
                    />
                  ) : (
                    <Icon name="box" />
                  )}
                </Flex.Item>
                <Flex.Item ml={1} style={{ fontSize: '11px', fontWeight: 'bold' }}>
                  {capitalizeFirst(prop.prop_name)}
                </Flex.Item>
              </Flex>
            </Button>
          </Stack.Item>
        ))}
        {!propData.length && (
          <Box color="average" italic>
            Drag any item onto the aquarium to use it as a decoration.
          </Box>
        )}
      </Stack>
    </Section>
  );
};

const Settings = () => {
  const { act, data } = useBackend<Data>();
  const {
    temperature,
    minTemperature,
    maxTemperature,
    fluidTypes,
    fluidType,
    allowBreeding,
    autoMode,
    beauty,
    capacity,
    fishCount,
  } = data;

  return (
    <Flex fill>
      <Flex.Item grow>
        <Section fill title="Temperature">
          <Knob
            mt={2}
            size={1.4}
            mb={1}
            value={temperature}
            unit="K"
            minValue={minTemperature}
            maxValue={maxTemperature}
            step={1}
            stepPixelSize={1}
            onChange={(e, value) =>
              act('temperature', {
                temperature: value,
              })
            }
          />
        </Section>
      </Flex.Item>
      <Flex.Item ml={1} grow>
        <Section fill title="Fluid">
          <Flex direction="column">
            {fluidTypes.map((fluid) => (
              <Flex.Item key={fluid}>
                <Button
                  fluid
                  textAlign="center"
                  color="transparent"
                  content={fluid}
                  selected={fluidType === fluid}
                  onClick={() => act('fluid', { fluid })}
                />
              </Flex.Item>
            ))}
          </Flex>
        </Section>
      </Flex.Item>
      <Flex.Item ml={1} grow>
        <Section fill title="Settings">
          <LabeledList>
            <LabeledList.Item label="Breeding">
              <Button
                fluid
                color={allowBreeding ? 'good' : 'bad'}
                content={allowBreeding ? 'Enabled' : 'Disabled'}
                onClick={() => act('toggle_breeding')}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Auto mode">
              <Button
                fluid
                color={autoMode ? 'good' : 'bad'}
                content={autoMode ? 'Enabled' : 'Disabled'}
                onClick={() => act('toggle_auto')}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Fish">
              {fishCount} / {capacity}
            </LabeledList.Item>
            <LabeledList.Item label="Beauty">
              <Tooltip content="Aquarium beauty score from its inhabitants.">
                <Box inline>{beauty}</Box>
              </Tooltip>
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Flex.Item>
    </Flex>
  );
};

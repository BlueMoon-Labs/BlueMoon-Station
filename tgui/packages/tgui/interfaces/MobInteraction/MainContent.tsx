import { useBackend, useLocalState } from '../../backend';
import { Button, Icon, Input, Section, Slider, Stack, Tabs } from '../../components';
import {
  CharacterPrefsTab,
  ContentPreferencesTab,
  GenitalTab,
  InteractionsTab,
} from './tabs';

type MainTypes = {
  interaction_speeds: number[];
  currently_active_interaction: string;
  auto_interaction_pace: number;
  auto_interaction_target: string;
  is_auto_target_self: boolean;
}

export const MainContent = (props, context) => {
  const { act, data } = useBackend<MainTypes>(context);
  const [
    searchText,
    setSearchText,
  ] = useLocalState(context, 'searchText', '');
  const [tabIndex, setTabIndex] = useLocalState(context, 'tabIndex', 0);

  const [inFavorites, setInFavorites] = useLocalState(context, 'inFavorites', false);

  const interaction_speeds = (data.interaction_speeds || []) as number[];
  const { auto_interaction_pace, auto_interaction_target, currently_active_interaction, is_auto_target_self } = data;

  return (
    <Section fill>
      <Stack vertical fill>
        <Stack.Item>
          <Tabs fluid textAlign="center">
            <Tabs.Tab selected={tabIndex === 0} onClick={() => setTabIndex(0)}
              rightSlot={
                <Button
                  icon={"star" + (inFavorites ? "" : "-o")}
                  color="transparent"
                  onClick={() => setInFavorites(!inFavorites)}
                  tooltip={`Click here to ${inFavorites ? "show all" : "show favorites"}`} />
              }>
              Interactions
            </Tabs.Tab>
            <Tabs.Tab selected={tabIndex === 1} onClick={() => setTabIndex(1)}>
              Genital Options
            </Tabs.Tab>
            <Tabs.Tab selected={tabIndex === 2} onClick={() => setTabIndex(2)}>
              Character Prefs
            </Tabs.Tab>
            <Tabs.Tab selected={tabIndex === 3} onClick={() => setTabIndex(3)}>
              Preferences
            </Tabs.Tab>
          </Tabs>
        </Stack.Item>
        <Stack.Item>
          <Stack align="baseline" fill>
            <Stack.Item>
              <Icon name="search" />
            </Stack.Item>
            <Stack.Item grow>
              <Input
                fluid
                placeholder={
                  tabIndex === 0 ? "Search for an interaction"
                    : tabIndex === 1 ? "Search for a genital"
                      : "Searching is unavailable for this tab"
                }
                onInput={(e, value) => setSearchText(value)}
              />
            </Stack.Item>
          </Stack>
        </Stack.Item>
        <Stack.Item grow basis={0} mb={tabIndex === 0 ? -1 : -2.3}>
          <Section overflow="auto" fill>
            {(() => {
              switch (tabIndex) {
                default:
                  return <InteractionsTab />;
                case 1:
                  return <GenitalTab />;
                case 2:
                  return <CharacterPrefsTab />;
                case 3:
                  return <ContentPreferencesTab />;
              }
            })()}
          </Section>
        </Stack.Item>
        {tabIndex === 0 && (
          <Stack.Item>
            <Stack fill>
              {!!currently_active_interaction && (
                <Stack.Item>
                  <Button
                    icon="stop"
                    selected
                    tooltip={`Stop interacting with ${is_auto_target_self ? "yourself" : auto_interaction_target}`}
                    onClick={() => act("toggle_auto_interaction")}
                  />
                </Stack.Item>
              )}
              <Stack.Item grow>
                <Slider
                  fluid
                  minValue={1}
                  maxValue={interaction_speeds.length}
                  value={interaction_speeds.indexOf(auto_interaction_pace) + 1}
                  format={value => interaction_speeds[value - 1] / 10}
                  unit="seconds"
                  stepPixelSize={50}
                  onChange={(e, value) => act("interaction_pace",
                    { speed: interaction_speeds[value - 1] })}
                />
              </Stack.Item>
            </Stack>
          </Stack.Item>
        )}
      </Stack>
    </Section>
  );
};

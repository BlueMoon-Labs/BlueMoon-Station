import { useState } from 'react';

import { useBackend, useLocalState } from '../../backend';
import { Button, Icon, Input, Section, Slider, Stack, Tabs } from '../../components';
import {
  CharacterPrefsTab,
  ContentPreferencesTab,
  CustomInteractionsTab,
  GenitalTab,
  InteractionsTab,
  Pixelshift,
} from './tabs';

type MainTypes = {
  interaction_speeds: number[];
  currently_active_interaction: string;
  auto_interaction_pace: number;
  auto_interaction_target: string;
  is_auto_target_self: boolean;
  tab_interactions_enabled: boolean;
  tab_genital_options_enabled: boolean;
  tab_character_prefs_enabled: boolean;
  tab_sex_animations_enabled: boolean;
  tab_custom_enabled: boolean;
  compact_custom_tab: boolean;
}

export const TABS = [
  { key: 'interactions', label: 'Interactions', enabledKey: 'tab_interactions_enabled' },
  { key: 'custom', label: 'Custom', enabledKey: 'tab_custom_enabled' },
  { key: 'genitals', label: 'Genital Options', enabledKey: 'tab_genital_options_enabled' },
  { key: 'character_prefs', label: 'Character Prefs', enabledKey: 'tab_character_prefs_enabled' },
  { key: 'sex_animations', label: 'Sex Animations', enabledKey: 'tab_sex_animations_enabled' },
] as const;

export const MainContent = (props) => {
  const { act, data } = useBackend<MainTypes>();
  const [
    searchText,
    setSearchText,
  ] = useLocalState('searchText', '');
  const [activeTab, setActiveTab] = useState<string>('interactions');

  const [inFavorites, setInFavorites] = useLocalState('inFavorites', false);

  const interaction_speeds = (data.interaction_speeds || []) as number[];
  const { auto_interaction_pace, auto_interaction_target, currently_active_interaction, is_auto_target_self } = data;

  const visibleTabs = TABS.filter(t => {
    const enabled = data[t.enabledKey];
    return enabled === undefined || !!enabled;
  });
  const tab = (activeTab === 'preferences' || visibleTabs.some(t => t.key === activeTab))
    ? activeTab
    : (visibleTabs[0]?.key || 'preferences');

  const compactCustomTab = !!data.compact_custom_tab;
  const tabBarTabs = compactCustomTab
    ? visibleTabs.filter(t => t.key !== 'custom')
    : visibleTabs;
  const showCompactCustomButton = compactCustomTab
    && visibleTabs.some(t => t.key === 'custom');

  return (
    <Section fill>
      <Stack vertical fill>
        <Stack.Item>
          <Tabs fluid textAlign="center">
            {visibleTabs[0]?.key === 'interactions' && (
              <Tabs.Tab
                selected={tab === 'interactions'}
                onClick={() => setActiveTab('interactions')}
                leftSlot={showCompactCustomButton ? (
                  <Button
                    icon="plus"
                    color={tab === 'custom' ? 'green' : 'transparent'}
                    onClick={(e) => {
                      e.stopPropagation();
                      setActiveTab('custom');
                    }}
                    tooltip="Custom" />
                ) : undefined}
                rightSlot={
                  <Button
                    icon={"star" + (inFavorites ? "" : "-o")}
                    color="transparent"
                    onClick={() => setInFavorites(!inFavorites)}
                    tooltip={`Click here to ${inFavorites ? "show all" : "show favorites"}`} />
                }>
                Interactions
              </Tabs.Tab>
            )}
            {tabBarTabs.filter(t => t.key !== 'interactions').map(({ key, label }) => (
              <Tabs.Tab
                key={key}
                selected={tab === key}
                onClick={() => setActiveTab(key)}>
                {label}
              </Tabs.Tab>
            ))}
            <Tabs.Tab selected={tab === 'preferences'} onClick={() => setActiveTab('preferences')}>
              Preferences
            </Tabs.Tab>
          </Tabs>
        </Stack.Item>
        {tab === 'interactions' || tab === 'genitals' ? (
          <Stack.Item>
            <Stack align="baseline" fill>
              <Stack.Item>
                <Icon name="search" />
              </Stack.Item>
              <Stack.Item grow>
                <Input
                  fluid
                  placeholder={
                    tab === 'interactions' ? "Search for an interaction"
                      : "Search for a genital"
                  }
                  onInput={(e, value) => setSearchText(value)}
                />
              </Stack.Item>
          </Stack>
        </Stack.Item> ) : null}
        <Stack.Item grow basis={0} mb={tab === 'interactions' ? -1 : -2.3}>
          <Section scrollable fill>
            {(() => {
              switch (tab) {
                case 'custom':
                  return <CustomInteractionsTab />;
                case 'genitals':
                  return <GenitalTab />;
                case 'character_prefs':
                  return <CharacterPrefsTab />;
                case 'sex_animations':
                  return <Pixelshift />;
                case 'preferences':
                  return <ContentPreferencesTab />;
                default:
                  return <InteractionsTab />;
              }
            })()}
          </Section>
        </Stack.Item>
        {tab === 'interactions' && (
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

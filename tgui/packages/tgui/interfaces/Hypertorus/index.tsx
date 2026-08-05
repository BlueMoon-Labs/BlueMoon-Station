import { useState } from 'react';

import { useBackend } from '../../backend';
import { Box, Icon, Stack, Tabs } from '../../components';
import { Window } from '../../layouts';
import { Filters } from './Filters';
import { collectAlerts, getReactorStatus } from './helpers';
import { Overview } from './Overview';
import { Recipes } from './Recipes';
import { StatusHeader } from './StatusHeader';
import { Tuning } from './Tuning';
import { HypertorusData } from './types';

const TABS = [
  { id: 'overview', title: 'Обзор', icon: 'tachometer-alt' },
  { id: 'recipes', title: 'Рецепты', icon: 'flask' },
  { id: 'tuning', title: 'Настройка', icon: 'sliders-h' },
  { id: 'filters', title: 'Фильтры', icon: 'filter' },
];

export const Hypertorus = () => {
  const { data } = useBackend<HypertorusData>();
  const [tab, setTab] = useState('overview');
  const status = getReactorStatus(data);
  /** Счётчик на вкладке "Обзор": сюда стекаются все претензии реактора. */
  const alertCount = collectAlerts(data).filter(
    (alert) => alert.level !== 'info',
  ).length;

  return (
    <Window title="Гиперторовый термоядерный реактор" width={720} height={680}>
      <Window.Content
        scrollable
        className={`Hypertorus Hypertorus--${status.id}`}
      >
        <StatusHeader />
        <Tabs fluid className="Hypertorus__tabs">
          {TABS.map((entry) => (
            <Tabs.Tab
              key={entry.id}
              icon={entry.icon}
              selected={tab === entry.id}
              onClick={() => setTab(entry.id)}
            >
              <Stack inline align="center">
                <Stack.Item>{entry.title}</Stack.Item>
                {entry.id === 'overview' && alertCount > 0 && (
                  <Stack.Item>
                    <Box className="Hypertorus__tabBadge">{alertCount}</Box>
                  </Stack.Item>
                )}
                {entry.id === 'recipes' && !data.selected && (
                  <Stack.Item>
                    <Icon name="exclamation" color="average" />
                  </Stack.Item>
                )}
              </Stack>
            </Tabs.Tab>
          ))}
        </Tabs>
        {tab === 'overview' && <Overview />}
        {tab === 'recipes' && <Recipes />}
        {tab === 'tuning' && <Tuning />}
        {tab === 'filters' && <Filters />}
      </Window.Content>
    </Window>
  );
};

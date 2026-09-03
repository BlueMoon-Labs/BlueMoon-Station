import { useState } from 'react';

import { useBackend } from '../../backend';
import { Box, Icon, Stack, Tabs } from '../../components';
import { Window } from '../../layouts';
import { Filters } from './Filters';
import { collectAlerts, getReactorStatus } from './helpers';
import { Overview } from './Overview';
import { Recipes } from './Recipes';
import { StatusHeader } from './StatusHeader';
import { HypertorusData } from './types';

/**
 * Регуляторы живут прямо на обзоре, рядом со своими показаниями: отдельная
 * вкладка настройки заставляла прыгать туда-сюда между действием и откликом.
 */
const TABS = [
  { id: 'overview', title: 'Обзор', icon: 'tachometer-alt' },
  { id: 'recipes', title: 'Рецепты', icon: 'flask' },
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
    <Window title="Гиперторовый термоядерный реактор" width={720} height={740}>
      {/* Шапка и вкладки прибиты: скроллится только тело вкладки, и целостность
          с уровнем мощности не уезжают за край при чтении нижних секций. */}
      <Window.Content className={`Hypertorus Hypertorus--${status.id}`}>
        <Stack fill vertical>
          <Stack.Item>
            <StatusHeader />
          </Stack.Item>
          <Stack.Item>
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
          </Stack.Item>
          <Stack.Item grow className="Hypertorus__body">
            {tab === 'overview' && (
              <Overview onOpenRecipes={() => setTab('recipes')} />
            )}
            {tab === 'recipes' && <Recipes />}
            {tab === 'filters' && <Filters />}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

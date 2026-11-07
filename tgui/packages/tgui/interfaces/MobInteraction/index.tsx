import { useState } from 'react';

import { useBackend } from '../../backend';
import { Window } from '../../layouts';
import { MainContent, TABS } from './MainContent';

const BASE_WIDTH = 600;
const MIN_WIDTH = BASE_WIDTH - 200;
const MAX_WIDTH = 800;
const WIDTH_PER_TAB = 40;

type MobInteractionInfo = Record<string, boolean>;

export const MobInteraction = () => {
  const { data } = useBackend<MobInteractionInfo>();
  const [width] = useState(() => {
    if (!data.dynamic_window_size) {
      return BASE_WIDTH;
    }
    const enabledTabsCount = TABS.filter(t => {
      const enabled = data[t.enabledKey];
      return enabled === undefined || !!enabled;
    }).length;
    return Math.min(MAX_WIDTH, MIN_WIDTH + enabledTabsCount * WIDTH_PER_TAB);
  });

  return (
    <Window
      width={width}
      height={570}
      resizable>
      <Window.Content>
        <MainContent />
      </Window.Content>
    </Window>
  );
};

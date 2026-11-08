import { useBackend } from '../../backend';
import { Window } from '../../layouts';
import { MainContent, TABS } from './MainContent';

const BASE_WIDTH = 600;
const MIN_WIDTH = BASE_WIDTH - 200;
const MAX_WIDTH = 800;
const WIDTH_PER_TAB = 40;

type MobInteractionInfo = Partial<Record<
  (typeof TABS)[number]['enabledKey'] | 'dynamic_window_size' | 'compact_custom_tab',
  boolean | 0 | 1
>>;

export const MobInteraction = () => {
  const { data } = useBackend<MobInteractionInfo>();
  let width = BASE_WIDTH;
  if (data.dynamic_window_size) {
    const enabledTabsCount = TABS.filter(({ key, enabledKey }) => (
      (data[enabledKey] === undefined || !!data[enabledKey])
      && (key !== 'custom' || !data.compact_custom_tab)
    )).length;
    width = Math.min(MAX_WIDTH, MIN_WIDTH + enabledTabsCount * WIDTH_PER_TAB);
  }

  return (
    <Window
      width={width}
      height={650}
      resizable>
      <Window.Content>
        <MainContent />
      </Window.Content>
    </Window>
  );
};

import { useBackend, useLocalState } from '../../backend';
import { Button, Stack } from '../../components';
import { Window } from '../../layouts';
import { SettingsTab } from './SettingsTab';
import { AntagsSection } from './AntagsSection';
import { KeybindingsTab } from './KeybindingsTab';

type GamePrefData = {
  has_admin: boolean;
};

export const GamePreferences = (props, context) => {
  const { data } = useBackend<GamePrefData>(context);
  const [currentPage, setCurrentPage] = useLocalState(context, 'currentPage', 0);

  const pages = [
    { label: 'Настройки', component: SettingsTab },
    { label: 'Антагонисты', component: AntagsSection },
    { label: 'Горячие клавиши', component: KeybindingsTab },
  ];

  const safePage = currentPage < pages.length ? currentPage : 0;

  let pageContents;
  if (safePage < pages.length) {
    const PageComponent = pages[safePage].component;
    pageContents = <PageComponent has_admin={data.has_admin} />;
  }

  return (
    <Window width={800} height={700} resizable>
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Stack fill>
              {pages.map(({ label }, idx) => (
                <Stack.Item key={idx} grow>
                  <Button
                    align="center"
                    fontSize="1.2em"
                    fluid
                    selected={safePage === idx}
                    onClick={() => setCurrentPage(idx)}
                  >
                    {label}
                  </Button>
                </Stack.Item>
              ))}
            </Stack>
          </Stack.Item>
          <Stack.Divider />
          <Stack.Item grow shrink basis="1px">
            {pageContents}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

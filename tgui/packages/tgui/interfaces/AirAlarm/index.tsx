import { useState } from 'react';

import { useBackend } from '../../backend';
import { Section, Stack, Tabs } from '../../components';
import { Window } from '../../layouts';
import { InterfaceLockNoticeBox } from '../common/InterfaceLockNoticeBox';
import { AirAlarmStatus } from './AlarmStatus';
import { Modes } from './screens/Modes';
import { Overview } from './screens/Overview';
import { Scrubbers } from './screens/Scrubbers';
import { Thresholds } from './screens/Thresholds';
import { Vents } from './screens/Vents';
import { ThresholdModal } from './ThresholdModal';
import { AirAlarmData, ThresholdEdit } from './types';

const TABS = [
  { id: 'overview', title: 'Обзор', icon: 'tachometer-alt' },
  { id: 'vents', title: 'Венты', icon: 'sign-out-alt' },
  { id: 'scrubbers', title: 'Скрубберы', icon: 'filter' },
  { id: 'modes', title: 'Режим', icon: 'cog' },
  { id: 'thresholds', title: 'Пороги', icon: 'chart-bar' },
];

export const AirAlarm = () => {
  const { data } = useBackend<AirAlarmData>();
  const locked = data.locked && !data.siliconUser;
  const [tab, setTab] = useState('overview');
  const [edit, setEdit] = useState<ThresholdEdit>(null);

  const renderScreen = () => {
    switch (tab) {
      case 'vents':
        return <Vents />;
      case 'scrubbers':
        return <Scrubbers />;
      case 'modes':
        return <Modes />;
      case 'thresholds':
        return <Thresholds onEdit={setEdit} />;
      default:
        return <Overview />;
    }
  };

  return (
    <Window width={520} height={680}>
      <Window.Content scrollable>
        <Stack vertical>
          <Stack.Item mb={-1}>
            <InterfaceLockNoticeBox
              lockLabel="Блокировка интерфейса:"
              lockedText="Заблокирован"
              unlockedText="Разблокирован"
              swipeText={`Приложите карту доступа, чтобы ${
                data.locked ? 'разблокировать' : 'заблокировать'
              } интерфейс.`}
            />
          </Stack.Item>
          <Stack.Item>
            <AirAlarmStatus />
          </Stack.Item>
          {!locked && (
            <Stack.Item grow>
              <Section fitted>
                <Tabs fluid>
                  {TABS.map((entry) => (
                    <Tabs.Tab
                      key={entry.id}
                      icon={entry.icon}
                      selected={tab === entry.id}
                      onClick={() => setTab(entry.id)}>
                      {entry.title}
                    </Tabs.Tab>
                  ))}
                </Tabs>
              </Section>
              <Section>{renderScreen()}</Section>
            </Stack.Item>
          )}
        </Stack>
        {edit && (
          <ThresholdModal
            key={`${edit.env}-${edit.val}`}
            edit={edit}
            onClose={() => setEdit(null)}
          />
        )}
      </Window.Content>
    </Window>
  );
};

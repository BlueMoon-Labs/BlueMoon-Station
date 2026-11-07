import { BooleanLike } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Icon, NoticeBox, Section, Stack, Tabs } from '../components';
import { Window } from '../layouts';
import { ScenarioBanner, ScenarioData, ScenarioPhase, TrainingScenario } from './AntagTrainingScenario';
import { SquadData, TrainingSquads } from './AntagTrainingSquads';

export type BoardSlot = {
  id: string;
  label: string;
  side_name: string;
  role_name: string | null;
  program_name: string;
  count: number;
  required: BooleanLike;
  occupants: string[];
  free: number;
  joinable: BooleanLike;
};
export type BoardScenario = { name: string; phase: ScenarioPhase; venue: string | null; slots: BoardSlot[] };
export type BoardSquad = {
  id: string;
  name: string;
  color: string;
  open: BooleanLike;
  leader: string | null;
  members: string[];
  sector: string | null;
  scenario: BoardScenario | null;
};

export const phaseNames: Record<ScenarioPhase, string> = {
  setup: 'разбор слотов',
  starting: 'запускается',
  running: 'идёт партия',
  summary: 'итог',
};

type BoardListProps = {
  squads: BoardSquad[];
  /** Без обработчика список только для просмотра. */
  onJoin?: (squadId: string, slotId?: string) => void;
  empty: string;
};

/** Группы полигона с их сценариями и слотами: доска хаба и каталог входа. */
export const SquadBoardList = ({ squads, onJoin, empty }: BoardListProps) => {
  if (!squads.length) return <Box color="label">{empty}</Box>;
  return (
    <>
      {squads.map((squad) => (
        <Section
          key={squad.id}
          title={squad.name}
          buttons={onJoin && !!squad.open ? <Button icon="right-to-bracket" onClick={() => onJoin(squad.id)}>Войти в группу</Button> : <Box color="label">{squad.open ? 'Открытая' : 'По приглашению'}</Box>}>
          <Box color="label">
            <Icon name="flag" color={squad.color} mr={0.5} />
            Лидер {squad.leader || '—'} · участников {squad.members.length}{squad.sector ? ` · сектор «${squad.sector}»` : ''}
          </Box>
          {!!squad.members.length && <Box mt={0.25}>{squad.members.join(', ')}</Box>}
          {squad.scenario ? (
            <Box mt={1}>
              <Box bold mb={0.5}>
                <Icon name="flag-checkered" mr={0.5} />
                Сценарий «{squad.scenario.name}» · {phaseNames[squad.scenario.phase]}{squad.scenario.venue ? ` · ${squad.scenario.venue}` : ''}
              </Box>
              {squad.scenario.slots.map((slot) => (
                <Stack key={slot.id} align="center" mb={0.5}>
                  <Stack.Item grow>
                    <b>{slot.label}</b> · {slot.side_name} · {slot.role_name || 'учебный персонаж'}, {slot.program_name}
                    {slot.required ? ' · обязательный' : ''}
                    <Box color="label">{slot.occupants.length ? slot.occupants.join(', ') : 'никого'} · мест {slot.occupants.length}/{slot.count}</Box>
                  </Stack.Item>
                  {onJoin && !!slot.joinable && (
                    <Stack.Item>
                      <Button icon="user-plus" onClick={() => onJoin(squad.id, slot.id)}>Занять слот</Button>
                    </Stack.Item>
                  )}
                </Stack>
              ))}
            </Box>
          ) : (
            <Box color="label" mt={0.5}>Сценарий не выбран: группа тренируется свободно.</Box>
          )}
        </Section>
      ))}
    </>
  );
};

type BoardData = SquadData &
  ScenarioData & {
    participant: BooleanLike;
    board?: BoardSquad[];
    members?: { id: string; name: string; self: BooleanLike; connected: BooleanLike }[];
  };

export const AntagTrainingBoard = () => {
  const { data } = useBackend<BoardData>();
  const [tab, setTab] = useState('squads');
  return (
    <Window width={620} height={640} title="Доска групп и сценариев">
      <Window.Content scrollable>
        {data.participant ? (
          <>
            <ScenarioBanner />
            <Tabs>
              <Tabs.Tab icon="flag" selected={tab === 'squads'} onClick={() => setTab('squads')}>Группы</Tabs.Tab>
              <Tabs.Tab icon="flag-checkered" selected={tab === 'scenario'} onClick={() => setTab('scenario')}>Сценарий</Tabs.Tab>
            </Tabs>
            {tab === 'squads' ? <TrainingSquads members={data.members || []} /> : <TrainingScenario />}
          </>
        ) : (
          <>
            <NoticeBox info>Доска только для просмотра. Чтобы войти в группу или занять слот, откройте вход на полигон.</NoticeBox>
            <SquadBoardList squads={data.board || []} empty="Групп на полигоне пока нет." />
          </>
        )}
      </Window.Content>
    </Window>
  );
};

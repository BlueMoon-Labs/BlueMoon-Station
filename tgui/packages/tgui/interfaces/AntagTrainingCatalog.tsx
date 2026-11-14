import { BooleanLike } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Icon, NoticeBox, ProgressBar, Section, Stack } from '../components';
import { Window } from '../layouts';
import { BoardSquad, SquadBoardList } from './AntagTrainingBoard';
import { roleAllowed, roleName, RolePicker, TrainingRoleEntry } from './AntagTrainingRolePicker';

export type TrainingProgramEntry = {
  id: string;
  name: string;
  category: string;
  desc?: string | null;
  sector?: string | null;
  icon?: string | null;
  color?: string | null;
  learn?: string[];
  difficulty?: number;
  order?: number;
  exercises_done?: number;
  exercises_total?: number;
  allowed_roles?: number;
  /** Программа, которой входят в этот шаг, если шаг - не сама программа. */
  program?: string;
};

export type AntagTrainingCatalogData = {
  programs: TrainingProgramEntry[];
  mechanics?: TrainingProgramEntry | null;
  can_load_character: BooleanLike;
  roles?: TrainingRoleEntry[];
  /** Открытые группы полигона: войти сразу в группу или в свободный слот её сценария. */
  squads?: BoardSquad[];
};

const categoryOrder = ['Общее', 'Предатели экипажа', 'Чужаки', 'Культы и магия', 'Существа', 'Станционные угрозы', 'Команды'];

const categoryRank = (category: string) => {
  const index = categoryOrder.indexOf(category);
  return index === -1 ? categoryOrder.length : index;
};

/** Программы по разделам в порядке каталога; неизвестный раздел идёт последним. */
export const groupByCategory = <T extends { category: string }>(programs: T[]): [string, T[]][] => {
  const groups = new Map<string, T[]>();
  for (const program of programs) {
    groups.set(program.category, [...(groups.get(program.category) || []), program]);
  }
  return [...groups.entries()].sort(([first], [second]) => categoryRank(first) - categoryRank(second));
};

/** Шаги «С чего начать»: программы с местом и шаг механик, по месту. */
export const startSteps = (programs: TrainingProgramEntry[], mechanics?: TrainingProgramEntry | null) =>
  [...programs, ...(mechanics ? [mechanics] : [])].filter((entry) => (entry.order ?? 0) > 0).sort((first, second) => (first.order ?? 0) - (second.order ?? 0));

const difficultyNames = ['', 'простая', 'средняя', 'сложная'];

export const DifficultyMarks = ({ level }: { level?: number }) => {
  if (!level) return null;
  return (
    <span className="AntagTraining__level" title={`Сложность: ${difficultyNames[level]}`}>
      {[1, 2, 3].map((mark) => <i key={mark} className={mark <= level ? 'AntagTraining__levelMark--on' : undefined} />)}
    </span>
  );
};

const ProgressLabel = ({ entry }: { entry: TrainingProgramEntry }) => {
  if (!entry.exercises_total) return null;
  const done = entry.exercises_done ?? 0;
  return <Box as="span" className="AntagTraining__progress" color={done >= entry.exercises_total ? 'good' : 'label'}>{done}/{entry.exercises_total}</Box>;
};

const ProgramRow = (props: { entry: TrainingProgramEntry; selected: boolean; step?: number; onSelect: () => void }) => {
  const { entry, selected, step, onSelect } = props;
  return (
    <div className={`AntagTraining__row${selected ? ' AntagTraining__row--selected' : ''}`} onClick={onSelect}>
      {!!step && <span className="AntagTraining__step">{step}</span>}
      <Icon className="AntagTraining__rowIcon" name={entry.icon || 'circle'} color={entry.color || 'label'} />
      <span className="AntagTraining__rowName">{entry.name}</span>
      <ProgressLabel entry={entry} />
      <DifficultyMarks level={entry.difficulty} />
    </div>
  );
};

export const AntagTrainingCatalog = () => {
  const { act, data } = useBackend<AntagTrainingCatalogData>();
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [useCharacter, setUseCharacter] = useState(!!data.can_load_character);
  const [role, setRole] = useState('default');
  const [pickRole, setPickRole] = useState(false);
  const [mode, setMode] = useState<'programs' | 'squads'>('programs');
  const roles = data.roles || [];
  const squads = data.squads || [];
  const joining = mode === 'squads';
  const steps = startSteps(data.programs, data.mechanics);
  const selected = [...data.programs, ...(data.mechanics ? [data.mechanics] : [])].find((program) => program.id === selectedId);
  const ownCharacter = useCharacter && !!data.can_load_character;
  return (
    <Window width={900} height={640}>
      <Window.Content className="AntagTrainingCatalog">
        <Stack vertical fill>
          <Stack.Item>
            <NoticeBox info>Вход означает согласие на совместные тренировки и PvP. Роль можно сменить позже в пульте.</NoticeBox>
          </Stack.Item>
          <Stack.Item grow>
            <Stack fill>
              <Stack.Item basis="42%">
                <Section
                  fill
                  scrollable
                  title={joining ? 'Открытые группы' : 'Программы'}
                  buttons={
                    <>
                      <Button icon="list" selected={!joining} onClick={() => setMode('programs')}>Программы</Button>
                      <Button icon="flag" selected={joining} onClick={() => setMode('squads')}>Группы{squads.length ? ` (${squads.length})` : ''}</Button>
                    </>
                  }>
                  {joining && (
                    <SquadBoardList
                      squads={squads}
                      empty="Открытых групп сейчас нет. Войдите программой и соберите свою группу в пульте, во вкладке «Участники»."
                      onJoin={(squad, slot) => act('join_squad', { squad, slot, use_character: ownCharacter, role })}
                    />
                  )}
                  {!joining && !!steps.length && (
                    <Box mb={1.5} className="AntagTraining__start">
                      <Box bold mb={0.5}>С чего начать</Box>
                      {steps.map((entry, index) => (
                        <ProgramRow key={`start-${entry.id}`} entry={entry} step={index + 1} selected={entry.id === selectedId} onSelect={() => setSelectedId(entry.id)} />
                      ))}
                    </Box>
                  )}
                  {!joining && groupByCategory(data.programs).map(([category, programs]) => (
                    <Box key={category} mb={1.5}>
                      <Box bold color="label" mb={0.5}>{category}</Box>
                      {programs.map((program) => (
                        <ProgramRow key={program.id} entry={program} selected={program.id === selectedId} onSelect={() => setSelectedId(program.id)} />
                      ))}
                    </Box>
                  ))}
                </Section>
              </Stack.Item>
              <Stack.Item grow basis={0}>
                <Section fill scrollable>
                  <Stack vertical fill>
                    <Stack.Item grow>
                      {joining ? (
                        <Box color="label">
                          Вход в группу - программой «Снаряжение и бой», с куклой и должностью, выбранными ниже. В слоте сценария своя должность, а программу слота вы получите, когда лидер нажмёт «Старт». Если слот займут, пока вы входите, вы окажетесь на полигоне без группы.
                        </Box>
                      ) : selected ? <ProgramDetails entry={selected} /> : (
                        <Box color="label">Выберите программу слева. Если вы здесь впервые, начните с первого шага в «С чего начать».</Box>
                      )}
                    </Stack.Item>
                    <Stack.Item>
                      <Box color="label" mb={0.5}>Кукла</Box>
                      <Button icon="user" selected={ownCharacter} disabled={!data.can_load_character} onClick={() => setUseCharacter(true)}>Своя кукла</Button>
                      <Button icon="user-shield" selected={!ownCharacter} onClick={() => setUseCharacter(false)}>Учебная кукла</Button>
                      <Box color="label" mt={0.5}>
                        {ownCharacter ? 'Имя, раса и внешность из активного слота персонажа.' : 'Стандартный учебный персонаж.'} Снаряжение выдаётся учебное.
                      </Box>
                    </Stack.Item>
                    {!!roles.length && (
                      <Stack.Item>
                        <Box color="label" mb={0.5}>Должность</Box>
                        <Button icon="id-card" selected={pickRole} onClick={() => setPickRole(!pickRole)}>{roleName(roles, role)}</Button>
                        <Box color="label" mt={0.5}>Снаряжение, ID с доступом и импланты должности станции. Работает со свободной тренировкой и антагонистами экипажа.</Box>
                        {pickRole && <Box mt={1}><RolePicker roles={roles} selected={role} allowed={joining ? undefined : selected?.allowed_roles} onSelect={(id) => { setRole(id); setPickRole(false); }} /></Box>}
                      </Stack.Item>
                    )}
                    {!joining && !!selected && !roleAllowed(roles.find((entry) => entry.id === role), selected.allowed_roles) && (
                      <Stack.Item>
                        <NoticeBox>Эта программа работает только с человеком. Выберите должность экипажа или программу «Снаряжение и бой».</NoticeBox>
                      </Stack.Item>
                    )}
                    {!joining && (
                      <Stack.Item>
                        <Button fluid className="AntagTraining__mainAction" textAlign="center" icon="play" disabled={!selected || !roleAllowed(roles.find((entry) => entry.id === role), selected.allowed_roles)} onClick={() => selected && act('start', { program: selected.program || selected.id, use_character: ownCharacter, role })}>Войти</Button>
                      </Stack.Item>
                    )}
                  </Stack>
                </Section>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const ProgramDetails = ({ entry }: { entry: TrainingProgramEntry }) => (
  <>
    <div className="AntagTraining__detailHead">
      <Icon className="AntagTraining__detailIcon" name={entry.icon || 'circle'} color={entry.color || 'label'} />
      <div>
        <Box bold fontSize={1.4}>{entry.name}</Box>
        <Box color="label" mt={0.25}>{entry.category}{entry.difficulty ? ` · сложность ${difficultyNames[entry.difficulty]}` : ''}</Box>
      </div>
    </div>
    <Box my={1}>{entry.desc}</Box>
    {!!entry.learn?.length && (
      <Box mb={1}>
        <Box bold mb={0.5}>Что вы освоите</Box>
        {entry.learn.map((item) => <Box key={item} className="AntagTraining__learn"><Icon name="angle-right" mr={0.75} color="label" />{item}</Box>)}
      </Box>
    )}
    {!!entry.sector && <Box color="label" mb={1}><Icon name="map" mr={0.5} />Сектор: {entry.sector}</Box>}
    {!!entry.exercises_total && (
      <ProgressBar value={(entry.exercises_done ?? 0) / entry.exercises_total} color={(entry.exercises_done ?? 0) >= entry.exercises_total ? 'good' : 'teal'}>
        Упражнения за раунд: {entry.exercises_done ?? 0} из {entry.exercises_total}
      </ProgressBar>
    )}
  </>
);

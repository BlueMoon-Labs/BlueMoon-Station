import { BooleanLike } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Dropdown, Icon, Input, NoticeBox, ProgressBar, Section, Stack, Tabs } from '../components';
import { Window } from '../layouts';
import { DifficultyMarks, groupByCategory } from './AntagTrainingCatalog';
import { PadsData, TrainingPads } from './AntagTrainingPads';
import { roleName, RolePicker, TrainingRoleEntry } from './AntagTrainingRolePicker';
import { ScenarioBanner, ScenarioData, TrainingScenario } from './AntagTrainingScenario';
import { resetLocked, SectorBooking, sectorClosed, SquadData, TrainingSquads } from './AntagTrainingSquads';
import { limitLabel, limitReached, StandData, StandToggle, TrainingStand } from './AntagTrainingStand';

type Choice = { id: string; name: string };
type CatalogEntry = Choice & { category: string; desc?: string | null; icon?: string | null; color?: string | null };
type ExerciseProgress = { exercises_done?: number; exercises_total?: number; practice?: number };
type Zone = Choice & ExerciseProgress & { desc: string; current: BooleanLike; members: number; targets: number };
type SectorState = 'unloaded' | 'loading' | 'ready' | 'unloading';
type Sector = Choice & ExerciseProgress & { desc: string; state: SectorState; members: number; current: BooleanLike };
type Target = Choice & {
  health: number;
  max_health: number;
  dead: BooleanLike;
  human: BooleanLike;
  living: BooleanLike;
  brute?: number;
  burn?: number;
  toxin?: number;
  oxygen?: number;
  stamina?: number | null;
  states?: string[];
  zone: string;
  owner: string;
  can_manage: BooleanLike;
};
type ExerciseStep = { name: string; done: BooleanLike; current: BooleanLike; hint: string | null };
export type Exercise = Choice & {
  desc: string;
  difficulty: number;
  zone: string | null;
  practice: BooleanLike;
  score_rule: string | null;
  steps: ExerciseStep[];
  best: { time: number; hints: number; score: number } | null;
  run: { elapsed?: number; hints?: number; ended: BooleanLike; success: BooleanLike; score?: number | null; result: string | null } | null;
};

type RoleGoal = { text: string; done: BooleanLike };

type Route = ExerciseProgress & { sectors: Choice[]; scenarios: (Choice & { venue: string | null })[]; presets: Choice[] };

export type AntagTrainingData = SquadData & ScenarioData & PadsData & {
  preparing: BooleanLike;
  supply_ready: BooleanLike;
  practice_ready: BooleanLike;
  last_feedback: string | null;
  last_kit: string | null;
  kits: Choice[];
  paths: (Choice & { desc: string })[];
  selected_path: string | null;
  path_stage: number;
  recipes: (Choice & { ingredients: string; hint: string; components: BooleanLike; result: BooleanLike })[];
  resource: { name: string; value: number; max: number; description: string } | null;
  practice: { id: string; target: string; complete: BooleanLike; hint: string; damage: number; healing: number; last_damage: number; critical_seconds: number | null; steps?: { name: string; done: BooleanLike; current: BooleanLike }[] | null } | null;
  dance_lesson?: BooleanLike;
  spirit_lesson?: BooleanLike;
  exercises: Exercise[];
  duel: { phase: string; first: string; second: string; lethal: BooleanLike; remaining: number; involved: BooleanLike; can_accept: BooleanLike } | null;
  last_duel_result: string | null;
  duel_ready: BooleanLike;
  program: string;
  program_id: string;
  program_allowed_roles?: number;
  auto_recover: BooleanLike;
  health: number | null;
  max_health: number | null;
  target_limit: number;
  supply_count: number;
  supply_limit: number;
  structure_count: number;
  structure_limit: number;
  build_error: string | null;
  busy: BooleanLike;
  return_to_body: BooleanLike;
  /** Хаб полигона загружен: кнопка «В хаб» ведёт в его вестибюль. */
  hub?: BooleanLike;
  cleaning_personal: BooleanLike;
  reset_vote: { zone: string; approved: number; total: number; remaining: number; voted: BooleanLike; can_vote?: BooleanLike; can_cancel?: BooleanLike } | null;
  members: (Choice & {
    program: string;
    health: number | null;
    max_health: number | null;
    dead: BooleanLike;
    connected: BooleanLike;
    zone: string;
    defeats: number;
    self: BooleanLike;
  })[];
  zones: Zone[];
  sectors: Sector[];
  sector_idle_minutes: number;
  equipment: CatalogEntry[];
  structures: CatalogEntry[];
  injuries: Choice[];
  conditions?: Choice[];
  creatures: Choice[];
  targets: Target[];
  programs: CatalogEntry[];
  options: string[];
  /** Где тренировать программу: сектора, упражнения, сценарии с её слотом и пресеты площадок. */
  route?: Route;
  /** Учебные цели ролей участника с отметкой выполнения. */
  role_objectives?: RoleGoal[];
  /** Первая невыполненная цель или текущий шаг упражнения. */
  role_next?: string | null;
  roles?: TrainingRoleEntry[];
  role?: string;
  role_applies?: BooleanLike;
  option_hints?: Record<string, string>;
  heretic?: BooleanLike;
  target_action?: string | null;
  start_tab?: string | null;
  stand?: StandData | null;
};

const sectorIcons: Record<string, string> = {
  hub: 'shield-halved', melee: 'hand-fist', range: 'bullseye',
  pve: 'paw', laboratory: 'flask', dark: 'moon',
  engineering: 'bolt', atmos: 'wind', eva: 'user-astronaut',
  robotics: 'robot', station: 'building',
};
const sectorStates: Record<SectorState, { label: string; color: string }> = {
  unloaded: { label: 'Не загружен', color: 'label' },
  loading: { label: 'Загружается…', color: 'average' },
  ready: { label: 'Готов', color: 'good' },
  unloading: { label: 'Выгружается…', color: 'average' },
};
const pluralMinutes = (count: number) => {
  const tail = count % 100;
  if (tail > 10 && tail < 20) return 'минут';
  if (count % 10 === 1) return 'минуту';
  return count % 10 >= 2 && count % 10 <= 4 ? 'минуты' : 'минут';
};
const tabs = [
  { name: 'Начать', icon: 'play' },
  { name: 'Упражнения', icon: 'list-check' },
  { name: 'Зоны', icon: 'map' },
  { name: 'Снаряжение', icon: 'toolbox' },
  { name: 'Мастерская', icon: 'hammer' },
  { name: 'Цели', icon: 'crosshairs' },
  { name: 'Моя роль', icon: 'user-gear' },
  { name: 'Участники', icon: 'users' },
  { name: 'Сценарий', icon: 'flag-checkered' },
  { name: 'Площадки', icon: 'vector-square' },
];
const healthFraction = (health: number, maximum: number) => health / Math.max(1, maximum);

export const AntagTraining = () => {
  const { act, data } = useBackend<AntagTrainingData>();
  const [tab, setTab] = useState(data.start_tab === 'exercises' ? 'Упражнения' : 'Начать');
  return (
    <Window width={960} height={760}>
      <Window.Content fitted className="AntagTraining">
        <div className="AntagTraining__header">
          <Stack align="center" justify="space-between" wrap>
            <Stack.Item>
              <Box className="AntagTraining__title">Общий полигон</Box>
              <Box color="label" mt={0.5}>{data.program}</Box>
            </Stack.Item>
            <Stack.Item>
              <Box className="AntagTraining__capacity"><Icon name="users" /> Участников: {data.members.length}</Box>
              <Box color="label" textAlign="right" mt={0.5}>Вход через меню гостролей или капсулу в Гост-Кафе</Box>
            </Stack.Item>
          </Stack>
          <Stack align="center" mt={1.5} wrap>
            <Stack.Item grow basis="180px">
              {data.health === null ? (
                <Box color="label">У этого тела нет здоровья: восстановление создаёт его заново.</Box>
              ) : (
                <ProgressBar value={healthFraction(data.health, data.max_health ?? 0)} color={data.health > 0 ? 'good' : 'bad'}>
                  Здоровье {Math.round(data.health)} / {data.max_health}
                </ProgressBar>
              )}
            </Stack.Item>
            {!!data.stand && <Stack.Item><StandToggle /></Stack.Item>}
            <Stack.Item><Button icon="heart" onClick={() => act('heal')}>Восстановиться</Button></Stack.Item>
            <Stack.Item><Button icon="door-open" disabled={!data.hub || !!data.busy || !!data.preparing} onClick={() => act('hub')}>В хаб</Button></Stack.Item>
            <Stack.Item><Button icon="house" disabled={!!data.busy || !!data.preparing} onClick={() => act('move', { zone: 'hub' })}>В центр</Button></Stack.Item>
            <Stack.Item><Button.Confirm icon="sign-out-alt" color="transparent" content="Выйти" confirmContent={data.return_to_body ? 'Вернуться в тело в кафе?' : 'Выбрать, куда выйти?'} onClick={() => act('exit')} /></Stack.Item>
          </Stack>
        </div>
        {!!data.reset_vote && (
          <div className="AntagTraining__vote">
          <Box bold>Сброс: {data.reset_vote.zone}</Box>
          <Box mt={0.5} mb={0.5}>Согласны {data.reset_vote.approved} из {data.reset_vote.total} · осталось {data.reset_vote.remaining} с. Обстановка будет очищена, участники вернутся в центр. Персонажи и их инвентарь сохранятся.</Box>
          {data.reset_vote.can_vote === 0 ? (
            <Box color="label">Сектор занят группой: голосуют только её участники.</Box>
          ) : (
            <Button icon="check" disabled={!!data.reset_vote.voted} onClick={() => act('reset_approve')}>{data.reset_vote.voted ? 'Вы согласились' : 'Согласиться'}</Button>
          )}
          {data.reset_vote.can_cancel !== 0 && <Button icon="xmark" color="transparent" onClick={() => act('reset_cancel')}>Отменить сброс</Button>}
          </div>
        )}
        {!!data.duel && <TrainingDuel />}
        <ScenarioBanner />
        <Tabs className="AntagTraining__tabs">
          {[...tabs, ...(data.stand?.enabled ? [{ name: 'Стенд', icon: 'flask-vial' }] : [])].map(({ name, icon }) => (
            <Tabs.Tab key={name} selected={tab === name} onClick={() => setTab(name)} icon={icon}>{name}</Tabs.Tab>
          ))}
        </Tabs>
        <div className="AntagTraining__body">
          {!!data.busy && <NoticeBox>Сектор восстанавливается. Подождите завершения работ.</NoticeBox>}
          {!!data.preparing && <NoticeBox>Подготавливаем комплект. Восстановление и выход доступны.</NoticeBox>}
          {!!data.last_feedback && <NoticeBox>{data.last_feedback}</NoticeBox>}
          {tab === 'Начать' && <TrainingStart navigate={setTab} />}
          {tab === 'Упражнения' && <TrainingExercises navigate={setTab} />}
          {tab === 'Зоны' && <TrainingZones />}
          {tab === 'Снаряжение' && <TrainingEquipment />}
          {tab === 'Мастерская' && <TrainingWorkshop />}
          {tab === 'Цели' && <TrainingTargets />}
          {tab === 'Моя роль' && <TrainingProgram navigate={setTab} />}
          {tab === 'Участники' && <TrainingMembers />}
          {tab === 'Сценарий' && <TrainingScenario />}
          {tab === 'Площадки' && <TrainingPads />}
          {tab === 'Стенд' && <TrainingStand />}
        </div>
      </Window.Content>
    </Window>
  );
};

const TrainingDuel = () => {
  const { act, data } = useBackend<AntagTrainingData>();
  const duel = data.duel;
  if (!duel) return null;
  return (
    <div className="AntagTraining__vote">
      <Box bold>{duel.first} — {duel.second} · {duel.lethal ? 'до смерти' : 'до крита'}</Box>
      <Box my={0.5}>{duel.phase === 'invite' ? 'Ожидаем согласия' : duel.phase === 'countdown' ? 'Приготовьтесь, дождитесь команды «Бой»' : 'Бой идёт'} · {duel.remaining} с.</Box>
      {!!duel.can_accept && <Button icon="check" onClick={() => act('duel_accept')}>Принять вызов</Button>}
      {!!duel.involved && <Button icon="xmark" color="transparent" onClick={() => act('duel_cancel')}>Отменить дуэль</Button>}
    </div>
  );
};

const TrainingStart = ({ navigate }: { navigate: (tab: string) => void }) => {
  const { act, data } = useBackend<AntagTrainingData>();
  const practice = data.practice;
  const blocked = !!data.busy || !!data.preparing;
  return (
    <>
      <Box fontSize={1.4} bold mb={0.5}>Что хотите потренировать?</Box>
      <Box color="label" mb={2}>Выберите комплект, наденьте снаряжение и подготовьте цель. Повтор упражнения заменяет только вашу учебную цель.</Box>
      <Section title="1. Подготовка">
        <div className="AntagTraining__categories">
          {data.kits.map((kit) => <Button key={kit.id} icon="toolbox" disabled={blocked || !data.supply_ready} selected={data.last_kit === kit.id} onClick={() => act('kit', { id: kit.id })}>{kit.name}</Button>)}
          <Button icon="book" onClick={() => navigate('Моя роль')}>{data.heretic ? 'Путь и рецепты еретика' : 'Возможности роли'}</Button>
        </div>
        <Box color="label">Комплект перенесёт вас в подходящий сектор и положит вещи рядом; незагруженный дополнительный сектор он сначала загрузит. Для личного набора откройте «Снаряжение».</Box>
      </Section>
      <Section title="2. Упражнение">
        <Stack wrap>
          <Stack.Item><Button icon="bullseye" disabled={blocked || !data.practice_ready} onClick={() => act('practice', { id: 'combat' })}>Довести цель до крита</Button></Stack.Item>
          <Stack.Item><Button icon="heart-pulse" disabled={blocked || !data.practice_ready} onClick={() => act('practice', { id: 'medicine' })}>Вылечить пациента</Button></Stack.Item>
          <Stack.Item><Button icon="book-skull" disabled={blocked || !data.practice_ready || !data.heretic} onClick={() => act('practice', { id: 'hunt' })}>Первое подношение</Button></Stack.Item>
          {!!data.dance_lesson && <Stack.Item><Button icon="music" disabled={blocked || !data.practice_ready} onClick={() => act('practice', { id: 'dance' })}>Урок Пляски</Button></Stack.Item>}
          {!!data.spirit_lesson && <Stack.Item><Button icon="ghost" disabled={blocked || !data.practice_ready} onClick={() => act('practice', { id: 'spirit' })}>Урок Духа</Button></Stack.Item>}
        </Stack>
        <Box color="label" mt={1}>Человеческая цель стоит на месте. В разделе «Цели» есть бегущий человек, противники с ИИ и кнопки, которые сбивают цель с ног, обессиливают или сковывают.</Box>
      </Section>
      {!!practice && (
        <Section title={practice.complete ? 'Упражнение выполнено' : `Ваша цель: ${practice.target}`}>
          <Box mb={1.5} color={practice.complete ? 'good' : undefined}>{practice.hint}</Box>
          {!!practice.steps?.length && (
            <Stack vertical mb={1.5}>
              {practice.steps.map((step, index) => (
                <Stack.Item key={step.name}>
                  <Box color={step.done ? 'good' : step.current ? undefined : 'label'} bold={!!step.current}>
                    {step.done ? <Icon name="check" mr={0.5} /> : `${index + 1}. `}{step.name}
                  </Box>
                </Stack.Item>
              ))}
            </Stack>
          )}
          <div className="AntagTraining__damage">
            <div><Box color="label">Получено урона</Box><Box bold>{Math.round(practice.damage)}</Box></div>
            <div><Box color="label">Восстановлено</Box><Box bold>{Math.round(practice.healing)}</Box></div>
            <div><Box color="label">Последнее снижение HP</Box><Box bold>{Math.round(practice.last_damage)}</Box></div>
            <div><Box color="label">До крита</Box><Box bold>{practice.critical_seconds === null ? '—' : `${practice.critical_seconds.toFixed(1)} с`}</Box></div>
          </div>
          <Box color="label" mb={1}>Считаются изменения здоровья цели от всех источников. Лечение учитывается отдельно; время идёт с первого изменения HP. «Исцелить» в пульте завершает упражнение.</Box>
          <Button icon="rotate" disabled={blocked || !data.practice_ready} onClick={() => act('practice', { id: practice.id })}>Повторить упражнение</Button>
          <Button color="transparent" disabled={blocked} onClick={() => act('practice_stop')}>Завершить упражнение</Button>
        </Section>
      )}
      <Section title="Упражнения зоны">
        <Box mb={1}>{data.exercises.length ? `Здесь доступно упражнений: ${data.exercises.length}. Шаги, подсказки и лучший результат смотрите во вкладке «Упражнения».` : 'В этой зоне нет упражнений для вашей роли. Во вкладке «Упражнения» видно, где они есть.'}</Box>
        <Button icon="list-check" onClick={() => navigate('Упражнения')}>Открыть упражнения</Button>
      </Section>
      <Section title="Совместная тренировка">
        <Box mb={1}>Пригласите участника на дуэль с отсчётом и результатом. Условия и свои комплекты согласуйте перед вызовом.</Box>
        <Button icon="users" onClick={() => navigate('Участники')}>Выбрать соперника</Button>
        <Button icon="hammer" onClick={() => navigate('Мастерская')}>Строительство и оборудование</Button>
      </Section>
    </>
  );
};

const exerciseStatus = (exercise: Exercise) => {
  if (exercise.run && !exercise.run.ended) return { text: 'идёт', color: 'teal' };
  if (exercise.run?.ended) return exercise.run.success ? { text: 'выполнено', color: 'good' } : { text: 'не выполнено', color: 'bad' };
  if (exercise.best) return { text: `лучший ${exercise.best.score}`, color: 'good' };
  return null;
};

const TrainingExercises = ({ navigate }: { navigate: (tab: string) => void }) => {
  const { act, data } = useBackend<AntagTrainingData>();
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const blocked = !!data.busy || !!data.preparing;
  const { exercises } = data;
  const selected = exercises.find((exercise) => exercise.id === selectedId) || exercises.find((exercise) => exercise.run && !exercise.run.ended) || exercises[0];
  if (!selected) {
    const places = [...data.zones, ...data.sectors].filter((place) => (place.exercises_total ?? 0) > 0 || (place.practice ?? 0) > 0);
    return (
      <div className="AntagTraining__empty">
        <Icon name="list-check" className="AntagTraining__emptyIcon" />
        <Box bold mt={1}>Здесь нет упражнений для вашей роли</Box>
        <Box color="label" mt={0.5} mb={1.5}>{places.length ? 'Перейдите туда, где они есть:' : 'Для вашей роли упражнений пока нет. Тренируйтесь свободно во вкладках «Снаряжение» и «Цели».'}</Box>
        {places.map((place) => {
          const sector = data.sectors.includes(place as Sector);
          return (
            <Button key={place.id} icon={sectorIcons[place.id] || 'layer-group'} disabled={!!data.busy || (sector && !!data.preparing)} onClick={() => (sector ? act('sector_enter', { id: place.id }) : act('move', { zone: place.id }))}>
              {place.exercises_total ? `${place.name} · ${place.exercises_done ?? 0}/${place.exercises_total}` : `${place.name} · практика`}
            </Button>
          );
        })}
        <Box mt={1.5}><Button color="transparent" icon="map" onClick={() => navigate('Зоны')}>Все зоны</Button></Box>
      </div>
    );
  }
  return (
    <div className="AntagTraining__split">
      <div className="AntagTraining__list">
        {exercises.map((exercise) => {
          const status = exerciseStatus(exercise);
          return (
            <div key={exercise.id} className={`AntagTraining__row${exercise.id === selected.id ? ' AntagTraining__row--selected' : ''}`} onClick={() => setSelectedId(exercise.id)}>
              <Icon className="AntagTraining__rowIcon" name={exercise.practice ? 'user-graduate' : 'list-check'} color="label" />
              <span className="AntagTraining__rowName">{exercise.name}</span>
              {!!status && <Box as="span" className="AntagTraining__progress" color={status.color}>{status.text}</Box>}
              <DifficultyMarks level={exercise.difficulty} />
            </div>
          );
        })}
      </div>
      <TrainingExercise exercise={selected} blocked={blocked} />
    </div>
  );
};

const TrainingExercise = ({ exercise, blocked }: { exercise: Exercise; blocked: boolean }) => {
  const { act, data } = useBackend<AntagTrainingData>();
  const { run, best } = exercise;
  const active = !!run && !run.ended;
  const practice = !!exercise.practice;
  const start = () => (practice ? act('practice', { id: exercise.id }) : act('exercise_start', { id: exercise.id }));
  return (
    <div className={`AntagTraining__exercise${active ? ' AntagTraining__exercise--active' : ''}`}>
      <Box bold fontSize={1.3}>{exercise.name}</Box>
      <Box color="label" mt={0.25}>{exercise.zone} · сложность {exercise.difficulty} из 3{practice ? ' · практика роли' : ''}</Box>
      <Box mt={1}>{exercise.desc}</Box>
      <Box mt={1.5} mb={1.5} className="AntagTraining__steps">
        {exercise.steps.map((step, index) => (
          <div key={`${index}-${step.name}`}>
            <Box color={step.done ? 'good' : step.current ? undefined : 'label'} bold={!!step.current}>
              {step.done ? <Icon name="check" mr={0.5} /> : `${index + 1}. `}{step.name}
            </Box>
            {!!step.hint && <Box className="AntagTraining__exerciseHint">Подсказка: {step.hint}</Box>}
          </div>
        ))}
      </Box>
      {active && !practice && <Box mb={1}>Время: {run?.elapsed?.toFixed(1)} с · подсказок: {run?.hints}</Box>}
      {!!run?.result && <Box mb={1} color={run?.ended ? (run.success ? 'good' : 'bad') : undefined}>{run?.result}</Box>}
      <Box mb={1.5} color={best ? 'good' : 'label'}>
        {best ? `Лучший результат: ${best.score} баллов за ${best.time.toFixed(1)} с, подсказок: ${best.hints}` : practice ? 'Практика роли идёт без оценки.' : 'Лучшего результата пока нет.'}
      </Box>
      <Button className="AntagTraining__mainAction" icon={run ? 'rotate' : 'play'} disabled={blocked || (practice && !data.practice_ready)} onClick={start}>{run ? 'Начать заново' : 'Начать'}</Button>
      {active && !practice && <Button icon="lightbulb" disabled={blocked} onClick={() => act('exercise_hint')}>Подсказка</Button>}
      {!!run && <Button color="transparent" disabled={blocked} onClick={() => act(practice ? 'practice_stop' : 'exercise_stop')}>{active ? 'Прекратить' : 'Убрать итог'}</Button>}
      {!!exercise.score_rule && <Box color="label" mt={1.5}>{exercise.score_rule}</Box>}
    </div>
  );
};

const TrainingRecipes = () => {
  const { act, data } = useBackend<AntagTrainingData>();
  const [path, setPath] = useState(data.selected_path || data.paths[0]?.id || '');
  const [stage, setStage] = useState('1');
  const [search, setSearch] = useState('');
  const blocked = !!data.busy || !!data.preparing || !data.supply_ready;
  const recipes = data.recipes.filter((recipe) => `${recipe.name} ${recipe.ingredients}`.toLowerCase().includes(search.toLowerCase()));
  return (
    <>
      <Section title="Подготовить путь">
        <Stack wrap align="center">
          <Stack.Item><Dropdown width={15} selected={data.selected_path || path} disabled={!!data.selected_path} options={data.paths.map((entry) => ({ value: entry.id, displayText: entry.name }))} onSelected={setPath} /></Stack.Item>
          <Stack.Item><Dropdown width={19} selected={stage} options={[{ value: '1', displayText: 'Начало: ступень 1' }, { value: '4', displayText: 'Основы: ступень 4' }, { value: '9', displayText: 'Полный путь: ступень 9' }]} onSelected={setStage} /></Stack.Item>
          <Stack.Item><Button disabled={blocked || !path} onClick={() => act('prepare_path', { id: data.selected_path || path, stage })}>Изучить до ступени</Button></Stack.Item>
        </Stack>
        <Box color="label" mt={1}>Сейчас: ступень {data.path_stage}. Подготовка выдаёт нужные знания и учебные души. Вознесение проводится отдельно. Для смены пути начните новым персонажем ниже.</Box>
      </Section>
      {!!data.resource && <Section title={`${data.resource.name}: ${data.resource.value} / ${data.resource.max}`}><Box>{data.resource.description}</Box></Section>}
      <Section title="Рецепты и готовые предметы">
        <Input fluid value={search} placeholder="Найти рецепт или компонент…" onInput={(_, value) => setSearch(value)} mb={1} />
        {!recipes.length && <Box color="label">Изучите путь или измените поиск. Здесь появятся доступные рецепты.</Box>}
        {recipes.map((recipe) => (
          <div key={recipe.id} className="AntagTraining__recipe">
            <Box bold>{recipe.name}</Box>
            <Box color="label" my={0.5}>{recipe.ingredients || 'Особые условия обряда'}</Box>
            {!!recipe.hint && <Box color="label" mb={0.5}>{recipe.hint}</Box>}
            <Button disabled={blocked || !recipe.components} onClick={() => act('recipe', { id: recipe.id, components: true })}>Компоненты</Button>
            <Button disabled={blocked || !recipe.result} onClick={() => act('recipe', { id: recipe.id, components: false })}>Готовый предмет</Button>
          </div>
        ))}
        <Box color="label" mt={1}>Предметы появятся рядом; тела для вознесения — рядом с вами в секторе, а из центра — в лаборатории. Температуру, положение цели и прочие условия обряда подготовьте самостоятельно.</Box>
      </Section>
    </>
  );
};

const ZoneProgress = ({ place }: { place: ExerciseProgress }) => {
  const total = place.exercises_total ?? 0;
  if (!total) return null;
  const done = place.exercises_done ?? 0;
  return (
    <div className="AntagTraining__zoneProgress">
      <Box color={done >= total ? 'good' : 'label'} mb={0.5}><Icon name="list-check" mr={0.5} />Упражнения: {done} из {total}</Box>
      <div className="AntagTraining__meter"><div className="AntagTraining__meterFill" style={{ width: `${(done / total) * 100}%` }} /></div>
    </div>
  );
};

const TrainingZones = () => {
  const { act, data } = useBackend<AntagTrainingData>();
  const ordered = ['laboratory', 'pve', 'hub', 'melee', 'range'];
  return (
    <>
      <Stack align="center" wrap mb={1.5}>
        <Stack.Item grow basis="300px" color="label">Выберите сектор для тренировки. Другие участники видят общие цели и снаряжение.</Stack.Item>
        <Stack.Item><Button.Confirm icon="rotate" disabled={!!data.busy || !!data.reset_vote} content="Сброс всего полигона" confirmContent="Запросить общий сброс?" onClick={() => act('reset_zone', { zone: 'all' })} /></Stack.Item>
      </Stack>
      <div className="AntagTraining__map">
        {ordered.map((id) => data.zones.find((zone) => zone.id === id)).filter(Boolean).map((zone) => (
          <div key={zone.id} className={`AntagTraining__sector AntagTraining__sector--${zone.id}${zone.current ? ' AntagTraining__sector--current' : ''}`}>
            <div className="AntagTraining__sectorHeading">
              <Icon name={sectorIcons[zone.id]} />
              <Box bold fontSize={1.2}>{zone.name}</Box>
              {!!zone.current && <span className="AntagTraining__here">Вы здесь</span>}
            </div>
            <Box color="label" mt={1} mb={1.5}>{zone.desc}</Box>
            <ZoneProgress place={zone} />
            <Stack align="center" wrap mt="auto">
              <Stack.Item grow color="label"><Icon name="users" /> {zone.members} · целей {zone.targets}</Stack.Item>
              <Stack.Item>
                {zone.id !== 'hub' && <Button.Confirm icon="rotate" color="transparent" disabled={!!data.busy || !!data.reset_vote} content="Сброс" confirmContent="Запросить сброс?" onClick={() => act('reset_zone', { zone: zone.id })} />}
                <Button icon="location-dot" selected={!!zone.current} disabled={!!data.busy} onClick={() => act('move', { zone: zone.id })}>Перейти</Button>
              </Stack.Item>
            </Stack>
          </div>
        ))}
      </div>
      {!!data.sectors.length && (
        <Section title="Дополнительные сектора" mt={1.5}>
          <Box color="label" mb={1.5}>Сектор грузится при первом входе и выгружается через {data.sector_idle_minutes} {pluralMinutes(data.sector_idle_minutes)} без участников.</Box>
          <Box color="label" mb={1.5}>Группа может забронировать сектор: занято {data.booking_used ?? 0} из {data.booking_max ?? 0}, остальные всегда открыты для всех.</Box>
          <div className="AntagTraining__map">
            {data.sectors.map((sector) => (
              <div key={sector.id} className={`AntagTraining__sector${sector.current ? ' AntagTraining__sector--current' : ''}`}>
                <div className="AntagTraining__sectorHeading">
                  <Icon name={sectorIcons[sector.id] || 'layer-group'} />
                  <Box bold fontSize={1.2}>{sector.name}</Box>
                  {!!sector.current && <span className="AntagTraining__here">Вы здесь</span>}
                </div>
                <Box color="label" mt={1} mb={1.5}>{sector.desc}</Box>
                <ZoneProgress place={sector} />
                <SectorBooking sectorId={sector.id} />
                <Stack align="center" wrap mt="auto">
                  <Stack.Item color="label"><Icon name="users" /> {sector.members}</Stack.Item>
                  <Stack.Item grow color={sectorStates[sector.state].color}>{sectorStates[sector.state].label}</Stack.Item>
                  <Stack.Item>
                    {sector.state === 'ready' && <Button.Confirm icon="rotate" color="transparent" disabled={!!data.busy || !!data.reset_vote || resetLocked(data, sector.id)} content="Сброс" confirmContent="Запросить сброс?" onClick={() => act('reset_zone', { zone: sector.id })} />}
                    <Button icon="location-dot" selected={!!sector.current} disabled={!!data.busy || !!data.preparing || sectorClosed(data, sector.id)} onClick={() => act('sector_enter', { id: sector.id })}>{sector.state === 'ready' ? 'Перейти' : 'Загрузить и перейти'}</Button>
                  </Stack.Item>
                </Stack>
              </div>
            ))}
          </div>
        </Section>
      )}
      <Box className="AntagTraining__hint"><Icon name="shield-halved" /> В центре и в вестибюле хаба вы защищены от урона. Сброс сектора требует согласия всех участников, а в занятом группой секторе его запускает лидер и решает только группа. Если голосует один человек, сброс начнётся сразу после подтверждения.</Box>
    </>
  );
};

const TrainingEquipment = () => {
  const { act, data } = useBackend<AntagTrainingData>();
  return <TrainingCatalog entries={data.equipment} blocked={!!data.busy || limitReached(data.supply_count, data.supply_limit, data.stand)} onCreate={(id) => act('equipment', { id })} />;
};

const categoryIcons: Record<string, string> = {
  'Ближний бой': 'hand-fist', 'Стрельба': 'crosshairs', 'Защита': 'shield-halved',
  'Инструменты': 'screwdriver-wrench', 'Медицина': 'briefcase-medical', 'Материалы': 'layer-group',
  'Химия': 'flask', 'Сборка машин': 'microchip', 'Обстановка': 'chair',
  'Преграды': 'door-open', 'Оборудование': 'gears', 'Медицина и химия': 'flask',
  'Контрмеры': 'cross', 'Инженерия': 'bolt', 'Атмос': 'wind',
  'Космос': 'user-astronaut', 'Робототехника': 'robot',
  'Скрытность': 'user-secret', 'Разное': 'box-open',
};

const TrainingWorkshop = () => {
  const { act, data } = useBackend<AntagTrainingData>();
  return (
    <>
      <div className="AntagTraining__workshopIntro">
        <Icon name="hammer" />
        <div>
          <Box bold fontSize={1.2}>Соберите свой испытательный стенд</Box>
          <Box color="label" mt={0.5}>Повернитесь к свободной клетке в секторе и установите объект перед собой. Инструменты, платы и материалы — во вкладке «Снаряжение».</Box>
        </div>
      </div>
      <div className={`AntagTraining__placement${data.build_error ? ' AntagTraining__placement--blocked' : ''}`}>
        <Icon name={data.build_error ? 'circle-info' : 'check'} />
        {data.build_error || 'Место перед вами свободно. Можно устанавливать.'}
      </div>
      <TrainingCatalog workshop entries={data.structures} blocked={!!data.busy || !!data.build_error || limitReached(data.structure_count, data.structure_limit, data.stand) || limitReached(data.supply_count, data.supply_limit, data.stand)} onCreate={(id) => act('build', { id })} />
      <Section title="Убрать после опыта" mt={1.5}>
        <Box color="label" mb={1}>Личная очистка убирает ваши объекты и оборудование. Вещи, переданные другим участникам, и занятые ими объекты сохраняются.</Box>
        <Button.Confirm icon="broom" disabled={!!data.busy || !!data.cleaning_personal} content={data.cleaning_personal ? 'Очистка…' : 'Очистить своё'} confirmContent="Удалить свои объекты?" onClick={() => act('clean_personal')} />
      </Section>
    </>
  );
};

const TrainingCatalog = (props: { entries: CatalogEntry[]; workshop?: boolean; blocked: boolean; onCreate: (id: string) => void }) => {
  const { data } = useBackend<AntagTrainingData>();
  const { entries, workshop, blocked, onCreate } = props;
  const [search, setSearch] = useState('');
  const [category, setCategory] = useState('Все');
  const categories = ['Все', ...new Set(entries.map((item) => item.category))];
  const items = entries.filter((item) => (category === 'Все' || item.category === category) && `${item.name} ${item.category} ${item.desc || ''}`.toLocaleLowerCase().includes(search.trim().toLocaleLowerCase()));
  return (
    <>
      <Section title={workshop ? 'Объекты для установки' : 'Снаряжение'} buttons={<Box color="label">{workshop ? `Установлено ${limitLabel(data.structure_count, data.structure_limit, data.stand)}` : `Выдано ${limitLabel(data.supply_count, data.supply_limit, data.stand)}`}</Box>}>
        <Input fluid placeholder={workshop ? 'Найти объект или занятие: операции, химия, ремонт…' : 'Найти оружие, инструмент или материал…'} value={search} onInput={(_, value) => setSearch(value)} />
        <div className="AntagTraining__categories">
          {categories.map((name) => <Button key={name} icon={categoryIcons[name]} selected={category === name} onClick={() => setCategory(name)}>{name}</Button>)}
        </div>
        <Stack justify="space-between" wrap mt={0.5}>
          <Stack.Item grow color="label">{workshop ? 'Общий лимит учитывает и предметы, и установленные объекты.' : 'Предмет появится на полу рядом с вами. Уборка освобождает лимит.'}</Stack.Item>
          <Stack.Item color="label">Найдено: {items.length}</Stack.Item>
        </Stack>
      </Section>
      <div className="AntagTraining__catalog">
        {items.map((item) => (
          <div key={item.id} className="AntagTraining__equipment">
            <Icon className="AntagTraining__catalogIcon" name={categoryIcons[item.category] || 'cube'} />
            <div className="AntagTraining__catalogText"><Box bold>{item.name}</Box><Box color="label" mt={0.5}>{item.desc || item.category}</Box></div>
            <Button icon={workshop ? 'hammer' : 'plus'} disabled={blocked} onClick={() => onCreate(item.id)}>{workshop ? 'Установить' : 'Выдать'}</Button>
          </div>
        ))}
      </div>
      {!items.length && <NoticeBox>Ничего не найдено. Измените запрос или выберите другую категорию.</NoticeBox>}
    </>
  );
};

const TrainingTargets = () => {
  const { act, data } = useBackend<AntagTrainingData>();
  const [zone, setZone] = useState('pve');
  const [template, setTemplate] = useState('human');
  const [active, setActive] = useState(false);
  const canUseAi = !['human', 'runner', 'armored', 'corpse'].includes(template);
  return (
    <>
      <Section title="Создать цель" buttons={<Box color="label">{limitLabel(data.targets.length, data.target_limit, data.stand)}</Box>}>
        <Stack wrap align="end">
          <Stack.Item><Box color="label" mb={0.5}>Противник</Box><Dropdown width={19} selected={template} options={data.creatures.map((item) => ({ value: item.id, displayText: item.name }))} onSelected={setTemplate} /></Stack.Item>
          <Stack.Item><Box color="label" mb={0.5}>Сектор</Box><Dropdown width={17} selected={zone} options={data.zones.filter((item) => item.id !== 'hub' && !sectorClosed(data, item.id)).map((item) => ({ value: item.id, displayText: item.name }))} onSelected={setZone} /></Stack.Item>
          <Stack.Item><Button.Checkbox disabled={!canUseAi} checked={canUseAi && active} onClick={() => setActive(!active)}>Активный ИИ</Button.Checkbox></Stack.Item>
          <Stack.Item><Button icon="plus" disabled={!!data.busy || limitReached(data.targets.length, data.target_limit, data.stand)} onClick={() => act('spawn', { id: template, zone, active: canUseAi && active })}>Создать</Button></Stack.Item>
        </Stack>
        <Box mt={1} color="label">Человек стоит на месте: подходит для ритуалов, оружия, выносливости и медицины. Бегущий человек ходит челноком поперёк сектора и замирает, пока его держат, сковали или сбили с ног. Для боя с человеком пригласите второго игрока в дуэль и выберите ему роль «Снаряжение и бой».</Box>
        <NoticeBox mt={1}>Животные и оперативники с ИИ не получают урон выносливости. На них нельзя оценить истощение души Духа и давление отражений Луны; используйте человеческую цель.</NoticeBox>
      </Section>
      <Box className="AntagTraining__targetHint"><Icon name="briefcase-medical" /> Для медицинской практики создайте человека, задайте повреждения и лечите обычными средствами. Повторное применение добавляет урон; «Исцелить» восстанавливает цель. Пациента можно перетащить на стол из мастерской.</Box>
      <div className="AntagTraining__catalog">
        {data.targets.map((target) => (
          <div key={target.id} className="AntagTraining__target">
            <Stack justify="space-between"><Stack.Item bold>{target.name}</Stack.Item><Stack.Item color="label">{target.zone}</Stack.Item></Stack>
            <Box color="label" mt={0.5}>Создатель: {target.owner}</Box>
            {!target.living && <Box mt={1}><ProgressBar value={healthFraction(target.health, target.max_health)} color="average">{`Прочность ${Math.round(target.health)} / ${target.max_health}`}</ProgressBar></Box>}
            {!!target.living && (
              <>
                <Box mt={1}><ProgressBar value={healthFraction(target.health, target.max_health)} color={target.dead ? 'bad' : 'average'}>{target.dead ? 'Мертва' : `Здоровье ${Math.round(target.health)} / ${target.max_health}`}</ProgressBar></Box>
                <div className="AntagTraining__damage">
                  {[['Физический', target.brute], ['Ожоги', target.burn], ['Токсины', target.toxin], ['Кислород', target.oxygen]].map(([name, value]) => <div key={name}><Box color="label">{name}</Box><Box bold>{Math.round(Number(value))}</Box></div>)}
                </div>
                <Box mt={1} color="label">{target.human ? `Урон выносливости: ${Math.round(target.stamina ?? 0)}` : 'Урон выносливости не действует'}</Box>
              </>
            )}
            {!!target.human && !target.dead && <Box mt={0.5} color={target.states?.length ? 'average' : 'label'}>Состояние: {target.states?.length ? target.states.join(', ') : 'на ногах'}</Box>}
            {!!target.human && (
              <div className="AntagTraining__injuries">
                <Box color="label" mb={0.5}>Добавить повреждения</Box>
                {data.injuries.map((injury) => <Button key={injury.id} disabled={!!data.busy || !target.can_manage || !!target.dead} onClick={() => act('target_injure', { id: target.id, injury: injury.id })}>{injury.name}</Button>)}
                <Box color="label" mt={0.5} mb={0.5}>Обездвижить: захваты и обряды еретика берут сбитую с ног, обессиленную или скованную цель</Box>
                {(data.conditions || []).map((condition) => <Button key={condition.id} disabled={!!data.busy || !target.can_manage || !!target.dead} onClick={() => act('target_condition', { id: target.id, condition: condition.id })}>{condition.name}</Button>)}
              </div>
            )}
            <Box>
              {!!target.human && !!data.target_action && <Button icon="crosshairs" disabled={!!data.busy || !target.can_manage} onClick={() => act('target_hunt', { id: target.id })}>{data.target_action}</Button>}
              {!!target.living && <Button icon="heart" disabled={!!data.busy || !target.can_manage} onClick={() => act('target_heal', { id: target.id })}>Исцелить</Button>}
              <Button icon="trash" color="transparent" disabled={!!data.busy || !target.can_manage} tooltip="Удалить цель" onClick={() => act('target_delete', { id: target.id })} />
            </Box>
          </div>
        ))}
      </div>
      {!data.targets.length && <div className="AntagTraining__empty"><Icon name="crosshairs" className="AntagTraining__emptyIcon" /><Box bold mt={1}>Подготовьте первого противника</Box><Box color="label" mt={0.5}>Выберите тип цели и сектор выше. Для дуэли второй игрок входит через меню гостролей или капсулу в Гост-Кафе.</Box></div>}
    </>
  );
};

const TrainingRoute = ({ navigate }: { navigate: (tab: string) => void }) => {
  const { act, data } = useBackend<AntagTrainingData>();
  const route = data.route;
  if (!route) return null;
  const total = route.exercises_total ?? 0;
  const empty = !route.sectors.length && !route.scenarios.length && !route.presets.length && !total;
  return (
    <Section title="Где тренировать">
      {empty && <Box color="label">Своего сектора, сценариев и пресетов площадок у программы нет. Учебные цели - во вкладке «Цели», снаряжение - во вкладке «Снаряжение».</Box>}
      {!!route.sectors.length && (
        <Box mb={1}>
          <Box color="label" mb={0.5}>{route.sectors.length > 1 ? 'Сектора механик' : 'Сектор программы'}</Box>
          {route.sectors.map((sector) => (
            <Button key={sector.id} icon={sectorIcons[sector.id] || 'layer-group'} disabled={!!data.busy || !!data.preparing || sectorClosed(data, sector.id)} onClick={() => act('sector_enter', { id: sector.id })}>{sector.name}</Button>
          ))}
        </Box>
      )}
      {!!total && (
        <Box mb={1}>
          Упражнения программы: {route.exercises_done ?? 0} из {total}{' '}
          <Button icon="list-check" onClick={() => navigate('Упражнения')}>Упражнения</Button>
        </Box>
      )}
      {!!route.scenarios.length && (
        <Box mb={1}>
          <Box color="label" mb={0.5}>Сценарии со слотом программы</Box>
          {route.scenarios.map((scenario) => <Box key={scenario.id}>{scenario.name}{scenario.venue ? ` · ${scenario.venue}` : ''}</Box>)}
          <Button mt={0.5} icon="flag-checkered" onClick={() => navigate('Сценарий')}>К сценариям</Button>
        </Box>
      )}
      {!!route.presets.length && (
        <Box>
          Пресеты площадок: {route.presets.map((preset) => preset.name).join(', ')}{' '}
          <Button icon="vector-square" onClick={() => navigate('Площадки')}>Площадки</Button>
        </Box>
      )}
    </Section>
  );
};

const TrainingRoleGoals = () => {
  const { data } = useBackend<AntagTrainingData>();
  const goals = data.role_objectives ?? [];
  if (!goals.length && !data.role_next) return null;
  return (
    <Section title="Цели роли">
      {goals.map((goal, index) => (
        <Box key={index} mb={0.5} color={goal.done ? 'good' : undefined}>
          <Icon name={goal.done ? 'square-check' : 'square'} mr={1} />
          {goal.text}
          {!!goal.done && <Box as="span" color="label"> · выполнено</Box>}
        </Box>
      ))}
      {!!data.role_next && <NoticeBox info mt={goals.length ? 1 : 0}>Что дальше: {data.role_next}</NoticeBox>}
    </Section>
  );
};

const TrainingProgram = ({ navigate }: { navigate: (tab: string) => void }) => {
  const { act, data } = useBackend<AntagTrainingData>();
  return (
    <>
      <TrainingRoleGoals />
      <TrainingRoute navigate={navigate} />
      {!!data.heretic && <TrainingRecipes />}
      <Section title="Восстановление после смерти">
        <Button.Checkbox checked={!!data.auto_recover} onClick={() => act('auto_recover')}>Автовосстановление через 3 секунды</Button.Checkbox>
        <Box color="label" mt={1}>Погибший встаёт в вестибюле хаба, ИИ - в своём ядре: пульт ядро не переносит. Отключите для испытаний с телом погибшего участника. Ручное восстановление и выход доступны даже после смерти.</Box>
      </Section>
      {!!data.roles?.length && (
        <Section title={`Должность: ${roleName(data.roles, data.role || 'default')}`}>
          {!data.role_applies && <NoticeBox>Эта программа не использует должность. Она применится, когда вы перейдёте на свободную тренировку или антагониста экипажа.</NoticeBox>}
          <Box color="label" mb={1}>Смена должности пересоберёт персонажа, как кнопка «Начать новым персонажем»: снаряжение, ID с доступом и импланты должности. Станция об этом не знает, гарнитура отдела работает только между участниками полигона.</Box>
          <RolePicker roles={data.roles} selected={data.role || 'default'} allowed={data.program_allowed_roles} disabled={!!data.busy} onSelect={(id) => act('set_role', { role: id })} />
        </Section>
      )}
      <Section title="Возможности роли">
        <div className="AntagTraining__catalog">
          {data.options.map((option) => <Button key={option} fluid disabled={!!data.busy} tooltip={data.option_hints?.[option]} onClick={() => act('program_option', { option })}>{option}</Button>)}
        </div>
        {!data.options.length && <Box>Свободная тренировка: снаряжение, бой, строительство и медицина. Для способностей антагонистов выберите учебную роль ниже.</Box>}
      </Section>
      <Section title="Убрать свои объекты">
        <Box mb={1.5} color="label">Удалит ваши выданные предметы, цели и созданные объекты. Предметы в руках и инвентаре других участников сохранятся. Обстановка сектора и ваш персонаж останутся.</Box>
        <Button.Confirm icon="broom" disabled={!!data.busy || !!data.cleaning_personal} content={data.cleaning_personal ? 'Очистка…' : 'Очистить своё'} confirmContent="Удалить свои объекты?" onClick={() => act('clean_personal')} />
      </Section>
      <Section title="Начать новым персонажем">
        <Box mb={1.5} color="label">Сбросит вашу роль, тело и инвентарь. Остальные участники и обстановка сохранятся.</Box>
        {groupByCategory(data.programs).map(([category, programs]) => (
          <Box key={category} mb={1.5}>
            <Box bold color="label" mb={0.5}>{category}</Box>
            {programs.map((program) => (
              <Box key={program.id} mb={1}>
                <Button.Confirm fluid icon={program.icon || 'rotate'} iconColor={program.color || undefined} disabled={!!data.busy} tooltip={program.desc} content={program.name} confirmContent="Сбросить своего персонажа?" onClick={() => act('restart', { program: program.id })} />
              </Box>
            ))}
          </Box>
        ))}
      </Section>
    </>
  );
};

const TrainingMembers = () => {
  const { act, data } = useBackend<AntagTrainingData>();
  const [lethal, setLethal] = useState(false);
  return (
    <>
      {!!data.last_duel_result && <NoticeBox>{data.last_duel_result}</NoticeBox>}
      <TrainingSquads members={data.members} />
      <Section title="Дуэль">
        <Button.Checkbox checked={lethal} onClick={() => setLethal(!lethal)}>До смерти (по умолчанию — до крита)</Button.Checkbox>
        <Box color="label" mt={1}>Одна дуэль на арене ближнего боя. При старте восстановится здоровье; вещи, ресурсы и перезарядки сохраняются. Дождитесь команды «Бой». Восстановление, выход и изменение подготовки через пульт завершат попытку.</Box>
      </Section>
      <Section title="Общая тренировка">
        <Box>Все входят через гостроль «Тренировочный полигон» или капсулу в Гост-Кафе и используют общие секторы.</Box>
        <Box color="label" mt={1}>Роль, здоровье и автовосстановление каждый настраивает для себя. Общий сброс требует единогласия; любой участник может отменить его. После выхода очищаются оставленные игроком объекты. Предметы у других участников сохраняются. После последнего выхода очищается весь полигон. С концом раунда все сеансы закрываются.</Box>
      </Section>
      <Box color="label" mb={1.5}>Перед боем договоритесь об условиях. Для проверки атак еретика по экипажу соперник выбирает «Снаряжение и бой»: иммунитеты ролей сохраняются.</Box>
      <div className="AntagTraining__catalog">
        {data.members.map((member) => (
          <div key={member.id} className={`AntagTraining__member${member.self ? ' AntagTraining__member--self' : ''}`}>
            <Stack align="center" justify="space-between"><Stack.Item bold>{member.name}{member.self ? ' (вы)' : ''}</Stack.Item><Stack.Item color={member.connected ? 'good' : 'label'}>{member.connected ? member.zone : 'Нет соединения'}</Stack.Item></Stack>
            <Box color="label" mt={0.5} mb={1}>{member.program}</Box>
            {member.health !== null && <ProgressBar value={healthFraction(member.health, member.max_health ?? 0)} color={member.dead ? 'bad' : 'good'}>{member.dead ? 'Мёртв' : `Здоровье ${Math.round(member.health)} / ${member.max_health}`}</ProgressBar>}
            <Box color="label" mt={1}>Поражений за сеанс: {member.defeats}</Box>
            {!member.self && <Button mt={1} icon="hand-fist" disabled={!!data.duel || !!data.busy || !!data.preparing || !data.duel_ready || !member.connected || !!member.dead} onClick={() => act('duel_request', { id: member.id, lethal })}>Вызвать на дуэль</Button>}
          </div>
        ))}
      </div>
      <Box className="AntagTraining__hint"><Icon name="heart" /> Каждый участник может восстановиться, сменить роль или выйти в любой момент.</Box>
    </>
  );
};

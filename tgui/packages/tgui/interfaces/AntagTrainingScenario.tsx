import { BooleanLike } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Dropdown, Icon, NoticeBox, Section, Stack } from '../components';
import { roleAllowed, TrainingRoleEntry } from './AntagTrainingRolePicker';
import { GoalKind, GoalSpec, ScenarioGoals } from './AntagTrainingScenarioGoals';
import { formatClock } from './AntagTrainingSquads';

export type ScenarioPhase = 'setup' | 'starting' | 'running' | 'summary';
export type ScenarioTemplate = {
  id: string;
  name: string;
  desc: string;
  sector: string | null;
  pad_preset?: string | null;
  pad_preset_name?: string | null;
  min_players: number;
  max_players: number;
  minutes: number;
  sides: string[];
};
export type ScenarioOccupant = { id: string; name: string; self: BooleanLike; out: BooleanLike };
export type ScenarioSlot = {
  id: string;
  side: string;
  label: string;
  role: string;
  role_name: string | null;
  program: string | null;
  program_name: string;
  count: number;
  required: BooleanLike;
  occupants: ScenarioOccupant[];
};
export type ScenarioObjective = { name: string; side: string; side_name: string; done: BooleanLike; progress: string | null };
export type ScenarioSummary = {
  winner: string | null;
  winner_name: string | null;
  reason: string;
  time: number;
  objectives: ScenarioObjective[];
  eliminated: string[];
};
export type ScenarioEntry = {
  id: string;
  name: string;
  desc: string;
  phase: ScenarioPhase;
  sector: string;
  sector_id: string;
  venue_kind?: 'sector' | 'pad';
  booked: BooleanLike;
  leader: BooleanLike;
  free_play: BooleanLike;
  min_players: number;
  max_players: number;
  time_limit: number;
  elapsed: number;
  remaining: number | null;
  sides: { id: string; name: string }[];
  slots: ScenarioSlot[];
  members: { id: string; name: string; slot: string | null }[];
  my_slot: string | null;
  objectives: ScenarioObjective[];
  /** Своя сборка: цели листа собирает лидер. */
  objectives_editable?: BooleanLike;
  objective_specs?: GoalSpec[];
  objective_library?: GoalKind[] | null;
  start_problem: string | null;
  summary: ScenarioSummary | null;
  runs: number;
};
type ProgramChoice = { id: string; name: string; allowed_roles?: number };
export type ScenarioData = {
  scenario_templates?: ScenarioTemplate[];
  scenario?: ScenarioEntry | null;
};
/** Что окно сценария читает из общих данных пульта. */
type ScenarioView = ScenarioData & {
  squad?: string | null;
  squad_leader?: BooleanLike;
  sectors?: { id: string; name: string }[];
  pads?: { id: string; name: string; owner: string | null; mine: BooleanLike }[];
  roles?: TrainingRoleEntry[];
  programs?: ProgramChoice[];
};

const FREE_PROGRAM = '/datum/antag_training_program/free';
const sideColors = ['red', 'blue', 'green', 'yellow', 'purple', 'orange'];

export const sideColor = (scenario: ScenarioEntry, sideId: string) => sideColors[Math.max(0, scenario.sides.findIndex((side) => side.id === sideId)) % sideColors.length];

/** Полоска над вкладками: идущая партия видна с любой вкладки пульта. */
export const ScenarioBanner = () => {
  const { data } = useBackend<ScenarioView>();
  const scenario = data.scenario;
  if (!scenario || scenario.phase !== 'running') return null;
  const done = scenario.objectives.filter((objective) => objective.done).length;
  return (
    <div className="AntagTraining__vote">
      <Icon name="flag-checkered" mr={0.5} />
      <b>Сценарий «{scenario.name}»</b> · {scenario.remaining === null ? `идёт ${formatClock(scenario.elapsed)}` : `осталось ${formatClock(scenario.remaining)}`}
      {scenario.objectives.length > 0 && ` · целей выполнено ${done} из ${scenario.objectives.length}`}
    </div>
  );
};

export const TrainingScenario = () => {
  const { data } = useBackend<ScenarioView>();
  const scenario = data.scenario;
  if (!data.squad) {
    return (
      <>
        <NoticeBox>Сценарии играет группа. Соберите её или войдите в чужую во вкладке «Участники».</NoticeBox>
        <ScenarioCatalog />
      </>
    );
  }
  if (!scenario) return <ScenarioCatalog />;
  return (
    <>
      <ScenarioHeader scenario={scenario} />
      {scenario.phase === 'starting' && <NoticeBox>{scenario.venue_kind === 'pad' ? 'Площадка загружается' : 'Сектор сбрасывается'}, тела собираются по слотам. Подождите несколько секунд.</NoticeBox>}
      {scenario.phase === 'running' && <ScenarioLive scenario={scenario} />}
      {scenario.phase === 'summary' && <ScenarioResult scenario={scenario} />}
      {(scenario.phase === 'setup' || scenario.phase === 'summary') && !!scenario.objectives_editable && <ScenarioGoals scenario={scenario} colorOf={(side) => sideColor(scenario, side)} />}
      {(scenario.phase === 'setup' || scenario.phase === 'summary') && <ScenarioSlots scenario={scenario} />}
    </>
  );
};

const ScenarioCatalog = () => {
  const { act, data } = useBackend<ScenarioView>();
  const leader = !!data.squad && !!data.squad_leader;
  const sectors = data.sectors || [];
  const places = [...sectors, ...(data.pads || []).filter((pad) => !pad.owner || pad.mine).map((pad) => ({ id: pad.id, name: pad.name }))];
  const [sector, setSector] = useState(sectors[0]?.id || '');
  const sectorName = (id: string | null) => sectors.find((entry) => entry.id === id)?.name || 'любой сектор';
  const placeLabel = (template: ScenarioTemplate) => {
    if (template.pad_preset) return `Площадка хаба, пресет «${template.pad_preset_name}»`;
    return template.sector ? `Сектор: ${sectorName(template.sector)}` : 'Сектор или площадка на выбор';
  };
  return (
    <>
      {data.squad && !leader && <NoticeBox>Сценарий выбирает лидер группы. Когда он выберет, здесь появятся слоты.</NoticeBox>}
      {(data.scenario_templates || []).map((template) => (
        <Section
          key={template.id}
          title={template.name}
          buttons={
            leader && (
              <Stack align="center">
                {!template.sector && !template.pad_preset && (
                  <Stack.Item><Dropdown width={14} selected={sector} options={places.map((entry) => ({ value: entry.id, displayText: entry.name }))} onSelected={setSector} /></Stack.Item>
                )}
                <Stack.Item>
                  <Button icon="flag-checkered" onClick={() => act('scenario_pick', template.sector || template.pad_preset ? { id: template.id } : { id: template.id, sector })}>
                    {template.sector || template.pad_preset ? 'Выбрать' : 'Пустой лист'}
                  </Button>
                </Stack.Item>
              </Stack>
            )
          }>
          <Box>{template.desc}</Box>
          <Box color="label" mt={0.5}>
            {placeLabel(template)} · игроков {template.min_players}–{template.max_players}
            {template.minutes > 0 ? ` · ${template.minutes} мин` : ' · без ограничения времени'}
            {template.sides.length > 0 && (template.sector || template.pad_preset) ? ` · ${template.sides.join(' против ')}` : ''}
          </Box>
        </Section>
      ))}
    </>
  );
};

const ScenarioHeader = ({ scenario }: { scenario: ScenarioEntry }) => {
  const { act } = useBackend<ScenarioView>();
  return (
    <Section
      title={`Сценарий «${scenario.name}»`}
      buttons={
        !!scenario.leader && scenario.phase === 'setup' && (
          <Button.Confirm icon="xmark" color="transparent" content="Снять сценарий" confirmContent="Снять сценарий?" onClick={() => act('scenario_cancel')} />
        )
      }>
      <Box>{scenario.desc}</Box>
      <Box color="label" mt={0.5}>
        <Icon name={scenario.booked ? 'lock' : 'lock-open'} mr={0.5} />
        {scenario.venue_kind === 'pad' ? `Площадка «${scenario.sector}»: ${scenario.booked ? 'занята группой' : 'не занята'}` : `Сектор «${scenario.sector}»: ${scenario.booked ? 'занят группой' : 'не занят'}`}
        {!scenario.booked && !!scenario.leader && (
          <Button ml={1} icon="lock" onClick={() => act('scenario_book')}>{scenario.venue_kind === 'pad' ? 'Занять площадку' : 'Занять сектор'}</Button>
        )}
      </Box>
      {!!scenario.free_play && <Box color="label" mt={0.5}>Целей нет: партия идёт, пока лидер не подведёт итог.</Box>}
    </Section>
  );
};

const ScenarioLive = ({ scenario }: { scenario: ScenarioEntry }) => {
  const { act } = useBackend<ScenarioView>();
  return (
    <Section
      title={scenario.remaining === null ? `Партия идёт · ${formatClock(scenario.elapsed)}` : `Партия идёт · осталось ${formatClock(scenario.remaining)}`}
      buttons={!!scenario.leader && <Button.Confirm icon="flag" content="Подвести итог" confirmContent="Остановить партию без победителя?" onClick={() => act('scenario_end')} />}>
      <ScenarioObjectives objectives={scenario.objectives} />
      <Box color="label" mt={0.5}>Пока идёт партия, её участнику из пульта открыты только снаряжение и выход: кнопки программы, лечение, смена роли, упражнения, учебные цели и переходы пультом и платформами закрыты до итога. На место партии пускают только её участников, остальные из группы и выбывшие смотрят её на экранах трибуны.</Box>
      <Stack mt={1} wrap>
        {scenario.sides.map((side) => (
          <Stack.Item key={side.id} grow basis="200px">
            <Box bold color={sideColor(scenario, side.id)}>{side.name}</Box>
            {scenario.slots.filter((slot) => slot.side === side.id).flatMap((slot) => slot.occupants.map((occupant) => (
              <Box key={occupant.id} color={occupant.out ? 'label' : undefined}>
                {occupant.out ? <Icon name="skull" mr={0.5} /> : <Icon name="user" mr={0.5} />}
                {occupant.name} · {slot.label}{occupant.out ? ' · выбыл' : ''}
              </Box>
            )))}
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

const ScenarioObjectives = ({ objectives }: { objectives: ScenarioObjective[] }) => {
  if (!objectives.length) return <Box color="label">Целей нет.</Box>;
  return (
    <>
      {objectives.map((objective, index) => (
        <Box key={index} mb={0.5}>
          <Icon name={objective.done ? 'check' : 'circle'} color={objective.done ? 'good' : 'label'} mr={0.5} />
          {objective.name} <Box as="span" color="label">· {objective.side_name}{objective.progress ? ` · ${objective.progress}` : ''}</Box>
        </Box>
      ))}
    </>
  );
};

const ScenarioResult = ({ scenario }: { scenario: ScenarioEntry }) => {
  const { act } = useBackend<ScenarioView>();
  const summary = scenario.summary;
  return (
    <Section
      title={summary?.winner_name ? `Победа: ${summary.winner_name}` : 'Итог: без победителя'}
      buttons={
        !!scenario.leader && (
          <>
            <Button icon="rotate-right" disabled={!!scenario.start_problem} tooltip={scenario.start_problem || undefined} onClick={() => act('scenario_replay')}>Повтор</Button>
            <Button icon="right-left" onClick={() => act('scenario_swap')}>Сменить стороны</Button>
            <Button.Confirm icon="house" content="Завершить" confirmContent="Всех в вестибюль хаба с прежними ролями?" onClick={() => act('scenario_finish')} />
          </>
        )
      }>
      {summary && (
        <>
          <Box mb={1}>{summary.reason} Время партии: {formatClock(summary.time)}.</Box>
          <ScenarioObjectives objectives={summary.objectives} />
          <Box color="label" mt={1}>{summary.eliminated.length ? `Выбыли: ${summary.eliminated.join(', ')}.` : 'Никто не выбыл.'}</Box>
        </>
      )}
      {!scenario.leader && <Box color="label" mt={1}>Повтор, смену сторон или конец сценария выбирает лидер группы.</Box>}
    </Section>
  );
};

const ScenarioSlots = ({ scenario }: { scenario: ScenarioEntry }) => {
  const { act, data } = useBackend<ScenarioView>();
  const leader = !!scenario.leader;
  const roles = data.roles || [];
  const programs = data.programs || [];
  return (
    <Section
      title="Слоты"
      buttons={
        leader && scenario.phase === 'setup' && (
          <Button icon="play" color="good" disabled={!!scenario.start_problem} tooltip={scenario.start_problem || undefined} onClick={() => act('scenario_start')}>Старт</Button>
        )
      }>
      {!!scenario.start_problem && <Box color="average" mb={1}>{scenario.start_problem}</Box>}
      {!scenario.slots.length && <Box color="label" mb={1}>Слотов пока нет.{leader ? ' Добавьте их ниже.' : ' Их добавляет лидер.'}</Box>}
      {scenario.sides.filter((side) => leader || scenario.slots.some((slot) => slot.side === side.id)).map((side) => (
        <Box key={side.id} mb={1}>
          <Box bold color={sideColor(scenario, side.id)} mb={0.5}>{side.name}</Box>
          {scenario.slots.filter((slot) => slot.side === side.id).map((slot) => (
            <ScenarioSlotRow key={slot.id} scenario={scenario} slot={slot} roles={roles} programs={programs} />
          ))}
        </Box>
      ))}
      {leader && <ScenarioSlotAdd scenario={scenario} roles={roles} programs={programs} />}
    </Section>
  );
};

const ScenarioSlotRow = (props: { scenario: ScenarioEntry; slot: ScenarioSlot; roles: TrainingRoleEntry[]; programs: ProgramChoice[] }) => {
  const { act } = useBackend<ScenarioView>();
  const { scenario, slot, roles, programs } = props;
  const leader = !!scenario.leader;
  const mine = scenario.my_slot === slot.id;
  const free = slot.count - slot.occupants.length;
  const role = roles.find((entry) => entry.id === slot.role);
  const unassigned = scenario.members.filter((member) => member.slot !== slot.id);
  const edit = (field: string, value: unknown) => act('scenario_slot_edit', { slot: slot.id, field, value });
  return (
    <Box className="AntagTraining__slot" mb={0.5}>
      <Stack align="center" wrap>
        <Stack.Item grow basis="220px">
          <Box bold>{slot.required ? <Icon name="star" color="average" mr={0.5} /> : null}{slot.label}</Box>
          <Box color="label">{slot.role_name || 'Учебное тело'} · {slot.program_name} · мест {slot.occupants.length}/{slot.count}</Box>
          <Box>{slot.occupants.length ? slot.occupants.map((occupant) => (
            <Box as="span" key={occupant.id} mr={1}>
              {occupant.name}
              {leader && <Button icon="xmark" color="transparent" tooltip="Убрать из слота" onClick={() => act('scenario_assign', { slot: '', member: occupant.id })} />}
            </Box>
          )) : <Box as="span" color="label">свободно</Box>}
          </Box>
        </Stack.Item>
        <Stack.Item>
          {mine ? (
            <Button icon="right-from-bracket" color="transparent" onClick={() => act('scenario_leave')}>Выйти из слота</Button>
          ) : (
            <Button icon="right-to-bracket" disabled={free < 1} onClick={() => act('scenario_take', { slot: slot.id })}>Занять</Button>
          )}
          {leader && free > 0 && unassigned.length > 0 && (
            <Dropdown width={12} selected="" displayText="Поставить…" options={unassigned.map((member) => ({ value: member.id, displayText: member.name }))} onSelected={(member) => act('scenario_assign', { slot: slot.id, member })} />
          )}
        </Stack.Item>
      </Stack>
      {leader && (
        <Stack align="center" mt={0.5} wrap>
          <Stack.Item><Dropdown width={13} selected={slot.side} options={scenario.sides.map((side) => ({ value: side.id, displayText: side.name }))} onSelected={(value) => edit('side', value)} /></Stack.Item>
          <Stack.Item><Dropdown width={15} selected={slot.role} options={roles.map((entry) => ({ value: entry.id, displayText: entry.name }))} onSelected={(value) => edit('role', value)} /></Stack.Item>
          <Stack.Item>
            <Dropdown width={17} selected={slot.program || FREE_PROGRAM} options={programs.filter((program) => roleAllowed(role, program.allowed_roles)).map((program) => ({ value: program.id, displayText: program.name }))} onSelected={(value) => edit('program', value)} />
          </Stack.Item>
          <Stack.Item>
            <Button icon="minus" disabled={slot.count <= 1} onClick={() => edit('count', slot.count - 1)} />
            <Button icon="plus" onClick={() => edit('count', slot.count + 1)} />
          </Stack.Item>
          <Stack.Item><Button.Checkbox checked={!!slot.required} onClick={() => edit('required', !slot.required)}>Обязательный</Button.Checkbox></Stack.Item>
          <Stack.Item><Button.Confirm icon="trash" color="transparent" content="Убрать слот" confirmContent="Убрать?" onClick={() => act('scenario_slot_remove', { slot: slot.id })} /></Stack.Item>
        </Stack>
      )}
    </Box>
  );
};

const ScenarioSlotAdd = (props: { scenario: ScenarioEntry; roles: TrainingRoleEntry[]; programs: ProgramChoice[] }) => {
  const { act } = useBackend<ScenarioView>();
  const { scenario, roles, programs } = props;
  const [side, setSide] = useState(scenario.sides[0]?.id || '');
  const [roleId, setRoleId] = useState('default');
  const [program, setProgram] = useState(FREE_PROGRAM);
  const role = roles.find((entry) => entry.id === roleId);
  const fits = programs.find((entry) => entry.id === program);
  return (
    <Box mt={1}>
      <Box bold mb={0.5}>Новый слот</Box>
      <Stack align="center" wrap>
        <Stack.Item><Dropdown width={13} selected={side} options={scenario.sides.map((entry) => ({ value: entry.id, displayText: entry.name }))} onSelected={setSide} /></Stack.Item>
        <Stack.Item><Dropdown width={15} selected={roleId} options={roles.map((entry) => ({ value: entry.id, displayText: entry.name }))} onSelected={setRoleId} /></Stack.Item>
        <Stack.Item>
          <Dropdown width={17} selected={program} options={programs.filter((entry) => roleAllowed(role, entry.allowed_roles)).map((entry) => ({ value: entry.id, displayText: entry.name }))} onSelected={setProgram} />
        </Stack.Item>
        <Stack.Item>
          <Button icon="plus" disabled={!!fits && !roleAllowed(role, fits.allowed_roles)} onClick={() => act('scenario_slot_add', { side, role: roleId, program })}>Добавить слот</Button>
        </Stack.Item>
      </Stack>
      <Box color="label" mt={0.5}>Сочетать можно любые роли и программы, которые выдерживает тело: ИИ и киборг не берут программы только для людей.</Box>
    </Box>
  );
};

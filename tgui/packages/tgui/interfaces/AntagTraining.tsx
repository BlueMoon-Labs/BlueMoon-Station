import { BooleanLike } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Dropdown, Icon, Input, NoticeBox, ProgressBar, Section, Stack, Tabs } from '../components';
import { Window } from '../layouts';

type Choice = { id: string; name: string };
type Zone = Choice & { desc: string; current: BooleanLike; members: number; targets: number };
type Target = Choice & {
  health: number;
  max_health: number;
  dead: BooleanLike;
  human: BooleanLike;
  brute: number;
  burn: number;
  toxin: number;
  oxygen: number;
  zone: string;
  owner: string;
  can_manage: BooleanLike;
};

export type AntagTrainingData = {
  program: string;
  program_id: string;
  auto_recover: BooleanLike;
  health: number;
  max_health: number;
  target_limit: number;
  supply_count: number;
  supply_limit: number;
  busy: BooleanLike;
  cleaning_personal: BooleanLike;
  reset_vote: { zone: string; approved: number; total: number; remaining: number; voted: BooleanLike } | null;
  members: (Choice & {
    program: string;
    health: number;
    max_health: number;
    dead: BooleanLike;
    connected: BooleanLike;
    zone: string;
    defeats: number;
    self: BooleanLike;
  })[];
  zones: Zone[];
  equipment: (Choice & { category: string })[];
  creatures: Choice[];
  targets: Target[];
  programs: Choice[];
  options: string[];
};

const sectorIcons: Record<string, string> = {
  hub: 'shield-halved', melee: 'hand-fist', range: 'bullseye',
  pve: 'paw', laboratory: 'flask',
};
const tabs = [
  { name: 'Зоны', icon: 'map' },
  { name: 'Снаряжение', icon: 'toolbox' },
  { name: 'Цели', icon: 'crosshairs' },
  { name: 'Моя роль', icon: 'user-gear' },
  { name: 'Участники', icon: 'users' },
];
const healthFraction = (health: number, maximum: number) => health / Math.max(1, maximum);

export const AntagTraining = () => {
  const { act, data } = useBackend<AntagTrainingData>();
  const [tab, setTab] = useState('Зоны');
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
              <Box color="label" textAlign="right" mt={0.5}>Вход через гостроль</Box>
            </Stack.Item>
          </Stack>
          <Stack align="center" mt={1.5} wrap>
            <Stack.Item grow basis="180px">
              <ProgressBar value={healthFraction(data.health, data.max_health)} color={data.health > 0 ? 'good' : 'bad'}>
                Здоровье {Math.round(data.health)} / {data.max_health}
              </ProgressBar>
            </Stack.Item>
            <Stack.Item><Button icon="heart" onClick={() => act('heal')}>Восстановиться</Button></Stack.Item>
            <Stack.Item><Button icon="house" disabled={!!data.busy} onClick={() => act('move', { zone: 'hub' })}>В центр</Button></Stack.Item>
            <Stack.Item><Button.Confirm icon="sign-out-alt" color="transparent" content="Выйти" confirmContent="Выйти в призрака?" onClick={() => act('exit')} /></Stack.Item>
          </Stack>
        </div>
        {!!data.reset_vote && (
          <div className="AntagTraining__vote">
          <Box bold>Сброс: {data.reset_vote.zone}</Box>
          <Box mt={0.5} mb={0.5}>Согласны {data.reset_vote.approved} из {data.reset_vote.total} · осталось {data.reset_vote.remaining} с. Обстановка будет очищена, участники вернутся в центр. Персонажи и их инвентарь сохранятся.</Box>
          <Button icon="check" disabled={!!data.reset_vote.voted} onClick={() => act('reset_approve')}>{data.reset_vote.voted ? 'Вы согласились' : 'Согласиться'}</Button>
          <Button icon="xmark" color="transparent" onClick={() => act('reset_cancel')}>Отменить сброс</Button>
          </div>
        )}
        <Tabs className="AntagTraining__tabs">
          {tabs.map(({ name, icon }) => (
            <Tabs.Tab key={name} selected={tab === name} onClick={() => setTab(name)} icon={icon}>{name}</Tabs.Tab>
          ))}
        </Tabs>
        <div className="AntagTraining__body">
          {!!data.busy && <NoticeBox>Сектор восстанавливается. Подождите завершения работ.</NoticeBox>}
          {tab === 'Зоны' && <TrainingZones />}
          {tab === 'Снаряжение' && <TrainingEquipment />}
          {tab === 'Цели' && <TrainingTargets />}
          {tab === 'Моя роль' && <TrainingProgram />}
          {tab === 'Участники' && <TrainingMembers />}
        </div>
      </Window.Content>
    </Window>
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
      <Box className="AntagTraining__hint"><Icon name="shield-halved" /> В центре вы защищены от урона. Сброс сектора требует согласия всех участников. Если вы один, он начнётся сразу после подтверждения.</Box>
    </>
  );
};

const TrainingEquipment = () => {
  const { act, data } = useBackend<AntagTrainingData>();
  const [search, setSearch] = useState('');
  const [category, setCategory] = useState('Все');
  const categories = ['Все', ...new Set(data.equipment.map((item) => item.category))];
  const items = data.equipment.filter((item) => (category === 'Все' || item.category === category) && item.name.toLocaleLowerCase().includes(search.trim().toLocaleLowerCase()));
  return (
    <>
      <Section title="Снаряжение" buttons={<Box color="label">Выдано {data.supply_count} / {data.supply_limit}</Box>}>
        <Input fluid placeholder="Найти оружие, инструмент или материал…" value={search} onInput={(_, value) => setSearch(value)} />
        <Box mt={1}>
          {categories.map((name) => <Button key={name} mb={0.5} selected={category === name} onClick={() => setCategory(name)}>{name}</Button>)}
        </Box>
        <Box color="label" mt={0.5}>Предмет появится на полу рядом с вами. Удаление предметов и сброс сектора освобождают лимит.</Box>
      </Section>
      <div className="AntagTraining__catalog">
        {items.map((item) => (
          <div key={item.id} className="AntagTraining__equipment">
            <div><Box bold>{item.name}</Box><Box color="label" mt={0.5}>{item.category}</Box></div>
            <Button icon="plus" disabled={!!data.busy || data.supply_count >= data.supply_limit} onClick={() => act('equipment', { id: item.id })}>Выдать</Button>
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
  const canUseAi = !['human', 'armored', 'corpse'].includes(template);
  return (
    <>
      <Section title="Создать цель" buttons={<Box color="label">{data.targets.length} / {data.target_limit}</Box>}>
        <Stack wrap align="end">
          <Stack.Item><Box color="label" mb={0.5}>Противник</Box><Dropdown width={19} selected={template} options={data.creatures.map((item) => ({ value: item.id, displayText: item.name }))} onSelected={setTemplate} /></Stack.Item>
          <Stack.Item><Box color="label" mb={0.5}>Сектор</Box><Dropdown width={17} selected={zone} options={data.zones.filter((item) => item.id !== 'hub').map((item) => ({ value: item.id, displayText: item.name }))} onSelected={setZone} /></Stack.Item>
          <Stack.Item><Button.Checkbox disabled={!canUseAi} checked={canUseAi && active} onClick={() => setActive(!active)}>Активный ИИ</Button.Checkbox></Stack.Item>
          <Stack.Item><Button icon="plus" disabled={!!data.busy || data.targets.length >= data.target_limit} onClick={() => act('spawn', { id: template, zone, active: canUseAi && active })}>Создать</Button></Stack.Item>
        </Stack>
        <Box mt={1} color="label">Человеческие цели неподвижны: подходят для ритуалов, оружия и медицины. Включённый ИИ действует у животных и оперативников.</Box>
      </Section>
      <div className="AntagTraining__catalog">
        {data.targets.map((target) => (
          <div key={target.id} className="AntagTraining__target">
            <Stack justify="space-between"><Stack.Item bold>{target.name}</Stack.Item><Stack.Item color="label">{target.zone}</Stack.Item></Stack>
            <Box color="label" mt={0.5}>Создатель: {target.owner}</Box>
            <Box mt={1}><ProgressBar value={healthFraction(target.health, target.max_health)} color={target.dead ? 'bad' : 'average'}>{target.dead ? 'Мертва' : `Здоровье ${Math.round(target.health)} / ${target.max_health}`}</ProgressBar></Box>
            <div className="AntagTraining__damage">
              {[['Физический', target.brute], ['Ожоги', target.burn], ['Токсины', target.toxin], ['Кислород', target.oxygen]].map(([name, value]) => <div key={name}><Box color="label">{name}</Box><Box bold>{Math.round(Number(value))}</Box></div>)}
            </div>
            <Box>
              {!!target.human && data.options.length > 0 && <Button icon="crosshairs" disabled={!!data.busy || !target.can_manage} onClick={() => act('target_hunt', { id: target.id })}>Цель охоты</Button>}
              <Button icon="heart" disabled={!!data.busy || !target.can_manage} onClick={() => act('target_heal', { id: target.id })}>Исцелить</Button>
              <Button icon="trash" color="transparent" disabled={!!data.busy || !target.can_manage} tooltip="Удалить цель" onClick={() => act('target_delete', { id: target.id })} />
            </Box>
          </div>
        ))}
      </div>
      {!data.targets.length && <div className="AntagTraining__empty"><Icon name="crosshairs" className="AntagTraining__emptyIcon" /><Box bold mt={1}>Подготовьте первого противника</Box><Box color="label" mt={0.5}>Выберите тип цели и сектор выше. Для дуэли второй игрок входит через ту же гостроль.</Box></div>}
    </>
  );
};

const TrainingProgram = () => {
  const { act, data } = useBackend<AntagTrainingData>();
  return (
    <>
      <Section title="Восстановление после смерти">
        <Button.Checkbox checked={!!data.auto_recover} onClick={() => act('auto_recover')}>Автовосстановление через 3 секунды</Button.Checkbox>
        <Box color="label" mt={1}>Отключите для испытаний с телом погибшего участника. Ручное восстановление и выход доступны даже после смерти.</Box>
      </Section>
      <Section title="Возможности роли">
        <div className="AntagTraining__catalog">
          {data.options.map((option) => <Button key={option} fluid disabled={!!data.busy} onClick={() => act('program_option', { option })}>{option}</Button>)}
        </div>
        {!data.options.length && <Box>Свободная тренировка: снаряжение, бой, строительство и медицина. Для способностей еретика выберите учебную роль ниже.</Box>}
      </Section>
      <Section title="Убрать свои объекты">
        <Box mb={1.5} color="label">Удалит ваши выданные предметы, цели и созданные объекты. Предметы в руках и инвентаре других участников сохранятся. Обстановка сектора и ваш персонаж останутся.</Box>
        <Button.Confirm icon="broom" disabled={!!data.busy || !!data.cleaning_personal} content={data.cleaning_personal ? 'Очистка…' : 'Очистить своё'} confirmContent="Удалить свои объекты?" onClick={() => act('clean_personal')} />
      </Section>
      <Section title="Начать новым персонажем">
        <Box mb={1.5} color="label">Сбросит вашу роль, тело и инвентарь. Остальные участники и обстановка сохранятся.</Box>
        {data.programs.map((program) => (
          <Box key={program.id} mb={1}>
            <Button.Confirm fluid icon="rotate" disabled={!!data.busy} content={program.name} confirmContent="Сбросить своего персонажа?" onClick={() => act('restart', { program: program.id })} />
          </Box>
        ))}
      </Section>
    </>
  );
};

const TrainingMembers = () => {
  const { data } = useBackend<AntagTrainingData>();
  return (
    <>
      <Section title="Общая тренировка">
        <Box>Все входят через гостроль «Тренировочный полигон» и используют общие секторы.</Box>
        <Box color="label" mt={1}>Роль, здоровье и автовосстановление каждый настраивает для себя. Общий сброс требует единогласия; любой участник может отменить его. После выхода очищаются оставленные игроком объекты. Предметы у других участников сохраняются. После последнего выхода очищается весь полигон.</Box>
      </Section>
      <Box color="label" mb={1.5}>Перед боем договоритесь об условиях. Для проверки атак еретика по экипажу соперник выбирает «Снаряжение и бой»: иммунитеты ролей сохраняются.</Box>
      <div className="AntagTraining__catalog">
        {data.members.map((member) => (
          <div key={member.id} className={`AntagTraining__member${member.self ? ' AntagTraining__member--self' : ''}`}>
            <Stack align="center" justify="space-between"><Stack.Item bold>{member.name}{member.self ? ' (вы)' : ''}</Stack.Item><Stack.Item color={member.connected ? 'good' : 'label'}>{member.connected ? member.zone : 'Нет соединения'}</Stack.Item></Stack>
            <Box color="label" mt={0.5} mb={1}>{member.program}</Box>
            <ProgressBar value={healthFraction(member.health, member.max_health)} color={member.dead ? 'bad' : 'good'}>{member.dead ? 'Мёртв' : `Здоровье ${Math.round(member.health)} / ${member.max_health}`}</ProgressBar>
            <Box color="label" mt={1}>Поражений за сеанс: {member.defeats}</Box>
          </div>
        ))}
      </div>
      <Box className="AntagTraining__hint"><Icon name="heart" /> Каждый участник может восстановиться, сменить роль или выйти в любой момент.</Box>
    </>
  );
};

import { BooleanLike } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Dropdown, Icon, Input, NoticeBox, ProgressBar, Section, Stack, Tabs } from '../components';
import { Window } from '../layouts';

type Choice = { id: string; name: string };
type CatalogEntry = Choice & { category: string; desc?: string | null };
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
  practice: { id: string; target: string; complete: BooleanLike; hint: string; damage: number; healing: number; last_damage: number; critical_seconds: number | null } | null;
  duel: { phase: string; first: string; second: string; lethal: BooleanLike; remaining: number; involved: BooleanLike; can_accept: BooleanLike } | null;
  last_duel_result: string | null;
  duel_ready: BooleanLike;
  program: string;
  program_id: string;
  auto_recover: BooleanLike;
  health: number;
  max_health: number;
  target_limit: number;
  supply_count: number;
  supply_limit: number;
  structure_count: number;
  structure_limit: number;
  build_error: string | null;
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
  equipment: CatalogEntry[];
  structures: CatalogEntry[];
  injuries: Choice[];
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
  { name: 'Начать', icon: 'play' },
  { name: 'Зоны', icon: 'map' },
  { name: 'Снаряжение', icon: 'toolbox' },
  { name: 'Мастерская', icon: 'hammer' },
  { name: 'Цели', icon: 'crosshairs' },
  { name: 'Моя роль', icon: 'user-gear' },
  { name: 'Участники', icon: 'users' },
];
const healthFraction = (health: number, maximum: number) => health / Math.max(1, maximum);

export const AntagTraining = () => {
  const { act, data } = useBackend<AntagTrainingData>();
  const [tab, setTab] = useState('Начать');
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
            <Stack.Item><Button icon="house" disabled={!!data.busy || !!data.preparing} onClick={() => act('move', { zone: 'hub' })}>В центр</Button></Stack.Item>
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
        {!!data.duel && <TrainingDuel />}
        <Tabs className="AntagTraining__tabs">
          {tabs.map(({ name, icon }) => (
            <Tabs.Tab key={name} selected={tab === name} onClick={() => setTab(name)} icon={icon}>{name}</Tabs.Tab>
          ))}
        </Tabs>
        <div className="AntagTraining__body">
          {!!data.busy && <NoticeBox>Сектор восстанавливается. Подождите завершения работ.</NoticeBox>}
          {!!data.preparing && <NoticeBox>Подготавливаем комплект. Восстановление и выход доступны.</NoticeBox>}
          {!!data.last_feedback && <NoticeBox>{data.last_feedback}</NoticeBox>}
          {tab === 'Начать' && <TrainingStart navigate={setTab} />}
          {tab === 'Зоны' && <TrainingZones />}
          {tab === 'Снаряжение' && <TrainingEquipment />}
          {tab === 'Мастерская' && <TrainingWorkshop />}
          {tab === 'Цели' && <TrainingTargets />}
          {tab === 'Моя роль' && <TrainingProgram />}
          {tab === 'Участники' && <TrainingMembers />}
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
          <Button icon="book" onClick={() => navigate('Моя роль')}>Путь и рецепты еретика</Button>
        </div>
        <Box color="label">Комплект перенесёт вас в подходящий сектор и положит вещи рядом. Для личного набора откройте «Снаряжение».</Box>
      </Section>
      <Section title="2. Упражнение">
        <Stack wrap>
          <Stack.Item><Button icon="bullseye" disabled={blocked || !data.practice_ready} onClick={() => act('practice', { id: 'combat' })}>Довести цель до крита</Button></Stack.Item>
          <Stack.Item><Button icon="heart-pulse" disabled={blocked || !data.practice_ready} onClick={() => act('practice', { id: 'medicine' })}>Вылечить пациента</Button></Stack.Item>
          <Stack.Item><Button icon="book-skull" disabled={blocked || !data.practice_ready || !data.options.length} onClick={() => act('practice', { id: 'hunt' })}>Первое подношение</Button></Stack.Item>
        </Stack>
        <Box color="label" mt={1}>Человеческая цель неподвижна. Для активного противника выберите тип и включите ИИ в разделе «Цели».</Box>
      </Section>
      {!!practice && (
        <Section title={practice.complete ? 'Упражнение выполнено' : `Ваша цель: ${practice.target}`}>
          <Box mb={1.5} color={practice.complete ? 'good' : undefined}>{practice.hint}</Box>
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
      <Section title="Совместная тренировка">
        <Box mb={1}>Пригласите участника на дуэль с отсчётом и результатом. Условия и свои комплекты согласуйте перед вызовом.</Box>
        <Button icon="users" onClick={() => navigate('Участники')}>Выбрать соперника</Button>
        <Button icon="hammer" onClick={() => navigate('Мастерская')}>Строительство и оборудование</Button>
      </Section>
    </>
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
        <Box color="label" mt={1}>Предметы появятся рядом; тела для вознесения — в лаборатории. Температуру, положение цели и прочие условия обряда подготовьте самостоятельно.</Box>
      </Section>
    </>
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
  return <TrainingCatalog entries={data.equipment} blocked={!!data.busy || data.supply_count >= data.supply_limit} onCreate={(id) => act('equipment', { id })} />;
};

const categoryIcons: Record<string, string> = {
  'Ближний бой': 'hand-fist', 'Стрельба': 'crosshairs', 'Защита': 'shield-halved',
  'Инструменты': 'screwdriver-wrench', 'Медицина': 'briefcase-medical', 'Материалы': 'layer-group',
  'Химия': 'flask', 'Сборка машин': 'microchip', 'Обстановка': 'chair',
  'Преграды': 'door-open', 'Оборудование': 'gears', 'Медицина и химия': 'flask',
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
      <TrainingCatalog workshop entries={data.structures} blocked={!!data.busy || !!data.build_error || data.structure_count >= data.structure_limit || data.supply_count >= data.supply_limit} onCreate={(id) => act('build', { id })} />
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
      <Section title={workshop ? 'Объекты для установки' : 'Снаряжение'} buttons={<Box color="label">{workshop ? `Установлено ${data.structure_count} / ${data.structure_limit}` : `Выдано ${data.supply_count} / ${data.supply_limit}`}</Box>}>
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
      <Box className="AntagTraining__targetHint"><Icon name="briefcase-medical" /> Для медицинской практики создайте человека, задайте повреждения и лечите обычными средствами. Повторное применение добавляет урон; «Исцелить» восстанавливает цель. Пациента можно перетащить на стол из мастерской.</Box>
      <div className="AntagTraining__catalog">
        {data.targets.map((target) => (
          <div key={target.id} className="AntagTraining__target">
            <Stack justify="space-between"><Stack.Item bold>{target.name}</Stack.Item><Stack.Item color="label">{target.zone}</Stack.Item></Stack>
            <Box color="label" mt={0.5}>Создатель: {target.owner}</Box>
            <Box mt={1}><ProgressBar value={healthFraction(target.health, target.max_health)} color={target.dead ? 'bad' : 'average'}>{target.dead ? 'Мертва' : `Здоровье ${Math.round(target.health)} / ${target.max_health}`}</ProgressBar></Box>
            <div className="AntagTraining__damage">
              {[['Физический', target.brute], ['Ожоги', target.burn], ['Токсины', target.toxin], ['Кислород', target.oxygen]].map(([name, value]) => <div key={name}><Box color="label">{name}</Box><Box bold>{Math.round(Number(value))}</Box></div>)}
            </div>
            {!!target.human && (
              <div className="AntagTraining__injuries">
                <Box color="label" mb={0.5}>Добавить повреждения</Box>
                {data.injuries.map((injury) => <Button key={injury.id} disabled={!!data.busy || !target.can_manage || !!target.dead} onClick={() => act('target_injure', { id: target.id, injury: injury.id })}>{injury.name}</Button>)}
              </div>
            )}
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
      {!!data.options.length && <TrainingRecipes />}
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
  const { act, data } = useBackend<AntagTrainingData>();
  const [lethal, setLethal] = useState(false);
  return (
    <>
      {!!data.last_duel_result && <NoticeBox>{data.last_duel_result}</NoticeBox>}
      <Section title="Дуэль">
        <Button.Checkbox checked={lethal} onClick={() => setLethal(!lethal)}>До смерти (по умолчанию — до крита)</Button.Checkbox>
        <Box color="label" mt={1}>Одна дуэль на арене ближнего боя. При старте восстановится здоровье; вещи, ресурсы и перезарядки сохраняются. Дождитесь команды «Бой». Восстановление, выход и изменение подготовки через пульт завершат попытку.</Box>
      </Section>
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
            {!member.self && <Button mt={1} icon="hand-fist" disabled={!!data.duel || !!data.busy || !!data.preparing || !data.duel_ready || !member.connected || !!member.dead} onClick={() => act('duel_request', { id: member.id, lethal })}>Вызвать на дуэль</Button>}
          </div>
        ))}
      </div>
      <Box className="AntagTraining__hint"><Icon name="heart" /> Каждый участник может восстановиться, сменить роль или выйти в любой момент.</Box>
    </>
  );
};

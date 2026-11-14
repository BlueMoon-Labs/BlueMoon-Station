import { BooleanLike } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Dropdown, Input, NoticeBox, Section, Stack } from '../components';
import { TrainingRoleEntry } from './AntagTrainingRolePicker';

export type StandSquad = { id: string; name: string; members: number; sector_id: string | null; sector: string | null; scenario?: string | null };
export type StandPad = { id: string; name: string; owner: string; preset: string };
export type StandMember = { id: string; name: string; role: string | null; program_id: string; self: BooleanLike };
export type StandData = {
  enabled: BooleanLike;
  full: BooleanLike;
  /** Во сколько раз стенд поднимает лимиты; 0 - лимитов нет. */
  limit_scale?: number;
  query: string | null;
  results: { path: string; name: string }[];
  more: BooleanLike;
  members: StandMember[];
  squads?: StandSquad[];
  pads?: StandPad[];
};

type Choice = { id: string; name: string };
type StandBackend = {
  stand?: StandData | null;
  roles?: TrainingRoleEntry[];
  programs: Choice[];
  zones: Choice[];
  sectors: Choice[];
  busy: BooleanLike;
};

export const STAND_QUERY_MIN = 3;

/** Лимит полигона с учётом стенда: стенд кодера и ментора его умножает, стенд админа снимает (null). */
export const standLimit = (limit: number, stand?: StandData | null) => {
  if (!stand?.enabled) {
    return limit;
  }
  const scale = stand.limit_scale ?? 0;
  return scale ? limit * scale : null;
};
export const limitLabel = (count: number, limit: number, stand?: StandData | null) => {
  const effective = standLimit(limit, stand);
  return effective === null ? `${count} · без лимита` : `${count} / ${effective}`;
};
export const limitReached = (count: number, limit: number, stand?: StandData | null) => {
  const effective = standLimit(limit, stand);
  return effective !== null && count >= effective;
};

export const StandToggle = () => {
  const { act, data } = useBackend<StandBackend>();
  if (!data.stand) {
    return null;
  }
  return (
    <Button.Checkbox
      checked={!!data.stand.enabled}
      color={data.stand.enabled ? 'average' : 'transparent'}
      tooltip="Для админов, кодеров и менторов: снимает ваши лимиты (кодерам и менторам удваивает), даёт спавн по пути, смену роли и программы любому участнику и сброс без голосования. Каждое действие пишется в лог администрации."
      onClick={() => act('stand_toggle')}>
      Режим стенда
    </Button.Checkbox>
  );
};

export const TrainingStand = () => {
  const { act, data } = useBackend<StandBackend>();
  const stand = data.stand;
  const [query, setQuery] = useState(stand?.query || '');
  if (!stand?.enabled) {
    return <NoticeBox>Режим стенда выключен. Включите его в шапке пульта.</NoticeBox>;
  }
  const search = () => act('stand_search', { query });
  const roleOptions = (data.roles || []).map((role) => ({ value: role.id, displayText: role.name }));
  const programOptions = data.programs.map((program) => ({ value: program.id, displayText: program.name }));
  const resetZones = [...data.zones.filter((zone) => zone.id !== 'hub'), ...data.sectors];
  return (
    <>
      <NoticeBox>
        {stand.full ? 'Лимиты целей, вещей и построек для вас сняты.' : 'Лимиты целей, вещей и построек для вас удвоены.'} Всё созданное стендом считается вашим: «Очистить своё» и закрытие полигона его убирают. Каждое действие стенда попадает в лог администрации.
      </NoticeBox>
      <Section title="Создать по пути">
        {!stand.full && <Box color="label" mb={1}>Опасное для станции скрыто: сингулярность и тесла, гравген, шаттлы и их части, бомбы, аномалии, ядерные устройства, суперматерия, консоли связи, тревоги, роботехники и законов ИИ, сами ИИ и киборги, оверминд блоба и ревенант; бюджет и карго, записи СБ и медотдела, телекоммуникации и сервер сообщений, исследования, телепорты, гост-спавнеры и аплинки, запасная карта капитана, хартия станции и платы этих консолей. Их создают только администраторы.</Box>}
        <Stack>
          <Stack.Item grow>
            <Input fluid value={query} placeholder="Часть пути, например gun/energy" onInput={(_, value) => setQuery(value)} onEnter={search} />
          </Stack.Item>
          <Stack.Item>
            <Button icon="magnifying-glass" disabled={query.trim().length < STAND_QUERY_MIN} onClick={search}>Найти</Button>
          </Stack.Item>
        </Stack>
        <Box color="label" mt={1} mb={1}>Предмет или существо появится на клетке перед вами, а если она занята - под вами. Только внутри полигона.</Box>
        {!!stand.query && stand.query.length < STAND_QUERY_MIN && <Box color="label">Введите хотя бы {STAND_QUERY_MIN} символа пути.</Box>}
        {!!stand.query && stand.query.length >= STAND_QUERY_MIN && !stand.results.length && <Box color="label">Ничего не нашлось.</Box>}
        {stand.results.map((result) => (
          <Stack key={result.path} align="center" mb={0.5}>
            <Stack.Item grow>
              <Box>{result.name}</Box>
              <Box color="label" fontSize={0.9}>{result.path}</Box>
            </Stack.Item>
            <Stack.Item>
              <Button icon="plus" disabled={!!data.busy} onClick={() => act('stand_spawn', { path: result.path })}>Создать</Button>
            </Stack.Item>
          </Stack>
        ))}
        {!!stand.more && <Box color="label" mt={1}>Показаны первые {stand.results.length}. Уточните запрос.</Box>}
      </Section>
      <Section title="Участники">
        {stand.members.map((member) => (
          <Stack key={member.id} align="center" wrap mb={1}>
            <Stack.Item basis="180px" bold>{member.name}{member.self ? ' (вы)' : ''}</Stack.Item>
            {!!roleOptions.length && (
              <Stack.Item>
                <Dropdown width={16} selected={member.role || 'default'} options={roleOptions} disabled={!!data.busy} onSelected={(role: string) => act('stand_role', { id: member.id, role })} />
              </Stack.Item>
            )}
            <Stack.Item>
              <Dropdown width={18} selected={member.program_id} options={programOptions} disabled={!!data.busy} onSelected={(program: string) => act('stand_program', { id: member.id, program })} />
            </Stack.Item>
          </Stack>
        ))}
        <Box color="label">Смена должности или программы пересобирает персонажа участника, как его собственная кнопка «Начать новым персонажем».</Box>
      </Section>
      {!!stand.squads?.length && (
        <Section title="Группы и бронь">
          {stand.squads.map((squad) => (
            <Stack key={squad.id} align="center" wrap mb={1}>
              <Stack.Item grow>
                <Box bold>{squad.name}</Box>
                <Box color="label">Участников: {squad.members} · {squad.sector ? `бронь: ${squad.sector}` : 'без брони'}{squad.scenario ? ` · сценарий «${squad.scenario}»` : ''}</Box>
              </Stack.Item>
              {!!squad.sector_id && (
                <Stack.Item>
                  <Button.Confirm icon="lock-open" disabled={!!data.busy} content="Снять бронь" confirmContent="Снять бронь группы?" onClick={() => act('stand_release', { kind: 'booking', id: squad.sector_id })} />
                </Stack.Item>
              )}
              {!!squad.scenario && (
                <Stack.Item>
                  <Button.Confirm icon="flag-checkered" disabled={!!data.busy} content="Завершить сценарий" confirmContent="Закрыть сценарий группы?" onClick={() => act('stand_release', { kind: 'scenario', id: squad.id })} />
                </Stack.Item>
              )}
              <Stack.Item>
                <Button.Confirm icon="users-slash" color="bad" disabled={!!data.busy} content="Распустить" confirmContent="Распустить группу?" onClick={() => act('stand_release', { kind: 'squad', id: squad.id })} />
              </Stack.Item>
            </Stack>
          ))}
          <Box color="label">Группа узнает, что бронь снята, сценарий закрыт или группа распущена через стенд. Закрытый сценарий возвращает участникам прежние роли.</Box>
        </Section>
      )}
      {!!stand.pads?.length && (
        <Section title="Площадки хаба">
          {stand.pads.map((pad) => (
            <Stack key={pad.id} align="center" wrap mb={1}>
              <Stack.Item grow>
                <Box bold>{pad.name}</Box>
                <Box color="label">Владелец: {pad.owner} · пресет «{pad.preset}»</Box>
              </Stack.Item>
              <Stack.Item>
                <Button.Confirm icon="flag-checkered" disabled={!!data.busy} content="Освободить" confirmContent="Освободить площадку?" onClick={() => act('stand_release', { kind: 'pad', id: pad.id })} />
              </Stack.Item>
            </Stack>
          ))}
          <Box color="label">Владелец узнает, что площадку освободили через стенд; на ней снова пустой зал.</Box>
        </Section>
      )}
      <Section title="Сброс без голосования">
        <Box color="label" mb={1}>Обстановка зоны пересоздаётся сразу, участники из неё вернутся в центр.</Box>
        <Stack wrap>
          {resetZones.map((zone) => (
            <Stack.Item key={zone.id} mb={0.5}>
              <Button.Confirm icon="rotate" disabled={!!data.busy} content={zone.name} confirmContent="Сбросить сейчас?" onClick={() => act('stand_reset', { zone: zone.id })} />
            </Stack.Item>
          ))}
          <Stack.Item mb={0.5}>
            <Button.Confirm icon="rotate" color="bad" disabled={!!data.busy} content="Весь полигон" confirmContent="Сбросить всё сейчас?" onClick={() => act('stand_reset', { zone: 'all' })} />
          </Stack.Item>
        </Stack>
      </Section>
    </>
  );
};

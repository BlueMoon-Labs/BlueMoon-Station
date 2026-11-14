import { BooleanLike } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Dropdown, Icon, NoticeBox, Section, Stack } from '../components';
import { Window } from '../layouts';
import { formatClock } from './AntagTrainingSquads';

export type PadVote = {
  preset_name: string;
  reload: BooleanLike;
  approved: number;
  total: number;
  remaining: number;
  voted: BooleanLike;
  can_vote: BooleanLike;
};
export type PadEntry = {
  id: string;
  name: string;
  preset: string;
  preset_name: string;
  owner: string | null;
  squad: BooleanLike;
  mine: BooleanLike;
  open: BooleanLike;
  can_enter: BooleanLike;
  loading: BooleanLike;
  ready: BooleanLike;
  inside: number;
  scenario: string | null;
  idle_remaining: number | null;
  vote: PadVote | null;
};
export type PadPreset = { id: string; name: string; desc: string; programs?: string[]; scenarios?: string[] };
export type PadsData = {
  pads?: PadEntry[];
  pad_presets?: PadPreset[];
  pad_idle_minutes?: number;
  pads_ready?: BooleanLike;
  pad_mine?: string | null;
};

const padStatus = (pad: PadEntry) => {
  if (pad.loading) return 'загружается';
  if (!pad.ready) return 'не готова';
  if (!pad.owner) return 'свободна';
  if (pad.scenario) return `сценарий «${pad.scenario}»`;
  return pad.open ? 'открыта для всех' : 'только для владельцев';
};

const PadVoteBox = ({ pad }: { pad: PadEntry }) => {
  const { act } = useBackend<PadsData>();
  const vote = pad.vote;
  if (!vote) return null;
  return (
    <div className="AntagTraining__vote">
      <Box bold>{vote.reload ? 'Перезагрузка площадки' : `Пресет «${vote.preset_name}»`}</Box>
      <Box my={0.5}>Согласны {vote.approved} из {vote.total} · осталось {vote.remaining} с. Всех внутри выведут в галерею, обстановка вернётся как была в пресете.</Box>
      {!!vote.can_vote && (
        <Button icon="check" disabled={!!vote.voted} onClick={() => act('pad_vote', { id: pad.id })}>{vote.voted ? 'Вы согласились' : 'Согласиться'}</Button>
      )}
    </div>
  );
};

const PadCard = ({ pad }: { pad: PadEntry }) => {
  const { act, data } = useBackend<PadsData>();
  const presets = data.pad_presets || [];
  const [preset, setPreset] = useState(presets.find((entry) => entry.id === pad.preset)?.id || presets[0]?.id || '');
  const busy = !!pad.loading || !pad.ready;
  const chosen = presets.find((entry) => entry.id === preset);
  return (
    <Section
      title={pad.name}
      buttons={<Box color={pad.owner ? (pad.open ? 'good' : 'average') : 'label'}><Icon name={pad.open ? 'door-open' : 'lock'} mr={0.5} />{padStatus(pad)}</Box>}>
      <Box>
        Пресет: <b>{pad.preset_name}</b>
        {pad.owner ? ` · владелец: ${pad.owner}` : ''}
        {pad.inside > 0 ? ` · внутри ${pad.inside}` : ''}
      </Box>
      {pad.idle_remaining !== null && !pad.scenario && (
        <Box color="label" mt={0.5}>Без владельцев на площадке освободится через {formatClock(pad.idle_remaining)}.</Box>
      )}
      {!!pad.owner && !pad.can_enter && <Box color="label" mt={0.5}>{pad.scenario ? 'Идёт сценарий: внутрь пускают только его участников, выбывшие смотрят с трибуны.' : 'Вход закрыт: внутрь пускают только владельцев.'}</Box>}
      <PadVoteBox pad={pad} />
      <Stack mt={1} wrap align="center">
        {!pad.owner && (
          <Stack.Item>
            <Button icon="flag" disabled={busy || !!data.pad_mine} tooltip={data.pad_mine ? 'У вас или вашей группы уже есть площадка.' : undefined} onClick={() => act('pad_claim', { id: pad.id })}>Занять</Button>
          </Stack.Item>
        )}
        {!!pad.mine && (
          <>
            <Stack.Item>
              <Dropdown width={14} selected={preset} options={presets.map((entry) => ({ value: entry.id, displayText: entry.name }))} disabled={busy || !!pad.scenario} onSelected={setPreset} />
            </Stack.Item>
            <Stack.Item>
              <Button icon="download" disabled={busy || !!pad.scenario || !preset} onClick={() => act('pad_preset', { id: pad.id, preset })}>Загрузить</Button>
            </Stack.Item>
            <Stack.Item>
              <Button.Checkbox checked={!!pad.open} disabled={busy} onClick={() => act('pad_open', { id: pad.id })}>Пускать всех</Button.Checkbox>
            </Stack.Item>
            <Stack.Item>
              <Button.Confirm icon="flag-checkered" color="transparent" disabled={busy || !!pad.scenario} content="Освободить" confirmContent="Освободить площадку?" onClick={() => act('pad_release', { id: pad.id })} />
            </Stack.Item>
          </>
        )}
        {(!!pad.mine || (pad.inside > 0 && !!pad.can_enter)) && (
          <Stack.Item>
            <Button icon="rotate" disabled={busy || !!pad.scenario} tooltip="Возвращает обстановку пресета. Нужно согласие всех, кто внутри." onClick={() => act('pad_reload', { id: pad.id })}>Перезагрузить</Button>
          </Stack.Item>
        )}
      </Stack>
      {!!pad.mine && !!chosen && <Box color="label" mt={0.5}>{chosen.desc}</Box>}
      {!!pad.mine && !!chosen?.programs?.length && <Box color="label" mt={0.5}>Подходит программам: {chosen.programs.join(', ')}.</Box>}
      {!!pad.mine && !!chosen?.scenarios?.length && <Box color="label" mt={0.5}>Сценарии на этом пресете: {chosen.scenarios.join(', ')}.</Box>}
    </Section>
  );
};

export const TrainingPads = () => {
  const { data } = useBackend<PadsData>();
  const pads = data.pads || [];
  if (!data.pads_ready) {
    return <NoticeBox>Площадки хаба загружаются вместе с мини-станцией, когда на полигон входит игрок.</NoticeBox>;
  }
  return (
    <>
      <Box color="label" mb={1}>
        Четыре площадки 15x15 к северу от галереи. Любой участник занимает свободную площадку для себя, а в группе - для группы: одна площадка на игрока или группу. Владелец выбирает пресет комнаты и решает, пускать ли остальных. Без владельцев на площадке и действий с пульта она освобождается через {data.pad_idle_minutes} мин.
      </Box>
      {pads.map((pad) => (
        <PadCard key={pad.id} pad={pad} />
      ))}
    </>
  );
};

type PanelData = PadsData & { focus: string | null };

export const AntagTrainingPads = () => {
  const { data } = useBackend<PanelData>();
  const focused = (data.pads || []).filter((pad) => pad.id === data.focus);
  return (
    <Window width={560} height={420} title="Пульт площадки">
      <Window.Content scrollable>
        {!data.pads && <NoticeBox>Пультом площадки пользуются участники полигона.</NoticeBox>}
        {!!data.pads && !data.pads_ready && <NoticeBox>Площадки хаба загружаются вместе с мини-станцией, когда на полигон входит игрок.</NoticeBox>}
        {!!data.pads_ready && focused.map((pad) => <PadCard key={pad.id} pad={pad} />)}
        {!!data.pads_ready && (
          <Box color="label">Остальные площадки и их владельцы - во вкладке «Площадки» пульта полигона.</Box>
        )}
      </Window.Content>
    </Window>
  );
};

import { BooleanLike } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Icon, Input, Section, Stack } from '../components';

export type SquadMember = { id: string; name: string; leader: BooleanLike };
export type SquadEntry = {
  id: string;
  name: string;
  color: string;
  open: BooleanLike;
  leader: string | null;
  members: SquadMember[];
  sector: string | null;
  sector_id: string | null;
  mine: BooleanLike;
  invited: { id: string; name: string; remaining: number }[];
};
export type SquadInvite = { id: string; name: string; color: string; remaining: number };
export type SectorBookingEntry = {
  id: string;
  squad: string | null;
  color: string | null;
  mine: BooleanLike;
  leader: BooleanLike;
  waitlist: string[];
  on_waitlist: BooleanLike;
  remaining: number;
  idle_remaining: number;
  /** Свободный сектор придержан за этой группой из очереди. */
  priority?: string | null;
  priority_mine?: BooleanLike;
  priority_remaining?: number;
};
export type SquadData = {
  squads?: SquadEntry[];
  squad_invites?: SquadInvite[];
  squad?: string | null;
  squad_leader?: BooleanLike;
  bookings?: Record<string, SectorBookingEntry>;
  booking_used?: number;
  booking_max?: number;
  booking_minutes?: number;
  booking_idle_minutes?: number;
  squad_invite_seconds?: number;
};
type Participant = { id: string; name: string; self: BooleanLike; connected: BooleanLike };

export const formatClock = (seconds: number) => {
  const total = Math.max(0, Math.floor(seconds));
  return `${Math.floor(total / 60)}:${String(total % 60).padStart(2, '0')}`;
};

/** Сектор занят чужой группой: входить нельзя. */
export const sectorClosed = (data: SquadData, sectorId: string) => {
  const booking = data.bookings?.[sectorId];
  return !!booking?.squad && !booking.mine;
};

/** Сброс занятого сектора запускает только лидер группы брони. */
export const resetLocked = (data: SquadData, sectorId: string) => {
  const booking = data.bookings?.[sectorId];
  return !!booking?.squad && !booking.leader;
};

export const TrainingSquads = ({ members }: { members: Participant[] }) => {
  const { act, data } = useBackend<SquadData>();
  const [name, setName] = useState('');
  const [open, setOpen] = useState(true);
  const squads = data.squads || [];
  const invites = data.squad_invites || [];
  const mine = squads.find((squad) => squad.id === data.squad);
  const grouped = new Set(squads.flatMap((squad) => squad.members.map((member) => member.id)));
  const leader = !!data.squad_leader;
  return (
    <>
      {invites.map((invite) => (
        <div key={invite.id} className="AntagTraining__vote">
          <Box bold><Icon name="flag" color={invite.color} mr={0.5} />Вас зовут в группу «{invite.name}»</Box>
          <Box my={0.5}>Ответьте в течение {invite.remaining} с. Из своей группы сначала нужно выйти.</Box>
          <Button icon="check" disabled={!!mine} onClick={() => act('squad_accept', { id: invite.id })}>Принять</Button>
          <Button icon="xmark" color="transparent" onClick={() => act('squad_decline', { id: invite.id })}>Отказаться</Button>
        </div>
      ))}
      {mine ? (
        <Section
          title={`Группа «${mine.name}»`}
          buttons={<Button.Confirm icon="right-from-bracket" color="transparent" content="Выйти из группы" confirmContent={leader && mine.members.length > 1 ? 'Лидером станет следующий. Выйти?' : 'Выйти из группы?'} onClick={() => act('squad_leave')} />}>
          <Box color="label" mb={1}>
            <Icon name="flag" color={mine.color} mr={0.5} />
            {mine.sector ? `Бронь: ${mine.sector}. Входить туда может только группа.` : leader ? 'Сектор не занят. Забронируйте его во вкладке «Зоны».' : 'Сектор бронирует лидер группы во вкладке «Зоны».'}
          </Box>
          {leader && (
            <Button.Checkbox checked={!!mine.open} onClick={() => act('squad_open')}>Открытая группа: войти может любой</Button.Checkbox>
          )}
          <Stack vertical mt={1}>
            {mine.members.map((member) => (
              <Stack.Item key={member.id}>
                <Stack align="center">
                  <Stack.Item grow>{member.leader ? <Icon name="crown" mr={0.5} color="average" /> : null}{member.name}</Stack.Item>
                  {leader && !member.leader && (
                    <Stack.Item>
                      <Button icon="crown" color="transparent" onClick={() => act('squad_leader', { id: member.id })}>Сделать лидером</Button>
                      <Button icon="user-minus" color="transparent" onClick={() => act('squad_kick', { id: member.id })}>Исключить</Button>
                    </Stack.Item>
                  )}
                </Stack>
              </Stack.Item>
            ))}
          </Stack>
          {leader && (
            <Box mt={1.5}>
              <Box bold mb={0.5}>Пригласить</Box>
              {members.filter((member) => !member.self && !grouped.has(member.id)).map((member) => {
                const pending = mine.invited.find((invite) => invite.id === member.id);
                return (
                  <Button key={member.id} icon="user-plus" disabled={!!pending || !member.connected} onClick={() => act('squad_invite', { id: member.id })}>
                    {pending ? `${member.name} · ждём ${pending.remaining} с` : member.name}
                  </Button>
                );
              })}
              {!members.some((member) => !member.self && !grouped.has(member.id)) && <Box color="label">Все участники уже в группах.</Box>}
            </Box>
          )}
        </Section>
      ) : (
        <Section title="Новая группа">
          <Stack align="center" wrap>
            <Stack.Item grow basis="220px"><Input fluid value={name} placeholder="Название (можно не указывать)" onInput={(_, value) => setName(value)} /></Stack.Item>
            <Stack.Item><Button.Checkbox checked={open} onClick={() => setOpen(!open)}>Открытая</Button.Checkbox></Stack.Item>
            <Stack.Item><Button icon="flag" onClick={() => act('squad_create', { name, open })}>Собрать группу</Button></Stack.Item>
          </Stack>
          <Box color="label" mt={1}>В открытую группу входят сами, в закрытую — по приглашению лидера (на ответ {data.squad_invite_seconds ?? 30} с).</Box>
        </Section>
      )}
      {squads.filter((squad) => !squad.mine).length > 0 && (
        <Section title="Группы на полигоне">
          {squads.filter((squad) => !squad.mine).map((squad) => (
            <Stack key={squad.id} align="center" mb={0.5}>
              <Stack.Item grow>
                <Icon name="flag" color={squad.color} mr={0.5} />
                <b>{squad.name}</b> · лидер {squad.leader} · участников {squad.members.length}{squad.sector ? ` · занят сектор «${squad.sector}»` : ''}
              </Stack.Item>
              <Stack.Item>
                {squad.open ? (
                  <Button icon="right-to-bracket" disabled={!!mine} onClick={() => act('squad_join', { id: squad.id })}>Войти</Button>
                ) : (
                  <Box color="label">По приглашению</Box>
                )}
              </Stack.Item>
            </Stack>
          ))}
        </Section>
      )}
      <Box className="AntagTraining__hint">
        <Icon name="flag" /> Участники группы управляют целями друг друга и пользуются вещами товарищей. Лидер бронирует один сектор на {data.booking_minutes ?? 40} минут: внутрь входит только группа, сброс решает только она. Бронь снимется, если {data.booking_idle_minutes ?? 5} минут в секторе нет никого из группы. Пока в секторе идёт партия сценария группы, бронь не истекает и не снимается за простой.
      </Box>
    </>
  );
};

export const SectorBooking = ({ sectorId }: { sectorId: string }) => {
  const { act, data } = useBackend<SquadData>();
  const booking = data.bookings?.[sectorId];
  if (!booking) return null;
  const mySquad = data.squads?.find((squad) => squad.id === data.squad);
  if (!booking.squad) {
    const full = (data.booking_used ?? 0) >= (data.booking_max ?? 0);
    const heldElsewhere = !!booking.priority && !booking.priority_mine;
    const clock = formatClock(booking.priority_remaining ?? 0);
    return (
      <Stack align="center" mb={1}>
        <Stack.Item grow color="label">
          <Icon name="lock-open" mr={0.5} />
          {booking.priority ? (booking.priority_mine ? `Придержан за вашей группой из очереди · ещё ${clock}` : `Первой занять может группа «${booking.priority}» из очереди · ещё ${clock}`) : 'Свободен для всех'}
        </Stack.Item>
        {!!data.squad_leader && !mySquad?.sector && (
          <Stack.Item>
            <Button icon="lock" disabled={full || heldElsewhere} tooltip={full ? 'Все доступные брони заняты: два сектора всегда остаются свободными.' : heldElsewhere ? 'Группы из очереди занимают освободившийся сектор первыми, каждая в свою минуту.' : undefined} onClick={() => act('booking_book', { id: sectorId })}>Забронировать</Button>
          </Stack.Item>
        )}
      </Stack>
    );
  }
  const waiting = booking.waitlist.length;
  return (
    <Box mb={1}>
      <Box><Icon name="lock" color={booking.color || undefined} mr={0.5} />Занят группой «{booking.squad}» · ещё {formatClock(booking.remaining)}</Box>
      {booking.mine ? (
        <Box color="label" mt={0.5}>Если в секторе не будет никого из группы, бронь снимется через {formatClock(booking.idle_remaining)}.</Box>
      ) : null}
      <Box color="label" mt={0.5}>{waiting ? `В очереди: ${waiting} (${booking.waitlist.join(', ')}). Продлить бронь нельзя.` : 'Очередь пуста.'}</Box>
      <Box mt={0.5}>
        {!!booking.leader && (
          <>
            <Button icon="clock-rotate-left" disabled={waiting > 0} tooltip={waiting ? 'Сектор ждут в очереди: освободите его, когда закончите.' : undefined} onClick={() => act('booking_extend')}>Продлить</Button>
            <Button.Confirm icon="lock-open" color="transparent" content="Освободить" confirmContent="Снять бронь?" onClick={() => act('booking_release')} />
          </>
        )}
        {!booking.mine && (booking.on_waitlist ? (
          <Button icon="xmark" color="transparent" onClick={() => act('waitlist_leave', { id: sectorId })}>Выйти из очереди</Button>
        ) : (
          <Button icon="hourglass-half" onClick={() => act('waitlist_join', { id: sectorId })}>Встать в очередь</Button>
        ))}
      </Box>
    </Box>
  );
};

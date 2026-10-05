import { useBackend } from '../backend';
import { Box, Button, LabeledList, ProgressBar, Section } from '../components';
import { Window } from '../layouts';

export const VrSleeper = (props) => {
  const { act, data } = useBackend();
  // Modes, loadouts and the player roster all arrive as flat
  // "deathmatch_<thing>_N_field" keys. A DM list of assoc lists reaches the
  // browser as a list of lists, which left every mode.name and mode.id undefined
  // and rendered the buttons as bare "()".
  const modeCount = data.deathmatch_mode_count || 0;
  const deathmatchModes = [];
  for (let i = 1; i <= modeCount; i++) {
    deathmatchModes.push({
      id: data[`deathmatch_mode_${i}_id`],
      name: data[`deathmatch_mode_${i}_name`],
      description: data[`deathmatch_mode_${i}_description`],
      players: data[`deathmatch_mode_${i}_players`],
      waiting: data[`deathmatch_mode_${i}_waiting`],
    });
  }

  const loadoutCount = data.deathmatch_loadout_count || 0;
  const deathmatchLoadouts = [];
  for (let i = 1; i <= loadoutCount; i++) {
    deathmatchLoadouts.push({
      id: data[`deathmatch_loadout_${i}_id`],
      name: data[`deathmatch_loadout_${i}_name`],
    });
  }

  const rosterCount = data.deathmatch_roster_count || 0;
  const deathmatchRoster = [];
  for (let i = 1; i <= rosterCount; i++) {
    deathmatchRoster.push({
      name: data[`deathmatch_roster_${i}_name`],
      host: data[`deathmatch_roster_${i}_host`],
      loadout: data[`deathmatch_roster_${i}_loadout`],
      self: data[`deathmatch_roster_${i}_self`],
    });
  }

  const inLobby = !!data.in_deathmatch_lobby;
  const lobbyRunning = !!data.deathmatch_lobby_running;
  const needed = data.deathmatch_players_needed || 0;
  // The roster is closed the moment the arena loads, so loadouts are only
  // choosable while people are still gathering.
  const canPickLoadout = inLobby && !lobbyRunning;
  return (
    <Window
      width={475}
      height={620}>
      <Window.Content>
        {!!data.emagged && (
          <Section>
            <Box color="bad">
              Safety restraints disabled.
            </Box>
          </Section>
        )}

        <Section title={"Virtual Avatar"}>
          {data.vr_avatar ? (
            <LabeledList>
              <LabeledList.Item
                label={"Name"} >
                {data.vr_avatar.name}
              </LabeledList.Item>
              <LabeledList.Item
                label={"Status"} >
                {data.vr_avatar.status}
              </LabeledList.Item>
              {!!data.vr_avatar && (
                <LabeledList.Item
                  label={"Health"} >
                  {<ProgressBar
                    value={data.vr_avatar.health / data.vr_avatar.maxhealth}
                    ranges={{
                      good: [0.9, Infinity],
                      average: [0.7, 0.8],
                      bad: [-Infinity, 0.5],
                    }} />}
                </LabeledList.Item>
              )}
            </LabeledList>
          ) : (
            "No Virtual Avatar detected"
          )}
        </Section>
        <Section title="VR Commands">
          <Button
            icon={data.toggle_open ? 'unlock' : 'lock'}
            disabled={data.stored < data.max}
            onClick={() => act('toggle_open')}>
            {data.toggle_open
              ? 'Close VR Sleeper'
              : 'Open VR Sleeper'}
          </Button>
          {!!data.vr_avatar && (
            <Button
              icon={'recycle'}
              onClick={() => {
                act('delete_avatar');
              }}>
              Delete VR avatar
            </Button>
          )}
        </Section>
        <Section title="Deathmatch">
          {inLobby ? (
            <Box>
              <Box color="good">
                {data.deathmatch_lobby_name} lobby:{' '}
                {data.deathmatch_player_count}/{data.deathmatch_min_players} min
                {lobbyRunning
                  ? ' (running)'
                  : needed > 0
                    ? ` - waiting for ${needed} more`
                    : ' - ready to start'}
                .
              </Box>
              <Section title="Players">
                {deathmatchRoster.length === 0 ? (
                  <Box color="bad">Nobody on the roster.</Box>
                ) : (
                  deathmatchRoster.map((entry, i) => (
                    <Box key={`${entry.name}-${i}`}>
                      {entry.name}
                      {entry.self ? ' (you)' : ''}
                      {entry.host ? ' [host]' : ''} - {entry.loadout}
                    </Box>
                  ))
                )}
              </Section>
              <Section title="Your loadout">
                {deathmatchLoadouts.map((loadout) => (
                  <Button
                    key={loadout.id}
                    icon={loadout.id === data.deathmatch_selected_loadout
                      ? 'check'
                      : 'gear'}
                    color={loadout.id === data.deathmatch_selected_loadout
                      ? 'green'
                      : 'blue'}
                    disabled={!canPickLoadout
                      || loadout.id === data.deathmatch_selected_loadout}
                    onClick={() => act('select_deathmatch_loadout', {
                      loadout: loadout.id,
                    })}>
                    {loadout.name}
                  </Button>
                ))}
              </Section>
              {data.is_hosting_deathmatch ? (
                <Button
                  icon={'play'}
                  color={'good'}
                  disabled={!data.can_start_deathmatch}
                  onClick={() => act('start_deathmatch')}>
                  Start deathmatch
                </Button>
              ) : (
                <Box color="bad">
                  {needed > 0
                    ? `Waiting for the host. ${needed} more player(s) needed.`
                    : 'Waiting for the host to start.'}
                </Box>
              )}
              {data.is_hosting_deathmatch && !lobbyRunning && (
                <Button
                  icon={'stop'}
                  color={'red'}
                  onClick={() => act('end_deathmatch')}>
                  Cancel lobby
                </Button>
              )}
              <Button.Confirm
                color={'red'}
                icon={'minus'}
                onClick={() => act('leave_deathmatch')}>
                Leave
              </Button.Confirm>
            </Box>
          ) : (
            <Box>
              {deathmatchModes.length === 0 ? (
                <Box color="bad">No deathmatch modes are compiled in.</Box>
              ) : (
                deathmatchModes.map((mode) => (
                  <Button
                    key={mode.id}
                    icon={'play'}
                    color={'blue'}
                    tooltip={mode.description}
                    onClick={() => act('select_deathmatch_mode', { mode: mode.id })}>
                    {mode.name} ({mode.players}
                    {mode.waiting ? `, ${mode.waiting} waiting` : ''})
                  </Button>
                ))
              )}
              {!data.isoccupant && (
                <Box color="bad">
                  Lie in the sleeper to open a lobby. You can join an open one
                  from here.
                </Box>
              )}
            </Box>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};

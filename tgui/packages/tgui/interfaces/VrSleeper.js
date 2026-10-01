import { useBackend } from '../backend';
import { Box, Button, LabeledList, ProgressBar, Section } from '../components';
import { Window } from '../layouts';

export const VrSleeper = (props) => {
  const { act, data } = useBackend();
  // TDM cannot tell an empty DM list from an empty assoc list and hands the
  // first over as {}, so this is not guaranteed to be an array. Normalised once
  // here instead of guarding each use.
  const deathmatchModes = Array.isArray(data.deathmatch_modes)
    ? data.deathmatch_modes
    : Object.values(data.deathmatch_modes || {});
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
          <Section>
            {data.isoccupant ? (
              <Button.Confirm
                color={'blue'}
                onClick={() => {
                  act('vr_connect');
                  act('tgui:close');
                }}
                icon={'unlock'}>
                Connect to VR
              </Button.Confirm>
            ) : (
              "You need to be inside the VR sleeper to connect to VR"
            )}
          </Section>
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
          {data.is_hosting_deathmatch ? (
            <Box>
              <Box color="good">
                Hosting {data.hosting_deathmatch.name} with{' '}
                {data.hosting_deathmatch.players} player(s).
              </Box>
              <Button.Confirm
                color={'red'}
                icon={'stop'}
                onClick={() => act('end_deathmatch')}>
                End game
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
                    icon={mode.id === data.selected_deathmatch_mode
                      ? 'check'
                      : 'play'}
                    color={mode.id === data.selected_deathmatch_mode
                      ? 'green'
                      : 'blue'}
                    tooltip={mode.description}
                    onClick={() => act('select_deathmatch_mode', { mode: mode.id })}>
                    {mode.name} ({mode.players})
                  </Button>
                ))
              )}
              <Button.Confirm
                color={'good'}
                icon={'play'}
                disabled={!data.can_start_deathmatch
                  || !data.selected_deathmatch_mode}
                onClick={() => act('start_deathmatch')}>
                Start deathmatch
              </Button.Confirm>
              {!data.isoccupant && (
                <Box color="bad">
                  Lie in the sleeper to host a game.
                </Box>
              )}
            </Box>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};

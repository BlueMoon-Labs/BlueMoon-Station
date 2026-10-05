import { BooleanLike } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  Divider,
  Dropdown,
  Icon,
  LabeledList,
  Modal,
  NoticeBox,
  Section,
  Stack,
  Table,
  Tooltip,
} from '../components';
import { Window } from '../layouts';

/**
 * One lobby: who is here, what they picked, and the host's controls.
 *
 * Ported from newTG's DeathmatchLobby. The shape is unchanged - player table on the
 * left with a loadout picker and a ready box per row, map info and modifiers on the
 * right, controls along the bottom - but it is driven by a VR sleeper rather than by
 * newTG's standalone ghost controller, and the rows are positional arrays because
 * that is what the DM side builds with UNTYPED_LIST_ADD.
 *
 * The index constants are the contract with deathmatch_lobby.dm. If a row is
 * reordered there, it moves here too.
 */
type PlayerRow = [
  string, // ckey
  string, // display name
  BooleanLike, // host
  BooleanLike, // ready
  BooleanLike, // observer
  BooleanLike, // you
  string, // loadout name, or "watching"
  BooleanLike, // standing in the arena
];

type LoadoutRow = [string, string, string];
type ModifierRow = [string, string, string, BooleanLike];
type ModeRow = [string, string, string, number, number];

type Data = {
  map_name: string;
  map_display_name: string;
  map_description: string;
  host: string;
  state: string;
  seat_count: number;
  player_count: number;
  observer_count: number;
  max_players: number;
  min_players: number;
  ready_count: number;
  players_needed: number;
  is_host: BooleanLike;
  you_are_observer: BooleanLike;
  time_left: string;
  can_start: BooleanLike;
  start_refusal: string;
  players?: PlayerRow[];
  selected_modifiers?: string[];
  your_loadout: string;
  your_loadouts?: LoadoutRow[];
  // ui_static_data is merged into data by backend.ts, not kept apart.
  modes?: ModeRow[];
  modifiers?: ModifierRow[];
};

const CKEY = 0;
const DISPLAY_NAME = 1;
const IS_HOST = 2;
const IS_READY = 3;
const IS_OBSERVER = 4;
const IS_YOU = 5;
const LOADOUT = 6;

const KIT_PATH = 0;
const KIT_NAME = 1;

const MOD_PATH = 0;
const MOD_NAME = 1;
const MOD_DESC = 2;

const MODE_NAME = 0;
const MODE_DISPLAY = 1;

export function DeathmatchLobby(props) {
  const { act, data } = useBackend<Data>();
  const [modMenu, setModMenu] = useState(false);
  const { is_host, players = [], start_refusal, state, time_left } = data;
  const [you_are_observer] = [data.you_are_observer];

  const running = state === 'running';
  const fighters = players.filter((player) => !player[IS_OBSERVER]);
  const allReady =
    fighters.length > 0 && fighters.every((player) => player[IS_READY]);

  return (
    <Window title="Deathmatch Lobby" width={640} height={580}>
      {modMenu && <ModSelector onClose={() => setModMenu(false)} />}
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Stack fill align="center" justify="space-between">
              <Stack.Item>
                <Box bold>{data.map_display_name || 'No arena'}</Box>
                <Box color="average">
                  Hosted by {data.host} &mdash; {running ? time_left : 'Waiting'}
                </Box>
              </Stack.Item>
              <Stack.Item>
                <Stack>
                  <Stack.Item>
                    <Tooltip content="Fighting">
                      <Box color="label">
                        {data.player_count}/{data.max_players}
                      </Box>
                    </Tooltip>
                  </Stack.Item>
                  {!!data.observer_count && (
                    <Stack.Item>
                      <Tooltip content="Watching">
                        <Box color="average">
                          <Icon name="eye" /> {data.observer_count}
                        </Box>
                      </Tooltip>
                    </Stack.Item>
                  )}
                  <Stack.Item>
                    <Tooltip content="Ready">
                      <Box color="label">
                        {data.ready_count}/{fighters.length}
                      </Box>
                    </Tooltip>
                  </Stack.Item>
                </Stack>
              </Stack.Item>
            </Stack>
          </Stack.Item>

          <Stack.Item>
            <Divider />
          </Stack.Item>

          <Stack.Item grow>
            <Stack fill>
              <Stack.Item grow={4}>
                <PlayerColumn />
              </Stack.Item>
              <Stack.Item grow={3}>
                <SideColumn onOpenMods={() => setModMenu(true)} />
              </Stack.Item>
            </Stack>
          </Stack.Item>

          <Stack.Item>
            <Section>
              <Stack fill>
                <Stack.Item grow>
                  {!!is_host && running && (
                    <Button color="bad" onClick={() => act('end_game')}>
                      End Game
                    </Button>
                  )}
                </Stack.Item>
                <Stack.Item>
                  <Button
                    color="caution"
                    disabled={running}
                    onClick={() => act('toggle_observe')}
                  >
                    {you_are_observer ? 'Join In' : 'Observe'}
                  </Button>
                  <Button color="bad" onClick={() => act('leave_game')}>
                    Leave
                  </Button>
                  <Button
                    color="good"
                    // can_start is the server's own answer - it already folds in the
                    // refusal, which is where "somebody is not ready" comes from. A
                    // second copy of that rule here would be a second thing to drift.
                    disabled={!data.can_start}
                    onClick={() => act('start_game')}
                  >
                    Start Game
                  </Button>
                </Stack.Item>
              </Stack>
              {!!start_refusal && (
                <Box mt="1" color="average" textAlign="center">
                  {start_refusal}
                </Box>
              )}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
}

function PlayerColumn(props) {
  const { data } = useBackend<Data>();
  const { is_host, players = [], your_loadout, your_loadouts = [] } = data;

  const running = data.state === 'running';
  // value is the index, not the type path: Dropdown hands onSelected() whatever sits
  // in `value`, and select_loadout() on the DM side counts into available_loadouts()
  // rather than matching on a path. displayText keeps the readable name on screen.
  const kitOptions = your_loadouts.map((kit, index) => ({
    value: index,
    displayText: kit[KIT_NAME],
  }));
  // -1 means the backend has a loadout for us that is not in this list, which happens
  // the moment the host swaps arenas. undefined rather than -1, so the control falls
  // back to its own state instead of showing the number.
  const yourKitIndex = your_loadouts.findIndex(
    (kit) => kit[KIT_PATH] === your_loadout);
  const fighters = players.filter((player) => !player[IS_OBSERVER]);
  const spectators = players.filter((player) => player[IS_OBSERVER]);
  const allReady =
    fighters.length > 0 && fighters.every((player) => player[IS_READY]);

  return (
    <Section
      fill
      scrollable
      title="Players"
      buttons={
        <Tooltip
          content={
            allReady
              ? 'Everybody who is fighting has said yes.'
              : 'Players are still preparing.'
          }
        >
          <Icon
            name={allReady ? 'check-circle' : 'check'}
            color={allReady && 'green'}
          />
        </Tooltip>
      }
    >
      <Table>
        <Table.Row header>
          <Table.Cell collapsing />
          <Table.Cell>Name</Table.Cell>
          <Table.Cell>Loadout</Table.Cell>
          <Table.Cell collapsing align="center">
            <Tooltip content="Ready">
              <Icon name="check" />
            </Tooltip>
          </Table.Cell>
        </Table.Row>

        {fighters.map((player) => (
          <FighterRow
            key={player[CKEY]}
            player={player}
            isHost={!!is_host}
            running={running}
            kitOptions={kitOptions}
            yourKitIndex={yourKitIndex}
          />
        ))}

        {spectators.map((player) => (
          <SpectatorRow
            key={player[CKEY]}
            player={player}
            isHost={!!is_host}
          />
        ))}
      </Table>
    </Section>
  );
}

function FighterRow(props) {
  const { act } = useBackend<Data>();
  const { isHost, kitOptions, player, running, yourKitIndex } = props;

  const host = !!player[IS_HOST];
  const self = !!player[IS_YOU];
  // Kicking yourself is what the Leave button is for, and a host handing hosting to
  // themselves is not an action.
  const canAdmin = isHost && !self;

  return (
    <Table.Row className="candystripe">
      <Table.Cell align="center" collapsing verticalAlign="top">
        {host ? (
          <Tooltip content="Host">
            <Icon color="gold" name="star" pt={self && 0.5} />
          </Tooltip>
        ) : (
          self && (
            <Tooltip content="You">
              <Icon color="green" name="arrow-right" pt={0.9} />
            </Tooltip>
          )
        )}
      </Table.Cell>

      <Table.Cell verticalAlign="top">
        {!canAdmin ? (
          <Box color="label">{player[DISPLAY_NAME]}</Box>
        ) : (
          <AdminDropdown player={player[CKEY]} host={host} />
        )}
      </Table.Cell>

      <Table.Cell>
        {!self ? (
          <Box color="label">{player[LOADOUT]}</Box>
        ) : (
          <Dropdown
            width={10}
            selected={yourKitIndex === -1 ? undefined : yourKitIndex}
            // The roster closes the moment the arena loads, so a loadout picked then
            // would come too late to matter.
            disabled={running}
            options={kitOptions}
            onSelected={(value) => act('select_loadout', { choice: value })}
          />
        )}
      </Table.Cell>

      <Table.Cell align="center" verticalAlign="middle">
        {self ? (
          <Button.Checkbox
            disabled={running}
            checked={player[IS_READY]}
            onClick={() => act('set_ready')}
          />
        ) : (
          !!player[IS_READY] && <Icon name="check" />
        )}
      </Table.Cell>
    </Table.Row>
  );
}

function SpectatorRow(props) {
  const { player, isHost } = props;
  const self = !!player[IS_YOU];
  const canAdmin = isHost && !self;

  return (
    <Table.Row>
      <Table.Cell align="center" collapsing verticalAlign="top">
        <Tooltip content={player[IS_HOST] ? 'Host' : 'Watching'}>
          <Icon color={player[IS_HOST] ? 'gold' : 'average'} name="eye" />
        </Tooltip>
      </Table.Cell>
      <Table.Cell verticalAlign="top">
        {canAdmin ? (
          <AdminDropdown player={player[CKEY]} host={false} />
        ) : (
          <Box color="label">{player[DISPLAY_NAME]}</Box>
        )}
      </Table.Cell>
      <Table.Cell colSpan={2}>
        <Box color="average">Observing</Box>
      </Table.Cell>
    </Table.Row>
  );
}

/**
 * The host's per-player menu.
 *
 * newTG folds Kick, Transfer host and Toggle observe into one dropdown and sends a
 * single `host` action with a `func` string. Split into three named actions here:
 * each one is a distinct server proc with its own preconditions, and a `func` string
 * that has to be re-parsed and re-validated on the DM side is one more place for the
 * window and the server to disagree about who may do what.
 *
 * Transfer host is left off the host's own row and Toggle observe is left off
 * spectators: an observer cannot hold the host bit, and handing somebody the game is
 * the host's call rather than something a guest can do to themselves.
 */
function AdminDropdown(props) {
  const { act } = useBackend<Data>();
  const { host, player } = props;

  const actions = {
    Kick: () => act('kick_player', { ckey: player }),
    'Transfer host': () => act('transfer_host', { ckey: player }),
    'Toggle observe': () => act('host_toggle_observe', { ckey: player }),
  };

  return (
    <Dropdown
      width={9}
      // Not `selected={player}`: selected is matched against option *values*, and the
      // ckey is not one of them, so the closed control would have shown the ckey and
      // looked like a selection that never happened. displayText is the placeholder.
      displayText="Options"
      options={Object.keys(actions)}
      onSelected={(value) => actions[value]()}
    />
  );
}

function SideColumn(props) {
  const { data } = useBackend<Data>();
  const { is_host, player_count, selected_modifiers = [], state } = data;

  return (
    <Section fill scrollable title="Arena">
      <MapInfo />
      <Divider />
      <Box textAlign="center" color="average">
        {selected_modifiers.length === 0
          ? 'No modifiers'
          : selected_modifiers.length +
            ' modifier' +
            (selected_modifiers.length === 1 ? '' : 's')}
      </Box>
      {!!is_host && state !== 'running' && (
        <>
          <Divider />
          <Button textAlign="center" fluid onClick={props.onOpenMods}>
            Modifiers
          </Button>
        </>
      )}
      <Divider />
      <LabeledList>
        <LabeledList.Item label="Fighting">{player_count}</LabeledList.Item>
        <LabeledList.Item label="Waiting for">{data.players_needed}</LabeledList.Item>
        <LabeledList.Item label="Ready">{data.ready_count}</LabeledList.Item>
      </LabeledList>
    </Section>
  );
}

/**
 * The modifier picker.
 *
 * Open state is client side. newTG keeps `mod_menu_open` on the server, so opening
 * and closing the menu each cost a round trip and the modal flickers on every click;
 * nothing else needs to know whether it is open.
 */
const ModSelector = (props) => {
  const { act, data } = useBackend<Data>();
  const { selected_modifiers = [] } = data;
  const { modifiers = [] } = data;

  return (
    <Modal>
      <Button fluid color="bad" onClick={props.onClose}>
        Back
      </Button>
      {modifiers.length === 0 && (
        <NoticeBox textAlign="center">No modifiers are compiled in.</NoticeBox>
      )}
      {modifiers.map((mod, index) => {
        const on = selected_modifiers.includes(mod[MOD_PATH]);
        return (
          <Button.Checkbox
            key={mod[MOD_PATH] || index}
            mb={2}
            checked={on}
            tooltip={mod[MOD_DESC]}
            color={on ? 'green' : 'blue'}
            onClick={() => act('toggle_modifier', { modifier: mod[MOD_PATH] })}
          >
            {mod[MOD_NAME]}
          </Button.Checkbox>
        );
      })}
    </Modal>
  );
};

function MapInfo(props) {
  const { act, data } = useBackend<Data>();
  const { map_display_name, map_description, map_name, state } = data;
  const { modes = [] } = data;

  // Read only for anybody who is not the host, which includes whoever opened this
  // window with the browser's View button and never sat down at the table.
  if (!data.is_host) {
    return (
      <Box>
        <Box bold>{map_display_name || 'No arena'}</Box>
        <Box color="average">{map_description}</Box>
      </Box>
    );
  }

  return (
    <>
      <Dropdown
        color="average"
        width="100%"
        // Keyed on the template name rather than looking the label back up: two
        // arenas are allowed to share a display name, and the name is what
        // change_map() actually resolves.
        selected={map_name}
        disabled={state === 'running'}
        options={modes.map((mode) => ({
          value: mode[MODE_NAME],
          displayText: mode[MODE_DISPLAY],
        }))}
        onSelected={(value) => act('change_map', { map: value })}
      />
      <Divider />
      <Box color="average">{map_description}</Box>
      <Divider />
      <LabeledList>
        <LabeledList.Item label="Min Players">{data.min_players}</LabeledList.Item>
        <LabeledList.Item label="Max Players">{data.max_players}</LabeledList.Item>
        <LabeledList.Item label="Seats">{data.seat_count}</LabeledList.Item>
      </LabeledList>
      {state === 'running' && (
        <>
          <Divider />
          <Box textAlign="center" color="average">
            Running. The arena cannot be swapped now.
          </Box>
        </>
      )}
    </>
  );
}

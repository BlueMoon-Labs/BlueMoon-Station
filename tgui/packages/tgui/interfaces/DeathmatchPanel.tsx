import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  Divider,
  Icon,
  NoticeBox,
  Section,
  Stack,
  Table,
  Tooltip,
} from '../components';
import { Window } from '../layouts';

/**
 * The VR sleeper panel, doubling as the Deathmatch lobby browser.
 *
 * Ported from newTG's DeathmatchPanel, which is a ghost window listing every open
 * lobby over on a standalone deathmatch controller. Here it is a machine: the top of
 * the window is the sleeper's own VR controls, and everything below it is the same
 * lobby table with a Create button per arena instead of a single Create Lobby.
 *
 * Rows are positional arrays rather than objects because that is what the DM side
 * builds with UNTYPED_LIST_ADD. The index constants below are the contract - if
 * deathmatch_maps.dm ever reorders a row, these move with it.
 */
type PanelData = {
  // FALSE when the window was opened from the guest browser rather than from a
  // sleeper, which is how somebody in the afterlife reaches it. The machine fields
  // below are still sent so a panel built against an older payload renders greyed
  // out rather than reaching into undefined.
  has_machine?: BooleanLike;

  // Machine, from vr_sleeper.dm.
  toggle_open: BooleanLike;
  emagged: BooleanLike;
  isoccupant: BooleanLike;
  can_delete_avatar: BooleanLike;
  vr_avatar: any;
  isliving: BooleanLike;
  sleeper_notice: string;

  // Deathmatch, from vr_sleeper.dm's ui_data.
  lobbies?: LobbyRow[];
  can_create_lobby: BooleanLike;
  in_lobby: BooleanLike;
  lobby_map: string;
  lobby_name: string;
  lobby_running: BooleanLike;
  lobby_is_host: BooleanLike;
  your_balance: number;
  // ui_static_data is merged into data by backend.ts, not kept apart.
  modes?: ModeRow[];
};

// [map, display name, description, host, running, players, spectators, max, min,
//  joinable, free to join something, stake M$]
type LobbyRow = [
  string,
  string,
  string,
  string,
  BooleanLike,
  number,
  number,
  number,
  number,
  BooleanLike,
  BooleanLike,
  number,
];

// [name, display name, description, min players, max players]
type ModeRow = [string, string, string, number, number];

const MAP = 0;
const DISPLAY_NAME = 1;
const HOST = 3;
const RUNNING = 4;
const PLAYERS = 5;
const SPECTATORS = 6;
const MAX = 7;
const JOINABLE = 9;
const FREE_TO_JOIN = 10;
const STAKE = 11;

const MODE_NAME = 0;
const MODE_DISPLAY = 1;
const MODE_DESC = 2;
const MODE_MIN = 3;
const MODE_MAX = 4;

export function DeathmatchPanel(props) {
  const { act, data } = useBackend<PanelData>();
  const { has_machine, in_lobby, sleeper_notice } = data;

  return (
    <Window
      title={has_machine ? 'VR Sleeper' : 'Deathmatch'}
      width={420}
      height={560}
    >
      <Window.Content>
        <Stack fill vertical>
          {sleeper_notice && (
            <Stack.Item>
              <NoticeBox textAlign="center">{sleeper_notice}</NoticeBox>
            </Stack.Item>
          )}

          {!!data.has_machine && (
            <>
              <Stack.Item>
                <MachinePane />
              </Stack.Item>

              <Stack.Item>
                <Divider />
              </Stack.Item>
            </>
          )}

          <Stack.Item grow>
            <LobbyPane />
          </Stack.Item>

          {in_lobby && (
            <Stack.Item>
              <NoticeBox textAlign="center" color="average">
                You are already in a game. Use the button below to get back to it.
              </NoticeBox>
            </Stack.Item>
          )}

          {/* Opening a game means lying in a sleeper, because that is where the
              host's real body ends up when it is over. A guest opens no game, so
              the whole pane is the machine's and goes away with it. */}
          {!!data.has_machine && (
            <>
              <Stack.Item>
                <Divider />
              </Stack.Item>

              <Stack.Item>
                <ModePane />
              </Stack.Item>
            </>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
}

/**
 * The sleeper's own controls, kept above the Deathmatch list because they are what
 * the machine is for. The Deathmatch part was bolted onto this window when the
 * browser moved here, and it would be easy to bury the thing that actually puts you
 * in VR underneath a lobby table.
 */
function MachinePane(props) {
  const { act, data } = useBackend<PanelData>();
  const {
    can_delete_avatar,
    emagged,
    isliving,
    isoccupant,
    toggle_open,
    vr_avatar,
  } = data;

  return (
    <Section
      title="Sleeper"
      buttons={
        <Button
          icon={toggle_open ? 'lock' : 'lock-open'}
          onClick={() => act('toggle_open')}
        >
          {toggle_open ? 'Close' : 'Open'}
        </Button>
      }
    >
      {!!emagged && (
        <NoticeBox danger width="100%" mb="2">
          Danger mode: you die for real.
        </NoticeBox>
      )}

      {vr_avatar ? (
        <Box>
          <Box bold>{vr_avatar.name}</Box>
          {!!isliving && (
            <Box>
              {vr_avatar.status} &mdash; {vr_avatar.health}/
              {vr_avatar.maxhealth}
            </Box>
          )}
          <Stack mt="2" justify="flex-end">
            <Stack.Item>
              <Button
                icon="trash"
                color="bad"
                disabled={!can_delete_avatar}
                onClick={() => act('delete_avatar')}
              >
                Delete avatar
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="play"
                color="good"
                disabled={!isoccupant || !can_delete_avatar}
                onClick={() => act('vr_connect')}
              >
                Connect
              </Button>
            </Stack.Item>
          </Stack>
        </Box>
      ) : (
        <Box color="average">No virtual avatar.</Box>
      )}
    </Section>
  );
}

function LobbyPane(props) {
  const { data } = useBackend<PanelData>();
  const { lobbies = [], your_balance = 0 } = data;

  return (
    <Section
      fill
      scrollable
      title="Open Lobbies"
      buttons={
        <Box color="gold">
          {your_balance} M$
        </Box>
      }
    >
      <Table>
        <Table.Row header>
          <Table.Cell>Host</Table.Cell>
          <Table.Cell>Arena</Table.Cell>
          <Table.Cell collapsing>
            <Tooltip content="Fighting">
              <Icon name="users" />
            </Tooltip>
          </Table.Cell>
          <Table.Cell align="center" collapsing>
            <Tooltip content="Actions">
              <Icon name="hammer" />
            </Tooltip>
          </Table.Cell>
        </Table.Row>

        {lobbies.length === 0 && (
          <Table.Row>
            <Table.Cell colSpan={4}>
              <NoticeBox textAlign="center">
                No lobbies are open. Open one below.
              </NoticeBox>
            </Table.Cell>
          </Table.Row>
        )}

        {lobbies.map((lobby, index) => (
          <LobbyDisplay key={lobby[MAP] || index} lobby={lobby} />
        ))}
      </Table>
    </Section>
  );
}

function LobbyDisplay(props) {
  const { act, data } = useBackend<PanelData>();
  const { lobby } = props;
  const { in_lobby, lobby_map, your_balance = 0 } = data;

  const map = lobby[MAP];
  // Already in this one: the button becomes View rather than being greyed out,
  // because "I am in this game" and "there is a game I could join" are different
  // questions and the panel has to answer both.
  const isThis = lobby_map === map;
  const blocked = !!in_lobby && !isThis;
  // A competitive lobby costs stake M$ to enter. The server does the real check on
  // join; this just tells the player why the button is dead before they click.
  const tooPoor = !!lobby[STAKE] && your_balance < lobby[STAKE];
  // Two different questions, so two different answers. A full arena cannot be joined
  // but can still be watched, and a running one cannot be joined at all because the
  // roster closed - neither of which is a reason to hide Spectate. Hiding both
  // behind `joinable` is what left a guest with a row of dead buttons.
  const joinable = !!lobby[JOINABLE] && !blocked && !tooPoor;
  const spectatable = !blocked;

  let buttons;
  if (isThis) {
    buttons = (
      <Button
        color="average"
        width="100%"
        textAlign="center"
        onClick={() => act('view_lobby', { map })}
      >
        View
      </Button>
    );
  } else if (tooPoor && !!lobby[JOINABLE] && !blocked) {
    buttons = (
      <Stack spacing="0">
        <Button
          color="good"
          width="100%"
          textAlign="center"
          disabled
          tooltip="Entry costs stake. You need more M$."
        >
          {lobby[STAKE]} M$
        </Button>
        <Button
          color="average"
          width="100%"
          textAlign="center"
          onClick={() => act('spectate_lobby', { map })}
        >
          Spectate
        </Button>
      </Stack>
    );
  } else if (joinable) {
    buttons = (
      <Stack spacing="0">
        <Button
          color="good"
          width="100%"
          textAlign="center"
          onClick={() => act('join_lobby', { map })}
        >
          Join
        </Button>
        <Button
          color="average"
          width="100%"
          textAlign="center"
          onClick={() => act('spectate_lobby', { map })}
        >
          Spectate
        </Button>
      </Stack>
    );
  } else if (spectatable) {
    buttons = (
      <Stack spacing="0">
        <Button
          color="good"
          width="100%"
          textAlign="center"
          disabled
          onClick={() => act('join_lobby', { map })}
        >
          {lobby[RUNNING] ? 'Started' : 'Full'}
        </Button>
        <Button
          color="average"
          width="100%"
          textAlign="center"
          onClick={() => act('spectate_lobby', { map })}
        >
          Spectate
        </Button>
      </Stack>
    );
  } else {
    buttons = (
      <Button
        color="good"
        width="100%"
        textAlign="center"
        disabled
        onClick={() => act('view_lobby', { map })}
      >
        In a game
      </Button>
    );
  }

  return (
    <Table.Row className="candystripe">
      <Table.Cell>{lobby[HOST]}</Table.Cell>
      <Table.Cell collapsing>
        {lobby[DISPLAY_NAME]}
        {!!lobby[RUNNING] && (
          <Box as="span" color="average">
            {' '}
            (running)
          </Box>
        )}
        {!!lobby[STAKE] && (
          <Box as="span" color="gold">
            {' '}
            {lobby[STAKE]} M$
          </Box>
        )}
      </Table.Cell>
      <Table.Cell collapsing>
        {lobby[PLAYERS]}/{lobby[MAX]}
        {!!lobby[SPECTATORS] && (
          <Box as="span" color="average">
            {' '}
            +{lobby[SPECTATORS]} watching
          </Box>
        )}
      </Table.Cell>
      <Table.Cell align="center" collapsing>
        {buttons}
      </Table.Cell>
    </Table.Row>
  );
}

/**
 * One Create button per arena.
 *
 * newTG has a single Create Lobby because a ghost picks the arena afterwards, in the
 * lobby window. Here the sleeper's occupant is the only person who may open a game -
 * it is where their real body ends up - so the arena has to be chosen here.
 */
function ModePane(props) {
  const { act, data } = useBackend<PanelData>();
  const { can_create_lobby, in_lobby } = data;
  const { modes = [] } = data;

  return (
    <Section
      title="Open a Lobby"
      buttons={
        <Tooltip
          content={
            in_lobby
              ? 'You are already in a game.'
              : 'Only the person in the sleeper can open one.'
          }
        >
          <Box color={can_create_lobby ? 'average' : 'red'}>
            <Icon name={can_create_lobby ? 'unlock' : 'lock'} />
          </Box>
        </Tooltip>
      }
    >
      {modes.length === 0 && (
        <NoticeBox textAlign="center">No arenas are compiled in.</NoticeBox>
      )}
      {modes.map((mode, index) => (
        <Box key={mode[MODE_NAME] || index} mb="1">
          <Button
            fluid
            textAlign="left"
            color="good"
            disabled={!can_create_lobby}
            onClick={() => act('create_lobby', { mode: mode[MODE_NAME] })}
          >
            <Stack vertical>
              <Stack.Item bold>{mode[MODE_DISPLAY]}</Stack.Item>
              <Stack.Item>
                {mode[MODE_DESC]} &mdash; {mode[MODE_MIN]}-{mode[MODE_MAX]}{' '}
                players
              </Stack.Item>
            </Stack>
          </Button>
        </Box>
      ))}
    </Section>
  );
}

import { classes } from 'common/react';
import { createSearch } from 'common/string';
import { multiline } from 'common/string';

import { resolveAsset } from '../assets';
import { useBackend, useLocalState } from '../backend';
import { Box, Button, Collapsible, Divider, Flex, Icon, Input, Section } from '../components';
import { Window } from '../layouts';

const PATTERN_NUMBER = / \(([0-9]+)\)$/;

const searchFor = searchText => createSearch(searchText, thing => thing.name);

const compareString = (a, b) => a < b ? -1 : a > b;

const compareNumberedText = (a, b) => {
  const aName = a.name;
  const bName = b.name;

  // Check if aName and bName are the same except for a number at the end
  // e.g. Medibot (2) and Medibot (3)
  const aNumberMatch = aName.match(PATTERN_NUMBER);
  const bNumberMatch = bName.match(PATTERN_NUMBER);

  if (aNumberMatch
    && bNumberMatch
    && aName.replace(PATTERN_NUMBER, "") === bName.replace(PATTERN_NUMBER, "")
  ) {
    const aNumber = parseInt(aNumberMatch[1], 10);
    const bNumber = parseInt(bNumberMatch[1], 10);

    return aNumber - bNumber;
  }

  return compareString(aName, bName);
};

const BasicSection = (props, context) => {
  const { act } = useBackend(context);
  const { searchText, source, title } = props;
  const things = source.filter(searchFor(searchText));
  things.sort(compareNumberedText);
  return source.length > 0 && (
    <Collapsible title={`${title} - (${source.length})`} open>
      <Section>
        {things.map(thing => (
          <Button
            key={thing.name}
            content={thing.name}
            onClick={() => act("orbit", {
              ref: thing.ref,
            })} />
        ))}
      </Section>
    </Collapsible>
  );
};

const OrbitedButton = (props, context) => {
  const { act } = useBackend(context);
  const { color, thing } = props;

  return (
    <Button
      color={color}
      onClick={() => act("orbit", {
        ref: thing.ref,
      })}>
      {thing.assignment && (
        <Box inline ml={1}>
          <Box
            className={classes([
              'jobs8x8',
              thing.assignment,
            ])}
            style={{
              transform: 'scale(1.5) translate(-50%, 0)',
            }} />
        </Box>
      )}
      {thing.name}
      {thing.orbiters && (
        <Box inline ml={1}>
          {"("}{thing.orbiters}{" "}
          <Box
            as="img"
            src={resolveAsset('ghost.png')}
            opacity={0.7} />
          {")"}
        </Box>
      )}
    </Button>
  );
};

export const Orbit = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    alive,
    antagonists,
    auto_observe,
    compact_mode,
    dead,
    dead_players,
    ghosts,
    misc,
    npcs,
    ghost_roles,
  } = data;

  const [searchText, setSearchText] = useLocalState(context, "searchText", "");

  const collatedAntagonists = {};
  for (const antagonist of antagonists) {
    if (collatedAntagonists[antagonist.antag] === undefined) {
      collatedAntagonists[antagonist.antag] = [];
    }
    collatedAntagonists[antagonist.antag].push(antagonist);
  }

  const sortedAntagonists = Object.entries(collatedAntagonists);
  sortedAntagonists.sort((a, b) => {
    return compareString(a[0], b[0]);
  });

  const collatedGhostRoles = {};
  for (const ghostRole of ghost_roles) {
    if (collatedGhostRoles[ghostRole.role] === undefined) {
      collatedGhostRoles[ghostRole.role] = [];
    }
    collatedGhostRoles[ghostRole.role].push(ghostRole);
  }

  const sortedGhostRoles= Object.entries(collatedGhostRoles);
  sortedGhostRoles.sort((a, b) => {
    return compareString(a[0], b[0]);
  });

  const orbitMostRelevant = searchText => {
    for (const source of [
      sortedAntagonists.map(([_, antags]) => antags),
      alive, ghosts, dead, dead_players, npcs, misc,
      sortedGhostRoles.map(([_, ghostRoles]) => ghostRoles),
    ]) {
      const member = source
        .filter(searchFor(searchText))
        .sort(compareNumberedText)[0];
      if (member !== undefined) {
        act("orbit", { ref: member.ref });
        break;
      }
    }
  };

  return (
    <Window
      title="Orbit"
      width={500}
      height={800}>
      <Window.Content overflow="auto">
        <Section>
          <Flex>
            <Flex.Item>
              <Icon
                name="search"
                mr={1} />
            </Flex.Item>
            <Flex.Item grow={1}>
              <Input
                placeholder="Search..."
                autoFocus
                fluid
                value={searchText}
                onInput={(_, value) => setSearchText(value)}
                onEnter={(_, value) => orbitMostRelevant(value)} />
            </Flex.Item>
            <Flex.Item>
              <Divider vertical />
            </Flex.Item>
            <Flex.Item>
              <Button
                inline
                color="transparent"
                tooltip={multiline`Toggle Auto-Observe. When active, you'll
                see the UI / full inventory of whoever you're orbiting. Neat!`}
                tooltipPosition="bottom-start"
                selected={auto_observe}
                icon={auto_observe ? "toggle-on" : "toggle-off"}
                onClick={() => act("toggle_observe")} />
              <Button
                inline
                color="transparent"
                tooltip="Прячет всё, что не связано с игроками."
                tooltipPosition="bottom-start"
                selected={compact_mode}
                icon={compact_mode ? "lock" : "lock-open"}
                onClick={() => act("toggle_compact_mode")} />
              <Button
                inline
                color="transparent"
                tooltip="Refresh"
                tooltipPosition="bottom-start"
                icon="sync-alt"
                onClick={() => act("refresh")} />
            </Flex.Item>
          </Flex>
        </Section>
        {antagonists.length > 0 && (
          <Collapsible title={`Ghost-Visible Antagonists - (${antagonists.length})`} open>
            <Section>
              {sortedAntagonists.map(([name, antags]) => (
                <Section key={name} title={`${name} - (${antags.length})`} level={2}>
                  {antags
                    .filter(searchFor(searchText))
                    .sort(compareNumberedText)
                    .map(antag => (
                      <OrbitedButton
                        key={antag.name}
                        color="bad"
                        thing={antag}
                      />
                    ))}
                </Section>
              ))}
            </Section>
          </Collapsible>
        )}

        {ghost_roles.length > 0 && (
          <Collapsible title={`Ghost Roles - (${ghost_roles.length})`}>
            <Section>
              {sortedGhostRoles.map(([name, ghostRoles]) => (
                <Section key={name} title={`${name} - (${ghostRoles.length})`} level={2}>
                  {ghostRoles
                    .filter(searchFor(searchText))
                    .sort(compareNumberedText)
                    .map(ghostRole => (
                      <OrbitedButton
                        key={ghostRole.name}
                        color="violet"
                        thing={ghostRole}
                      />
                    ))}
                </Section>
              ))}
            </Section>
          </Collapsible>
        )}

        <Collapsible title={`Alive - (${alive.length})`} open>
          <Section>
            {alive
              .filter(searchFor(searchText))
              .sort(compareNumberedText)
              .map(thing => (
                <OrbitedButton
                  key={thing.name}
                  color="good"
                  thing={thing} />
              ))}
          </Section>
        </Collapsible>

        <Collapsible title={`Ghosts - (${ghosts.length})`} open>
          <Section>
            {ghosts
              .filter(searchFor(searchText))
              .sort(compareNumberedText)
              .map(thing => (
                <OrbitedButton
                  key={thing.name}
                  color="grey"
                  thing={thing} />
              ))}
          </Section>
        </Collapsible>

        <BasicSection
          title="Dead Players"
          source={dead_players}
          searchText={searchText}
        />

        {!compact_mode && (
          <>
          <BasicSection
            title="Dead"
            source={dead}
            searchText={searchText}
          />

          <BasicSection
            title="NPCs"
            source={npcs}
            searchText={searchText}
          />

          <BasicSection
            title="Misc"
            source={misc}
            searchText={searchText}
          />
          </>
        )}
      </Window.Content>
    </Window>
  );
};

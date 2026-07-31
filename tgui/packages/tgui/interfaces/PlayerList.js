import { useBackend, useLocalState } from '../backend';
import { Box, Button, Flex, Icon, Input, Section } from '../components';
import { Window } from '../layouts';

const getBadges = (p) => {
  const badges = [];
  if (p._hasGhostRole) badges.push({ label: 'ГОСТРОЛЬ', color: '#ab47bc' });
  if (p._hasObserver) badges.push({ label: '👻', color: '#78909c' });
  if (p._hasNewPlayer) badges.push({ label: 'ЛОББИ', color: '#ffa726' });
  if (p._mergedStat !== null && p._mergedStat !== undefined) {
    if (p._mergedStat === 2) badges.push({ label: 'МЁРТВ', color: '#b71c1c' });
    else if (p._mergedStat === 1) badges.push({ label: 'КОМА', color: '#ff1744' });
    else badges.push({ label: 'ЖИВ', color: '#2e7d32' });
  }
  return badges;
};

const filterModes = [
  { key: 'all', label: 'Все' },
  { key: 'antag', label: 'Антагонисты' },
  { key: 'targets', label: 'Цели' },
];

export const PlayerList = (props, context) => {
  const { act, data } = useBackend();
  const { players = [], total = 0 } = data;

  const [search, setSearch] = useLocalState('playerlist_search', '');
  const [filterMode, setFilterMode] = useLocalState('playerlist_filterMode', 'all');
  const [secCmdOnly, setSecCmdOnly] = useLocalState('playerlist_secCmd', false);

  const sortOrder = (p) => {
    let order = 0;
    if (p.antag) order -= 1000;
    if (p.is_sec_or_cmd) order -= 500;
    if (p._hasGhostRole) order += 500;
    return order;
  };

  const lowerSearch = search.toLowerCase();

  const ckeyGroups = new Map();
  for (const p of players) {
    const group = ckeyGroups.get(p.key);
    if (group) group.push(p);
    else ckeyGroups.set(p.key, [p]);
  }

  const merged = [];
  for (const [, entries] of ckeyGroups) {
    const primary = entries.find(e => !e.is_observer && !e.is_new_player) || entries[0];
    const bodies = entries.filter(e => !e.is_observer && !e.is_new_player);
    const mergedStat = bodies.length > 0 ? Math.min(...bodies.map(e => e.stat)) : null;
    merged.push({
      ...primary,
      _hasGhostRole: entries.some(e => e.is_ghost_role),
      _hasObserver: entries.some(e => e.is_observer && !e.is_new_player),
      _hasNewPlayer: entries.some(e => e.is_new_player),
      _mergedStat: mergedStat,
      antag: entries.some(e => e.antag),
      is_cyborg: entries.some(e => e.is_cyborg),
      is_sec_or_cmd: entries.some(e => e.is_sec_or_cmd),
    });
  }

  const processed = merged
    .filter((p) => {
      if (!lowerSearch) return true;
      return (
        (p.name && p.name.toLowerCase().includes(lowerSearch))
        || (p.real_name && p.real_name.toLowerCase().includes(lowerSearch))
        || (p.key && p.key.toLowerCase().includes(lowerSearch))
        || (p.job && p.job.toLowerCase().includes(lowerSearch))
      );
    })
    .filter((p) => {
      if (secCmdOnly && !p.is_sec_or_cmd) return false;
      if (filterMode === 'antag' && !p.antag) return false;
      if (filterMode === 'targets') {
        if (p.antag || p._hasGhostRole || p.is_observer || p.is_new_player) return false;
      }
      return true;
    })
    .sort((a, b) => sortOrder(a) - sortOrder(b));

  return (
    <Window title="Player Panel" width={950} height={700} resizable>
      <Window.Content scrollable>
        <Section>
          <Box
            textAlign="center"
            fontSize="24px"
            bold
            m={1.5}
            style={{ color: '#98B0C3', textShadow: '1px 1px 3px #000' }}
          >
            <Icon name="users" mr={1} />
            Панель игроков
          </Box>

          <Flex align="center" justify="center" wrap mb={2}>
            <Box fontSize="13px" style={{ color: '#8a9bae' }}>
              <Button
                icon="user-secret"
                color="transparent"
                tooltip="Открыть список антагонистов"
                style={{
                  color: '#b0bec5',
                  padding: '4px 8px',
                  margin: 0,
                  border: '1px solid #546e7a',
                  borderRadius: '4px',
                }}
                onClick={() => act('check_antagonists')}
              >
                Проверить антагонистов
              </Button>
              {' '}
              <Button
                icon="sign-out-alt"
                color="transparent"
                tooltip="Выгнать всех из лобби"
                style={{
                  color: '#b0bec5',
                  padding: '4px 8px',
                  margin: 0,
                  border: '1px solid #546e7a',
                  borderRadius: '4px',
                }}
                onClick={() => act('kick_all_from_lobby', { afkonly: 0 })}
              >
                Выгнать всех
              </Button>
              {' '}
              <Button
                icon="clock"
                color="transparent"
                tooltip="Выгнать только AFK из лобби"
                style={{
                  color: '#b0bec5',
                  padding: '4px 8px',
                  margin: 0,
                  border: '1px solid #546e7a',
                  borderRadius: '4px',
                }}
                onClick={() => act('kick_all_from_lobby', { afkonly: 1 })}
              >
                Выгнать AFK
              </Button>
            </Box>
          </Flex>

          <Flex align="center" gap={1} mb={1}>
            {filterModes.map((fm) => (
              <Button
                key={fm.key}
                compact
                selected={filterMode === fm.key}
                style={{
                  color: filterMode === fm.key ? '#4fc3ff' : '#aaa',
                  border: `1px solid ${filterMode === fm.key ? '#4fc3ff' : '#444'}`,
                  backgroundColor: filterMode === fm.key ? '#4fc3ff18' : 'transparent',
                }}
                onClick={() => setFilterMode(fm.key)}
              >
                {fm.label}
              </Button>
            ))}
            <Box mx={0.5} style={{ color: '#444' }}>|</Box>
            <Button
              compact
              selected={secCmdOnly}
              style={{
                color: secCmdOnly ? '#ffd54f' : '#aaa',
                border: `1px solid ${secCmdOnly ? '#ffd54f' : '#444'}`,
                backgroundColor: secCmdOnly ? '#ffd54f18' : 'transparent',
              }}
              onClick={() => setSecCmdOnly(!secCmdOnly)}
            >
              СБ+КМД
            </Button>
          </Flex>

          <Flex align="center" gap={1} mb={2}>
            <Flex.Item>
              <b style={{ fontSize: '14px' }}>
                <Icon name="search" mr={0.5} />
                Поиск:
              </b>
            </Flex.Item>
            <Flex.Item width="50%">
              <Input
                width="100%"
                placeholder="Введите имя, ckey или должность..."
                value={search}
                onInput={(e, value) => setSearch(value)}
              />
            </Flex.Item>
            <Flex.Item grow={1} />
            <Flex.Item>
              <Box
                px={1.5}
                py={0.5}
                style={{
                  backgroundColor: '#222',
                  borderRadius: '4px',
                  color: '#888',
                  fontSize: '13px',
                }}
              >
                <Icon name="user" mr={0.5} />
                {processed.length}/{total}
              </Box>
            </Flex.Item>
          </Flex>
        </Section>

        {processed.length === 0 && (
          <Box
            textAlign="center"
            py={8}
            style={{ color: '#555', fontSize: '16px' }}
          >
            <Icon name="ghost" size={2.5} mb={1.5} />
            <Box>Нет игроков по вашему запросу.</Box>
          </Box>
        )}

        {processed.map((p) => (
          <PlayerCard key={p.ref} player={p} act={act} />
        ))}
      </Window.Content>
    </Window>
  );
};

const ACTION_ROWS = [
  [
    { key: 'open_pp', icon: 'user', label: 'PP', tooltip: 'Player Panel', color: '#5695d6' },
    { key: 'open_vv', icon: 'eye', label: 'VV', tooltip: 'View Variables', color: '#ff9800' },
    { key: 'open_tp', icon: 'user-secret', label: 'TP', tooltip: 'Traitor Panel', color: '#9c27b0' },
  ],
  [
    { key: 'open_sm', icon: 'volume-up', label: 'SM', tooltip: 'Subtle Message', color: '#e91e63' },
    { key: 'open_flw', icon: 'arrow-right', label: 'FLW', tooltip: 'Следовать', color: '#4caf50' },
    { key: 'open_logs', icon: 'book', label: 'LOGS', tooltip: 'Логи', color: '#795548' },
    { key: 'open_ban', icon: 'gavel', label: 'BAN', tooltip: 'Забанить', color: '#f44336' },
  ],
  [
    { key: 'open_pm', icon: 'comment', label: 'PM', tooltip: 'Приватное сообщение', color: '#00bcd4' },
    { key: 'open_notes', icon: 'sticky-note', label: 'N', tooltip: 'Заметки', color: '#8bc34a' },
    { key: 'open_kick', icon: 'ban', label: 'KICK', tooltip: 'Выгнать', color: '#ff7043' },
  ],
];

const PlayerCard = (props) => {
  const { player: p, act } = props;
  const isAntag = !!p.antag;
  const badges = getBadges(p);

  const rows = ACTION_ROWS.map((row) => {
    let items = [...row];
    if (p.is_cyborg) {
      const bp = { key: 'open_bp', icon: 'robot', label: 'BP', tooltip: 'Borg Panel', color: '#607d8b' };
      if (row === ACTION_ROWS[0]) {
        items = [...items, bp];
      }
    }
    return items;
  });

  return (
    <Section>
      <Flex direction="row" gap={1}>
        <Flex.Item grow={1}>
          <Flex direction="column" gap={0.5}>
            <Flex.Item>
              <Flex align="center" wrap gap={0.5}>
                <Box
                  fontSize="18px"
                  bold
                  style={{
                    color: isAntag ? '#ff6b6b' : '#e0e0e0',
                    textShadow: isAntag ? '0 0 5px rgba(255,0,0,0.35)' : 'none',
                  }}
                >
                  {isAntag && (
                    <Icon name="skull" mr={0.5} style={{ color: '#ff4444' }} />
                  )}
                  {p.key}
                </Box>
                <Box ml={1}>
                  {isAntag && (
                    <Box
                      as="span"
                      px={1}
                      py={0.3}
                      fontSize="12px"
                      bold
                      style={{
                        color: '#fff',
                        backgroundColor: '#ff4444',
                        borderRadius: '3px',
                        textTransform: 'uppercase',
                      }}
                    >
                      АНТАГОНИСТ
                    </Box>
                  )}
                  {badges.map((b, i) => (
                    <Box
                      key={i}
                      as="span"
                      px={1}
                      py={0.3}
                      fontSize="11px"
                      bold
                      ml={0.5}
                      style={{
                        color: '#fff',
                        backgroundColor: b.color,
                        borderRadius: '3px',
                      }}
                    >
                      {b.label}
                    </Box>
                  ))}
                </Box>
              </Flex>
            </Flex.Item>

            <Flex.Item ml={1}>
              <Flex direction="column" gap={0.4}>
                <Flex.Item>
                  <Box fontSize="13px" style={{ color: '#aaa' }}>
                    <Icon name="briefcase" mr={0.8} color="#78909c" />
                    Должность: <b>{p.job || 'Неизвестно'}</b>
                    {' | '}
                    <Icon name="tag" mr={0.5} color="#78909c" />
                    Имя: <b>{p.name}</b>
                    {' | '}
                    <Icon name="user-circle" mr={0.5} color="#78909c" />
                    <b>{p.real_name}</b>
                  </Box>
                </Flex.Item>
                <Flex.Item>
                  <Box fontSize="12px" style={{ color: '#777' }}>
                    <Icon name="globe" mr={0.8} color="#78909c" />
                    {p.ip || '0.0.0.0'} / CID: {p.cid || '?'}
                  </Box>
                </Flex.Item>
              </Flex>
            </Flex.Item>
          </Flex>
        </Flex.Item>

        <Flex.Item shrink={0} style={{ alignSelf: 'flex-start' }}>
          <Flex direction="column" gap={0.4}
            px={1}
            py={0.7}
            style={{
              backgroundColor: '#1a1a1a',
              borderRadius: '4px',
            }}
          >
            {rows.map((row, ri) => (
              <Flex.Item key={ri}>
                <Flex align="center" gap={0.5} wrap>
                  {row.map((btn) => (
                    <Button
                      key={btn.key}
                      icon={btn.icon}
                      tooltip={btn.tooltip}
                      compact
                      style={{
                        color: btn.color,
                        border: `1px solid ${btn.color}44`,
                        backgroundColor: `${btn.color}18`,
                      }}
                      onClick={() => act(btn.key, { ref: p.ref })}
                    >
                      {btn.label}
                    </Button>
                  ))}
                </Flex>
              </Flex.Item>
            ))}
          </Flex>
        </Flex.Item>
      </Flex>
    </Section>
  );
};

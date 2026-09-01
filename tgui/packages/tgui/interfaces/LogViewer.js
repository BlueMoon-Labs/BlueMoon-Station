import { useCallback, useEffect, useRef, useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Dropdown, Flex, Icon, Input, Section } from '../components';
import { Window } from '../layouts';

const stripHtml = (str) => {
  if (!str) return str;
  return String(str).replace(/<[^>]*>/g, '').trim();
};

const extractAreaName = (whereStr) => {
  if (!whereStr) return '';
  const match = whereStr.match(/^(.*?)\s*\(\d+,\s*\d+,\s*\d+\)/);
  return match ? match[1].trim() : whereStr.trim();
};

const LOG_COLORS = {
  Attack: '#ff6b6b',
  Say: '#4dd0e1',
  Emote: '#64b5f6',
  Comms: '#90a4ae',
  OOC: '#5b9bd5',
  Admin: '#ef5350',
  Game: '#66bb6a',
  Deadchat: '#ce93d8',
  Mecha: '#ffb74d',
  Virus: '#81c784',
  Shuttle: '#ffd54f',
  Whisper: '#b39ddb',
  Victim: '#ff8a65',
};

const getLogColor = (type) => LOG_COLORS[type] || 'gray';

export const LogViewer = (props) => {
  const { act, data } = useBackend();
  const {
    logs = [],
    log_count = 0,
    log_count_total = 0,
    target_name,
    target_ckey,
    source_type,
    filter_text,
    target_filter: targetFilter = '',
    zone_filter: zoneFilter = '',
    viewing_type,
    log_types = [],
    source_options = [],
    ckeys_list = [],
  } = data;

  const debounceRef = useRef(null);
  const intervalRef = useRef(null);
  const logsArray = Array.isArray(logs) ? logs : [];
  const safeLogCount = logsArray.length;
  const [autoRefresh, setAutoRefresh] = useState(true);

  useEffect(() => {
    if (autoRefresh) {
      intervalRef.current = setInterval(() => act('refresh'), 3000);
    }
    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
        intervalRef.current = null;
      }
    };
  }, [autoRefresh, act]);

  const debouncedAct = useCallback((action, payload, delay = 120) => {
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(() => act(action, payload), delay);
  }, [act]);

  const handleCkeySelect = (ckey) => {
    act('select_ckey', { ckey });
  };

  const handleKeyDown = useCallback((e) => {
    if (e.key === 'Escape') {
      if (filter_text || targetFilter || zoneFilter) {
        act('set_filter', { text: '' });
        act('set_target_filter', { text: '' });
        act('set_zone_filter', { text: '' });
      }
    }
  }, [filter_text, targetFilter, zoneFilter, act]);

  const showAllFlag = log_types.find(
    (t) => t.name === 'Показать все' || t.name === 'Show All'
  )?.flag;
  const isShowAll = viewing_type === showAllFlag;
  const handleClearText = useCallback(() => act('set_filter', { text: '' }), [act]);
  const handleClearTarget = useCallback(() => act('set_target_filter', { text: '' }), [act]);
  const handleClearZone = useCallback(() => act('set_zone_filter', { text: '' }), [act]);
  const handleClearType = useCallback(() => {
    if (showAllFlag !== undefined) act('set_viewing_type', { type: showAllFlag });
  }, [act, showAllFlag]);

  const handleTypeClick = (flag) => {
    if (flag === showAllFlag) {
      act('set_viewing_type', { type: showAllFlag });
      return;
    }
    if (isShowAll) {
      act('set_viewing_type', { type: flag });
    } else {
      const newType = viewing_type ^ flag;
      act('set_viewing_type', { type: newType || showAllFlag });
    }
  };

  return (
    <Window title="Log Viewer" width={1100} height={700} resizable>
      <Window.Content scrollable tabIndex={0} onKeyDown={handleKeyDown}>
        <Section>
          <Flex direction="column" gap={0.5}>
            <Flex.Item>
              <Flex align="center" gap={1}>
                <Flex.Item shrink={0}>
                  <Box inline bold mr={0.5}
                    style={{ color: '#aaa', fontSize: '13px' }}>
                    Игрок:
                  </Box>
                </Flex.Item>
                <Flex.Item grow={1}>
                  <Dropdown
                    width="100%"
                    placeholder="Выберите игрока..."
                    selected={target_ckey}
                    options={ckeys_list}
                    onSelected={handleCkeySelect}
                  />
                </Flex.Item>
                <Flex.Item shrink={0}>
                  <Button
                    icon="user"
                    color="transparent"
                    tooltip="Открыть панель игрока"
                    style={{
                      color: '#999',
                      border: '1px solid #444',
                      padding: '3px 8px',
                    }}
                    onClick={() => act('open_pp')}
                  >
                    {target_name || 'Нет'}
                  </Button>
                </Flex.Item>
              </Flex>
            </Flex.Item>

            <Flex.Item style={{ width: '100%' }}>
              <Flex align="center" gap={1} style={{ width: '100%' }}>
                <Flex.Item shrink={0}>
                  <Box inline bold mr={0.5}
                    style={{ color: '#aaa', fontSize: '13px' }}>
                    Источник:
                  </Box>
                  {source_options.map((src) => {
                    const srcColor = src === 'CLIENT' ? '#4fc3ff' : '#81c784';
                    const isSelected = source_type === src;
                    return (
                      <Button
                        key={src}
                        content={src}
                        compact
                        style={{
                          color: isSelected ? srcColor : srcColor + '77',
                          fontWeight: isSelected ? 'bold' : 'normal',
                          border: `1px solid ${isSelected ? srcColor : 'transparent'}`,
                          backgroundColor: 'transparent',
                        }}
                        onClick={() => act('set_source', { source: src })}
                      />
                    );
                  })}
                </Flex.Item>
                <Flex.Item grow={1} style={{ minWidth: 0 }} />
                <Flex.Item shrink={0}>
                  <Input
                    width="150px"
                    placeholder="Поиск..."
                    value={filter_text}
                    onInput={(e, value) =>
                      debouncedAct('set_filter', { text: value })
                    }
                  />
                </Flex.Item>
                <Flex.Item shrink={0}>
                  <Input
                    width="180px"
                    placeholder="Цель (игрок 2)..."
                    value={targetFilter}
                    onInput={(e, value) =>
                      debouncedAct('set_target_filter', { text: value })
                    }
                  />
                </Flex.Item>
              </Flex>
            </Flex.Item>

            <Flex.Item>
              <Flex align="center" gap={0.5} wrap>
                <Box inline bold mr={0.5}
                  style={{ color: '#aaa', fontSize: '13px' }}>
                  Тип:
                </Box>
                {log_types.map((lt) => {
                  const isSelected = lt.flag === showAllFlag ? isShowAll : (viewing_type & lt.flag);
                  return (
                    <Button
                      key={lt.flag}
                      compact
                      style={{
                        color: isSelected ? lt.color : lt.color + '77',
                        fontWeight: isSelected ? 'bold' : 'normal',
                        border: `1px solid ${isSelected ? lt.color : lt.color + '44'}`,
                        backgroundColor: 'transparent',
                        opacity: lt.flag === showAllFlag && !isSelected ? 0.45 : 1,
                      }}
                      content={lt.name}
                      onClick={() => handleTypeClick(lt.flag)}
                    />
                  );
                })}
              </Flex>
            </Flex.Item>

            {(filter_text || targetFilter || zoneFilter) && (
              <Flex.Item>
                <Flex align="center" gap={0.5}>
                  <Box style={{ color: '#999', fontSize: '11px' }}>
                    Фильтры:
                  </Box>
                  {filter_text && (
                    <Box
                      as="span"
                      ml={0.5}
                      px={0.5}
                      py={0.2}
                      fontSize="10px"
                      style={{
                        color: '#ffd54f',
                        backgroundColor: '#ffd54f22',
                        border: '1px solid #ffd54f44',
                        borderRadius: '3px',
                        cursor: 'pointer',
                      }}
                      onClick={handleClearText}
                    >
                      текст: {filter_text} ×
                    </Box>
                  )}
                  {targetFilter && (
                    <Box
                      as="span"
                      ml={0.5}
                      px={0.5}
                      py={0.2}
                      fontSize="10px"
                      style={{
                        color: '#ffd54f',
                        backgroundColor: '#ffd54f22',
                        border: '1px solid #ffd54f44',
                        borderRadius: '3px',
                        cursor: 'pointer',
                      }}
                      onClick={handleClearTarget}
                    >
                      цель: {targetFilter} ×
                    </Box>
                  )}
                  {zoneFilter && (
                    <Box
                      as="span"
                      ml={0.5}
                      px={0.5}
                      py={0.2}
                      fontSize="10px"
                      style={{
                        color: '#81c784',
                        backgroundColor: '#81c78422',
                        border: '1px solid #81c78444',
                        borderRadius: '3px',
                        cursor: 'pointer',
                      }}
                      onClick={handleClearZone}
                    >
                      зона: {zoneFilter} ×
                    </Box>
                  )}
                </Flex>
              </Flex.Item>
            )}
          </Flex>
        </Section>

        <Section
          title={"Лог (" + safeLogCount + " записей)"}
          buttons={
            <Flex align="center" gap={0.5}>
              <Button.Checkbox
                checked={autoRefresh}
                content="Авто"
                tooltip="Автообновление каждые 3 сек"
                onClick={() => setAutoRefresh(!autoRefresh)}
              />
              <Button
                icon="sync"
                content="Обновить"
                onClick={() => act('refresh')}
              />
            </Flex>
          }
        >
          {!target_ckey && (
            <Box style={{ color: '#555', textAlign: 'center', py: 6, fontSize: '14px' }}>
              <Icon name="chevron-circle-up" mr={1} />
              Выберите игрока из списка выше
            </Box>
          )}
          {target_ckey && safeLogCount === 0 && (
            <Box style={{ color: '#555', textAlign: 'center', py: 6, fontSize: '14px' }}>
              <Icon name="search" mr={1} />
              Логов не найдено
            </Box>
          )}
          {logsArray.slice().reverse().map((entry, i) => (
            <LogEntry key={entry.time + entry.who + entry.type + i} entry={entry} act={act} />
          ))}
        </Section>
      </Window.Content>
    </Window>
  );
};

const LogEntry = (props) => {
  const { entry, act } = props;
  const {
    time = '??:??:??',
    who = 'unknown',
    what = '',
    where = '',
    type = 'Misc',
    health = null,
    color = null,
    target_name = null,
    target_key = null,
  } = entry;

  const typeColor = getLogColor(type);
  const hasTarget = target_name || target_key;
  const areaName = extractAreaName(where);

  return (
    <Box
      mb={0.5}
      px={1.5}
      py={0.8}
      style={{
        borderLeft: `4px solid ${typeColor}`,
        borderBottom: '1px solid #1a1a1a',
        backgroundColor: '#0a0a0a',
        fontFamily: 'monospace',
        fontSize: '12px',
        lineHeight: '1.5',
        transition: 'background-color 0.1s',
      }}
    >
      <Flex align="flex-start" gap={0.5}>
        <Flex.Item shrink={0}
          style={{ color: '#b0b0b0', minWidth: '58px', fontSize: '11px', fontWeight: 'bold' }}>
          {time}
        </Flex.Item>
        <Flex.Item shrink={0}>
          <Box
            px={0.5}
            style={{
              color: typeColor,
              fontSize: '10px',
              fontWeight: 'bold',
              textTransform: 'uppercase',
              letterSpacing: '0.5px',
              opacity: 0.8,
            }}
          >
            {type}
          </Box>
        </Flex.Item>
        <Flex.Item grow={1}
          style={{
            color: color || '#ccc',
            textShadow: color ? '0 0 3px rgba(0,0,0,0.8)' : 'none',
            wordBreak: 'break-word',
          }}>
          {stripHtml(what)}
        </Flex.Item>
        <Flex.Item shrink={0}
          style={{
            color: '#666',
            minWidth: '100px',
            textAlign: 'right',
            fontSize: '11px',
          }}>
          {who}
        </Flex.Item>
      </Flex>
      <Flex mt={0.3} align="center" wrap>
        <Flex.Item style={{ color: '#aaa', fontSize: '11px' }}>
          {where && (
            <>
              <Box
                as="span"
                style={{
                  cursor: 'pointer',
                  borderBottom: '1px dashed #666',
                }}
                onClick={() => act('set_zone_filter', { text: areaName })}
              >
                {areaName}
              </Box>
              {where.substring(areaName.length)}
            </>
          )}
          {!where && '—'}
          {health !== null && health !== undefined && (
            <Box as="span" ml={1.5}
              style={{ color: '#ff8c00', fontWeight: 'bold' }}>
              HP: {health}
            </Box>
          )}
        </Flex.Item>
        {hasTarget && (
          <Flex.Item grow={1} />
        )}
        {hasTarget && (
          <Flex.Item>
            <Box
              as="span"
              px={0.5}
              py={0.2}
              style={{
                fontSize: '10px',
                color: '#4fc3ff',
                backgroundColor: '#4fc3ff15',
                border: '1px solid #4fc3ff33',
                borderRadius: '3px',
                cursor: 'pointer',
              }}
              onClick={() => act('set_target_filter', { text: target_key || target_name })}
            >
              <Icon name="crosshairs" mr={0.3} />
              {target_key || target_name}
            </Box>
          </Flex.Item>
        )}
      </Flex>
    </Box>
  );
};
import { createSearch } from 'common/string';
import { vecLength, vecSubtract } from 'common/vector';

import { useBackend, useLocalState } from '../backend';
import { Box, Button, ColorBox, Icon, Input, NoticeBox, Section, Stack, Table, Tabs, Tooltip } from '../components';
import { COLORS } from '../constants';
import { Window } from '../layouts';
import { StationMap } from './common/StationMap';

const HEALTHY_COLOR = '#17d568';
const DEAD_COLOR = '#ed2814';
const DAMAGE_COLORS = ['#ffeb3b', '#ffc107', '#ff9800'];
const DAMAGE_PULSE_DURATIONS = ['3s', '1.5s', '0.7s'];

const CrewJobIcon = ({ jobIcon, color }) => {
  const dead = color === DEAD_COLOR;
  const damageLevel = DAMAGE_COLORS.indexOf(color);
  return (
    <span className="CrewConsole__jobIconFrame">
      <Box
        className={`jobs8x8 ${jobIcon || 'no_id'} CrewConsole__jobIcon${dead ? ' CrewConsole__jobIcon--dead' : ''}${damageLevel >= 0 ? ' CrewConsole__jobIcon--damaged' : ''}`}
        style={damageLevel >= 0 ? {
          animationDuration: DAMAGE_PULSE_DURATIONS[damageLevel],
        } : undefined} />
      {damageLevel >= 0 && (
        <span
          className="CrewConsole__damageDot"
          aria-hidden="true"
          style={{ backgroundColor: color }} />
      )}
      {dead && (
        <span className="CrewConsole__deathBadge" aria-hidden="true">
          <Icon name="skull" />
        </span>
      )}
    </span>
  );
};

const jobIsHead = jobId => jobId % 10 === 0;

const jobToColor = jobId => {
  if (jobId === 0) {
    return COLORS.department.captain;
  }
  if (jobId >= 10 && jobId < 20) {
    return COLORS.department.security;
  }
  if (jobId >= 20 && jobId < 30) {
    return COLORS.department.medbay;
  }
  if (jobId >= 30 && jobId < 40) {
    return COLORS.department.science;
  }
  if (jobId >= 40 && jobId < 50) {
    return COLORS.department.engineering;
  }
  if (jobId >= 50 && jobId < 60) {
    return COLORS.department.cargo;
  }
  if (jobId >= 200 && jobId < 230) {
    return COLORS.department.centcom;
  }
  return COLORS.department.other;
};

const healthToColor = (oxy, tox, burn, brute, life_status) => {
  if (life_status === false || life_status === 0) {
    return DEAD_COLOR;
  }
  const healthSum = (oxy ?? 0) + (tox ?? 0) + (burn ?? 0) + (brute ?? 0);
  if (healthSum < 40) {
    return HEALTHY_COLOR;
  }
  // Ступени повреждений: 40–79, 80–119 и от 120; красный оставляем смерти.
  const level = Math.min(Math.floor(healthSum / 40) - 1, DAMAGE_COLORS.length - 1);
  return DAMAGE_COLORS[level];
};

const HealthStat = props => {
  const { type, value } = props;
  return (
    <Box
      inline
      width={2}
      color={COLORS.damageType[type]}
      textAlign="center">
      {value}
    </Box>
  );
};

export const CrewConsole = () => {
  const { act, data } = useBackend();
  const [tab, setTab] = useLocalState('crewTab', 'list');
  // Отметки привязаны к UID моба: одинаковые имена не объединяются, переименование сохраняет отметку.
  const highlightedIds = data.highlighted_ids || [];
  const toggleHighlight = id => act('toggle_highlight', { id });
  const clearHighlights = () => act('clear_highlights');
  const highlightProps = { highlightedIds, clearHighlights, toggleHighlight };
  return (
    <Window
      title="Монитор экипажа"
      width={800}
      height={600}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Tabs>
              <Tabs.Tab
                icon="table"
                selected={tab === 'list'}
                onClick={() => setTab('list')}>
                Данные экипажа
              </Tabs.Tab>
              <Tabs.Tab
                icon="map-marked-alt"
                selected={tab === 'map'}
                onClick={() => setTab('map')}>
                Карта
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item grow>
            {tab === 'list' ? (
              <Section fill scrollable>
                <CrewTable {...highlightProps} />
              </Section>
            ) : (
              <CrewMap {...highlightProps} />
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const CrewTable = (props) => {
  const { data } = useBackend();
  const { highlightedIds, clearHighlights, toggleHighlight } = props;
  const [search, setSearch] = useLocalState('crewSearch', '');
  const sensors = data.sensors || [];
  const searcher = createSearch(search, sensor => (
    `${sensor.name}|${sensor.assignment || ''}|${sensor.area || ''}`
  ));
  const highlighted = new Set(highlightedIds);
  const matchingSensors = sensors.filter(searcher);
  const filteredSensors = [
    ...matchingSensors.filter(sensor => highlighted.has(sensor.id)),
    ...matchingSensors.filter(sensor => !highlighted.has(sensor.id)),
  ];
  return (
    <>
      <Input
        fluid
        mb={1}
        value={search}
        placeholder="Поиск по имени, должности или локации..."
        onInput={(e, value) => setSearch(value)} />
      <Table>
        <Table.Row>
          <Table.Cell collapsing>
            <Button
              className="CrewConsole__plainButton"
              color="transparent"
              icon="times"
              tooltip="Снять все отметки"
              disabled={!highlightedIds.length}
              onClick={clearHighlights} />
          </Table.Cell>
          <Table.Cell bold>
            Имя
          </Table.Cell>
          <Table.Cell bold collapsing />
          <Table.Cell bold collapsing textAlign="center">
            Показатели
          </Table.Cell>
          <Table.Cell bold>
            Локация
          </Table.Cell>
          <Table.Cell bold collapsing>
            Направление
          </Table.Cell>
          {!!data.link_allowed && (
            <Table.Cell bold collapsing>
              Слежение
            </Table.Cell>
          )}
        </Table.Row>
        {filteredSensors.map(sensor => (
          <CrewTableEntry
            sensor_data={sensor}
            key={sensor.id}
            highlighted={highlighted.has(sensor.id)}
            toggleHighlight={toggleHighlight} />
        ))}
      </Table>
      {!filteredSensors.length && (
        <NoticeBox mt={1}>
          {sensors.length ? 'Никто не найден.' : 'Нет доступных датчиков.'}
        </NoticeBox>
      )}
    </>
  );
};

const CrewTableEntry = (props) => {
  const { act, data } = useBackend();
  const { link_allowed } = data;
  const { sensor_data, highlighted, toggleHighlight } = props;
  const {
    id,
    name,
    assignment,
    ijob,
    life_status,
    oxydam,
    toxdam,
    burndam,
    brutedam,
    area,
    pos_x,
    pos_y,
    pos_z,
    floor,
    can_track,
  } = sensor_data;
  const color = healthToColor(oxydam, toxdam, burndam, brutedam, life_status);

  return (
    <Table.Row className={highlighted && 'CrewConsole__highlightedRow'}>
      <Table.Cell collapsing>
        <Button.Checkbox
          className="CrewConsole__plainButton"
          checked={highlighted}
          tooltip="Отметить персонажа на карте"
          onClick={() => toggleHighlight(id)} />
      </Table.Cell>
      <Table.Cell
        bold={jobIsHead(ijob)}
        color={jobToColor(ijob)}>
        <span className="CrewConsole__jobIconSlot" aria-hidden="true">
          <CrewJobIcon jobIcon={sensor_data.job_icon} />
        </span>
        {name}{assignment !== undefined ? ` (${assignment})` : ""}
      </Table.Cell>
      <Table.Cell collapsing textAlign="center">
        <ColorBox
          color={color} />
      </Table.Cell>
      <Table.Cell collapsing textAlign="center">
        {Number.isFinite(oxydam) ? (
          <Box inline>
            <HealthStat type="oxy" value={oxydam} />
            {'/'}
            <HealthStat type="toxin" value={toxdam} />
            {'/'}
            <HealthStat type="burn" value={burndam} />
            {'/'}
            <HealthStat type="brute" value={brutedam} />
          </Box>
        ) : (
          <Box inline color={life_status ? 'good' : 'bad'}>
            {life_status ? 'Жив' : 'Мёртв'}
          </Box>
        )}
      </Table.Cell>
      <Table.Cell>
        {area || 'Нет данных'}
        {!!pos_z && ` (${pos_x}, ${pos_y}${data.levels?.length > 1 ? `, Этаж ${floor}` : ''})`}
      </Table.Cell>
      <Table.Cell collapsing>
        <CrewDirection sensor={sensor_data} position={data.position} />
      </Table.Cell>
      {!!link_allowed && (
        <Table.Cell collapsing>
          <Button
            content="Следить"
            disabled={!can_track}
            onClick={() => act('select_person', {
              id,
            })} />
        </Table.Cell>
      )}
    </Table.Row>
  );
};

const CrewDirection = ({ sensor, position }) => {
  if (!position || !sensor.pos_z) {
    return <Box color="label">—</Box>;
  }
  const otherLevel = sensor.pos_z !== position.z;
  // Расстояние считаем как в GPS, без ограничения BYOND в 127 тайлов.
  const distance = Math.round(vecLength(vecSubtract(
    [position.x, position.y], [sensor.pos_x, sensor.pos_y],
  )));
  const degrees = Math.atan2(sensor.pos_x - position.x, sensor.pos_y - position.y) * 180 / Math.PI;
  return (
    <Box nowrap>
      <Icon
        mr={1}
        size={1.2}
        name={distance ? 'arrow-up' : 'map-marker-alt'}
        rotation={distance ? degrees : 0} />
      {`${distance} м${otherLevel ? ` (Э: ${sensor.floor})` : ''}`}
    </Box>
  );
};

const CrewMap = (props) => {
  const { act, data } = useBackend();
  const { highlightedIds, toggleHighlight } = props;
  const showNames = !!data.show_names;
  const showIcons = !!data.show_icons;
  const maps = (data.levels || [])
    .map(z => (data.maps || []).find(map => map.z === z))
    .filter(Boolean);
  const sensors = (data.sensors || []).filter(sensor => (
    sensor.pos_z && (data.levels || []).includes(sensor.pos_z)
  ));
  return (
    <StationMap
      maps={maps}
      initialZ={data.z}
      statePrefix="crewMap"
      showDepartments={!!data.show_departments}
      onToggleDepartments={() => act('toggle_departments')}
      controls={(
        <>
          <Button.Checkbox checked={showNames} onClick={() => act('toggle_names')}>
            Имена
          </Button.Checkbox>
          <Button.Checkbox checked={showIcons} onClick={() => act('toggle_icons')}>
            Иконки
          </Button.Checkbox>
        </>
      )}
      hint=" Нажатие на метку — выделение. Полупрозрачные метки — персонажи на других этажах."
      renderMarkers={(floor, scale) => (
        <>
          {sensors.map(sensor => (
            <CrewMapMarker
              key={sensor.id}
              sensor={sensor}
              floor={floor}
              scale={scale}
              highlighted={highlightedIds.includes(sensor.id)}
              showName={showNames}
              showIcon={showIcons}
              toggleHighlight={toggleHighlight} />
          ))}
          {!!data.position && (
            <Tooltip content="Ваше местоположение">
              <div
                className="CrewConsole__marker CrewConsole__marker--highlighted CrewConsole__marker--observer"
                aria-label="Ваше местоположение"
                tabIndex={0}
                onMouseDown={e => e.stopPropagation()}
                style={{
                  left: `${(data.position.x - floor.min_x + 0.5) * scale}px`,
                  bottom: `${(data.position.y - floor.min_y + 0.5) * scale}px`,
                  opacity: data.position.z === floor.z ? 1 : 0.4,
                }} />
            </Tooltip>
          )}
        </>
      )} />
  );
};

const CrewMapMarker = (props) => {
  const { sensor, floor, scale, highlighted, showName, showIcon, toggleHighlight } = props;
  const otherLevel = sensor.pos_z !== floor.z;
  const color = healthToColor(
    sensor.oxydam, sensor.toxdam, sensor.burndam, sensor.brutedam, sensor.life_status,
  );
  const tooltip = `${sensor.name}${sensor.assignment ? ` (${sensor.assignment})` : ''}`
    + `${otherLevel ? ` (Этаж ${sensor.floor})` : ''}`
    + ` — ${sensor.area} (${sensor.pos_x}, ${sensor.pos_y})`;
  return (
    <Tooltip content={tooltip}>
      <div
        className={`CrewConsole__marker${showIcon ? ' CrewConsole__marker--job' : ''}${highlighted ? ' CrewConsole__marker--highlighted' : ''}`}
        role="button"
        aria-label={tooltip}
        tabIndex={0}
        onMouseDown={e => e.stopPropagation()}
        onClick={() => toggleHighlight(sensor.id)}
        onKeyDown={e => {
          if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            toggleHighlight(sensor.id);
          }
        }}
        style={{
          left: `${(sensor.pos_x - floor.min_x + 0.5) * scale}px`,
          bottom: `${(sensor.pos_y - floor.min_y + 0.5) * scale}px`,
          color,
          backgroundColor: showIcon ? undefined : color,
          opacity: otherLevel ? 0.4 : 1,
          zIndex: (otherLevel ? 1 : 2) + (highlighted ? 2 : 0),
        }}>
        {showIcon && <CrewJobIcon jobIcon={sensor.job_icon} color={color} />}
        {highlighted && showName && (
          <span className="CrewConsole__markerLabel">
            {sensor.name}{otherLevel ? ` (Этаж ${sensor.floor})` : ''}
          </span>
        )}
      </div>
    </Tooltip>
  );
};

import { createSearch } from 'common/string';
import { vecLength, vecSubtract } from 'common/vector';

import { useBackend, useLocalState } from '../backend';
import { Box, Button, ColorBox, Icon, Input, NoticeBox, Section, Stack, Table, Tabs, Tooltip } from '../components';
import { COLORS } from '../constants';
import { Window } from '../layouts';
import { StationMap } from './common/StationMap';

const HEALTH_COLOR_BY_LEVEL = [
  '#17d568',
  '#2ecc71',
  '#e67e22',
  '#ed5100',
  '#e74c3c',
  '#ed2814',
];

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
  if (!life_status) {
    return HEALTH_COLOR_BY_LEVEL[HEALTH_COLOR_BY_LEVEL.length - 1];
  }
  const healthSum = (oxy ?? 0) + (tox ?? 0) + (burn ?? 0) + (brute ?? 0);
  const level = Math.min(Math.max(Math.ceil(healthSum / 25), 0), 5);
  return HEALTH_COLOR_BY_LEVEL[level];
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
  const [tab, setTab] = useLocalState('crewTab', 'list');
  // Отметки привязаны к UID моба: одинаковые имена не объединяются, переименование сохраняет отметку.
  const [highlightedIds, setHighlightedIds] = useLocalState('crewHighlightedIds', []);
  const toggleHighlight = id => setHighlightedIds(ids => (
    ids.includes(id) ? ids.filter(entry => entry !== id) : [...ids, id]
  ));
  const highlightProps = { highlightedIds, setHighlightedIds, toggleHighlight };
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
  const { highlightedIds, setHighlightedIds, toggleHighlight } = props;
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
              onClick={() => setHighlightedIds([])} />
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
        {name}{assignment !== undefined ? ` (${assignment})` : ""}
      </Table.Cell>
      <Table.Cell collapsing textAlign="center">
        <ColorBox
          color={healthToColor(
            oxydam,
            toxdam,
            burndam,
            brutedam,
            life_status)} />
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
  const { data } = useBackend();
  const { highlightedIds, toggleHighlight } = props;
  const [showNames, setShowNames] = useLocalState('crewMapHighlightedNames', true);
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
      controls={(
        <Button.Checkbox checked={showNames} onClick={() => setShowNames(!showNames)}>
          Имена
        </Button.Checkbox>
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
  const { sensor, floor, scale, highlighted, showName, toggleHighlight } = props;
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
        className={`CrewConsole__marker${highlighted ? ' CrewConsole__marker--highlighted' : ''}`}
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
          backgroundColor: color,
          opacity: otherLevel ? 0.4 : 1,
          zIndex: (otherLevel ? 1 : 2) + (highlighted ? 2 : 0),
        }}>
        {highlighted && showName && (
          <span className="CrewConsole__markerLabel">
            {sensor.name}{otherLevel ? ` (Этаж ${sensor.floor})` : ''}
          </span>
        )}
      </div>
    </Tooltip>
  );
};

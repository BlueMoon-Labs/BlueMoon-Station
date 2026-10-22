import { createSearch } from 'common/string';

import { useBackend, useLocalState } from '../backend';
import { Box, Button, ColorBox, Input, NoticeBox, OrbitalMapComponent, Section, Slider, Stack, Table, Tabs, Tooltip } from '../components';
import { COLORS } from '../constants';
import { Window } from '../layouts';

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
  // Отметки хранятся у пользователя по отображаемому имени, без ссылок на мобов.
  const [highlightedNames, setHighlightedNames] = useLocalState('crewHighlights', []);
  const toggleHighlight = name => setHighlightedNames(names => (
    names.includes(name) ? names.filter(entry => entry !== name) : [...names, name]
  ));
  const highlightProps = { highlightedNames, setHighlightedNames, toggleHighlight };
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
  const { highlightedNames, setHighlightedNames, toggleHighlight } = props;
  const [search, setSearch] = useLocalState('crewSearch', '');
  const sensors = data.sensors || [];
  const searcher = createSearch(search, sensor => (
    `${sensor.name}|${sensor.assignment || ''}|${sensor.area || ''}`
  ));
  const filteredSensors = sensors.filter(searcher);
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
              icon="times"
              tooltip="Снять все отметки"
              disabled={!highlightedNames.length}
              onClick={() => setHighlightedNames([])} />
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
          {!!data.link_allowed && (
            <Table.Cell bold collapsing>
              Слежение
            </Table.Cell>
          )}
        </Table.Row>
        {filteredSensors.map((sensor, index) => (
          <CrewTableEntry
            sensor_data={sensor}
            key={`${sensor.name}-${index}`}
            highlighted={highlightedNames.includes(sensor.name)}
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
    can_track,
  } = sensor_data;

  return (
    <Table.Row className={highlighted && 'CrewConsole__highlightedRow'}>
      <Table.Cell collapsing>
        <Button.Checkbox
          checked={highlighted}
          tooltip="Отметить персонажа на карте"
          onClick={() => toggleHighlight(name)} />
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
          life_status ? 'Жив' : 'Мёртв'
        )}
      </Table.Cell>
      <Table.Cell>
        {area || 'Нет данных'}
        {!!pos_z && ` (${pos_x}, ${pos_y}, Z: ${pos_z})`}
      </Table.Cell>
      {!!link_allowed && (
        <Table.Cell collapsing>
          <Button
            content="Следить"
            disabled={!can_track}
            onClick={() => act('select_person', {
              name: name,
            })} />
        </Table.Cell>
      )}
    </Table.Row>
  );
};

const CrewMap = (props) => {
  const { data } = useBackend();
  const { highlightedNames, toggleHighlight } = props;
  const [selectedZ, setSelectedZ] = useLocalState('crewMapZ', data.z);
  const [zoom, setZoom] = useLocalState('crewMapZoom', 1);
  const [offset, setOffset] = useLocalState('crewMapOffset', [0, 0]);
  const maps = (data.levels || [])
    .map(z => (data.maps || []).find(map => map.z === z))
    .filter(Boolean);
  const floor = maps.find(map => map.z === selectedZ)
    || maps.find(map => map.z === data.z) || maps[0];
  if (!floor) {
    return <NoticeBox>Карта этого уровня недоступна.</NoticeBox>;
  }
  const floorIndex = maps.indexOf(floor);
  const scale = 2 * zoom;
  const setMapZoom = value => setZoom(Math.min(8, Math.max(1, value)));
  const sensors = (data.sensors || []).filter(sensor => (
    sensor.pos_z && (data.levels || []).includes(sensor.pos_z)
  ));
  return (
    <Stack fill vertical>
      <Stack.Item>
        <Stack align="center">
          <Stack.Item>
            <Button
              icon="arrow-down"
              tooltip="Уровнем ниже"
              disabled={floorIndex === 0}
              onClick={() => setSelectedZ(maps[floorIndex - 1].z)} />
            <Button
              icon="arrow-up"
              tooltip="Уровнем выше"
              disabled={floorIndex === maps.length - 1}
              onClick={() => setSelectedZ(maps[floorIndex + 1].z)} />
          </Stack.Item>
          <Stack.Item grow>
            {`Уровень Z: ${floor.z}`}
          </Stack.Item>
          <Stack.Item>Масштаб:</Stack.Item>
          <Stack.Item>
            <Button
              icon="minus"
              tooltip="Уменьшить"
              disabled={zoom <= 1}
              onClick={() => setMapZoom(zoom - 0.5)} />
          </Stack.Item>
          <Stack.Item>
            <Slider
              width={10}
              value={zoom}
              minValue={1}
              maxValue={8}
              step={0.5}
              stepPixelSize={15}
              format={value => `${value}x`}
              onChange={(e, value) => setMapZoom(value)} />
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="plus"
              tooltip="Увеличить"
              disabled={zoom >= 8}
              onClick={() => setMapZoom(zoom + 0.5)} />
            <Button
              icon="sync"
              tooltip="Сбросить масштаб и положение карты"
              onClick={() => {
                setZoom(1);
                setOffset([0, 0]);
              }} />
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item grow>
        <Box
          className="CrewConsole__mapViewport"
          onWheel={e => {
            if (e.deltaY) {
              e.preventDefault();
              setMapZoom(zoom + (e.deltaY < 0 ? 0.5 : -0.5));
            }
          }}>
          <OrbitalMapComponent
            valueX={offset[0]}
            valueY={offset[1]}
            step={1}
            stepPixelSize={1}
            onDrag={(e, x, y) => setOffset([x, y])}>
            {({ xOffset, yOffset, handleDragStart }) => (
              <Box fillPositionedParent onMouseDown={e => {
                if (e.button === 0) {
                  e.preventDefault();
                  handleDragStart(e);
                }
              }}>
                <div
                  className="CrewConsole__map"
                  style={{
                    width: `${(floor.max_x - floor.min_x + 1) * scale}px`,
                    height: `${(floor.max_y - floor.min_y + 1) * scale}px`,
                    transform: `translate(calc(-50% - ${xOffset}px), calc(-50% - ${yOffset}px))`,
                  }}>
                  <img
                    src={floor.image}
                    alt={`Карта уровня Z: ${floor.z}`}
                    draggable={false} />
                  {sensors.map((sensor, index) => (
                    <CrewMapMarker
                      key={`${sensor.name}-${index}`}
                      sensor={sensor}
                      floor={floor}
                      scale={scale}
                      highlighted={highlightedNames.includes(sensor.name)}
                      toggleHighlight={toggleHighlight} />
                  ))}
                </div>
              </Box>
            )}
          </OrbitalMapComponent>
        </Box>
      </Stack.Item>
      <Stack.Item color="label">
        Колесо мыши — масштаб; перетаскивание — сдвиг; нажатие на метку — выделение.
        Полупрозрачные метки — персонажи на других уровнях.
      </Stack.Item>
    </Stack>
  );
};

const CrewMapMarker = (props) => {
  const { sensor, floor, scale, highlighted, toggleHighlight } = props;
  const otherLevel = sensor.pos_z !== floor.z;
  const color = healthToColor(
    sensor.oxydam, sensor.toxdam, sensor.burndam, sensor.brutedam, sensor.life_status,
  );
  const tooltip = `${sensor.name}${sensor.assignment ? ` (${sensor.assignment})` : ''}`
    + `${otherLevel ? ` (уровень Z: ${sensor.pos_z})` : ''}`
    + ` — ${sensor.area} (${sensor.pos_x}, ${sensor.pos_y})`;
  return (
    <Tooltip content={tooltip}>
      <div
        className={`CrewConsole__marker${highlighted ? ' CrewConsole__marker--highlighted' : ''}`}
        role="button"
        aria-label={tooltip}
        tabIndex={0}
        onMouseDown={e => e.stopPropagation()}
        onClick={() => toggleHighlight(sensor.name)}
        onKeyDown={e => {
          if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            toggleHighlight(sensor.name);
          }
        }}
        style={{
          left: `${(sensor.pos_x - floor.min_x + 0.5) * scale}px`,
          bottom: `${(sensor.pos_y - floor.min_y + 0.5) * scale}px`,
          color,
          backgroundColor: color,
          opacity: otherLevel ? 0.4 : 1,
          zIndex: (otherLevel ? 1 : 2) + (highlighted ? 2 : 0),
        }} />
    </Tooltip>
  );
};

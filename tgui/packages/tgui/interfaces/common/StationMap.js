import { useLocalState } from '../../backend';
import { Box, Button, NoticeBox, OrbitalMapComponent, Slider, Stack } from '../../components';

export const StationMap = (props) => {
  const { maps = [], initialZ, statePrefix = 'stationMap', renderMarkers, hint } = props;
  const [selectedZ, setSelectedZ] = useLocalState(`${statePrefix}Z`, initialZ);
  const [zoom, setZoom] = useLocalState(`${statePrefix}Zoom`, 1);
  const [offset, setOffset] = useLocalState(`${statePrefix}Offset`, [0, 0]);
  const [showDepartments, setShowDepartments] = useLocalState(`${statePrefix}Departments`, false);
  const floor = maps.find(map => map.z === selectedZ)
    || maps.find(map => map.z === initialZ) || maps[0];
  if (!floor) {
    return <NoticeBox>Карта этого этажа недоступна.</NoticeBox>;
  }
  const floorIndex = maps.indexOf(floor);
  const scale = 2 * zoom;
  const setMapZoom = value => setZoom(Math.min(8, Math.max(1, value)));
  return (
    <Stack fill vertical>
      <Stack.Item>
        <Stack align="center">
          {maps.length > 1 && (
            <Stack.Item>
              <Button
                icon="arrow-down"
                tooltip="Этажом ниже"
                disabled={floorIndex === 0}
                onClick={() => setSelectedZ(maps[floorIndex - 1].z)} />
              <Button
                icon="arrow-up"
                tooltip="Этажом выше"
                disabled={floorIndex === maps.length - 1}
                onClick={() => setSelectedZ(maps[floorIndex + 1].z)} />
            </Stack.Item>
          )}
          <Stack.Item grow>
            {maps.length > 1 && `Этаж: ${floor.floor}`}
          </Stack.Item>
          <Stack.Item>
            <Button.Checkbox
              checked={showDepartments}
              onClick={() => setShowDepartments(!showDepartments)}>
              Отделы
            </Button.Checkbox>
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
          className="StationMap__viewport"
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
                  className="StationMap__map"
                  style={{
                    width: `${(floor.max_x - floor.min_x + 1) * scale}px`,
                    height: `${(floor.max_y - floor.min_y + 1) * scale}px`,
                    transform: `translate(calc(-50% - ${xOffset}px), calc(-50% - ${yOffset}px))`,
                  }}>
                  <img
                    src={showDepartments ? floor.department_image : floor.image}
                    alt={`Карта этажа ${floor.floor}`}
                    draggable={false} />
                  {renderMarkers?.(floor, scale)}
                </div>
              </Box>
            )}
          </OrbitalMapComponent>
        </Box>
      </Stack.Item>
      <Stack.Item color="label">
        Колесо мыши — масштаб; перетаскивание — сдвиг.
        {hint}
      </Stack.Item>
    </Stack>
  );
};


import { useRef, useState } from 'react';

import { useLocalState } from '../../backend';
import { Box, Button, NoticeBox, Slider, Stack } from '../../components';

export const StationMap = (props) => {
  const { maps = [], initialZ, statePrefix = 'stationMap', renderMarkers, controls, hint } = props;
  const [selectedZ, setSelectedZ] = useLocalState(`${statePrefix}Z`, initialZ);
  const [savedZoom, setSavedZoom] = useLocalState(`${statePrefix}Zoom`, 1);
  const [zoom, setZoom] = useState(savedZoom);
  const currentZoom = useRef(savedZoom);
  const [offset, setOffset] = useLocalState(`${statePrefix}Offset`, [0, 0]);
  const [viewOffset, setViewOffset] = useState(offset);
  const drag = useRef(null);
  const currentOffset = useRef(offset);
  const finishDrag = () => {
    if (!drag.current) {
      return;
    }
    drag.current = null;
    setOffset(currentOffset.current);
  };
  const [showDepartments, setShowDepartments] = useLocalState(`${statePrefix}Departments`, false);
  const floor = maps.find(map => map.z === selectedZ)
    || maps.find(map => map.z === initialZ) || maps[0];
  if (!floor) {
    return <NoticeBox>Карта этого этажа недоступна.</NoticeBox>;
  }
  const floorIndex = maps.indexOf(floor);
  const scale = 2 * zoom;
  const setMapZoom = (value, anchor = [0, 0]) => {
    const nextZoom = Math.min(8, Math.max(1, value));
    if (nextZoom === currentZoom.current) {
      return;
    }
    const ratio = nextZoom / currentZoom.current;
    // Сохраняем под якорем ту же точку карты; без курсора якорь — центр видимой области.
    const nextOffset = currentOffset.current.map((position, axis) => (
      (position + anchor[axis]) * ratio - anchor[axis]
    ));
    currentZoom.current = nextZoom;
    currentOffset.current = nextOffset;
    if (drag.current) {
      drag.current.offset = nextOffset;
      drag.current.x = drag.current.lastX;
      drag.current.y = drag.current.lastY;
    }
    setZoom(nextZoom);
    setViewOffset(nextOffset);
    setSavedZoom(nextZoom);
    setOffset(nextOffset);
  };
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
          {controls && <Stack.Item>{controls}</Stack.Item>}
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
                currentZoom.current = 1;
                setZoom(1);
                setSavedZoom(1);
                currentOffset.current = [0, 0];
                setViewOffset([0, 0]);
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
              const viewport = e.currentTarget;
              const rect = viewport.getBoundingClientRect();
              const pixelScale = rect.width / viewport.clientWidth;
              setMapZoom(currentZoom.current + (e.deltaY < 0 ? 0.5 : -0.5), [
                (e.clientX - rect.left - rect.width / 2) / pixelScale,
                (e.clientY - rect.top - rect.height / 2) / pixelScale,
              ]);
            }
          }}>
          <Box
            fillPositionedParent
            onPointerDown={e => {
              if (e.button !== 0 || drag.current
                || e.target.closest('.CrewConsole__marker, button, [role="button"]')) {
                return;
              }
              e.preventDefault();
              const viewport = e.currentTarget;
              // Переводим экранное смещение в пиксели карты с учётом CSS zoom TGUI.
              const pixelScale = viewport.getBoundingClientRect().width / viewport.clientWidth;
              drag.current = {
                pointerId: e.pointerId,
                x: e.clientX,
                y: e.clientY,
                lastX: e.clientX,
                lastY: e.clientY,
                offset: currentOffset.current,
                pixelScale,
              };
              viewport.setPointerCapture(e.pointerId);
            }}
            onPointerMove={e => {
              const session = drag.current;
              if (!session || session.pointerId !== e.pointerId) {
                return;
              }
              if (!(e.buttons & 1)) {
                finishDrag();
                return;
              }
              const nextOffset = [
                session.offset[0] - (e.clientX - session.x) / session.pixelScale,
                session.offset[1] - (e.clientY - session.y) / session.pixelScale,
              ];
              session.lastX = e.clientX;
              session.lastY = e.clientY;
              currentOffset.current = nextOffset;
              // Обновляем обе оси вместе; общее состояние TGUI сохраняем только в конце жеста.
              setViewOffset(nextOffset);
            }}
            onPointerUp={finishDrag}
            onPointerCancel={finishDrag}
            onLostPointerCapture={finishDrag}>
            <div
              className="StationMap__map"
              style={{
                width: `${(floor.max_x - floor.min_x + 1) * scale}px`,
                height: `${(floor.max_y - floor.min_y + 1) * scale}px`,
                transform: `translate(calc(-50% - ${viewOffset[0]}px), calc(-50% - ${viewOffset[1]}px))`,
              }}>
              <img
                src={showDepartments ? floor.department_image : floor.image}
                alt={`Карта этажа ${floor.floor}`}
                draggable={false} />
              {renderMarkers?.(floor, scale)}
            </div>
          </Box>
        </Box>
      </Stack.Item>
      <Stack.Item color="label">
        Колесо мыши — масштаб к курсору; перетаскивание — сдвиг.
        {hint}
      </Stack.Item>
    </Stack>
  );
};


import { filter, sortBy } from 'common/collections';
import { flow } from 'common/fp';
import { classes } from 'common/react';
import { createSearch } from 'common/string';
import { useState } from 'react';

import { useBackend, useLocalState } from '../backend';
import { Box, Button, ByondUi, Flex, Icon, Input, Section, Stack, Tabs } from '../components';
import { Window } from '../layouts';
import { StationMap } from './common/StationMap';

/**
 * Returns previous and next camera names relative to the currently
 * active camera.
 */
export const prevNextCamera = (cameras, activeCamera) => {
  if (!activeCamera) {
    return [];
  }
  const index = cameras.findIndex(camera => (
    camera.name === activeCamera.name
  ));
  return [
    cameras[index - 1]?.name,
    cameras[index + 1]?.name,
  ];
};

/**
 * Camera selector.
 *
 * Filters cameras, applies search terms and sorts the alphabetically.
 */
export const selectCameras = (cameras, searchText = '') => {
  const testSearch = createSearch(searchText, camera => camera.name);
  return flow([
    // Null camera filter
    filter(camera => camera?.name),
    // Optional search term
    searchText && filter(testSearch),
    // Slightly expensive, but way better than sorting in BYOND
    sortBy(camera => camera.name),
  ])(cameras);
};

export const CameraConsole = (props) => {
  const { act, data } = useBackend();
  const { mapRef, activeCamera } = data;
  const [tab, setTab] = useLocalState('cameraTab', 'list');
  const hasMap = Array.isArray(data.maps);
  const showMap = hasMap && tab === 'map';
  const cameras = selectCameras(data.cameras);
  const [
    prevCameraName,
    nextCameraName,
  ] = prevNextCamera(cameras, activeCamera);
  return (
    <Window
      width={hasMap ? 1100 : 870}
      height={750}>
      <Window.Content>
        <Stack fill vertical>
          {hasMap && (
            <Stack.Item>
              <Tabs>
                <Tabs.Tab
                  icon="table"
                  selected={tab === 'list'}
                  onClick={() => setTab('list')}>
                  Список камер
                </Tabs.Tab>
                <Tabs.Tab
                  icon="map-marked-alt"
                  selected={showMap}
                  onClick={() => setTab('map')}>
                  Карта
                </Tabs.Tab>
              </Tabs>
            </Stack.Item>
          )}
          <Stack.Item grow position="relative">
            <div className={classes([
              'CameraConsole__content',
              showMap && 'CameraConsole__overview',
            ])}>
              <div className="CameraConsole__left">
                {showMap ? <CameraMap /> : <CameraConsoleContent />}
              </div>
              <div className="CameraConsole__right">
                <div className="CameraConsole__toolbar" title={activeCamera?.name}>
                  <b>Камера: </b>
                  {activeCamera?.name || '—'}
                  {activeCamera && !activeCamera.status && ' — нет сигнала'}
                </div>
                <div className="CameraConsole__toolbarRight">
                  <Button
                    icon="chevron-left"
                    tooltip="Предыдущая камера"
                    disabled={!prevCameraName}
                    onClick={() => act('switch_camera', {
                      name: prevCameraName,
                    })} />
                  <Button
                    icon="chevron-right"
                    tooltip="Следующая камера"
                    disabled={!nextCameraName}
                    onClick={() => act('switch_camera', {
                      name: nextCameraName,
                    })} />
                </div>
                <ByondUi
                  className="CameraConsole__map"
                  params={{
                    id: mapRef,
                    type: 'map',
                  }} />
              </div>
            </div>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const CameraMap = () => {
  const { act, data } = useBackend();
  return (
    <Box className="CameraConsole__overviewMap">
      <Stack fill vertical>
        <Stack.Item>
          <Box inline mr={1} color="#66dd77">● Работает</Box>
          <Box inline mr={1} color="#ff5c5c">● Недоступна</Box>
          <Box inline color="#ffd700">● Выбрана</Box>
        </Stack.Item>
        <Stack.Item grow>
          <StationMap
            maps={data.maps}
            initialZ={data.z}
            statePrefix="cameraMap"
            showDepartments={!!data.show_departments}
            onToggleDepartments={() => act('toggle_departments')}
            hint=" Нажмите на камеру, чтобы посмотреть изображение."
            renderMarkers={(floor, scale) => data.cameras
              .filter(camera => camera.z === floor.z
                && camera.x >= floor.min_x && camera.x <= floor.max_x
                && camera.y >= floor.min_y && camera.y <= floor.max_y)
              .map(camera => {
                const selected = camera.name === data.activeCamera?.name;
                const color = selected ? '#ffd700' : camera.status ? '#66dd77' : '#ff5c5c';
                const label = `${camera.name} — ${camera.status ? 'работает' : 'нет сигнала'}`;
                return (
                  <button
                    key={camera.name}
                    type="button"
                    className={classes([
                      'CameraConsole__marker',
                      selected && 'CameraConsole__marker--selected',
                    ])}
                    title={label}
                    aria-label={label}
                    aria-pressed={selected}
                    style={{
                      left: `${(camera.x - floor.min_x + 0.5) * scale}px`,
                      bottom: `${(camera.y - floor.min_y + 0.5) * scale}px`,
                      color,
                    }}
                    onClick={() => act('switch_camera', { name: camera.name })}>
                    <Icon name="video" />
                  </button>
                );
              })} />
        </Stack.Item>
      </Stack>
    </Box>
  );
};

export const CameraConsoleContent = (props) => {
  const { act, data } = useBackend();
  const [
    searchText,
    setSearchText,
  ] = useState('');
  const { activeCamera } = data;
  const cameras = selectCameras(data.cameras, searchText);
  return (
    <Flex
      direction={"column"}
      height="100%">
      <Flex.Item>
        <Input
          autoFocus
          fluid
          mt={1}
          placeholder="Поиск камеры"
          onInput={(e, value) => setSearchText(value)} />
      </Flex.Item>
      <Flex.Item
        height="100%">
        <Section
          fill
          scrollable>
          {cameras.map(camera => (
          // We're not using the component here because performance
          // would be absolutely abysmal (50+ ms for each re-render).
            <div
              key={camera.name}
              title={camera.name}
              className={classes([
                'Button',
                'Button--fluid',
                'Button--color--transparent',
                'Button--ellipsis',
                activeCamera
                && camera.name === activeCamera.name
                && 'Button--selected',
              ])}
              onClick={() => act('switch_camera', {
                name: camera.name,
              })}>
              {camera.name}
            </div>
          ))}
        </Section>
      </Flex.Item>
    </Flex>
  );
};

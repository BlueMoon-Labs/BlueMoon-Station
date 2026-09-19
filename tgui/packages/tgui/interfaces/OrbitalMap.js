import { useBackend, useLocalState } from '../backend';
import { Box, Button, Divider, DraggableClickableControl, Dropdown, NoticeBox, OrbitalMapComponent, OrbitalMapSvg, ProgressBar, Section, Table } from '../components';
import { Window } from '../layouts';

export const OrbitalMap = (props) => {
  const { act, data } = useBackend();
  const {
    map_objects = [],
    linkedToShuttle = false,
    canLaunch = false,
    recall_docking_port_id = "",
    thrust_alert = false,
    damage_alert = false,
    shuttleName = "",
    interdictionTime = 0,
  } = data;
  const [
    zoomScale,
    setZoomScale,
  ] = useLocalState('zoomScale', 1);
  const [
    xOffset,
    setXOffset,
  ] = useLocalState('xOffset', 0);
  const [
    yOffset,
    setYOffset,
  ] = useLocalState('yOffset', 0);
  const [
    trackedBody,
    setTrackedBody,
  ] = useLocalState('trackedBody', shuttleName);

  let dynamicXOffset = xOffset;
  let dynamicYOffset = yOffset;

  let trackedObject = null;
  let ourObject = null;
  let firstObjectName = "null";
  if (map_objects.length > 0 && interdictionTime === 0)
  {
    firstObjectName = map_objects[1]
      ? map_objects[1].name
      : map_objects[0].name;
    // Find the right tracked body
    map_objects.forEach(element => {
      if (element.name === shuttleName)
      {
        ourObject = element;
      }
      if (element.name === trackedBody && !trackedObject)
      {
        trackedObject = element;
        if (trackedBody !== map_objects[0].name)
        {
          dynamicXOffset = trackedObject.position_x
           + trackedObject.velocity_x;
          dynamicYOffset = trackedObject.position_y
           + trackedObject.velocity_y;
        }
      }
    });
  }

  return (
    <Window
      width={1089}
      height={720}
      resizable
      overflowY="hidden">
      <Window.Content overflowY="hidden">
        <div className="OrbitalMap__radar" id="radar">
          {interdictionTime ? (
            <InterdictionDisplay
              xOffset={dynamicXOffset}
              yOffset={dynamicYOffset}
              zoomScale={zoomScale}
              setZoomScale={setZoomScale}
              setXOffset={setXOffset}
              setYOffset={setYOffset} />
          ) : (
            <OrbitalMapDisplay
              dynamicXOffset={dynamicXOffset}
              dynamicYOffset={dynamicYOffset}
              isTracking={map_objects.length > 0
                && trackedBody !== map_objects[0].name}
              zoomScale={zoomScale}
              setZoomScale={setZoomScale}
              setTrackedBody={setTrackedBody}
              ourObject={ourObject} />
          )}
        </div>
        <div className="OrbitalMap__panel">
          <Box overflowY="scroll" overflowX="hidden" height="100%">
            <Section title="Отслеживание тел">
              <Box bold>
                Отслеживание
              </Box>
              <Box mb={1}>
                {trackedBody}
              </Box>
              <Box>
                <b>
                  X:&nbsp;
                </b>
                {trackedObject && trackedObject.position_x}
              </Box>
              <Box>
                <b>
                  Y:&nbsp;
                </b>
                {trackedObject && trackedObject.position_y}
              </Box>
              <Box>
                <b>
                  Ускорение:&nbsp;
                </b>
                ({trackedObject && trackedObject.velocity_x}
                , {trackedObject && trackedObject.velocity_y})
              </Box>
              <Box>
                <b>
                  Радиус:&nbsp;
                </b>
                {trackedObject && trackedObject.radius} БСЕ
              </Box>
              <Divider />
              <Dropdown
                selected={trackedBody}
                width="100%"
                color="grey"
                options={map_objects.sort((first,
                  second) => { return second.priority - first.priority; })
                  .map(map_object => (map_object.name))}
                onSelected={value => setTrackedBody(value)} />
            </Section>
            <Divider />
            <Section title="Управление полётом">
              {(!thrust_alert) || (
                <NoticeBox color="red">
                  {thrust_alert}
                </NoticeBox>
              )}
              {(!damage_alert) || (
                <NoticeBox color="red">
                  {damage_alert}
                </NoticeBox>
              )}
              {recall_docking_port_id !== ""
                ? <RecallControl />
                : linkedToShuttle
                  ? <ShuttleControls />
                  : (canLaunch ? (
                    <>
                      <NoticeBox>
                        Пристыкованы, ожидаем запуск.
                      </NoticeBox>
                      <Button
                        content="ЗАПУСК"
                        textAlign="center"
                        fontSize="30px"
                        icon="rocket"
                        width="100%"
                        height="50px"
                        onClick={() => act('launch')} />
                    </>
                  ) : (
                    <NoticeBox
                      color="red">
                      Не обнаружен шаттл.
                    </NoticeBox>
                  ))}
            </Section>
          </Box>
        </div>
      </Window.Content>
    </Window>
  );
};

export const InterdictionDisplay = (props) => {

  const boxTargetStyle = {
    "fill-opacity": 0,
    stroke: '#DDDDDD',
    strokeWidth: '1',
  };

  const {
    xOffset,
    yOffset,
    zoomScale,
    setZoomScale,
    setXOffset,
    setYOffset,
  } = props;

  let lockedZoomScale = Math.max(Math.min(zoomScale, 4), 0.125);

  const { data } = useBackend();

  const {
    interdictionTime = 0,
    interdictedShuttles = [],
  } = data;

  return (
    <>
      <NoticeBox
        position="absolute"
        color="red">
        <Box bold mt={1} ml={1}>
          ДВИГАТЕЛИ ПЕРЕХВАЧЕНЫ
        </Box>
        <Box ml={1}>
          Управление полётом отключено.
          Двигатели перезапустятся через {interdictionTime / 10} секунд.
        </Box>
        <Box ml={1}>
          Местные шаттлы отмечены на карте.
        </Box>
      </NoticeBox>
      <Button
        position="absolute"
        icon="search-plus"
        right="20px"
        top="15px"
        fontSize="18px"
        color="grey"
        onClick={() => setZoomScale(zoomScale * 2)} />
      <Button
        position="absolute"
        icon="search-minus"
        right="20px"
        top="47px"
        fontSize="18px"
        color="grey"
        onClick={() => setZoomScale(zoomScale / 2)} />
      <DraggableClickableControl
        position="absolute"
        value={xOffset}
        dragMatrix={[-1, 0]}
        step={1}
        stepPixelSize={2 * zoomScale}
        onDrag={(e, value) => {
          setXOffset(value);
        }}
        onClick={(e, value) => {}}
        updateRate={5}>
        {control => (
          <DraggableClickableControl
            position="absolute"
            value={yOffset}
            dragMatrix={[0, -1]}
            step={1}
            stepPixelSize={2 * zoomScale}
            onDrag={(e, value) => {
              setYOffset(value);
            }}
            onClick={(e, value) => {}}
            updateRate={5}>
            {control1 => (
              <>
                {control.inputElement}
                {control1.inputElement}
                <svg
                  onMouseDown={e => {
                    control.handleDragStart(e);
                    control1.handleDragStart(e);
                  }}
                  viewBox="-250 -250 500 500"
                  position="absolute"
                  overflowY="hidden">
                  <defs>
                    <pattern id="grid" width={100 * lockedZoomScale}
                      height={100 * lockedZoomScale}
                      patternUnits="userSpaceOnUse"
                      x={-xOffset * zoomScale}
                      y={-yOffset * zoomScale}>
                      <rect width={100 * lockedZoomScale}
                        height={100 * lockedZoomScale}
                        fill="url(#smallgrid)" />
                      <path
                        fill="none" stroke="#CE1935" stroke-width="1"
                        d={"M " + (100 * lockedZoomScale)+ " 0 L 0 0 0 " + (100 * lockedZoomScale)} />
                    </pattern>
                    <pattern id="smallgrid"
                      width={50 * lockedZoomScale}
                      height={50 * lockedZoomScale}
                      patternUnits="userSpaceOnUse">
                      <rect
                        width={50 * lockedZoomScale}
                        height={50 * lockedZoomScale}
                        fill="#382424" />
                      <path
                        fill="none"
                        stroke="#CE1935"
                        stroke-width="0.5"
                        d={"M " + (50 * lockedZoomScale) + " 0 L 0 0 0 "
                        + (50 * lockedZoomScale)} />
                    </pattern>
                  </defs>
                  <rect x="-50%" y="-50%" width="100%" height="100%"
                    fill="url(#grid)" />
                  {interdictedShuttles.map(map_object => (
                    <>
                      <rect
                        x={(map_object.x * 10 - 25 - xOffset) * zoomScale}
                        y={(-map_object.y * 10 - 25 - yOffset) * zoomScale}
                        width={50 * zoomScale}
                        height={50 * zoomScale}
                        style={boxTargetStyle} />
                      <text
                        x={Math.max(Math.min((map_object.x * 10
                          - xOffset
                          + 30)
                          * zoomScale, 200), -250)}
                        y={Math.max(Math.min((-map_object.y * 10
                          - yOffset
                          - 30)
                          * zoomScale, 250), -240)}
                        fill="white"
                        fontSize={Math.min(40 * lockedZoomScale, 14)}>
                        {map_object.shuttleName} ({map_object.x},{map_object.y})
                      </text>
                    </>
                  ))}
                </svg>
              </>
            )}
          </DraggableClickableControl>
        )}
      </DraggableClickableControl>
    </>
  );

};

export const OrbitalMapDisplay = (props) => {

  const {
    zoomScale,
    setZoomScale,
    setTrackedBody,
    ourObject,
    isTracking = false,
    dynamicXOffset,
    dynamicYOffset,
  } = props;

  const [
    offset,
    setOffset,
  ] = useLocalState('offset', [0, 0]);

  let lockedZoomScale = Math.max(Math.min(zoomScale, 4), 0.125);

  const { act, data } = useBackend();

  const {
    map_objects = [],
    shuttleName = "",
    validDockingPorts = [],
    isDocking = false,
    interdiction_range = 150,
    shuttleTargetX = 0,
    shuttleTargetY = 0,
    update_index = 0,
  } = data;

  return (
    <>
      <Button
        position="absolute"
        icon="search-plus"
        right="20px"
        top="15px"
        fontSize="18px"
        color="grey"
        onClick={() => setZoomScale(zoomScale * 2)} />
      <Button
        position="absolute"
        icon="search-minus"
        right="20px"
        top="47px"
        fontSize="18px"
        color="grey"
        onClick={() => setZoomScale(zoomScale / 2)} />
      {!isDocking || (
        <NoticeBox
          position="absolute"
          color="red"
          top="50px"
          left="calc(50% - 150px)"
          width="300px"
          textAlign="center"
          fontSize="14px">
          <>
            <NoticeBox mt={1}>
              СТЫКОВОЧНЫЙ ПРОТОКОЛ АКТИВЕН,
              ПОЛЁТ ОСТАНОВЛЕН -
              ВЫБЕРИТЕ МЕСТО СТЫКОВКИ.
            </NoticeBox>
            <Dropdown
              mt={1}
              selected="Выбрать место стыковки"
              width="100%"
              options={validDockingPorts.map(
                map_object => ({
                  value: map_object.id,
                  displayText: map_object.name,
                }))}
              onSelected={value => act("gotoPort", {
                port: value,
              })} />
          </>
        </NoticeBox>
      )}
      <OrbitalMapComponent
        position="absolute"
        step={1}
        stepPixelSize={2 * zoomScale}
        onDrag={(e, valueX, valueY) => {
          setOffset([valueX, valueY]);
          if (map_objects[0]) {
            setTrackedBody(map_objects[0].name);
          }
        }}
        valueX={isTracking ? dynamicXOffset : offset[0]}
        valueY={isTracking ? dynamicYOffset : offset[1]}
        isTracking={isTracking}
        dynamicXOffset={dynamicXOffset}
        dynamicYOffset={dynamicYOffset}
        currentUpdateIndex={update_index}
        onClick={(e, xOffset, yOffset) => {
          let clickedOnDiv = document.getElementById("radar"); // This is kind
          // of funky but A) I don't know react / javascript and B) Nobody in
          // the history of the universe knows react / javascript so nobody
          // will probably ever read this so I'm good.
          let proportionalX = e.offsetX / clickedOnDiv.offsetWidth * 500;
          let proportionalY = (e.offsetY - 30) / clickedOnDiv.offsetHeight
           * 500;
          act("setTargetCoords", {
            x: (proportionalX - 250) / zoomScale + (isTracking
              ? dynamicXOffset : xOffset),
            y: (proportionalY - 250) / zoomScale + (isTracking
              ? dynamicYOffset : yOffset),
          });
        }} >
        {control => (
          <OrbitalMapSvg
            scaledXOffset={-control.xOffset * zoomScale}
            scaledYOffset={-control.yOffset * zoomScale}
            xOffset={-control.xOffset}
            yOffset={-control.yOffset}
            ourObject={ourObject}
            lockedZoomScale={lockedZoomScale}
            map_objects={map_objects}
            interdiction_range={interdiction_range}
            shuttleTargetX={shuttleTargetX}
            shuttleTargetY={shuttleTargetY}
            dragStartEvent={e => control.handleDragStart(e)}
            zoomScale={zoomScale}
            shuttleName={shuttleName}
            currentUpdateIndex={update_index}>
            {control => (
              control.svgComponent
            )}
          </OrbitalMapSvg>
        )}
      </OrbitalMapComponent>
    </>
  );

};

export const RecallControl = (props) => {
  const { act, data } = useBackend();
  const { request_shuttle_message } = data;
  return (
    <>
      <NoticeBox>
        Ручное управление отключено, данная локация
        может только призывать шаттл.
      </NoticeBox>
      <Button
        content={request_shuttle_message}
        textAlign="center"
        fontSize="30px"
        icon="rocket"
        width="100%"
        height="50px"
        onClick={() => act('callShuttle')} />
    </>
  );
};

export const ShuttleControls = (props) => {
  const { act, data } = useBackend();
  const {
    map_objects = [],
    shuttleTarget = null,
    shuttleAngle = 0,
    shuttleThrust = 0,
    canDock = false,
    isDocking = false,
    display_fuel = false,
    fuel = 0,
    display_stats = [],
    autopilot_enabled = false,
  } = data;
  // Sort the map objects by priority
  let sortedMapObjects = map_objects.sort((first,
    second) => { return second.priority - first.priority; });
  return (
    <>
      <Box bold>
        Автопилот к цели
      </Box>
      <Dropdown
        mt={1}
        selected={shuttleTarget}
        width="100%"
        options={sortedMapObjects.map(map_object => (map_object.name))}
        onSelected={value => act("setTarget", {
          target: value,
        })} />
      <Box mt={1}>
        Ускорение будет синхронизированно с ускорением объекта.
      </Box>
      <ShuttleMap />
      <NoticeBox color="purple" mt={2}>
        Нажми на основной дисплей чтобы лететь.
      </NoticeBox>
      <Box bold>
        Скорость
      </Box>
      <Box>
        Ускорение: {shuttleThrust}
      </Box>
      <Box bold mt={2}>
        Угол ускорения
      </Box>
      <Box>
        Угол: {shuttleAngle}
      </Box>
      {(!display_fuel) || (
        <>
          <Box bold mt={2}>
            Топлива осталось
          </Box>
          <ProgressBar
            value={fuel}>
            {fuel} моль.
          </ProgressBar>
        </>
      )}
      <Table mt={2}>
        {Object.keys(display_stats).map(value => (
          <Table.Row key={value}>
            <Table.Cell bold>
              {value} :
            </Table.Cell>
            <Table.Cell textAlign="right">
              {display_stats[value]}
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
      <Button
        mt={2}
        content="Переключить автопилот"
        onClick={() => act('nautopilot')}
        color={autopilot_enabled ? "green" : "red"} />
      {!(canDock && !isDocking) || (
        <Button
          mt={2}
          content="Начать стыковку"
          onClick={() => act('dock')} />
      )}
      <Button
        mt={2}
        content="ЗАПУСТИТЬ ПЕРЕХВАТ"
        onClick={() => act('interdict')}
        color="purple" />
    </>
  );
};

export const ShuttleMap = (props) => {
  const lineStyle = {
    stroke: '#BBBBBB',
    strokeWidth: '2',
  };
  const velLineStyle = {
    stroke: '#00FF00',
    strokeWidth: '2',
  };
  const { act, data } = useBackend();
  const {
    shuttleAngle = 0,
    shuttleThrust = 0,
    shuttleVelX = 0,
    shuttleVelY = 0,
  } = data;
  let x = (shuttleThrust + 30) * Math.cos(shuttleAngle * (2 * Math.PI / 360));
  let y = (shuttleThrust + 30) * Math.sin(shuttleAngle * (2 * Math.PI / 360));
  return (
    <Box
      width="370px"
      height="160px">
      <svg
        position="absolute"
        height="100%"
        viewBox="-100 -100 200 200">
        <defs>
          <pattern id="grid" width={200} height={200} patternUnits="userSpaceOnUse">
            <rect width={200} height={200} fill="url(#smallgrid)" />
            <path d={"M 200 0 L 0 0 0 200"} fill="none" stroke="#4665DE" stroke-width="1" />
          </pattern>
          <pattern id="smallgrid" width={100} height={100} patternUnits="userSpaceOnUse">
            <rect width={100} height={100} fill="#2B2E3B" />
            <path d={"M 100 0 L 0 0 0 100"} fill="none" stroke="#4665DE" stroke-width="0.5" />
          </pattern>
        </defs>
        <rect x="-50%" y="-50%" width="100%" height="100%" fill="url(#grid)" />
        <circle
          r="30px"
          stroke="#BBBBBB"
          stroke-width="1"
          fill="rgba(0,0,0,0)" />
        <line
          x1={0}
          y1={0}
          x2={x}
          y2={y}
          style={lineStyle} />
        <line
          x1={0}
          y1={0}
          x2={shuttleVelX}
          y2={shuttleVelY}
          style={velLineStyle} />
      </svg>
    </Box>
  );
};

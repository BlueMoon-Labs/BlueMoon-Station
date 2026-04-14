import { Component, createRef } from 'inferno';

import { resolveAsset } from '../../assets';
import { useBackend } from '../../backend';
import {
  Box,
  Button,
  InfinitePlane,
  Input,
  Stack,
} from '../../components';
import { Window } from '../../layouts';
import { CircuitInfo } from './CircuitInfo';
import { CircuitToolbar } from './CircuitToolbar';
import { Connections } from './Connections';
import { ABSOLUTE_Y_OFFSET, MOUSE_BUTTON_LEFT } from './constants';
import {
  byondListToArray,
  connectedToRefList,
  normalizeCircuitComponent,
} from './byondPayload';
import { ObjectComponent } from './ObjectComponent';
import { VariableMenu } from './VariableMenu';
import type {
  CircuitComponentView,
  CircuitPortPayload,
  IntegratedCircuitData,
  IntegratedCircuitState,
  PortLocation,
  SelectedPortState,
  WireConnection,
} from './types';

export class IntegratedCircuit extends Component<unknown, IntegratedCircuitState> {
  connectionsSvgRef = createRef<SVGSVGElement>();
  /** Смещали ли поле мышью с прошлого сохранённого screen_x/y (не слать move_screen на каждый mouseup). */
  planePanDirty = false;

  constructor() {
    super();
    this.state = {
      locations: {},
      selectedPort: null,
      dragClientX: null,
      dragClientY: null,
      zoom: 1,
      backgroundX: 0,
      backgroundY: 0,
      menuOpen: false,
      lgbtqRainbowMode: false,
      screenPanOverride: null,
      planeHomeNonce: 0,
    };
    this.handlePortLocation = this.handlePortLocation.bind(this);
    this.handleMouseDown = this.handleMouseDown.bind(this);
    this.handleMouseUp = this.handleMouseUp.bind(this);
    this.handlePortClick = this.handlePortClick.bind(this);
    this.handlePortRightClick = this.handlePortRightClick.bind(this);
    this.handlePortUp = this.handlePortUp.bind(this);

    this.handlePortDrag = this.handlePortDrag.bind(this);
    this.handlePortRelease = this.handlePortRelease.bind(this);
    this.handleZoomChange = this.handleZoomChange.bind(this);
    this.handleBackgroundMoved = this.handleBackgroundMoved.bind(this);
    this.handlePanToOrigin = this.handlePanToOrigin.bind(this);
  }

  /**
   * Port anchor position in the same coordinate space as the connections SVG
   * (inside InfinitePlane’s translate+scale). offsetLeft/offsetTop ignores parent
   * scale, so we use bounding rects and divide by zoom.
   */
  getPosition(el: HTMLElement | null) {
    if (!el) {
      return { x: 0, y: 0 };
    }
    const svg = this.connectionsSvgRef?.current;
    const zoom = Math.max(this.state.zoom || 1, 0.01);
    const portRect = el.getBoundingClientRect?.();
    const svgRect = svg?.getBoundingClientRect?.();
    if (portRect && svgRect && portRect.width >= 0 && svgRect.width >= 0) {
      return {
        x: (portRect.left + portRect.width / 2 - svgRect.left) / zoom,
        y: (portRect.top + portRect.height / 2 - svgRect.top) / zoom,
      };
    }

    let xPos = 0;
    let yPos = 0;
    let node: HTMLElement | null = el;
    while (node) {
      xPos += node.offsetLeft;
      yPos += node.offsetTop;
      node = node.offsetParent as HTMLElement | null;
    }
    const w = el.offsetWidth || 0;
    const h = el.offsetHeight || 0;
    return {
      x: xPos + w / 2,
      y: yPos + h / 2 + ABSOLUTE_Y_OFFSET,
    };
  }

  handlePortLocation(port: CircuitPortPayload, dom: HTMLElement | null) {
    const { locations } = this.state;

    if (!dom) {
      return;
    }

    const lastPosition = locations[port.ref];
    const position = this.getPosition(dom);
    const withColor = { ...position, color: port.color };

    if (
      Number.isNaN(withColor.x)
      || Number.isNaN(withColor.y)
      || (lastPosition
        && lastPosition.x === withColor.x
        && lastPosition.y === withColor.y)
    ) {
      return;
    }
    locations[port.ref] = withColor;
    this.setState({ locations: locations });
  }

  handlePortClick(
    portIndex: number,
    componentId: number,
    port: CircuitPortPayload,
    isOutput: boolean,
    event: MouseEvent,
  ) {
    if (event.button !== MOUSE_BUTTON_LEFT) {
      return;
    }

    event.stopPropagation();
    this.setState({
      selectedPort: {
        index: portIndex,
        component_id: componentId,
        is_output: isOutput,
        ref: port.ref,
      },
    });

    this.handlePortDrag(event);

    window.addEventListener('mousemove', this.handlePortDrag);
    window.addEventListener('mouseup', this.handlePortRelease);
  }

  // mouse up called whilst over a port. This means we can check if selectedPort
  // exists and do perform some actions if it does.
  handlePortUp(
    portIndex: number,
    componentId: number,
    port: CircuitPortPayload,
    isOutput: boolean,
    event: MouseEvent,
  ) {
    const { act } = useBackend<IntegratedCircuitData>(this.context);
    const {
      selectedPort,
    } = this.state;
    if (!selectedPort) {
      return;
    }
    if (selectedPort.is_output === isOutput) {
      return;
    }
    let data;
    if (isOutput) {
      data = {
        input_port_id: selectedPort.index,
        output_port_id: portIndex,
        input_component_id: selectedPort.component_id,
        output_component_id: componentId,
      };
    } else {
      data = {
        input_port_id: portIndex,
        output_port_id: selectedPort.index,
        input_component_id: componentId,
        output_component_id: selectedPort.component_id,
      };
    }
    act("add_connection", data);
  }

  handlePortDrag(event: MouseEvent) {
    this.setState({
      dragClientX: event.clientX,
      dragClientY: event.clientY,
    });
  }

  handlePortRelease(_event: MouseEvent) {
    this.setState({
      selectedPort: null,
      dragClientX: null,
      dragClientY: null,
    });

    window.removeEventListener('mousemove', this.handlePortDrag);
    window.removeEventListener('mouseup', this.handlePortRelease);
  }

  handlePortRightClick(
    portIndex: number,
    componentId: number,
    port: CircuitPortPayload,
    isOutput: boolean,
    event: MouseEvent,
  ) {
    const { act } = useBackend<IntegratedCircuitData>(this.context);

    event.preventDefault();
    act('remove_connection', {
      component_id: componentId,
      is_input: !isOutput,
      port_id: portIndex,
    });
  }

  handleZoomChange(newZoom: number) {
    this.setState({
      zoom: newZoom,
    });
  }

  handleBackgroundMoved(newX: number, newY: number) {
    this.planePanDirty = true;
    this.setState({
      backgroundX: newX,
      backgroundY: newY,
    });
    if (this.state.menuOpen) {
      this.setState({
        menuOpen: false,
      });
    }
  }

  /** Поле схемы к началу координат (0, 0) — сервер и локальный якорь. */
  handlePanToOrigin() {
    const { act } = useBackend<IntegratedCircuitData>(this.context);
    this.planePanDirty = false;
    this.setState((s) => ({
      screenPanOverride: { x: 0, y: 0 },
      backgroundX: 0,
      backgroundY: 0,
      planeHomeNonce: s.planeHomeNonce + 1,
    }));
    act('move_screen', { screen_x: 0, screen_y: 0 });
  }

  /** IE: экранные координаты → rel_x/rel_y в пространстве нод (как при перетаскивании). */
  ieClientToCircuitCoords(clientX: number, clientY: number) {
    const svg = this.connectionsSvgRef?.current;
    const z = Math.max(this.state.zoom || 1, 0.01);
    if (!svg) {
      return { rel_x: 0, rel_y: 0 };
    }
    const r = svg.getBoundingClientRect();
    return {
      rel_x: (clientX - r.left) / z,
      rel_y: (clientY - r.top) / z,
    };
  }

  handleShiftPlaneMouseDown = (event: MouseEvent) => {
    const { act, data } = useBackend<IntegratedCircuitData>(this.context);
    if (!data.ie_circuit || data.ie_clone_copy_mode !== 'assembly') {
      return;
    }
    const { rel_x, rel_y } = this.ieClientToCircuitCoords(event.clientX, event.clientY);
    act('ie_place_hand_chip_at', { rel_x, rel_y });
  };

  handleIePlaceChipCenter = () => {
    const { act, data } = useBackend<IntegratedCircuitData>(this.context);
    if (!data.ie_circuit || data.ie_clone_copy_mode !== 'assembly') {
      return;
    }
    const svg = this.connectionsSvgRef?.current;
    const z = Math.max(this.state.zoom || 1, 0.01);
    if (!svg) {
      act('ie_place_hand_chip_at', { rel_x: 0, rel_y: 0 });
      return;
    }
    const r = svg.getBoundingClientRect();
    act('ie_place_hand_chip_at', {
      rel_x: (r.width / 2) / z,
      rel_y: (r.height / 2) / z,
    });
  };

  componentDidUpdate(_prevProps: unknown, _prevState: IntegratedCircuitState) {
    const { data } = useBackend<IntegratedCircuitData>(this.context);
    if (!this.state.screenPanOverride) {
      return;
    }
    const sx = data.screen_x;
    const sy = data.screen_y;
    if (typeof sx === 'number' && sx === 0 && typeof sy === 'number' && sy === 0) {
      this.setState({ screenPanOverride: null });
    }
  }

  componentDidMount() {
    window.addEventListener('mousedown', this.handleMouseDown);
    window.addEventListener('mouseup', this.handleMouseUp);
  }

  componentWillUnmount() {
    window.removeEventListener('mousedown', this.handleMouseDown);
    window.removeEventListener('mouseup', this.handleMouseUp);
    window.removeEventListener('mousemove', this.handlePortDrag);
    window.removeEventListener('mouseup', this.handlePortRelease);
  }

  handleMouseDown(_event: MouseEvent) {
    const { act, data } = useBackend<IntegratedCircuitData>(this.context);
    const { examined_name } = data;
    if (examined_name) {
      act('remove_examined_component');
    }
  }

  handleMouseUp(_event: MouseEvent) {
    if (!this.planePanDirty) {
      return;
    }
    this.planePanDirty = false;
    const { act } = useBackend<IntegratedCircuitData>(this.context);
    const { backgroundX, backgroundY } = this.state;
    act("move_screen", {
      screen_x: backgroundX,
      screen_y: backgroundY,
    });
  }

  buildWireConnections(
    components: (CircuitComponentView | null)[],
    locations: Record<string, PortLocation>,
    selectedPort: SelectedPortState | null,
    dragClientX: number | null,
    dragClientY: number | null,
    zoomState: number,
  ): WireConnection[] {
    const connections: WireConnection[] = [];

    for (const comp of components) {
      if (comp === null) {
        continue;
      }

      const inputPorts = comp.input_ports;
      for (const input of inputPorts) {
        const linked = connectedToRefList(input?.connected_to);
        for (const outputRef of linked) {
          const output_port = locations[outputRef];
          connections.push({
            color: (output_port && output_port.color) || 'blue',
            from: output_port,
            to: locations[input.ref],
            outRef: outputRef,
            inRef: input.ref,
          });
        }
      }
    }

    if (selectedPort) {
      const z = Math.max(zoomState || 1, 0.01);
      const isOutput = selectedPort.is_output;
      const portLocation = locations[selectedPort.ref];
      const svg = this.connectionsSvgRef?.current;
      if (
        portLocation
        && svg
        && dragClientX !== null
        && dragClientY !== null
      ) {
        const sr = svg.getBoundingClientRect();
        const mouseCoords = {
          x: (dragClientX - sr.left) / z,
          y: (dragClientY - sr.top) / z,
        };
        connections.push({
          color: (portLocation && portLocation.color) || 'blue',
          from: isOutput ? portLocation : mouseCoords,
          to: isOutput ? mouseCoords : portLocation,
          isPreview: true,
        });
      }
    }

    const fanOutOrder = new Map<string, number>();
    for (const comp of components) {
      if (!comp) {
        continue;
      }
      for (const op of comp.output_ports) {
        const targets = connectedToRefList(op?.connected_to);
        for (let ti = 0; ti < targets.length; ti++) {
          fanOutOrder.set(`${op.ref}\0${targets[ti]}`, ti);
        }
      }
    }

    connections.sort((a, b) => {
      if (a.isPreview || b.isPreview) {
        if (a.isPreview && b.isPreview) {
          return 0;
        }
        return a.isPreview ? 1 : -1;
      }
      if (!a.outRef || !b.outRef || !a.inRef || !b.inRef) {
        return 0;
      }
      if (a.outRef !== b.outRef) {
        return a.outRef.localeCompare(b.outRef);
      }
      const ia = fanOutOrder.get(`${a.outRef}\0${a.inRef}`) ?? 999;
      const ib = fanOutOrder.get(`${b.outRef}\0${b.inRef}`) ?? 999;
      return ia - ib;
    });

    return connections;
  }

  render() {
    const { act, data } = useBackend<IntegratedCircuitData>(this.context);
    const {
      circuit_on,
      display_name,
      examined_name,
      examined_desc,
      examined_notices,
      examined_rel_x,
      examined_rel_y,
      screen_x,
      screen_y,
      is_admin,
      variables,
      global_basic_types,
      ie_circuit,
      ie_clone_copy_mode,
      ie_debug_copy_ref,
      circuit_pulse_out_ref,
      circuit_pulse_in_ref,
    } = data;
    const components = byondListToArray(data.components).map(
      normalizeCircuitComponent,
    );
    const ieBatteryPercent = ie_circuit && data.ie_battery_percent !== undefined
      ? data.ie_battery_percent
      : undefined;
    const ieUsedSize = ie_circuit ? data.ie_used_size : undefined;
    const ieMaxSize = ie_circuit ? data.ie_max_size : undefined;
    const ieUsedComplexity = ie_circuit ? data.ie_used_complexity : undefined;
    const ieMaxComplexity = ie_circuit ? data.ie_max_complexity : undefined;
    const circuitCellPercent = !ie_circuit ? data.circuit_cell_percent : undefined;
    const panX = this.state.screenPanOverride?.x ?? screen_x ?? 0;
    const panY = this.state.screenPanOverride?.y ?? screen_y ?? 0;
    const { locations, selectedPort, menuOpen, zoom, dragClientX, dragClientY } = this.state;
    const connections = this.buildWireConnections(
      components,
      locations,
      selectedPort,
      dragClientX,
      dragClientY,
      zoom,
    );
    const componentCount = components.reduce((n, c) => n + (c ? 1 : 0), 0);
    const variableCount = variables?.length ?? 0;
    const zoomPercent = Math.round((zoom || 1) * 100);
    /** Только корпус сборки (не одиночный чип в руках) — вставка чипа в поле. */
    const ieAssemblyUi = !!ie_circuit && ie_clone_copy_mode === 'assembly';

    return (
      <Window
        width={920}
        height={720}
        buttons={(
          <Box
            className="IntegratedCircuit__titleNameWrap"
            position="absolute"
            left={0}
            top="4px"
            height="24px"
          >
            <Stack align="center" wrap="nowrap">
              <Stack.Item>
                <Input
                  width="260px"
                  maxWidth="min(100%, 320px)"
                  placeholder={ie_circuit
                    ? 'Имя корпуса (не поиск по деталям)'
                    : 'Имя схемы'}
                  value={display_name}
                  onChange={(e, value) => act("set_display_name", { display_name: value })}
                />
              </Stack.Item>
              {!ie_circuit && (
                <Stack.Item>
                  <Button
                    color="transparent"
                    icon="cog"
                    tooltip="Переменные и сеттеры/геттеры"
                    selected={menuOpen}
                    onClick={() => this.setState((state) => ({
                      menuOpen: !state.menuOpen,
                    }))}
                  />
                </Stack.Item>
              )}
              {!!is_admin && !ie_circuit && (
                <Stack.Item>
                  <Button
                    color="transparent"
                    tooltip="Сохранить схему (JSON)"
                    onClick={() => act("save_circuit")}
                    icon="save"
                  />
                </Stack.Item>
              )}
            </Stack>
          </Box>
        )}
      >
        <Window.Content
          fitted
          className="IntegratedCircuit__content"
          data-ic-rainbow={this.state.lgbtqRainbowMode ? '' : undefined}
          style={{
            'background-image': 'none',
          }}>
          <Box className="IntegratedCircuit__frame">
            <CircuitToolbar
              circuitOn={circuit_on}
              componentCount={componentCount}
              variableCount={variableCount}
              zoomPercent={zoomPercent}
              showVariableChip={!ie_circuit}
              lgbtqRainbowMode={this.state.lgbtqRainbowMode}
              onLgbtqRainbowToggle={() => this.setState((s) => ({
                lgbtqRainbowMode: !s.lgbtqRainbowMode,
              }))}
              ieBatteryPercent={ieBatteryPercent}
              circuitCellPercent={circuitCellPercent}
              onEjectPowerCell={
                (ie_circuit && ieBatteryPercent !== null)
                || (!ie_circuit && circuitCellPercent !== null && circuitCellPercent !== undefined)
                  ? () => act(ie_circuit ? 'ie_eject_battery' : 'eject_circuit_cell')
                  : undefined
              }
              ieCloneCopyMode={ie_circuit ? ie_clone_copy_mode : null}
              ieUsedSize={ieUsedSize}
              ieMaxSize={ieMaxSize}
              ieUsedComplexity={ieUsedComplexity}
              ieMaxComplexity={ieMaxComplexity}
              onIeCloneCopy={
                ie_circuit
                && (ie_clone_copy_mode === 'assembly' || ie_clone_copy_mode === 'chip')
                  ? () =>
                    act(
                      ie_clone_copy_mode === 'assembly'
                        ? 'ie_copy_assembly_code'
                        : 'ie_copy_component_code',
                    )
                  : undefined
              }
              onIeClassicUi={
                ie_circuit ? () => act('ie_switch_classic_ui') : undefined
              }
              onIePlaceChipCenter={
                ieAssemblyUi ? this.handleIePlaceChipCenter : undefined
              }
            />
            <Box className="IntegratedCircuit__planeHost">
              <InfinitePlane
                width="100%"
                height="100%"
                backgroundImage={resolveAsset('grid_background.png')}
                imageWidth={1200}
                onZoomChange={this.handleZoomChange}
                onBackgroundMoved={this.handleBackgroundMoved}
                initialLeft={panX}
                initialTop={panY}
                resetPanNonce={this.state.planeHomeNonce}
                onShiftPlaneMouseDown={
                  ieAssemblyUi ? this.handleShiftPlaneMouseDown : undefined
                }
              >
                <Connections
                  connections={connections}
                  svgRef={this.connectionsSvgRef}
                  pulseOutRef={circuit_pulse_out_ref ?? null}
                  pulseInRef={circuit_pulse_in_ref ?? null}>
                  {components.map(
                    (comp, index) =>
                      comp && (
                        <ObjectComponent
                          key={index}
                          {...comp}
                          index={index + 1}
                          circuitOn={circuit_on ?? true}
                          portLayoutKey={`${zoom}|${this.state.backgroundX}|${this.state.backgroundY}`}
                          onPortUpdated={this.handlePortLocation}
                          onPortLoaded={this.handlePortLocation}
                          onPortMouseDown={this.handlePortClick}
                          onPortRightClick={this.handlePortRightClick}
                          onPortMouseUp={this.handlePortUp}
                          debugCopyRef={!!ie_circuit && !!ie_debug_copy_ref}
                        />
                      )
                  )}
                </Connections>
              </InfinitePlane>
            </Box>
          </Box>
          {!!examined_name && (
            <CircuitInfo
              position="absolute"
              className="CircuitInfo__Examined"
              top={`${examined_rel_y}px`}
              left={`${examined_rel_x}px`}
              name={examined_name}
              desc={examined_desc}
              notices={examined_notices}
            />
          )}
          {!!menuOpen && !ie_circuit && (
            <Box
              className="IntegratedCircuit__variableDock"
              position="absolute"
              bottom={0}
              left={0}
              height="50%"
              minHeight="300px"
              width="100%"
            >
              <VariableMenu
                variables={variables}
                types={global_basic_types}
                onAddVariable={(name, type, event) => act("add_variable", {
                  variable_name: name,
                  variable_datatype: type,
                })}
                onRemoveVariable={(name, event) => act("remove_variable", {
                  variable_name: name,
                })}
                handleAddSetter={(e) => act("add_setter_or_getter", {
                  is_setter: true,
                })}
                handleAddGetter={(e) => act("add_setter_or_getter", {
                  is_setter: false,
                })}
              />
            </Box>
          )}
        </Window.Content>
      </Window>
    );
  }
}

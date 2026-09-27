import { Component, createRef } from 'react';

import { resolveAsset } from '../../assets';
import { useBackend } from '../../backend';
import {
  Box,
  Button,
  Icon,
  InfinitePlane,
  Input,
  Section,
  Stack,
} from '../../components';
import { Window } from '../../layouts';
import {
  byondListToArray,
  connectedToRefList,
  normalizeCircuitComponent,
} from './byondPayload';
import { CircuitInfo } from './CircuitInfo';
import { CircuitToolbar } from './CircuitToolbar';
import { Connections } from './Connections';
import { ABSOLUTE_Y_OFFSET, MOUSE_BUTTON_LEFT } from './constants';
import { ObjectComponent } from './ObjectComponent';
import { PinEditor } from './PinEditor';
import type {
  CircuitComponentView,
  CircuitPortPayload,
  CircuitPulse,
  GroupDragState,
  IntegratedCircuitData,
  IntegratedCircuitState,
  PortLocation,
  SelectedPortState,
  WireConnection,
} from './types';
import { VariableMenu } from './VariableMenu';

/** Карта REF порта → подпись «Компонент · Порт» для попапа порядка связей. */
function buildPortLabelByRef(
  components: (CircuitComponentView | null)[],
): Map<string, string> {
  const portLabelByRef = new Map<string, string>();
  for (const comp of components) {
    if (!comp) {
      continue;
    }
    const compLabel = comp.name || '';
    for (const p of comp.input_ports) {
      portLabelByRef.set(p.ref, `${compLabel} · ${p.name}`);
    }
    for (const p of comp.output_ports) {
      portLabelByRef.set(p.ref, `${compLabel} · ${p.name}`);
    }
  }
  return portLabelByRef;
}

/** Ключи «живых» импульсов проводов: out\0in. IE отдаёт список, wiremod — один ref. */
function buildPulseKeys(
  circuit_pulses: CircuitPulse[] | null | undefined,
  circuit_pulse_out_ref: string | null | undefined,
  circuit_pulse_in_ref: string | null | undefined,
): Set<string> {
  const pulseKeys = new Set<string>();
  if (Array.isArray(circuit_pulses)) {
    for (const pulse of circuit_pulses) {
      if (pulse && pulse.out && pulse.in) {
        pulseKeys.add(`${pulse.out}\u0000${pulse.in}`);
      }
    }
  }
  else if (circuit_pulse_out_ref && circuit_pulse_in_ref) {
    pulseKeys.add(`${circuit_pulse_out_ref}\u0000${circuit_pulse_in_ref}`);
  }
  return pulseKeys;
}

export class IntegratedCircuit extends Component<unknown, IntegratedCircuitState> {
  connectionsSvgRef = createRef<SVGSVGElement>();
  /** Смещали ли поле мышью с прошлого сохранённого screen_x/y (не слать move_screen на каждый mouseup). */
  planePanDirty = false;
  /** Позиции портов, ожидающие перемеривания; замер переносится в requestAnimationFrame, чтобы сотни getBoundingClientRect не превращались в сотни синхронных reflow за кадр. */
  locationPending = new Map<string, { port: CircuitPortPayload; dom: HTMLElement }>();
  locationRaf: number | null = null;
  /** Актуальный нормализованный массив компонентов (для группового драга). */
  latestComponents: (CircuitComponentView | null)[] = [];
  /** Старт курсора при mousedown по порту: отличает клик от перетаскивания провода. */
  portDragStartX = 0;
  portDragStartY = 0;
  portDragMoved = false;

  constructor(props: unknown) {
    super(props);
    this.state = {
      locations: {},
      selectedPort: null,
      connectSource: null,
      dragClientX: null,
      dragClientY: null,
      zoom: 1,
      backgroundX: 0,
      backgroundY: 0,
      menuOpen: false,
      lgbtqRainbowMode: false,
      screenPanOverride: null,
      planeHomeNonce: 0,
      componentsPanelOpen: false,
      componentsFilter: '',
      selection: [],
      dragState: null,
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

    this.handleNodeMouseDown = this.handleNodeMouseDown.bind(this);
    this.handleNodeDrag = this.handleNodeDrag.bind(this);
    this.handleNodeDragEnd = this.handleNodeDragEnd.bind(this);
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
    if (!dom || !dom.isConnected) {
      return;
    }
    this.locationPending.set(port.ref, { port, dom });
    if (this.locationRaf === null) {
      this.locationRaf = requestAnimationFrame(() => {
        this.locationRaf = null;
        this.flushPortLocations();
      });
    }
  }

  /**
   * Один замер на кадр: перечитываем только порты, которые просили обновление,
   * и шлём один setState, если что-то реально сдвинулось. Убирает O(портов)
   * форс-layout на каждый «пустой» апдейт данных от сервера.
   */
  flushPortLocations() {
    const pending = this.locationPending;
    if (pending.size === 0) {
      return;
    }
    this.locationPending = new Map();
    const { locations } = this.state;
    let next: Record<string, PortLocation> | null = null;
    pending.forEach(({ port, dom }) => {
      if (!dom.isConnected) {
        return;
      }
      const position = this.getPosition(dom);
      const withColor = { x: position.x, y: position.y, color: port.color };
      if (Number.isNaN(withColor.x) || Number.isNaN(withColor.y)) {
        return;
      }
      const last = locations[port.ref];
      if (
        last
        && last.x === withColor.x
        && last.y === withColor.y
      ) {
        return;
      }
      if (!next) {
        next = { ...locations };
      }
      next[port.ref] = withColor;
    });
    if (next) {
      this.setState({ locations: next });
    }
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

    // Клик → клик: если пин уже «выбран» без перетаскивания, второй клик по
    // противоположному пину сразу соединяет их — тянуть провод не обязательно.
    const connectSource = this.state.connectSource;
    if (connectSource) {
      if (connectSource.ref === port.ref) {
        // Повторный клик по уже выбранному пину — снять выбор.
        this.setState({ connectSource: null });
      } else if (connectSource.is_output === isOutput) {
        // Тот же тип: просто переносим «источник» на этот пин.
        this.setState({
          connectSource: {
            index: portIndex,
            component_id: componentId,
            is_output: isOutput,
            ref: port.ref,
          },
        });
      } else {
        this.connectPins(connectSource, {
          index: portIndex,
          component_id: componentId,
          is_output: isOutput,
        });
        this.setState({ connectSource: null });
      }
      return;
    }

    // Обычное перетаскивание провода (mousedown — mousemove — mouseup).
    this.portDragMoved = false;
    this.portDragStartX = event.clientX;
    this.portDragStartY = event.clientY;
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

  connectPins(
    source: SelectedPortState,
    target: { index: number; component_id: number; is_output: boolean },
  ) {
    const { act } = useBackend<IntegratedCircuitData>();
    let data;
    if (target.is_output) {
      data = {
        input_port_id: source.index,
        output_port_id: target.index,
        input_component_id: source.component_id,
        output_component_id: target.component_id,
      };
    } else {
      data = {
        input_port_id: target.index,
        output_port_id: source.index,
        input_component_id: target.component_id,
        output_component_id: source.component_id,
      };
    }
    act("add_connection", data);
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
    const {
      selectedPort,
    } = this.state;
    if (!selectedPort) {
      return;
    }
    if (selectedPort.is_output === isOutput) {
      return;
    }
    this.connectPins(selectedPort, {
      index: portIndex,
      component_id: componentId,
      is_output: isOutput,
    });
  }

  handlePortDrag(event: MouseEvent) {
    if (!this.portDragMoved) {
      const dx = event.clientX - this.portDragStartX;
      const dy = event.clientY - this.portDragStartY;
      if (dx * dx + dy * dy < 9) {
        return;
      }
      this.portDragMoved = true;
    }
    this.setState({
      dragClientX: event.clientX,
      dragClientY: event.clientY,
    });
  }

  handlePortRelease(_event: MouseEvent) {
    const { selectedPort } = this.state;
    if (selectedPort && !this.portDragMoved) {
      // Был клик без перетаскивания — оставляем пин «выбранным» для клик → клик.
      this.setState({
        connectSource: selectedPort,
        selectedPort: null,
        dragClientX: null,
        dragClientY: null,
      });
    } else {
      this.setState({
        selectedPort: null,
        dragClientX: null,
        dragClientY: null,
      });
    }
    this.portDragMoved = false;

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
    const { act } = useBackend<IntegratedCircuitData>();

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
    const { act } = useBackend<IntegratedCircuitData>();
    this.planePanDirty = false;
    this.setState((s) => ({
      screenPanOverride: { x: 0, y: 0 },
      backgroundX: 0,
      backgroundY: 0,
      planeHomeNonce: s.planeHomeNonce + 1,
    }));
    act('move_screen', { screen_x: 0, screen_y: 0 });
  }

  /** Отцентрировать поле на компоненте из списка (jump to). */
  handleJumpToComponent(comp: CircuitComponentView) {
    const { act } = useBackend<IntegratedCircuitData>();
    const svg = this.connectionsSvgRef?.current;
    const z = Math.max(this.state.zoom || 1, 0.01);
    let targetX = 0;
    let targetY = 0;
    if (svg) {
      const r = svg.getBoundingClientRect();
      targetX = r.width / 3 - (comp.x || 0) * z;
      targetY = r.height / 3 - (comp.y || 0) * z;
    }
    this.planePanDirty = false;
    this.setState((s) => ({
      screenPanOverride: { x: targetX, y: targetY },
      backgroundX: targetX,
      backgroundY: targetY,
      planeHomeNonce: s.planeHomeNonce + 1,
    }));
    act('move_screen', { screen_x: targetX, screen_y: targetY });
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
    const { act, data } = useBackend<IntegratedCircuitData>();
    if (!data.ie_circuit || data.ie_clone_copy_mode !== 'assembly') {
      return;
    }
    const { rel_x, rel_y } = this.ieClientToCircuitCoords(event.clientX, event.clientY);
    act('ie_place_hand_chip_at', { rel_x, rel_y });
  };

  handleIePlaceChipCenter = () => {
    const { act, data } = useBackend<IntegratedCircuitData>();
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
    const { data } = useBackend<IntegratedCircuitData>();
    if (!this.state.screenPanOverride) {
      return;
    }
    const sx = data.screen_x;
    const sy = data.screen_y;
    const ox = this.state.screenPanOverride.x;
    const oy = this.state.screenPanOverride.y;
    // Сбрасываем подмену якоря, когда сервер подтвердил наши координаты (0,0 или цель прыжка).
    if (
      typeof sx === 'number'
      && typeof sy === 'number'
      && Math.abs(sx - ox) < 0.01
      && Math.abs(sy - oy) < 0.01
    ) {
      this.setState({ screenPanOverride: null });
    }
  }

  componentDidMount() {
    window.addEventListener('mousedown', this.handleMouseDown);
    window.addEventListener('mouseup', this.handleMouseUp);
    window.addEventListener('keydown', this.handleWindowKeyDown);
  }

  componentWillUnmount() {
    window.removeEventListener('mousedown', this.handleMouseDown);
    window.removeEventListener('mouseup', this.handleMouseUp);
    window.removeEventListener('keydown', this.handleWindowKeyDown);
    window.removeEventListener('mousemove', this.handlePortDrag);
    window.removeEventListener('mouseup', this.handlePortRelease);
    window.removeEventListener('mousemove', this.handleNodeDrag);
    window.removeEventListener('mouseup', this.handleNodeDragEnd);
    if (this.locationRaf !== null) {
      cancelAnimationFrame(this.locationRaf);
      this.locationRaf = null;
    }
    this.locationPending.clear();
  }

  handleMouseDown(_event: MouseEvent) {
    const { act, data } = useBackend<IntegratedCircuitData>();
    const { examined_name } = data;
    if (examined_name) {
      act('remove_examined_component');
    }
    // Клик по пустому полю (не по ноде — ноды стопают пропагацию) снимает выделение.
    // «Клик → клик» (connectSource) намеренно НЕ сбрасываем: игрок должен иметь
    // возможность пановать схему и соединить выбранный пин кликом в другом месте.
    if (this.state.selection.length) {
      this.setState({ selection: [] });
    }
  }

  handleWindowKeyDown = (event: KeyboardEvent) => {
    if (event.key !== 'Escape') {
      return;
    }
    const { connectSource, selectedPort, selection } = this.state;
    if (!connectSource && !selectedPort && selection.length === 0) {
      return;
    }
    this.setState({
      connectSource: null,
      selectedPort: null,
      selection: [],
    });
  }

  handleMouseUp(_event: MouseEvent) {
    if (!this.planePanDirty) {
      return;
    }
    this.planePanDirty = false;
    const { act } = useBackend<IntegratedCircuitData>();
    const { backgroundX, backgroundY } = this.state;
    act("move_screen", {
      screen_x: backgroundX,
      screen_y: backgroundY,
    });
  }

  handleNodeMouseDown(componentId: number, event: MouseEvent) {
    event.stopPropagation();
    const additive = event.shiftKey || event.ctrlKey || event.metaKey;
    const { selection } = this.state;
    let nextSelection: number[];
    if (additive) {
      nextSelection = selection.includes(componentId)
        ? selection.filter((id) => id !== componentId)
        : [...selection, componentId];
    }
    else if (selection.includes(componentId)) {
      nextSelection = selection;
    }
    else {
      nextSelection = [componentId];
    }
    if (!nextSelection.length) {
      this.setState({ selection: [] });
      return;
    }
    const startPositions: GroupDragState['startPositions'] = {};
    for (const id of nextSelection) {
      const comp = this.latestComponents[id - 1];
      if (comp) {
        startPositions[id] = { x: comp.x || 0, y: comp.y || 0 };
      }
    }
    this.setState({
      selection: nextSelection,
      dragState: {
        ids: nextSelection,
        startPositions,
        startClientX: event.clientX,
        startClientY: event.clientY,
        deltaX: 0,
        deltaY: 0,
      },
    });
    window.addEventListener('mousemove', this.handleNodeDrag);
    window.addEventListener('mouseup', this.handleNodeDragEnd);
  }

  handleNodeDrag(event: MouseEvent) {
    const { dragState } = this.state;
    if (!dragState) {
      return;
    }
    event.preventDefault();
    const z = Math.max(this.state.zoom || 1, 0.01);
    const deltaX = (event.clientX - dragState.startClientX) / z;
    const deltaY = (event.clientY - dragState.startClientY) / z;
    if (deltaX !== dragState.deltaX || deltaY !== dragState.deltaY) {
      this.setState((s) => s.dragState
        ? { dragState: { ...s.dragState, deltaX, deltaY } }
        : null);
    }
  }

  handleNodeDragEnd() {
    window.removeEventListener('mousemove', this.handleNodeDrag);
    window.removeEventListener('mouseup', this.handleNodeDragEnd);
    const { dragState } = this.state;
    if (dragState) {
      const { act } = useBackend<IntegratedCircuitData>();
      const moved = dragState.deltaX !== 0 || dragState.deltaY !== 0;
      if (moved) {
        for (const id of dragState.ids) {
          const start = dragState.startPositions[id];
          if (!start) {
            continue;
          }
          act('set_component_coordinates', {
            component_id: id,
            rel_x: Math.round(start.x + dragState.deltaX),
            rel_y: Math.round(start.y + dragState.deltaY),
          });
        }
      }
    }
    this.setState({ dragState: null });
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
        // REF-строки сравниваем код-поинтами (быстрее localeCompare на сотнях проводов).
        return a.outRef < b.outRef ? -1 : 1;
      }
      const ia = fanOutOrder.get(`${a.outRef}\0${a.inRef}`) ?? 999;
      const ib = fanOutOrder.get(`${b.outRef}\0${b.inRef}`) ?? 999;
      return ia - ib;
    });

    return connections;
  }

  render() {
    const { act, data } = useBackend<IntegratedCircuitData>();
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
      circuit_pulses,
      circuit_pulse_out_ref,
      circuit_pulse_in_ref,
    } = data;
    const components = byondListToArray(data.components).map(
      normalizeCircuitComponent,
    );
    this.latestComponents = components;
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
    const { componentsPanelOpen, componentsFilter, selection, dragState } = this.state;
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
    const filterQuery = componentsFilter.trim().toLowerCase();
    const filteredComponents = components
      .map((comp, i) => (comp ? { comp, index: i + 1 } : null))
      .filter((entry): entry is { comp: CircuitComponentView; index: number } =>
        entry !== null
        && (!filterQuery
          || entry.comp.name.toLowerCase().includes(filterQuery)
          || String(entry.index).includes(filterQuery)));
    /** Только корпус сборки (не одиночный чип в руках) — вставка чипа в поле. */
    const ieAssemblyUi = !!ie_circuit && ie_clone_copy_mode === 'assembly';

    // Карта REF порта → подпись «Компонент · Порт» для попапа порядка связей.
    const portLabelByRef = buildPortLabelByRef(components);

    // Ключи «живых» импульсов проводов: out\0in. IE отдаёт список, wiremod — один ref.
    const pulseKeys = buildPulseKeys(
      circuit_pulses,
      circuit_pulse_out_ref,
      circuit_pulse_in_ref,
    );

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
            backgroundImage: 'none',
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
                  pulseKeys={pulseKeys}>
                  {components.map(
                    (comp, index) =>
                      comp && (() => {
                        const componentId = index + 1;
                        const dragging = !!dragState && dragState.ids.includes(componentId);
                        const dx = dragging ? dragState.deltaX : 0;
                        const dy = dragging ? dragState.deltaY : 0;
                        return (
                          <ObjectComponent
                            key={index}
                            {...comp}
                            x={(comp.x || 0) + dx}
                            y={(comp.y || 0) + dy}
                            index={componentId}
                            circuitOn={circuit_on ?? true}
                            portLayoutKey={`${zoom}|${this.state.backgroundX}|${this.state.backgroundY}`}
                            onPortUpdated={this.handlePortLocation}
                            onPortLoaded={this.handlePortLocation}
                            onPortMouseDown={this.handlePortClick}
                            onPortRightClick={this.handlePortRightClick}
                            onPortMouseUp={this.handlePortUp}
                            portLabelByRef={portLabelByRef}
                            connectSourceRef={this.state.connectSource?.ref ?? null}
                            selected={selection.includes(componentId)}
                            onNodeMouseDown={(e) => this.handleNodeMouseDown(componentId, e)}
                          />
                        );
                      })()
                  )}
                </Connections>
              </InfinitePlane>
              <Box
                className="IntegratedCircuit__componentsToggle"
                position="absolute"
                right="0.5rem"
                top="2rem"
                style={{ zIndex: 6 }}>
                <Button
                  icon="list-ul"
                  selected={componentsPanelOpen}
                  color="transparent"
                  tooltip="Список компонентов (прыжок к компоненту)"
                  onClick={() => this.setState((s) => ({
                    componentsPanelOpen: !s.componentsPanelOpen,
                  }))}>
                  Компоненты
                </Button>
              </Box>
              {componentsPanelOpen && (
                <Box
                  className="IntegratedCircuit__componentsPanel"
                  position="absolute"
                  right="0"
                  top="2.9rem"
                  bottom="0"
                  width="18rem"
                  style={{ zIndex: 6 }}>
                  <Section
                    title={`Компоненты (${componentCount})`}
                    fill
                    scrollable
                    buttons={(
                      <Button
                        icon="times"
                        color="transparent"
                        tooltip="Закрыть список"
                        onClick={() => this.setState({ componentsPanelOpen: false })}
                      />
                    )}>
                    <Stack vertical>
                      <Stack.Item>
                        <Input
                          fluid
                          placeholder="Поиск по имени / номеру…"
                          value={componentsFilter}
                          onChange={(e, val) => this.setState({ componentsFilter: val })}
                        />
                      </Stack.Item>
                      {filteredComponents.length === 0 && (
                        <Stack.Item>
                          <Box color="label" opacity={0.7} mt={0.5}>
                            {components.length === 0 ? 'Нет компонентов' : 'Ничего не найдено'}
                          </Box>
                        </Stack.Item>
                      )}
                      {filteredComponents.map(({ comp, index }) => (
                        <Stack.Item key={index}>
                          <Button
                            fluid
                            color="transparent"
                            tooltip={`Перейти к «${comp.name}»`}
                            onClick={() => this.handleJumpToComponent(comp)}>
                            <Icon name="circle" color={comp.color || 'blue'} />
                            {' '}
                            #{index}
                            {' '}
                            {comp.name}
                          </Button>
                        </Stack.Item>
                      ))}
                    </Stack>
                  </Section>
                </Box>
              )}
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
          <PinEditor />
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

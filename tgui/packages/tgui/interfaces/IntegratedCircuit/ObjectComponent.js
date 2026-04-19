import { Component } from 'inferno';

import { classes, shallowDiffers } from '../../../common/react';
import { useBackend } from '../../backend';
import {
  Box,
  Button,
  Icon,
  Input,
  Stack,
} from '../../components';
import { ABSOLUTE_Y_OFFSET } from './constants';
import { formatIeCooldownDs, formatIeSizeDisplay } from './circuitNodeFormat';
import { byondListToArray } from './byondPayload';
import { Port } from './Port';


export class ObjectComponent extends Component {
  constructor() {
    super();
    this.state = {
      isDragging: false,
      dragPos: null,
      startPos: null,
      lastMousePos: null,
      editingNodeTitle: false,
      nodeTitleDraft: '',
    };

    this.handleStartDrag = this.handleStartDrag.bind(this);
    this.handleStopDrag = this.handleStopDrag.bind(this);
    this.handleDrag = this.handleDrag.bind(this);
    this.commitNodeTitleEdit = this.commitNodeTitleEdit.bind(this);
  }

  commitNodeTitleEdit() {
    const { act } = useBackend(this.context);
    const { name, index } = this.props;
    const { nodeTitleDraft } = this.state;
    const trimmed = (nodeTitleDraft ?? '').trim();
    this.setState({ editingNodeTitle: false });
    if (trimmed && trimmed !== name) {
      act('set_component_display_name', {
        component_id: index,
        display_name: trimmed,
      });
    }
  }

  handleStartDrag(e) {
    const { x, y } = this.props;
    e.stopPropagation();
    this.setState({
      lastMousePos: null,
      isDragging: true,
      dragPos: { x: x, y: y },
      startPos: { x: x, y: y },
    });
    window.addEventListener('mousemove', this.handleDrag);
    window.addEventListener('mouseup', this.handleStopDrag);
  }

  handleStopDrag(e) {
    const { act } = useBackend(this.context);
    const { dragPos } = this.state;
    const { index } = this.props;
    if (dragPos) {
      act('set_component_coordinates', {
        component_id: index,
        rel_x: dragPos.x,
        rel_y: dragPos.y,
      });
    }

    window.removeEventListener('mousemove', this.handleDrag);
    window.removeEventListener('mouseup', this.handleStopDrag);
    this.setState({ isDragging: false });
  }

  handleDrag(e) {
    const { dragPos, isDragging, lastMousePos } = this.state;
    if (dragPos && isDragging) {
      e.preventDefault();
      const { screenZoomX, screenZoomY, screenX, screenY } = e;
      let xPos = screenZoomX || screenX;
      let yPos = screenZoomY || screenY;
      if (lastMousePos) {
        this.setState({
          dragPos: {
            x: dragPos.x - (lastMousePos.x - xPos),
            y: dragPos.y - (lastMousePos.y - yPos),
          },
        });
      }
      this.setState({
        lastMousePos: { x: xPos, y: yPos },
      });
    }
  }

  shouldComponentUpdate(nextProps, nextState) {
    const { input_ports, output_ports } = this.props;

    return (
      shallowDiffers(this.props, nextProps)
      || shallowDiffers(this.state, nextState)
      || shallowDiffers(input_ports, nextProps.input_ports)
      || shallowDiffers(output_ports, nextProps.output_ports)
    );
  }

  render() {
    const {
      input_ports: rawInputPorts,
      output_ports: rawOutputPorts,
      name,
      x,
      y,
      index,
      color = 'blue',
      removable,
      recent_pulse,
      circuitOn,
      locations,
      onPortUpdated,
      onPortLoaded,
      onPortMouseDown,
      onPortRightClick,
      onPortMouseUp,
      portLayoutKey: _portLayoutKey,
      debugCopyRef,
      ie_size,
      ie_complexity,
      ie_cooldown_ds,
      ie_ext_cooldown_ds,
      power_usage_per_input,
      ...rest
    } = this.props;
    const input_ports = byondListToArray(rawInputPorts);
    const output_ports = byondListToArray(rawOutputPorts);
    const { act, data } = useBackend(this.context);
    const isIe = !!data.ie_circuit;
    const showIeNodeStats = isIe && typeof ie_complexity === 'number';
    const showWiremodPower = !isIe && typeof power_usage_per_input === 'number';

    const rowsWithIndex = (ports) =>
      ports.map((port, i) => ({ port, portIndex: i + 1 }));
    const isPulse = (p) => p.type === 'signal';
    const dataInputs = rowsWithIndex(input_ports).filter((r) => !isPulse(r.port));
    const pulseInputs = rowsWithIndex(input_ports).filter((r) => isPulse(r.port));
    const dataOutputs = rowsWithIndex(output_ports).filter((r) => !isPulse(r.port));
    const pulseOutputs = rowsWithIndex(output_ports).filter((r) => isPulse(r.port));
    const hasDataZone = dataInputs.length > 0 || dataOutputs.length > 0;
    const hasPulseZone = pulseInputs.length > 0 || pulseOutputs.length > 0;

    const renderPortList = (rows, isOutput) =>
      rows.map(({ port, portIndex }) => (
        <Stack.Item key={`${isOutput ? 'o' : 'i'}-${port.ref || portIndex}`}>
          <Port
            port={port}
            portIndex={portIndex}
            componentId={index}
            isOutput={!!isOutput}
            act={act}
            {...PortOptions}
          />
        </Stack.Item>
      ));

    const renderPortColumns = (inRows, outRows) => (
      <Stack className="ObjectComponent__portColumns">
        <Stack.Item grow={1}>
          <Box className="ObjectComponent__colLabel" textAlign="left">
            Входы
          </Box>
          <Stack vertical>
            {renderPortList(inRows, false)}
          </Stack>
        </Stack.Item>
        <Stack.Item ml={5}>
          <Box className="ObjectComponent__colLabel" textAlign="right">
            Выходы
          </Box>
          <Stack vertical>
            {renderPortList(outRows, true)}
          </Stack>
        </Stack.Item>
      </Stack>
    );
    const { startPos, dragPos } = this.state;
    const powered = !!circuitOn;

    let [x_pos, y_pos] = [x, y];
    if (dragPos && startPos && startPos.x === x_pos && startPos.y === y_pos) {
      x_pos = dragPos.x;
      y_pos = dragPos.y;
    }

    // Assigned onto the ports
    const PortOptions = {
      onPortLoaded: onPortLoaded,
      onPortUpdated: onPortUpdated,
      onPortMouseDown: onPortMouseDown,
      onPortRightClick: onPortRightClick,
      onPortMouseUp: onPortMouseUp,
    };

    return (
      <Box
        {...rest}
        position="absolute"
        left={`${x_pos}px`}
        top={`${y_pos}px`}
        className={classes([
          'ObjectComponent__root',
          !powered && 'ObjectComponent--poweroff',
          recent_pulse && powered && 'ObjectComponent--recentPulse',
        ])}
        onMouseDown={this.handleStartDrag}
        onMouseUp={this.handleStopDrag}
        onComponentWillUnmount={this.handleDrag}>
        <Box
          backgroundColor={color}
          py={1}
          px={1}
          className="ObjectComponent__Titlebar">
          <Stack align="center">
            <Stack.Item>
              <Box
                className={classes([
                  'ObjectComponent__ActivityLamp',
                  recent_pulse && powered && 'ObjectComponent__ActivityLamp--pulse',
                  !powered && 'ObjectComponent__ActivityLamp--off',
                ])}
                title={
                  !powered
                    ? 'Плата выключена'
                    : recent_pulse
                      ? 'Компонент недавно выполнялся'
                      : 'Ожидание'
                }
              />
            </Stack.Item>
            <Stack.Item>
              <Icon
                name="arrows-alt"
                size={0.85}
                opacity={0.65}
                title="Перетащить ноду"
              />
            </Stack.Item>
            <Stack.Item grow={1} unselectable="on">
              {!!showIeNodeStats && this.state.editingNodeTitle ? (
                <Input
                  autoFocus
                  className="ObjectComponent__titleInput"
                  value={this.state.nodeTitleDraft}
                  onMouseDown={(e) => e.stopPropagation()}
                  onInput={(e, val) =>
                    this.setState({ nodeTitleDraft: val })}
                  onBlur={() => this.commitNodeTitleEdit()}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      e.currentTarget.blur();
                    }
                    if (e.key === 'Escape') {
                      this.setState({
                        editingNodeTitle: false,
                        nodeTitleDraft: name,
                      });
                    }
                  }}
                />
              ) : (
                <Box
                  className="ObjectComponent__titleText"
                  title="Двойной клик или карандаш — переименовать; второй клик по карандашу — подтвердить"
                  onMouseDown={(e) => e.stopPropagation()}
                  onDblClick={(e) => {
                    e.stopPropagation();
                    if (!showIeNodeStats) {
                      return;
                    }
                    this.setState({
                      editingNodeTitle: true,
                      nodeTitleDraft: name,
                    });
                  }}>
                  {name}
                </Box>
              )}
            </Stack.Item>
            {!!showIeNodeStats && (
              <Stack.Item>
                <Button
                  color="transparent"
                  icon="pen"
                  compact
                  tooltip={
                    this.state.editingNodeTitle
                      ? 'Подтвердить имя'
                      : 'Переименовать ноду'
                  }
                  onMouseDown={(e) => {
                    e.stopPropagation();
                    if (this.state.editingNodeTitle) {
                      e.preventDefault();
                    }
                  }}
                  onClick={(e) => {
                    e.stopPropagation();
                    if (this.state.editingNodeTitle) {
                      this.commitNodeTitleEdit();
                    } else {
                      this.setState({
                        editingNodeTitle: true,
                        nodeTitleDraft: name,
                      });
                    }
                  }}
                />
              </Stack.Item>
            )}
            <Stack.Item>
              <Button
                color="transparent"
                icon="info"
                compact
                tooltip="Описание и подсказки"
                onClick={(e) => act('set_examined_component', {
                  component_id: index,
                  x: e.pageX,
                  y: e.pageY + ABSOLUTE_Y_OFFSET,
                })} />
            </Stack.Item>
            {!!debugCopyRef && (
              <Stack.Item>
                <Button
                  color="transparent"
                  icon="hashtag"
                  compact
                  tooltip="Ref чипа в чат (только R_DEBUG)"
                  onClick={() => act('ie_copy_component_ref', {
                    component_id: index,
                  })} />
              </Stack.Item>
            )}
            {!!removable && (
              <Stack.Item>
                <Button
                  color="transparent"
                  icon="times"
                  compact
                  tooltip="Снять с платы"
                  onClick={() => act('detach_component', { component_id: index })} />
              </Stack.Item>
            )}
          </Stack>
        </Box>
        {!!showIeNodeStats && (
          <Box className="ObjectComponent__ieStats" px={1} py={0.35}>
            <Box
              className="ObjectComponent__ieStatsText"
              title={'Размер и сложность — лимиты корпуса. КД — пауза компонента после срабатывания. Внеш. КД — общая пауза корпуса при действиях компонента в мир.'}>
              Разм. {formatIeSizeDisplay(ie_size)} · Сложн. {ie_complexity} · КД {formatIeCooldownDs(ie_cooldown_ds, false)} · Вн. КД {formatIeCooldownDs(ie_ext_cooldown_ds, true)}
            </Box>
          </Box>
        )}
        {!!showWiremodPower && (
          <Box className="ObjectComponent__ieStats ObjectComponent__ieStats--wiremod" px={1} py={0.35}>
            <Box
              className="ObjectComponent__ieStatsText"
              title="Расход заряда ячейки на одно срабатывание входа">
              Энергия: {power_usage_per_input} за вход
            </Box>
          </Box>
        )}
        <Box
          className="ObjectComponent__Content"
          unselectable="on"
          py={1}
          px={1}>
          {!!hasDataZone && (
            <Box className="ObjectComponent__dataZone">
              {!!(hasDataZone && hasPulseZone) && (
                <Box className="ObjectComponent__zoneLabel">
                  Данные
                </Box>
              )}
              {renderPortColumns(dataInputs, dataOutputs)}
            </Box>
          )}
          {!!hasPulseZone && (
            <Box
              className={classes([
                'ObjectComponent__pulseZone',
                hasDataZone && 'ObjectComponent__pulseZone--split',
              ])}>
              <Box className="ObjectComponent__zoneLabel ObjectComponent__zoneLabel--pulse">
                Импульсы
              </Box>
              {renderPortColumns(pulseInputs, pulseOutputs)}
            </Box>
          )}
        </Box>
      </Box>
    );
  }
}

import { Component } from 'react';

import { classes, shallowDiffers } from '../../../common/react';
import { useBackend } from '../../backend';
import {
  Box,
  Button,
  Icon,
  Input,
  Stack,
} from '../../components';
import { byondListToArray } from './byondPayload';
import { formatIeCooldownDs, formatIeSizeDisplay } from './circuitNodeFormat';
import { ABSOLUTE_Y_OFFSET } from './constants';
import { Port } from './Port';

/**
 * Cheap structural equality for a single port row. Only the fields that can
 * change at runtime are compared (live value + wiring); name/type/color are
 * static for a mount so skipping them is safe and keeps this O(rows).
 */
const portSig = (p) => (p
  ? `${p.ref}\u0000${JSON.stringify(p.current_data)}\u0000${JSON.stringify(p.connected_to)}`
  : '');

const portsEqual = (a, b) => {
  if (a === b) {
    return true;
  }
  if (!a || !b || a.length !== b.length) {
    return false;
  }
  for (let i = 0; i < a.length; i++) {
    if (portSig(a[i]) !== portSig(b[i])) {
      return false;
    }
  }
  return true;
};


export class ObjectComponent extends Component {
  constructor() {
    super();
    this.state = {
      editingNodeTitle: false,
      nodeTitleDraft: '',
    };

    this.commitNodeTitleEdit = this.commitNodeTitleEdit.bind(this);
  }

  commitNodeTitleEdit() {
    const { act } = useBackend();
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

  shouldComponentUpdate(nextProps, nextState) {
    // Локальное состояние ноды (перетаскивание, переименование) — редкое и важное.
    if (shallowDiffers(this.state, nextState)) {
      return true;
    }
    // Смена зума/панорамы обязана перемерить позиции портов, даже если данные не
    // изменились: координаты проводов зависят от transform плоскости.
    if (this.props.portLayoutKey !== nextProps.portLayoutKey) {
      return true;
    }
    const p = this.props;
    const n = nextProps;
    if (
      p.x !== n.x
      || p.y !== n.y
      || p.name !== n.name
      || p.color !== n.color
      || p.removable !== n.removable
      || p.recent_pulse !== n.recent_pulse
      || p.circuitOn !== n.circuitOn
      || p.selected !== n.selected
      || p.connectSourceRef !== n.connectSourceRef
      || p.ie_size !== n.ie_size
      || p.ie_complexity !== n.ie_complexity
      || p.ie_cooldown_ds !== n.ie_cooldown_ds
      || p.ie_ext_cooldown_ds !== n.ie_ext_cooldown_ds
      || p.power_usage_per_input !== n.power_usage_per_input
      || !portsEqual(p.input_ports, n.input_ports)
      || !portsEqual(p.output_ports, n.output_ports)
    ) {
      return true;
    }
    return false;
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
      ie_size,
      ie_complexity,
      ie_cooldown_ds,
      ie_ext_cooldown_ds,
      power_usage_per_input,
      portLabelByRef,
      connectSourceRef,
      selected,
      onNodeMouseDown,
      ...rest
    } = this.props;
    const input_ports = byondListToArray(rawInputPorts);
    const output_ports = byondListToArray(rawOutputPorts);
    const { act, data } = useBackend();
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
            portLabelByRef={portLabelByRef}
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
    const powered = !!circuitOn;
    const x_pos = x;
    const y_pos = y;

    // Assigned onto the ports
    const PortOptions = {
      onPortLoaded: onPortLoaded,
      onPortUpdated: onPortUpdated,
      onPortMouseDown: onPortMouseDown,
      onPortRightClick: onPortRightClick,
      onPortMouseUp: onPortMouseUp,
      connectSourceRef: connectSourceRef,
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
          selected && 'ObjectComponent--selected',
        ])}
        onMouseDown={onNodeMouseDown}>
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
                  onDoubleClick={(e) => {
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

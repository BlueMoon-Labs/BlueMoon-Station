import { Component, createRef } from 'react';

import { classes } from '../../../common/react';
import {
  Box,
  Button,
  Icon,
  Stack,
} from '../../components';
import { connectedToRefList } from './byondPayload';
import { DisplayName } from './DisplayName';

const CONN_POPOVER_SHOW_MS = 240;
const CONN_POPOVER_HIDE_MS = 200;

export class Port extends Component {
  constructor() {
    super();
    this.iconRef = createRef();
    this.state = { connPopover: false, dragOverIndex: null };
    this.reorderSrc = null;
    this.hoverEnterTimer = null;
    this.hoverLeaveTimer = null;
    this.componentDidUpdate = this.componentDidUpdate.bind(this);
    this.componentDidMount = this.componentDidMount.bind(this);
    this.handlePortMouseDown = this.handlePortMouseDown.bind(this);
    this.handlePortRightClick = this.handlePortRightClick.bind(this);
    this.handlePortMouseUp = this.handlePortMouseUp.bind(this);
    this.handleConnHoverEnter = this.handleConnHoverEnter.bind(this);
    this.handleConnHoverLeave = this.handleConnHoverLeave.bind(this);
    this.handleReorderDragStart = this.handleReorderDragStart.bind(this);
    this.handleReorderDragOver = this.handleReorderDragOver.bind(this);
    this.handleReorderDrop = this.handleReorderDrop.bind(this);
    this.handleReorderDragEnd = this.handleReorderDragEnd.bind(this);
    this.removeConnection = this.removeConnection.bind(this);
  }

  componentWillUnmount() {
    clearTimeout(this.hoverEnterTimer);
    clearTimeout(this.hoverLeaveTimer);
  }

  handleConnHoverEnter() {
    clearTimeout(this.hoverLeaveTimer);
    this.hoverLeaveTimer = null;
    const { port } = this.props;
    const n = connectedToRefList(port.connected_to).length;
    if (n <= 1) {
      return;
    }
    if (this.state.connPopover) {
      return;
    }
    clearTimeout(this.hoverEnterTimer);
    this.hoverEnterTimer = setTimeout(() => {
      this.hoverEnterTimer = null;
      this.setState({ connPopover: true });
    }, CONN_POPOVER_SHOW_MS);
  }

  handleConnHoverLeave() {
    clearTimeout(this.hoverEnterTimer);
    this.hoverEnterTimer = null;
    this.hoverLeaveTimer = setTimeout(() => {
      this.hoverLeaveTimer = null;
      this.setState({ connPopover: false });
    }, CONN_POPOVER_HIDE_MS);
  }

  swapConnection(lowerIndexOneBased) {
    const { act, componentId, portIndex, isOutput } = this.props;
    if (!act) {
      return;
    }
    const action = isOutput
      ? 'swap_output_connection_order'
      : 'swap_input_connection_order';
    act(action, {
      component_id: componentId,
      port_id: portIndex,
      lower_index: lowerIndexOneBased,
    });
  }

  moveConnection(fromIndex, toIndex) {
    const { act, componentId, portIndex, isOutput } = this.props;
    if (!act) {
      return;
    }
    const action = isOutput
      ? 'move_output_connection_order'
      : 'move_input_connection_order';
    act(action, {
      component_id: componentId,
      port_id: portIndex,
      from_index: fromIndex,
      to_index: toIndex,
    });
  }

  handleReorderDragStart(e, idx) {
    // 1-based позиция источника
    this.reorderSrc = idx + 1;
    e.dataTransfer.effectAllowed = 'move';
    try {
      e.dataTransfer.setData('text/plain', String(idx + 1));
    }
    catch (err) {}
  }

  handleReorderDragOver(e, idx) {
    if (this.reorderSrc === null) {
      return;
    }
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    if (this.state.dragOverIndex !== idx) {
      this.setState({ dragOverIndex: idx });
    }
  }

  handleReorderDrop(e, idx) {
    e.preventDefault();
    const from = this.reorderSrc;
    this.reorderSrc = null;
    this.setState({ dragOverIndex: null });
    if (from === null) {
      return;
    }
    const to = idx + 1;
    if (from === to) {
      return;
    }
    this.moveConnection(from, to);
  }

  handleReorderDragEnd() {
    this.reorderSrc = null;
    this.setState({ dragOverIndex: null });
  }

  removeConnection(idx) {
    const { act, componentId, portIndex, isOutput } = this.props;
    if (!act) {
      return;
    }
    act('remove_connection_at', {
      component_id: componentId,
      port_id: portIndex,
      is_input: !isOutput,
      connection_index: idx + 1,
    });
  }

  handlePortMouseDown(e) {
    const {
      port,
      portIndex,
      componentId,
      isOutput,
      onPortMouseDown,
      act,
    } = this.props;

    if (
      !isOutput
      && port.type === 'signal'
      && e.shiftKey
      && act
    ) {
      e.preventDefault();
      e.stopPropagation();
      act('set_component_input', {
        component_id: componentId,
        port_id: portIndex,
      });
      return;
    }

    onPortMouseDown(portIndex, componentId, port, isOutput, e);
  }

  handlePortMouseUp(e) {
    const {
      port,
      portIndex,
      componentId,
      isOutput,
      onPortMouseUp,
    } = this.props;
    onPortMouseUp(portIndex, componentId, port, isOutput, e);
  }

  handlePortRightClick(e) {
    const {
      port,
      portIndex,
      componentId,
      isOutput,
      onPortRightClick,
    } = this.props;
    onPortRightClick(portIndex, componentId, port, isOutput, e);
  }

  componentDidUpdate() {
    const { port, onPortUpdated } = this.props;
    if (onPortUpdated) {
      onPortUpdated(port, this.iconRef.current);
    }
  }

  componentDidMount() {
    const { port, onPortLoaded } = this.props;
    if (onPortLoaded) {
      onPortLoaded(port, this.iconRef.current);
    }
  }

  render() {
    const {
      port,
      portIndex,
      componentId,
      isOutput,
      act,
      portLabelByRef,
      connectSourceRef,
      ...rest
    } = this.props;

    const connectionRefs = connectedToRefList(port.connected_to);
    const multiConn = connectionRefs.length > 1;
    const { connPopover, dragOverIndex } = this.state;
    const armed = !!connectSourceRef && port.ref === connectSourceRef;

    const resolveLabel = (ref) => {
      if (portLabelByRef && portLabelByRef.has(ref)) {
        return portLabelByRef.get(ref);
      }
      return ref;
    };

    const baseHint = armed
      ? 'Пин выбран — кликните по противоположному пину, чтобы соединить; ещё клик сюда — снять выбор'
      : isOutput
        ? 'Выход: клик → клик или ЛКМ-тянуть к входу · ПКМ — снять связи'
        : 'Вход: клик → клик или ЛКМ-тянуть от выхода · ПКМ — снять связи';
    const pulseInHint = ' · Shift+ЛКМ по кругу — вручную импульс';
    const multiHint = multiConn ? ' · Несколько связей: наведи на круг — порядок' : '';
    const portHint
      = port.type === 'signal' && !isOutput
        ? `${baseHint}${pulseInHint}${multiHint}`
        : `${baseHint}${multiHint}`;

    return (
      <Stack
        {...rest}
        className="IntegratedCircuit__portRow"
        align="flex-start"
        justify={isOutput ? 'flex-end' : 'flex-start'}
        title={portHint}
        onMouseDown={(e) => e.stopPropagation()}>
        {!!isOutput && (
          <Stack.Item>
            <DisplayName
              port={port}
              isOutput={isOutput}
              componentId={componentId}
              portIndex={portIndex} />
          </Stack.Item>
        )}
        <Stack.Item>
          <Box
            position="relative"
            display="inline-block"
            lineHeight={1}
            onMouseEnter={this.handleConnHoverEnter}
            onMouseLeave={this.handleConnHoverLeave}>
            <Icon
              color={port.color || 'blue'}
              name={'circle'}
              position="relative"
              title={portHint}
              className={armed ? 'IntegratedCircuit__port--armed' : undefined}
              onMouseDown={this.handlePortMouseDown}
              onContextMenu={this.handlePortRightClick}
              onMouseUp={this.handlePortMouseUp}>
              <span ref={this.iconRef} className="ObjectComponent__PortPos" />
            </Icon>
            {!!(connPopover && multiConn && act) && (
              <Box
                className="PortConnectionPopover"
                position="absolute"
                left={isOutput ? undefined : '100%'}
                right={isOutput ? '100%' : undefined}
                top="50%"
                ml={isOutput ? undefined : 0.5}
                mr={isOutput ? 0.5 : undefined}
                style={{
                  transform: 'translateY(-50%)',
                  zIndex: 12,
                }}>
                <Box className="PortConnectionPopover__title">
                  Порядок связей
                </Box>
                <Box
                  className="PortConnectionPopover__caption"
                  fontSize="0.7rem"
                  opacity={0.6}
                  mb={0.3}>
                  Перетащи строку, чтобы изменить порядок
                </Box>
                <Stack vertical>
                      {connectionRefs.map((ref, idx) => {
                        const pos = idx + 1;
                        const label = resolveLabel(ref);
                        return (
                          <Stack.Item key={ref}>
                            <Stack
                              align="center"
                              className={classes([
                                'PortConnectionPopover__row',
                                dragOverIndex === idx && 'PortConnectionPopover__row--dragOver',
                              ])}>
                              <Stack.Item grow={1}>
                                <Stack
                                  align="center"
                                  draggable
                                  onDragStart={(e) => this.handleReorderDragStart(e, idx)}
                                  onDragOver={(e) => this.handleReorderDragOver(e, idx)}
                                  onDrop={(e) => this.handleReorderDrop(e, idx)}
                                  onDragEnd={this.handleReorderDragEnd}
                                  title="Перетащи для изменения порядка">
                                  <Stack.Item>
                                    <Icon
                                      name="grip-vertical"
                                      size={0.72}
                                      opacity={0.55}
                                    />
                                  </Stack.Item>
                                  <Stack.Item>
                                    <Icon
                                      name="circle"
                                      color={port.color || 'blue'}
                                      size={0.85}
                                    />
                                  </Stack.Item>
                                  <Stack.Item grow={1} minWidth="8rem" maxWidth="16rem">
                                    <Box
                                      className="PortConnectionPopover__name"
                                      title={ref}>
                                      <b>#{pos}</b> {label}
                                    </Box>
                                  </Stack.Item>
                                </Stack>
                              </Stack.Item>
                              <Stack.Item>
                                <Button
                                  icon="times"
                                  color="transparent"
                                  compact
                                  tooltip="Удалить это соединение"
                                  onClick={() => this.removeConnection(idx)}
                                />
                              </Stack.Item>
                            </Stack>
                          </Stack.Item>
                        );
                      })}
                </Stack>
              </Box>
            )}
          </Box>
        </Stack.Item>
        {!isOutput && (
          <Stack.Item>
            <DisplayName
              port={port}
              isOutput={isOutput}
              componentId={componentId}
              portIndex={portIndex} />
          </Stack.Item>
        )}
      </Stack>
    );
  }
}

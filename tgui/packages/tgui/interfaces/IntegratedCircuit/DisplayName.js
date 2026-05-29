import { classes } from 'common/react';
import { useBackend } from '../../backend';
import { Box, Button, Flex, Stack } from '../../components';
import { connectedToRefList } from './byondPayload';
import { DATATYPE_DISPLAY_HANDLERS, FUNDAMENTAL_DATA_TYPES } from './FundamentalTypes';
import { formatPortLiveValue } from './portValueFormat';

export const DisplayName = (props, context) => {
  const { act, data } = useBackend(context);
  const { port, isOutput, componentId, portIndex, className, ...rest } = props;
  const isIeCircuit = !!data.ie_circuit;

  const fundamentalType = FUNDAMENTAL_DATA_TYPES[port.type] ? port.type : 'any';
  const InputComponent = FUNDAMENTAL_DATA_TYPES[fundamentalType];
  const TypeDisplayHandler = DATATYPE_DISPLAY_HANDLERS[fundamentalType];

  const connectionRefs = connectedToRefList(port.connected_to);

  const hasInput = !isOutput && !!InputComponent;

  const displayType = port.pin_type_label
    || (TypeDisplayHandler ? TypeDisplayHandler(port) : fundamentalType);
  const showLive = isOutput || !!connectionRefs.length;
  const liveText = showLive
    ? formatPortLiveValue(port.current_data, fundamentalType)
    : null;

  const pdata = port.current_data;
  const liveInspectable = isIeCircuit && (
    fundamentalType === 'list'
    || (pdata !== null && pdata !== undefined && typeof pdata === 'object')
  );

  const showDebuggerUpload = isIeCircuit && hasInput && fundamentalType !== 'signal'
    && fundamentalType !== 'option' && fundamentalType !== 'entity' && fundamentalType !== 'any'
    && fundamentalType !== 'list';

  const applyDebuggerUpload = () => act('set_component_input', {
    component_id: componentId,
    port_id: portIndex,
    marked_atom: true,
  });

  const openPortInspect = () => {
    if (!isIeCircuit) {
      return;
    }
    if (fundamentalType === 'list') {
      act('ie_open_list_editor', {
        component_id: componentId,
        port_id: portIndex,
        is_output: !!isOutput,
      });
    }
    else {
      act('ie_open_data_inspector', {
        component_id: componentId,
        port_id: portIndex,
        is_output: !!isOutput,
      });
    }
  };

  return (
    <Box
      {...rest}
      className={classes([className, 'IntegratedCircuit__portDisplayName'])}>
      <Flex direction="column">
        <Flex.Item>
          {(hasInput && (
            <Stack align="center" wrap>
              {!!showDebuggerUpload && (
                <Stack.Item>
                  <Button
                    compact
                    color="transparent"
                    icon="upload"
                    tooltip="Debugger: вставить память (ref/null/строка/число/список) или скопировать сюда в режиме Copy; предмет в активной руке — ref на ref/any"
                    onClick={applyDebuggerUpload}
                  />
                </Stack.Item>
              )}
              <Stack.Item grow>
                <InputComponent
                  act={act}
                  componentId={componentId}
                  portId={portIndex}
                  isOutput={isOutput}
                  ieCircuit={isIeCircuit}
                  setValue={(val, extraParams) =>
                    act('set_component_input', {
                      component_id: componentId,
                      port_id: portIndex,
                      input: val,
                      ...extraParams,
                    })}
                  color={port.color}
                  name={port.name}
                  value={port.current_data}
                  extraData={port.datatype_data}
                />
              </Stack.Item>
            </Stack>
          ))
            || (isOutput && (
              <Flex align="center" direction="row">
                {!!(isIeCircuit && fundamentalType !== 'signal' && fundamentalType !== 'option') && (
                  <Flex.Item>
                    <Button
                      compact
                      color="transparent"
                      icon="upload"
                      tooltip="Debugger: вставить память во вход (слева); режим Copy — скопировать текущее значение с этого выхода"
                      onClick={() => act('set_component_input', {
                        component_id: componentId,
                        port_id: portIndex,
                        marked_atom: true,
                        is_output: true,
                      })}
                    />
                  </Flex.Item>
                )}
                <Flex.Item>
                  <Button
                    compact
                    color="transparent"
                    icon="comment-dots"
                    tooltip="Показать значение (balloon)"
                    onClick={() =>
                      act('get_component_value', {
                        component_id: componentId,
                        port_id: portIndex,
                      })} />
                </Flex.Item>
                {isIeCircuit && fundamentalType === 'list' && (
                  <Flex.Item>
                    <Button
                      compact
                      color="transparent"
                      icon="list-ul"
                      tooltip="Редактор / просмотр списка"
                      onClick={openPortInspect}
                    />
                  </Flex.Item>
                )}
                <Flex.Item grow>
                  <Box color="white">{port.name}</Box>
                </Flex.Item>
              </Flex>
            ))
            || port.name}
        </Flex.Item>
        <Flex.Item>
          <Box
            fontSize={0.75}
            opacity={0.25}
            textAlign={isOutput ? 'right' : 'left'}>
            {displayType || 'unknown'}
          </Box>
        </Flex.Item>
        {connectionRefs.length > 1 && (
          <Flex.Item>
            <Box
              fontSize={0.64}
              opacity={0.4}
              mt={0.12}
              textAlign={isOutput ? 'right' : 'left'}
              className="PortConnectionOrder__hint">
              Порядок связей — наведи на круг порта
            </Box>
          </Flex.Item>
        )}
        {!!showLive && (
          <Flex.Item>
            <Box
              className="PortLiveValue__label"
              textAlign={isOutput ? 'right' : 'left'}>
              значение
            </Box>
            {liveInspectable ? (
              <Box
                className="PortLiveValue PortLiveValue--inspect"
                textAlign={isOutput ? 'right' : 'left'}
                title={
                  fundamentalType === 'list'
                    ? `${liveText} — открыть список`
                    : `${liveText} — открыть полные данные`
                }
                onClick={openPortInspect}>
                {liveText}
              </Box>
            ) : (
              <Box
                className="PortLiveValue"
                textAlign={isOutput ? 'right' : 'left'}
                title={liveText}>
                {liveText}
              </Box>
            )}
          </Flex.Item>
        )}
      </Flex>
    </Box>
  );
};

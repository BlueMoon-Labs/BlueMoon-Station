import { toFixed } from 'common/math';

import { useBackend } from '../../backend';
import {
  AnimatedNumber,
  Box,
  Button,
  ColorBox,
  Divider,
  Icon,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
  Table,
} from '../../components';

export const BeakerSidePanel = (props, context) => {
  const { act } = useBackend(context);
  const {
    recording,
    isBeakerLoaded,
    beakerContents,
    beakerCurrentVolume,
    beakerMaxVolume,
    beakerCurrentpH,
    beakerCurrentpHCol,
    beakerTransferAmounts,
    canStore,
    phAcidName,
    phAcidPH,
    phBaseName,
    phBasePH,
    isDrinkDispenser = false,
    onOptimisticRemove,
    onEject,
    onDispensePH,
    onStore,
    onStoreAll,
    isEjecting,
  } = props;

  const showPH = !isDrinkDispenser;

  const freeSpace = Math.max(0, (beakerMaxVolume || 0) - (beakerCurrentVolume || 0));

  return (
    <Section
      fill
      scrollable
      title={
        <span>
          <Icon name="flask" mr={1} />
          {recording ? "Ёмкость (Сим.)" : "Ёмкость"}
        </span>
      }
      buttons={
        <Stack>
          {isBeakerLoaded && (
            <>
              {!!canStore && beakerContents.length > 0 && (
                <Stack.Item>
                  <Button
                    icon="upload"
                    compact
                    tooltip="Сохранить все"
                    disabled={recording || isEjecting}
                    onClick={() => onStoreAll ? onStoreAll() : act('store_all')}
                  />
                </Stack.Item>
              )}
              <Stack.Item>
                <Button
                  icon="eject"
                  compact
                  tooltip="Извлечь"
                  onClick={() => onEject ? onEject() : act('eject')}
                />
              </Stack.Item>
            </>
          )}
        </Stack>
      }>
      {!isBeakerLoaded && !recording ? (
        <NoticeBox>Вставьте ёмкость</NoticeBox>
      ) : (
        <>
          <ProgressBar
            mb={1}
            value={(beakerCurrentVolume || 0) / (beakerMaxVolume || 1)}
            ranges={{ good: [0, 0.9], average: [0.9, 0.95], bad: [0.95, Infinity] }}>
            <AnimatedNumber value={beakerCurrentVolume || 0} /> / {beakerMaxVolume || 0} u
            <Box as="span" ml={1} color="label" fontSize="10px">
              ({toFixed(freeSpace)}u свободно)
            </Box>
          </ProgressBar>

          {showPH && beakerCurrentpH !== null && (
            <Stack mb={1} align="center">
              <Stack.Item>
                <Icon name="tint" mr={0.5} />
              </Stack.Item>
              <Stack.Item>
                <Box
                  inline
                  px={0.5}
                  backgroundColor={beakerCurrentpHCol || 'label'}
                  style={{ borderRadius: '3px' }}>
                  pH: <AnimatedNumber value={beakerCurrentpH} format={v => v?.toFixed(2)} />
                </Box>
              </Stack.Item>
            </Stack>
          )}

          {showPH && isBeakerLoaded && (
            <Box mb={1}>
              <Box color="label" fontSize="10px" mb={0.5}>Коррекция pH (1u):</Box>
              <Stack>
                <Stack.Item>
                  <Button
                    compact
                    icon="arrow-down"
                    color="orange"
                    tooltip={`${phAcidName} 1u (pH ${phAcidPH}) - понижает pH`}
                    disabled={recording || isEjecting}
                    onClick={() => onDispensePH ? onDispensePH('acid') : act('dispense_ph', { type: 'acid' })}>
                    -pH
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    compact
                    icon="arrow-up"
                    color="blue"
                    tooltip={`${phBaseName} 1u (pH ${phBasePH}) - повышает pH`}
                    disabled={recording || isEjecting}
                    onClick={() => onDispensePH ? onDispensePH('base') : act('dispense_ph', { type: 'base' })}>
                    +pH
                  </Button>
                </Stack.Item>
              </Stack>
            </Box>
          )}

          <Divider />

          <Box mb={1}>
            <Box color="label" fontSize="10px" mb={0.5}>Слить:</Box>
            <Box>
              {beakerTransferAmounts.map(amount => (
                <Button
                  key={amount}
                  compact
                  icon="minus"
                  content={amount}
                  disabled={recording || isEjecting}
                  onClick={() => {
                    if (onOptimisticRemove) onOptimisticRemove(amount, false);
                    act('remove', { amount });
                  }}
                />
              ))}
              <Button
                compact
                icon="trash"
                color="bad"
                tooltip="Слить всё"
                disabled={recording || !beakerCurrentVolume || isEjecting}
                onClick={() => {
                  if (onOptimisticRemove) onOptimisticRemove(0, true);
                  act('remove', { all: true });
                }}
              />
            </Box>
          </Box>

          <Divider />

          {beakerContents.length === 0 ? (
            <Box color="label" textAlign="center" py={1}>
              <Icon name="droplet-slash" size={1.5} mb={0.5} />
              <br />
              Пусто
            </Box>
          ) : (
            <Table>
              {beakerContents.map(chemical => {
                const percentage = beakerCurrentVolume > 0
                  ? ((chemical.volume / beakerCurrentVolume) * 100).toFixed(0)
                  : 0;
                return (
                  <Table.Row key={chemical.id} className="candystripe">
                    <Table.Cell collapsing>
                      <ColorBox color={chemical.pHCol || 'label'} />
                    </Table.Cell>
                    <Table.Cell fontSize="11px">
                      <AnimatedNumber value={chemical.volume} initial={0} />u {chemical.name}
                      <Box as="span" color="label" ml={0.5}>
                        ({percentage}%)
                      </Box>
                    </Table.Cell>
                    {!!canStore && (
                      <Table.Cell collapsing>
                        <Button
                          compact
                          icon="upload"
                          tooltip="Сохранить"
                          disabled={recording || isEjecting}
                          onClick={() => onStore ? onStore(chemical.id) : act('store', { id: chemical.id })}
                        />
                      </Table.Cell>
                    )}
                  </Table.Row>
                );
              })}
            </Table>
          )}
        </>
      )}
    </Section>
  );
};

import { toFixed } from 'common/math';

import { useBackend } from '../../backend';
import {
  AnimatedNumber,
  Box,
  Button,
  ColorBox,
  Icon,
  ProgressBar,
  Section,
  Stack,
  Table,
} from '../../components';

export const StorageSidePanel = (props, context) => {
  const { act } = useBackend(context);
  const {
    storedContents,
    storedVol,
    maxVol,
    recording,
    isBeakerLoaded,
    onUnstore,
    onUnstoreAll,
    onClearStorage,
    isEjecting,
  } = props;

  const freeSpace = Math.max(0, maxVol - storedVol);

  return (
    <Section
      fill
      scrollable
      title={
        <span>
          <Icon name="box" mr={1} />
          Хранилище
        </span>
      }
      buttons={
        <Stack>
          {storedContents.length > 0 && (
            <>
              <Stack.Item>
                <Button
                  icon="download"
                  compact
                  tooltip="Извлечь все"
                  disabled={recording || !isBeakerLoaded || isEjecting}
                  onClick={() => onUnstoreAll ? onUnstoreAll() : act('unstore_all')}
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="trash"
                  compact
                  color="bad"
                  tooltip="Очистить"
                  disabled={isEjecting}
                  onClick={() => onClearStorage ? onClearStorage() : act('clear_storage')}
                />
              </Stack.Item>
            </>
          )}
        </Stack>
      }>
      <ProgressBar
        mb={1}
        value={storedVol / maxVol}
        ranges={{ good: [0, 0.9], average: [0.9, 0.95], bad: [0.95, Infinity] }}>
        {toFixed(storedVol)} / {maxVol} u
        <Box as="span" ml={1} color="label" fontSize="10px">
          ({toFixed(freeSpace)}u свободно)
        </Box>
      </ProgressBar>

      {storedContents.length === 0 ? (
        <Box color="label" textAlign="center" py={1}>
          <Icon name="box-open" size={1.5} mb={0.5} />
          <br />
          Пусто
        </Box>
      ) : (
        <Table>
          {storedContents.map(chemical => {
            const percentage = storedVol > 0
              ? ((chemical.volume / storedVol) * 100).toFixed(0)
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
                <Table.Cell collapsing>
                  <Button
                    compact
                    icon="download"
                    tooltip="Извлечь"
                    disabled={recording || !isBeakerLoaded || isEjecting}
                    onClick={() => onUnstore ? onUnstore(chemical.id) : act('unstore', { id: chemical.id })}
                  />
                </Table.Cell>
              </Table.Row>
            );
          })}
        </Table>
      )}
    </Section>
  );
};

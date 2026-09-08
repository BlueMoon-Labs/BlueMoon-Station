import { useBackend } from '../backend';
import {
  Box,
  Button,
  Divider,
  Flex,
  Icon,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Table,
} from '../components';
import { Window } from '../layouts';

type DetectiveScannerData = {
  scanning: boolean;
  scan_progress: number;
  has_scan: boolean;
  target_name: string;
  target_icon: string | null;
  timestamp: string;
  location: string;
  fingerprints: string[];
  blood: Array<{ dna: string; type: string }>;
  fibers: string[];
  reagents: Array<{ name: string; volume: number }>;
  print_count: number;
  can_print: boolean;
};

export const DetectiveScanner = () => {
  const { act, data } = useBackend<DetectiveScannerData>();
  const { scan_progress, target_name, target_icon, timestamp, location } = data;
  const scanning = !!data.scanning;
  const has_scan = !!data.has_scan;
  const can_print = !!data.can_print;
  const fingerprints = Array.isArray(data.fingerprints) ? data.fingerprints : [];
  const blood = Array.isArray(data.blood) ? data.blood : [];
  const fibers = Array.isArray(data.fibers) ? data.fibers : [];
  const reagents = Array.isArray(data.reagents) ? data.reagents : [];

  return (
    <Window title="Криминалистический сканер NT-2000" width={600} height={640}>
      <Window.Content scrollable>
        <Section
          title={scanning ? 'АНАЛИЗ' : has_scan ? `ОБЪЕКТ: ${target_name}` : 'ГОТОВ К СКАНИРОВАНИЮ'}
          buttons={<Button icon="print" content={`FR-${data.print_count + 1}`} tooltip="Следующий номер отчёта" disabled />}
        >
          {!has_scan && !scanning && (
            <NoticeBox color="grey" textAlign="center">
              Наведите сканер на объект в упор и активируйте. Хранится только один скан.
            </NoticeBox>
          )}

          {(has_scan || scanning) && (
            <Flex align="center">
              <Flex.Item mr={2}>
                <Box
                  width="72px"
                  height="72px"
                  backgroundColor="rgba(0,0,0,0.15)"
                  style={{
                    border: '1px solid #777',
                    borderRadius: '4px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    overflow: 'hidden',
                  }}
                >
                  {target_icon ? (
                    <img
                      src={`data:image/png;base64,${target_icon}`}
                      style={{
                        width: '64px',
                        height: '64px',
                        imageRendering: 'pixelated',
                      }}
                    />
                  ) : (
                    <Icon name="cube" size={3} color="label" />
                  )}
                </Box>
              </Flex.Item>
              <Flex.Item grow={1}>
                <LabeledList>
                  <LabeledList.Item label="Объект">
                    <Box bold>{target_name || '-'}</Box>
                  </LabeledList.Item>
                  <LabeledList.Item label="Время">{timestamp || '-'}</LabeledList.Item>
                  <LabeledList.Item label="Статус">
                    {scanning ? (
                      <Box color="label" bold>
                        <Icon name="spinner" spin mr={1} />
                        Анализ
                      </Box>
                    ) : has_scan ? (
                      <Box color="good">Готов к печати</Box>
                    ) : (
                      <Box color="label">Ожидание</Box>
                    )}
                  </LabeledList.Item>
                </LabeledList>
              </Flex.Item>
            </Flex>
          )}

          {scanning && (
            <Box mt={1}>
              <ProgressBar value={scan_progress / 100} color="grey" ranges={{ grey: [0, 0.99], good: [1, 1] }}>
                <Box>
                  {scan_progress < 30 && 'Сканирование отпечатков...'}
                  {scan_progress >= 30 && scan_progress < 60 && 'Анализ ДНК...'}
                  {scan_progress >= 60 && scan_progress < 85 && 'Идентификация волокон...'}
                  {scan_progress >= 85 && scan_progress < 100 && 'Хроматография...'}
                  {scan_progress === 100 && 'Завершено'}
                  {' - '}
                  {scan_progress}%
                </Box>
              </ProgressBar>
              <Box mt={0.5} color="label" fontSize="11px" textAlign="center">
                Не убирайте сканер до окончания анализа
              </Box>
            </Box>
          )}
        </Section>

        {has_scan && !scanning && (
          <>
            <Flex wrap="wrap">
              <Flex.Item basis="50%" pr={0.5} mb={0.5}>
                <Section
                  title="ОТПЕЧАТКИ"
                  level={2}
                  buttons={fingerprints.length ? <Box>{fingerprints.length}</Box> : null}
                  style={{ minHeight: '140px' }}
                >
                  {fingerprints.length === 0 ? (
                    <Box color="label" textAlign="center" py={1}>
                      - не обнаружено -
                    </Box>
                  ) : (
                    <Table>
                      <Table.Row header>
                        <Table.Cell>#</Table.Cell>
                        <Table.Cell>MD5</Table.Cell>
                      </Table.Row>
                      {fingerprints.map((fp, i) => (
                        <Table.Row key={i} className="candystripe">
                          <Table.Cell collapsing color="label">
                            {i + 1}
                          </Table.Cell>
                          <Table.Cell
                            style={{
                              fontFamily: 'monospace',
                              fontSize: '11px',
                              wordBreak: 'break-all',
                            }}
                          >
                            {fp}
                          </Table.Cell>
                        </Table.Row>
                      ))}
                    </Table>
                  )}
                </Section>
              </Flex.Item>

              <Flex.Item basis="50%" pl={0.5} mb={0.5}>
                <Section
                  title="КРОВЬ / ДНК"
                  level={2}
                  buttons={blood.length ? <Box color="bad">{blood.length}</Box> : null}
                  style={{ minHeight: '140px' }}
                >
                  {blood.length === 0 ? (
                    <Box color="label" textAlign="center" py={1}>
                      - не обнаружено -
                    </Box>
                  ) : (
                    <Table>
                      <Table.Row header>
                        <Table.Cell>Группа</Table.Cell>
                        <Table.Cell>ДНК</Table.Cell>
                      </Table.Row>
                      {blood.map((entry, i) => (
                        <Table.Row key={i} className="candystripe">
                          <Table.Cell collapsing color="bad" bold textAlign="center">
                            {entry.type}
                          </Table.Cell>
                          <Table.Cell
                            style={{
                              fontFamily: 'monospace',
                              fontSize: '11px',
                              wordBreak: 'break-all',
                            }}
                          >
                            {entry.dna}
                          </Table.Cell>
                        </Table.Row>
                      ))}
                    </Table>
                  )}
                </Section>
              </Flex.Item>

              <Flex.Item basis="50%" pr={0.5}>
                <Section
                  title="ВОЛОКНА"
                  level={2}
                  buttons={fibers.length ? <Box>{fibers.length}</Box> : null}
                  style={{ minHeight: '140px' }}
                >
                  {fibers.length === 0 ? (
                    <Box color="label" textAlign="center" py={1}>
                      - не обнаружено -
                    </Box>
                  ) : (
                    <Box maxHeight="120px" overflowY="auto">
                      {fibers.map((f, i) => (
                        <Box key={i} mb={0.3} style={{ fontSize: '11px', borderLeft: '2px solid #777', paddingLeft: '6px' }}>
                          {f}
                        </Box>
                      ))}
                    </Box>
                  )}
                </Section>
              </Flex.Item>

              <Flex.Item basis="50%" pl={0.5}>
                <Section
                  title="РЕАГЕНТЫ"
                  level={2}
                  buttons={reagents.length ? <Box>{reagents.length}</Box> : null}
                  style={{ minHeight: '140px' }}
                >
                  {reagents.length === 0 ? (
                    <Box color="label" textAlign="center" py={1}>
                      - не обнаружено -
                    </Box>
                  ) : (
                    <Table>
                      <Table.Row header>
                        <Table.Cell>Реагент</Table.Cell>
                        <Table.Cell textAlign="right">Объём</Table.Cell>
                      </Table.Row>
                      {reagents.map((entry, i) => (
                        <Table.Row key={i} className="candystripe">
                          <Table.Cell>{entry.name}</Table.Cell>
                          <Table.Cell textAlign="right">{entry.volume}u</Table.Cell>
                        </Table.Row>
                      ))}
                    </Table>
                  )}
                </Section>
              </Flex.Item>
            </Flex>

            <Divider />

            <Section title="ДЕЙСТВИЯ" level={2} buttons={<Box color="label" fontSize="11px">ID: FR-{data.print_count + 1}</Box>}>
              <Flex>
                <Flex.Item grow={1} mr={1}>
                  <Button
                    fluid
                    icon="print"
                    content="Напечатать отчёт"
                    color="good"
                    disabled={!can_print}
                    onClick={() => act('print_report')}
                  />
                </Flex.Item>
                <Flex.Item grow={1}>
                  <Button fluid icon="broom" content="Очистить" onClick={() => act('clear_scan')} />
                </Flex.Item>
              </Flex>
              <Box mt={1} color="label" fontSize="10px" textAlign="center">
                Отчёт формируется на бумаге. Требуется подпись для юридической силы.
              </Box>
            </Section>
          </>
        )}

        {scanning && (
          <Section textAlign="center" mt={1}>
            <Icon name="microscope" size={2} color="label" spin />
            <Box mt={1} color="label">
              Идёт анализ...
            </Box>
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};
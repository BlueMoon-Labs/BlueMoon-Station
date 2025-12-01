import { useBackend } from '../backend';
import { Box, Button, Collapsible, NoticeBox, ProgressBar, Section, Stack } from '../components';
import { Window } from '../layouts';

export const CloningConsole = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    useRecords,
    hasAutoprocess,
    autoprocess,
    scannerLocked,
    hasOccupant,
    scan_result,
    cloning_result,
    hasScanner,
    diskData = [],
    records = [],
    pods = [],
  } = data;

  const makeNoticeFlags = flag => ({
    info: flag === 'info',
    danger: flag === 'danger',
    warning: flag === 'warning',
    success: flag === 'success',
  });

  return (
    <Window width="400" height="600" resizable>
      <Window.Content overflow="auto">
        <Section>
          <Section
            title="Cloning Pods Status"
            buttons={useRecords &&
              <Button
                content="Autoclone"
                color={autoprocess ? "green" : "default"}
                icon={autoprocess ? "toggle-on" : "toggle-off"}
                disabled={!hasAutoprocess}
                onClick={() => act('toggle_autoprocess')}
              />
            }>

            {/* нет подов */}
            {pods.length === 0 && (
              <NoticeBox danger>
                No Cloning Pods connected!
              </NoticeBox>
            )}
            {/* 1–5 пода: Cloning Pod №[Индекс]: [Статус] */}
            {pods.length > 0 && pods.length <= 5 && pods.map((pod, i) => (
              <Stack key={i}>
                <Stack.Item>
                  <Box bold>
                    Cloning Pod №{(i + 1)}:
                  </Box>
                </Stack.Item>
                <Stack.Item>
                  <Box bold color={pod.color}>
                    {pod.status}
                  </Box>
                </Stack.Item>
              </Stack>
            ))}

            {/* >5 подов: всё то же, но внутри Collapsible */}
            {pods.length > 5 && (
              <Collapsible title={`Cloning pods (${pods.length})`} open={pods.length <= 7}>
                {pods.map((pod, i) => (
                  <Stack key={i}>
                    <Stack.Item>
                      <Box bold>
                        Cloning Pod №{(i + 1)}:
                      </Box>
                    </Stack.Item>
                    <Stack.Item>
                      <Box bold color={pod.color}>
                        {pod.status}
                      </Box>
                    </Stack.Item>
                  </Stack>
                ))}
              </Collapsible>
            )}
          </Section>
          {hasScanner ? (
            <Section title="Scanner Functions">
              <NoticeBox {...makeNoticeFlags(scan_result.flag)}>{scan_result.message}</NoticeBox>
              {cloning_result.message && (
                <NoticeBox {...makeNoticeFlags(cloning_result.flag)}>{cloning_result.message}</NoticeBox>
              )}
              <br />
              <Button
                content={useRecords ? "Start Scan" : "Clone"}
                icon={useRecords ? "search" : "power-off"}
                disabled={!hasOccupant}
                onClick={() => act('scan')}
              />
              <Button
                content={scannerLocked ? "Unlock Scanner" : "Lock Scanner"}
                icon={scannerLocked ? "lock" : "lock-open"}
                color={scannerLocked ? "bad" : "good"}
                disabled={!hasOccupant && !scannerLocked}
                onClick={() => act('toggle_lock')}
              />
            </Section>
          ) : (
            <>
              <NoticeBox danger>
                ERROR: No Scanner Detected!
              </NoticeBox>
              {cloning_result.message && (
                <NoticeBox {...makeNoticeFlags(cloning_result.flag)}>{cloning_result.message}</NoticeBox>
              )}
            </>
          )}
          {useRecords && (
            <Section>
              <Section title="Database Functions">
                <Collapsible disabled={!records.length} title={`View Records (${records.length})`}>
                  <Box color="blue"><h3>Current Records:</h3></Box>
                  {records.map(record => (
                    <Collapsible
                      key={record["id"] || record["name"]}
                      title={record["name"]}
                      buttons={
                        <Button
                          content="Clone"
                          icon="power-off"
                          color="good"
                          onClick={() => act('clone', {
                            target: record["id"],
                          })}
                        />
                      }>
                      <div style={{
                        'word-break': 'break-all',
                      }}>
                        Scan ID {record["id"]}<br />
                        <Button
                          content="Clone"
                          icon="power-off"
                          color="good"
                          onClick={() => act('clone', {
                            target: record["id"],
                          })}
                        />
                        <Button
                          content="Delete Record"
                          icon="user-slash"
                          color="bad"
                          onClick={() => act('delrecord', {
                            target: record["id"],
                          })}
                        />
                        <Button
                          content="Save to Disk"
                          icon="upload"
                          color="orange"
                          disabled={diskData.length === 0}
                          onClick={() => act('save', {
                            target: record["id"],
                          })}
                        />
                        <br />
                        Health Implant Data<br />

                        <small>
                          Oxygen Deprivation Damage:<br />
                          <ProgressBar color="blue" value={record["damages"]["oxy"] / 100} />
                          Fire Damage:<br />
                          <ProgressBar color="orange" value={record["damages"]["burn"] / 100} />
                          Toxin Damage:<br />
                          <ProgressBar color="green" value={record["damages"]["tox"] / 100} />
                          Brute Damage:<br />
                          <ProgressBar color="red" value={record["damages"]["brute"] / 100} />
                        </small><br />
                        Unique Identifier:<br />
                        {record["UI"]}<br />
                        Unique Enzymes:<br />
                        {record["UE"]}<br />
                        Blood Type: {record["blood_type"]}
                      </div>
                    </Collapsible>
                  ))}
                </Collapsible>
              </Section>
              <Section
                title="Disk"
                buttons={
                  <Box>
                    <Button
                      content="Load"
                      icon="download"
                      disabled={!diskData["name"]}
                      onClick={() => act('load')}
                    />
                    <Button
                      content="Eject Disk"
                      icon="eject"
                      disabled={diskData.length === 0}
                      onClick={() => act('eject')}
                    />
                  </Box>
                }
              >
                {diskData.length !== 0 ? (
                  <Collapsible title={diskData["name"] ? diskData["name"] : "Empty Disk"}>
                    {diskData["id"] ? (
                      <Box style={{
                        'word-break': 'break-all',
                      }}>
                        ID: {diskData["id"]}<br />
                        UI: {diskData["UI"]}<br />
                        UE: {diskData["UE"]}<br />
                        Blood Type: {diskData["blood_type"]}<br />
                      </Box>
                    ) : ("No Data")}
                  </Collapsible>
                ) : ("No Disk")}
              </Section>
            </Section>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};

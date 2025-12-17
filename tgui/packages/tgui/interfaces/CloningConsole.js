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
            title="Статус капсул"
            buttons={useRecords &&
              <Button
                content="Автоклонирование"
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
              <Collapsible title={`Капсулы клонирования (${pods.length})`} open={pods.length <= 7}>
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
            <Section title="Функции сканера">
              <NoticeBox {...makeNoticeFlags(scan_result.flag)}>{scan_result.message}</NoticeBox>
              {cloning_result.message && (
                <NoticeBox {...makeNoticeFlags(cloning_result.flag)}>{cloning_result.message}</NoticeBox>
              )}
              <br />
              <Button
                content={useRecords ? "Сканировать" : "Клонировать"}
                icon={useRecords ? "search" : "power-off"}
                disabled={!hasOccupant}
                onClick={() => act('scan')}
              />
              <Button
                content={scannerLocked ? "Разблокировать сканер" : "Заблокировать сканер"}
                icon={scannerLocked ? "lock" : "lock-open"}
                color={scannerLocked ? "bad" : "good"}
                disabled={!hasOccupant && !scannerLocked}
                onClick={() => act('toggle_lock')}
              />
            </Section>
          ) : (
            <>
              <NoticeBox danger>
                ОШИБКА: сканера не обнаружено!
              </NoticeBox>
              {cloning_result.message && (
                <NoticeBox {...makeNoticeFlags(cloning_result.flag)}>{cloning_result.message}</NoticeBox>
              )}
            </>
          )}
          {useRecords && (
            <Section>
              <Section title="Файлы записей">
                <Collapsible disabled={!records.length} title={`Просмотр записей (${records.length})`}>
                  <Box color="blue"><h3>Current Records:</h3></Box>
                  {records.map(record => (
                    <Collapsible
                      key={record["id"] || record["name"]}
                      title={record["имя"]}
                      buttons={
                        <Button
                          content="Клонировать"
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
                          content="Клонировать"
                          icon="power-off"
                          color="good"
                          onClick={() => act('clone', {
                            target: record["id"],
                          })}
                        />
                        <Button
                          content="Удалить запись"
                          icon="user-slash"
                          color="bad"
                          onClick={() => act('delrecord', {
                            target: record["id"],
                          })}
                        />
                        <Button
                          content="Сохранить на диск"
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
                title="Диск"
                buttons={
                  <Box>
                    <Button
                      content="Загрузить"
                      icon="download"
                      disabled={!diskData["name"]}
                      onClick={() => act('load')}
                    />
                    <Button
                      content="Извлечь"
                      icon="eject"
                      disabled={diskData.length === 0}
                      onClick={() => act('eject')}
                    />
                  </Box>
                }
              >
                {diskData.length !== 0 ? (
                  <Collapsible title={diskData["name"] ? diskData["name"] : "Пустой диск"}>
                    {diskData["id"] ? (
                      <Box style={{
                        'word-break': 'break-all',
                      }}>
                        ID: {diskData["id"]}<br />
                        UI: {diskData["UI"]}<br />
                        UE: {diskData["UE"]}<br />
                        Blood Type: {diskData["blood_type"]}<br />
                      </Box>
                    ) : ("Запись отсутствует")}
                  </Collapsible>
                ) : ("Отсутствует")}
              </Section>
            </Section>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};

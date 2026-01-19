import { useBackend } from '../backend';
import { Box, Button, Icon, NoticeBox, ProgressBar, Section, Stack, Tooltip } from '../components';
import { Window } from '../layouts';

export const BloodBankGen = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    bank,
    inputBag,
    outputBag,
    draining,
    filling,
  } = data;
  return (
    <Window width="450" height="600" resizable>
      <Window.Content overflow="auto">
        <Section
          title={
            <>
              Хранилище Синткрови
              <Box inline ml={1}>
                <Tooltip
                  content={
                    <>
                      Машина перерабатывает обычную кровь в синтетическую.<br /><br />
                      1. Поместите пакет с кровью и переработайте кровь.<br />
                      2. Пустой пакет поместите в приемник и наполните синткровью.
                    </>
                  }>
                  <Icon name="info-circle" />
                </Tooltip>
              </Box>
            </>
          }
        >
          <ProgressBar
            value={bank.currentVolume}
            maxValue={bank.maxVolume}
            color="blue">
            <h3>{bank.currentVolume} / {bank.maxVolume} units</h3>
          </ProgressBar>
        </Section>
        {inputBag ? (
          <Section title="Пакет с кровью"
            buttons={
              <>
                <Button
                  content={draining ? "Переработка..." : "Переработать"}
                  icon="rotate"
                  color={draining ? "yellow" : "good"}
                  iconSpin={draining}
                  onClick={() => act('drain')}
                />
                <Button
                  content="Извлечь"
                  icon="arrow-up-from-bracket"
                  onClick={() => act("take", { type: "input" })}
                />
              </>
            }
          >
            <ProgressBar
              value={inputBag.currentVolume}
              maxValue={inputBag.maxVolume}
              color="red">
              {inputBag.currentVolume} / {inputBag.maxVolume} units
            </ProgressBar>
          </Section>
        ) : (
          <NoticeBox mt={1.5} info>
            <Stack>
              <Stack.Item>
                <Button
                  content="Поместить"
                  icon="arrow-right-to-bracket"
                  color="good"
                  onClick={() => act("insert", { type: "input" })}
                />
              </Stack.Item>
              <Stack.Item mt={0.4}>
                Вставьте пакет крови на переработку...
              </Stack.Item>
            </Stack>
          </NoticeBox>)}
        {outputBag ? (
          <Section title="Заполняемый пакет"
            buttons={
              <>
                <Button
                  content={filling ? "Заполнение..." : "Заполнить"}
                  icon={filling ? "rotate" : "download"}
                  color={filling ? "good" : ""}
                  iconSpin={filling}
                  onClick={() => act('fill')}
                />
                <Button
                  content="Извлечь"
                  icon="arrow-up-from-bracket"
                  onClick={() => act("take", { type: "output" })}
                />
              </>
            }
          >
            <ProgressBar
              value={outputBag.currentVolume}
              maxValue={outputBag.maxVolume}
              color="blue">
              {outputBag.currentVolume} / {outputBag.maxVolume} units
            </ProgressBar>
          </Section>
        ) : (
          <NoticeBox mt={1.5} info>
            <Stack>
              <Stack.Item>
                <Button
                  content="Поместить"
                  icon="arrow-right-to-bracket"
                  color="good"
                  onClick={() => act("insert", { type: "output" })}
                />
              </Stack.Item>
              <Stack.Item mt={0.5}>
                Вставьте пакет для заполнения...
              </Stack.Item>
            </Stack>
          </NoticeBox>)}
      </Window.Content>
    </Window>
  );
};

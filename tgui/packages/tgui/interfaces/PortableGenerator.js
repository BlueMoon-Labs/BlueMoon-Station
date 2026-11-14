import { useBackend } from '../backend';
import { Box, Button, LabeledList, NoticeBox, ProgressBar, Section } from '../components';
import { Window } from '../layouts';

export const PortableGenerator = (props) => {
  const { act, data } = useBackend();
  const {
    stack_percent,
  } = data;
  const stackPercentState = (
    stack_percent > 50 && 'good'
    || stack_percent > 15 && 'average'
    || 'bad'
  );
  return (
    <Window
      width={450}
      height={340}>
      <Window.Content overflow="auto">
        {!data.anchored && (
          <NoticeBox>Генератор не закреплён.</NoticeBox>
        )}
        <Section title="Статус">
          <LabeledList>
            <LabeledList.Item label="Кнопка питания">
              <Button
                icon={data.active ? 'power-off' : 'times'}
                onClick={() => act('toggle_power')}
                disabled={!data.ready_to_boot}>
                {data.active ? 'On' : 'Off'}
              </Button>
            </LabeledList.Item>
            <LabeledList.Item label={data.sheet_name + ' осталось'}>
              <Box inline color={stackPercentState}>{data.sheets + ' шт.'}</Box>
              {data.sheets >= 1 && (
                <Button
                  ml={1}
                  icon="eject"
                  disabled={data.active}
                  onClick={() => act('eject')}>
                  Извлечь
                </Button>
              )}
            </LabeledList.Item>
            <LabeledList.Item label="Остаток топлива">
              <ProgressBar
                value={data.stack_percent / 100}
                ranges={{
                  good: [0.1, Infinity],
                  average: [0.01, 0.1],
                  bad: [-Infinity, 0.01],
                }} />
            </LabeledList.Item>
            <LabeledList.Item label="Уровень нагрева">
              {data.current_heat < 100 ? (
                <Box inline color="good">номинальный</Box>
              ) : (
                data.current_heat < 200 ? (
                  <Box inline color="average">повышенный</Box>
                ) : (
                  <Box inline color="bad">НЕБЕЗОПАСНЫЙ</Box>
                )
              )}
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Section title="Энергоотдача">
          <LabeledList>
            <LabeledList.Item label="Текущая отдача">
              {data.power_output}
            </LabeledList.Item>
            <LabeledList.Item label="Настройка">
              <Button
                icon="minus"
                onClick={() => act('lower_power')}>
                {data.power_generated}
              </Button>
              <Button
                icon="plus"
                onClick={() => act('higher_power')}>
                {data.power_generated}
              </Button>
            </LabeledList.Item>
            <LabeledList.Item label="Доступно энергии">
              <Box inline color={!data.connected && 'bad'}>
                {data.connected ? data.power_available : "нет подключения к энергосети"}
              </Box>
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Window.Content>
    </Window>
  );
};

import { useBackend } from '../backend';
import { Box, LabeledList, NoticeBox, ProgressBar, Section, Slider } from '../components';
import { Window } from '../layouts';

export const AstroSensor = (props) => {
  const { act, data } = useBackend();
  const {
    broken,
    collected,
    gain,
    heat,
    heatWarning,
    intensity,
    phase,
    phenomenon,
    readout,
    secondsToPeak,
    seesSpace,
    viewRange,
    yieldCap,
  } = data;
  const lines = readout || [];
  // Порог предупреждения приходит от машины: держать копию числа в двух местах
  // означало бы, что после балансировки шкала врёт игроку.
  const heatRanges = {
    good: [0, heatWarning],
    average: [heatWarning, 90],
    bad: [90, Infinity],
  };

  return (
    <Window title="Астрометрический сенсор" width={420} height={480}>
      <Window.Content scrollable>
        {!!broken && (
          <NoticeBox danger>
            Приёмник выгорел. Замените сканирующий модуль.
          </NoticeBox>
        )}
        {!broken && !seesSpace && (
          <NoticeBox warning>
            Обзор перекрыт. Тарелке нужен прямой вид в космос в пределах{' '}
            {viewRange} м по направлению наводки.
          </NoticeBox>
        )}

        <Section title="Наблюдение">
          {phenomenon ? (
            <LabeledList>
              <LabeledList.Item label="Явление">{phenomenon}</LabeledList.Item>
              <LabeledList.Item label="Фаза">{phase}</LabeledList.Item>
              <LabeledList.Item label="Интенсивность">
                <ProgressBar
                  value={intensity}
                  minValue={0}
                  maxValue={100}
                  ranges={{
                    good: [0, 40],
                    average: [40, 80],
                    bad: [80, Infinity],
                  }}
                >
                  {intensity}%
                </ProgressBar>
              </LabeledList.Item>
              <LabeledList.Item label="До пика">
                {secondsToPeak > 0 ? secondsToPeak + ' с' : 'пик начался'}
              </LabeledList.Item>
            </LabeledList>
          ) : (
            <Box color="label">
              Сектор чист. Аномальных объектов в зоне наблюдения нет.
            </Box>
          )}
        </Section>

        <Section title="Приёмник">
          <LabeledList>
            <LabeledList.Item label="Усиление">
              <Slider
                value={gain}
                minValue={0}
                maxValue={100}
                step={5}
                stepPixelSize={4}
                onChange={(e, value) => act('gain', { value: value })}
              >
                {gain}%
              </Slider>
            </LabeledList.Item>
            <LabeledList.Item label="Нагрев">
              <ProgressBar
                value={heat}
                minValue={0}
                maxValue={100}
                ranges={heatRanges}
              >
                {heat}%
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Собрано данных">
              {collected}
              {yieldCap ? ' из ' + yieldCap : ''}
            </LabeledList.Item>
          </LabeledList>
          <Box mt={1} color="label">
            Нагрев растёт вместе с усилением и интенсивностью явления. На подходе
            тарелку можно выкрутить полностью, на пике то же усиление сожжёт
            приёмник.
          </Box>
        </Section>

        {lines.length > 0 && (
          <Section title="Прогноз на пик">
            {lines.map((line, index) => (
              <Box key={index}>{line}</Box>
            ))}
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};

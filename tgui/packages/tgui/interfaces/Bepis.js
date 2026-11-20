import { useBackend } from '../backend';
import { Box, Button, Grid, LabeledList, NumberInput, Section } from '../components';
import { Window } from '../layouts';

export const Bepis = () => {
  const { act, data } = useBackend();
  const { amount } = data;
  return (
    <Window
      width={500}
      height={480}>
      <Window.Content scrollable>
        <Section title="Инкубатор коммерческих технологий B.E.P.I.S.">
          <Section
            title="Информация"
            backgroundColor="#450F44"
            buttons={(
              <Button
                icon="power-off"
                content={data.manual_power ? 'Выкл.' : 'Вкл.'}
                selected={!data.manual_power}
                onClick={() => act('toggle_power')} />
            )}>
            Всё, что нужно знать о B.E.P.I.S. и о вас! Камера проводит сотни
            тестов в секунду, используя электрические и финансовые ресурсы,
            чтобы изобретать новые продукты или открывать технологии, которые
            иначе были бы упущены из-за слишком высокого риска или узкой ниши!
          </Section>
          <Section
            title="Счёт плательщика"
            buttons={(
              <Button
                icon="redo-alt"
                content="Сбросить счёт"
                onClick={() => act('account_reset')} />
            )}>
            {data.account_owner
              ? `В данный момент консолью управляет ${data.account_owner}.`
              : 'В данный момент консолью никто не управляет.'}
          </Section>
          <Grid>
            <Grid.Column size={1.5}>
              <Section title="Сохранённые данные и статистика">
                <LabeledList>
                  <LabeledList.Item label="Доступно кредитов">
                    {data.stored_cash}
                  </LabeledList.Item>
                  <LabeledList.Item label="Изменчивость инвестиций">
                    {data.accuracy_percentage}%
                  </LabeledList.Item>
                  <LabeledList.Item label="Бонус инноваций">
                    {data.positive_cash_offset}
                  </LabeledList.Item>
                  <LabeledList.Item label="Поправка на риск" color="bad">
                    {data.negative_cash_offset}
                  </LabeledList.Item>
                  <LabeledList.Item label="Сумма вклада">
                    <NumberInput
                      value={amount}
                      unit="кредитов"
                      minValue={100}
                      maxValue={30000}
                      step={100}
                      stepPixelSize={2}
                      onChange={(e, value) => act('amount', {
                        amount: value,
                      })} />
                  </LabeledList.Item>
                </LabeledList>
              </Section>
              <Box>
                <Button
                  icon="donate"
                  content="Внести кредиты"
                  disabled={data.manual_power === 1
                    || data.silicon_check === 1}
                  onClick={() => act('deposit_cash')}
                />
                <Button
                  icon="eject"
                  content="Вывести кредиты"
                  disabled={data.manual_power === 1}
                  onClick={() => act('withdraw_cash')} />
              </Box>
            </Grid.Column>
            <Grid.Column>
              <Section title="Рыночные данные и анализ">
                <Box>
                  Средняя стоимость технологии: {data.mean_value}
                </Box>
                <Box>
                  Ожидаемый шанс успеха: ~{data.success_estimate}%
                </Box>
                {!!data.error_name && (
                  <Box color="bad">
                    Причина прошлой неудачи: {data.error_name}.
                  </Box>
                )}
                <Box m={1} />
                <Button
                  icon="microscope"
                  disabled={data.manual_power === 1}
                  onClick={() => act('begin_experiment')}
                  content="Начать тестирование" />
              </Section>
            </Grid.Column>
          </Grid>
        </Section>
      </Window.Content>
    </Window>
  );
};

import { useBackend } from '../backend';
import { Button, LabeledList, Section } from '../components';
import { Window } from '../layouts';

export const TurbineComputer = (props) => {
  const { act, data } = useBackend();
  const operational = Boolean(data.compressor
    && !data.compressor_broke
    && data.turbine
    && !data.turbine_broke);
  return (
    <Window
      width={310}
      height={150}>
      <Window.Content>
        <Section
          title="Статус"
          buttons={(
            <>
              <Button
                icon={data.online ? 'power-off' : 'times'}
                content={data.online ? 'Включено' : 'Отключено'}
                selected={data.online}
                disabled={!operational}
                onClick={() => act('toggle_power')} />
              <Button
                icon="sync"
                content="Переподключить"
                onClick={() => act('reconnect')} />
            </>
          )}>
          {!operational && (
            <LabeledList>
              <LabeledList.Item
                label="Статус компрессора"
                color={(!data.compressor || data.compressor_broke)
                  ? 'bad'
                  : 'good'}>
                {data.compressor_broke
                  ? data.compressor ? 'Offline' : 'Missing'
                  : 'Online'}
              </LabeledList.Item>
              <LabeledList.Item
                label="Статус турбины"
                color={(!data.turbine || data.turbine_broke)
                  ? 'bad'
                  : 'good'}>
                {data.turbine_broke
                  ? data.turbine ? 'Offline' : 'Missing'
                  : 'Online'}
              </LabeledList.Item>
            </LabeledList>
          ) || (
            <LabeledList>
              <LabeledList.Item label="Скорость турбины">
                {data.rpm} ОВМ
              </LabeledList.Item>
              <LabeledList.Item label="Внутренняя темп.">
                {data.temp} К
              </LabeledList.Item>
              <LabeledList.Item label="Выработка энергии">
                {data.power}
              </LabeledList.Item>
            </LabeledList>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};

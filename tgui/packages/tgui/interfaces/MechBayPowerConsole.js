import { useBackend } from '../backend';
import { AnimatedNumber, Button, LabeledList, NoticeBox, ProgressBar, Section } from '../components';
import { Window } from '../layouts';

export const MechBayPowerConsole = (props) => {
  const { act, data } = useBackend();
  const { recharge_port } = data;
  const mech = recharge_port && recharge_port.mech;
  const cell = mech && mech.cell;
  return (
    <Window
      width={400}
      height={200}>
      <Window.Content>
        <Section
          title="Состояние меха"
          textAlign="center"
          buttons={(
            <Button
              icon="sync"
              content="Синхронизировать"
              onClick={() => act('reconnect')} />
          )}>
          <LabeledList>
            <LabeledList.Item label="Целостность">
              {!recharge_port && (
                <NoticeBox>
                  Порт питания не обнаружен. Повторите синхронизацию.
                </NoticeBox>
              ) || !mech && (
                <NoticeBox>
                  Мех не обнаружен.
                </NoticeBox>
              ) || (
                <ProgressBar
                  value={mech.health / mech.maxhealth}
                  ranges={{
                    good: [0.7, Infinity],
                    average: [0.3, 0.7],
                    bad: [-Infinity, 0.3],
                  }} />
              )}
            </LabeledList.Item>
            <LabeledList.Item label="Питание">
              {!recharge_port && (
                <NoticeBox>
                  Порт питания не обнаружен. Повторите синхронизацию.
                </NoticeBox>
              ) || !mech && (
                <NoticeBox>
                  Мех не обнаружен.
                </NoticeBox>
              ) || !cell && (
                <NoticeBox>
                  Аккумулятор не установлен.
                </NoticeBox>
              ) || (
                <ProgressBar
                  value={cell.charge / cell.maxcharge}
                  ranges={{
                    good: [0.7, Infinity],
                    average: [0.3, 0.7],
                    bad: [-Infinity, 0.3],
                  }}>
                  <AnimatedNumber value={cell.charge} />
                  {' / ' + cell.maxcharge}
                </ProgressBar>
              )}
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Window.Content>
    </Window>
  );
};

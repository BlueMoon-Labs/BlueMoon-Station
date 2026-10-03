import { useBackend } from '../backend';
import { AnimatedNumber, Box, Button, LabeledList, ProgressBar, Section } from '../components';
import { Window } from '../layouts';

export const SmokeMachine = (props) => {
  const { act, data } = useBackend();
  const {
    TankContents,
    isTankLoaded,
    TankCurrentVolume,
    TankMaxVolume,
    active,
    setting,
    maxSetting = 1,
    open,
    hasPowercell,
    powerLevel,
  } = data;
  return (
    <Window
      width={400}
      height={350}>
      <Window.Content>
        <Section
          title="Питание"
          buttons={(
            <>
              <Button
                icon="eject"
                content="Извлечь батарею"
                disabled={!hasPowercell || !open}
                onClick={() => act('eject')} />
              <Button
                icon={active ? 'power-off' : 'times'}
                content={active ? 'Включено' : 'Выключено'}
                selected={active}
                disabled={!hasPowercell}
                onClick={() => act('power')} />
            </>
          )}>
          <LabeledList>
            <LabeledList.Item
              label="Батарея"
              color={!hasPowercell && 'bad'}>
              {hasPowercell && (
                <ProgressBar
                  value={powerLevel / 100}
                  ranges={{
                    good: [0.6, Infinity],
                    average: [0.3, 0.6],
                    bad: [-Infinity, 0.3],
                  }}>
                  {powerLevel + '%'}
                </ProgressBar>
              ) || 'Нет'}
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Section title="Дисперсионный резервуар">
          <ProgressBar
            value={TankCurrentVolume / TankMaxVolume}
            ranges={{
              bad: [-Infinity, 0.3],
            }}>
            <AnimatedNumber initial={0} value={TankCurrentVolume || 0} />
            {' / ' + TankMaxVolume}
          </ProgressBar>
          <Box mt={1}>
            <LabeledList>
              <LabeledList.Item label="Радиус">
                {[1, 2, 3, 4, 5, 6, 9].map(amount => (
                  <Button
                    key={amount}
                    selected={setting === amount}
                    icon="plus"
                    content={amount * 2}
                    disabled={maxSetting < amount}
                    onClick={() => act('setting', { amount })} />
                ))}
              </LabeledList.Item>
            </LabeledList>
          </Box>
        </Section>
        <Section title="Содержимое"
          buttons={(
            <Button
              icon="trash"
              content="Утилизировать"
              onClick={() => act('purge')} />
          )}>
          {TankContents.map(chemical => (
            <Box
              key={chemical.name}
              color="label">
              <AnimatedNumber
                initial={0}
                value={chemical.volume} />
              {' '}
              u {chemical.name}
            </Box>
          ))}
        </Section>
      </Window.Content>
    </Window>
  );
};

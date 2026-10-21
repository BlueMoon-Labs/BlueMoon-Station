import { useBackend } from '../../backend';
import { Box, Button, Icon, Section, Stack } from '../../components';
import type { MainData } from './data';
import { useHonk } from './honk';

const damageDescriptions = {
  MECHA_INT_FIRE: ['Пожара нет', 'Внутренний пожар'],
  MECHA_INT_TEMP_CONTROL: ['Терморегуляция в норме', 'Отказ терморегуляции'],
  MECHA_INT_TANK_BREACH: ['Баллон герметичен', 'Разгерметизация баллона'],
  MECHA_INT_CONTROL_LOST: ['Управление в норме', 'Сбой калибровки'],
  MECHA_INT_SHORT_CIRCUIT: ['Электроника в норме', 'Короткое замыкание'],
};

export const AlertPane = () => {
  const { act, data } = useBackend<MainData>();
  const honk = useHonk(data.ui_honked ? 0.4 : 0);
  return (
    <Section title={honk('Статус')}>
      <Stack vertical>
        {Object.entries(data.internal_damage_keys).map(([key, flag]) => {
          const damaged = !!(data.internal_damage & flag);
          return (
            <Stack.Item key={key}>
              <Stack align="center" justify="space-between">
                <Stack.Item>
                  <Box color={damaged ? 'bad' : 'good'}>
                    <Icon mr={1} name={damaged ? 'exclamation-triangle' : 'check'} />
                    {honk(damageDescriptions[key][damaged ? 1 : 0])}
                  </Box>
                </Stack.Item>
                {damaged && key === 'MECHA_INT_CONTROL_LOST' && (
                  <Stack.Item>
                    <Button
                      color="bad"
                      content="Калибровать"
                      disabled={!data.can_settings}
                      onClick={() => act('repair_int_damage')} />
                  </Stack.Item>
                )}
              </Stack>
            </Stack.Item>
          );
        })}
      </Stack>
    </Section>
  );
};

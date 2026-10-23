import { useBackend } from '../../backend';
import { Box, Button, Icon, Section, Stack, Tooltip } from '../../components';
import type { MainData } from './data';
import { useHonk } from './honk';

const damageDescriptions = {
  MECHA_INT_FIRE: ['Пожара нет', 'Внутренний пожар'],
  MECHA_INT_TEMP_CONTROL: ['Терморегуляция в норме', 'Отказ терморегуляции'],
  MECHA_INT_TANK_BREACH: ['Баллон герметичен', 'Разгерметизация баллона'],
  MECHA_INT_CONTROL_LOST: ['Управление в норме', 'Сбой калибровки'],
  MECHA_INT_SHORT_CIRCUIT: ['Электроника в норме', 'Короткое замыкание'],
};

const damageRepairHints = {
  MECHA_INT_FIRE: 'При исправной терморегуляции пожар погаснет автоматически. Если она повреждена, сначала почините её отвёрткой снаружи меха.',
  MECHA_INT_TEMP_CONTROL: 'Починить регулятор можно отвёрткой снаружи меха. Неисправность также может устранить включённый ремонтный дрон.',
  MECHA_INT_TANK_BREACH: 'Заварите пробоину включённым сварочным аппаратом снаружи меха. Неисправность также может устранить включённый ремонтный дрон.',
  MECHA_INT_CONTROL_LOST: 'Нажмите «Калибровать» и оставайтесь на месте 10 секунд до завершения калибровки.',
  MECHA_INT_SHORT_CIRCUIT: 'Разрешите техобслуживание и активируйте его протокол ID-картой с нужным доступом. Открутите болты гаечным ключом, откройте люк ломом и примените два отрезка кабеля.',
};

export const AlertPane = () => {
  const { act, data } = useBackend<MainData>();
  const honk = useHonk(data.ui_honked ? 0.4 : 0);
  return (
    <Section title={honk('Статус')}>
      <Stack vertical>
        {Object.entries(data.internal_damage_keys).map(([key, flag]) => {
          const description = damageDescriptions[key];
          if (!description) {
            return null;
          }
          const damaged = !!(data.internal_damage & flag);
          const status = (
            <Box color={damaged ? 'bad' : 'good'}>
              <Icon mr={1} name={damaged ? 'exclamation-triangle' : 'check'} />
              {honk(description[damaged ? 1 : 0])}
            </Box>
          );
          return (
            <Stack.Item key={key}>
              <Stack align="center" justify="space-between">
                <Stack.Item>
                  {damaged ? (
                    <Tooltip content={damageRepairHints[key]}>{status}</Tooltip>
                  ) : status}
                </Stack.Item>
                {damaged && key === 'MECHA_INT_CONTROL_LOST' && (
                  <Stack.Item>
                    <Button
                      color="bad"
                      content="Калибровать"
                      disabled={!data.can_settings}
                      tooltip={!data.can_settings ? 'С этого места нельзя управлять настройками меха.' : undefined}
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

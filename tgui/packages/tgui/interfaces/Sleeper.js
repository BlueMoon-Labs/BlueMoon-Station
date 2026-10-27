import { useBackend } from '../backend';
import { Box, Button, LabeledList, ProgressBar, Section } from '../components';
import { Window } from '../layouts';

const damageTypes = [
  {
    label: 'Травмы',
    type: 'bruteLoss',
  },
  {
    label: 'Ожоги',
    type: 'fireLoss',
  },
  {
    label: 'Токсины',
    type: 'toxLoss',
  },
  {
    label: 'Гипоксия',
    type: 'oxyLoss',
  },
];

export const Sleeper = (props) => {
  const { act, data } = useBackend();
  const {
    open,
    occupant = {},
    occupied,
    mounted,
    stasis_enabled,
    life_support_active,
  } = data;
  const preSortChems = data.chems || [];
  const chems = preSortChems.sort((a, b) => {
    const descA = a.name.toLowerCase();
    const descB = b.name.toLowerCase();
    if (descA < descB) {
      return -1;
    }
    if (descA > descB) {
      return 1;
    }
    return 0;
  });
  return (
    <Window
      width={310}
      height={mounted ? 575 : 505}>
      <Window.Content>
        {!!mounted && (
          <Section title="Системы капсулы">
            <Button
              icon="snowflake"
              selected={stasis_enabled}
              content={`Стазис: ${stasis_enabled ? 'включён' : 'выключен'}`}
              tooltip="Приостанавливает биологические процессы и обмен лекарств. Требует питания."
              onClick={() => act('stasis')} />
            {!!occupied && (
              <Box color={life_support_active ? 'good' : 'bad'}>
                {life_support_active ? 'Кислород и микроклимат в норме' : 'Нет питания'}
              </Box>
            )}
          </Section>
        )}
        <Section
          title={occupant.name ? occupant.name : 'Пациент отсутствует'}
          minHeight="210px"
          buttons={!!occupant.stat && (
            <Box
              inline
              bold
              color={occupant.statstate}>
              {occupant.stat}
            </Box>
          )}>
          {!!occupied && (
            <>
              <ProgressBar
                value={occupant.health}
                minValue={occupant.minHealth}
                maxValue={occupant.maxHealth}
                ranges={{
                  good: [50, Infinity],
                  average: [0, 50],
                  bad: [-Infinity, 0],
                }} />
              <Box mt={1} />
              <LabeledList>
                {damageTypes.map(type => (
                  <LabeledList.Item
                    key={type.type}
                    label={type.label}>
                    <ProgressBar
                      value={occupant[type.type]}
                      minValue={0}
                      maxValue={occupant.maxHealth}
                      color="bad" />
                  </LabeledList.Item>
                ))}
                <LabeledList.Item
                  label="Клетки"
                  color={occupant.cloneLoss ? 'bad' : 'good'}>
                  {occupant.cloneLoss ? 'Распадаются' : 'Целостны'}
                </LabeledList.Item>
                <LabeledList.Item
                  label="Мозг"
                  color={occupant.brainLoss ? 'bad' : 'good'}>
                  {occupant.brainLoss ? 'Повреждён' : 'Стабилен'}
                </LabeledList.Item>
              </LabeledList>
            </>
          )}
        </Section>
        <Section
          title="Препараты"
          minHeight="245px"
          buttons={(
            <Button
              icon={open ? 'door-open' : 'door-closed'}
              content={mounted ? 'Извлечь' : open ? 'Открыта' : 'Закрыта'}
              disabled={!!mounted && !occupied}
              onClick={() => act('door')} />
          )}>
          {chems.map(chem => (
            <Button
              key={chem.name}
              icon={chem.overdose_threshold || chem.addiction_threshold ? 'triangle-exclamation' : 'flask'}
              tooltip={[
                chem.overdose_threshold && `Передозировка: ${chem.overdose_threshold}u`,
                chem.addiction_threshold && `Зависимость: ${chem.addiction_threshold}u`,
              ].filter(Boolean).join(' | ')}
              content={chem.name}
              disabled={!occupied || !chem.allowed || (!!mounted && !life_support_active)}
              width="140px"
              onClick={() => act('inject', {
                chem: chem.id,
              })} />
          ))}
        </Section>
      </Window.Content>
    </Window>
  );
};

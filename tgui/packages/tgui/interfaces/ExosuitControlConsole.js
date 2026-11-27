import { toFixed } from 'common/math';

import { useBackend } from '../backend';
import { AnimatedNumber, Box, Button, LabeledList, NoticeBox, Section } from '../components';
import { Window } from '../layouts';

export const ExosuitControlConsole = (props) => {
  const { act, data } = useBackend();
  const {
    mechs = [],
  } = data;
  return (
    <Window
      width={500}
      height={500}>
      <Window.Content overflow="auto">
        {mechs.length === 0 && (
          <NoticeBox>
            Экзокостюмы не обнаружены
          </NoticeBox>
        )}
        {mechs.map(mech => (
          <Section
            key={mech.tracker_ref}
            title={mech.name}
            buttons={(
              <>
                <Button
                  icon="envelope"
                  content="Сообщение"
                  disabled={!mech.pilot}
                  onClick={() => act('send_message', {
                    tracker_ref: mech.tracker_ref,
                  })} />
                <Button
                  icon="wifi"
                  content={mech.emp_recharging
                    ? 'Перезарядка...'
                    : 'ЭМИ-импульс'}
                  color="bad"
                  disabled={mech.emp_recharging}
                  onClick={() => act('shock', {
                    tracker_ref: mech.tracker_ref,
                  })} />
              </>
            )}>
            <LabeledList>
              <LabeledList.Item label="Целостность">
                <Box
                  color={(
                    mech.integrity <= 30 && 'bad'
                    || mech.integrity <= 70 && 'average'
                    || 'good'
                  )}>
                  {mech.integrity}%
                </Box>
              </LabeledList.Item>
              <LabeledList.Item label="Заряд">
                <Box
                  color={(
                    mech.charge <= 30 && 'bad'
                    || mech.charge <= 70 && 'average'
                    || 'good'
                  )}>
                  {typeof mech.charge === 'number'
                    && mech.charge + '%'
                    || 'Не найдено'}
                </Box>
              </LabeledList.Item>
              <LabeledList.Item label="Баллон">
                {typeof mech.airtank === 'number' && (
                  <AnimatedNumber
                    value={mech.airtank}
                    format={value => toFixed(value, 2) + ' кПа'} />
                ) || 'Не установлен'}
              </LabeledList.Item>
              <LabeledList.Item label="Пилот">
                {mech.pilot.length > 0 && (
                  mech.pilot.map(pilot => (
                    <Box
                      key={pilot}
                      inline>
                      {pilot}{mech.pilot.length > 1 ? '|' : ''}
                    </Box>
                  ))) || 'Нет'}
              </LabeledList.Item>
              <LabeledList.Item label="Местоположение">
                {mech.location || 'Неизвестно'}
              </LabeledList.Item>
              <LabeledList.Item label="Активное оборудование">
                {mech.active_equipment || 'Нет'}
              </LabeledList.Item>
              {mech.cargo_space >= 0 && (
                <LabeledList.Item label="Использовано грузового места">
                  <Box
                    color={(
                      mech.cargo_space <= 30 && 'good'
                      || mech.cargo_space <= 70 && 'average'
                      || 'bad'
                    )}>
                    {mech.cargo_space}%
                  </Box>
                </LabeledList.Item>
              )}
            </LabeledList>
          </Section>
        ))}
      </Window.Content>
    </Window>
  );
};

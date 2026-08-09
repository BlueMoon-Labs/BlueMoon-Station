import { useBackend } from '../../../backend';
import { Button, LabeledList } from '../../../components';
import { AirAlarmData } from '../types';

export const Overview = () => {
  const { act, data } = useBackend<AirAlarmData>();
  const {
    atmos_alarm,
    mode,
    panic_mode,
    filtering_mode,
    vents = [],
    scrubbers = [],
  } = data;
  const ventsOn = vents.filter((vent) => vent.power).length;
  const scrubbersOn = scrubbers.filter((scrubber) => scrubber.power).length;
  const panicking = mode === panic_mode;
  const currentMode = (data.modes || []).find((entry) => entry.selected);
  return (
    <LabeledList>
      <LabeledList.Item
        label="Тревога зоны"
        color={atmos_alarm ? 'bad' : 'good'}
        buttons={
          <Button
            icon={atmos_alarm ? 'exclamation-triangle' : 'exclamation'}
            color={atmos_alarm ? 'caution' : null}
            content={atmos_alarm ? 'Снять' : 'Объявить'}
            onClick={() => act(atmos_alarm ? 'reset' : 'alarm')}
          />
        }>
        {atmos_alarm ? 'Объявлена' : 'Не объявлена'}
      </LabeledList.Item>
      <LabeledList.Item
        label="Аварийная откачка"
        color={panicking ? 'bad' : 'good'}
        buttons={
          <Button
            icon={panicking ? 'exclamation-triangle' : 'exclamation'}
            color={panicking ? 'danger' : null}
            content={panicking ? 'Остановить' : 'Запустить'}
            tooltip="Быстрая разгерметизация зоны. Нужны внутренние баллоны."
            onClick={() =>
              act('mode', { mode: panicking ? filtering_mode : panic_mode })
            }
          />
        }>
        {panicking ? 'Идёт' : 'Остановлена'}
      </LabeledList.Item>
      <LabeledList.Item label="Текущий режим">
        {currentMode ? currentMode.name : 'Неизвестен'}
      </LabeledList.Item>
      <LabeledList.Item label="Вентиляторы">
        {ventsOn} из {vents.length} включены
      </LabeledList.Item>
      <LabeledList.Item label="Скрубберы">
        {scrubbersOn} из {scrubbers.length} включены
      </LabeledList.Item>
    </LabeledList>
  );
};

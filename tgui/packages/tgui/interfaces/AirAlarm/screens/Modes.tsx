import { useBackend } from '../../../backend';
import { Box, Button, LabeledList, NoticeBox } from '../../../components';
import { AirAlarmData } from '../types';

export const Modes = () => {
  const { act, data } = useBackend<AirAlarmData>();
  const modes = data.modes || [];
  if (modes.length === 0) {
    return <NoticeBox>Режимы недоступны.</NoticeBox>;
  }
  return (
    <LabeledList>
      {modes.map((mode) => (
        <LabeledList.Item
          key={mode.mode}
          label={mode.name}
          labelColor={mode.danger ? 'bad' : 'label'}
          buttons={
            <Button
              icon={mode.selected ? 'check-square-o' : 'square-o'}
              selected={mode.selected}
              color={mode.selected && mode.danger && 'danger'}
              content={mode.selected ? 'Активен' : 'Включить'}
              onClick={() => act('mode', { mode: mode.mode })}
            />
          }>
          {/* Описание рядом с названием, а не в тултипе: выбирать режим
              разгерметизации вслепую по одному слову - плохая идея. */}
          <Box color="label">{mode.description}</Box>
        </LabeledList.Item>
      ))}
    </LabeledList>
  );
};

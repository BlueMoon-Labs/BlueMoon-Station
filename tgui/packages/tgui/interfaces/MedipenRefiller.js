import { useBackend } from '../backend';
import { Box, Button, LabeledList, NoticeBox, ProgressBar, Section } from '../components';
import { Window } from '../layouts';

export const MedipenRefiller = () => {
  const { act, data } = useBackend();
  const { slots, enabled, operational, refillTime, speedUp } = data;
  return (
    <Window width={480} height={560} resizable>
      <Window.Content scrollable>
        <Section title="Заправщик медипенов" buttons={(
          <Button
            icon="power-off"
            selected={enabled}
            onClick={() => act('power')}>
            {enabled ? 'Выключить' : 'Включить'}
          </Button>
        )}>
          <LabeledList>
            <LabeledList.Item label="Слотов">{slots.length}</LabeledList.Item>
            <LabeledList.Item label="Время заправки">
              {refillTime} с (сокращение на {speedUp}%)
            </LabeledList.Item>
          </LabeledList>
          <Box mt={1} color="label">
            Медипен заправляется только после завершения цикла.
            Остановка или извлечение отменяют заправку.
          </Box>
        </Section>
        {!operational && (
          <NoticeBox>Машина выключена или не готова к работе.</NoticeBox>
        )}
        {slots.map(slot => (
          <Section key={slot.id} title={slot.name ? slot.name : ("Пустой слот")} buttons={(
            slot.name ? (
              <>
                <Button
                  icon={slot.filling ? 'stop' : 'fill-drip'}
                  disabled={!slot.filling && (!operational || slot.filled)}
                  onClick={() => act(slot.filling ? 'stop' : 'start', { slot: slot.id })}>
                  {slot.filling ? 'Остановить' : 'Заправить'}
                </Button>
                <Button icon="eject" onClick={() => act('eject', { slot: slot.id })}>
                  Извлечь
                </Button>
              </>
            ) : (
              <Button icon="plus" onClick={() => act('insert', { slot: slot.id })}>
                Поместить
              </Button>
            )
          )}>
            {slot.name ? (
              <>
                <ProgressBar value={slot.filling ? slot.progress : (slot.filled ? 1 : 0)} color="blue">
                  {slot.filling
                    ? `Создание реагентов: ${Math.floor(slot.progress * 100)}%` //`Создание реагентов: ${Math.floor(slot.progress * 100)}% — осталось ${slot.remaining} с`
                    : (slot.filled ? 'Медипен содержит реагенты' : 'Готов к заправке')}
                </ProgressBar>
              </>
            ) : (
              <Box color="label">Вставьте поддерживаемый медипен.</Box>
            )}
          </Section>
        ))}
      </Window.Content>
    </Window>
  );
};

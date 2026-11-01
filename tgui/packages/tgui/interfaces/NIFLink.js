import { useBackend } from '../backend';
import { Box, Button, ProgressBar, Section, Stack } from '../components';
import { Window } from '../layouts';

export const NIFLink = () => {
  const { act, data } = useBackend();
  const {
    power, maximum, durability, max_durability, calibrating,
    calibration_remaining = 0, broken, nutrition, blood, balance,
    slots, programs = [], catalog = [],
  } = data;
  return (
    <Window width={650} height={720}>
      <Window.Content scrollable>
        <Section title="Nanite Implant Framework">
          <Box mb={1}>Энергия</Box>
          <ProgressBar value={power / maximum}>{Math.round(power)} / {maximum}</ProgressBar>
          <Box my={1}>Прочность</Box>
          <ProgressBar value={durability / max_durability}>{durability} / {max_durability}</ProgressBar>
          {!!calibrating && (
            <Box mt={1} color="yellow">
              Калибровка: осталось {Math.ceil(calibration_remaining)} с.
              Программы можно загрузить сейчас, а запустить после калибровки.
            </Box>
          )}
          {!!broken && <Box mt={1} color="bad">Восстановление после ЭМИ. Установка и запуск программ недоступны.</Box>}
          {durability <= 0 && <Box mt={1} color="bad">Имплант повреждён. Используйте NIF Regenerator.</Box>}
        </Section>
        <Section title="Питание">
          <Button.Checkbox checked={nutrition} onClick={() => act('nutrition')}>Использовать сытость</Button.Checkbox>
          <Button.Checkbox checked={blood} onClick={() => act('blood')}>Использовать кровь</Button.Checkbox>
        </Section>
        <Section title={`Установленные программы (${programs.length} / ${slots})`}>
          {!programs.length && <Box>Программы не установлены. Выберите программу в каталоге ниже.</Box>}
          <Stack vertical>
            {programs.map((program) => (
              <Stack.Item key={program.ref}>
                <Box bold>{program.name}</Box>
                <Box mb={1}>{program.description}</Box>
                <Button
                  selected={program.active}
                  disabled={!program.active && !program.ready}
                  onClick={() => act('activate', { ref: program.ref })}>
                  {program.active ? 'Выключить' : program.toggle ? 'Включить' : 'Открыть'}
                </Button>
                <Button.Confirm icon="trash" onClick={() => act('remove', { ref: program.ref })}>Удалить</Button.Confirm>
              </Stack.Item>
            ))}
          </Stack>
        </Section>
        <Section title="Каталог NIFSoft">
          <Box mb={1}>{balance === null || balance === undefined ? 'Для платных программ нужна ID с банковским счётом.' : `Баланс: ${balance} кр.`}</Box>
          {catalog.map((program) => (
            <Box key={program.id} mb={2}>
              <Box bold>{program.name} — {program.category}</Box>
              <Box mb={1}>{program.description}</Box>
              <Button
                icon="download"
                disabled={!!program.reason}
                onClick={() => act('purchase', { program: program.id })}>
                Установить {program.name} ({program.price} кр.)
              </Button>
              {!!program.reason && <Box mt={0.5} color="yellow">{program.reason}</Box>}
            </Box>
          ))}
        </Section>
      </Window.Content>
    </Window>
  );
};

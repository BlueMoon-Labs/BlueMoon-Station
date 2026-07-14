import { useBackend } from '../backend';
import { NoticeBox, ProgressBar, Section, Table } from '../components';
import { NtosWindow } from '../layouts';

export const NtosHydroponics = (props) => {
  const { act, data } = useBackend();
  const { trays = [] } = data;

  return (
    <NtosWindow width={500} height={550}>
      <NtosWindow.Content scrollable>
        <Section title="Монитор гидропоники">
          {trays.length === 0 && (
            <NoticeBox info>
              Гидропонные лотки не найдены.
            </NoticeBox>
          )}
          {trays.map(tray => (
            <Section
              key={tray.name + tray.area}
              title={tray.name + ' - ' + tray.area}>
              <Table>
                <Table.Row>
                  <Table.Cell bold>Растение:</Table.Cell>
                  <Table.Cell>{tray.plant}</Table.Cell>
                </Table.Row>
                <Table.Row>
                  <Table.Cell bold>Здоровье:</Table.Cell>
                  <Table.Cell>
                    <ProgressBar
                      value={tray.health}
                      maxValue={tray.max_health}
                      ranges={{
                        good: [tray.max_health * 0.7, tray.max_health],
                        average: [tray.max_health * 0.3, tray.max_health * 0.7],
                        bad: [0, tray.max_health * 0.3],
                      }}>
                      {tray.health}/{tray.max_health}
                    </ProgressBar>
                  </Table.Cell>
                </Table.Row>
                <Table.Row>
                  <Table.Cell bold>Вода:</Table.Cell>
                  <Table.Cell>{tray.water}u</Table.Cell>
                </Table.Row>
                <Table.Row>
                  <Table.Cell bold>Питательные вещества:</Table.Cell>
                  <Table.Cell>{tray.nutri}u</Table.Cell>
                </Table.Row>
                <Table.Row>
                  <Table.Cell bold>Сорняки:</Table.Cell>
                  <Table.Cell>{tray.weed_level}</Table.Cell>
                </Table.Row>
                <Table.Row>
                  <Table.Cell bold>Вредители:</Table.Cell>
                  <Table.Cell>{tray.pest_level}</Table.Cell>
                </Table.Row>
                <Table.Row>
                  <Table.Cell bold>Готово к сбору:</Table.Cell>
                  <Table.Cell>
                    {tray.harvest ? 'Да' : 'Нет'}
                  </Table.Cell>
                </Table.Row>
              </Table>
            </Section>
          ))}
        </Section>
      </NtosWindow.Content>
    </NtosWindow>
  );
};

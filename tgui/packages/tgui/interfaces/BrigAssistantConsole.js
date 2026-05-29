import { useBackend } from '../backend';
import { Button, NoticeBox, Section, Table } from '../components';
import { Window } from '../layouts';

export const BrigAssistantConsole = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    wanted = [],
    remove = [],
  } = data;

  return (
    <Window
      title="Задания брига"
      width={500}
      height={500}>
      <Window.Content scrollable>
        <Section title="Развешивание плакатов с разыскиваемыми">
          <Table>
            <Table.Row header>
              <Table.Cell>Имя</Table.Cell>
              <Table.Cell>Статус</Table.Cell>
              <Table.Cell>Взято</Table.Cell>
              <Table.Cell collapsing>Действие</Table.Cell>
            </Table.Row>
            {wanted.map(w => (
              <Table.Row key={w.id}>
                <Table.Cell>{w.name}</Table.Cell>
                <Table.Cell>{w.status}</Table.Cell>
                <Table.Cell>
                  {w.takes_count}/{3}
                  {w.reason && ` (${w.reason})`}
                </Table.Cell>
                <Table.Cell collapsing>
                  <Button
                    content="Взять задание"
                    disabled={!w.can_take}
                    tooltip={!w.has_photo ? "Нет фото в досье" : null}
                    onClick={() => act('take_task', { id: w.id })} />
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
          {wanted.length === 0 && (
            <NoticeBox info>
              Нет разыскиваемых в базе данных. Добавьте записи через консоль СБ.
            </NoticeBox>
          )}
        </Section>
        <Section title="Снятие плакатов (пойманные)">
          <Table>
            <Table.Row header>
              <Table.Cell>Имя</Table.Cell>
              <Table.Cell>Статус</Table.Cell>
              <Table.Cell collapsing>Действие</Table.Cell>
            </Table.Row>
            {remove.map(r => (
              <Table.Row key={r.id}>
                <Table.Cell>{r.name}</Table.Cell>
                <Table.Cell>{r.status}</Table.Cell>
                <Table.Cell collapsing>
                  <Button
                    content={r.has_task ? "Задание взято" : "Взять задание"}
                    disabled={r.has_task}
                    tooltip="Снимите плакаты кусачками. Награда: 75-100 кредитов."
                    onClick={() => act('take_remove_task', { id: r.id })} />
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
          {remove.length === 0 && (
            <NoticeBox info>
              Нет пойманных в базе. Плакаты снимают после смены статуса в консоли СБ.
            </NoticeBox>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};

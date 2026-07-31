import { useBackend } from '../backend';
import { NoticeBox, Section, Table } from '../components';
import { NtosWindow } from '../layouts';

export const NtosCustodialLocator = (props) => {
  const { act, data } = useBackend();
  const { items = [] } = data;

  return (
    <NtosWindow width={400} height={500}>
      <NtosWindow.Content scrollable>
        <Section title="Локатор уборщика">
          {items.length === 0 && (
            <NoticeBox info>
              Уборочное оборудование не найдено.
            </NoticeBox>
          )}
          {items.length > 0 && (
            <Table>
              <Table.Row header>
                <Table.Cell>Предмет</Table.Cell>
                <Table.Cell>Местоположение</Table.Cell>
                <Table.Cell collapsing>Тип</Table.Cell>
              </Table.Row>
              {items.map(item => (
                <Table.Row key={item.name + item.area}>
                  <Table.Cell>{item.name}</Table.Cell>
                  <Table.Cell>{item.area}</Table.Cell>
                  <Table.Cell collapsing>
                    {item.type === 'bucket' ? 'Ведро' : 'Бот'}
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
        </Section>
      </NtosWindow.Content>
    </NtosWindow>
  );
};

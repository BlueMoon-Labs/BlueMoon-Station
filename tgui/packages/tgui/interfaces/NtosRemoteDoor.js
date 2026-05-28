import { useBackend } from '../backend';
import { Section, Button, NoticeBox } from '../components';
import { NtosWindow } from '../layouts';

export const NtosRemoteDoor = (props, context) => {
  const { act, data } = useBackend(context);
  const { doors = [] } = data;

  return (
    <NtosWindow width={350} height={450}>
      <NtosWindow.Content scrollable>
        <Section title="Удаленное управление дверями">
          {doors.length === 0 && (
            <NoticeBox info>
              Нет доступных шлюзов поблизости.
            </NoticeBox>
          )}
          {doors.map(door => (
            <Button
              key={door.ref}
              fluid
              icon={door.open ? 'door-open' : 'door-closed'}
              content={door.name}
              selected={door.open}
              onClick={() => act('toggle', { ref: door.ref })}
            />
          ))}
        </Section>
      </NtosWindow.Content>
    </NtosWindow>
  );
};

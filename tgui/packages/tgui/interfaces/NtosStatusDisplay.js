import { useBackend } from '../backend';
import { Button, Input, Section } from '../components';
import { NtosWindow } from '../layouts';

export const NtosStatusDisplay = (props) => {
  const { act, data } = useBackend();

  const handleMsg1 = (e, v) => act('set_message', { msg1: v, msg2: '' });
  const handleMsg2 = (e, v) => act('set_message', { msg1: '', msg2: v });
  const handleAlert = () => act('set_alert', { alert: 'alert' });
  const handleClear = () => act('set_alert', { alert: 'default' });

  return (
    <NtosWindow width={400} height={400}>
      <NtosWindow.Content>
        <Section title="Управление статус-дисплеем">
          <Input fluid placeholder="Строка 1" onEnter={handleMsg1} />
          <Input fluid placeholder="Строка 2" onEnter={handleMsg2} />
        </Section>
        <Section title="Тревога">
          <Button icon="exclamation-triangle" onClick={handleAlert}>
            Тревога
          </Button>
          <Button icon="shield-alt" onClick={handleClear}>
            Сброс
          </Button>
        </Section>
      </NtosWindow.Content>
    </NtosWindow>
  );
};

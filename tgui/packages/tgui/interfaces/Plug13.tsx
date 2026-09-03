
import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Input, NoticeBox, Section, Stack } from '../components';
import { Window } from '../layouts';


type Plug13State = {
  is_connected: string,
  pending: boolean,
  username: string,
  error: string,
  code: string
}

const codeRegex = /^([A-Za-z0-9]{10}|([A-Za-z0-9]{5}-[A-Za-z0-9]{5}))$/;

export const Plug13 = (props) => {
  const { act, data } = useBackend<Plug13State>();

  const [code, setCode] = useState('');

  const validateCode = (code: string) => {
    if (code.length < 10) return false;
    return codeRegex.test(code);
  };

  return (
    <Window
      width={400}
      height={240}
      resizable>
      <Window.Content scrollable={false}>
        { !data.is_connected ? (
          <Section title="Подключение" fill>
            <Stack direction="column" justify="center" align="center" fill>
              { data.error ? (
                <Stack.Item mb={1}>
                  <NoticeBox danger style={{ maxWidth: '300px' }}>{ data.error }</NoticeBox>
                </Stack.Item>
              ) : (<Box />)}
              <Stack.Item>
                <Input
                  monospace
                  maxLength="11"
                  placeholder="ABCDE-FGHIJ"
                  style={{ fontSize: '14px', textTransform: 'uppercase' }}
                  disabled={data.pending}
                  value={data.code}
                  onInput={(_, value) => setCode(value.toUpperCase())} />
              </Stack.Item>
              <Stack.Item mt={1}>
                <Button
                  icon={data.pending ? "spinner" : "bolt"}
                  iconSpin={data.pending}
                  disabled={data.pending || !validateCode(code)}
                  content="Подключиться"
                  onClick={() => act('connect', { code })} />
              </Stack.Item>
            </Stack>
          </Section>
        ) : (
          <Section title="Статус" fill buttons={<Button icon="times" onClick={() => act('disconnect')}>Отключиться</Button>}>
            <Stack direction="column" justify="center" align="center" fill>
              <Stack.Item>
                <span>Подключен к аккаунту </span>
                <b>{ data.username }</b>
              </Stack.Item>
              <Stack.Item mt={1} fontSize={0.9} style={{ fontStyle: 'italic' }}>(Это окошко можно закрыть)</Stack.Item>
            </Stack>
          </Section>
        ) }
      </Window.Content>
    </Window>
  ); ``;
};

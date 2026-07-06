import { useBackend, useLocalState } from '../backend';
import { Box, Button, Input, NoticeBox, Section, Stack } from '../components';
import { Window } from '../layouts';

const DirectRecruit = (props) => {
  const { act, data } = useBackend();
  const { name, comments, is_inteq } = data;
  const [input, setInput] = useLocalState('paiDirectInput', {
    name: name || '',
    comments: comments || '',
  });

  const { name: iName, comments: iComments } = input;

  return (
    <Window width={400} height={370} title="Заявка на роль ПИИ">
      <Window.Content>
        <Stack fill vertical>
          {!!is_inteq && (
            <Stack.Item>
              <NoticeBox danger>
                Внимание! Это интековский ПИИ — роль помощника антагониста.
                Вы помогаете носителю в его целях, даже если они противоречат
                закону.
              </NoticeBox>
            </Stack.Item>
          )}
          <Stack.Item grow>
            <Section title="Данные личности" fill>
              <Stack fill vertical>
                <Stack.Item>
                  <Box bold color="label">
                    Имя
                  </Box>
                  <Input
                    fluid
                    maxLength={41}
                    value={iName}
                    onChange={(e, value) =>
                      setInput({ ...input, name: value })
                    }
                  />
                </Stack.Item>
                <Stack.Item mt={1}>
                  <Box bold color="label">
                    OOC заметки
                  </Box>
                  <Input
                    fluid
                    maxLength={256}
                    value={iComments}
                    onChange={(e, value) =>
                      setInput({ ...input, comments: value })
                    }
                  />
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Button
              fluid
              icon="check"
              color="good"
              textAlign="center"
              onClick={() =>
                act('submit', {
                  name: iName,
                  comments: iComments,
                })
              }
            >
              Занять роль
            </Button>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const NormalRecruit = (props) => {
  const { act, data } = useBackend();
  const { comments, description, name, has_candidate } = data;
  const [input, setInput] = useLocalState('paiInput', {
    comments: comments || '',
    description: description || '',
    name: name || '',
  });

  const { comments: iComments, description: iDesc, name: iName } = input;

  return (
    <Window width={400} height={520} title="Меню кандидатов ПИИ">
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Section title="О роли ПИИ" scrollable>
              <Box color="label">
                Персональные ИИ — это продвинутые модели, способные к тонко
                настроенному взаимодействию. Они созданы, чтобы помогать своим
                хозяевам в работе. У них нет рук, поэтому они не могут
                взаимодействовать с оборудованием или предметами. Находясь в
                форме голограммы, вы не можете быть убиты напрямую, но можете
                быть выведены из строя.
                <br />
                <br />
                От вас ожидается в определённой степени участие в ролевой игре.
                Имейте в виду: если вы не укажете свои данные, вас могут не
                выбрать. Нажмите «Отправить», чтобы уведомить ПИИ-карты о вашей
                кандидатуре.
              </Box>
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Section title="Данные кандидата" fill>
              {!has_candidate && (
                <NoticeBox info>
                  Заполните поля и нажмите «Отправить», чтобы стать доступным
                  для загрузки.
                </NoticeBox>
              )}
              <Stack fill vertical>
                <Stack.Item>
                  <Box bold color="label">
                    Имя
                  </Box>
                  <Input
                    fluid
                    maxLength={41}
                    value={iName}
                    onChange={(e, value) =>
                      setInput({ ...input, name: value })
                    }
                  />
                </Stack.Item>
                <Stack.Item>
                  <Box bold color="label">
                    Описание
                  </Box>
                  <Input
                    fluid
                    maxLength={256}
                    value={iDesc}
                    onChange={(e, value) =>
                      setInput({ ...input, description: value })
                    }
                  />
                </Stack.Item>
                <Stack.Item>
                  <Box bold color="label">
                    OOC комментарии
                  </Box>
                  <Input
                    fluid
                    maxLength={256}
                    value={iComments}
                    onChange={(e, value) =>
                      setInput({ ...input, comments: value })
                    }
                  />
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Section>
              <Stack>
                <Stack.Item grow>
                  <Button
                    fluid
                    icon="save"
                    onClick={() =>
                      act('save', {
                        comments: iComments,
                        description: iDesc,
                        name: iName,
                      })
                    }
                    tooltip="Сохраняет данные локально."
                  >
                    Сохранить
                  </Button>
                </Stack.Item>
                <Stack.Item grow>
                  <Button
                    fluid
                    icon="upload"
                    onClick={() => act('load')}
                    tooltip="Загружает сохранённые данные."
                  >
                    Загрузить
                  </Button>
                </Stack.Item>
                <Stack.Item grow>
                  <Button
                    fluid
                    icon="check"
                    color="good"
                    onClick={() =>
                      act('submit', {
                        comments: iComments,
                        description: iDesc,
                        name: iName,
                      })
                    }
                    tooltip="Отправить кандидатуру."
                  >
                    Отправить
                  </Button>
                </Stack.Item>
                <Stack.Item grow>
                  <Button
                    fluid
                    icon="times"
                    color="bad"
                    onClick={() => act('withdraw')}
                    tooltip="Отозвать кандидатуру."
                  >
                    Отозвать
                  </Button>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

export const PaiSubmit = (props) => {
  const { data } = useBackend();
  const { card_ref, load_version } = data;

  if (card_ref) {
    return <DirectRecruit />;
  }
  return <NormalRecruit key={load_version || 'default'} />;
};
import { useBackend } from '../backend';
import { Box, Button, Icon, LabeledList, NoticeBox, Section, Stack } from '../components';
import { Window } from '../layouts';

export const PaiRecruit = (props, context) => {
  const { act, data } = useBackend(context);
  const { candidates = [], device, searching } = data;
  return (
    <Window title="Поиск pAI" width={500} height={500}>
      <Window.Content>
        <Section title="Доступные личности">
          {candidates.length === 0 && (
            <NoticeBox info>
              <Icon name={searching ? 'spinner' : 'search'} spin={!!searching} />{' '}
              {searching ? 'Идет поиск свободных личностей...' : 'Нет доступных личностей.'}
            </NoticeBox>
          )}
          <Stack vertical>
            {candidates.map(c => (
              <Stack.Item key={c.ref}>
                <Section title={c.name || 'Безымянный'}>
                  <LabeledList>
                    <LabeledList.Item label="Описание">
                      {c.description || 'Нет'}
                    </LabeledList.Item>
                    <LabeledList.Item label="Предпочитаемая роль">
                      {c.role || 'Нет'}
                    </LabeledList.Item>
                    <LabeledList.Item label="Комментарии">
                      {c.comments || 'Нет'}
                    </LabeledList.Item>
                  </LabeledList>
                  <Box mt={1}>
                    <Button
                      icon="download"
                      color="good"
                      onClick={() => act('download', {
                        candidate: c.ref,
                        device: device,
                      })}
                    >
                      Загрузить {c.name || 'личность'}
                    </Button>
                  </Box>
                </Section>
              </Stack.Item>
            ))}
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};
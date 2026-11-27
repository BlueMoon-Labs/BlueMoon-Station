import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Input, Section, Stack, TextArea } from '../components';
import { Window } from '../layouts';
import { type PhotoMedia, PhotoPreview } from './PhotoViewer';

type PhotoEditorData = PhotoMedia & {
  defaultName: string;
  nameLimit: number;
  descriptionLimit: number;
  captionLimit: number;
};

export const PhotoEditor = () => {
  const { act, data } = useBackend<PhotoEditorData>();
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [caption, setCaption] = useState('');

  return (
    <Window width={820} height={530}>
      <Window.Content fitted>
        <Stack fill vertical>
          <Stack.Item grow style={{ minHeight: 0, overflow: 'auto' }}>
            <Box
              p={1}
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(min(100%, 18rem), 1fr))',
                gap: '0.75rem',
              }}>
              <Section title="Снимок">
                <PhotoPreview {...data} />
              </Section>
              <Section title="Оформление">
                <Stack vertical>
                  <Stack.Item>
                    <Box as="label" display="block">
                      <Box mb={0.5}>Название</Box>
                      <Input
                        fluid
                        maxLength={data.nameLimit}
                        placeholder={data.defaultName}
                        value={name}
                        onInput={(_, value) => setName(value)} />
                    </Box>
                  </Stack.Item>
                  <Stack.Item>
                    <Box as="label" display="block">
                      <Box mb={0.5}>Дополнение к описанию</Box>
                      <TextArea
                        dontUseTabForIndent
                        fluid
                        scrollbar
                        height="7em"
                        maxLength={data.descriptionLimit}
                        value={description}
                        onInput={(_, value) => setDescription(value)} />
                    </Box>
                  </Stack.Item>
                  <Stack.Item>
                    <Box as="label" display="block">
                      <Box mb={0.5}>Подпись на обратной стороне</Box>
                      <TextArea
                        dontUseTabForIndent
                        fluid
                        scrollbar
                        height="7em"
                        maxLength={data.captionLimit}
                        value={caption}
                        onInput={(_, value) => setCaption(value)} />
                    </Box>
                  </Stack.Item>
                </Stack>
              </Section>
            </Box>
          </Stack.Item>
          <Stack.Item px={1} pb={1}>
            <Stack justify="flex-end">
              <Stack.Item>
                <Button onClick={() => act('cancel')}>Отменить</Button>
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="check"
                  onClick={() => act('save', { name, description, caption })}>
                  Сохранить
                </Button>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import { Box, Button, Divider, Flex, NoticeBox, Stack } from '../components';
import { Window } from '../layouts';

type NewsItem = {
  body: string;
  author: string;
  image: string | null;
};

type ChannelPage = {
  name: string;
  author: string;
  censored: BooleanLike;
  empty: BooleanLike;
  messages: NewsItem[];
};

type ContentsEntry = {
  name: string;
  page: number;
};

export type NewspaperData = {
  currPage: number;
  pages: number;
  lastPage: number;
  scribble: string | null;
  wantedAuthor: string;
  wantedCriminal: string;
  wantedBody: string;
  wantedPhoto: string | null;
  contents: ContentsEntry[];
  channel: ChannelPage | null;
};

/** Обложка: оглавление выпуска. */
const Cover = () => {
  const { data } = useBackend<NewspaperData>();
  const contents = Array.isArray(data.contents) ? data.contents : [];
  return (
    <>
      {!contents.length && !data.wantedAuthor && (
        <Box italic color="label">
          Кроме заголовка, остальная часть газеты не напечатана...
        </Box>
      )}
      {!!contents.length && (
        <>
          <Box bold mb={0.5}>
            Содержание:
          </Box>
          <Stack vertical>
            {contents.map((entry) => (
              <Stack.Item key={entry.name}>
                <Box>
                  <b>{entry.name}</b> — страница {entry.page}
                </Box>
              </Stack.Item>
            ))}
            {!!data.wantedAuthor && (
              <Stack.Item>
                <Box color="bad">
                  <b>** Важное сообщение службы безопасности **</b> — страница {data.pages + 2}
                </Box>
              </Stack.Item>
            )}
          </Stack>
        </>
      )}
    </>
  );
};

/** Страница с новостями канала. */
const ChannelView = () => {
  const { data } = useBackend<NewspaperData>();
  const channel = data.channel;
  if (!channel) {
    return <Box color="label">Страница пуста.</Box>;
  }
  const messages = Array.isArray(channel.messages) ? channel.messages : [];
  return (
    <>
      <Box mb={0.5} fontSize="1.4rem" bold>
        {channel.name}
      </Box>
      <Box mb={1} color="label" fontSize="0.85rem">
        создано: {channel.author}
      </Box>
      {!!channel.censored && (
        <NoticeBox danger mb={1}>
          Канал был признан опасным для благополучия станции и помечен D-Notice. Его содержимое не было напечатано.
        </NoticeBox>
      )}
      {!channel.censored && !messages.length && (
        <Box italic color="label">
          От этого канала не поступило ни одной новости...
        </Box>
      )}
      <Stack vertical>
        {!channel.censored && messages.map((message, index) => (
          <Stack.Item key={index} mb={1}>
            <Box preserveWhitespace>{message.body}</Box>
            {!!message.image && (
              <Box mt={0.5}>
                <img src={message.image} width={180} alt="Фото к новости" />
              </Box>
            )}
            <Box mt={0.5} color="label" fontSize="0.85rem">
              — {message.author}
            </Box>
            <Divider />
          </Stack.Item>
        ))}
      </Stack>
    </>
  );
};

/** Последняя страница: розыск или объявления. */
const LastPage = () => {
  const { data } = useBackend<NewspaperData>();
  if (!data.wantedAuthor) {
    return (
      <Box italic color="label">
        Кроме неинтересных объявлений, на этой странице ничего нет...
      </Box>
    );
  }
  return (
    <>
      <Box mb={1} fontSize="1.4rem" bold color="bad">
        Объявление в розыск
      </Box>
      <Box mb={0.5}>
        <b>Разыскиваемый:</b> {data.wantedCriminal}
      </Box>
      <Box mb={0.5} preserveWhitespace>
        <b>Описание:</b> {data.wantedBody}
      </Box>
      {!!data.wantedPhoto && (
        <Box mb={0.5}>
          <img src={data.wantedPhoto} width={180} alt="Фото разыскиваемого" />
        </Box>
      )}
      <Box color="label" fontSize="0.85rem">
        Опубликовал: {data.wantedAuthor}
      </Box>
    </>
  );
};

/** Газета «The Griffon»: старое HTML-окно заменено на tgui. */
export const Newspaper = () => {
  const { act, data } = useBackend<NewspaperData>();
  const cover = data.currPage === 0;
  const last = data.currPage >= data.lastPage;
  return (
    <Window width={460} height={620} title="Газета">
      <Window.Content scrollable>
        <Box textAlign="center" mb={0.5}>
          <Box fontSize="2rem" bold>
            The Griffon
          </Box>
          <Box color="label" fontSize="0.8rem">
            Nanotrasen-standard newspaper, for use on Nanotrasen? Space Facilities
          </Box>
        </Box>
        <Divider />
        <Box my={1}>
          {cover ? <Cover /> : last ? <LastPage /> : <ChannelView />}
        </Box>
        {!!data.scribble && (
          <NoticeBox info mt={1}>
            <i>
              На этой странице есть небольшая пометка: «{data.scribble}»
            </i>
          </NoticeBox>
        )}
        <Divider />
        <Flex justify="space-between" align="center" mt={1}>
          <Flex.Item>
            <Button
              icon="arrow-left"
              content="Назад"
              disabled={cover}
              onClick={() => act('prevPage')}
            />
          </Flex.Item>
          <Flex.Item>
            <Box color="label">{data.currPage + 1}</Box>
          </Flex.Item>
          <Flex.Item>
            <Button
              icon="arrow-right"
              content="Вперёд"
              disabled={last}
              onClick={() => act('nextPage')}
            />
          </Flex.Item>
        </Flex>
        <Box mt={1} textAlign="center">
          <Button icon="xmark" content="Закончить чтение" onClick={() => act('close')} />
        </Box>
      </Window.Content>
    </Window>
  );
};

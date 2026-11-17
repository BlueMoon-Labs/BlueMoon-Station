import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import { Box, Button, NoticeBox, Section, Stack } from '../components';
import { Window } from '../layouts';

type NewsChannel = {
  ref: string;
  name: string;
  messages: number;
  locked: BooleanLike;
  censored: BooleanLike;
  admin: BooleanLike;
};

type NewsComment = {
  body: string;
  author: string;
  time: string;
};

type NewsMessage = {
  body: string;
  author: string;
  time: string;
  image: string | null;
  caption: string;
  comments: NewsComment[];
  locked: BooleanLike;
};

export type NewsChannelsData = {
  channels: NewsChannel[];
  selected: string | null;
  channelName?: string;
  channelAuthor?: string;
  channelCensored?: BooleanLike;
  messages: NewsMessage[];
};

/** Список каналов новостей. */
const ChannelList = () => {
  const { act, data } = useBackend<NewsChannelsData>();
  // Пустой список из BYOND приходит как {} — проверяем именно массив.
  const channels = Array.isArray(data.channels) ? data.channels : [];
  return (
    <Section title="Каналы новостей">
      {!channels.length && <NoticeBox info>Нет доступных каналов.</NoticeBox>}
      <Stack vertical>
        {channels.map((channel) => (
          <Stack.Item key={channel.ref}>
            <Section
              fitted
              title={channel.name}
              buttons={
                <Button
                  icon="chevron-right"
                  content="Открыть"
                  onClick={() => act('select', { channel: channel.ref })}
                />
              }>
              <Box color="label" fontSize="0.85rem">
                {channel.messages} сообщений
                {!!channel.locked && <span className="color-bad"> • ЗАКРЫТ</span>}
                {!!channel.censored && <span className="color-bad"> • CENSORED</span>}
                {!!channel.admin && <span className="color-good"> • ADMIN</span>}
              </Box>
            </Section>
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

/** Сообщения выбранного канала. */
const ChannelView = () => {
  const { act, data } = useBackend<NewsChannelsData>();
  const messages = Array.isArray(data.messages) ? data.messages : [];
  return (
    <Section
      title={data.channelName || 'Канал'}
      buttons={
        <Button
          icon="arrow-left"
          content="К списку"
          onClick={() => act('back')}
        />
      }>
      <Box mb={1} color="label">
        Создатель: {data.channelAuthor || 'неизвестно'}
      </Box>
      {!!data.channelCensored && (
        <NoticeBox danger>
          Канал признан угрожающим благополучию станции и помечен D-Notice Nanotrasen.
        </NoticeBox>
      )}
      {!messages.length && <NoticeBox info>В канале нет сообщений.</NoticeBox>}
      <Stack vertical>
        {messages.map((message, index) => (
          <Stack.Item key={index}>
            <Section fitted title={`${message.author} — ${message.time}`}>
              <Box preserveWhitespace>{message.body}</Box>
              {!!message.image && (
                <Box mt={0.5}>
                  <img src={message.image} width={180} alt={message.caption || 'Фото'} />
                </Box>
              )}
              {!!message.caption && (
                <Box mt={0.5} italic>
                  {message.caption}
                </Box>
              )}
              {Array.isArray(message.comments) && !!message.comments.length && (
                <Box mt={0.5}>
                  <b>
                    {message.comments.length} комментариев
                  </b>
                  {message.comments.map((comment, commentIndex) => (
                    <Box key={commentIndex} ml={1} fontSize="0.85rem" color="label">
                      {comment.body} — {comment.author} ({comment.time})
                    </Box>
                  ))}
                </Box>
              )}
              {!!message.locked && (
                <Box mt={0.5} color="bad">
                  Комментарии закрыты
                </Box>
              )}
            </Section>
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

/** Просмотр новостных каналов для призраков. */
export const NewsChannels = () => {
  const { data } = useBackend<NewsChannelsData>();
  return (
    <Window width={560} height={720} title="Каналы новостей">
      <Window.Content scrollable>
        {data.selected ? <ChannelView /> : <ChannelList />}
      </Window.Content>
    </Window>
  );
};

import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import { Box, Button, NoticeBox, Section, Stack } from '../components';
import { Window } from '../layouts';

type Channel = {
  ref: string;
  name: string;
  author: string;
  locked: BooleanLike;
  censored: BooleanLike;
  admin: BooleanLike;
  messages: number;
};

type Comment = {
  ref: string;
  body: string;
  author: string;
  time: string;
};

type FeedMessage = {
  ref: string;
  body: string;
  author: string;
  time: string;
  image: string | null;
  caption: string;
  comments: Comment[];
  locked: BooleanLike;
  bodyCensor: BooleanLike;
  authorCensor: BooleanLike;
  admin: BooleanLike;
};

type ViewingChannel = {
  ref: string;
  name: string;
  author: string;
  censored: BooleanLike;
  admin: BooleanLike;
  authorCensor: BooleanLike;
  messages: FeedMessage[];
};

export type NewscasterData = {
  unitNo: number;
  securityCaster: BooleanLike;
  scannedUser: string;
  screen: number;
  paperRemaining: number;
  channelName: string;
  cLocked: BooleanLike;
  message: string;
  allowComments: BooleanLike;
  pictureAttached: BooleanLike;
  picture: string | null;
  wantedActive: BooleanLike;
  wantedAdmin: BooleanLike;
  wantedCriminal: string;
  wantedBody: string;
  wantedAuthor: string;
  wantedPhoto: string | null;
  channels: Channel[];
  viewingChannel: ViewingChannel | null;
};

const BackButton = () => {
  const { act } = useBackend<NewscasterData>();
  return <Button icon="arrow-left" content="Назад" onClick={() => act('navigate', { screen: 0 })} />;
};

/** Главное меню. */
const MainMenu = () => {
  const { act, data } = useBackend<NewscasterData>();
  return (
    <>
      <Section title="Главное меню">
        <Box mb={1} color="label">
          Добро пожаловать в новостной терминал #{data.unitNo}. Интерфейс и новостная сеть работают.
        </Box>
        <NoticeBox info>Property of Nanotrasen Inc</NoticeBox>
        <Stack vertical mt={1}>
          {!!data.wantedActive && (
            <Stack.Item>
              <Button
                fluid
                icon="user-secret"
                content="Прочитать объявление в розыск"
                onClick={() => act('navigate', { screen: 18 })}
              />
            </Stack.Item>
          )}
          <Stack.Item>
            <Button fluid icon="plus" content="Создать новостной канал" onClick={() => act('navigate', { screen: 2 })} />
          </Stack.Item>
          <Stack.Item>
            <Button fluid icon="list" content="Просмотреть каналы" onClick={() => act('navigate', { screen: 1 })} />
          </Stack.Item>
          <Stack.Item>
            <Button fluid icon="pen" content="Подать новость" onClick={() => act('navigate', { screen: 3 })} />
          </Stack.Item>
          <Stack.Item>
            <Button fluid icon="newspaper" content="Распечатать газету" onClick={() => act('navigate', { screen: 8 })} />
          </Stack.Item>
          <Stack.Item>
            <Button fluid icon="refresh" content="Пересканировать пользователя" onClick={() => act('refresh')} />
          </Stack.Item>
        </Stack>
      </Section>

      {!!data.securityCaster && (
        <Section title="Служба безопасности">
          <Stack vertical>
            <Stack.Item>
              <Button fluid icon="eye" content="Цензура новостей" onClick={() => act('navigate', { screen: 10 })} />
            </Stack.Item>
            <Stack.Item>
              <Button fluid icon="ban" content="Распоряжения D-Notice" onClick={() => act('navigate', { screen: 11 })} />
            </Stack.Item>
            <Stack.Item>
              <Button
                fluid
                icon="user-secret"
                content={data.wantedActive ? 'Управление розыском' : 'Объявить в розыск'}
                onClick={() => act('menuWanted')}
              />
            </Stack.Item>
          </Stack>
        </Section>
      )}

      <Section title="Оператор">
        <Box color="good">Терминал распознаёт вас как: {data.scannedUser}</Box>
      </Section>
    </>
  );
};

/** Список каналов. */
const ChannelList = () => {
  const { act, data } = useBackend<NewscasterData>();
  const channels = Array.isArray(data.channels) ? data.channels : [];
  return (
    <Section title="Каналы новостей" buttons={<BackButton />}>
      {!channels.length && <NoticeBox info>Нет активных каналов.</NoticeBox>}
      <Stack vertical>
        {channels.map((channel) => (
          <Stack.Item key={channel.ref}>
            <Section
              fitted
              title={channel.name}
              buttons={
                <Button icon="chevron-right" content="Открыть" onClick={() => act('viewChannel', { channel: channel.ref })} />
              }>
              <Box color="label" fontSize="0.85rem">
                {channel.messages} сообщений {!!channel.censored && <span className="color-bad"> • D-NOTICE</span>}
                {!!channel.admin && <span className="color-good"> • ADMIN</span>}
              </Box>
            </Section>
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

/** Создание канала. */
const CreateChannel = () => {
  const { act, data } = useBackend<NewscasterData>();
  return (
    <Section title="Создание канала" buttons={<BackButton />}>
      <Stack vertical>
        <Stack.Item>
          <Box mb={0.5} color="label">
            Название канала
          </Box>
          <Button icon="pen" content={data.channelName || 'Ввести название'} onClick={() => act('setChannelName')} />
        </Stack.Item>
        <Stack.Item>
          <Box color="label">
            Автор: <b>{data.scannedUser}</b>
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon={data.cLocked ? 'lock' : 'lock-open'}
            content={data.cLocked ? 'Приём публичных сообщений: НЕТ' : 'Приём публичных сообщений: ДА'}
            selected={!data.cLocked}
            onClick={() => act('toggleChannelLock')}
          />
        </Stack.Item>
        <Stack.Item mt={1}>
          <Button.Confirm
            icon="check"
            color="good"
            content="Создать канал"
            confirmContent="Создать этот канал?"
            disabled={!data.channelName}
            onClick={() => act('submitNewChannel')}
          />
        </Stack.Item>
      </Stack>
    </Section>
  );
};

/** Написание новости. */
const CreateStory = () => {
  const { act, data } = useBackend<NewscasterData>();
  const channels = Array.isArray(data.channels) ? data.channels : [];
  const available = channels.filter((channel) => (!channel.locked || channel.author === data.scannedUser) && !channel.censored);
  return (
    <Section title="Новая новость" buttons={<BackButton />}>
      <Stack vertical>
        <Stack.Item>
          <Box mb={0.5} color="label">
            Канал-получатель: <b>{data.channelName || 'не выбран'}</b>
          </Box>
          <Stack vertical>
            {available.map((channel) => (
              <Stack.Item key={channel.ref}>
                <Button
                  fluid
                  icon={data.channelName === channel.name ? 'check' : 'circle'}
                  selected={data.channelName === channel.name}
                  content={channel.name}
                  onClick={() => act('selectReceivingChannel', { channel: channel.ref })}
                />
              </Stack.Item>
            ))}
            {!available.length && <Box color="bad">Нет доступных каналов.</Box>}
          </Stack>
        </Stack.Item>
        <Stack.Item mt={1}>
          <Box mb={0.5} color="label">
            Текст новости
          </Box>
          <Box preserveWhitespace mb={0.5}>
            {data.message || <i>Не написано</i>}
          </Box>
          <Button icon="pen" content={data.message ? 'Изменить текст' : 'Написать текст'} onClick={() => act('setMessage')} />
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="image"
            content={data.pictureAttached ? 'Открепить фото' : 'Прикрепить фото'}
            selected={!!data.pictureAttached}
            onClick={() => act('toggleAttachment')}
          />
          <Button
            icon="comment"
            content={data.allowComments ? 'Комментарии: ВКЛ' : 'Комментарии: ВЫКЛ'}
            selected={!!data.allowComments}
            onClick={() => act('toggleComments')}
          />
        </Stack.Item>
        {!!data.picture && (
          <Stack.Item>
            <img src={data.picture} width={180} alt="Вложение" />
          </Stack.Item>
        )}
        <Stack.Item mt={1}>
          <Button.Confirm
            icon="paper-plane"
            color="good"
            content="Опубликовать"
            confirmContent="Опубликовать новость?"
            disabled={!data.message || !data.channelName}
            onClick={() => act('submitNewMessage')}
          />
        </Stack.Item>
      </Stack>
    </Section>
  );
};

/** Экраны результата. */
const ResultScreen = () => {
  const { act, data } = useBackend<NewscasterData>();
  const screen = data.screen;
  const results: Record<number, { title: string; text: string; good: boolean }> = {
    4: { title: 'Готово', text: 'Новость опубликована в ленте.', good: true },
    5: { title: 'Готово', text: 'Новостной канал создан.', good: true },
    6: {
      title: 'Ошибка',
      text: 'Не удалось опубликовать новость: неверный текст, канал или неподтверждённый автор.',
      good: false,
    },
    7: {
      title: 'Ошибка',
      text: 'Не удалось создать канал: неверное название, конфликт с существующим каналом или автором.',
      good: false,
    },
    15: { title: 'Готово', text: 'Объявление в розыск опубликовано.', good: true },
    16: { title: 'Ошибка', text: 'Не удалось опубликовать розыск: заполните имя и описание.', good: false },
    17: { title: 'Готово', text: 'Объявление снято с публикации.', good: true },
    19: { title: 'Готово', text: 'Объявление в розыск изменено.', good: true },
    20: { title: 'Готово', text: 'Газета напечатана. Заберите её из нижнего отсека.', good: true },
    21: { title: 'Ошибка', text: 'Не удалось напечатать газету: закончилась бумага.', good: false },
  };
  const result = results[screen] || { title: 'Готово', text: '', good: true };
  return (
    <Section title={result.title}>
      <NoticeBox success={result.good} danger={!result.good}>
        {result.text}
      </NoticeBox>
      <Button mt={1} icon="arrow-left" content="Продолжить" onClick={() => act('navigate', { screen: 0 })} />
    </Section>
  );
};

/** Печать газеты. */
const PrintPaper = () => {
  const { act, data } = useBackend<NewscasterData>();
  return (
    <Section title="Печать газеты" buttons={<BackButton />}>
      <Box mb={1}>Бумаги осталось: {data.paperRemaining * 100} см³</Box>
      <Button.Confirm
        icon="print"
        color="good"
        content="Напечатать"
        confirmContent="Напечатать выпуск газеты?"
        disabled={!data.paperRemaining}
        onClick={() => act('printPaper')}
      />
    </Section>
  );
};

/** Просмотр канала. */
const ViewChannel = () => {
  const { act, data } = useBackend<NewscasterData>();
  const viewing = data.viewingChannel;
  const messages = viewing && Array.isArray(viewing.messages) ? viewing.messages : [];
  return (
    <Section title={viewing?.name || 'Канал'} buttons={<Button icon="list" content="К каналам" onClick={() => act('navigate', { screen: 1 })} />}>
      <Box mb={1} color="label">
        Создатель: {viewing?.author || 'неизвестно'}
      </Box>
      {!!viewing?.censored && <NoticeBox danger>Канал помечен распоряжением D-Notice.</NoticeBox>}
      {!messages.length && <NoticeBox info>В канале нет сообщений.</NoticeBox>}
      <Stack vertical>
        {messages.map((message) => {
          const comments = Array.isArray(message.comments) ? message.comments : [];
          return (
            <Stack.Item key={message.ref}>
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
                {!!comments.length && (
                  <Box mt={0.5}>
                    <b>{comments.length} комментариев</b>
                    {comments.map((comment) => (
                      <Box key={comment.ref} ml={1} fontSize="0.85rem" color="label">
                        {comment.body} — {comment.author} ({comment.time})
                      </Box>
                    ))}
                  </Box>
                )}
                <Box mt={0.5}>
                  {!message.locked ? (
                    <Button icon="comment" content="Комментировать" onClick={() => act('newComment', { message: message.ref })} />
                  ) : (
                    <Box color="bad">Комментарии закрыты</Box>
                  )}
                </Box>
              </Section>
            </Stack.Item>
          );
        })}
      </Stack>
    </Section>
  );
};

/** Выбор канала для цензуры / D-Notice. */
const ChannelPicker = () => {
  const { act, data } = useBackend<NewscasterData>();
  const channels = Array.isArray(data.channels) ? data.channels : [];
  const dnotice = data.screen === 11;
  return (
    <Section title={dnotice ? 'Распоряжения D-Notice' : 'Цензура новостей'} buttons={<BackButton />}>
      <NoticeBox info>
        {dnotice
          ? 'D-Notice закрывает канал для обновлений, не удаляя уже опубликованные сообщения.'
          : 'Выберите канал, чтобы управлять цензурой сообщений.'}
      </NoticeBox>
      <Stack vertical mt={1}>
        {channels.map((channel) => (
          <Stack.Item key={channel.ref}>
            <Button
              fluid
              icon={channel.censored ? 'ban' : 'eye'}
              color={channel.censored ? 'bad' : undefined}
              content={channel.name}
              onClick={() => act(dnotice ? 'pickDNotice' : 'pickCensorChannel', { channel: channel.ref })}
            />
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

/** Цензура сообщений выбранного канала. */
const CensorChannel = () => {
  const { act, data } = useBackend<NewscasterData>();
  const viewing = data.viewingChannel;
  const messages = viewing && Array.isArray(viewing.messages) ? viewing.messages : [];
  return (
    <Section title={`Цензура: ${viewing?.name || ''}`} buttons={<Button icon="arrow-left" content="Назад" onClick={() => act('navigate', { screen: 10 })} />}>
      {!!viewing && !viewing.admin && (
        <Box mb={1}>
          <Button
            icon="user-slash"
            content={viewing.authorCensor ? 'Отменить цензуру автора канала' : 'Скрыть автора канала'}
            onClick={() => act('censorChannelAuthor', { channel: viewing.ref })}
          />
        </Box>
      )}
      <Stack vertical>
        {messages.map((message) => {
          const comments = Array.isArray(message.comments) ? message.comments : [];
          return (
            <Stack.Item key={message.ref}>
              <Section fitted title={message.time}>
                <Box preserveWhitespace>{message.body}</Box>
                {!message.admin && (
                  <Box mt={0.5}>
                    <Button
                      icon="user-slash"
                      content={message.authorCensor ? 'Показать автора' : 'Скрыть автора'}
                      onClick={() => act('censorStoryAuthor', { message: message.ref })}
                    />
                    <Button
                      icon="eye-slash"
                      content={message.bodyCensor ? 'Показать текст' : 'Скрыть текст'}
                      onClick={() => act('censorStoryBody', { message: message.ref })}
                    />
                    <Button
                      icon={message.locked ? 'lock-open' : 'lock'}
                      content={message.locked ? 'Открыть комментарии' : 'Закрыть комментарии'}
                      onClick={() => act('lockComment', { message: message.ref })}
                    />
                  </Box>
                )}
                {!!comments.length && (
                  <Box mt={0.5}>
                    {comments.map((comment) => (
                      <Box key={comment.ref}>
                        {comment.body} — {comment.author}
                        <Button
                          icon="trash"
                          color="bad"
                          content="Удалить"
                          onClick={() => act('delComment', { comment: comment.ref, message: message.ref })}
                        />
                      </Box>
                    ))}
                  </Box>
                )}
              </Section>
            </Stack.Item>
          );
        })}
      </Stack>
    </Section>
  );
};

/** D-Notice для выбранного канала. */
const DNoticeChannel = () => {
  const { act, data } = useBackend<NewscasterData>();
  const viewing = data.viewingChannel;
  return (
    <Section title={`D-Notice: ${viewing?.name || ''}`} buttons={<Button icon="arrow-left" content="Назад" onClick={() => act('navigate', { screen: 11 })} />}>
      <NoticeBox danger>
        D-Notice делает канал недоступным для обновлений, сохраняя уже опубликованные статьи.
      </NoticeBox>
      {viewing?.admin ? (
        <Box mt={1} color="bad">
          Канал создан представителем Nanotrasen — наложить D-Notice нельзя.
        </Box>
      ) : (
        <Button.Confirm
          mt={1}
          icon="ban"
          color="bad"
          content={viewing?.censored ? 'Снять D-Notice' : 'Наложить D-Notice'}
          confirmContent={viewing?.censored ? 'Снять D-Notice с канала?' : 'Наложить D-Notice на канал?'}
          onClick={() => act('toggleDNotice', { channel: viewing?.ref })}
        />
      )}
    </Section>
  );
};

/** Форма розыска. */
const WantedForm = () => {
  const { act, data } = useBackend<NewscasterData>();
  return (
    <Section title="Объявление в розыск" buttons={<BackButton />}>
      {!!data.wantedAdmin && <NoticeBox danger>Действующее объявление опубликовано Nanotrasen. Редактирование недоступно.</NoticeBox>}
      <Stack vertical mt={1}>
        <Stack.Item>
          <Box mb={0.5} color="label">
            Имя разыскиваемого
          </Box>
          <Button icon="pen" content={data.channelName || 'Ввести имя'} onClick={() => act('setWantedName')} />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5} color="label">
            Описание
          </Box>
          <Box preserveWhitespace mb={0.5}>
            {data.message || <i>Не заполнено</i>}
          </Box>
          <Button icon="pen" content={data.message ? 'Изменить описание' : 'Написать описание'} onClick={() => act('setWantedDesc')} />
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="image"
            content={data.pictureAttached ? 'Открепить фото' : 'Прикрепить фото'}
            selected={!!data.pictureAttached}
            onClick={() => act('toggleAttachment')}
          />
        </Stack.Item>
        <Stack.Item mt={1}>
          <Button.Confirm
            icon="paper-plane"
            color="good"
            content={data.wantedActive ? 'Сохранить изменения' : 'Опубликовать'}
            confirmContent="Подтвердить публикацию розыска?"
            disabled={!data.channelName || !data.message || !!data.wantedAdmin}
            onClick={() => act('submitWanted', { mode: data.wantedActive ? 2 : 1 })}
          />
          {!!data.wantedActive && !data.wantedAdmin && (
            <Button.Confirm
              icon="trash"
              color="bad"
              content="Снять с публикации"
              confirmContent="Снять объявление с публикации?"
              onClick={() => act('cancelWanted')}
            />
          )}
        </Stack.Item>
      </Stack>
    </Section>
  );
};

/** Просмотр действующего розыска. */
const WantedView = () => {
  const { act, data } = useBackend<NewscasterData>();
  return (
    <Section title="Объявление в розыск" buttons={<BackButton />}>
      <Box mb={1} color="bad">
        <b>ВНИМАНИЕ — РОЗЫСК</b>
      </Box>
      <Box mb={0.5}>
        <b>Разыскиваемый:</b> {data.wantedCriminal}
      </Box>
      <Box mb={0.5} preserveWhitespace>
        {data.wantedBody}
      </Box>
      {!!data.wantedPhoto && (
        <Box mb={0.5}>
          <img src={data.wantedPhoto} width={180} alt="Фото разыскиваемого" />
        </Box>
      )}
      <Box color="label">Опубликовал: {data.wantedAuthor}</Box>
    </Section>
  );
};

/** Новостной терминал: старое HTML-окно заменено на tgui. */
export const Newscaster = () => {
  const { data } = useBackend<NewscasterData>();
  const screen = data.screen || 0;
  return (
    <Window width={560} height={640} title={`Новостник #${data.unitNo}`}>
      <Window.Content scrollable>
        <Section title={`Новостник #${data.unitNo}`} buttons={<Box color="label">{data.scannedUser}</Box>}>
          <Box color="label">
            {data.securityCaster ? 'Терминал службы безопасности' : 'Стандартный терминал новостной ленты'}
          </Box>
        </Section>
        {screen === 0 && <MainMenu />}
        {screen === 1 && <ChannelList />}
        {screen === 2 && <CreateChannel />}
        {screen === 3 && <CreateStory />}
        {screen === 8 && <PrintPaper />}
        {screen === 9 && <ViewChannel />}
        {(screen === 10 || screen === 11) && <ChannelPicker />}
        {screen === 12 && <CensorChannel />}
        {screen === 13 && <DNoticeChannel />}
        {screen === 14 && <WantedForm />}
        {screen === 18 && <WantedView />}
        {[4, 5, 6, 7, 15, 16, 17, 19, 20, 21].includes(screen) && <ResultScreen />}
      </Window.Content>
    </Window>
  );
};

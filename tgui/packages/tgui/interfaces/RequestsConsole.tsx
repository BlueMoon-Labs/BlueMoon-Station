import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import { Box, Button, Flex, NoticeBox, Section, Stack } from '../components';
import { Window } from '../layouts';

type Department = {
  name: string;
  ckey: string;
};

type RequestMessage = {
  outgoing: BooleanLike;
  title: string;
  from: string;
  to?: string;
  body: string;
  priority: number;
  verified?: string;
  stamped?: string;
};

export type RequestsConsoleData = {
  department: string;
  departmentRu: string;
  screen: number;
  hacked: BooleanLike;
  speakerOn: BooleanLike;
  emergency: string | null;
  announcementConsole: BooleanLike;
  announceAuth: BooleanLike;
  canAnnounce: BooleanLike;
  message: string;
  recipient: string;
  priority: number;
  verified: string;
  stamped: string;
  newMessages: 'none' | 'normal' | 'high' | 'extreme';
  departments: Department[];
  messages: RequestMessage[];
};

const priorityColor = (priority: number) =>
  priority >= 3 ? 'bad' : priority === 2 ? 'average' : 'good';

const priorityName = (priority: number) =>
  priority >= 3 ? 'Экстремальный' : priority === 2 ? 'Высокий' : 'Обычный';

const BackButton = () => {
  const { act } = useBackend<RequestsConsoleData>();
  return <Button icon="arrow-left" content="Назад" onClick={() => act('navigate', { screen: 0 })} />;
};

/** Главное меню: входящие, запросы, тревоги, объявления и динамик. */
const MainMenu = () => {
  const { act, data } = useBackend<RequestsConsoleData>();
  const newMessageText = {
    extreme: 'Имеются новые сообщения ЭКСТРЕМАЛЬНОЙ ВАЖНОСТИ.',
    high: 'Имеются новые сообщения особой важности.',
    normal: 'Имеются новые сообщения.',
    none: '',
  }[data.newMessages || 'none'];

  return (
    <>
      {!!newMessageText && <NoticeBox info>{newMessageText}</NoticeBox>}
      {!!data.emergency && (
        <NoticeBox danger>
          <b>{data.emergency}</b> ТРЕВОГА НА ДАННОМ МЕСТОПОЛОЖЕНИИ!
        </NoticeBox>
      )}

      <Section
        title="Входящие сообщения"
        buttons={
          <Button
            icon="envelope-open-text"
            content="Открыть"
            onClick={() => act('navigate', { screen: 8 })}
          />
        }>
        <Box color="label">
          Просмотреть сообщения, поступившие на эту консоль.
        </Box>
      </Section>

      <Section title="Отправить запрос">
        <Stack vertical>
          <Stack.Item>
            <Button
              fluid
              icon="hands-helping"
              content="Запросить помощь"
              onClick={() => act('navigate', { screen: 1 })}
            />
          </Stack.Item>
          <Stack.Item>
            <Button
              fluid
              icon="box"
              content="Запросить припасы"
              onClick={() => act('navigate', { screen: 2 })}
            />
          </Stack.Item>
          <Stack.Item>
            <Button
              fluid
              icon="comment-dots"
              content="Передача анонимной информации"
              onClick={() => act('navigate', { screen: 3 })}
            />
          </Stack.Item>
        </Stack>
      </Section>

      <Section title="Тревоги">
        <Stack wrap>
          <Stack.Item>
            <Button.Confirm
              icon="shield-alt"
              color="bad"
              content="Охранная"
              confirmContent="Объявить охранную тревогу?"
              disabled={!!data.emergency}
              onClick={() => act('alarm', { alarm: 1 })}
            />
          </Stack.Item>
          <Stack.Item>
            <Button.Confirm
              icon="wrench"
              color="bad"
              content="Инженерная"
              confirmContent="Объявить инженерную тревогу?"
              disabled={!!data.emergency}
              onClick={() => act('alarm', { alarm: 2 })}
            />
          </Stack.Item>
          <Stack.Item>
            <Button.Confirm
              icon="briefcase-medical"
              color="bad"
              content="Медицинская"
              confirmContent="Объявить медицинскую тревогу?"
              disabled={!!data.emergency}
              onClick={() => act('alarm', { alarm: 3 })}
            />
          </Stack.Item>
        </Stack>
      </Section>

      {!!data.announcementConsole && (
        <Section title="Станционные объявления">
          <Button
            fluid
            icon="bullhorn"
            content="Отправить станционное объявление"
            onClick={() => act('navigate', { screen: 10 })}
          />
        </Section>
      )}

      <Section title="Настройки">
        <Button
          fluid
          icon={data.speakerOn ? 'volume-up' : 'volume-mute'}
          selected={!!data.speakerOn}
          content={data.speakerOn ? 'Динамик включён' : 'Динамик выключен'}
          onClick={() => act('speaker')}
        />
      </Section>
    </>
  );
};

/** Выбор отдела-получателя и приоритета. */
const DepartmentPicker = () => {
  const { act, data } = useBackend<RequestsConsoleData>();
  const titles: Record<number, string> = {
    1: 'Запросить помощь',
    2: 'Запросить припасы',
    3: 'Передача анонимной информации',
  };
  // Пустой список из BYOND приходит как {} — проверяем именно массив.
  const departments = Array.isArray(data.departments) ? data.departments : [];
  return (
    <Section
      title={titles[data.screen]}
      buttons={<BackButton />}>
      <Box mb={1} color="label">
        Выберите отдел и приоритет сообщения.
      </Box>
      {!departments.length && <NoticeBox info>Нет доступных отделов.</NoticeBox>}
      <Stack vertical>
        {departments.map((department) => (
          <Stack.Item key={department.ckey}>
            <Flex align="center">
              <Flex.Item grow={1} mr={1}>
                <Box bold>{department.name}</Box>
              </Flex.Item>
              <Flex.Item>
                <Button
                  icon="paper-plane"
                  content="Обычный"
                  onClick={() => act('compose', { department: department.ckey, priority: 1 })}
                />
                <Button
                  icon="exclamation"
                  color="average"
                  content="Высокий"
                  onClick={() => act('compose', { department: department.ckey, priority: 2 })}
                />
                {!!data.hacked && (
                  <Button
                    icon="skull"
                    color="bad"
                    content="Экстремальный"
                    onClick={() => act('compose', { department: department.ckey, priority: 3 })}
                  />
                )}
              </Flex.Item>
            </Flex>
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

/** История сообщений. */
const MessagesView = () => {
  const { act, data } = useBackend<RequestsConsoleData>();
  const messages = Array.isArray(data.messages) ? data.messages : [];
  return (
    <Section
      title="Сообщения"
      buttons={<BackButton />}>
      {!messages.length && <NoticeBox info>Сообщений нет.</NoticeBox>}
      <Stack vertical>
        {[...messages].reverse().map((message, index) => (
          <Stack.Item key={index}>
            <Section
              fitted
              color={priorityColor(message.priority)}
              title={message.title}
              buttons={
                !message.outgoing && (
                  <Button
                    icon="reply"
                    content="Ответить"
                    onClick={() => act('reply', { department: message.from })}
                  />
                )
              }>
              <Box bold>{priorityName(message.priority)}</Box>
              <Box mt={0.5} preserveWhitespace>
                {message.body}
              </Box>
              <Box mt={0.5} color="label">
                {message.outgoing ? `Кому: ${message.to}` : `От: ${message.from}`}
                {!!message.verified && ` • ${message.verified}`}
                {!!message.stamped && ` • ${message.stamped}`}
              </Box>
            </Section>
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

/** Подтверждение сообщения картой или печатью. */
const Authentication = () => {
  const { act, data } = useBackend<RequestsConsoleData>();
  return (
    <Section
      title="Авторизация сообщения"
      buttons={<BackButton />}>
      <Box mb={1} color="label">
        Сообщение для <b>{data.recipient}</b> ({priorityName(data.priority)}):
      </Box>
      <Section fitted>
        <Box preserveWhitespace>{data.message}</Box>
      </Section>
      <NoticeBox info mt={1}>
        Вы можете подтвердить подлинность сообщения, приложив карту или печать.
      </NoticeBox>
      <Box mt={1}>
        Утверждено:{' '}
        {data.verified ? <Box inline color="good">{data.verified}</Box> : <i>не прошло утверждение</i>}
      </Box>
      <Box mt={0.5}>
        Печать выставлена:{' '}
        {data.stamped ? <Box inline color="good">{data.stamped}</Box> : <i>не проставлена</i>}
      </Box>
      <Button.Confirm
        mt={1}
        icon="paper-plane"
        color="good"
        content="Отправить сообщение"
        confirmContent="Отправить сообщение?"
        onClick={() => act('send')}
      />
    </Section>
  );
};

/** Отправка станционного объявления. */
const Announcement = () => {
  const { act, data } = useBackend<RequestsConsoleData>();
  return (
    <Section
      title="Станционное объявление"
      buttons={<BackButton />}>
      <NoticeBox info={!data.announceAuth} success={!!data.announceAuth}>
        {data.announceAuth ? 'Авторизация пройдена' : 'Проведите картой для авторизации'}
      </NoticeBox>
      <Box mt={1} color="label">
        Сообщение:
      </Box>
      <Box mb={1}>{data.message || <i>Отсутствует</i>}</Box>
      <Button
        icon="pen"
        content={data.message ? 'Изменить сообщение' : 'Написать сообщение'}
        onClick={() => act('writeAnnouncement')}
      />
      <Button.Confirm
        mt={1}
        icon="bullhorn"
        color="good"
        content="Сделать объявление"
        confirmContent="Объявить по всей станции?"
        disabled={!data.canAnnounce || !data.message}
        onClick={() => act('sendAnnouncement')}
      />
    </Section>
  );
};

/** Экран результата отправки. */
const Result = () => {
  const { act, data } = useBackend<RequestsConsoleData>();
  const success = data.screen === 6;
  return (
    <Section title={success ? 'Сообщение отправлено' : 'Ошибка'}>
      <NoticeBox success={success} danger={!success}>
        {success ? 'Сообщение успешно отправлено.' : 'Произошла ошибка. Сообщение не отправлено.'}
      </NoticeBox>
      <Button
        mt={1}
        icon="arrow-left"
        content="Продолжить"
        onClick={() => act('navigate', { screen: 0 })}
      />
    </Section>
  );
};

/** Консоль запросов: старое HTML-окно заменено на tgui. */
export const RequestsConsole = () => {
  const { data } = useBackend<RequestsConsoleData>();
  const screen = data.screen || 0;
  return (
    <Window width={560} height={640} title="Консоль запросов">
      <Window.Content scrollable>
        <Section
          title="Консоль запросов"
          buttons={<Box color="label">{data.departmentRu || data.department}</Box>}>
          <Box color="label">
            Отдел: <b>{data.department}</b>
            {!!data.hacked && <span className="color-bad"> • ВЗЛОМАНА</span>}
          </Box>
        </Section>
        {screen === 0 && <MainMenu />}
        {(screen === 1 || screen === 2 || screen === 3) && <DepartmentPicker />}
        {screen === 8 && <MessagesView />}
        {screen === 9 && <Authentication />}
        {screen === 10 && <Announcement />}
        {(screen === 6 || screen === 7) && <Result />}
      </Window.Content>
    </Window>
  );
};

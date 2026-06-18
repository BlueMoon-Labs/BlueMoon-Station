import { Component, createRef } from 'inferno';
import { createSearch } from '../../common/string';
import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Divider,
  Icon,
  Input,
  Modal,
  NoticeBox,
  Section,
  Stack,
  TextArea,
  Tooltip,
} from '../components';
import { NtosWindow } from '../layouts';

export const NtosMessenger = (props, context) => {
  const { data } = useBackend(context);
  const {
    is_silicon,
    remote_silicon,
    saved_chats,
    open_chat,
    messengers,
    sending_virus,
  } = data;

  let content;
  if (remote_silicon) {
    content = <AccessDeniedScreen />;
  } else if (open_chat !== null) {
    const openChat = saved_chats[open_chat];
    const temporaryRecipient = messengers[open_chat];

    if (!openChat && !temporaryRecipient) {
      content = <ContactsScreen />;
    } else {
      content = (
        <ChatScreen
          isSilicon={is_silicon}
          sendingVirus={sending_virus}
          canReply={openChat ? openChat.can_reply : !!temporaryRecipient}
          messages={openChat ? openChat.messages : []}
          recipient={openChat ? openChat.recipient : temporaryRecipient}
          unreads={openChat ? openChat.unread_messages : 0}
          chatRef={openChat ? openChat.ref : null}
          blocked={openChat ? openChat.blocked : false}
        />
      );
    }
  } else {
    content = <ContactsScreen />;
  }

  return (
    <NtosWindow width={600} height={850}>
      <NtosWindow.Content>
        {content}
      </NtosWindow.Content>
    </NtosWindow>
  );
};

const AccessDeniedScreen = (props, context) => {
  return (
    <Stack fill vertical>
      <Stack.Item>
        <Section>
          <Stack vertical textAlign="center">
            <Box bold>
              <Icon name="address-card" />
              {' SpaceMessenger V6.5.3'}
            </Box>
          </Stack>
        </Section>
      </Stack.Item>
      <NoticeBox
        color="white"
        position="relative"
        top="30%"
        fontSize="30px"
        textAlign="center">
        ОШИБКА: СОЕДИНЕНИЕ ОТКЛОНЕНО
      </NoticeBox>
      <Stack vertical position="relative" top="35%" textAlign="left">
        <Section>
          <Box>Сообщение от хоста:</Box>
          <Box>- Удалённый доступ к этому приложению ограничен.</Box>
          <Box>- Обратитесь к администратору за помощью.</Box>
        </Section>
      </Stack>
    </Stack>
  );
};

const ContactsScreen = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    owner,
    alert_silenced,
    alert_able,
    sending_and_receiving,
    saved_chats,
    messengers,
    sort_by_job,
    can_spam,
    is_silicon,
    virus_attach,
    sending_virus,
    ringtone_list = [],
    current_ringtone,
  } = data;

  const [searchUser, setSearchUser] = useLocalState(context, 'searchUser', '');
  const [showRingtone, setShowRingtone] = useLocalState(context, 'showRingtone', false);

  const sortByUnreads = (array) =>
    [...array].sort((a, b) => b.unread_messages - a.unread_messages);

  const searchChatByName = createSearch(
    searchUser,
    (chat) => chat.recipient.name + chat.recipient.job,
  );
  const searchMessengerByName = createSearch(
    searchUser,
    (messenger) => messenger.name + messenger.job,
  );

  const chatToButton = (chat) => (
    <ChatButton
      key={chat.ref}
      name={`${chat.recipient.name} (${chat.recipient.job})`}
      chatRef={chat.ref}
      unreads={chat.unread_messages}
      blocked={chat.blocked}
    />
  );

  const messengerToButton = (messenger) => (
    <ChatButton
      key={messenger.ref}
      name={`${messenger.name} (${messenger.job})`}
      chatRef={messenger.ref}
      unreads={0}
    />
  );

  const openChatsArray = sortByUnreads(
    Object.values(saved_chats || {}),
  ).filter(searchChatByName);

  const filteredChatButtons = openChatsArray
    .filter((c) => c.visible)
    .map(chatToButton);

  const messengerButtons = Object.entries(messengers || {})
    .filter(
      ([ref, messenger]) =>
        openChatsArray.filter(c => c.visible).every((chat) => chat.recipient.ref !== ref)
        && searchMessengerByName(messenger),
    )
    .map(([_, messenger]) => messenger)
    .map(messengerToButton)
    .concat(
      openChatsArray.filter((chat) => !chat.visible).map(chatToButton),
    );

  return (
    <>
    <Stack fill vertical>
      <Stack.Item>
        <Section>
          <Stack vertical textAlign="center">
            <Box bold>
              <Icon name="address-card" mr={1} />
              SpaceMessenger V6.5.3
            </Box>
            <Box italic opacity={0.3} mt={1}>
              Шпионо-независимые коммуникации с 2467 года.
            </Box>
            <Divider hidden />
            <Box>
              <Button
                icon="bell"
                disabled={!alert_able}
                content={
                  alert_able && !alert_silenced ? 'Звонок: Вкл' : 'Звонок: Выкл'
                }
                onClick={() => act('PDA_toggleAlerts')}
              />
              <Button
                icon="address-card"
                content={
                  sending_and_receiving
                    ? 'Отправка / Приём: Вкл'
                    : 'Отправка / Приём: Выкл'
                }
                onClick={() => act('PDA_toggleSendingAndReceiving')}
              />
              <Button
                icon="bell"
                content={`Рингтон: ${current_ringtone || 'бип'}`}
                onClick={() => setShowRingtone(!showRingtone)}
              />
              <Button
                icon="sort"
                content={`Сортировка: ${sort_by_job ? 'Должность' : 'Имя'}`}
                onClick={() => act('PDA_changeSortStyle')}
              />
              {!!virus_attach && (
                <Button
                  icon="bug"
                  color="bad"
                  content={`Прикрепить вирус: ${sending_virus ? 'Да' : 'Нет'}`}
                  onClick={() => act('PDA_toggleVirus')}
                />
              )}
            </Box>
          </Stack>
          <Divider hidden />
          <Stack justify="space-between">
            <Box m={0.5}>
              <Icon name="magnifying-glass" mr={1} />
              Поиск пользователя
            </Box>
            <Input
              width="220px"
              placeholder="Поиск по имени или должности..."
              value={searchUser}
              onInput={(e, val) => setSearchUser(val)}
            />
          </Stack>
        </Section>
      </Stack.Item>
      {filteredChatButtons.length > 0 && (
        <Stack.Item grow={1}>
          <Stack vertical fill>
            <Section>
              <Icon name="comments" mr={1} />
              Предыдущие сообщения
            </Section>
            <Section fill scrollable>
              <Stack vertical>{filteredChatButtons}</Stack>
            </Section>
          </Stack>
        </Stack.Item>
      )}
      <Stack.Item grow={2}>
        <Stack vertical fill>
          <Section>
            <Stack>
              <Box m={0.5}>
                <Icon name="address-card" mr={1} />
                Обнаруженные мессенджеры
              </Box>
            </Stack>
          </Section>
          <Section fill scrollable>
            <Stack vertical pb={1} fill>
              {messengerButtons.length === 0 && (
                <Stack align="center" justify="center" fill pl={4}>
                  <Icon color="gray" name="user-slash" size={2} />
                  <Stack.Item fontSize={1.5} ml={3}>
                    Пользователи не найдены.
                  </Stack.Item>
                </Stack>
              )}
              {messengerButtons}
            </Stack>
          </Section>
        </Stack>
      </Stack.Item>
      {!!can_spam && (
        <Stack.Item>
          <SendToAllSection />
        </Stack.Item>
      )}
      </Stack>
      {showRingtone && (
        <Box style={{
          position: 'fixed',
          top: '120px',
          left: '10px',
          zIndex: 9999,
          background: '#1a1a1a',
          border: '1px solid rgba(255,255,255,0.3)',
          borderRadius: '4px',
          padding: '4px',
          maxHeight: '200px',
          overflowY: 'auto',
          minWidth: '140px',
        }}>
          {ringtone_list.map((ringtone) => (
            <Button
              key={ringtone}
              fluid
              color="transparent"
              content={ringtone}
              selected={ringtone === current_ringtone}
              onClick={() => {
                act('PDA_ringSetPreset', { ringtone: ringtone });
                setShowRingtone(false);
              }}
            />
          ))}
          <Divider />
          <Button
            fluid
            color="transparent"
            icon="edit"
            content="Свой..."
            onClick={() => {
              act('PDA_ringSet');
              setShowRingtone(false);
            }}
          />
        </Box>
      )}
    </>
  );
};

const ChatButton = (props, context) => {
  const { act } = useBackend(context);
  const { unreads, chatRef, name, blocked } = props;
  const hasUnreads = unreads > 0;
  return (
    <Button
      icon={blocked ? 'lock' : (hasUnreads && 'envelope')}
      color={blocked ? 'red' : undefined}
      key={chatRef}
      fluid
      onClick={() => act('PDA_viewMessages', { ref: chatRef })}>
      {hasUnreads && !blocked
        && `[${unreads <= 9 ? unreads : '9+'} непрочитанных]`}{' '}
      {blocked ? `[ЗАБЛОКИРОВАН] ` : ''}{name}
    </Button>
  );
};

const SendToAllSection = (props, context) => {
  const { data, act } = useBackend(context);
  const { on_spam_cooldown, has_scanned_photo, admin_photo_url } = data;

  const [message, setMessage] = useLocalState(context, 'spamMessage', '');

  return (
    <>
      <Section>
        <Stack justify="space-between">
          <Stack.Item align="center">
            <Icon name="satellite-dish" mr={1} ml={0.5} />
            Отправить всем
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="arrow-right"
              disabled={on_spam_cooldown || (message === '' && !has_scanned_photo && !admin_photo_url)}
              tooltip={on_spam_cooldown && 'Подождите перед отправкой новых сообщений!'}
              onClick={() => {
                act('PDA_sendEveryone', { message: message });
                setMessage('');
              }}>
              Отправить
            </Button>
          </Stack.Item>
        </Stack>
      </Section>
      <Section>
        <TextArea
          height={6}
          value={message}
          placeholder="Отправить сообщение всем..."
          onInput={(e, val) => setMessage(val)}
        />
      </Section>
    </>
  );
};

const ChatScreen = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    canReply,
    messages,
    recipient,
    chatRef,
    sendingVirus,
    unreads,
    blocked,
  } = props;

  const { emoji_list, emoji_base64, has_scanned_photo, selected_photo_path, admin_photo_url, can_set_url_photo } = data;
  const rawList = Array.isArray(emoji_list) ? emoji_list : Object.values(emoji_list || {});
  const uniqueEmojis = [...new Set(rawList)].slice(0, 100);
  const base64Map = emoji_base64 || {};

  const [message, setMessage] = useLocalState(context, 'chatMessage', '');
  const [canSend, setCanSend] = useLocalState(context, 'canSend', true);
  const [showEmoji, setShowEmoji] = useLocalState(context, 'showEmoji', false);
  const [showAdminUrl, setShowAdminUrl] = useLocalState(context, 'showAdminUrl', false);
  const [adminUrlInput, setAdminUrlInput] = useLocalState(context, 'adminUrlInput', '');
  const [previewUrl, setPreviewUrl] = useLocalState(context, 'previewUrl', null);

  const handleSendMessage = () => {
    if (message === '' && !has_scanned_photo && !admin_photo_url) {
      return;
    }
    const ref = chatRef || recipient.ref;
    act('PDA_sendMessage', {
      ref: ref,
      message: message,
    });
    setMessage('');
    setCanSend(false);
    setTimeout(() => setCanSend(true), 1000);
  };

  const handleEmojiClick = (emoji) => {
    setMessage(message + ' :' + emoji + ': ');
    setShowEmoji(false);
  };

  const filteredMessages = [];
  for (let index = 0; index < messages.length; index++) {
    const msg = messages[index];
    const isSwitch = !(
      index === 0 || messages[index - 1].outgoing === msg.outgoing
    );

    if (index === messages.length - unreads) {
      filteredMessages.push(
        <Box className="UnreadDivider" m={0} mt={isSwitch ? 3 : 1}>
          <div />
          <span>Непрочитанные сообщения</span>
          <div />
        </Box>,
      );
    }

    filteredMessages.push(
      <Stack.Item key={index} mt={isSwitch ? 3 : 1}>
        <ChatMessage
          outgoing={msg.outgoing}
          message={msg.message}
          everyone={msg.everyone}
          timestamp={msg.timestamp}
          photoPath={msg.photo_path}
          onPreview={setPreviewUrl}
        />
      </Stack.Item>,
    );
  }

  let sendingBar;

  if (!canReply) {
    sendingBar = (
      <Section fill>
        <Box width="100%" italic color="gray" ml={1}>
          Вы не можете ответить этому пользователю.
        </Box>
      </Section>
    );
  } else if (blocked) {
    sendingBar = (
      <Section fill>
        <Box width="100%" italic color="red" ml={1}>
          Пользователь заблокирован. Сообщения от него игнорируются.
        </Box>
      </Section>
    );
  } else {
    const buttons = (
      <>
        {!!sendingVirus && (
          <Stack.Item>
            <Button
              tooltip="ОШИБКА: Подпись файла не подтверждена."
              icon="triangle-exclamation"
              color="red"
            />
          </Stack.Item>
        )}
        <Stack.Item>
          <Button
            tooltip="Эмодзи"
            icon="smile"
            onClick={() => setShowEmoji(!showEmoji)}
          />
        </Stack.Item>
        {!!has_scanned_photo && (
          <Stack.Item>
            <Button
              tooltip="Фото прикреплено к следующему сообщению"
              icon="camera"
              color="green"
              disabled
            />
          </Stack.Item>
        )}
        {!!can_set_url_photo && (
          <Stack.Item>
            <Button
              tooltip="Установить URL фото"
              icon="globe"
              color="blue"
              onClick={() => setShowAdminUrl(!showAdminUrl)}
            />
          </Stack.Item>
        )}
        <Stack.Item>
          <Button
            tooltip="Отправить"
            icon="arrow-right"
            onClick={handleSendMessage}
            disabled={!canSend}
          />
        </Stack.Item>
      </>
    );

    sendingBar = (
      <Section fill>
        <Stack vertical fill>
          <Stack fill align="center">
            <Stack.Item grow>
              <Input
                placeholder={`Отправить сообщение ${recipient.name}...`}
                fluid
                autoFocus
                value={message}
                maxLength={1024}
                onInput={(e, val) => setMessage(val)}
                onEnter={handleSendMessage}
                selfClear
              />
            </Stack.Item>
            {buttons}
          </Stack>
          {!!showAdminUrl && (
            <Stack mt={1} fill align="center">
              <Stack.Item grow>
                <Input
                  placeholder="Введите URL изображения..."
                  fluid
                  value={adminUrlInput}
                  onInput={(e, val) => setAdminUrlInput(val)}
                  onEnter={() => {
                    act('PDA_setAdminPhoto', { url: adminUrlInput });
                    setShowAdminUrl(false);
                    setAdminUrlInput('');
                  }}
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  content="Установить"
                  color="green"
                  onClick={() => {
                    act('PDA_setAdminPhoto', { url: adminUrlInput });
                    setShowAdminUrl(false);
                    setAdminUrlInput('');
                  }}
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  content="Очистить"
                  color="red"
                  onClick={() => {
                    act('PDA_clearAdminPhoto');
                    setShowAdminUrl(false);
                    setAdminUrlInput('');
                  }}
                />
              </Stack.Item>
            </Stack>
          )}
          {!!admin_photo_url && (
            <Box mt={1}>
              <MediaAttachment src={admin_photo_url} maxHeight="320px" maxWidth="320px" onClick={() => setPreviewUrl(admin_photo_url)} />
              <Box fontSize={0.8} color="blue">
                URL фото: {admin_photo_url}
              </Box>
            </Box>
          )}
        </Stack>
      </Section>
    );
  }

  return (
    <>
    <Stack vertical fill>
      <Section>
        <Button
          icon="arrow-left"
          content="Назад"
          onClick={() => act('PDA_viewMessages', { ref: null })}
        />
        {chatRef && (
          <>
            <Button
              icon="box-archive"
              content="Закрыть чат"
              onClick={() => act('PDA_closeMessages', { ref: chatRef })}
            />
            <Button.Confirm
              icon="trash-can"
              content="Удалить чат"
              onClick={() => act('PDA_clearMessages', { ref: chatRef })}
            />
            <Button
              icon={blocked ? 'unlock' : 'lock'}
              content={blocked ? 'Разблокировать' : 'Заблокировать'}
              color={blocked ? 'green' : 'red'}
              onClick={() => act('PDA_toggleBlock', { ref: chatRef })}
            />
          </>
        )}
      </Section>

      <Stack.Item grow={1}>
        <Section
          scrollable
          fill
          fitted
          title={`${blocked ? '[ЗАБЛОКИРОВАН] ' : ''}${recipient.name} (${recipient.job})`}>
          <Stack vertical className="NtosChatLog">
            {!!(messages.length > 0 && canReply) && (
              <>
                <Stack.Item textAlign="center" fontSize={1}>
                  Начало чата с {recipient.name}.
                </Stack.Item>
                <Stack.Divider />
              </>
            )}
            {filteredMessages}
            <AutoScrollToBottom triggerKey={messages.length} />
          </Stack>
        </Section>
      </Stack.Item>

      <Stack.Item>{sendingBar}</Stack.Item>
    </Stack>
    {showEmoji && (() => {
        const EMOJIS_PER_ROW = 15;
        const rows = [];
        for (let i = 0; i < uniqueEmojis.length; i += EMOJIS_PER_ROW) {
          rows.push(uniqueEmojis.slice(i, i + EMOJIS_PER_ROW));
        }
        return (
          <Box style={{
            position: 'fixed',
            bottom: '50px',
            left: '10px',
            zIndex: 9999,
            background: '#1a1a1a',
            border: '1px solid rgba(255,255,255,0.3)',
            borderRadius: '4px',
            padding: '4px',
            maxHeight: '180px',
            overflowY: 'auto',
          }}>
            {rows.map((row, rowIdx) => (
              <Stack key={rowIdx} mb={0.5}>
                {row.map((emoji) => {
                  const b64 = base64Map[emoji];
                  return (
                    <Stack.Item key={emoji}>
                      <Button
                        color="transparent"
                        tooltip={emoji}
                        style={{
                          padding: '1px 3px',
                          fontSize: '11px',
                          minWidth: '28px',
                          width: '28px',
                          height: '28px',
                          textAlign: 'center',
                        }}
                        onClick={() => handleEmojiClick(emoji)}>
                        {b64 ? (
                          <img
                            src={'data:image/png;base64,' + b64}
                            alt={':' + emoji + ':'}
                            style={{ width: '16px', height: '16px', verticalAlign: 'middle' }}
                          />
                        ) : (
                          ':' + emoji + ':'
                        )}
                      </Button>
                    </Stack.Item>
                  );
                })}
              </Stack>
            ))}
          </Box>
        );
      })()}
      {!!previewUrl && (
        <Modal>
          <Stack vertical align="center">
            <Stack.Item>
              <MediaAttachment src={previewUrl} maxHeight="80vh" maxWidth="575px" />
            </Stack.Item>
            <Stack.Item>
              <Button content="Закрыть" onClick={() => setPreviewUrl(null)} />
            </Stack.Item>
          </Stack>
        </Modal>
      )}
    </>
  );
};

const MediaAttachment = ({ src, maxHeight = '200px', maxWidth = '100%', onClick }) => {
  if (!src) return null;

  const isVideo = /\.(webm|mp4)(\?.*)?$/i.test(src) || src.startsWith('data:video/');

  if (isVideo) {
    const videoType = src.startsWith('data:')
      ? (src.match(/^data:([^;,]+)/)?.[1] || 'video/webm')
      : (/\.mp4(\?.*)?$/i.test(src) ? 'video/mp4' : 'video/webm');
    return (
      <Box>
        <video
          controls
          preload="metadata"
          crossOrigin="anonymous"
          playsInline
          style={{
            maxWidth,
            maxHeight,
            width: 'auto',
            height: 'auto',
            objectFit: 'contain',
            display: 'block',
            marginTop: '5px',
          }}
        >
          <source src={src} type={videoType} />
        </video>
        {!!onClick && (
          <Button
            mt={1}
            icon="external-link-alt"
            content="Открыть видео"
            color="blue"
            onClick={onClick}
          />
        )}
      </Box>
    );
  }

  return (
    <img
      src={src}
      alt="Прикреплённое изображение"
      style={{
        maxWidth,
        maxHeight,
        width: 'auto',
        height: 'auto',
        objectFit: 'contain',
        cursor: onClick ? 'pointer' : 'default',
        display: 'block',
        marginTop: '5px',
      }}
      title={onClick ? 'Кликните для открытия полного изображения' : undefined}
      onClick={onClick}
    />
  );
};

class AutoScrollToBottom extends Component {
  constructor(props) {
    super(props);
    this.ref = createRef();
    this.atBottom = true;
    this.handleScroll = this.handleScroll.bind(this);
  }

  handleScroll(e) {
    const el = e.currentTarget;
    const threshold = 50;
    this.atBottom = el.scrollTop + el.clientHeight >= el.scrollHeight - threshold;
  }

  componentDidMount() {
    const content = this.ref.current?.parentElement?.closest('.Section__content');
    if (content) {
      content.addEventListener('scroll', this.handleScroll);
      content.scrollTop = content.scrollHeight;
    }
  }

  componentWillUnmount() {
    const content = this.ref.current?.parentElement?.closest('.Section__content');
    if (content) {
      content.removeEventListener('scroll', this.handleScroll);
    }
  }

  componentDidUpdate(prevProps) {
    if (this.props.triggerKey !== prevProps.triggerKey && this.atBottom) {
      const content = this.ref.current?.parentElement?.closest('.Section__content');
      if (content) {
        content.scrollTop = content.scrollHeight;
      }
    }
  }

  render() {
    return <div ref={this.ref} />;
  }
}

const ChatMessage = (props) => {
  const { message, everyone, outgoing, timestamp, photoPath, onPreview } = props;

  return (
    <Box className={`NtosChatMessage${outgoing ? '_outgoing' : ''}`}>
      <Box className="NtosChatMessage__content">
        <Box as="span" dangerouslySetInnerHTML={{ __html: message }} />
        <Tooltip content={timestamp} position={outgoing ? 'left' : 'right'}>
          <Icon
            className="NtosChatMessage__timestamp"
            name="clock-o"
            size={0.8}
          />
        </Tooltip>
      </Box>
      {!!photoPath && (
        <Box className="NtosChatMessage__photo">
          <MediaAttachment src={photoPath} maxHeight="320px" maxWidth="320px" onClick={() => onPreview && onPreview(photoPath)} />
        </Box>
      )}
      {!!everyone && (
        <Box className="NtosChatMessage__everyone">Отправлено всем</Box>
      )}
    </Box>
  );
};

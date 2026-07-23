import { Component, createRef, useState } from 'react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  Flex,
  Icon,
  Input,
  NoticeBox,
  Section,
  Stack,
  Tabs,
} from '../components';
import { Window } from '../layouts';

const STATE_COLORS = {
  1: '#f87171',
  2: '#94a3b8',
  3: '#4ade80',
};

const STATE_LABELS = {
  1: 'Открыт',
  2: 'Закрыт',
  3: 'Решён',
};

export const PlayerTicketPanel = (props) => {
  const { act, data } = useBackend();
  const {
    has_ticket = false,
    ticket = null,
    has_mentor_ticket = false,
    mentor_ticket = null,
  } = data;

  const [tab, setTab] = useState(1);

  return (
    <Window
      title="Обращение в администрацию"
      width={650}
      height={500}
      resizable
    >
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Tabs fluid>
              <Tabs.Tab
                selected={tab === 1}
                color="red"
                icon="exclamation-triangle"
                onClick={() => setTab(1)}
              >
                Администрация
              </Tabs.Tab>
              <Tabs.Tab
                selected={tab === 2}
                color="purple"
                icon="question-circle"
                onClick={() => setTab(2)}
              >
                Менторы
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item grow>
            {tab === 1 ? (
              has_ticket ? (
                <TicketChatPanel key="admin-chat" ticket={ticket} act={act} />
              ) : (
                <NewTicketPanel key="admin-new" act={act} type="admin" />
              )
            ) : (
              has_mentor_ticket ? (
                <TicketChatPanel key="mentor-chat" ticket={mentor_ticket} act={act} type="mentor" />
              ) : (
                <NewTicketPanel key="mentor-new" act={act} type="mentor" />
              )
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const NewTicketPanel = (props) => {
  const { act, type } = props;
  const [message, setMessage] = useState('');

  const isAdmin = type === 'admin';

  const sendTicket = () => {
    const msg = message.trim();
    if (!msg) return;
    act('create_ticket', { message: msg, type: type });
    setMessage('');
  };

  return (
    <Stack vertical fill>
      <Stack.Item grow>
        <Section
          title={isAdmin ? 'Создать обращение' : 'Спросить ментора'}
          fill
          scrollable
        >
          <Box fontSize="13px" color="#cbd5e1" mb={2}>
            {isAdmin
              ? 'Опишите вашу проблему подробно. Укажите имена причастных игроков.'
              : 'Опишите ваш вопрос подробно. Менторы помогут с игровыми механиками.'}
          </Box>
          <Input
            fluid
            multiline
            rows={6}
            placeholder={
              isAdmin
                ? 'Опишите проблему...'
                : 'Задайте вопрос...'
            }
            value={message}
            onInput={(e, val) => setMessage(val)}
            onEnter={sendTicket}
          />
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section>
          <Flex justify="space-between" align="center">
            <Flex.Item>
              <Button
                icon="paper-plane"
                color="blue"
                disabled={!message.trim()}
                onClick={sendTicket}
              >
                {isAdmin ? 'Отправить обращение' : 'Спросить ментора'}
              </Button>
            </Flex.Item>
            <Flex.Item>
              <Button
                icon="sync"
                onClick={() => act('refresh')}
              >
                Обновить
              </Button>
            </Flex.Item>
          </Flex>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const TicketChatPanel = (props) => {
  const { ticket, act, type } = props;
  const isActive = ticket.state === 1;
  const color = STATE_COLORS[ticket.state] || '#94a3b8';
  const [replyMessage, setReplyMessage] = useState('');
  const [lastTypingPing, setLastTypingPing] = useState(0);

  const typingAdmins = (ticket.typing_admins || []).filter(Boolean);

  const pingTyping = () => {
    const now = Date.now();
    if (now - lastTypingPing > 2000) {
      act('typing_start', { ref: ticket.ref, type: type || 'admin' });
      setLastTypingPing(now);
    }
  };

  const stopTyping = () => {
    act('typing_stop', { ref: ticket.ref, type: type || 'admin' });
    setLastTypingPing(0);
  };

  const sendReply = () => {
    const message = replyMessage.trim();
    if (!message) return;
    stopTyping();
    act('send_message', { message, ref: ticket.ref, type: type || 'admin' });
    setReplyMessage('');
  };

  const handleTypingInput = (e, value) => {
    setReplyMessage(value);
    if (value) {
      pingTyping();
    } else {
      stopTyping();
    }
  };

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Section
          title={
            <Flex align="center" justify="space-between" width="100%">
              <Flex.Item>
                <Icon name={isActive ? 'exclamation-triangle' : (ticket.state === 3 ? 'check-circle' : 'times-circle')} color={color} mr={1} />
                Тикет #{ticket.id}
              </Flex.Item>
              <Flex.Item shrink={0}>
                <Button icon="sync" tooltip="Обновить" mr={0.5} onClick={() => act('refresh')} />
              </Flex.Item>
            </Flex>
          }
        >
          <Flex align="center" justify="space-between" mb={1}>
            <Flex.Item>
              <Box
                fontSize="14px"
                bold
                color="white"
                px={1}
                py={0.3}
                style={{
                  backgroundColor: 'rgba(255,255,255,0.08)',
                  borderRadius: '4px',
                }}
              >
                {ticket.name}
              </Box>
            </Flex.Item>
            <Flex.Item shrink={0}>
              <Box
                fontSize="12px"
                px={1.5}
                py={0.4}
                style={{
                  backgroundColor: color,
                  color: '#fff',
                  borderRadius: '4px',
                  fontWeight: 'bold',
                }}
              >
                {STATE_LABELS[ticket.state]}
              </Box>
            </Flex.Item>
          </Flex>
          <Flex fontSize="12px" color="gray" wrap="wrap">
            <Flex.Item mr={3}>
              <b>Взял:</b>{' '}
              {ticket.handler ? (
                <Box as="span" color="#ffcc00" fontWeight="bold">
                  {ticket.handler}
                </Box>
              ) : (
                <Box as="span" color="#666">
                  Ожидание
                </Box>
              )}
            </Flex.Item>
            <Flex.Item mr={3}>
              <b>Открыт:</b> {ticket.opened_at_text || '—'}
            </Flex.Item>
            {ticket.close_reason && (
              <Flex.Item>
                <b>Причина:</b> {ticket.close_reason}
              </Flex.Item>
            )}
          </Flex>
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Section
          title="Переписка"
          fill
          scrollable
          buttons={
            <Box fontSize="10px" color="gray">
              {ticket.interactions?.length || 0} сообщ.
            </Box>
          }
        >
          {(!ticket.interactions || ticket.interactions.length === 0) && (
            <NoticeBox info>Нет сообщений. Ожидайте ответа.</NoticeBox>
          )}
          {(ticket.interactions || []).map((msg, idx) => (
            <Box
              key={idx}
              py={0.5}
              px={1}
              mb={0.3}
              fontSize="12px"
              style={{
                backgroundColor:
                  idx % 2 === 0 ? 'rgba(255,255,255,0.03)' : 'transparent',
                borderRadius: '3px',
                wordBreak: 'break-word',
              }}
              dangerouslySetInnerHTML={{ __html: msg }}
            />
          ))}
          <AutoScrollToBottom triggerKey={(ticket.interactions || []).length} />
        </Section>
      </Stack.Item>
      {isActive && (
        <Stack.Item>
          {(typingAdmins.length > 0) && (
            <Box fontSize="11px" color="#ffcc00" textAlign="left" py={0.5} style={{ fontWeight: 'bold' }}>
              <Icon name="pencil-alt" mr={0.5} />
              {typingAdmins.join(', ')} {(typingAdmins.length === 1 ? 'печатает' : 'печатают')}...
            </Box>
          )}
          <Section title="Написать сообщение">
            <Flex>
              <Flex.Item grow>
                <Input
                  fluid
                  placeholder="Введите сообщение..."
                  value={replyMessage}
                  onInput={handleTypingInput}
                  onEnter={sendReply}
                />
              </Flex.Item>
              <Flex.Item ml={1}>
                <Button
                  icon="paper-plane"
                  color="blue"
                  disabled={!replyMessage.trim()}
                  onClick={sendReply}
                >
                  Отправить
                </Button>
              </Flex.Item>
            </Flex>
          </Section>
        </Stack.Item>
      )}
    </Stack>
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

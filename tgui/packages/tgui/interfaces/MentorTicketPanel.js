import { Component, createRef, useState } from 'react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  Divider,
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
  1: '#a855f7',
  2: '#94a3b8',
  3: '#4ade80',
};

const STATE_LABELS = {
  1: 'Открыт',
  2: 'Закрыт',
  3: 'Решён',
};

export const MentorTicketPanel = (props) => {
  const { act, data } = useBackend();
  const {
    tickets = [],
    selected_ticket_ref,
    active_count = 0,
    closed_count = 0,
    resolved_count = 0,
    selected_state = 1,
  } = data;

  const [tab, setTab] = useState(selected_state);
  const selectedTicket = tickets.find((t) => t.ref === selected_ticket_ref);
  const filteredTickets = tickets.filter((t) => t.state === tab);

  return (
    <Window
      title="Ментор-тикеты"
      width={900}
      height={600}
      theme="admin"
      resizable
    >
      <Window.Content>
        <Flex height="100%">
          <Flex.Item width="230px" shrink={0}>
            <Stack vertical fill>
              <Stack.Item>
                <Section fitted>
                  <Tabs fluid>
                    <Tabs.Tab
                      selected={tab === 1}
                      color="purple"
                      icon="question-circle"
                      rightSlot={
                        active_count > 0 ? '(' + active_count + ')' : null
                      }
                      onClick={() => setTab(1)}
                    >
                      Актив.
                    </Tabs.Tab>
                    <Tabs.Tab
                      selected={tab === 2}
                      icon="times-circle"
                      rightSlot={
                        closed_count > 0 ? '(' + closed_count + ')' : null
                      }
                      onClick={() => setTab(2)}
                    >
                      Закр.
                    </Tabs.Tab>
                    <Tabs.Tab
                      selected={tab === 3}
                      color="green"
                      icon="check-circle"
                      rightSlot={
                        resolved_count > 0 ? '(' + resolved_count + ')' : null
                      }
                      onClick={() => setTab(3)}
                    >
                      Реш.
                    </Tabs.Tab>
                  </Tabs>
                </Section>
              </Stack.Item>
              <Stack.Item grow>
                <Section
                  title="Ментор-тикеты"
                  fill
                  scrollable
                  buttons={
                    <Button
                      icon="sync"
                      tooltip="Обновить"
                      onClick={() => act('refresh')}
                    />
                  }
                >
                  {filteredTickets.length === 0 && (
                    <NoticeBox info>Нет тикетов в этой категории.</NoticeBox>
                  )}
                  {filteredTickets.map((ticket) => (
                    <TicketListItem
                      key={ticket.ref}
                      ticket={ticket}
                      selected={ticket.ref === selected_ticket_ref}
                      onSelect={() => {
                        setTab(ticket.state);
                        act('select_ticket', { ref: ticket.ref });
                      }}
                    />
                  ))}
                </Section>
              </Stack.Item>
            </Stack>
          </Flex.Item>
          <Flex.Item mr={1}>
            <Divider vertical />
          </Flex.Item>
          <Flex.Item grow={1} basis={0}>
            {!selectedTicket ? (
              <Flex
                height="100%"
                align="center"
                justify="center"
                direction="column"
              >
                <Icon name="question-circle" size={4} color="gray" mb={2} />
                <Box color="gray" fontSize="16px">
                  Выберите ментор-тикет из списка слева
                </Box>
              </Flex>
            ) : (
              <TicketDetailPanel key={selectedTicket.ref} ticket={selectedTicket} act={act} data={data} />
            )}
          </Flex.Item>
        </Flex>
      </Window.Content>
    </Window>
  );
};

const TicketListItem = (props) => {
  const { ticket, selected, onSelect } = props;
  const color = STATE_COLORS[ticket.state] || '#94a3b8';
  const listTypingAdmins = (ticket.typing_admins || []).filter(Boolean);
  const hasListInitiatorTyping = !!ticket.initiator_typing;

  return (
    <Button
      fluid
      selected={selected}
      onClick={onSelect}
      mb={0.5}
      style={{
        textAlign: 'left',
        padding: '6px 8px',
        justifyContent: 'flex-start',
        borderLeft: selected
          ? '3px solid ' + color
          : '3px solid transparent',
      }}
    >
      <Flex align="center" justify="space-between">
        <Flex.Item grow={1} mr={1}>
          <Box
            bold
            fontSize="12px"
            style={{
              overflow: 'hidden',
              textOverflow: 'ellipsis',
              whiteSpace: 'nowrap',
            }}
          >
            #{ticket.id} — {ticket.initiator_key_name}
          </Box>
          <Box
            fontSize="10px"
            color="#cbd5e1"
            style={{
              overflow: 'hidden',
              textOverflow: 'ellipsis',
              whiteSpace: 'nowrap',
            }}
          >
            {ticket.name}
          </Box>
          {(listTypingAdmins.length > 0 || !!hasListInitiatorTyping) && (
            <Box
              fontSize="10px"
              color="#ffcc00"
              style={{
                overflow: 'hidden',
                textOverflow: 'ellipsis',
                whiteSpace: 'nowrap',
              }}
            >
              ✎ {listTypingAdmins.concat(
                hasListInitiatorTyping
                  ? [ticket.initiator_ckey || 'игрок']
                  : []
              ).join(', ')} {(listTypingAdmins.length + (hasListInitiatorTyping ? 1 : 0)) === 1 ? 'печатает' : 'печатают'}...
            </Box>
          )}
        </Flex.Item>
        <Flex.Item shrink={0}>
          <Box
            fontSize="9px"
            px={0.8}
            py={0.2}
            style={{
              backgroundColor: color,
              color: '#fff',
              borderRadius: '3px',
              fontWeight: 'bold',
            }}
          >
            {STATE_LABELS[ticket.state]}
          </Box>
        </Flex.Item>
      </Flex>
    </Button>
  );
};

const TicketDetailPanel = (props) => {
  const { ticket, act, data } = props;
  const [replyMessage, setReplyMessage] = useState('');
  const [lastTypingPing, setLastTypingPing] = useState(0);
  const isActive = ticket.state === 1;
  const color = STATE_COLORS[ticket.state] || '#94a3b8';

  const typingAdmins = (ticket.typing_admins || []).filter(Boolean);

  const pingTyping = () => {
    const now = Date.now();
    if (now - lastTypingPing > 2000) {
      act('typing_start');
      setLastTypingPing(now);
    }
  };

  const stopTyping = () => {
    act('typing_stop');
    setLastTypingPing(0);
  };

  const sendReply = () => {
    const message = replyMessage.trim();
    if (!message) return;
    stopTyping();
    act('send_reply', { message });
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
                <Icon
                  name={isActive ? 'question-circle' : (ticket.state === 3 ? 'check-circle' : 'times-circle')}
                  color={color}
                  mr={1}
                />
                Ментор-тикет #{ticket.id}
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
                fontSize="16px"
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
              <b>Игрок:</b> {ticket.initiator_key_name}
              {!ticket.has_initiator && (
                <Box as="span" color="red" ml={1}>
                  (ОТКЛЮЧЁН)
                </Box>
              )}
            </Flex.Item>
            <Flex.Item mr={3}>
              <b>Взят:</b>{' '}
              {ticket.handler ? (
                <Box as="span" color="#ffcc00" fontWeight="bold">
                  {ticket.handler}
                </Box>
              ) : (
                <Box as="span" color="#666">
                  Не взят
                </Box>
              )}
            </Flex.Item>
            <Flex.Item mr={3}>
              <b>Открыт:</b> {ticket.opened_at_text || '—'}
            </Flex.Item>
            {ticket.closed_at && (
              <Flex.Item mr={3}>
                <b>Закрыт:</b> {ticket.closed_at_text || '—'}
              </Flex.Item>
            )}
            {ticket.close_reason && (
              <Flex.Item>
                <b>Причина:</b> {ticket.close_reason}
              </Flex.Item>
            )}
          </Flex>
        </Section>
      </Stack.Item>
      {isActive && (
        <Stack.Item>
          <Section title="Действия">
            <Flex wrap="wrap" align="center">
              <Button icon="check-circle" color="green" mr={0.5} onClick={() => act('resolve')}>
                Решить
              </Button>
              <Button icon="times" color="red" mr={0.5} onClick={() => act('close')}>
                Закрыть
              </Button>
            </Flex>
          </Section>
        </Stack.Item>
      )}
      {!isActive && (
        <Stack.Item>
          <Section title="Действия">
            <Button icon="undo" color="purple" onClick={() => act('reopen')}>
              Переоткрыть
            </Button>
          </Section>
        </Stack.Item>
      )}
      <Stack.Item grow>
        <Section
          title="Чат-лог"
          fill
          scrollable
          buttons={
            <Flex align="center">
              <Icon name="sync" color={data.time ? 'green' : 'gray'} mr={1} opacity={data.time ? 1 : 0.3} />
              <Button icon="sync" tooltip="Обновить" onClick={() => act('refresh')} />
            </Flex>
          }
        >
          {(!ticket.interactions || ticket.interactions.length === 0) && (
            <NoticeBox info>Нет сообщений.</NoticeBox>
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
          {(typingAdmins.length > 0 || !!ticket.initiator_typing) && (
            <Box fontSize="11px" color="#ffcc00" textAlign="left" py={0.5} style={{ fontWeight: 'bold' }}>
              <Icon name="pencil-alt" mr={0.5} />
              {typingAdmins.concat(
                ticket.initiator_typing
                  ? [ticket.initiator_ckey || 'игрок']
                  : []
              ).join(', ')}{' '}
              {(typingAdmins.length + (ticket.initiator_typing ? 1 : 0)) === 1
                ? 'печатает'
                : 'печатают'}...
            </Box>
          )}
          <Section title={'Ответить ' + (ticket.initiator_ckey || 'ckey')}>
            <Flex>
              <Flex.Item grow>
                <Input
                  fluid
                  disabled={!ticket.has_initiator}
                  placeholder={
                    ticket.has_initiator
                      ? 'Введите сообщение...'
                      : 'Игрок отключён, ответ невозможен'
                  }
                  value={replyMessage}
                  onInput={handleTypingInput}
                  onEnter={sendReply}
                />
              </Flex.Item>
              <Flex.Item ml={1}>
                <Button
                  icon="paper-plane"
                  color="blue"
                  disabled={!ticket.has_initiator || !replyMessage.trim()}
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

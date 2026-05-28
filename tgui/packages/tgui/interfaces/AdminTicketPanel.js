import { useBackend, useLocalState } from '../backend';
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
  1: '#f87171',
  2: '#94a3b8',
  3: '#4ade80',
};

const STATE_LABELS = {
  1: 'Открыт',
  2: 'Закрыт',
  3: 'Решён',
};

const STATE_ICONS = {
  1: 'exclamation-triangle',
  2: 'times-circle',
  3: 'check-circle',
};

export const AdminTicketPanel = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    tickets = [],
    selected_ticket_ref,
    active_count = 0,
    closed_count = 0,
    resolved_count = 0,
    selected_state = 1,
  } = data;

  const [tab, setTab] = useLocalState(context, 'tab', selected_state);

  const selectedTicket = tickets.find((t) => t.ref === selected_ticket_ref);

  const filteredTickets = tickets.filter((t) => t.state === tab);

  return (
    <Window
      title="Admin Ticket Panel"
      width={1100}
      height={700}
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
                      color="red"
                      icon="exclamation-triangle"
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
                  title="Тикеты"
                  fill
                  scrollable
                  buttons={
                    <Flex align="center">
                      <Button
                        icon="sync"
                        tooltip="Обновить"
                        onClick={() => act('refresh')}
                      />
                    </Flex>
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
            {!selectedTicket && (
              <Flex
                height="100%"
                align="center"
                justify="center"
                direction="column"
              >
                <Icon name="ticket-alt" size={4} color="gray" mb={2} />
                <Box color="gray" fontSize="16px">
                  Выберите тикет из списка слева
                </Box>
              </Flex>
            )}
            {selectedTicket && (
              <TicketDetailPanel ticket={selectedTicket} act={act} />
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

  return (
    <Box
      className={'Button Button--fluid' + (selected ? ' Button--selected' : '')}
      onClick={onSelect}
      mb={0.5}
      style={{
        textAlign: 'left',
        padding: '6px 8px',
        cursor: 'pointer',
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
    </Box>
  );
};

const TicketDetailPanel = (props, context) => {
  const { ticket, act } = props;
  const [replyMessage, setReplyMessage] = useLocalState(
    context,
    'replyMessage',
    ''
  );
  const isActive = ticket.state === 1;
  const color = STATE_COLORS[ticket.state] || '#94a3b8';
  const canReply = isActive && ticket.has_initiator;

  const sendReply = () => {
    const message = replyMessage.trim();
    if (!message || !canReply) {
      return;
    }
    act('send_reply', { message });
    setReplyMessage('');
  };

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Section
  title={
    <Flex align="center" justify="space-between" width="100%">
      <Flex.Item>
        <Icon
          name={STATE_ICONS[ticket.state]}
          color={color}
          mr={1}
        />
        Тикет #{ticket.id}
      </Flex.Item>
      <Flex.Item shrink={0}>
        <Button
          icon="sync"
          tooltip="Обновить"
          mr={0.5}
          onClick={() => act('refresh')}
        />
        <Button
          icon="pen"
          tooltip="Переименовать"
          onClick={() => act('retitle')}
        />
        {!isActive && (
          <Button
            icon="door-open"
            tooltip="Переоткрыть"
            color="violet"
            onClick={() => act('reopen')}
          />
        )}
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
            {ticket.handler && (
              <Flex.Item mr={3}>
                <b>Взят:</b> {ticket.handler}
              </Flex.Item>
            )}
            <Flex.Item mr={3}>
              <b>Открыт:</b> {ticket.opened_at_text || '—'}{' '}
              <Box as="span" color="label">
                ({ticket.opened_ago_text || '—'} назад)
              </Box>
            </Flex.Item>
            {ticket.closed_at && (
              <Flex.Item mr={3}>
                <b>Закрыт:</b> {ticket.closed_at_text || '—'}{' '}
                <Box as="span" color="label">
                  ({ticket.closed_ago_text || '—'} назад)
                </Box>
              </Flex.Item>
            )}
            {ticket.close_reason && (
              <Flex.Item>
                <b>Причина закрытия:</b> {ticket.close_reason}
              </Flex.Item>
            )}
          </Flex>
        </Section>
      </Stack.Item>

      {isActive && (
        <Stack.Item>
          <Section title="Действия">
            <Flex wrap="wrap" align="center">
              <Flex.Item mr={1} mb={0.5}>
                <Flex wrap="wrap">
                  <Button
                    icon="reply"
                    color="blue"
                    mr={0.5}
                    mb={0.5}
                    onClick={() => act('reply')}
                  >
                    Открыть окно ответа
                  </Button>
                  <Button
                    icon="hand-paper"
                    color="violet"
                    mr={0.5}
                    mb={0.5}
                    onClick={() => act('handle_issue')}
                  >
                    Взять тикет
                  </Button>
                  <Button
                    icon="user"
                    mr={0.5}
                    mb={0.5}
                    onClick={() => act('player_panel')}
                  >
                    Панель игрока
                  </Button>
                  <Button
                    icon="eye"
                    color="teal"
                    mr={0.5}
                    mb={0.5}
                    disabled={!ticket.has_initiator}
                    onClick={() => act('follow')}
                  >
                    FLW
                  </Button>
                  <Button
                    icon="clipboard-list"
                    mr={0.5}
                    mb={0.5}
                    disabled={!ticket.has_initiator}
                    onClick={() => act('logs')}
                  >
                    Логи
                  </Button>
                  <Button
                    icon="gavel"
                    color="red"
                    mr={0.5}
                    mb={0.5}
                    onClick={() => act('ban_panel')}
                  >
                    Баны
                  </Button>
                </Flex>
              </Flex.Item>
              <Flex.Item mr={1} mb={0.5}>
                <Flex wrap="wrap">
                  <Button
                    icon="check-circle"
                    color="green"
                    mr={0.5}
                    mb={0.5}
                    onClick={() => act('resolve')}
                  >
                    Решить
                  </Button>
                  <Button
                    icon="times"
                    color="red"
                    mr={0.5}
                    mb={0.5}
                    onClick={() => act('close')}
                  >
                    Закрыть
                  </Button>
                  <Button
                    icon="ban"
                    color="red"
                    mb={0.5}
                    onClick={() => act('reject')}
                  >
                    Отклонить
                  </Button>
                </Flex>
              </Flex.Item>
              <Flex.Item mr={1} mb={0.5}>
                <Flex wrap="wrap">
                  <Button
                    icon="dice-d6"
                    mr={0.5}
                    mb={0.5}
                    onClick={() => act('icissue')}
                  >
                    IC Issue
                  </Button>
                  <Button
                    icon="skull"
                    color="orange"
                    mb={0.5}
                    onClick={() => act('skillissue')}
                  >
                    Skill Issue
                  </Button>
                </Flex>
              </Flex.Item>
              <Flex.Item mb={0.5}>
                <Button
                  icon={ticket.ticket_ping_stop ? 'bell-slash' : 'bell'}
                  color={ticket.ticket_ping_stop ? 'bad' : 'default'}
                  mb={0.5}
                  onClick={() => act('pingmute')}
                >
                  {ticket.ticket_ping_stop ? 'Пинги выкл' : 'Пинги вкл'}
                </Button>
              </Flex.Item>
            </Flex>
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
              <Button
                icon="sync"
                tooltip="Обновить"
                onClick={() => act('refresh')}
              />
            </Flex>
          }>
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
        </Section>
      </Stack.Item>
      {isActive && (
        <Stack.Item>
          <Section title={'Ответить ' + (ticket.initiator_ckey || 'ckey')}>
            <Flex>
              <Flex.Item grow>
                <Input
                  fluid
                  disabled={!canReply}
                  placeholder={
                    canReply
                      ? 'Введите сообщение...'
                      : 'Игрок отключён, ответ невозможен'
                  }
                  value={replyMessage}
                  onInput={(e, value) => setReplyMessage(value)}
                  onEnter={sendReply}
                />
              </Flex.Item>
              <Flex.Item ml={1}>
                <Button
                  icon="paper-plane"
                  color="blue"
                  disabled={!canReply || !replyMessage.trim()}
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

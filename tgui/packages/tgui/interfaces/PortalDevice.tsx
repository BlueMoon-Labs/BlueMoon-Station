import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Collapsible,
  Icon,
  LabeledList,
  NoticeBox,
  Section,
  Slider,
  Stack,
  Tabs,
} from '../components';
import { Window } from '../layouts';

type ConnectedDevice = {
  ref: string;
  name: string;
  mood_color: string;
  mood_text: string;
};

type NetworkMember = {
  nickname: string;
  mood_color: string;
  mood_text: string;
  is_owner: boolean;
};

type AvailableNetwork = {
  name: string;
  has_password: boolean;
  ref: string;
};

type PortalDeviceData = {
  device_type: 'panties' | 'fleshlight';
  device_name: string;
  is_owner: boolean;
  is_passive_mode?: boolean;
  connection_mode: string;
  telecomms_available: boolean;
  connected_count?: number;
  connected_devices?: ConnectedDevice[];
  connected?: boolean;
  connected_name?: string;
  has_private_pair: boolean;
  partner_mood_color?: string;
  partner_mood_text?: string;
  partner_vibration_enabled?: boolean;
  partner_vibration_intensity?: number;
  partner_vibration_pattern?: string;
  partner_control_mode?: string;
  partner_intensity_locked?: boolean;
  vibration_enabled: boolean;
  vibration_pattern: string;
  vibration_intensity: number;
  relay_intensity: number;
  mood: string;
  mood_color: string;
  mood_text: string;
  do_not_disturb: boolean;
  public_emotes_enabled: boolean;
  edging_enabled: boolean;
  owner_nickname?: string;
  safeword: string;
  safeword_enabled: boolean;
  seamless_locked?: boolean;
  blocked_nicknames: string[];
  allowed_nicknames: string[];
  connection_history: ConnectionHistoryEntry[];
  available_patterns: PatternInfo[];
  available_panties?: PantyInfo[];
  control_mode: string;
  intensity_locked: boolean;
  max_allowed_intensity: number;
  min_forced_intensity: number;
  quick_messages: string[];
  in_network: boolean;
  network_name: string;
  network_members: NetworkMember[];
  is_network_owner: boolean;
  available_networks: AvailableNetwork[];
  relay_vibrations: boolean;
  relay_edging: boolean;
  relay_climax: boolean;
  // Multiple connections support
  active_vibrations?: ActiveVibration[];
  has_remote_vibration?: boolean;
  effective_intensity?: number;
  effective_pattern?: string;
  public_privacy_mode?: string;
  target_connected_count?: number;
  target_connected_names?: string[] | null;
  our_remote_vibration_active?: boolean;
};

type ConnectionHistoryEntry = {
  time_text?: string;
  partner: string;
  action: string;
};

type PatternInfo = {
  id: string;
  name: string;
  desc?: string;
  icon?: string;
};

type PantyInfo = {
  name: string;
  ref: string;
};

type ActiveVibration = {
  ref: string;
  nickname: string;
  intensity: number;
  pattern: string;
};

type TabProps = {
  data: PortalDeviceData;
  act: (action: string, params?: object) => void;
};

// Control mode labels
const CONTROL_MODE_LABELS = {
  self: 'Самоконтроль',
  partner: 'Подчинение',
};

const CONTROL_MODE_ICONS = {
  self: 'user',
  partner: 'lock',
};

// Connection mode configuration
const CONNECTION_MODES: Record<string, { label: string; icon: string; desc: string; color: string }> = {
  public: { label: 'Публичный', icon: 'globe', desc: 'Любой может подключиться', color: 'green' },
  private: { label: 'Приватный', icon: 'user-lock', desc: 'Только выбранный партнёр', color: 'blue' },
  group: { label: 'Групповой', icon: 'users', desc: 'Только участники сети', color: 'purple' },
  disabled: { label: 'Закрыт', icon: 'ban', desc: 'Подключения запрещены', color: 'red' },
};

// Reusable component for connected devices list
const ConnectedDevicesList = (props: {
  devices: ConnectedDevice[];
  act: (action: string, params?: object) => void;
  showDisconnectAll?: boolean;
}) => {
  const { devices, act, showDisconnectAll = true } = props;

  if (!devices || devices.length === 0) {
    return <NoticeBox>Нет подключённых устройств</NoticeBox>;
  }

  return (
    <Stack vertical>
      <Stack.Item>
        <Box bold mb={1}>
          <Icon name="link" mr={1} color="good" />
          Подключено: {devices.length}
        </Box>
      </Stack.Item>
      {devices.map((device) => (
        <Stack.Item key={device.ref}>
          <Stack align="center">
            <Stack.Item>
              <Icon name="circle" size={0.8} color={device.mood_color} />
            </Stack.Item>
            <Stack.Item grow ml={1}>
              <Box inline bold>
                {device.name}
              </Box>
              <Box inline color="label" fontSize={0.9} ml={1}>
                ({device.mood_text})
              </Box>
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="times"
                color="red"
                tooltip="Отключить"
                onClick={() => act('disconnect_one', { ref: device.ref })}
              />
            </Stack.Item>
          </Stack>
        </Stack.Item>
      ))}
      {showDisconnectAll && devices.length > 1 && (
        <Stack.Item mt={1}>
          <Button icon="unlink" color="red" onClick={() => act('disconnect_all')}>
            Отключить всех
          </Button>
        </Stack.Item>
      )}
    </Stack>
  );
};

// Reusable component for quick messages
const QuickMessagesSection = (props: {
  messages: string[];
  act: (action: string, params?: object) => void;
  isConnected: boolean;
  editable?: boolean;
  telecommsAvailable?: boolean;
}) => {
  const { messages, act, isConnected, editable = false, telecommsAvailable = true } = props;

  if (!messages || messages.length === 0) {
    return null;
  }

  // Group messages into rows of 4
  const rows: string[][] = [];
  for (let i = 0; i < messages.length; i += 4) {
    rows.push(messages.slice(i, i + 4));
  }

  return (
    <Collapsible title="Быстрые сообщения" mt={1}>
      <Stack vertical>
        {rows.map((row, rowIdx) => (
          <Stack.Item key={rowIdx}>
            <Stack>
              {row.map((msg, i) => {
                const globalIdx = rowIdx * 4 + i;
                return (
                  <Stack.Item key={globalIdx}>
                    <Button
                      onClick={() => act('send_quick_message', { index: globalIdx + 1 })}
                      disabled={!isConnected || !telecommsAvailable}
                      tooltip={editable ? 'ПКМ для редактирования' : !telecommsAvailable ? 'Нет связи с сервером' : undefined}
                      onContextMenu={
                        editable
                          ? (e: Event) => {
                            e.preventDefault();
                            act('edit_quick_message', { index: globalIdx + 1 });
                          }
                          : undefined
                      }
                    >
                      {msg}
                    </Button>
                  </Stack.Item>
                );
              })}
            </Stack>
          </Stack.Item>
        ))}
      </Stack>
    </Collapsible>
  );
};

// Status Tab Content (Passive Mode for Panties)
const StatusTabContent = (props: TabProps) => {
  const { data, act } = props;
  const { connected_devices, vibration_enabled, vibration_intensity, vibration_pattern, available_patterns, quick_messages, telecomms_available, active_vibrations, has_remote_vibration, effective_intensity, effective_pattern, connected_count } = data;
  const isConnected = (connected_count || 0) > 0;

  // Use effective intensity from remote sources if available, otherwise local
  const displayIntensity = has_remote_vibration && effective_intensity ? effective_intensity : vibration_intensity;
  const displayPattern = has_remote_vibration && effective_pattern ? effective_pattern : vibration_pattern;
  const isVibrationActive = vibration_enabled || (has_remote_vibration && effective_intensity && effective_intensity > 0);

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Section title="Подключение">
          <ConnectedDevicesList devices={connected_devices || []} act={act} />
        </Section>
      </Stack.Item>

      <Stack.Item mt={1}>
        <Section title="Вибрация (управляется партнёром)">
          {(!has_remote_vibration || !active_vibrations || active_vibrations.length === 0) ? (
            <NoticeBox>
              <Icon name="plug" mr={1} />
              Нет подключения
            </NoticeBox>
          ) : (
            <>
              <LabeledList>
                <LabeledList.Item label="Статус">
                  <Icon
                    name={isVibrationActive ? 'play' : 'stop'}
                    color={isVibrationActive ? 'good' : 'grey'}
                    mr={1}
                  />
                  {isVibrationActive ? 'Активна' : 'Выключена'}
                </LabeledList.Item>
                <LabeledList.Item label="Интенсивность">
                  <Box inline>
                    {displayIntensity}/10
                    <Box
                      inline
                      ml={1}
                      style={{
                        width: '100px',
                        height: '8px',
                        background: '#333',
                        borderRadius: '4px',
                        display: 'inline-block',
                        verticalAlign: 'middle',
                      }}
                    >
                      <Box
                        style={{
                          width: `${displayIntensity * 10}%`,
                          height: '100%',
                          background:
                            displayIntensity >= 7
                              ? '#ff4444'
                              : displayIntensity >= 4
                                ? '#ffaa44'
                                : '#44ff44',
                          borderRadius: '4px',
                        }}
                      />
                    </Box>
                  </Box>
                </LabeledList.Item>
                <LabeledList.Item label="Режим">
                  {available_patterns.find((p) => p.id === displayPattern)?.name || displayPattern}
                </LabeledList.Item>
                <LabeledList.Item label="Источники">
                  {active_vibrations.length} устройств
                </LabeledList.Item>
              </LabeledList>
              <Collapsible title={`Кто управляет (${active_vibrations.length})`} mt={1}>
                {active_vibrations.map((v) => (
                  <Box key={v.ref} py={0.5}>
                    <Icon name="user" mr={1} />
                    <Box inline bold>{v.nickname || 'Неизвестно'}</Box>
                    <Box inline color="label" ml={1}>
                      {v.intensity ?? 0}/10
                    </Box>
                  </Box>
                ))}
              </Collapsible>
            </>
          )}
        </Section>
      </Stack.Item>

      <Stack.Item mt={1}>
        <Section title="Общение">
          {!telecomms_available && (
            <NoticeBox danger mb={1}>
              <Icon name="exclamation-triangle" mr={1} />
              Нет связи с сервером связи
            </NoticeBox>
          )}
          <Stack>
            <Stack.Item grow>
              <Button fluid icon="comment" onClick={() => act('send_whisper')} disabled={!isConnected || !telecomms_available}>
                Шёпот
              </Button>
            </Stack.Item>
            <Stack.Item grow>
              <Button fluid icon="heart" color="pink" onClick={() => act('send_emote')}>
                Эмоут
              </Button>
            </Stack.Item>
          </Stack>
          <QuickMessagesSection messages={quick_messages} act={act} isConnected={isConnected} telecommsAvailable={telecomms_available} />
        </Section>
      </Stack.Item>
    </Stack>
  );
};

// Control Tab Content
const ControlTabContent = (props: TabProps) => {
  const { data, act } = props;
  const {
    device_type,
    connection_mode,
    in_network,
    connected_devices,
    connected,
    connected_name,
    connected_count,
    partner_mood_color,
    partner_mood_text,
    available_panties,
    quick_messages,
    control_mode,
    intensity_locked,
    connection_history,
    telecomms_available,
  } = data;
  const isPanties = device_type === 'panties';
  const isConnected = isPanties ? (connected_count || 0) > 0 : !!connected;

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Section title="Режим доступа">
          {isPanties ? (
            <Stack vertical>
              {Object.entries(CONNECTION_MODES).map(([mode, info]) => (
                <Stack.Item key={mode}>
                  <Button
                    fluid
                    icon={info.icon}
                    color={connection_mode === mode ? info.color : 'grey'}
                    selected={connection_mode === mode}
                    onClick={() => act('set_connection_mode', { mode })}
                    disabled={mode === 'group' && !in_network}
                  >
                    {info.label}
                    {mode === 'group' && !in_network && ' (нужна сеть)'}
                  </Button>
                  <Box color="label" fontSize={0.85} ml={2} mb={0.5}>
                    {info.desc}
                  </Box>
                </Stack.Item>
              ))}
              {connection_mode === 'public' && (
                <Stack.Item mt={1}>
                  <Box bold mb={0.5}>Приватность для подключённых:</Box>
                  <Stack>
                    <Stack.Item grow>
                      <Button
                        fluid
                        icon="eye-slash"
                        selected={data.public_privacy_mode === 'count_only'}
                        onClick={() => act('set_privacy_mode', { mode: 'count_only' })}
                      >
                        Только количество
                      </Button>
                    </Stack.Item>
                    <Stack.Item grow>
                      <Button
                        fluid
                        icon="eye"
                        selected={data.public_privacy_mode === 'show_names'}
                        onClick={() => act('set_privacy_mode', { mode: 'show_names' })}
                      >
                        Показывать ники
                      </Button>
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
              )}
              {connected_devices && connected_devices.length > 0 && (
                <Stack.Item mt={1}>
                  <Box bold mb={1}>
                    <Icon name="link" mr={1} color="good" />
                    Подключено: {connected_devices.length}
                    {connected_devices.length > 1 && (
                      <Button icon="unlink" color="red" ml={1} onClick={() => act('disconnect_all')}>
                        Отключить всех
                      </Button>
                    )}
                  </Box>
                  <Stack vertical>
                    {connected_devices.map((device) => (
                      <Stack.Item key={device.ref}>
                        <Stack align="center">
                          <Stack.Item>
                            <Icon name="circle" size={0.8} color={device.mood_color} />
                          </Stack.Item>
                          <Stack.Item grow ml={1}>
                            <Box inline bold>
                              {device.name}
                            </Box>
                            <Box inline color="label" fontSize={0.9} ml={1}>
                              ({device.mood_text})
                            </Box>
                          </Stack.Item>
                          <Stack.Item>
                            <Button
                              icon="times"
                              color="red"
                              tooltip="Отключить"
                              onClick={() => act('disconnect_one', { ref: device.ref })}
                            />
                          </Stack.Item>
                        </Stack>
                      </Stack.Item>
                    ))}
                  </Stack>
                </Stack.Item>
              )}
            </Stack>
          ) : (
            <Box>
              {connected ? (
                <Stack align="center">
                  <Stack.Item grow>
                    <NoticeBox info>
                      <Stack align="center">
                        <Stack.Item>
                          <Icon name="circle" color={partner_mood_color} mr={1} />
                        </Stack.Item>
                        <Stack.Item grow>
                          <Box bold>{connected_name}</Box>
                          <Box color="label" fontSize={0.9}>
                            {partner_mood_text}
                          </Box>
                        </Stack.Item>
                      </Stack>
                    </NoticeBox>
                  </Stack.Item>
                  <Stack.Item>
                    <Button icon="unlink" color="red" onClick={() => act('disconnect')} />
                  </Stack.Item>
                </Stack>
              ) : available_panties && available_panties.length > 0 ? (
                <Stack vertical>
                  {available_panties.map((p) => (
                    <Stack.Item key={p.ref}>
                      <Button fluid icon="link" color="green" onClick={() => act('connect', { ref: p.ref })}>
                        {p.name}
                      </Button>
                    </Stack.Item>
                  ))}
                </Stack>
              ) : (
                <NoticeBox>Нет доступных устройств</NoticeBox>
              )}
            </Box>
          )}
        </Section>
      </Stack.Item>

      <Stack.Item mt={1}>
        <Section title="Общение">
          {!telecomms_available && (
            <NoticeBox danger mb={1}>
              <Icon name="exclamation-triangle" mr={1} />
              Нет связи с сервером связи
            </NoticeBox>
          )}
          {!isConnected && (
            <NoticeBox info mb={1}>
              Сначала соедините устройства (используйте фонарик на трусиках)
            </NoticeBox>
          )}
          <Stack>
            <Stack.Item grow>
              <Button fluid icon="comment" onClick={() => act('send_whisper')} disabled={!isConnected || !telecomms_available}>
                Шёпот
              </Button>
            </Stack.Item>
            <Stack.Item grow>
              <Button fluid icon="heart" color="pink" onClick={() => act('send_emote')}>
                Эмоут
              </Button>
            </Stack.Item>
          </Stack>
          <QuickMessagesSection messages={quick_messages} act={act} isConnected={isConnected} editable telecommsAvailable={telecomms_available} />
        </Section>
      </Stack.Item>

      {isPanties && (
        <Stack.Item mt={1}>
          <Section title="Режим управления">
            <Stack>
              {Object.entries(CONTROL_MODE_LABELS).map(([mode, label]) => (
                <Stack.Item key={mode} grow>
                  <Button
                    fluid
                    icon={CONTROL_MODE_ICONS[mode as keyof typeof CONTROL_MODE_ICONS]}
                    selected={control_mode === mode}
                    onClick={() => act('set_control_mode', { mode })}
                  >
                    {label}
                  </Button>
                </Stack.Item>
              ))}
            </Stack>
            {control_mode === 'partner' && (
              <Box mt={1}>
                <Button
                  icon={intensity_locked ? 'lock' : 'unlock'}
                  color={intensity_locked ? 'red' : 'grey'}
                  onClick={() => act('toggle_intensity_lock')}
                >
                  {intensity_locked ? 'Интенсивность заблокирована' : 'Заблокировать интенсивность'}
                </Button>
              </Box>
            )}
          </Section>
        </Stack.Item>
      )}

      {connection_history.length > 0 && (
        <Stack.Item mt={1}>
          <Section title="История">
            <Collapsible title={`Последние ${connection_history.length} событий`}>
              {connection_history.map((entry, i) => (
                <Box key={i} color="label" py={0.5}>
                  {entry.time_text && (
                    <Box as="span" color="average" mr={1}>
                      [{entry.time_text}]
                    </Box>
                  )}
                  <Box as="span" color="good">
                    {entry.partner}
                  </Box>
                  : {entry.action}
                </Box>
              ))}
            </Collapsible>
          </Section>
        </Stack.Item>
      )}
    </Stack>
  );
};

// Remote Control Tab (Fleshlight only)
const RemoteTabContent = (props: TabProps) => {
  const { data, act } = props;
  const {
    connected,
    connected_name,
    partner_mood_color,
    partner_mood_text,
    partner_vibration_enabled,
    partner_control_mode,
    partner_intensity_locked,
    available_patterns,
    available_panties,
    quick_messages,
    telecomms_available,
    // Use fleshlight's own settings for the slider (what we're sending), not partner's
    vibration_intensity,
    vibration_pattern,
  } = data;
  const isConnected = !!connected;

  if (!isConnected) {
    return (
      <Stack vertical fill>
        <Stack.Item>
          <NoticeBox>Подключитесь к устройству, чтобы управлять партнёром</NoticeBox>
          {available_panties && available_panties.length > 0 && (
            <Section title="Доступные устройства" mt={1}>
              <Stack vertical>
                {available_panties.map((p) => (
                  <Stack.Item key={p.ref}>
                    <Button fluid icon="link" color="green" onClick={() => act('connect', { ref: p.ref })}>
                      {p.name}
                    </Button>
                  </Stack.Item>
                ))}
              </Stack>
            </Section>
          )}
        </Stack.Item>
      </Stack>
    );
  }

  const canRemoteControl = partner_control_mode === 'partner';

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Section title={connected_name || 'Партнёр'}>
          <Stack align="center" mb={1}>
            <Stack.Item>
              <Icon name="circle" size={1.2} color={partner_mood_color} mr={1} />
            </Stack.Item>
            <Stack.Item>
              <Box bold>{connected_name}</Box>
            </Stack.Item>
          </Stack>
          <Box color="label" mb={1}>
            {partner_mood_text}
          </Box>

          {partner_control_mode === 'self' && (
            <NoticeBox warning mb={1}>
              <Icon name="ban" mr={1} />
              Партнёр в режиме самоконтроля - удалённое управление ограничено
            </NoticeBox>
          )}

          {data.target_connected_count !== undefined && data.target_connected_count > 1 && (
            <Box mt={1} mb={1} color="label" fontSize={0.9}>
              <Icon name="users" mr={1} />
              Всего подключено: {data.target_connected_count}
              {data.target_connected_names && data.target_connected_names.length > 1 && (
                <Box mt={0.5}>
                  Также: {data.target_connected_names.filter((n) => n !== connected_name).join(', ')}
                </Box>
              )}
            </Box>
          )}

          <Button
            fluid
            icon={data.our_remote_vibration_active ? 'stop' : 'play'}
            color={data.our_remote_vibration_active ? 'red' : 'purple'}
            fontSize={1.2}
            onClick={() => act('remote_vibrate')}
            disabled={!canRemoteControl}
          >
            {data.our_remote_vibration_active ? 'Остановить вибрацию' : 'Включить вибрацию'}
          </Button>
        </Section>
      </Stack.Item>

      <Stack.Item mt={1}>
        <Section title="Настройки удалённой вибрации">
          <LabeledList>
            <LabeledList.Item label="Интенсивность">
              <Slider
                value={vibration_intensity || 5}
                minValue={1}
                maxValue={10}
                step={1}
                stepPixelSize={20}
                disabled={!canRemoteControl || partner_intensity_locked}
                onChange={(_, value: number) => act('set_remote_intensity', { intensity: value })}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Режим">
              <Box>
                {available_patterns.map((p) => (
                  <Button
                    key={p.id}
                    icon={p.icon}
                    selected={vibration_pattern === p.id}
                    tooltip={p.desc}
                    disabled={!canRemoteControl}
                    onClick={() => act('set_remote_pattern', { pattern: p.id })}
                  >
                    {p.name}
                  </Button>
                ))}
              </Box>
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>

      <Stack.Item mt={1}>
        <Section title="Быстрые действия">
          {!telecomms_available && (
            <NoticeBox danger mb={1}>
              <Icon name="exclamation-triangle" mr={1} />
              Нет связи с сервером связи
            </NoticeBox>
          )}
          <Stack>
            <Stack.Item grow>
              <Button fluid icon="comment" onClick={() => act('send_whisper')} disabled={!telecomms_available}>
                Шёпот
              </Button>
            </Stack.Item>
            <Stack.Item grow>
              <Button fluid icon="heart" color="pink" onClick={() => act('send_emote')}>
                Эмоут
              </Button>
            </Stack.Item>
          </Stack>
          {quick_messages && quick_messages.length > 0 && (
            <Box mt={1}>
              {quick_messages.slice(0, 4).map((msg, i) => (
                <Button key={i} onClick={() => act('send_quick_message', { index: i + 1 })} disabled={!telecomms_available}>{msg}</Button>
              ))}
            </Box>
          )}
        </Section>
      </Stack.Item>
    </Stack>
  );
};

// Vibration Tab (Panties only)
const VibrationTabContent = (props: TabProps) => {
  const { data, act } = props;
  const { vibration_enabled, vibration_intensity, vibration_pattern, available_patterns, public_emotes_enabled, edging_enabled } = data;

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Section
          title="Локальная вибрация"
          buttons={
            <Button
              icon={vibration_enabled ? 'stop' : 'play'}
              color={vibration_enabled ? 'red' : 'green'}
              onClick={() => act('toggle_vibration')}
            >
              {vibration_enabled ? 'Стоп' : 'Старт'}
            </Button>
          }
        >
          <LabeledList>
            <LabeledList.Item label="Интенсивность">
              <Slider
                value={vibration_intensity}
                minValue={1}
                maxValue={10}
                step={1}
                stepPixelSize={20}
                onChange={(_, value: number) => act('set_intensity', { intensity: value })}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Режим">
              <Box>
                {available_patterns.map((p) => (
                  <Button
                    key={p.id}
                    icon={p.icon}
                    selected={vibration_pattern === p.id}
                    tooltip={p.desc}
                    onClick={() => act('set_pattern', { pattern: p.id })}
                  >
                    {p.name}
                  </Button>
                ))}
              </Box>
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>

      <Stack.Item mt={1}>
        <Section title="Ролевые настройки">
          <Stack vertical>
            <Stack.Item>
              <Button
                fluid
                icon={public_emotes_enabled ? 'eye' : 'eye-slash'}
                color={public_emotes_enabled ? 'green' : 'grey'}
                onClick={() => act('toggle_public_emotes')}
                tooltip="При высокой интенсивности показывает эмоции окружающим"
              >
                {public_emotes_enabled ? 'Публичные эмоуты: ВКЛ' : 'Публичные эмоуты: ВЫКЛ'}
              </Button>
            </Stack.Item>
            <Stack.Item mt={1}>
              <Button
                fluid
                icon={edging_enabled ? 'hand-paper' : 'hand-rock'}
                color={edging_enabled ? 'purple' : 'grey'}
                onClick={() => act('toggle_edging')}
                tooltip="Автоматически снижает интенсивность при приближении к оргазму"
              >
                {edging_enabled ? 'Режим эджинга: ВКЛ' : 'Режим эджинга: ВЫКЛ'}
              </Button>
            </Stack.Item>
          </Stack>
          <Box mt={1} color="label" fontSize={0.9} italic>
            Публичные эмоуты видны только в радиусе 1 тайла
          </Box>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

// Network Tab
const NetworkTabContent = (props: TabProps) => {
  const { data, act } = props;
  const { in_network, network_name, network_members, available_networks, relay_intensity, relay_vibrations, relay_edging, relay_climax, telecomms_available } = data;

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Section title="Статус сети">
          {in_network ? (
            <Stack align="center" mb={1}>
              <Stack.Item grow>
                <Box bold fontSize={1.2}>
                  <Icon name="wifi" mr={1} color="good" />
                  {network_name}
                </Box>
                <Box color="label" fontSize={0.9}>
                  {network_members?.length || 0} участников подключено
                </Box>
              </Stack.Item>
              <Stack.Item>
                <Button icon="sign-out-alt" color="red" onClick={() => act('leave_network')}>
                  Выйти
                </Button>
              </Stack.Item>
            </Stack>
          ) : (
            <Stack vertical>
              <Stack.Item>
                <NoticeBox info>
                  <Icon name="question-circle" mr={1} />
                  <b>Что такое сеть?</b> Сеть объединяет несколько устройств, позволяя делиться ощущениями между
                  всеми участниками. Вибрация, эджинг и оргазм могут передаваться партнёрам в реальном времени.
                </NoticeBox>
              </Stack.Item>
              <Stack.Item mt={1}>
                <Button fluid icon="plus" color="green" onClick={() => act('create_network')}>
                  Создать сеть
                </Button>
              </Stack.Item>
              {available_networks && available_networks.length > 0 && (
                <Stack.Item mt={1}>
                  <Box bold mb={0.5}>
                    Доступные сети:
                  </Box>
                  {available_networks.map((net) => (
                    <Button
                      key={net.ref}
                      fluid
                      icon={net.has_password ? 'lock' : 'unlock'}
                      onClick={() => act('join_network', { ref: net.ref })}
                      mb={0.5}
                    >
                      {net.name}
                    </Button>
                  ))}
                </Stack.Item>
              )}
            </Stack>
          )}
        </Section>
      </Stack.Item>

      {Boolean(in_network) && (
        <Stack.Item mt={1}>
          <Section title="Передача ощущений">
            <Box color="label" fontSize={0.9} mb={1}>
              Настройте какие ощущения передавать другим участникам сети
            </Box>

            <LabeledList>
              <LabeledList.Item label="Сила передачи">
                <Stack align="center">
                  <Stack.Item grow>
                    <Slider
                      value={relay_intensity}
                      minValue={25}
                      maxValue={100}
                      step={5}
                      stepPixelSize={4}
                      unit="%"
                      onChange={(_, value: number) => act('set_relay_intensity', { relay: value })}
                    />
                  </Stack.Item>
                  <Stack.Item ml={1}>
                    <Icon
                      name="info-circle"
                      color="label"
                      tooltip="Насколько сильно партнёры чувствуют ваши ощущения. 100% = полная сила, 25% = четверть."
                    />
                  </Stack.Item>
                </Stack>
              </LabeledList.Item>
            </LabeledList>

            <Box mt={1} bold mb={0.5}>
              Типы передаваемых ощущений:
            </Box>
            <Stack vertical>
              <Stack.Item>
                <Button
                  fluid
                  icon={relay_vibrations ? 'check-square' : 'square'}
                  color={relay_vibrations ? 'green' : 'grey'}
                  onClick={() => act('toggle_relay_vibrations')}
                >
                  <Icon name="wave-square" mr={1} />
                  Вибрация
                </Button>
                <Box color="label" fontSize={0.85} ml={2}>
                  Передавать ощущения вибрации (интенсивность 5+)
                </Box>
              </Stack.Item>

              <Stack.Item mt={0.5}>
                <Button
                  fluid
                  icon={relay_edging ? 'check-square' : 'square'}
                  color={relay_edging ? 'green' : 'grey'}
                  onClick={() => act('toggle_relay_edging')}
                >
                  <Icon name="hand-paper" mr={1} />
                  Эджинг
                </Button>
                <Box color="label" fontSize={0.85} ml={2}>
                  Уведомлять когда вы близки к оргазму
                </Box>
              </Stack.Item>

              <Stack.Item mt={0.5}>
                <Button
                  fluid
                  icon={relay_climax ? 'check-square' : 'square'}
                  color={relay_climax ? 'green' : 'grey'}
                  onClick={() => act('toggle_relay_climax')}
                >
                  <Icon name="heart" mr={1} />
                  Оргазм
                </Button>
                <Box color="label" fontSize={0.85} ml={2}>
                  Передавать волну удовольствия при оргазме
                </Box>
              </Stack.Item>
            </Stack>
          </Section>
        </Stack.Item>
      )}

      {Boolean(in_network) && network_members && network_members.length > 0 && (
        <Stack.Item mt={1}>
          <Section title={`Участники (${network_members.length})`}>
            <Stack vertical>
              {network_members.map((member, i) => (
                <Stack.Item key={i}>
                  <Stack align="center">
                    <Stack.Item>
                      <Icon name="circle" size={0.8} color={member.mood_color} />
                    </Stack.Item>
                    <Stack.Item grow ml={1}>
                      <Box inline bold>
                        {member.nickname}
                        {!!member.is_owner && <Icon name="crown" color="gold" ml={1} tooltip="Создатель сети" />}
                      </Box>
                      <Box inline color="label" fontSize={0.9} ml={1}>
                        ({member.mood_text})
                      </Box>
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
              ))}
            </Stack>
          </Section>
        </Stack.Item>
      )}

      {Boolean(in_network) && (
        <Stack.Item mt={1}>
          {!telecomms_available && (
            <NoticeBox danger mb={1}>
              <Icon name="exclamation-triangle" mr={1} />
              Нет связи с сервером связи
            </NoticeBox>
          )}
          <Button fluid icon="bullhorn" onClick={() => act('network_broadcast')} disabled={!telecomms_available}>
            Отправить сообщение всей сети
          </Button>
        </Stack.Item>
      )}
    </Stack>
  );
};

// Safety Tab
const SafetyTabContent = (props: TabProps) => {
  const { data, act } = props;
  const {
    safeword,
    safeword_enabled,
    seamless_locked,
    blocked_nicknames,
    allowed_nicknames,
    device_type,
  } = data;

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Section title="Стоп-слово">
          <Stack vertical>
            <Stack.Item>
              <Button
                fluid
                icon={safeword_enabled ? 'check-square' : 'square'}
                color={safeword_enabled ? 'green' : 'grey'}
                onClick={() => act('toggle_safeword_enabled')}
              >
                {safeword_enabled ? 'Стоп-слово включено' : 'Стоп-слово выключено'}
              </Button>
            </Stack.Item>
            <Stack.Item mt={1}>
              <Stack align="center">
                <Stack.Item grow>
                  <Button
                    fluid
                    icon="edit"
                    disabled={!safeword_enabled}
                    onClick={() => act('set_safeword')}
                  >
                    {safeword}
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="exclamation-triangle"
                    color="red"
                    disabled={!safeword_enabled}
                    onClick={() => act('trigger_safeword')}
                  >
                    СТОП
                  </Button>
                </Stack.Item>
              </Stack>
            </Stack.Item>
          </Stack>
          <Box mt={1} color="label" fontSize={0.9} italic>
            Произнесите стоп-слово вслух для экстренного отключения всех соединений
          </Box>
        </Section>
      </Stack.Item>

      {device_type === 'panties' && (
        <Stack.Item mt={1}>
          <Section title="Латексный замок">
            <LabeledList>
              <LabeledList.Item label="Статус">
                {seamless_locked ? (
                  <Box color="bad" bold>
                    <Icon name="lock" mr={1} />
                    Заблокировано
                  </Box>
                ) : (
                  <Box color="good">
                    <Icon name="lock-open" mr={1} />
                    Разблокировано
                  </Box>
                )}
              </LabeledList.Item>
              {Boolean(seamless_locked) && (
                <LabeledList.Item label="Снятие">
                  Используйте стоп-слово или латексный ключ
                </LabeledList.Item>
              )}
            </LabeledList>
          </Section>
        </Stack.Item>
      )}

      <Stack.Item mt={1}>
        <Section title="Блокировка">
          <Box bold mb={1}>
            <Icon name="ban" mr={1} />
            Заблокированные никнеймы:
          </Box>
          {blocked_nicknames.length > 0 ? (
            <Box mb={1}>
              {blocked_nicknames.map((nickname) => (
                <Button key={nickname} icon="times" color="red" onClick={() => act('remove_blocked', { nickname })}>
                  {nickname}
                </Button>
              ))}
            </Box>
          ) : (
            <Box color="label" mb={1}>
              Никто не заблокирован
            </Box>
          )}
          <Button icon="plus" onClick={() => act('add_blocked')}>
            Заблокировать
          </Button>
        </Section>
      </Stack.Item>

      <Stack.Item mt={1}>
        <Section title="Белый список">
          <Box bold mb={1}>
            <Icon name="check" mr={1} />
            Разрешённые никнеймы:
          </Box>
          {allowed_nicknames.length > 0 ? (
            <Box mb={1}>
              {allowed_nicknames.map((nickname) => (
                <Button key={nickname} icon="times" onClick={() => act('remove_allowed', { nickname })}>
                  {nickname}
                </Button>
              ))}
              <Button icon="trash" color="red" onClick={() => act('clear_allowed')}>
                Очистить
              </Button>
            </Box>
          ) : (
            <Box color="label" mb={1}>
              Подключаться могут все
            </Box>
          )}
          <Button icon="plus" onClick={() => act('add_allowed')}>
            Добавить
          </Button>
          <Box mt={1} color="label" fontSize={0.9} italic>
            Используйте портальные никнеймы
          </Box>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

// Main component
export const PortalDevice = (_, context) => {
  const { act, data } = useBackend<PortalDeviceData>(context);
  const {
    device_type,
    device_name,
    mood_color,
    mood_text,
    do_not_disturb,
    connected_count,
    connected,
    vibration_enabled,
    owner_nickname,
    control_mode,
    in_network,
    is_passive_mode,
  } = data;

  const isPanties = device_type === 'panties';
  const isPassiveMode = isPanties && !!is_passive_mode;
  const isConnected = isPanties ? (connected_count || 0) > 0 : !!connected;

  const defaultTab = isPassiveMode ? 'status' : !isPanties && isConnected ? 'remote' : 'control';
  const [activeTab, setActiveTab] = useLocalState(context, 'activeTab', defaultTab);

  const tabProps: TabProps = { data, act };

  return (
    <Window width={420} height={560} title={device_name}>
      <Window.Content>
        <Stack vertical fill>
          {/* Status Header */}
          <Stack.Item>
            <Section>
              <Stack align="center" justify="space-between">
                <Stack.Item>
                  <Stack align="center">
                    <Stack.Item>
                      <Icon
                        name="circle"
                        size={1.5}
                        color={mood_color}
                        style={{
                          animation: vibration_enabled ? 'pulse 0.5s infinite' : undefined,
                        }}
                      />
                    </Stack.Item>
                    <Stack.Item ml={1}>
                      <Box bold>{mood_text}</Box>
                      {!!owner_nickname && (
                        <Box color="label" fontSize={0.9}>
                          {owner_nickname}
                        </Box>
                      )}
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
                <Stack.Item>
                  <Stack>
                    <Stack.Item>
                      <Button icon="edit" tooltip="Изменить портальный никнейм" onClick={() => act('set_device_nickname')} />
                    </Stack.Item>
                    <Stack.Item>
                      <Button
                        icon={do_not_disturb ? 'moon' : 'sun'}
                        color={do_not_disturb ? 'grey' : 'green'}
                        onClick={() => act('toggle_dnd')}
                        tooltip={do_not_disturb ? 'Не беспокоить' : 'Активен'}
                      />
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
              </Stack>
              {isPassiveMode && (
                <NoticeBox info mt={1}>
                  <Icon name="eye" mr={1} />
                  Пассивный режим: снимите для настройки
                </NoticeBox>
              )}
              {control_mode === 'partner' && !isPassiveMode && (
                <NoticeBox warning mt={1}>
                  <Icon name="lock" mr={1} />
                  Режим подчинения: управление у партнёра
                </NoticeBox>
              )}
            </Section>
          </Stack.Item>

          {/* Tab Navigation */}
          <Stack.Item>
            <Tabs>
              {isPassiveMode ? (
                <>
                  <Tabs.Tab selected={activeTab === 'status'} onClick={() => setActiveTab('status')}>
                    <Icon name="info-circle" mr={1} />
                    Статус
                  </Tabs.Tab>
                  <Tabs.Tab selected={activeTab === 'safety'} onClick={() => setActiveTab('safety')}>
                    <Icon name="shield-alt" mr={1} />
                    Безопасность
                  </Tabs.Tab>
                </>
              ) : (
                <>
                  <Tabs.Tab selected={activeTab === 'control'} onClick={() => setActiveTab('control')}>
                    <Icon name="sliders-h" mr={1} />
                    Управление
                  </Tabs.Tab>
                  {!isPanties && (
                    <Tabs.Tab
                      selected={activeTab === 'remote'}
                      onClick={() => setActiveTab('remote')}
                      color={isConnected ? 'pink' : undefined}
                    >
                      <Icon name="satellite-dish" mr={1} />
                      Партнёр
                      {isConnected && <Icon name="circle" size={0.7} color="good" ml={1} />}
                    </Tabs.Tab>
                  )}
                  {isPanties && (
                    <Tabs.Tab selected={activeTab === 'vibration'} onClick={() => setActiveTab('vibration')}>
                      <Icon name="wave-square" mr={1} />
                      Вибро
                    </Tabs.Tab>
                  )}
                  <Tabs.Tab
                    selected={activeTab === 'network'}
                    onClick={() => setActiveTab('network')}
                    color={in_network ? 'green' : undefined}
                  >
                    <Icon name="users" mr={1} />
                    Сеть
                    {!!in_network && <Icon name="circle" size={0.7} color="good" ml={1} />}
                  </Tabs.Tab>
                  <Tabs.Tab selected={activeTab === 'safety'} onClick={() => setActiveTab('safety')}>
                    <Icon name="shield-alt" mr={1} />
                    Безопасность
                  </Tabs.Tab>
                </>
              )}
            </Tabs>
          </Stack.Item>

          {/* Tab Content */}
          <Stack.Item grow basis={0}>
            <Section fill scrollable>
              {activeTab === 'status' && isPassiveMode && <StatusTabContent {...tabProps} />}
              {activeTab === 'control' && !isPassiveMode && <ControlTabContent {...tabProps} />}
              {activeTab === 'remote' && !isPanties && <RemoteTabContent {...tabProps} />}
              {activeTab === 'vibration' && !isPassiveMode && isPanties && <VibrationTabContent {...tabProps} />}
              {activeTab === 'network' && !isPassiveMode && <NetworkTabContent {...tabProps} />}
              {activeTab === 'safety' && <SafetyTabContent {...tabProps} />}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

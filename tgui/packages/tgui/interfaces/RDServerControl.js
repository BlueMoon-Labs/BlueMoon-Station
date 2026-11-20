import { useBackend } from '../backend';
import {
  Box,
  Button,
  Divider,
  Icon,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
} from '../components';
import { Window } from '../layouts';

const STATUSES = {
  online: {
    label: 'ОНЛАЙН',
    icon: 'check-circle',
    tone: 'online',
  },
  no_power: {
    label: 'НЕТ ПИТАНИЯ',
    icon: 'power-off',
    tone: 'offline',
  },
  broken: {
    label: 'СЛОМАН',
    icon: 'times-circle',
    tone: 'offline',
  },
  emp: {
    label: 'ЭМИ',
    icon: 'bolt',
    tone: 'warning',
  },
  overheated: {
    label: 'ПЕРЕГРЕВ',
    icon: 'temperature-high',
    tone: 'offline',
  },
  emagged: {
    label: 'ВЗЛОМАН',
    icon: 'radiation',
    tone: 'warning',
  },
};

const getStatus = (status) => STATUSES[status] || STATUSES.broken;

const StatCard = ({ color, icon, label, value }) => (
  <Stack.Item grow>
    <Box className="RDServerControl__stat">
      <Stack align="center">
        <Stack.Item>
          <Icon name={icon} color={color} size={1.6} />
        </Stack.Item>
        <Stack.Item>
          <Box className="RDServerControl__statLabel">{label}</Box>
          <Box bold className="RDServerControl__statValue" color={color}>
            {value}
          </Box>
        </Stack.Item>
      </Stack>
    </Box>
  </Stack.Item>
);

const ServerCard = ({ server }) => {
  const status = getStatus(server.status);
  let tempColor;
  if (server.temperature >= server.temp_critical) {
    tempColor = 'bad';
  } else if (server.temperature >= server.temp_high) {
    tempColor = 'average';
  }
  return (
    <Box className="RDServerControl__server">
      <Stack align="center">
        <Stack.Item>
          <Box
            className={`RDServerControl__serverIcon RDServerControl__serverIcon--${status.tone}`}>
            <Icon name="server" size={1.4} />
          </Box>
        </Stack.Item>
        <Stack.Item grow>
          <Box bold className="RDServerControl__serverTitle">
            СЕРВЕР {server.id}
          </Box>
          <Box className="RDServerControl__serverPath">{server.path}</Box>
        </Stack.Item>
        <Stack.Item>
          <Box
            className={`RDServerControl__badge RDServerControl__badge--${status.tone}`}>
            <Icon name={status.icon} mr={0.5} />
            {status.label}
          </Box>
        </Stack.Item>
      </Stack>

      <Divider />

      <Stack>
        <Stack.Item grow>
          <LabeledList>
            <LabeledList.Item
              color={server.connected ? 'good' : 'bad'}
              label="Сеть">
              <Icon
                name={server.connected ? 'network-wired' : 'unlink'}
                mr={0.5}
              />
              {server.network}
            </LabeledList.Item>
            <LabeledList.Item label="Расположение">
              <Icon name="map-marker-alt" mr={0.5} />
              {server.location}
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
        <Stack.Item grow>
          <LabeledList>
            <LabeledList.Item label="Выработка">
              <Icon name="microchip" mr={0.5} />
              <Box bold color="good" inline>
                {server.income}
              </Box>{' '}
              RP/тик
            </LabeledList.Item>
            <LabeledList.Item color={tempColor} label="Температура">
              <Icon name="thermometer-half" mr={0.5} />
              {server.temperature}°C
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
      </Stack>

      <Box mt={0.5}>
        <ProgressBar
          maxValue={server.temp_critical}
          minValue={0}
          ranges={{
            good: [0, server.temp_high],
            average: [server.temp_high, server.temp_critical],
            bad: [server.temp_critical, Infinity],
          }}
          value={server.temperature}>
          <Box className="RDServerControl__barText">
            ТЕМПЕРАТУРА {server.temperature}°C / {server.temp_critical}°C
          </Box>
        </ProgressBar>
      </Box>
    </Box>
  );
};

export const RDServerControl = () => {
  const { act, data } = useBackend();
  const {
    emagged = false,
    network_count = 0,
    online_servers = 0,
    servers = [],
    total_income = 0,
    total_servers = 0,
  } = data;

  return (
    <Window
      height={640}
      theme="ntos_terminal"
      title="R&D Server Control"
      width={760}>
      <Window.Content scrollable>
        <Box className="RDServerControl">
          <Box className="RDServerControl__banner">
            <Stack align="center">
              <Stack.Item>
                <Icon
                  className="RDServerControl__logo"
                  name="satellite-dish"
                  size={2.4}
                />
              </Stack.Item>
              <Stack.Item grow>
                <Box className="RDServerControl__title">
                  R&D SERVER CONTROL
                </Box>
                <Box className="RDServerControl__subtitle">
                  NANOTRASEN RESEARCH DIVISION // DOS v3.4.2
                </Box>
              </Stack.Item>
              <Stack.Item>
                <Box className="RDServerControl__badge RDServerControl__badge--online">
                  <Icon name="wifi" mr={0.5} />
                  UPLINK CONNECTED
                </Box>
              </Stack.Item>
            </Stack>
            <Box className="RDServerControl__boot">
              <span className="RDServerControl__prompt">C:\&gt;</span>{' '}
              Инициализация системных ресурсов...{' '}
              <span className="RDServerControl__ok">OK</span>
              {' // '}
              Драйверы... <span className="RDServerControl__ok">OK</span>
              {' // '}
              Интерфейс... <span className="RDServerControl__ok">READY</span>
            </Box>
          </Box>

          {!!emagged && (
            <NoticeBox danger mb={1}>
              <Icon name="exclamation-triangle" mr={0.5} />
              Протоколы безопасности отключены. Данные могут быть искажены.
            </NoticeBox>
          )}

          <Section
            buttons={
              <Button
                content="Обновить"
                icon="sync"
                onClick={() => act('refresh')}
              />
            }
            title="Сводка">
            <Stack>
              <StatCard
                color="blue"
                icon="server"
                label="СЕРВЕРОВ"
                value={total_servers}
              />
              <StatCard
                color="good"
                icon="check-circle"
                label="ОНЛАЙН"
                value={online_servers}
              />
              <StatCard
                color="teal"
                icon="network-wired"
                label="СЕТЕЙ"
                value={network_count}
              />
              <StatCard
                color="yellow"
                icon="microchip"
                label="RP/ТИК"
                value={total_income}
              />
            </Stack>
          </Section>

          <Section title="Подключённые серверы">
            {servers.length === 0 ? (
              <NoticeBox>Серверы не обнаружены.</NoticeBox>
            ) : (
              servers.map((server) => (
                <ServerCard key={server.path} server={server} />
              ))
            )}
          </Section>

          <Box className="RDServerControl__footer">
            <span className="RDServerControl__prompt">C:\&gt;</span> Система
            готова.
            <span className="RDServerControl__cursor" />
          </Box>
        </Box>
      </Window.Content>
    </Window>
  );
};

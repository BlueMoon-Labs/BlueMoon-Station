import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  Collapsible,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
  Table,
} from '../components';
import { Window } from '../layouts';

type LedgerEntry = {
  name: string;
  intensity: number;
  expires_in: number | null;
};

type BeatEntry = {
  time: number;
  result: string;
  budget: number;
  action: string | null;
  severity: string | null;
  cost: number;
};

type DirectorPanelData = {
  paused: BooleanLike;
  budget: number;
  budgets: Record<string, number>;
  profileName: string | null;
  intensity: number;
  intensityCap: number;
  crew: number;
  deadFraction: number;
  staffing: Record<string, number>;
  configError: string | null;
  pending: string | null;
  ledger: LedgerEntry[];
  beats: BeatEntry[];
  blockedSeverities: string[];
  lastRejects: Record<string, Record<string, number>> | null;
};

const SEVERITY_LABELS: Record<string, string> = {
  flavor: 'Флейвор',
  minor: 'Малое',
  moderate: 'Среднее',
  major: 'Крупное',
  antag: 'Антагонист',
};

const RESULT_LABELS: Record<string, string> = {
  fired: 'Запущено',
  guaranteed: 'Гарантированно',
  blocked: 'Заблокировано',
  idle: 'Простой',
  cancelled: 'Отменено',
};

const REJECT_LABELS: Record<string, string> = {
  blocked: 'блокировка ступени',
  events_off: 'события выключены конфигом',
  intensity_cap: 'потолок intensity',
  evac: 'эвакуация',
  dead_crisis: 'доля мёртвых',
  major_cap: 'лимит крупных',
  spacing: 'пауза ступени',
  budget: 'нет бюджета',
  can_fire: 'не готово (can_fire)',
  no_weight: 'нулевой вес',
};

const DEPARTMENT_LABELS: Record<string, string> = {
  security: 'Охрана',
  engineering: 'Инженеры',
  medical: 'Медики',
  science: 'Учёные',
  supply: 'Снабжение',
  command: 'Командование',
};

export const DirectorPanel = (props) => {
  const { data, act } = useBackend<DirectorPanelData>();
  const {
    paused,
    budget,
    budgets,
    profileName,
    intensity,
    intensityCap,
    crew,
    deadFraction,
    staffing,
    configError,
    pending,
    ledger,
    beats,
    blockedSeverities,
    lastRejects,
  } = data;

  const staffingEntries = staffing || {};
  const staffingText = Object.keys(staffingEntries)
    .map((dept) => `${DEPARTMENT_LABELS[dept] || dept}: ${staffingEntries[dept]}`)
    .join(', ');
  const activeBlocked = blockedSeverities || [];
  const ledgerEntries = ledger || [];
  const beatEntries = (beats || []).slice().reverse();
  const rejectEntries = Object.entries(lastRejects || {});
  const budgetWallets = budgets || {};
  const budgetsText = Object.keys(SEVERITY_LABELS)
    .filter((severity) => severity in budgetWallets)
    .map((severity) => `${SEVERITY_LABELS[severity]}: ${budgetWallets[severity]}`)
    .join(', ');

  return (
    <Window theme="admin" title="Director Panel" width={640} height={680}>
      <Window.Content scrollable>
        <Stack vertical fill>
          {!!configError && (
            <Stack.Item>
              <NoticeBox danger>Ошибка конфига: {configError}</NoticeBox>
            </Stack.Item>
          )}
          {!!paused && (
            <Stack.Item>
              <NoticeBox danger>Директор на паузе</NoticeBox>
            </Stack.Item>
          )}
          {!!pending && (
            <Stack.Item>
              <NoticeBox warning>
                <Stack align="center">
                  <Stack.Item grow>
                    Ожидает запуска: {pending}
                  </Stack.Item>
                  <Stack.Item>
                    <Button onClick={() => act('cancel_pending')}>
                      Отменить
                    </Button>
                  </Stack.Item>
                </Stack>
              </NoticeBox>
            </Stack.Item>
          )}
          <Stack.Item>
            <Collapsible title="Справочник: как работает директор">
              <Box mb={1}>
                <b>Принцип.</b> Директор - единый планировщик всех случайных
                событий и мидраунд/латеджойн-рулсетов динамика. Раз в 60 секунд
                происходит &quot;бит&quot;: собираются сигналы станции (экипаж
                по
                отделам, доля мёртвых, живые антаги, эвакуация, текущая
                intensity), из пула действий отфильтровываются доступные и
                взвешенным броском выбирается одно - либо ничего.
              </Box>
              <Box mb={1}>
                <b>Бюджет.</b> Очки капают раз в минуту по кривым активного
                профиля (зависят от времени раунда и размера экипажа) и
                раскладываются по кошелькам ступеней в пропорции долей
                профиля. Запуск списывает cost из кошелька своей ступени,
                несостоявшийся запуск рефандится. При доле мёртвых выше порога
                капля режется вдвое.
              </Box>
              <Box mb={1}>
                <b>Ступени.</b> Флейвор (cost 0, атмосферные мелочи), Малое
                (по умолчанию 2), Среднее (6), Крупное (25), Антагонист (по
                рулсету). Среднее и тяжелее не стартуют мгновенно: открывается
                окно отмены (по умолчанию 15 с) с кнопками отмены и замены в
                чате админов.
              </Box>
              <Box mb={1}>
                <b>Intensity.</b> Мера текущего хаоса. Запуск добавляет вклад
                (Малое 5, Среднее 15, Крупное 40; антаги считаются динамически
                по доле выживших). Пока сумма выше потолка профиля, новые
                запуски блокируются - кроме флейвора. Вклады событий гаснут по
                их завершении, текущие видны в таблице &quot;Активные
                вклады&quot;.
              </Box>
              <Box mb={1}>
                <b>Темп.</b> У каждой ступени своя минимальная пауза между
                запусками, у тяжёлых антагов - отдельная. Ступень, отстающая
                от целевой доли запусков, получает буст веса, обогнавшая -
                штраф. Уже стрелявшие действия теряют вес с каждым запуском
                (затухание повторов), чтобы директор не крутил одно и то же.
                Если тишина тянется дольше порога профиля при низкой
                intensity, бит гарантированно запускает Малое/Среднее,
                игнорируя бюджет. Почему кандидаты не прошли последний бит -
                в таблице &quot;Отсев последнего бита&quot;.
              </Box>
              <Box mb={1}>
                <b>Предохранители.</b> После вызова эвакуации Крупные и антаги
                не стартуют, после улёта шаттла биты пусты. Высокая доля
                мёртвых блокирует Крупные и тяжёлых антагов, а
                недоукомплектованная охрана штрафует их вес. Латеджойн-антаги
                идут отдельным
                путём: кандидатом ставится только сам зашедший игрок.
              </Box>
              <Box>
                <b>Управление.</b> Пауза останавливает каплю и биты (уже
                запущенные события дотикивают). Форс-бит - немедленное решение
                вне расписания. Кнопки бюджета раскладывают дельту по
                кошелькам. Блокировка ступеней исключает их из выбора. Конфиг
                config/director.json перечитывается на лету, времена в нём - в
                минутах. Лог решений раунда пишется в director.json в папке
                логов, оффлайн-прогон пейсинга - верб Director Simulate.
              </Box>
            </Collapsible>
          </Stack.Item>
          <Stack.Item>
            <Section title="Статус">
              <LabeledList>
                <LabeledList.Item label="Профиль">
                  {profileName || 'не выбран'}
                </LabeledList.Item>
                <LabeledList.Item label="Бюджет">
                  {budget}
                </LabeledList.Item>
                <LabeledList.Item label="Кошельки">
                  {budgetsText || 'нет данных'}
                </LabeledList.Item>
                <LabeledList.Item label="Intensity">
                  <ProgressBar
                    value={intensity}
                    minValue={0}
                    maxValue={intensityCap || 1}>
                    {intensity} / {intensityCap}
                  </ProgressBar>
                </LabeledList.Item>
                <LabeledList.Item label="Экипаж">
                  {crew}
                </LabeledList.Item>
                <LabeledList.Item label="Доля мёртвых">
                  {deadFraction}%
                </LabeledList.Item>
                <LabeledList.Item label="По отделам">
                  {staffingText || 'нет данных'}
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Section title="Управление">
              <Stack wrap>
                <Stack.Item>
                  <Button
                    icon={paused ? 'play' : 'pause'}
                    onClick={() => act('toggle_pause')}>
                    {paused ? 'Возобновить' : 'Пауза'}
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button icon="forward" onClick={() => act('force_beat')}>
                    Форс-бит
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="plus"
                    onClick={() => act('adjust_budget', { amount: 5 })}>
                    +5 бюджета
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="minus"
                    onClick={() => act('adjust_budget', { amount: -5 })}>
                    -5 бюджета
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="rotate-right"
                    onClick={() => act('reload_config')}>
                    Перезагрузить конфиг
                  </Button>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Section title="Блокировка ступеней">
              <Stack wrap>
                {Object.keys(SEVERITY_LABELS).map((severity) => {
                  const isBlocked = activeBlocked.includes(severity);
                  return (
                    <Stack.Item key={severity}>
                      <Button
                        selected={isBlocked}
                        color={isBlocked ? 'bad' : undefined}
                        onClick={() =>
                          act('toggle_severity_block', { severity })}>
                        {SEVERITY_LABELS[severity]}
                      </Button>
                    </Stack.Item>
                  );
                })}
              </Stack>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Section title="Активные вклады">
              <Table>
                <Table.Row header>
                  <Table.Cell>Источник</Table.Cell>
                  <Table.Cell>Intensity</Table.Cell>
                  <Table.Cell>Истекает</Table.Cell>
                </Table.Row>
                {ledgerEntries.map((entry, index) => (
                  <Table.Row key={index}>
                    <Table.Cell>{entry.name}</Table.Cell>
                    <Table.Cell>{entry.intensity}</Table.Cell>
                    <Table.Cell>
                      {entry.expires_in
                        ? `истекает через ${entry.expires_in} мин`
                        : 'пока активно'}
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Section title="Отсев последнего бита">
              {rejectEntries.length ? (
                <LabeledList>
                  {rejectEntries.map(([severity, reasons]) => (
                    <LabeledList.Item
                      key={severity}
                      label={SEVERITY_LABELS[severity] || severity}>
                      {Object.entries(reasons)
                        .map(
                          ([reason, count]) =>
                            `${REJECT_LABELS[reason] || reason}: ${count}`,
                        )
                        .join(', ')}
                    </LabeledList.Item>
                  ))}
                </LabeledList>
              ) : (
                'бит ещё не проходил или все кандидаты прошли фильтры'
              )}
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Section title="Последние решения" fill scrollable>
              <Table>
                <Table.Row header>
                  <Table.Cell>Минута</Table.Cell>
                  <Table.Cell>Результат</Table.Cell>
                  <Table.Cell>Действие</Table.Cell>
                  <Table.Cell>Ступень</Table.Cell>
                  <Table.Cell>Cost</Table.Cell>
                  <Table.Cell>Бюджет</Table.Cell>
                </Table.Row>
                {beatEntries.map((entry, index) => (
                  <Table.Row key={index}>
                    <Table.Cell>{Math.round(entry.time / 600)}</Table.Cell>
                    <Table.Cell>
                      {RESULT_LABELS[entry.result] || entry.result}
                    </Table.Cell>
                    <Table.Cell>{entry.action || '-'}</Table.Cell>
                    <Table.Cell>
                      {entry.severity
                        ? SEVERITY_LABELS[entry.severity] || entry.severity
                        : '-'}
                    </Table.Cell>
                    <Table.Cell>{entry.cost}</Table.Cell>
                    <Table.Cell>{entry.budget}</Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

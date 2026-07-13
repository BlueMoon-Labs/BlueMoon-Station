import { BooleanLike } from 'common/react';
import { ReactNode, useState } from 'react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  Input,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
  Table,
  Tabs,
} from '../components';
import { Window } from '../layouts';

type LedgerEntry = {
  name: string;
  intensity: number;
  expires_in?: number | null;
  living?: number;
  assigned?: number;
};

// Динамическая строка рулсета живёт, пока живы его антаги; записи ledger - по таймеру или до конца события.
const ledgerExpiryText = (entry: LedgerEntry) => {
  if (entry.living) {
    return `пока живы антаги (${entry.living} из ${entry.assigned})`;
  }
  return entry.expires_in
    ? `истекает через ${entry.expires_in} мин`
    : 'пока активно';
};

type BeatEntry = {
  time: number;
  result: string;
  budget: number;
  action: string | null;
  severity: string | null;
  cost: number;
};

type PoolEntry = {
  name: string;
  kind: string;
  severity: string;
  cost: number;
  intensity: number;
  weight: number;
  occurrences: number;
  verdict: string;
  detail: string | null;
  chance?: number;
};

type ProfileEntry = {
  roundType: string;
  desc: string;
  active: BooleanLike;
  baseDrip: number;
  antagDrip: number;
  initialGrant: number;
  roundstartMin: number;
  roundstartMax: number;
  timeCurve: [number, number][];
  popCurve: [number, number][];
  intensityCap: number;
  maxActiveMajor: number;
  severitySpacing: Record<string, number>;
  globalSpacing: number;
  familySpacing: number;
  antagLightSpacing: number;
  antagHeavySpacing: number;
  ghostLightSpacing: number;
  ghostHeavySpacing: number;
  latejoinSpacing: number;
  poolShares: Record<string, number>;
  disruptionMults: Record<string, number>;
  antagPerCrew: number;
  antagHeavyEnabled: BooleanLike;
  maxQuiet: number;
  quietThreshold: number;
  securityPerPlayers: number;
  securityPenaltyMult: number;
  deadFractionThreshold: number;
  adminCancelTime: number;
  repeatPenalty: number;
};

type WalletEntry = {
  severity: string;
  points: number;
  share: number;
  spacingLeft: number;
  fired: number;
  correction: number;
  heavySpacingLeft?: number;
  savingFor?: string;
  savingCost?: number;
};

type DirectorPanelData = {
  paused: BooleanLike;
  budget: number;
  profileName: string | null;
  intensity: number;
  intensityCap: number;
  crew: number;
  deadFraction: number;
  staffing: Record<string, number>;
  configError: string | null;
  pending: string | null;
  pendingSeverity: string | null;
  pendingLeft: number | null;
  ledger: LedgerEntry[];
  beats: BeatEntry[];
  blockedSeverities: string[];
  lastRejects: Record<string, Record<string, number>> | null;
  wallets: WalletEntry[];
  dripRate: number;
  dripTimeMult: number;
  dripPopMult: number;
  dripDeadHalved: BooleanLike;
  antagDripRate: number;
  antagDeficit: number;
  antagLoad: number;
  antagTarget: number;
  quietFor: number;
  maxQuiet: number;
  quietThreshold: number;
  maxActiveMajor: number;
  pool: PoolEntry[];
  profiles: ProfileEntry[];
};

const SEVERITY_LABELS: Record<string, string> = {
  flavor: 'Флейвор',
  minor: 'Малое',
  moderate: 'Среднее',
  major: 'Крупное',
  antag: 'Антагонист',
  ghost: 'Гост-антаг',
  // Псевдо-ступень бита, отсечённого глобальной паузой (гейт бьёт по всем ступеням сразу)
  all: 'Все ступени',
};

const SEVERITY_ORDER = ['flavor', 'minor', 'moderate', 'major', 'antag', 'ghost'];

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
  family_spacing: 'пауза семейства',
  global_spacing: 'глобальная пауза',
  disruption: 'приглушено профилем',
  budget: 'нет бюджета',
  can_fire: 'не готово (can_fire)',
  no_weight: 'нулевой вес',
  antag_saturated: 'антагов достаточно',
  saving: 'пул копит на цель',
  antag_heavy_off: 'тяжёлые антаги выключены',
};

// Вердикты пула: причины отсева бита + расшифровка can_fire + структурные пропуски
const VERDICT_LABELS: Record<string, string> = {
  blocked: 'ступень заблокирована',
  events_off: 'события выключены конфигом',
  intensity_cap: 'потолок intensity',
  evac: 'эвакуация вызвана',
  dead_crisis: 'слишком много мёртвых',
  major_cap: 'лимит одновременных крупных',
  spacing: 'пауза ступени',
  family_spacing: 'пауза семейства',
  disruption: 'приглушено профилем (навязчивость)',
  budget: 'не хватает кошелька',
  can_fire: 'внутреннее условие действия',
  no_weight: 'нулевой вес',
  antag_saturated: 'живых антагов достаточно',
  saving: 'пул копит на другую цель',
  antag_heavy_off: 'тяжёлые антаги выключены профилем',
  disabled: 'выключено',
  admin_only: 'только ручной запуск',
  max_occurrences: 'лимит запусков исчерпан',
  early: 'слишком рано',
  min_players: 'мало экипажа',
  round_type: 'не тот тип раунда',
  staffing: 'не хватает штата отдела',
  special: 'специфичное условие действия',
  latejoin: 'только при латеджойне',
};

const KIND_LABELS: Record<string, string> = {
  event: 'Событие',
  ruleset: 'Рулсет',
};

const DEPARTMENT_LABELS: Record<string, string> = {
  security: 'Охрана',
  engineering: 'Инженеры',
  medical: 'Медики',
  science: 'Учёные',
  supply: 'Снабжение',
  command: 'Командование',
};

const OverviewTab = (props) => {
  const { data, act } = useBackend<DirectorPanelData>();
  const {
    paused,
    budget,
    profileName,
    intensity,
    intensityCap,
    crew,
    deadFraction,
    staffing,
    ledger,
    beats,
    blockedSeverities,
    lastRejects,
    wallets,
    dripRate,
    dripTimeMult,
    dripPopMult,
    dripDeadHalved,
    antagDripRate,
    antagDeficit,
    antagLoad,
    antagTarget,
    quietFor,
    maxQuiet,
    quietThreshold,
    maxActiveMajor,
  } = data;

  const staffingEntries = staffing || {};
  const staffingText = Object.keys(staffingEntries)
    .map((dept) => `${DEPARTMENT_LABELS[dept] || dept}: ${staffingEntries[dept]}`)
    .join(', ');
  const activeBlocked = blockedSeverities || [];
  const ledgerEntries = ledger || [];
  const beatEntries = (beats || []).slice().reverse();
  const rejectEntries = Object.entries(lastRejects || {});
  const walletRows = wallets || [];
  const quietReady = maxQuiet > 0 && quietFor >= maxQuiet;

  return (
    <>
      <Stack.Item>
        <Section title="Статус">
          <LabeledList>
            <LabeledList.Item label="Профиль">
              {profileName || 'не выбран'}
            </LabeledList.Item>
            <LabeledList.Item label="Бюджет">
              {budget}
              <Box inline ml={1} color="label">
                +{dripRate}/мин (время x{dripTimeMult}, экипаж x{dripPopMult}
                {!!dripDeadHalved && ', кризис мёртвых /2'})
              </Box>
            </LabeledList.Item>
            <LabeledList.Item label="Антаг-капля">
              +{antagDripRate}/мин
              <Box inline ml={1} color="label">
                дефицит {antagDeficit}% (нагрузка {antagLoad} при цели{' '}
                {antagTarget})
              </Box>
            </LabeledList.Item>
            <LabeledList.Item label="Intensity">
              <ProgressBar
                value={intensity}
                minValue={0}
                maxValue={intensityCap || 1}>
                {intensity} / {intensityCap}
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Тишина">
              <Box inline color={quietReady ? 'average' : undefined}>
                {quietFor} / {maxQuiet} мин
              </Box>
              <Box inline ml={1} color="label">
                {quietReady && intensity < quietThreshold
                  ? 'следующий бит гарантированный'
                  : `гарантированный бит при intensity ниже ${quietThreshold}`}
              </Box>
            </LabeledList.Item>
            <LabeledList.Item label="Крупные">
              {`одновременно не больше ${maxActiveMajor}`}
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
            {SEVERITY_ORDER.map((severity) => {
              const isBlocked = activeBlocked.includes(severity);
              return (
                <Stack.Item key={severity}>
                  <Button
                    icon={isBlocked ? 'ban' : undefined}
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
        <Section title="Кошельки бюджета">
          <Table>
            <Table.Row header>
              <Table.Cell>Ступень</Table.Cell>
              <Table.Cell>Очки</Table.Cell>
              <Table.Cell>Доля капли</Table.Cell>
              <Table.Cell>Пауза ступени</Table.Cell>
              <Table.Cell>Запусков</Table.Cell>
              <Table.Cell>Поправка веса</Table.Cell>
            </Table.Row>
            {walletRows.map((wallet) => (
              <Table.Row key={wallet.severity}>
                <Table.Cell>
                  {SEVERITY_LABELS[wallet.severity] || wallet.severity}
                </Table.Cell>
                <Table.Cell>
                  {wallet.points}
                  {wallet.savingFor !== undefined && (
                    <Box inline ml={1} color="label">
                      (копит на {wallet.savingFor}
                      {wallet.savingCost !== undefined
                        ? `, cost ${wallet.savingCost}`
                        : ''}
                      )
                    </Box>
                  )}
                </Table.Cell>
                <Table.Cell>{Math.round(wallet.share * 100)}%</Table.Cell>
                <Table.Cell>
                  {wallet.spacingLeft > 0 ? (
                    <Box inline color="average">
                      ещё {wallet.spacingLeft} мин
                    </Box>
                  ) : (
                    <Box inline color="good">
                      готова
                    </Box>
                  )}
                  {wallet.heavySpacingLeft !== undefined && (
                    <Box inline ml={1} color="label">
                      (тяжёлые:{' '}
                      {wallet.heavySpacingLeft > 0
                        ? `ещё ${wallet.heavySpacingLeft} мин`
                        : 'готовы'}
                      )
                    </Box>
                  )}
                </Table.Cell>
                <Table.Cell>{wallet.fired}</Table.Cell>
                <Table.Cell>
                  <Box
                    inline
                    color={
                      wallet.correction > 1
                        ? 'good'
                        : wallet.correction < 1
                          ? 'bad'
                          : undefined
                    }>
                    x{wallet.correction}
                  </Box>
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
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
                <Table.Cell>{ledgerExpiryText(entry)}</Table.Cell>
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
      <Stack.Item>
        <Section title="Последние решения">
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
    </>
  );
};

const verdictSortOrder = (entry: PoolEntry) => {
  if (entry.verdict === 'ok') {
    return 0;
  }
  if (entry.verdict === 'latejoin') {
    return 1;
  }
  return 2;
};

const PoolStatusCell = (props: { entry: PoolEntry }) => {
  const { entry } = props;
  if (entry.verdict === 'ok') {
    return (
      <Box inline color="good">
        шанс {entry.chance ?? 0}%
      </Box>
    );
  }
  const label = VERDICT_LABELS[entry.verdict] || entry.verdict;
  if (entry.verdict === 'latejoin') {
    return (
      <Box inline color="average">
        {label}
      </Box>
    );
  }
  return (
    <Box inline color="bad">
      {label}
      {entry.detail ? ` (${entry.detail})` : ''}
    </Box>
  );
};

const PoolTab = (props) => {
  const { data } = useBackend<DirectorPanelData>();
  const [search, setSearch] = useState('');
  const [onlyReady, setOnlyReady] = useState(false);
  const pool = data.pool || [];
  const query = search.toLowerCase();

  if (!pool.length) {
    return (
      <Stack.Item>
        <Section>
          Пул пуст: раунд ещё не начался или профиль не выбран.
        </Section>
      </Stack.Item>
    );
  }

  return (
    <>
      <Stack.Item>
        <Section>
          <Stack align="center">
            <Stack.Item grow>
              <Input
                fluid
                placeholder="Поиск по имени..."
                value={search}
                onInput={(e, value) => setSearch(value)}
              />
            </Stack.Item>
            <Stack.Item>
              <Button.Checkbox
                checked={onlyReady}
                onClick={() => setOnlyReady(!onlyReady)}>
                Только доступные
              </Button.Checkbox>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
      {SEVERITY_ORDER.map((severity) => {
        const entries = pool.filter((entry) => entry.severity === severity);
        if (!entries.length) {
          return null;
        }
        const readyCount = entries.filter(
          (entry) => entry.verdict === 'ok',
        ).length;
        const shown = entries
          .filter((entry) => !query || entry.name.toLowerCase().includes(query))
          .filter((entry) => !onlyReady || entry.verdict === 'ok')
          .sort((a, b) => {
            const order = verdictSortOrder(a) - verdictSortOrder(b);
            if (order !== 0) {
              return order;
            }
            if (a.verdict === 'ok' && b.verdict === 'ok') {
              return (b.chance ?? 0) - (a.chance ?? 0);
            }
            return a.name.localeCompare(b.name);
          });
        if (!shown.length) {
          return null;
        }
        return (
          <Stack.Item key={severity}>
            <Section
              title={`${SEVERITY_LABELS[severity]} - доступно ${readyCount} из ${entries.length}`}>
              <Table>
                <Table.Row header>
                  <Table.Cell>Действие</Table.Cell>
                  <Table.Cell>Тип</Table.Cell>
                  <Table.Cell>Cost</Table.Cell>
                  <Table.Cell>Int</Table.Cell>
                  <Table.Cell>Вес</Table.Cell>
                  <Table.Cell>Запуски</Table.Cell>
                  <Table.Cell>Статус</Table.Cell>
                </Table.Row>
                {shown.map((entry) => (
                  <Table.Row key={entry.name}>
                    <Table.Cell>{entry.name}</Table.Cell>
                    <Table.Cell>
                      {KIND_LABELS[entry.kind] || entry.kind}
                    </Table.Cell>
                    <Table.Cell>{entry.cost}</Table.Cell>
                    <Table.Cell>{entry.intensity}</Table.Cell>
                    <Table.Cell>{entry.weight}</Table.Cell>
                    <Table.Cell>{entry.occurrences}</Table.Cell>
                    <Table.Cell>
                      <PoolStatusCell entry={entry} />
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            </Section>
          </Stack.Item>
        );
      })}
    </>
  );
};

// Порядок колонок вкладки "Профили": от самого фонового к самому плотному
const PROFILE_ORDER = [
  'Extended',
  'Dynamic (Light)',
  'Dynamic (Medium)',
  'Dynamic (Hard)',
  'Dynamic (Team-Based)',
];

const PROFILE_LABELS: Record<string, string> = {
  'Extended': 'Extended',
  'Dynamic (Light)': 'Light',
  'Dynamic (Medium)': 'Medium',
  'Dynamic (Hard)': 'Hard',
  'Dynamic (Team-Based)': 'Team-Based',
};

const profileSortIndex = (profile: ProfileEntry) => {
  const index = PROFILE_ORDER.indexOf(profile.roundType);
  return index === -1 ? PROFILE_ORDER.length : index;
};

const curveText = (curve: [number, number][], unit: string) =>
  (curve || []).map(([x, y]) => `${x} ${unit}: x${y}`).join('; ');

type ProfileRowSpec = {
  label: string;
  render: (profile: ProfileEntry) => ReactNode;
};

const TEMPO_ROWS: ProfileRowSpec[] = [
  { label: 'Капля, очков/мин', render: (profile) => profile.baseDrip },
  {
    label: 'Антаг-капля при полном дефиците',
    render: (profile) => profile.antagDrip,
  },
  { label: 'Стартовый аванс', render: (profile) => profile.initialGrant },
  {
    label: 'Roundstart-бюджет',
    render: (profile) =>
      profile.roundstartMax > 0 ? (
        `${profile.roundstartMin}-${profile.roundstartMax}`
      ) : (
        <Box inline color="bad">
          нет
        </Box>
      ),
  },
  {
    label: 'Множитель от времени',
    render: (profile) => curveText(profile.timeCurve, 'мин'),
  },
  {
    label: 'Множитель от экипажа',
    render: (profile) => curveText(profile.popCurve, 'чел'),
  },
];

const CAPS_ROWS: ProfileRowSpec[] = [
  { label: 'Потолок intensity', render: (profile) => profile.intensityCap },
  {
    label: 'Крупных одновременно',
    render: (profile) =>
      profile.maxActiveMajor > 0 ? (
        profile.maxActiveMajor
      ) : (
        <Box inline color="bad">
          0
        </Box>
      ),
  },
  {
    label: 'Гарантированный бит после тишины',
    render: (profile) => `${profile.maxQuiet} мин`,
  },
  {
    label: 'Порог intensity для гарантии',
    render: (profile) => profile.quietThreshold,
  },
];

const SHARE_ROWS: ProfileRowSpec[] = SEVERITY_ORDER.map((severity) => ({
  label: SEVERITY_LABELS[severity],
  render: (profile) => {
    const share = profile.poolShares?.[severity] ?? 0;
    return share > 0 ? (
      `${Math.round(share * 100)}%`
    ) : (
      <Box inline color="bad">
        0%
      </Box>
    );
  },
}));

const SPACING_ROWS: ProfileRowSpec[] = [
  ...['flavor', 'minor', 'moderate', 'major'].map((severity) => ({
    label: SEVERITY_LABELS[severity],
    render: (profile: ProfileEntry) =>
      profile.severitySpacing?.[severity] ?? '-',
  })),
  {
    label: 'Глобальная (между любыми)',
    render: (profile) => profile.globalSpacing,
  },
  {
    label: 'Семейство однотипных',
    render: (profile) => profile.familySpacing,
  },
  {
    label: 'Антаги: лёгкие / тяжёлые',
    render: (profile) =>
      `${profile.antagLightSpacing} / ${profile.antagHeavySpacing}`,
  },
  {
    label: 'Гост-антаги: лёгкие / тяжёлые',
    render: (profile) =>
      `${profile.ghostLightSpacing} / ${profile.ghostHeavySpacing}`,
  },
  {
    label: 'Латеджойн-канал',
    render: (profile) => profile.latejoinSpacing,
  },
];

const DISRUPTION_ROW_LABELS: Record<string, string> = {
  ambient: 'Фоновые (ambient)',
  mild: 'Заметные (mild)',
  disruptive: 'Мешающие (disruptive)',
};

const DISRUPTION_ROWS: ProfileRowSpec[] = [
  'ambient',
  'mild',
  'disruptive',
].map((disruption) => ({
  label: DISRUPTION_ROW_LABELS[disruption],
  render: (profile) => {
    const mult = profile.disruptionMults?.[disruption];
    if (mult === undefined) {
      return 'x1';
    }
    return mult > 0 ? (
      `x${mult}`
    ) : (
      <Box inline color="bad">
        выкл
      </Box>
    );
  },
}));

const ANTAG_ROWS: ProfileRowSpec[] = [
  {
    label: 'Цель нагрузки на голову экипажа',
    render: (profile) => profile.antagPerCrew,
  },
  {
    label: 'Тяжёлые антаг-действия',
    render: (profile) =>
      profile.antagHeavyEnabled ? (
        <Box inline color="good">
          да
        </Box>
      ) : (
        <Box inline color="bad">
          нет
        </Box>
      ),
  },
];

const SAFETY_ROWS: ProfileRowSpec[] = [
  {
    label: 'Норма СБ: 1 офицер на',
    render: (profile) => `${profile.securityPerPlayers} экипажа`,
  },
  {
    label: 'Штраф веса при недоборе СБ',
    render: (profile) => `x${profile.securityPenaltyMult}`,
  },
  {
    label: 'Кризис мёртвых: порог доли',
    render: (profile) => `${Math.round(profile.deadFractionThreshold * 100)}%`,
  },
  {
    label: 'Окно отмены админом',
    render: (profile) => `${profile.adminCancelTime} с`,
  },
  {
    label: 'Затухание повторов',
    render: (profile) => profile.repeatPenalty,
  },
];

const ProfileTable = (props: {
  title: string;
  profiles: ProfileEntry[];
  rows: ProfileRowSpec[];
  note?: string;
}) => {
  const { title, profiles, rows, note } = props;
  return (
    <Stack.Item>
      <Section title={title}>
        {!!note && (
          <Box mb={1} color="label">
            {note}
          </Box>
        )}
        <Table>
          {/* Явные ширины: каждая секция - своя таблица, без них колонки гуляют от секции к секции */}
          <Table.Row header>
            <Table.Cell width="30%" />
            {profiles.map((profile) => (
              <Table.Cell
                key={profile.roundType}
                width="14%"
                color={profile.active ? 'good' : undefined}>
                {PROFILE_LABELS[profile.roundType] || profile.roundType}
              </Table.Cell>
            ))}
          </Table.Row>
          {rows.map((row) => (
            <Table.Row key={row.label}>
              <Table.Cell color="label">{row.label}</Table.Cell>
              {profiles.map((profile) => (
                <Table.Cell key={profile.roundType}>
                  {row.render(profile)}
                </Table.Cell>
              ))}
            </Table.Row>
          ))}
        </Table>
      </Section>
    </Stack.Item>
  );
};

const ProfilesTab = (props) => {
  const { data } = useBackend<DirectorPanelData>();
  const profiles = (data.profiles || [])
    .slice()
    .sort((a, b) => profileSortIndex(a) - profileSortIndex(b));

  if (!profiles.length) {
    return (
      <Stack.Item>
        <Section>Профили не загружены.</Section>
      </Stack.Item>
    );
  }

  return (
    <>
      <Stack.Item>
        <Section title="Профили темпа">
          <Box mb={1} color="label">
            Значения с учётом config/director.json: активный профиль показан
            живым (подсвечен), остальные - такими, какими станут при выборе
            их типа раунда. Времена в минутах.
          </Box>
          <LabeledList>
            {profiles.map((profile) => (
              <LabeledList.Item
                key={profile.roundType}
                label={PROFILE_LABELS[profile.roundType] || profile.roundType}
                color={profile.active ? 'good' : undefined}>
                {profile.desc}
                {!!profile.active && (
                  <Box inline ml={1} color="good">
                    (активен)
                  </Box>
                )}
              </LabeledList.Item>
            ))}
          </LabeledList>
        </Section>
      </Stack.Item>
      <ProfileTable title="Бюджет и темп" profiles={profiles} rows={TEMPO_ROWS} />
      <ProfileTable
        title="Потолки и тишина"
        profiles={profiles}
        rows={CAPS_ROWS}
      />
      <ProfileTable
        title="Доли капли по ступеням"
        profiles={profiles}
        rows={SHARE_ROWS}
        note="Доля Флейвора раскладывается по остальным ступеням: его действия бесплатны, кошелёк ему не нужен. Доля 0% выключает ступень."
      />
      <ProfileTable
        title="Паузы между запусками, мин"
        profiles={profiles}
        rows={SPACING_ROWS}
      />
      <ProfileTable
        title="Навязчивость: множители веса"
        profiles={profiles}
        rows={DISRUPTION_ROWS}
        note="Насколько профиль глушит мешающие играть события внутри своей ступени."
      />
      <ProfileTable
        title="Антагонисты"
        profiles={profiles}
        rows={ANTAG_ROWS}
        note="Цель нагрузки: живой лёгкий антаг = 15 intensity; при достижении цели (экипаж x значение) новые антаги не льются."
      />
      <ProfileTable
        title="Предохранители и прочее"
        profiles={profiles}
        rows={SAFETY_ROWS}
      />
    </>
  );
};

const HelpTab = (props) => {
  return (
    <Stack.Item>
      <Section title="Как работает директор">
        <Box mb={1}>
          <b>Принцип.</b> Директор - единый планировщик всех случайных
          событий и мидраунд/латеджойн-рулсетов динамика. Раз в 60 секунд
          происходит &quot;бит&quot;: собираются сигналы станции (экипаж по
          отделам, доля мёртвых, живые антаги, эвакуация, текущая
          intensity), из пула действий отфильтровываются доступные и
          взвешенным броском выбирается одно - либо ничего.
        </Box>
        <Box mb={1}>
          <b>Бюджет.</b> Очки капают раз в минуту по кривым активного
          профиля (зависят от времени раунда и размера экипажа) и
          раскладываются по кошелькам ступеней в пропорции долей профиля.
          Запуск списывает cost из кошелька своей ступени, несостоявшийся
          запуск рефандится. При доле мёртвых выше порога капля режется
          вдвое. Текущая скорость капли и её множители видны в строке
          &quot;Бюджет&quot; на вкладке &quot;Обзор&quot;.
        </Box>
        <Box mb={1}>
          <b>Ступени.</b> Флейвор (cost 0, атмосферные мелочи), Малое (по
          умолчанию 2), Среднее (6), Крупное (25), Антагонист и Гост-антаг
          (по рулсету). Антагонист - инжекции из живого экипажа
          (автотрейтор, культы), Гост-антаг - роли из призраков (нюки,
          ксеноморфы, дракон): у категорий свои кошельки и свои паузы, друг
          друга они не откладывают. Среднее и тяжелее не стартуют
          мгновенно: открывается окно отмены (по умолчанию 15 с) с
          кнопками отмены и замены - и в чате админов, и в шапке панели.
        </Box>
        <Box mb={1}>
          <b>Intensity.</b> Мера текущего хаоса. Запуск добавляет вклад
          (Малое 5, Среднее 15, Крупное 40; антаги считаются динамически по
          доле выживших). Пока сумма выше потолка профиля, новые запуски
          блокируются - кроме флейвора. Вклады событий гаснут по их
          завершении, антагов - по смерти; все текущие видны в таблице
          &quot;Активные вклады&quot;.
        </Box>
        <Box mb={1}>
          <b>Темп.</b> У каждой ступени своя минимальная пауза между
          запусками, у тяжёлых антагов - отдельная (и раздельная для
          экипажных и гост-антагов). Ступень, отстающая от
          целевой доли запусков, получает буст веса, обогнавшая - штраф
          (колонка &quot;Поправка веса&quot; в кошельках). Уже стрелявшие
          действия теряют вес с каждым запуском (затухание повторов), чтобы
          директор не крутил одно и то же. Если тишина тянется дольше
          порога профиля при низкой intensity, бит гарантированно запускает
          Малое/Среднее, игнорируя бюджет.
        </Box>
        <Box mb={1}>
          <b>Пул действий.</b> Вкладка со всеми зарегистрированными
          действиями и живой оценкой: у доступных показан шанс выбора на
          ближайшем бите (доля эффективного веса), у отсеянных - конкретная
          причина с деталью (сколько ждать паузу, сколько не хватает
          бюджета или экипажа). Оценка обновляется раз в несколько секунд.
          Латеджойн-рулсеты в битах не участвуют - они срабатывают только
          на зашедшего игрока.
        </Box>
        <Box mb={1}>
          <b>Профили.</b> Вкладка со всеми профилями темпа и их ручками:
          капля, доли ступеней, паузы, множители навязчивости,
          предохранители. Значения показаны с учётом config/director.json;
          активный профиль подсвечен и показан живым, остальные - такими,
          какими станут при выборе их типа раунда.
        </Box>
        <Box mb={1}>
          <b>Предохранители.</b> После вызова эвакуации Крупные и антаги не
          стартуют, после улёта шаттла биты пусты. Высокая доля мёртвых
          блокирует Крупные и тяжёлых антагов, а недоукомплектованная
          охрана штрафует их вес. На станции без эффективного экипажа биты
          простаивают и капля не копится (форс-бит работает).
          Латеджойн-антаги идут отдельным путём: кандидатом ставится только
          сам зашедший игрок.
        </Box>
        <Box>
          <b>Управление.</b> Пауза останавливает каплю и биты (уже
          запущенные события дотикивают). Форс-бит - немедленное решение
          вне расписания. Кнопки бюджета раскладывают дельту по кошелькам.
          Блокировка ступеней исключает их из выбора. Конфиг
          config/director.json перечитывается на лету, времена в нём - в
          минутах. Лог решений раунда пишется в director.json в папке
          логов, оффлайн-прогон пейсинга - верб Director Simulate.
        </Box>
      </Section>
    </Stack.Item>
  );
};

export const DirectorPanel = (props) => {
  const { data, act } = useBackend<DirectorPanelData>();
  const { paused, configError, pending, pendingSeverity, pendingLeft } = data;
  const [tab, setTab] = useState('overview');

  return (
    <Window theme="admin" title="Director Panel" width={800} height={720}>
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
                    {pendingSeverity
                      ? ` (${SEVERITY_LABELS[pendingSeverity] || pendingSeverity})`
                      : ''}
                    {pendingLeft !== null ? `, осталось ${pendingLeft} с` : ''}
                  </Stack.Item>
                  <Stack.Item>
                    <Button onClick={() => act('cancel_pending')}>
                      Отменить
                    </Button>
                  </Stack.Item>
                  <Stack.Item>
                    <Button onClick={() => act('reroll_pending')}>
                      Заменить
                    </Button>
                  </Stack.Item>
                </Stack>
              </NoticeBox>
            </Stack.Item>
          )}
          <Stack.Item>
            <Tabs>
              <Tabs.Tab
                selected={tab === 'overview'}
                onClick={() => setTab('overview')}>
                Обзор
              </Tabs.Tab>
              <Tabs.Tab
                selected={tab === 'pool'}
                onClick={() => setTab('pool')}>
                Пул действий
              </Tabs.Tab>
              <Tabs.Tab
                selected={tab === 'profiles'}
                onClick={() => setTab('profiles')}>
                Профили
              </Tabs.Tab>
              <Tabs.Tab
                selected={tab === 'help'}
                onClick={() => setTab('help')}>
                Справочник
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          {tab === 'overview' && <OverviewTab />}
          {tab === 'pool' && <PoolTab />}
          {tab === 'profiles' && <ProfilesTab />}
          {tab === 'help' && <HelpTab />}
        </Stack>
      </Window.Content>
    </Window>
  );
};

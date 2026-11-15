import { BooleanLike } from 'common/react';

import { Box, Table } from '../../components';

export type TransactionEntry = {
  time: string;
  label: string;
  amount: number;
  counterparty: string;
};

export type ContractEntry = {
  uid: number;
  department: string;
  department_name: string;
  title: string;
  desc: string;
  reward: number;
  urgent: BooleanLike;
  time_left: number | null;
  taken_by: string | null;
  taker_id: number | null;
  takeable: BooleanLike;
  /** Работа уже оплачена бюджету: награду целиком делят люди. */
  people_only?: BooleanLike;
  special: BooleanLike;
  rotates_in: number | null;
  started: BooleanLike;
  progress: string;
  kind?: 'department' | 'personal' | 'chain' | 'crew';
  /** Процент награды, который получает взявший контракт. */
  share?: number;
  /** Сколько счетов уже вложилось в контракт без исполнителя. */
  contributors?: number;
  /** Спрос на заказ, проценты награды: падает от повторных сдач. */
  demand?: number;
  stage?: number;
  stages?: number;
  chain_bonus?: number;
  poster?: string | null;
  poster_id?: number | null;
  reported?: BooleanLike;
};

export type ContractRank = {
  name: string;
  rep: number;
  done: number;
  slots: number;
  used: number;
  bonus: number;
  next_name: string | null;
  next_rep: number | null;
};

export type CrewRequestRules = {
  min: number;
  max: number;
  title_max: number;
  desc_max: number;
  minutes: number;
  accept_minutes: number;
};

export type RequestStatus = 'pending' | 'approved' | 'denied';

export type RequestEntry = {
  uid: number;
  pack: string;
  price: number;
  requester: string;
  reason: string;
  status: RequestStatus;
};

export type TreasuryRequestEntry = {
  uid: number;
  department_id: string;
  amount: number;
  requester: string;
  reason: string;
  status: RequestStatus;
};

export type StockEntry = {
  ticker: string;
  name: string;
  price: number;
  change: number;
  halted: BooleanLike;
  history: number[];
};

export type OfferEntry = {
  uid: number;
  partner: string;
  partner_id: string;
  item: string;
  requirement: string;
  quantity: number;
  delivered: number;
  unit_price: number;
  unit_reward: number;
  premium: number;
  reward: number;
  paid: number;
  accepted: BooleanLike;
  station_involved?: BooleanLike;
  contraband: BooleanLike;
  embargoed?: BooleanLike;
  time_left: number;
};

const NBSP = ' ';

type CreditsFormat = {
  signed?: boolean;
  decimals?: number;
};

export const formatCredits = (amount: number | null | undefined, options: CreditsFormat = {}) => {
  if (typeof amount !== 'number' || !Number.isFinite(amount)) {
    return '-';
  }
  const { signed = false, decimals = 0 } = options;
  const [whole, fraction] = Math.abs(amount).toFixed(decimals).split('.');
  const grouped = whole.replace(/\B(?=(\d{3})+(?!\d))/g, NBSP);
  const isZero = Number(Math.abs(amount).toFixed(decimals)) === 0;
  const sign = isZero ? '' : amount < 0 ? '-' : signed ? '+' : '';
  return `${sign}${grouped}${fraction ? '.' + fraction : ''}${NBSP}кр.`;
};

export const Credits = (props: { amount: number | null | undefined } & CreditsFormat) => {
  const { amount, ...options } = props;
  return <>{formatCredits(amount, options)}</>;
};

const trendColor = (value: number) => (value > 0 ? 'good' : value < 0 ? 'bad' : undefined);

export const ChangeBadge = (props: { percent: number }) => {
  const percent = Math.round(props.percent * 10) / 10;
  const arrow = percent > 0 ? '▲ +' : percent < 0 ? '▼ ' : '';
  return (
    <Box inline nowrap color={trendColor(percent)}>
      {arrow}
      {percent}%
    </Box>
  );
};

/** Логотип партнёра (по id) или компании (по тикеру) из спрайтшита economy_logos. */
export const EconomyLogo = (props: { id: string }) => (
  <Box
    inline
    className={`economy_logos32x32 logo-${props.id.toLowerCase()}`}
    style={{ verticalAlign: 'middle', marginRight: '0.5em' }}
  />
);

const SPARK_SIZE = 100;

export const Sparkline = (props: { values: number[]; color?: string; width?: string; height?: string }) => {
  const { values, width = '6em', height = '1.5em' } = props;
  if (values.length < 2) {
    return null;
  }
  const min = Math.min(...values);
  const span = Math.max(...values) - min;
  const step = SPARK_SIZE / (values.length - 1);
  const points = values
    .map((value, index) => {
      const y = span ? SPARK_SIZE - ((value - min) / span) * SPARK_SIZE : SPARK_SIZE / 2;
      return `${Math.round(index * step * 100) / 100},${Math.round(y * 100) / 100}`;
    })
    .join(' ');
  const color = props.color ?? trendColor(values[values.length - 1] - values[0]) ?? 'label';
  return (
    <Box inline width={width} height={height} color={color} verticalAlign="middle">
      <svg
        viewBox={`0 0 ${SPARK_SIZE} ${SPARK_SIZE}`}
        preserveAspectRatio="none"
        width="100%"
        height="100%"
        aria-hidden="true">
        <polyline
          points={points}
          fill="none"
          stroke="currentColor"
          strokeWidth={2}
          vectorEffect="non-scaling-stroke"
        />
      </svg>
    </Box>
  );
};

export const HistoryTable = (props: { entries: TransactionEntry[]; emptyText?: string }) => {
  const { entries, emptyText = 'Операций пока нет.' } = props;
  if (!entries.length) {
    return <Box color="label">{emptyText}</Box>;
  }
  return (
    <Table>
      {[...entries].reverse().map((entry, index) => (
        <Table.Row key={index}>
          <Table.Cell collapsing color="label">
            {entry.time}
          </Table.Cell>
          <Table.Cell>{entry.label}</Table.Cell>
          <Table.Cell color="label">{entry.counterparty}</Table.Cell>
          <Table.Cell collapsing textAlign="right" nowrap color={trendColor(entry.amount)}>
            {formatCredits(entry.amount, { signed: true })}
          </Table.Cell>
        </Table.Row>
      ))}
    </Table>
  );
};

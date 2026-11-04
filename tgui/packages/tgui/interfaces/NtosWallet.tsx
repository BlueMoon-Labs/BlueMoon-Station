import { BooleanLike } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  Dropdown,
  Input,
  LabeledList,
  NoticeBox,
  RestrictedInput,
  Section,
  Stack,
  Table,
  Tabs,
} from '../components';
import { NtosWindow } from '../layouts';
import { ContractTable } from './common/ContractTable';
import { ContractEntry, Credits, HistoryTable, TransactionEntry } from './common/Economy';

type Wage = {
  grade: string | null;
  department: string | null;
  base: number;
  bonus: number;
  amount: number;
  floor_only?: BooleanLike;
  tax_rate: number;
  owed: number;
};

type Lottery = {
  price: number;
  house_share: number;
  per_account: number;
  sold: number;
  prize: number;
  minutes_left: number;
  mine: number;
};

type ShareEntry = {
  ticker: string;
  name: string;
  count: number;
  value: number;
};

export type WalletData = {
  message: string;
  metadollars_available: BooleanLike;
  metadollars: number;
  transfer_max: number;
  transfer_cooldown: number;
  memo_max: number;
  name_max: number;
  audit_rights: string;
  owed_cap: number;
  wage_floor: number;
  tax_nt_share?: number;
  wage_interval: number;
  dormant_minutes: number;
  performer_share: number;
  contracts_help: string;
  crew: string[];
  has_account: BooleanLike;
  lottery?: Lottery | null;
  from_card?: BooleanLike;
  holder?: string;
  number?: number;
  balance?: number;
  state?: 'active' | 'frozen' | 'dormant';
  blocked?: BooleanLike;
  anonymous?: BooleanLike;
  personal?: BooleanLike;
  frozen_by?: string | null;
  freeze_reason?: string | null;
  freeze_source?: string | null;
  cooldown_left?: number;
  wage?: Wage;
  history?: TransactionEntry[];
  contracts?: ContractEntry[];
  my_account?: number;
  shares?: ShareEntry[];
  portfolio?: number;
};

type Tab = 'account' | 'transfer' | 'jobs' | 'shares' | 'meta';

const TABS: [Tab, string, string][] = [
  ['account', 'Счёт', 'wallet'],
  ['transfer', 'Перевод', 'paper-plane'],
  ['jobs', 'Подработка', 'briefcase'],
  ['shares', 'Акции', 'chart-line'],
  ['meta', 'Метадоллары', 'coins'],
];

export const NtosWallet = () => (
  <NtosWindow width={560} height={640}>
    <NtosWindow.Content scrollable>
      <NtosWalletContent />
    </NtosWindow.Content>
  </NtosWindow>
);

export const NtosWalletContent = () => {
  const { data } = useBackend<WalletData>();
  const [tab, setTab] = useState<Tab>('account');
  const needsAccount = tab !== 'meta' && !data.has_account;
  return (
    <>
      <Tabs>
        {TABS.map(([id, label, icon]) => (
          <Tabs.Tab key={id} icon={icon} selected={tab === id} onClick={() => setTab(id)}>
            {label}
          </Tabs.Tab>
        ))}
      </Tabs>
      {!!data.message && <NoticeBox info>{data.message}</NoticeBox>}
      {needsAccount ? (
        <NoticeBox>Счёт не найден: вставьте в КПК ID-карту со счётом.</NoticeBox>
      ) : (
        <>
          {tab === 'account' && <AccountTab />}
          {tab === 'transfer' && <TransferTab />}
          {tab === 'jobs' && <JobsTab />}
          {tab === 'shares' && <SharesTab />}
          {tab === 'meta' && <MetaTab />}
        </>
      )}
    </>
  );
};

const AccountNotices = () => {
  const { data } = useBackend<WalletData>();
  return (
    <>
      {data.state === 'frozen' && (
        <NoticeBox danger>
          Счёт заморожен {data.freeze_source || 'финансовым аудитом'}
          {data.freeze_reason ? `: ${data.freeze_reason}` : ''}. Переводы, чаевые, покупки, снятие наличных и сделки
          с акциями закрыты. Поступления принимаются, налоги, долги и возвраты по делам аудита списываются. Зарплата не
          выплачивается, а копится долгом отдела (до {data.owed_cap} базовых окладов) и придёт с первой зарплатой
          после разморозки.
        </NoticeBox>
      )}
      {!!data.blocked && (
        <NoticeBox danger>Счёт заблокирован в базе счетов: личные платежи с него и на него не проходят.</NoticeBox>
      )}
      {data.state === 'dormant' && (
        <NoticeBox warning>
          Счёт спит: владелец дольше {data.dormant_minutes} мин. мёртв или без связи. Зарплата не начисляется и в долг не
          копится, по имени счёт не находится - переводы на него только по номеру.
        </NoticeBox>
      )}
      {!!data.anonymous && (
        <NoticeBox>
          Анонимный счёт: без зарплаты и контрактов. Аудит видит движения по нему и след денег, каждое снятие наличных
          открывает дело с местом снятия.
        </NoticeBox>
      )}
      {!data.anonymous && !data.personal && (
        <NoticeBox warning>Это не личный счёт: переводы и чаевые с него и на него не проходят.</NoticeBox>
      )}
    </>
  );
};

const WageSection = () => {
  const { data } = useBackend<WalletData>();
  const wage = data.wage;
  if (!wage) {
    return null;
  }
  return (
    <Section title="Зарплата">
      <LabeledList>
        {wage.floor_only ? (
          <LabeledList.Item label="Выплата">
            {wage.grade ? `Грейд ${wage.grade}, но отдел не назначен` : 'Оклада нет'}: отдел не платит, NT платит
            минимум <Credits amount={data.wage_floor} /> раз в {data.wage_interval} мин.
          </LabeledList.Item>
        ) : wage.grade ? (
          <>
            <LabeledList.Item label="Грейд">
              {wage.grade}
              {wage.department ? `, отдел: ${wage.department}` : ''}
            </LabeledList.Item>
            <LabeledList.Item label="Выплата">
              <Credits amount={wage.base} /> + надбавка {wage.bonus}% = <Credits amount={wage.amount} /> раз в{' '}
              {data.wage_interval} мин.
            </LabeledList.Item>
          </>
        ) : (
          <LabeledList.Item label="Выплата">Не начисляется: у должности нет оклада.</LabeledList.Item>
        )}
        <LabeledList.Item label="Налог">
          Налог {wage.tax_rate}% удерживается с зарплаты, премий (от главы и за работу) и доли контрактов,{' '}
          {data.tax_nt_share ?? 0}% налога забирает NT, остальное получает казна. Без налога: доплата NT до минимума,
          переводы и чаевые.
        </LabeledList.Item>
        {wage.owed > 0 && (
          <LabeledList.Item label="Отдел должен" color="average">
            <Credits amount={wage.owed} />
          </LabeledList.Item>
        )}
      </LabeledList>
      <Box color="label" mt={1}>
        Зарплату платит бюджет отдела. Если денег в нём не хватает, недоплата копится долгом отдела (до {data.owed_cap}{' '}
        базовых окладов) и выплачивается со следующей зарплатой. Если отдел заплатил меньше{' '}
        <Credits amount={data.wage_floor} />, NT доплачивает до этой суммы без налога.
      </Box>
    </Section>
  );
};

const LotterySection = () => {
  const { act, data } = useBackend<WalletData>();
  const { lottery } = data;
  if (!lottery) {
    return null;
  }
  const left = lottery.per_account - lottery.mine;
  return (
    <Section title="Лотерея сектора">
      <LabeledList>
        <LabeledList.Item label="Билет">
          <Credits amount={lottery.price} />, ваших {lottery.mine} из {lottery.per_account}
        </LabeledList.Item>
        <LabeledList.Item label="Продано">{lottery.sold}</LabeledList.Item>
        <LabeledList.Item label="Выигрыш сейчас">
          <Credits amount={lottery.prize} />
        </LabeledList.Item>
        <LabeledList.Item label="Розыгрыш">через {lottery.minutes_left} мин.</LabeledList.Item>
      </LabeledList>
      <Box color="label" my={1}>
        Один билет выигрывает {100 - lottery.house_share}% всех продаж, {lottery.house_share}% забирает NT. Шанс
        растёт с числом ваших билетов.
      </Box>
      <Button icon="ticket-alt" disabled={left < 1} onClick={() => act('lottery_buy', { count: 1 })}>
        Купить билет
      </Button>
      <Button icon="ticket-alt" disabled={left < 5} onClick={() => act('lottery_buy', { count: 5 })}>
        Купить 5
      </Button>
    </Section>
  );
};

const AccountTab = () => {
  const { data } = useBackend<WalletData>();
  return (
    <>
      <AccountNotices />
      <Section title={`${data.holder} · №${data.number}`}>
        <LabeledList>
          <LabeledList.Item label="Баланс">
            <Box bold fontSize={1.4}>
              <Credits amount={data.balance} />
            </Box>
          </LabeledList.Item>
          <LabeledList.Item label="Источник">
            {data.from_card ? 'ID-карта в КПК' : 'Ваш личный счёт (карта в КПК не вставлена)'}
          </LabeledList.Item>
        </LabeledList>
      </Section>
      <LotterySection />
      <WageSection />
      <Section title="История">
        <HistoryTable entries={data.history || []} />
      </Section>
      <Box color="label">
        Финансовый аудит ({data.audit_rights}) видит движения по счёту и след денег. Дело открывают: серия частых
        переводов одному человеку, списания с неопознанных устройств, крупные выплаты из бюджета отдела одному
        человеку, премия главы самому себе, снятие наличных с анонимного счёта, сделки с акциями перед новостью о
        компании. Зарплата, налоги, чаевые, оплата работы и контрактов, единичные переводы дел не открывают.
      </Box>
    </>
  );
};

const TransferTab = () => {
  const { act, data } = useBackend<WalletData>();
  const [target, setTarget] = useState('');
  const [amount, setAmount] = useState(10);
  const [memo, setMemo] = useState('');
  const cooldown = data.cooldown_left || 0;
  const ready = target.trim().length > 0 && amount >= 1;
  return (
    <>
      <AccountNotices />
      <Section title="Перевод и чаевые">
        <Box color="label" mb={1}>
          Только с личного счёта на личный: бюджеты отделов и системные счета не принимают. Без налога, до{' '}
          <Credits amount={data.transfer_max} /> за раз, не чаще раза в {data.transfer_cooldown} с - переводы и чаевые
          делят этот кулдаун. По имени - только если владелец с таким именем один, иначе укажите номер счёта.
        </Box>
        <LabeledList>
          <LabeledList.Item label="Кому">
            <Stack>
              <Stack.Item grow>
                <Input
                  fluid
                  value={target}
                  maxLength={data.name_max}
                  placeholder="Имя или номер счёта"
                  onInput={(_, value) => setTarget(value)}
                />
              </Stack.Item>
              {data.crew.length > 0 && (
                <Stack.Item>
                  <Dropdown
                    width="12em"
                    options={data.crew}
                    selected={null}
                    displayText="Из манифеста"
                    onSelected={(value) => setTarget(value)}
                  />
                </Stack.Item>
              )}
            </Stack>
          </LabeledList.Item>
          <LabeledList.Item label="Сумма">
            <RestrictedInput
              value={amount}
              minValue={1}
              maxValue={data.transfer_max}
              onChange={(_, value) => setAmount(value)}
            />{' '}
            кр.
          </LabeledList.Item>
          <LabeledList.Item label="Назначение">
            <Input
              fluid
              value={memo}
              maxLength={data.memo_max}
              placeholder="Необязательно, только для перевода"
              onInput={(_, value) => setMemo(value)}
            />
          </LabeledList.Item>
        </LabeledList>
        {cooldown > 0 && (
          <Box color="average" mt={1}>
            Следующий платёж через {cooldown} с.
          </Box>
        )}
        <Stack mt={1}>
          <Stack.Item>
            <Button
              icon="paper-plane"
              disabled={!ready}
              onClick={() => act('transfer', { target: target.trim(), amount, memo })}>
              Перевести
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="hand-holding-usd"
              disabled={!ready}
              onClick={() => act('tip', { target: target.trim(), amount })}>
              Чаевые
            </Button>
          </Stack.Item>
        </Stack>
      </Section>
    </>
  );
};

const JobsTab = () => {
  const { data } = useBackend<WalletData>();
  return (
    <Section title="Контракты NT">
      {!!data.contracts_help && (
        <Box color="label" mb={1}>
          {data.contracts_help}
        </Box>
      )}
      <ContractTable showShare={false} />
    </Section>
  );
};

const SharesTab = () => {
  const { data } = useBackend<WalletData>();
  const shares = data.shares || [];
  return (
    <Section title="Портфель" buttons={<Credits amount={data.portfolio} />}>
      <Box color="label" mb={1}>
        Стоимость по текущей цене, без спреда и комиссии. Купить и продать акции можно в приложении «Биржа».
      </Box>
      {shares.length === 0 ? (
        <Box color="label">Акций нет.</Box>
      ) : (
        <Table>
          {shares.map((share) => (
            <Table.Row key={share.ticker}>
              <Table.Cell bold collapsing>
                {share.ticker}
              </Table.Cell>
              <Table.Cell color="label">{share.name}</Table.Cell>
              <Table.Cell collapsing>{share.count} шт.</Table.Cell>
              <Table.Cell collapsing textAlign="right">
                <Credits amount={share.value} />
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      )}
    </Section>
  );
};

const MetaTab = () => {
  const { act, data } = useBackend<WalletData>();
  const [amount, setAmount] = useState(1);
  return (
    <Section title="Метадоллары">
      <Box color="label" mb={1}>
        Метадоллары (M$) - ваш постоянный счёт между сменами, отдельный от кредитов станции. Кредиты в M$ и обратно не
        обмениваются.
      </Box>
      {!data.metadollars_available ? (
        <NoticeBox danger>Нет связи с вашим счётом метадолларов.</NoticeBox>
      ) : (
        <LabeledList>
          <LabeledList.Item label="Баланс">
            <Box bold>{data.metadollars} M$</Box>
          </LabeledList.Item>
          <LabeledList.Item label="Снять наличными">
            <RestrictedInput
              value={amount}
              minValue={1}
              maxValue={Math.max(data.metadollars, 1)}
              onChange={(_, value) => setAmount(value)}
            />{' '}
            <Button icon="money-bill-wave" disabled={amount < 1} onClick={() => act('md_withdraw', { amount })}>
              Снять
            </Button>
          </LabeledList.Item>
          <LabeledList.Item label="Зачислить">
            <Button icon="hand-holding-usd" onClick={() => act('md_deposit')}>
              Зачислить стопку из руки
            </Button>
            <Box color="label">Возьмите стопку метадолларов в активную руку.</Box>
          </LabeledList.Item>
        </LabeledList>
      )}
    </Section>
  );
};

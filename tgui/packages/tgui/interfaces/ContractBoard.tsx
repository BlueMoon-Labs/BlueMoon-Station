import { BooleanLike } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../backend';
import { AnimatedNumber, Box, Button, RestrictedInput, Stack } from '../components';
import { Window } from '../layouts';
import { ContractTable } from './common/ContractTable';
import { formatCredits } from './common/Economy';
import { NtEmpty, NtFrame, NtHelpTopic, NtHelpTopics, NtLine, NtReadout, NtScreen } from './common/NtTerminal';

type PadItem = { ref: string; name: string; problem: string | null };

type AuctionPad = {
  items: PadItem[];
  minutes: number[];
  fee: number;
  min_price: number;
  max_price: number;
  mine: number;
  per_account: number;
  lots: number;
  lots_max: number;
};

type ContractBoardData = {
  mode: 'pad' | 'console';
  contracts_help_topics?: NtHelpTopic[];
  my_name?: string | null;
  pad?: BooleanLike;
  pad_on_station?: BooleanLike;
  sending?: BooleanLike;
  status_report?: string;
  stored_cash?: number;
  auction?: AuctionPad;
};

const PadSection = (props) => {
  const { act, data } = useBackend<ContractBoardData>();
  const { pad, pad_on_station, sending, status_report } = data;
  return (
    <NtFrame
      title="Пад подработки"
      help="Положите на пад то, что просят контракты поставки, и отправьте: подходящее уйдёт ЦК, остальное останется на месте. Награда сразу зачисляется на счёт взявшего и отдела, ничего сдавать в снабжение не нужно."
      buttons={
        <>
          <Button icon="sync" content="Проверить" disabled={!pad} onClick={() => act('recalc')} />
          <Button
            icon={sending ? 'times' : 'arrow-up'}
            content={sending ? 'Отменить' : 'Отправить'}
            selected={sending}
            disabled={!pad}
            onClick={() => act(sending ? 'stop' : 'send')}
          />
        </>
      }>
      <NtLine label="Пад" tone={pad && pad_on_station ? 'good' : 'bad'}>
        {!pad ? 'Не найден' : pad_on_station ? 'На связи' : 'Вне станции'}
      </NtLine>
      <NtLine label="Отчёт">{status_report || '-'}</NtLine>
    </NtFrame>
  );
};

/** Аукцион экипажа: своя вещь с пада уходит на торги экипажа. */
const AuctionPadSection = (props) => {
  const { act, data } = useBackend<ContractBoardData>();
  const auction = data.auction;
  const [selected, setSelected] = useState<string | null>(null);
  const [price, setPrice] = useState<number | null>(null);
  const [minutes, setMinutes] = useState<number | null>(null);
  const [anonymous, setAnonymous] = useState(false);
  if (!auction) {
    return null;
  }
  const allowed = auction.items.filter((item) => !item.problem);
  const chosen = allowed.find((item) => item.ref === selected) || allowed[0];
  const duration = minutes !== null && auction.minutes.includes(minutes) ? minutes : auction.minutes[0];
  const start = Math.min(Math.max(price ?? auction.min_price * 4, auction.min_price), auction.max_price);
  let refusal: string | null = null;
  if (!data.my_name) {
    refusal = 'Нужен банковский счёт: вставьте ID-карту.';
  } else if (!data.pad_on_station) {
    refusal = 'Пад вне станции.';
  } else if (auction.mine >= auction.per_account) {
    refusal = `Больше лотов сразу не выставить: ваших на торгах уже ${auction.mine} из ${auction.per_account}.`;
  } else if (auction.lots >= auction.lots_max) {
    refusal = 'На аукционе нет мест, загляните позже.';
  } else if (!chosen) {
    refusal = 'На паде нет вещи, которую можно выставить.';
  }
  return (
    <NtFrame
      title="Аукцион экипажа"
      help={`Положите на пад свою вещь и выставьте её: торгуется только экипаж, ставки - в Кошельке на КПК и в консоли снабжения. Продавцу приходит ставка без сбора NT ${auction.fee}%, покупателю - запертая посылка на его имя на склад снабжения. Без ставок или снятая до первой ставки вещь вернётся к вам такой же посылкой. Оружие, импланты и органы, ID-карты и всё с доступом, деньги, контрабанда, живые существа и непустые контейнеры не принимаются.`}>
      {auction.items.length === 0 ? (
        <NtEmpty>Положите на пад вещь, которую хотите продать экипажу.</NtEmpty>
      ) : (
        auction.items.map((item) => (
          <NtLine
            key={item.ref}
            label={
              <Button.Checkbox
                checked={item === chosen}
                disabled={!!item.problem}
                onClick={() => setSelected(item.ref)}>
                {item.name}
              </Button.Checkbox>
            }
            tone={item.problem ? 'bad' : undefined}>
            {item.problem || 'можно выставить'}
          </NtLine>
        ))
      )}
      <Stack align="center" mt={1} wrap>
        <Stack.Item>
          Старт{' '}
          <RestrictedInput
            width="6em"
            value={start}
            minValue={auction.min_price}
            maxValue={auction.max_price}
            onChange={(_, value) => setPrice(value)}
          />{' '}
          кр.
        </Stack.Item>
        <Stack.Item>
          {auction.minutes.map((option) => (
            <Button key={option} selected={option === duration} onClick={() => setMinutes(option)}>
              {`${option} мин.`}
            </Button>
          ))}
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox checked={anonymous} onClick={() => setAnonymous(!anonymous)}>
            Скрыть моё имя
          </Button.Checkbox>
        </Stack.Item>
      </Stack>
      <Stack align="center" mt={1}>
        <Stack.Item>
          <Button
            icon="gavel"
            color="good"
            disabled={!!refusal}
            tooltip={refusal}
            onClick={() => chosen && act('auction_list', { ref: chosen.ref, price: start, minutes: duration, anonymous })}>
            {chosen ? `Выставить: ${chosen.name}` : 'Выставить'}
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Box className="NtTerm__hint">
            Ваших лотов {auction.mine} из {auction.per_account}, на аукционе {auction.lots} из {auction.lots_max}.
          </Box>
        </Stack.Item>
      </Stack>
    </NtFrame>
  );
};

/** Доска контрактов NT: пункт подработки с падом и консоль контрактов снабжения. */
export const ContractBoardContent = (props) => {
  const { act, data } = useBackend<ContractBoardData>();
  const { mode, contracts_help_topics, my_name, stored_cash } = data;
  return (
    <NtScreen
      tone="contracts"
      device={mode === 'pad' ? 'Пункт подработки' : 'Доска контрактов'}
      status={my_name ? `Счёт: ${my_name}` : 'Банковский счёт не найден: контракт не взять.'}
      readout={
        mode === 'console' ? (
          <NtReadout label="Бюджет снабжения">
            <AnimatedNumber value={stored_cash ?? 0} format={(value) => formatCredits(value)} />
          </NtReadout>
        ) : undefined
      }>
      {mode === 'pad' && <PadSection />}
      {mode === 'pad' && <AuctionPadSection />}
      <NtFrame
        title="Контракты NT"
        help={contracts_help_topics?.length ? <NtHelpTopics topics={contracts_help_topics} /> : undefined}
        buttons={mode === 'console' && <Button icon="print" content="Распечатать" onClick={() => act('Print')} />}>
        <ContractTable />
      </NtFrame>
    </NtScreen>
  );
};

export const ContractBoard = (props) => {
  return (
    <Window width={760} height={600} resizable>
      <Window.Content scrollable>
        <ContractBoardContent />
      </Window.Content>
    </Window>
  );
};

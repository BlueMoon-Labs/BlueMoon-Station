import { BooleanLike } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../../backend';
import { Box, Button, RestrictedInput, Stack } from '../../components';
import { formatCredits } from './Economy';

/** AUCTION_BID_MAX: больше лот не принимает. */
export const AUCTION_BID_MAX = 100000;

export type AuctionBidLot = {
  uid: number;
  bid: number;
  /** Ведёт ставка этого счёта: к ней доплачивается только разница. */
  mine?: BooleanLike;
  min_bid: number;
  increment: number;
  /** Дороже стольких процентов оценки станции-соперники не дают. */
  rival_cap?: number | null;
  /** Столько самое большее дадут станции-соперники. */
  rival_ceiling?: number | null;
  /** Наименьшая ставка, которую станции-соперники уже не перебьют; null - перебивать некого. */
  outbid_price?: number | null;
};

/** Сколько спишут со счёта за ставку amount. */
export const auctionBidCost = (lot: AuctionBidLot, amount: number) => amount - (lot.mine ? lot.bid : 0);

/** Почему ставку amount не поставить; null - можно. buyout - цена выкупа лота экипажа, ставка до неё не доходит. */
export const auctionBidRefusal = (lot: AuctionBidLot, amount: number, balance?: number | null, buyout = 0) => {
  if (!Number.isInteger(amount)) {
    return 'Ставка - целое число кредитов.';
  }
  if (amount < lot.min_bid) {
    return lot.bid
      ? `Мало: сейчас ставка ${formatCredits(lot.bid)}, шаг ${formatCredits(lot.increment)} - ставьте от ${formatCredits(lot.min_bid)}`
      : `Мало: торги начинаются с ${formatCredits(lot.min_bid)}`;
  }
  if (buyout && amount >= buyout) {
    return `Столько не поставить: лот можно сразу купить за ${formatCredits(buyout)}`;
  }
  if (amount > AUCTION_BID_MAX) {
    return `Больше ${formatCredits(AUCTION_BID_MAX)} не принимается.`;
  }
  const cost = auctionBidCost(lot, amount);
  if (typeof balance === 'number' && balance < cost) {
    return `Не хватает денег на счёте: нужно ${formatCredits(cost)}`;
  }
  return null;
};

type AuctionBidEntryProps = {
  lot: AuctionBidLot;
  /** Баланс счёта, с которого ставят; null - окно его не знает. */
  balance?: number | null;
  buyout?: number;
  /** Кнопки «Минимум» и «+2 шага» рядом с полем. */
  steps?: boolean;
};

/** Ставка своей суммой: вписал и нажал «Поставить» или Enter; «Перебить соперников» ставит сумму, которую станции сектора уже не перебьют. */
export const AuctionBidEntry = (props: AuctionBidEntryProps) => {
  const { act } = useBackend();
  const { lot, balance, buyout = 0, steps } = props;
  const [amount, setAmount] = useState<number | null>(null);
  const bid = amount ?? lot.min_bid;
  const refusal = auctionBidRefusal(lot, bid, balance, buyout);
  const place = (value: number) => {
    if (auctionBidRefusal(lot, value, balance, buyout)) {
      setAmount(value);
      return;
    }
    act('auction_bid', { uid: lot.uid, amount: value });
    setAmount(null);
  };
  const outbid = lot.outbid_price || 0;
  const outbidCost = outbid ? auctionBidCost(lot, outbid) : 0;
  const outbidShort = !!outbid && typeof balance === 'number' && balance < outbidCost;
  return (
    <Box>
      <Stack align="center" wrap>
        <Stack.Item>
          <RestrictedInput
            width="7em"
            value={bid}
            minValue={0}
            maxValue={AUCTION_BID_MAX}
            onChange={(_, value) => setAmount(value)}
            onEnter={(_, value) => place(value)}
          />{' '}
          кр.
        </Stack.Item>
        {steps && (
          <Stack.Item>
            <Button onClick={() => setAmount(lot.min_bid)}>Минимум</Button>
            <Button onClick={() => setAmount(lot.min_bid + lot.increment * 2)}>+2 шага</Button>
          </Stack.Item>
        )}
        <Stack.Item>
          <Button color="good" icon="gavel" disabled={!!refusal} tooltip={refusal} onClick={() => place(bid)}>
            {`Поставить ${formatCredits(bid)}`}
          </Button>
        </Stack.Item>
        {!!outbid && (
          <Stack.Item>
            <Button
              icon="angle-double-up"
              disabled={outbidShort}
              tooltip={
                outbidShort
                  ? `Не хватает денег на счёте: нужно ${formatCredits(outbidCost)}`
                  : `Станции сектора дают не больше ${lot.rival_cap ?? 0}% оценки (${formatCredits(lot.rival_ceiling)}): после этой ставки они её уже не перебьют, а экипаж - может.${lot.mine ? ` Доплатите только разницу: ${formatCredits(outbidCost)}` : ''}`
              }
              onClick={() => act('auction_bid', { uid: lot.uid, outbid: true, amount: outbid })}>
              {`Перебить соперников: ${formatCredits(outbid)}`}
            </Button>
          </Stack.Item>
        )}
      </Stack>
      {!!refusal && (
        <Box color="average" mt={0.5}>
          {refusal}
        </Box>
      )}
    </Box>
  );
};

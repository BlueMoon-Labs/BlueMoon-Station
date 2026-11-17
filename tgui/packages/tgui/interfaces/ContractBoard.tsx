import { BooleanLike } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../backend';
import { AnimatedNumber, Box, Button, NoticeBox, ProgressBar, RestrictedInput, Stack } from '../components';
import { Window } from '../layouts';
import {
  BoardReset,
  BoardResets,
  ContractRow,
  CrewRequestForm,
  formatTimeLeft,
  isMine,
  isMyPost,
  PartnerOfferRow,
} from './common/ContractTable';
import { ContractEntry, ContractRank, CrewRequestRules, formatCredits, OfferEntry } from './common/Economy';
import { NtEmpty, NtFrame, NtHelpTopic, NtHelpTopics, NtLine, NtMenu, NtMenuItem, NtReadout, NtScreen } from './common/NtTerminal';

type PadItem = { ref: string; name: string; problem: string | null; inscription?: string | null };

type AuctionPad = {
  items: PadItem[];
  minutes: number[];
  fee: number;
  min_price: number;
  max_price: number;
  /** Секунд до нового лота после снятия своего, 0 - можно. */
  relist_left?: number;
  mine: number;
  per_account: number;
  lots: number;
  lots_max: number;
};

type ContractBoardData = {
  mode: 'pad' | 'console';
  contracts_help_topics?: NtHelpTopic[];
  my_name?: string | null;
  my_account?: number | null;
  contracts?: ContractEntry[];
  partner_offers?: OfferEntry[];
  performer_share?: number;
  rank?: ContractRank | null;
  reroll_left?: number;
  board_resets?: BoardReset[];
  crew_request?: CrewRequestRules;
  pad?: BooleanLike;
  pad_on_station?: BooleanLike;
  sending?: BooleanLike;
  status_report?: string;
  stored_cash?: number;
  auction?: AuctionPad;
};

type Tab = 'board' | 'mine' | 'crew' | 'offers' | 'auction';

/** Пад подработки: всегда над вкладками, это главное действие пульта. */
const PadSection = () => {
  const { act, data } = useBackend<ContractBoardData>();
  const { pad, pad_on_station, sending, status_report } = data;
  return (
    <NtFrame
      title="Пад подработки"
      help="Положите на пад то, что просят контракты поставки или спецзаказы партнёров, и отправьте: подходящее уйдёт ЦК, остальное останется на месте. Награда сразу зачисляется на счёт взявшего и отдела, ничего сдавать в снабжение не нужно."
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

type BoardFilter = 'all' | 'free' | 'personal' | string;

/** Доска: контракты отделов, серии и личные заказы; объявления экипажа - на своей вкладке. */
const BoardTab = () => {
  const { act, data } = useBackend<ContractBoardData>();
  const { contracts = [], my_account, performer_share, rank, reroll_left = 0, board_resets = [], contracts_help_topics } = data;
  const [filter, setFilter] = useState<BoardFilter>('all');
  const board = contracts.filter((contract) => contract.kind !== 'crew');
  const canAct = !!my_account && !!rank;
  const departments = board.map((contract) => contract.department_name).filter((name, index, all) => all.indexOf(name) === index);
  const free = board.filter((contract) => !contract.taken_by && !!contract.takeable).length;
  const personal = board.filter((contract) => contract.kind === 'personal').length;
  const filters: [BoardFilter, string][] = [
    ['all', `Все (${board.length})`],
    ['free', `Свободные (${free})`],
    ...(personal ? ([['personal', `Личные (${personal})`]] as [BoardFilter, string][]) : []),
    ...(departments.length > 1 ? departments.map((name) => [`dep:${name}`, name] as [BoardFilter, string]) : []),
  ];
  const shown = board.filter((contract) => {
    if (filter === 'free') {
      return !contract.taken_by && !!contract.takeable;
    }
    if (filter === 'personal') {
      return contract.kind === 'personal';
    }
    if (filter.startsWith('dep:')) {
      return contract.department_name === filter.slice(4);
    }
    return true;
  });
  const tools = (
    <>
      {canAct && personal > 0 && (
        <Button
          icon="sync"
          disabled={reroll_left > 0}
          tooltip={reroll_left > 0 ? `Обновить можно через ${formatTimeLeft(reroll_left)}` : 'Невзятые личные заказы сменятся на новые.'}
          onClick={() => act('reroll')}>
          Обновить личные
        </Button>
      )}
      {data.mode === 'console' && <Button icon="print" content="Распечатать" onClick={() => act('Print')} />}
    </>
  );
  return (
    <NtFrame
      title="Контракты NT"
      buttons={tools}
      help={contracts_help_topics?.length ? <NtHelpTopics topics={contracts_help_topics} /> : undefined}>
      {board_resets.length > 0 && <BoardResets resets={board_resets} />}
      {!board.length ? (
        <NoticeBox>Контрактов сейчас нет.</NoticeBox>
      ) : (
        <div className="NtTerm__chips">
          {filters.map(([key, label]) => (
            <span key={key} className={filter === key ? 'NtTerm__chip NtTerm__chip--active' : 'NtTerm__chip'} onClick={() => setFilter(key)}>
              {label}
            </span>
          ))}
        </div>
      )}
      {board.length > 0 && !shown.length && <NtEmpty>Под этот фильтр контрактов нет.</NtEmpty>}
      {shown.map((contract) => (
        <ContractRow key={contract.uid} contract={contract} myAccount={my_account} />
      ))}
      {board.length > 0 && <Box className="NtTerm__hint" mt={1}>Взявший контракт получает {performer_share}% награды, остальное - отделу.</Box>}
    </NtFrame>
  );
};

/** Репутация подрядчика: ранг, путь до следующего, занятые слоты и надбавка NT. */
const RankCard = (props: { rank: ContractRank }) => {
  const { rank } = props;
  const next = rank.next_name && rank.next_rep ? rank.next_rep : null;
  return (
    <NtFrame title="Репутация подрядчика" help="Репутация растёт за выполненные контракты и падает за отказ от взятых. С рангом растут число контрактов, которые можно держать сразу, и надбавка NT к вашей доле.">
      <NtLine label="Ранг">
        <span className="NtTerm__rankName">{rank.name}</span>, репутация {rank.rep}
      </NtLine>
      {next ? (
        <ProgressBar value={Math.min(rank.rep / next, 1)} mb={0.5}>
          До ранга «{rank.next_name}»: ещё {next - rank.rep}
        </ProgressBar>
      ) : (
        <Box className="NtTerm__hint" mb={0.5}>
          Высший ранг
        </Box>
      )}
      <NtLine label="Контракты" tone={rank.used >= rank.slots ? 'warn' : undefined}>
        взято {rank.used} из {rank.slots}, выполнено {rank.done}
      </NtLine>
      {!!rank.bonus && <NtLine label="Надбавка NT">+{rank.bonus}% к вашей доле</NtLine>}
    </NtFrame>
  );
};

/** Мои: репутация, взятые контракты и свои объявления. */
const MineTab = () => {
  const { data } = useBackend<ContractBoardData>();
  const { contracts = [], my_account, rank } = data;
  const mine = contracts.filter((contract) => isMine(contract, my_account) || isMyPost(contract, my_account));
  return (
    <>
      {!!rank && <RankCard rank={rank} />}
      <NtFrame title="Взятые контракты и ваши объявления">
        {mine.length ? (
          mine.map((contract) => <ContractRow key={contract.uid} contract={contract} myAccount={my_account} />)
        ) : (
          <NtEmpty>{my_account ? 'Вы ничего не взяли. Свободные контракты - на вкладке «Доска».' : 'Банковский счёт не найден: контракт не взять.'}</NtEmpty>
        )}
      </NtFrame>
    </>
  );
};

/** Экипаж: объявления членов экипажа и форма своего. */
const CrewTab = () => {
  const { data } = useBackend<ContractBoardData>();
  const { contracts = [], my_account, rank, crew_request } = data;
  const [posting, setPosting] = useState(false);
  const crew = contracts.filter((contract) => contract.kind === 'crew');
  const canPost = !!my_account && !!rank && !!crew_request;
  return (
    <NtFrame
      title="Объявления экипажа"
      help="Работа, о которой просит экипаж. Награда лежит в депозите и целиком, без налога, достаётся исполнителю, когда заказчик примет работу; промолчит - работа будет принята сама."
      buttons={
        canPost && (
          <Button icon="bullhorn" selected={posting} onClick={() => setPosting(!posting)}>
            Дать объявление
          </Button>
        )
      }>
      {posting && !!crew_request && <CrewRequestForm rules={crew_request} onDone={() => setPosting(false)} />}
      {crew.length ? (
        crew.map((contract) => <ContractRow key={contract.uid} contract={contract} myAccount={my_account} />)
      ) : (
        <NtEmpty>Объявлений нет.{canPost ? ' Нужна помощь экипажа - дайте объявление.' : ''}</NtEmpty>
      )}
    </NtFrame>
  );
};

/** Спецзаказы партнёров снабжения: сдаются на паде подработки. */
const OffersTab = () => {
  const { data } = useBackend<ContractBoardData>();
  const offers = data.partner_offers || [];
  return (
    <NtFrame
      title="Спецзаказы партнёров снабжения"
      help="Положите товар на пад подработки и отправьте: оплата за штуки уйдёт вашему отделу, вам лично - доля участника. Купленное через снабжение и в автоматах не засчитывается.">
      {offers.length ? offers.map((offer) => <PartnerOfferRow key={offer.uid} offer={offer} />) : <NtEmpty>Спецзаказов сейчас нет.</NtEmpty>}
    </NtFrame>
  );
};

/** Аукцион экипажа: своя вещь с пада уходит на торги экипажа. */
const AuctionTab = () => {
  const { act, data } = useBackend<ContractBoardData>();
  const auction = data.auction;
  const [selected, setSelected] = useState<string | null>(null);
  const [price, setPrice] = useState<number | null>(null);
  const [minutes, setMinutes] = useState<number | null>(null);
  const [anonymous, setAnonymous] = useState(false);
  const [buyoutOn, setBuyoutOn] = useState(false);
  const [buyoutPrice, setBuyoutPrice] = useState<number | null>(null);
  if (!auction) {
    return null;
  }
  const allowed = auction.items.filter((item) => !item.problem);
  const chosen = allowed.find((item) => item.ref === selected) || allowed[0];
  const duration = minutes !== null && auction.minutes.includes(minutes) ? minutes : auction.minutes[0];
  const start = Math.min(Math.max(price ?? auction.min_price * 4, auction.min_price), auction.max_price);
  const buyout = Math.min(Math.max(buyoutPrice ?? start * 2, start), auction.max_price);
  const relistLeft = auction.relist_left || 0;
  let refusal: string | null = null;
  if (!data.my_name) {
    refusal = 'Нужен банковский счёт: возьмите свою ID-карту в руку или наденьте её.';
  } else if (!data.pad_on_station) {
    refusal = 'Пад вне станции.';
  } else if (relistLeft > 0) {
    refusal = `Вы недавно сняли свой лот: новый можно выставить через ${formatTimeLeft(relistLeft)}.`;
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
      help={`Положите на пад свою вещь и выставьте её: торгуется только экипаж, ставки - в Кошельке на КПК и в консоли снабжения. Можно назначить цену «купить сразу»: тот, кто её заплатит, забирает лот без торгов. Продавцу приходит ставка без сбора NT ${auction.fee}%, покупателю - запертая посылка на его имя капсулой в снабжение. Без ставок или снятая до первой ставки вещь вернётся к вам такой же посылкой на этот пад; после снятия своего лота новый можно выставить не сразу. Лот называется исходным именем вещи, ваша надпись на ней видна отдельно. Оружие и взрывчатка, слишком тяжёлое для удара, магия и вещи антагонистов, импланты и органы, ID-карты и всё с доступом, деньги, контрабанда, вещи на особом учёте NT, живые существа и непустые контейнеры не принимаются.`}>
      <NtLine label="Лоты">
        ваших {auction.mine} из {auction.per_account}, на аукционе {auction.lots} из {auction.lots_max}
      </NtLine>
      <Box className="NtTerm__hint" mb={0.5}>
        Вещь на паде
      </Box>
      {auction.items.length === 0 ? (
        <NtEmpty>Положите на пад вещь, которую хотите продать экипажу.</NtEmpty>
      ) : (
        auction.items.map((item) => (
          <NtLine
            key={item.ref}
            label={
              <Button.Checkbox checked={item === chosen} disabled={!!item.problem} onClick={() => setSelected(item.ref)}>
                {item.name}
              </Button.Checkbox>
            }
            tone={item.problem ? 'bad' : undefined}>
            {item.problem || 'можно выставить'}
            {!!item.inscription && <Box className="NtTerm__hint">надпись: {item.inscription}</Box>}
          </NtLine>
        ))
      )}
      <Stack align="center" mt={1} wrap>
        <Stack.Item>
          Старт{' '}
          <RestrictedInput width="6em" value={start} minValue={auction.min_price} maxValue={auction.max_price} onChange={(_, value) => setPrice(value)} />{' '}
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
        <Stack.Item>
          <Button.Checkbox checked={buyoutOn} onClick={() => setBuyoutOn(!buyoutOn)}>
            Можно купить сразу за
          </Button.Checkbox>{' '}
          {buyoutOn && (
            <>
              <RestrictedInput width="6em" value={buyout} minValue={start} maxValue={auction.max_price} onChange={(_, value) => setBuyoutPrice(value)} />{' '}
              кр.
            </>
          )}
        </Stack.Item>
      </Stack>
      <Box mt={1}>
        <Button
          icon="gavel"
          color="good"
          disabled={!!refusal}
          tooltip={refusal}
          onClick={() => chosen && act('auction_list', { ref: chosen.ref, price: start, minutes: duration, anonymous, buyout: buyoutOn ? buyout : 0 })}>
          {chosen ? `Выставить: ${chosen.name}` : 'Выставить'}
        </Button>
        {!!refusal && (
          <Box className="NtTerm__hint" mt={0.5}>
            {refusal}
          </Box>
        )}
      </Box>
    </NtFrame>
  );
};

/** Доска контрактов NT: пункт подработки с падом и консоль контрактов снабжения. Вкладки: доска, мои, экипаж, спецзаказы, аукцион (только у пада). */
export const ContractBoardContent = () => {
  const { data } = useBackend<ContractBoardData>();
  const { mode, my_name, my_account, stored_cash, rank, contracts = [], partner_offers = [] } = data;
  const [tab, setTab] = useState<Tab>('board');
  const mine = contracts.filter((contract) => isMine(contract, my_account) || isMyPost(contract, my_account)).length;
  const crewFree = contracts.filter((contract) => contract.kind === 'crew' && !contract.taken_by && !isMyPost(contract, my_account)).length;
  const tabs: NtMenuItem<Tab>[] = [
    { key: 'board', label: 'Доска' },
    { key: 'mine', label: 'Мои', count: mine },
    { key: 'crew', label: 'Экипаж', count: crewFree },
    { key: 'offers', label: 'Спецзаказы', count: partner_offers.length },
  ];
  if (mode === 'pad' && data.auction) {
    tabs.push({ key: 'auction', label: 'Аукцион' });
  }
  const current = tabs.some((item) => item.key === tab) ? tab : 'board';
  return (
    <NtScreen
      tone="contracts"
      device={mode === 'pad' ? 'Пункт подработки' : 'Доска контрактов'}
      status={my_name ? `Счёт: ${my_name}${rank ? `, ранг «${rank.name}»` : ''}` : 'Банковский счёт не найден: контракт не взять.'}
      readout={
        <>
          {!!rank && <NtReadout label="Взято">{`${rank.used} / ${rank.slots}`}</NtReadout>}
          {mode === 'console' && (
            <NtReadout label="Бюджет снабжения">
              <AnimatedNumber value={stored_cash ?? 0} format={(value) => formatCredits(value)} />
            </NtReadout>
          )}
        </>
      }
      menu={<NtMenu<Tab> items={tabs} selected={current} onSelect={setTab} />}>
      {mode === 'pad' && <PadSection />}
      {current === 'board' && <BoardTab />}
      {current === 'mine' && <MineTab />}
      {current === 'crew' && <CrewTab />}
      {current === 'offers' && <OffersTab />}
      {current === 'auction' && <AuctionTab />}
    </NtScreen>
  );
};

export const ContractBoard = () => {
  return (
    <Window width={760} height={640} resizable>
      <Window.Content scrollable>
        <ContractBoardContent />
      </Window.Content>
    </Window>
  );
};

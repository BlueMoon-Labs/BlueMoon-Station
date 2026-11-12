import { useState } from 'react';

import { useBackend } from '../../backend';
import { Box, Button, Input, NoticeBox } from '../../components';
import { ContractEntry, ContractRank, CrewRequestRules, formatCredits, OfferEntry } from './Economy';

type ContractBoardData = {
  contracts?: ContractEntry[];
  my_account?: number | null;
  performer_share?: number;
  team_share?: number;
  drop_cooldown?: number;
  rank?: ContractRank | null;
  reroll_left?: number;
  crew_request?: CrewRequestRules;
  partner_offers?: OfferEntry[];
};

const formatTimeLeft = (seconds: number) => {
  const minutes = Math.floor(seconds / 60);
  const rest = String(seconds % 60).padStart(2, '0');
  return `${minutes}:${rest}`;
};

/** "12 из 30" и подобное: доля для полоски прогресса, если её можно прочитать. */
const progressShare = (progress?: string | null) => {
  const match = /(\d+(?:[.,]\d+)?)\D+(\d+(?:[.,]\d+)?)/.exec(progress || '');
  if (!match) {
    return null;
  }
  const done = Number(match[1].replace(',', '.'));
  const total = Number(match[2].replace(',', '.'));
  return total > 0 ? Math.min(done / total, 1) : null;
};

const isMine = (contract: ContractEntry, myAccount?: number | null) => !!contract.taken_by && contract.taker_id === myAccount;

const isMyPost = (contract: ContractEntry, myAccount?: number | null) =>
  contract.kind === 'crew' && !!myAccount && contract.poster_id === myAccount;

const DropButton = (props: { contract: ContractEntry }) => {
  const { act, data } = useBackend<ContractBoardData>();
  const { contract } = props;
  const cooldown = data.drop_cooldown ? ` Новый контракт - через ${data.drop_cooldown} мин., репутация подрядчика упадёт.` : '';
  let tooltip = `Контракт уйдёт с доски, на его место придёт другой.${cooldown}`;
  if (contract.kind === 'crew') {
    tooltip = `Объявление снова станет свободным.${cooldown}`;
  } else if (contract.started) {
    tooltip = `Контракт снова станет свободным, отгруженное по нему останется засчитанным.${cooldown}`;
  }
  return (
    <Button.Confirm
      mt={0.5}
      icon="times"
      content="Отказаться"
      confirmContent="Точно отказаться?"
      tooltip={tooltip}
      onClick={() => act('drop', { uid: contract.uid })}
    />
  );
};

/** Кнопки заказчика объявления: снять невзятое, принять или отклонить работу. */
const PosterAction = (props: { contract: ContractEntry }) => {
  const { act, data } = useBackend<ContractBoardData>();
  const { contract } = props;
  if (!contract.taken_by) {
    return (
      <>
        <Box color="good">Ваше объявление</Box>
        <Button.Confirm
          mt={0.5}
          icon="times"
          content="Снять"
          confirmContent="Снять объявление?"
          tooltip="Депозит вернётся на счёт."
          onClick={() => act('crew_cancel', { uid: contract.uid })}
        />
      </>
    );
  }
  return (
    <>
      <Box color={contract.reported ? 'average' : 'label'}>
        {contract.reported ? `Работу сдал: ${contract.taken_by}` : `Взял: ${contract.taken_by}`}
      </Box>
      <Button
        mt={0.5}
        color="good"
        icon="check"
        tooltip="Награда из депозита уйдёт исполнителю."
        onClick={() => act('crew_accept', { uid: contract.uid })}>
        Принять работу
      </Button>
      {!!contract.reported && (
        <Button.Confirm
          mt={0.5}
          icon="undo"
          content="Отклонить"
          confirmContent="Точно отклонить?"
          tooltip={`Объявление снова станет свободным. Без ответа работа будет принята через ${data.crew_request?.accept_minutes ?? 10} мин. после сдачи.`}
          onClick={() => act('crew_reject', { uid: contract.uid })}
        />
      )}
    </>
  );
};

const ContractAction = (props: { contract: ContractEntry; myAccount?: number | null; readOnly?: boolean }) => {
  const { act } = useBackend<ContractBoardData>();
  const { contract, myAccount, readOnly } = props;
  if (!readOnly && isMyPost(contract, myAccount)) {
    return <PosterAction contract={contract} />;
  }
  if (contract.taken_by) {
    if (contract.taker_id !== myAccount) {
      return <Box color="label">Взял: {contract.taken_by}</Box>;
    }
    return (
      <>
        <Box color="good">Ваш контракт</Box>
        {!readOnly && contract.kind === 'crew' && !contract.reported && (
          <Button
            mt={0.5}
            color="good"
            icon="check"
            tooltip="Заказчик примет или отклонит работу; промолчит - она будет принята сама."
            onClick={() => act('crew_report', { uid: contract.uid })}>
            Сдать работу
          </Button>
        )}
        {contract.kind === 'crew' && !!contract.reported && <Box color="average">Ждёт заказчика</Box>}
        {!readOnly && <DropButton contract={contract} />}
      </>
    );
  }
  if (!contract.takeable) {
    return <Box color="label">Выполняет отдел</Box>;
  }
  if (readOnly) {
    return <Box color="good">Свободен</Box>;
  }
  return (
    <Button
      color="good"
      disabled={!myAccount}
      tooltip={myAccount ? null : 'Нужен банковский счёт'}
      onClick={() => act('take', { uid: contract.uid })}>
      Взять
    </Button>
  );
};

type Filter = 'all' | 'free' | 'mine' | 'personal' | 'crew' | string;

/** Что исполнитель получит на руки до налога, или подсказка про долю участников. */
const RewardNote = (props: { contract: ContractEntry; myAccount?: number | null }) => {
  const { data } = useBackend<ContractBoardData>();
  const { contract, myAccount } = props;
  if (contract.kind === 'crew') {
    return <div className="NtTerm__hint">Исполнителю целиком, без налога</div>;
  }
  if (contract.taken_by ? isMine(contract, myAccount) : !!contract.takeable) {
    const share = contract.share ?? data.performer_share ?? 0;
    return (
      <div className="NtTerm__hint">
        Исполнителю {share}%: {formatCredits(Math.round((contract.reward * share) / 100))}
      </div>
    );
  }
  if (!contract.taken_by && !!data.team_share) {
    return (
      <div className="NtTerm__hint">
        Участникам {data.team_share}% по вкладу{contract.contributors ? `, участвуют: ${contract.contributors}` : ''}
      </div>
    );
  }
  return null;
};

const ContractRow = (props: { contract: ContractEntry; myAccount?: number | null; readOnly?: boolean }) => {
  const { contract, myAccount, readOnly } = props;
  const share = progressShare(contract.progress);
  const mine = isMine(contract, myAccount) || isMyPost(contract, myAccount);
  const lowDemand = contract.demand !== undefined && contract.demand < 100;
  return (
    <div className={mine ? 'NtTerm__contract NtTerm__contract--mine' : 'NtTerm__contract'}>
      <div className="NtTerm__contractMain">
        <div className="NtTerm__contractTitle">
          <span className="NtTerm__tag NtTerm__tag--lead">{contract.department_name}</span>
          {contract.title}
          {contract.special ? ' (заказ ЦК)' : ''}
          {!!contract.urgent && <span className="NtTerm__contractUrgent">Срочный</span>}
          {contract.kind === 'personal' && <span className="NtTerm__contractTag">Личный заказ</span>}
          {contract.kind === 'chain' && (
            <span className="NtTerm__contractTag">
              Серия: этап {contract.stage} из {contract.stages}
            </span>
          )}
          {contract.kind === 'crew' && <span className="NtTerm__contractTag">Объявление: {contract.poster}</span>}
          {lowDemand && <span className="NtTerm__contractTag NtTerm__contractTag--low">Спрос {contract.demand}%</span>}
        </div>
        <div className="NtTerm__hint">{contract.desc}</div>
        {contract.kind === 'chain' && (
          <div className="NtTerm__hint">
            Каждый этап оплачивается сразу, за последний - премия {contract.chain_bonus}% от суммы этапов.
          </div>
        )}
        {lowDemand && <div className="NtTerm__hint">Этот заказ недавно сдавали: награда снижена, со временем спрос вернётся.</div>}
        {!!contract.progress && (
          <div className="NtTerm__contractProgress">
            {share !== null && (
              <span className="NtTerm__bar">
                <span className="NtTerm__barFill" style={{ width: `${Math.round(share * 100)}%` }} />
              </span>
            )}
            <span>{contract.progress}</span>
          </div>
        )}
      </div>
      <div className="NtTerm__contractSide">
        <div className="NtTerm__contractReward">{formatCredits(contract.reward)}</div>
        {!readOnly && <RewardNote contract={contract} myAccount={myAccount} />}
        {contract.time_left !== null && contract.time_left !== undefined && (
          <div className="NtTerm__hint">Осталось {formatTimeLeft(contract.time_left)}</div>
        )}
        {contract.rotates_in !== null && contract.rotates_in !== undefined && (
          <div className={contract.started ? 'color-average' : 'NtTerm__hint'}>
            {contract.started
              ? `Снимется через ${formatTimeLeft(contract.rotates_in)}, отгруженное не вернётся`
              : `Смена через ${formatTimeLeft(contract.rotates_in)}`}
          </div>
        )}
        <Box mt={0.5}>
          <ContractAction contract={contract} myAccount={myAccount} readOnly={readOnly} />
        </Box>
      </div>
    </div>
  );
};

/** Спецзаказ партнёра снабжения: сдаётся на паде подработки, оплата - отделу сдавшего. */
const PartnerOfferRow = (props: { offer: OfferEntry }) => {
  const { data } = useBackend<ContractBoardData>();
  const { offer } = props;
  const margin = offer.unit_reward - offer.unit_price;
  return (
    <div className="NtTerm__contract">
      <div className="NtTerm__contractMain">
        <div className="NtTerm__contractTitle">
          <span className="NtTerm__tag NtTerm__tag--lead">{offer.partner}</span>
          {offer.item}
          <span className="NtTerm__contractTag">Спецзаказ</span>
        </div>
        <div className="NtTerm__hint">Нужно: {offer.requirement}</div>
        <div className="NtTerm__hint">
          {formatCredits(offer.unit_price)} за штуку сразу при сдаче
          {margin > 0 ? `, ещё ${formatCredits(margin)} за штуку - маржа отделу, закрывшему спецзаказ` : ''}.
        </div>
        <div className="NtTerm__contractProgress">
          <span className="NtTerm__bar">
            <span className="NtTerm__barFill" style={{ width: `${Math.round((offer.delivered / Math.max(offer.quantity, 1)) * 100)}%` }} />
          </span>
          <span>
            {offer.delivered} из {offer.quantity}
          </span>
        </div>
      </div>
      <div className="NtTerm__contractSide">
        <div className="NtTerm__contractReward">{formatCredits(offer.reward)}</div>
        {!!data.team_share && <div className="NtTerm__hint">Сдавшему {data.team_share}% оплаты за штуки</div>}
        <div className="NtTerm__hint">Осталось {formatTimeLeft(offer.time_left)}</div>
        <Box mt={0.5} color="label">
          {offer.accepted ? 'Взят, сдаётся на паде' : 'Сдаётся на паде'}
        </Box>
      </div>
    </div>
  );
};

const PartnerOffers = (props: { offers: OfferEntry[] }) => {
  const { offers } = props;
  return (
    <Box mt={1}>
      <div className="NtTerm__contractTitle">Спецзаказы партнёров снабжения</div>
      <Box className="NtTerm__hint" mb={0.5}>
        Положите товар на пад подработки и отправьте: оплата за штуки уйдёт вашему отделу, вам лично - доля участника. Купленное через
        снабжение и в автоматах не засчитывается.
      </Box>
      {offers.map((offer) => (
        <PartnerOfferRow key={offer.uid} offer={offer} />
      ))}
    </Box>
  );
};

/** Репутация подрядчика: ранг, занятые слоты и сколько осталось до следующего ранга. */
const RankLine = (props: { rank: ContractRank }) => {
  const { rank } = props;
  return (
    <div className="NtTerm__rank">
      <span>
        Репутация подрядчика: <span className="NtTerm__rankName">{rank.name}</span> ({rank.rep})
      </span>
      <span>
        Контрактов взято: {rank.used} из {rank.slots}
      </span>
      {!!rank.bonus && <span>Надбавка NT к вашей доле: {rank.bonus}%</span>}
      {rank.next_name ? (
        <span className="NtTerm__hint">
          До ранга «{rank.next_name}»: ещё {(rank.next_rep ?? 0) - rank.rep}
        </span>
      ) : (
        <span className="NtTerm__hint">Высший ранг</span>
      )}
    </div>
  );
};

/** Форма объявления экипажа: награда сразу уходит в депозит. */
const CrewRequestForm = (props: { rules: CrewRequestRules; onDone: () => void }) => {
  const { act } = useBackend<ContractBoardData>();
  const { rules, onDone } = props;
  const [title, setTitle] = useState('');
  const [desc, setDesc] = useState('');
  const [reward, setReward] = useState(String(rules.min));
  const amount = Math.round(Number(reward));
  const valid = title.trim().length > 0 && desc.trim().length > 0 && amount >= rules.min && amount <= rules.max;
  return (
    <div className="NtTerm__post">
      <Box className="NtTerm__hint" mb={1}>
        Опишите, какая работа вам нужна от экипажа. Награда сразу уйдёт в депозит и достанется исполнителю, когда вы примете работу.
        Объявление висит {rules.minutes} мин., невзятое можно снять и вернуть депозит.
      </Box>
      <Input fluid value={title} maxLength={rules.title_max} placeholder="Что нужно сделать" onInput={(_, value) => setTitle(value)} />
      <Input
        fluid
        mt={0.5}
        value={desc}
        maxLength={rules.desc_max}
        placeholder="Подробности: что, куда, к какому сроку"
        onInput={(_, value) => setDesc(value)}
      />
      <Box mt={0.5}>
        Награда, кр.:{' '}
        <Input width="90px" value={reward} maxLength={6} onInput={(_, value) => setReward(value)} />{' '}
        <span className="NtTerm__hint">
          от {formatCredits(rules.min)} до {formatCredits(rules.max)}
        </span>
      </Box>
      <Button
        mt={0.5}
        color="good"
        icon="bullhorn"
        disabled={!valid}
        onClick={() => {
          act('crew_post', { title: title.trim(), desc: desc.trim(), reward: amount });
          onDone();
        }}>
        Разместить
      </Button>
    </div>
  );
};

/** Доска контрактов NT: кнопка "Взять" шлёт act('take', { uid }); readOnly - только просмотр. */
export const ContractTable = (props: { showShare?: boolean; readOnly?: boolean }) => {
  const { showShare = true, readOnly = false } = props;
  const { act, data } = useBackend<ContractBoardData>();
  const { contracts = [], my_account, performer_share, rank, reroll_left = 0, crew_request, partner_offers = [] } = data;
  const [filter, setFilter] = useState<Filter>('all');
  const [posting, setPosting] = useState(false);
  const canAct = !readOnly && !!my_account && !!rank;
  const departments = contracts
    .filter((contract) => contract.kind !== 'crew')
    .map((contract) => contract.department_name)
    .filter((name, index, all) => all.indexOf(name) === index);
  const mineCount = contracts.filter((contract) => isMine(contract, my_account) || isMyPost(contract, my_account)).length;
  const personalCount = contracts.filter((contract) => contract.kind === 'personal').length;
  const crewCount = contracts.filter((contract) => contract.kind === 'crew').length;
  const filters: [Filter, string][] = [
    ['all', `Все (${contracts.length})`],
    ...(readOnly ? [] : ([['free', 'Свободные']] as [Filter, string][])),
    ...(mineCount ? ([['mine', `Мои (${mineCount})`]] as [Filter, string][]) : []),
    ...(personalCount ? ([['personal', `Личные (${personalCount})`]] as [Filter, string][]) : []),
    ...(crewCount ? ([['crew', `Экипаж (${crewCount})`]] as [Filter, string][]) : []),
    ...(departments.length > 1 ? departments.map((name) => [`dep:${name}`, name] as [Filter, string]) : []),
  ];
  const shown = contracts.filter((contract) => {
    if (filter === 'free') {
      return !contract.taken_by && !!contract.takeable && !isMyPost(contract, my_account);
    }
    if (filter === 'mine') {
      return isMine(contract, my_account) || isMyPost(contract, my_account);
    }
    if (filter === 'personal' || filter === 'crew') {
      return contract.kind === filter;
    }
    if (filter.startsWith('dep:')) {
      return contract.kind !== 'crew' && contract.department_name === filter.slice(4);
    }
    return true;
  });
  return (
    <>
      {canAct && !!rank && <RankLine rank={rank} />}
      {showShare && (
        <Box className="NtTerm__hint" mb={1}>
          Взявший контракт получает {performer_share}% награды, остальное - отделу.
        </Box>
      )}
      {canAct && (
        <Box mb={1}>
          {personalCount > 0 && (
            <Button
              icon="sync"
              disabled={reroll_left > 0}
              tooltip={
                reroll_left > 0
                  ? `Обновить можно через ${formatTimeLeft(reroll_left)}`
                  : 'Невзятые личные заказы сменятся на новые.'
              }
              onClick={() => act('reroll')}>
              Обновить личные заказы
            </Button>
          )}
          {!!crew_request && (
            <Button icon="bullhorn" selected={posting} onClick={() => setPosting(!posting)}>
              Дать объявление
            </Button>
          )}
        </Box>
      )}
      {canAct && posting && !!crew_request && <CrewRequestForm rules={crew_request} onDone={() => setPosting(false)} />}
      {!contracts.length && <NoticeBox>Контрактов сейчас нет.</NoticeBox>}
      {filters.length > 1 && contracts.length > 0 && (
        <div className="NtTerm__chips">
          {filters.map(([key, label]) => (
            <span key={key} className={filter === key ? 'NtTerm__chip NtTerm__chip--active' : 'NtTerm__chip'} onClick={() => setFilter(key)}>
              {label}
            </span>
          ))}
        </div>
      )}
      {contracts.length > 0 && shown.length === 0 && <Box className="NtTerm__hint">Под этот фильтр контрактов нет.</Box>}
      {shown.map((contract) => (
        <ContractRow key={contract.uid} contract={contract} myAccount={my_account} readOnly={readOnly} />
      ))}
      {!readOnly && partner_offers.length > 0 && <PartnerOffers offers={partner_offers} />}
    </>
  );
};

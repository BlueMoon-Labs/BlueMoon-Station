import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import { AnimatedNumber, Button } from '../components';
import { Window } from '../layouts';
import { CargoCatalog } from './Cargo';
import { formatTimeLeft } from './common/ContractTable';
import { ContractEntry, formatCredits, OfferEntry } from './common/Economy';
import { InterfaceLockNoticeBox } from './common/InterfaceLockNoticeBox';
import { NtEmpty, NtFrame, NtHelpTopic, NtHelpTopics, NtLine, NtReadout, NtScreen } from './common/NtTerminal';

/** Заработок аванпоста: его заказы и спецзаказы партнёров, всё сдаётся сканером продажи. */
type OutpostEarnings = {
  contracts: ContractEntry[];
  offers: OfferEntry[];
  team_share: number;
  refill_in: number;
  budget_name: string;
};

type Data = {
  locked: BooleanLike;
  points: number;
  budget_name?: string;
  self_paid?: BooleanLike;
  usingBeacon: BooleanLike;
  beaconzone: string;
  beaconName: string;
  canBuyBeacon: BooleanLike;
  hasBeacon: BooleanLike;
  printMsg: string;
  message: string;
  access_hint: string;
  beacon_only: BooleanLike;
  help_topics?: NtHelpTopic[];
  outpost?: OutpostEarnings;
};

export const CargoExpress = (props) => {
  const { act, data } = useBackend<Data>();
  const { locked, access_hint, outpost } = data;

  return (
    <Window width={600} height={700}>
      <Window.Content scrollable>
        <NtScreen
          tone="supply"
          device="Экспресс-снабжение"
          status={locked ? 'Консоль заблокирована' : data.message}
          readout={
            !locked && (
              <NtReadout label={data.budget_name || 'Бюджет'}>
                <AnimatedNumber value={Math.round(data.points)} format={(value) => formatCredits(value)} />
              </NtReadout>
            )
          }>
          {locked ? (
            <>
              <InterfaceLockNoticeBox accessText={access_hint} />
              <Button fluid icon="unlock" content="Разблокировать консоль" onClick={() => act('toggleLock')} />
              {outpost && <OutpostEarningsFrame outpost={outpost} />}
            </>
          ) : (
            <>
              {outpost && <OutpostEarningsFrame outpost={outpost} />}
              <CargoExpressContent />
            </>
          )}
        </NtScreen>
      </Window.Content>
    </Window>
  );
};

const OutpostContractRow = (props: { contract: ContractEntry }) => {
  const { contract } = props;
  return (
    <div className="NtTerm__contract">
      <div className="NtTerm__contractMain">
        <div className="NtTerm__contractTitle">{contract.title}</div>
        <div className="NtTerm__hint">{contract.desc}</div>
        {!!contract.progress && <div className="NtTerm__hint">Сдано: {contract.progress}</div>}
      </div>
      <div className="NtTerm__contractSide">
        <div className="NtTerm__contractReward">{formatCredits(contract.reward)}</div>
        <div className="NtTerm__hint">Сдавшим {contract.share}%</div>
        {contract.rotates_in !== null && contract.rotates_in !== undefined && (
          <div className="NtTerm__hint">Снимут через {formatTimeLeft(contract.rotates_in)}</div>
        )}
      </div>
    </div>
  );
};

const OutpostOfferRow = (props: { offer: OfferEntry }) => {
  const { offer } = props;
  const margin = offer.unit_reward - offer.unit_price;
  return (
    <div className="NtTerm__contract">
      <div className="NtTerm__contractMain">
        <div className="NtTerm__contractTitle">
          <span className="NtTerm__tag NtTerm__tag--lead">{offer.partner}</span>
          {offer.item}
        </div>
        <div className="NtTerm__hint">Нужно: {offer.requirement}</div>
        <div className="NtTerm__hint">
          {formatCredits(offer.unit_price)} за штуку сразу{margin > 0 ? `, ещё ${formatCredits(margin)} за штуку, если спецзаказ выполнят в срок` : ''}.
        </div>
        <div className="NtTerm__hint">
          Сдано {offer.delivered} из {offer.quantity}
        </div>
      </div>
      <div className="NtTerm__contractSide">
        <div className="NtTerm__contractReward">{formatCredits(offer.reward)}</div>
        <div className="NtTerm__hint">Осталось {formatTimeLeft(offer.time_left)}</div>
      </div>
    </div>
  );
};

const OutpostEarningsFrame = (props: { outpost: OutpostEarnings }) => {
  const { contracts, offers, team_share, refill_in, budget_name } = props.outpost;
  return (
    <NtFrame
      title="Заработок аванпоста"
      help={`Кликни сканером продажи по предмету рядом и постой пару секунд: сканер сразу подскажет, куда уйдёт вещь. Что подходит под заказ или спецзаказ, засчитается в него, остальное уйдёт на рынок по цене сектора. Деньги идут в ${budget_name}, сдавшему лично ${team_share}% награды заказа и оплаты спецзаказа, экипаж станции платит с этой доли обычный налог. Купленное через снабжение и в автоматах не засчитывается.`}>
      <div className="NtTerm__contractTitle">Заказы аванпоста</div>
      {contracts.length ? (
        contracts.map((contract) => <OutpostContractRow key={contract.uid} contract={contract} />)
      ) : (
        <NtEmpty>Заказов сейчас нет.</NtEmpty>
      )}
      <NtLine label="Новые заказы">{refill_in > 0 ? `через ${formatTimeLeft(refill_in)}` : 'с ближайшим обновлением доски'}</NtLine>
      <div className="NtTerm__contractTitle">Спецзаказы партнёров</div>
      {offers.length ? offers.map((offer) => <OutpostOfferRow key={offer.uid} offer={offer} />) : <NtEmpty>Спецзаказов сейчас нет.</NtEmpty>}
    </NtFrame>
  );
};

const CargoExpressContent = (props) => {
  const { act, data } = useBackend<Data>();
  const {
    hasBeacon,
    usingBeacon,
    beaconzone,
    beaconName,
    canBuyBeacon,
    printMsg,
    beacon_only,
    help_topics,
    budget_name,
    self_paid,
  } = data;

  return (
    <>
      <NtFrame
        title="Доставка капсулой"
        help={help_topics?.length ? <NtHelpTopics topics={help_topics} /> : undefined}
        buttons={<Button icon="lock" content="Заблокировать" onClick={() => act('toggleLock')} />}>
        <NtLine label="Куда">
          {!beacon_only && <Button content="Склад снабжения" selected={!usingBeacon} onClick={() => act('LZCargo')} />}
          <Button selected={usingBeacon} disabled={!hasBeacon} onClick={() => act('LZBeacon')}>
            {beaconzone} ({beaconName})
          </Button>
          <Button content={printMsg} disabled={!canBuyBeacon} onClick={() => act('printBeacon')} />
        </NtLine>
        <NtLine label="Оплата">
          {self_paid ? 'личный счёт карты' : budget_name}, сразу при заказе, по цене пака у партнёра
        </NtLine>
      </NtFrame>
      <CargoCatalog express />
    </>
  );
};

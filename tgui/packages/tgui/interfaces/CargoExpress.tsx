import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import { AnimatedNumber, Button, NoticeBox } from '../components';
import { Window } from '../layouts';
import { CargoCatalog } from './Cargo';
import { formatCredits } from './common/Economy';
import { InterfaceLockNoticeBox } from './common/InterfaceLockNoticeBox';
import { NtFrame, NtLine, NtReadout, NtScreen } from './common/NtTerminal';

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
  market_help?: string;
};

export const CargoExpress = (props) => {
  const { act, data } = useBackend<Data>();
  const { locked, access_hint } = data;

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
          <InterfaceLockNoticeBox accessText={access_hint} />
          <Button
            fluid
            color={locked ? 'good' : 'bad'}
            icon={locked ? 'unlock' : 'lock'}
            content={locked ? 'Разблокировать консоль' : 'Заблокировать консоль'}
            onClick={() => act('toggleLock')}
            mb={1.5}
          />
          {!locked && <CargoExpressContent />}
        </NtScreen>
      </Window.Content>
    </Window>
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
    market_help,
    budget_name,
    self_paid,
  } = data;

  return (
    <>
      {!!market_help && <NoticeBox info>{market_help}</NoticeBox>}
      <NtFrame title="Доставка капсулой">
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

import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import { AnimatedNumber, Box, Button, LabeledList, NoticeBox, Section } from '../components';
import { Window } from '../layouts';
import { CargoCatalog } from './Cargo';
import { formatCredits } from './common/Economy';
import { InterfaceLockNoticeBox } from './common/InterfaceLockNoticeBox';

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
        <InterfaceLockNoticeBox accessText={access_hint} />
        <Button
          fluid
          color={locked ? 'green' : 'red'}
          icon={locked ? 'unlock' : 'lock'}
          content={locked ? 'Unlock Console' : 'Lock Console'}
          onClick={() => act('toggleLock')}
          mb={1}
        />
        {!locked && <CargoExpressContent />}
      </Window.Content>
    </Window>
  );
};

const CargoExpressContent = (props) => {
  const { act, data } = useBackend<Data>();
  const {
    hasBeacon,
    message,
    points,
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
      <Section
        title="Cargo Express"
        buttons={
          <Box inline bold>
            {budget_name ? `${budget_name}: ` : ''}
            <AnimatedNumber value={Math.round(points)} format={(value) => formatCredits(value)} />
          </Box>
        }>
        <LabeledList>
          <LabeledList.Item label="Landing Location">
            {!beacon_only && (
              <Button
                content="Cargo Bay"
                selected={!usingBeacon}
                onClick={() => act('LZCargo')}
              />
            )}
            <Button
              selected={usingBeacon}
              disabled={!hasBeacon}
              onClick={() => act('LZBeacon')}>
              {beaconzone} ({beaconName})
            </Button>
            <Button
              content={printMsg}
              disabled={!canBuyBeacon}
              onClick={() => act('printBeacon')}
            />
          </LabeledList.Item>
          <LabeledList.Item label="Оплата">
            {self_paid ? 'личный счёт карты' : budget_name}, сразу при заказе, по цене пака у партнёра
          </LabeledList.Item>
          <LabeledList.Item label="Notice">{message}</LabeledList.Item>
        </LabeledList>
      </Section>
      <CargoCatalog express />
    </>
  );
};

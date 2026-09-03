import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import { AnimatedNumber, Box, Button, LabeledList, Section } from '../components';
import { Window } from '../layouts';
import { CargoCatalog } from './Cargo';
import { InterfaceLockNoticeBox } from './common/InterfaceLockNoticeBox';

type Data = {
  locked: BooleanLike;
  points: number;
  usingBeacon: BooleanLike;
  beaconzone: string;
  beaconName: string;
  canBuyBeacon: BooleanLike;
  hasBeacon: BooleanLike;
  printMsg: string;
  message: string;
  access_hint: string;
  beacon_only: BooleanLike;
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
  } = data;

  return (
    <>
      <Section
        title="Cargo Express"
        buttons={
          <Box inline bold>
            <AnimatedNumber value={Math.round(points)} />
            {' credits'}
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
          <LabeledList.Item label="Notice">{message}</LabeledList.Item>
        </LabeledList>
      </Section>
      <CargoCatalog express />
    </>
  );
};

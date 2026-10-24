import { useBackend } from '../backend';
import { LabeledList, NoticeBox, Section, Stack } from '../components';
import { Window } from '../layouts';

type Data = {
  currentTram: Tram[];
  previousTrams: Tram[];
};

type Tram = {
  serialNumber: string;
  mfgDate: string;
  distanceTravelled: number;
  tramCollisions: number;
};

export const TramPlaque = (props) => {
  const { data } = useBackend<Data>();
  const { currentTram = [], previousTrams = [] } = data;

  return (
    <Window
      title="Информационная табличка трамвая"
      width={600}
      height={360}
      theme="dark">
      <Window.Content>
        <NoticeBox info>SkyyTram Mk VI от Nakamura Engineering</NoticeBox>
        <Section
          title={
            currentTram.map((serialNumber) => serialNumber.serialNumber) +
            ' - построен ' +
            currentTram.map((serialNumber) => serialNumber.mfgDate)
          }>
          <LabeledList>
            <LabeledList.Item label="Пробег">
              {currentTram.map(
                (serialNumber) => serialNumber.distanceTravelled / 1000
              )}{' '}
              км
            </LabeledList.Item>
            <LabeledList.Item label="Столкновения">
              {currentTram.map((serialNumber) => serialNumber.tramCollisions)}
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Section title="Прежние трамваи">
          <Stack fill>
            <Stack.Item m={1} grow>
              <b>Серийный номер</b>
            </Stack.Item>
            <Stack.Item m={1} grow>
              <b>Построен</b>
            </Stack.Item>
            <Stack.Item m={1} grow>
              <b>Пробег</b>
            </Stack.Item>
            <Stack.Item m={1} grow>
              <b>Столкновения</b>
            </Stack.Item>
          </Stack>
          <Stack vertical fill>
            {previousTrams.map((tram_entry) => (
              <Stack.Item key={tram_entry.serialNumber}>
                <Stack fill>
                  <Stack.Item m={1} grow>
                    {tram_entry.serialNumber}
                  </Stack.Item>
                  <Stack.Item m={1} grow>
                    {tram_entry.mfgDate}
                  </Stack.Item>
                  <Stack.Item m={1} grow>
                    {tram_entry.distanceTravelled / 1000} км
                  </Stack.Item>
                  <Stack.Item m={1} grow>
                    {tram_entry.tramCollisions}
                  </Stack.Item>
                </Stack>
              </Stack.Item>
            ))}
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};

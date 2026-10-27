import { Box, Button, NoticeBox, Section, Table } from '../components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  previous_attempts: Attempts[];
  attempts_left: number;
};

type Attempts = {
  attempt: string;
  bulls: number;
  cows: number;
};

const check_attempts = (attempts_to_check: number) => {
  return attempts_to_check === 1
    ? 'при следующей неудачной попытке.'
    : `после ${attempts_to_check} неудачных попыток.`;
};

const BULLS_COWS_INFO = `Код состоит из неповторяющихся цифр.
Каждая неверная попытка покажет, сколько цифр угадано на верных позициях
и сколько верных цифр стоит на неверных позициях.`;

export const AbandonedCrate = (props) => {
  const { data } = useBackend<Data>();
  const { previous_attempts, attempts_left } = data;

  return (
    <Window width={335} height={180 + previous_attempts.length * 19}>
      <Window.Content scrollable>
        <Section
          title="Кодовый замок"
          buttons={
            <Button
              tooltip={BULLS_COWS_INFO}
              icon="info"
              tooltipPosition="top"
            />
          }
        >
          <NoticeBox color="bad">
            Противовзломная бомба активируется {check_attempts(attempts_left)}
          </NoticeBox>
          <Table>
            {!!previous_attempts.length && (
              <Table.Row fontSize="125%" bold>
                <Table.Cell
                  collapsing
                  color="white"
                  textAlign="center"
                  pr="5px"
                >
                  Попытка
                </Table.Cell>
                <Table.Cell collapsing textAlign="center">
                  <Button
                    tooltip={`Верные цифры на верных позициях`}
                    icon="check"
                    color="green"
                  />
                </Table.Cell>
                <Table.Cell collapsing textAlign="center">
                  <Button
                    tooltip={`Верные цифры на неверных позициях`}
                    icon="asterisk"
                    color="yellow"
                  />
                </Table.Cell>
              </Table.Row>
            )}
            {previous_attempts.map((previous_attempts) => (
              <Table.Row
                key={previous_attempts.attempt}
                style={{ borderTop: '2px solid #222' }}
              >
                <Table.Cell collapsing textAlign="center" pr="5px">
                  <Box color="white" inline fontSize="125%">
                    {previous_attempts.attempt}
                  </Box>
                </Table.Cell>
                <Table.Cell collapsing textAlign="center">
                  <Box color="green" inline fontSize="125%">
                    {previous_attempts.bulls}
                  </Box>
                </Table.Cell>
                <Table.Cell collapsing textAlign="center">
                  <Box color="yellow" inline fontSize="125%">
                    {previous_attempts.cows}
                  </Box>
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>
      </Window.Content>
    </Window>
  );
};

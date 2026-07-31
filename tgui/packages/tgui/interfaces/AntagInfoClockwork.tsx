import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import { Section, Stack } from '../components';
import { Window } from '../layouts';

interface Info {
  HONOR_RATVAR: BooleanLike;
}

let REC_RATVAR = "";
// You may ask "why is this not inside ClockworkSlab"
// It's because cslab gets called every time. Lag is bad.
for (let index = 0; index < Math.min(Math.random()*100); index++) {
  REC_RATVAR += "HONOR RATVAR ";
}

export const AntagInfoClockwork = (props) => {
  const { data } = useBackend<Info>();
  const {
    HONOR_RATVAR = false,
  } = data;
  return (
    <Window
      width={400}
      height={400}
      theme="clockcult">
      <Window.Content>
        <Section fill>
          <Stack vertical fill textAlign="center">
            <Stack.Item fontFamily="Times New Roman" fontSize={2}>
              Chetr nyy hagehguf naq ubabe Ratvar.
            </Stack.Item>
            <Stack.Item fontSize={1.2} color="#BE8700">
              {`Помогайте своим новым товарищам в их праведных усилиях.
                Ваша цель - это их цель, а их цель - ваша.
                Вы служите Часовому Юстициару, не смотря ни на что.`}
            </Stack.Item>
            <br />
            <Stack.Item>
              <Section
                title="Такова воля Ратвара"
                vertical
                fill>
                <Stack.Item grow >
                  {HONOR_RATVAR ? (
                    <Stack.Item
                      textColor="#BE8700"
                      fontSize={2}
                      bold>
                      {REC_RATVAR}
                    </Stack.Item>
                  ) : (
                    <Stack.Item
                      textColor="#dab44d"
                      fontSize={2}
                      bold>
                      Постройте Ковчег
                      Часового Юстициара и освободите Ратвара.
                    </Stack.Item>
                  )}
                </Stack.Item>
              </Section>
            </Stack.Item>
            <br />
            <Stack.Divider />
            <Stack.Item fontSize={2} color="#BE8700" bold>
              Выполняйте все его прихоти без колебаний.
            </Stack.Item>
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};

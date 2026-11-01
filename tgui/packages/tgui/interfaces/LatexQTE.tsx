import { useEffect, useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, NoticeBox, Section, Stack } from '../components';
import { Window } from '../layouts';

type QteData = {
  round_id: number;
  zone: string;
  zone_start: number;
  zone_width: number;
  elapsed: number;
  period: number;
  remaining: number;
  submitted: boolean;
};

const PERCENT = 100;
const FRAME_DELAY = 30;
const ZONE_NAMES = {
  l_leg: 'левая нога',
  r_leg: 'правая нога',
  chest: 'корпус',
  l_arm: 'левая рука',
  r_arm: 'правая рука',
  head: 'голова',
};

const pointerPosition = (elapsed: number, period: number) => {
  const phase = (elapsed % period) / period;
  return phase <= 0.5 ? phase * 2 : (1 - phase) * 2;
};

export const LatexQTE = () => {
  const { act, data } = useBackend<QteData>();
  const [elapsed, setElapsed] = useState(data.elapsed);

  useEffect(() => {
    const start = Date.now();
    setElapsed(data.elapsed);
    const timer = setInterval(() => {
      setElapsed(data.elapsed + Date.now() - start);
    }, FRAME_DELAY);
    return () => clearInterval(timer);
  }, [data.elapsed, data.round_id]);

  const stop = () => {
    if (!data.submitted) {
      act('stop', { round_id: data.round_id });
    }
  };
  const remaining = Math.max(0, data.remaining - elapsed + data.elapsed);
  const position = pointerPosition(elapsed, data.period) * PERCENT;

  return (
    <Window title="Сбросить латекс" width={480} height={360}>
      <Window.Content
        scrollable
        onKeyDown={(event) => {
          if (event.code === 'Space' && !event.repeat) {
            event.preventDefault();
            stop();
          }
        }}>
        <Section title={`Латекс обволакивает: ${ZONE_NAMES[data.zone] || data.zone}`}>
          <Box mb={1}>
            Остановите указатель в светлой зоне, чтобы сбросить латекс.
            На каждую часть тела даётся одна попытка.
          </Box>
          <Box
            mb={1}
            style={{ position: 'relative', height: '38px', background: '#17171c' }}>
            <Box
              style={{
                position: 'absolute',
                left: `${data.zone_start * PERCENT}%`,
                width: `${data.zone_width * PERCENT}%`,
                height: '100%',
                background: '#a6d7c4',
              }}
            />
            <Box
              style={{
                position: 'absolute',
                left: `${position}%`,
                top: 0,
                bottom: 0,
                width: '4px',
                background: '#fff',
                transform: 'translateX(-50%)',
              }}
            />
          </Box>
          <Stack>
            <Stack.Item grow>
              <Button fluid onClick={stop} disabled={data.submitted}>
                Остановить (пробел)
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button onClick={() => act('yield', { round_id: data.round_id })}>
                Не сопротивляться
              </Button>
            </Stack.Item>
          </Stack>
          <Box mt={1}>До следующей части: {Math.ceil(remaining / 1000)} с.</Box>
          {data.submitted && (
            <NoticeBox mt={1}>Промах. Следующая попытка — на следующей части тела.</NoticeBox>
          )}
          <Box mt={1} color="label">
            Закрытие окна не останавливает обволакивание. «Сопротивляться» откроет его снова.
          </Box>
        </Section>
      </Window.Content>
    </Window>
  );
};

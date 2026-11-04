import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import { Box, Section, Table } from '../components';
import { Window } from '../layouts';
import { ChangeBadge } from './common/Economy';

type PagerEvent = {
  ticker: string;
  headline: string;
  effect: number;
  positive: BooleanLike;
  eta: number;
};

export type InsiderPagerData = {
  knows: BooleanLike;
  events: PagerEvent[];
  eta_min?: number;
  eta_max?: number;
};

const SECONDS_PER_MINUTE = 60;

export const formatEta = (seconds: number) => {
  const total = Math.max(Math.round(seconds), 0);
  const minutes = String(Math.floor(total / SECONDS_PER_MINUTE)).padStart(2, '0');
  return `${minutes}:${String(total % SECONDS_PER_MINUTE).padStart(2, '0')}`;
};

/** Инсайдерский пейджер: предатель видит настоящие события компаний в очереди биржи; постороннему - пустой экран. */
export const InsiderPagerContent = () => {
  const { data } = useBackend<InsiderPagerData>();
  const { knows, events, eta_min = 0, eta_max = 0 } = data;
  if (!knows) {
    return (
      <Section title="Пейджер">
        <Box color="label">Новых сообщений нет.</Box>
      </Section>
    );
  }
  return (
    <>
      <Section title="Биржевая сводка">
        {events.length === 0 ? (
          <Box color="label">Пейджер молчит: событий компаний в очереди нет.</Box>
        ) : (
          <Table>
            {events.map((event, index) => (
              <Table.Row key={`${event.ticker}-${index}`} className="candystripe">
                <Table.Cell collapsing bold>
                  {event.ticker}
                </Table.Cell>
                <Table.Cell>{event.headline}</Table.Cell>
                <Table.Cell collapsing nowrap>
                  <ChangeBadge percent={event.effect} />
                </Table.Cell>
                <Table.Cell collapsing nowrap textAlign="right">
                  через {formatEta(event.eta)}
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        )}
      </Section>
      <Section title="Памятка">
        <Box color="label">
          Здесь только настоящие события компаний, уже стоящие в очереди: каждое выходит через {formatEta(eta_min)}-
          {formatEta(eta_max)} после постановки и сдвигает цену акций на указанный процент. Фальшивых пресс-релизов и
          опровержений пейджер не видит.
        </Box>
        <Box color="label" mt={1}>
          Крупные сделки в сторону события, сделанные после его постановки в очередь, - то есть по сводке пейджера, -
          финансовый аудит помечает как инсайд.
        </Box>
      </Section>
    </>
  );
};

export const InsiderPager = () => {
  const { data } = useBackend<InsiderPagerData>();
  return (
    <Window width={420} height={420} theme={data.knows ? 'syndicate' : undefined}>
      <Window.Content scrollable>
        <InsiderPagerContent />
      </Window.Content>
    </Window>
  );
};

import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import { Box, Button, Icon, NoticeBox, ProgressBar, Section, Stack } from '../components';
import { Window } from '../layouts';

type Mutation = {
  id: string;
  name: string;
  discovered: BooleanLike;
};

type AnalysisResult = {
  name: string;
  sequence: string;
};

/**
 * Каждая пара нуклеотидов — это две цепочки ДНК: первая буква пары
 * относится к верхнему ряду, вторая — к нижнему.
 */
const ROW_COLORS = ['green', 'blue'] as const;

/** Последовательность с подсветкой рядов, чтобы было видно верхнюю и нижнюю цепочки. */
const SequenceLetters = ({ sequence }: { sequence: string }) => {
  let position = 0;
  return (
    <Box
      bold
      preserveWhitespace
      style={{ fontFamily: 'monospace', fontSize: '13px', letterSpacing: '1px' }}>
      {Array.from(sequence).map((letter, index) => {
        if (letter === '-') {
          return (
            <Box as="span" key={index} color="label">
              {letter}
            </Box>
          );
        }
        const row = position % 2;
        position += 1;
        return (
          <Box as="span" key={index} color={ROW_COLORS[row]}>
            {letter}
          </Box>
        );
      })}
    </Box>
  );
};

type SequenceAnalyzerData = {
  /** Последний просканированный субъект. */
  subject: string;
  /** Мутации в буфере сканера. */
  mutations: Mutation[];
  /** Последняя расшифрованная последовательность. */
  result: AnalysisResult | null;
  ready: BooleanLike;
  /** Длительность перезарядки в децисекундах. */
  cooldown: number;
  /** Остаток перезарядки в децисекундах. */
  rechargeLeft: number;
};

export const SequenceAnalyzer = () => {
  const { act, data } = useBackend<SequenceAnalyzerData>();
  const {
    subject,
    mutations = [],
    result,
    ready,
    cooldown = 0,
    rechargeLeft = 0,
  } = data;
  const available = Array.isArray(mutations) ? mutations : [];
  const sortedMutations = [...available].sort((a, b) => a.name.localeCompare(b.name));
  const recharging = !ready && rechargeLeft > 0;
  const progress = Math.min(1, Math.max(0, 1 - rechargeLeft / Math.max(cooldown, 1)));

  return (
    <Window title="Genetic Sequence Analyzer" width={460} height={440}>
      <Window.Content scrollable>
        <Section
          title="Анализ потенциала"
          buttons={<Box color="label">{subject || 'Нет субъекта'}</Box>}>
          {sortedMutations.length > 0 ? (
            <Stack vertical>
              {sortedMutations.map(mutation => (
                <Stack.Item key={mutation.id}>
                  <Button
                    fluid
                    icon="dna"
                    disabled={recharging}
                    content={mutation.name}
                    tooltip={mutation.discovered
                      ? 'Мутация известна базе данных'
                      : 'Мутация не опознана'}
                    onClick={() => act('analyze', { mutation: mutation.id })}
                  />
                </Stack.Item>
              ))}
            </Stack>
          ) : (
            <NoticeBox color="grey">
              Буфер пуст. Просканируйте субъекта, чтобы записать его последовательность.
            </NoticeBox>
          )}
        </Section>

        {result && (
          <Section
            title="Результат анализа"
            buttons={(
              <Button icon="comment" onClick={() => act('chat')}>
                Текстом
              </Button>
            )}>
            <Box mb={0.5} color="label">{result.name}</Box>
            <SequenceLetters sequence={result.sequence} />
            <Box mt={0.5} color="label" style={{ fontSize: '11px' }}>
              <Box as="span" color="green">Верхний ряд</Box>
              {' · '}
              <Box as="span" color="blue">Нижний ряд</Box>
            </Box>
          </Section>
        )}

        <Section title="Состояние сканера">
          {recharging ? (
            <ProgressBar value={progress} color="good">
              Перезарядка: {Math.ceil(rechargeLeft / 10)} с
            </ProgressBar>
          ) : (
            <Box color="good">
              <Icon name="circle-check" mr={1} />
              Сканер готов к анализу
            </Box>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};

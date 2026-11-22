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
            <Box
              bold
              color="good"
              preserveWhitespace
              style={{ fontFamily: 'monospace', fontSize: '13px', letterSpacing: '1px' }}>
              {result.sequence}
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

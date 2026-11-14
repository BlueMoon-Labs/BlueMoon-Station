import { capitalize } from 'common/string';
import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, LabeledList, Section, Stack } from '../components';
import { Window } from '../layouts';

type FishInfo = {
  name: string;
  desc: string;
  fluid: string;
  temp_min: number;
  temp_max: number;
  feed: string;
  source: string;
  icon: string;
  discovered: number;
  max_weight: number;
};

const formatWeight = (weight: number) => {
  if (!weight) {
    return 'нет данных';
  }
  return weight >= 1000
    ? `${(weight / 1000).toFixed(2)} кг`
    : `${Math.round(weight)} г`;
};

export const FishCatalog = (props) => {
  const { data } = useBackend<{
    fish_info: FishInfo[];
    sponsored_by: string;
    discovered_count: number;
  }>();
  const { fish_info, sponsored_by, discovered_count } = data;
  const fish_by_name = (fish_info || [])
    .slice()
    .sort((a, b) => a.name.localeCompare(b.name));
  const [currentFish, setCurrentFish] = useState<FishInfo | null>(null);
  return (
    <Window width={620} height={520}>
      <Window.Content>
        <Stack fill>
          <Stack.Item width="210px">
            <Section fill scrollable title="Виды">
              {fish_by_name.map((fish) => (
                <Button
                  key={fish.name}
                  fluid
                  color="transparent"
                  selected={fish === currentFish}
                  onClick={() => setCurrentFish(fish)}>
                  <Box bold={fish === currentFish}>
                    {(fish.discovered ? '✓ ' : '? ') + fish.name}
                  </Box>
                  {fish.discovered && fish.max_weight > 0 && (
                    <Box fontSize="11px" color="label">
                      рекорд: {formatWeight(fish.max_weight)}
                    </Box>
                  )}
                </Button>
              ))}
            </Section>
          </Stack.Item>
          <Stack.Item grow basis={0}>
            <Section
              fill
              scrollable
              title={
                currentFish
                  ? capitalize(currentFish.name)
                  : `${sponsored_by} — рыбный справочник`
              }>
              {!currentFish && (
                <Stack vertical>
                  <Stack.Item>
                    <Box fontSize="15px" bold>
                      Изучено видов: {discovered_count}
                    </Box>
                  </Stack.Item>
                  <Stack.Item>
                    <Box color="label">
                      Выберите рыбу слева, чтобы посмотреть описание, условия
                      содержания и личный рекорд веса.
                    </Box>
                  </Stack.Item>
                  <Stack.Item>
                    <Box color="label">
                      Отмечайте новые виды анализатором рыбы. Пойманная рыба
                      автоматически попадает в справочник.
                    </Box>
                  </Stack.Item>
                </Stack>
              )}
              {currentFish && (
                <Stack vertical>
                  <Stack.Item>
                    <Box
                      bold
                      color={currentFish.discovered ? 'good' : 'label'}>
                      {currentFish.discovered
                        ? 'Вид изучен'
                        : 'Вид ещё не изучен'}
                    </Box>
                  </Stack.Item>
                  <Stack.Item>
                    <LabeledList>
                      <LabeledList.Item label="Личный рекорд">
                        {currentFish.max_weight > 0
                          ? formatWeight(currentFish.max_weight)
                          : currentFish.discovered
                            ? 'вес не записан'
                            : 'пока не поймана'}
                      </LabeledList.Item>
                      <LabeledList.Item label="Описание">
                        {currentFish.desc}
                      </LabeledList.Item>
                      <LabeledList.Item label="Тип воды">
                        {currentFish.fluid}
                      </LabeledList.Item>
                      <LabeledList.Item label="Температура">
                        от {currentFish.temp_min} до {currentFish.temp_max} °C
                      </LabeledList.Item>
                      <LabeledList.Item label="Корм">
                        {currentFish.feed}
                      </LabeledList.Item>
                      <LabeledList.Item label="Где ловить">
                        {currentFish.source}
                      </LabeledList.Item>
                    </LabeledList>
                  </Stack.Item>
                </Stack>
              )}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

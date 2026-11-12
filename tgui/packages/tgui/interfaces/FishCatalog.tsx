import { capitalize } from 'common/string';
import { useState } from 'react';

import { useBackend } from '../backend';
import { Button, LabeledList, Section, Stack } from '../components';
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
};

export const FishCatalog = (props) => {
  const { data } = useBackend<{
    fish_info: FishInfo[];
    sponsored_by: string;
    discovered_count: number;
  }>();
  const { fish_info, sponsored_by, discovered_count } = data;
  const fish_by_name = (fish_info || []).slice().sort((a, b) => a.name.localeCompare(b.name));
  const [currentFish, setCurrentFish] = useState<FishInfo | null>(null);
  return (
    <Window width={500} height={400}>
      <Window.Content>
        <Stack fill>
          <Stack.Item width="140px">
            <Section fill scrollable>
              {fish_by_name.map((f) => (
                <Button
                  key={f.name}
                  fluid
                  color="transparent"
                  selected={f === currentFish}
                  onClick={() => setCurrentFish(f)}>
                  {(f.discovered ? '✓ ' : '? ') + f.name}
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
                  : sponsored_by + ' — рыбный справочник (изучено: ' + discovered_count + ')'
              }>
              {currentFish && (
                <LabeledList>
                  <LabeledList.Item label="Статус">
                    {currentFish.discovered ? 'Вид изучен' : 'Не просканирован'}
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
              )}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

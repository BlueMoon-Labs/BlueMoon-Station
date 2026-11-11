import { useBackend } from '../backend';
import { Box, Button, LabeledList, Section } from '../components';
import { Window } from '../layouts';

type Data = {
  bait: string | null;
  line: string | null;
  hook: string | null;
  difficulty_modifier: number;
  ui_description: string;
  wiki_description: string;
  cast_range: number;
  experience_multiplier: number;
  completion_speed_mult: number;
  bait_speed_mult: number;
  deceleration_mult: number;
  bounciness_mult: number;
  gravity_mult: number;
  bait_height_mult: number;
};

const Slot = (props: {
  name: string;
  slot: string;
  value: string | null;
}) => {
  const { act } = useBackend();
  return (
    <LabeledList.Item
      label={props.name}
      buttons={
        <Button
          disabled={!props.value}
          onClick={() => act('remove_' + props.slot)}>
          Снять
        </Button>
      }>
      {props.value || 'Нет'}
    </LabeledList.Item>
  );
};

export const FishingRod = (props) => {
  const { data } = useBackend<Data>();
  const d = data;
  return (
    <Window width={420} height={500}>
      <Window.Content scrollable>
        <Section title="Снаряжение">
          <LabeledList>
            <Slot name="Наживка" slot="bait" value={d.bait} />
            <Slot name="Леска" slot="line" value={d.line} />
            <Slot name="Крючок" slot="hook" value={d.hook} />
          </LabeledList>
        </Section>
        <Section title="Удочка">
          <Box mb={1}>{d.ui_description}</Box>
          <LabeledList>
            <LabeledList.Item label="Дальность заброса">
              {d.cast_range} клеток
            </LabeledList.Item>
            <LabeledList.Item label="Сложность">
              {d.difficulty_modifier}
            </LabeledList.Item>
            <LabeledList.Item label="Опыт">
              x{d.experience_multiplier}
            </LabeledList.Item>
            <LabeledList.Item label="Скорость вываживания">
              x{d.completion_speed_mult}
            </LabeledList.Item>
            <LabeledList.Item label="Скорость приманки">
              x{d.bait_speed_mult}
            </LabeledList.Item>
            <LabeledList.Item label="Торможение">
              x{d.deceleration_mult}
            </LabeledList.Item>
            <LabeledList.Item label="Отскок">
              x{d.bounciness_mult}
            </LabeledList.Item>
            <LabeledList.Item label="Гравитация">
              x{d.gravity_mult}
            </LabeledList.Item>
            <LabeledList.Item label="Размер приманки">
              x{d.bait_height_mult}
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Window.Content>
    </Window>
  );
};

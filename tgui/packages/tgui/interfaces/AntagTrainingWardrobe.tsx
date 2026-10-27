import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import { Box, NoticeBox, Section } from '../components';
import { Window } from '../layouts';
import { RolePicker, TrainingRoleEntry } from './AntagTrainingRolePicker';

export type AntagTrainingWardrobeData = {
  department: string;
  program: string | null;
  selected: string | null;
  busy: BooleanLike;
  roles: TrainingRoleEntry[];
  blocked: string[];
};

export const AntagTrainingWardrobe = () => {
  const { act, data } = useBackend<AntagTrainingWardrobeData>();
  const { department, program, selected, busy, roles, blocked } = data;
  return (
    <Window width={440} height={420} title={`Раздевалка: ${department}`}>
      <Window.Content scrollable>
        <Section title={department}>
          <Box color="label" mb={1}>
            Должность меняет форму, снаряжение и доступ ID. Программа{program ? ` «${program}»` : ''} остаётся прежней.
          </Box>
          {!!blocked.length && (
            <NoticeBox>
              Ваша программа не работает с ролями: {blocked.join(', ')}. Смените программу в пульте полигона.
            </NoticeBox>
          )}
          <RolePicker roles={roles} selected={selected || 'default'} disabled={!!busy} onSelect={(id) => act('set_role', { role: id })} />
        </Section>
      </Window.Content>
    </Window>
  );
};

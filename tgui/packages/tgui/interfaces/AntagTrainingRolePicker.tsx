import { useState } from 'react';

import { Box, Button, Input, Stack } from '../components';

export type TrainingRoleEntry = { id: string; name: string; department: string; order: number; kind?: number };

/** Программа с allowed_roles принимает только должности этих видов; 0 или нет поля - принимает любую и её игнорирует. */
export const roleAllowed = (role: TrainingRoleEntry | undefined, allowed?: number) => !allowed || !role || !!(allowed & (role.kind || 1));

/** Должности по отделам в порядке первого появления отдела, внутри отдела - по порядку должностей. */
export const groupRoles = (roles: TrainingRoleEntry[]): [string, TrainingRoleEntry[]][] => {
  const groups = new Map<string, TrainingRoleEntry[]>();
  for (const role of roles) {
    const list = groups.get(role.department) || [];
    list.push(role);
    groups.set(role.department, list);
  }
  return [...groups.entries()].map(([department, list]) => [department, [...list].sort((a, b) => a.order - b.order)]);
};

export const roleName = (roles: TrainingRoleEntry[], id: string) => roles.find((role) => role.id === id)?.name || 'Учебное тело';

export const RolePicker = (props: { roles: TrainingRoleEntry[]; selected: string; onSelect: (id: string) => void; disabled?: boolean; allowed?: number }) => {
  const { roles, selected, onSelect, disabled, allowed } = props;
  const [search, setSearch] = useState('');
  const needle = search.trim().toLowerCase();
  const shown = needle ? roles.filter((role) => role.name.toLowerCase().includes(needle) || role.department.toLowerCase().includes(needle)) : roles;
  return (
    <Box>
      <Input fluid placeholder="Поиск должности" value={search} onInput={(_, value) => setSearch(value)} mb={1} />
      {groupRoles(shown).map(([department, list]) => (
        <Box key={department} mb={1}>
          <Box bold color="label" mb={0.5}>{department}</Box>
          <Stack wrap="wrap">
            {list.map((role) => (
              <Stack.Item key={role.id} mb={0.5}>
                <Button selected={role.id === selected} disabled={disabled || !roleAllowed(role, allowed)} tooltip={roleAllowed(role, allowed) ? undefined : 'Эта программа работает только с человеком'} onClick={() => onSelect(role.id)}>{role.name}</Button>
              </Stack.Item>
            ))}
          </Stack>
        </Box>
      ))}
      {!shown.length && <Box color="label">Такой должности нет.</Box>}
    </Box>
  );
};

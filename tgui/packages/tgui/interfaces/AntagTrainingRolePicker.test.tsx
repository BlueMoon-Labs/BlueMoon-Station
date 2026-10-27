import { fireEvent, render } from '@testing-library/react';

import { groupRoles, RolePicker, TrainingRoleEntry } from './AntagTrainingRolePicker';

const roles: TrainingRoleEntry[] = [
  { id: 'default', name: 'Учебное тело', department: 'Полигон', order: 0 },
  { id: 'crew:Security Officer', name: 'Security Officer', department: 'Служба безопасности', order: 32 },
  { id: 'crew:Warden', name: 'Warden', department: 'Служба безопасности', order: 31 },
  { id: 'crew:Medical Doctor', name: 'Medical Doctor', department: 'Медицина', order: 41 },
];

test('должности по отделам, внутри отдела по порядку', () => {
  expect(groupRoles(roles).map(([department, list]) => [department, list.map((role) => role.id)])).toEqual([
    ['Полигон', ['default']],
    ['Служба безопасности', ['crew:Warden', 'crew:Security Officer']],
    ['Медицина', ['crew:Medical Doctor']],
  ]);
});

test('поиск сужает список, клик сообщает выбранную должность', () => {
  const onSelect = jest.fn();
  const ui = render(<RolePicker roles={roles} selected="default" onSelect={onSelect} />);
  fireEvent.input(ui.getByPlaceholderText('Поиск должности'), { target: { value: 'doctor' } });
  expect(ui.queryByText('Warden')).toBeNull();
  fireEvent.click(ui.getByText('Medical Doctor'));
  expect(onSelect).toHaveBeenCalledWith('crew:Medical Doctor');
});

test('должность синтетика неактивна для программы только для людей', () => {
  const withBorg = [...roles, { id: 'silicon:cyborg', name: 'Киборг', department: 'Синтетики', order: 2, kind: 2 }];
  const onSelect = jest.fn();
  const ui = render(<RolePicker roles={withBorg} selected="default" allowed={1} onSelect={onSelect} />);
  fireEvent.click(ui.getByText('Киборг'));
  expect(onSelect).not.toHaveBeenCalled();
  fireEvent.click(ui.getByText('Medical Doctor'));
  expect(onSelect).toHaveBeenCalledWith('crew:Medical Doctor');
});

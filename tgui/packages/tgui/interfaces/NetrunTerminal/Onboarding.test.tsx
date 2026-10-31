import { fireEvent, render } from '@testing-library/react';

import { MatrixPanel } from './Matrix';
import { NodePanel } from './NodePanel';
import type { MatrixState } from './types';

const mockAct = jest.fn();
let mockData: any;
jest.mock('./useNetrunBackend', () => ({
  useNetrunBackend: () => ({ act: mockAct, data: mockData }),
}));

beforeEach(() => mockAct.mockClear());

test('a guest can open public firmware without receiving the protected file catalog', () => {
  mockData = {
    workspace_view: 'map', map: {}, networks: [], can_breach: false, entity: null,
    selected: { address: 'CAM:1', name: 'Камера', type: 'camera', network: 'ENG',
      access: 1, legit: 0, online: true, security: 2, commands: [], status: [], manual_uid: 'firmware' },
  };
  const panel = render(<NodePanel />);
  fireEvent.click(panel.getByText('Справка узла'));
  expect(mockAct).toHaveBeenCalledWith('read', { uid: 'firmware' });
  expect(panel.container.querySelector('[data-net-files="remote"]')).toBeNull();
});

test('the protocol explains legal choices and finite-buffer goals beside the matrix', () => {
  const state: MatrixState = { minigame: 'matrix', target: 'Узел', security: 3, size: 1,
    cells: [{ code: '1C', active: true }], buffer_size: 4, buffer: [], daemons: [], time_left: 20, pick_row: true };
  const panel = render(<MatrixPanel state={state} />);
  expect(panel.getByText(/Первый код выбирайте в верхней строке/).textContent).toContain('Клетки нельзя использовать повторно');
  expect(panel.getByText(/Соберите коды цели подряд в буфере/).textContent).toContain('число мест в нём ограничено');
  fireEvent.click(panel.getByRole('button', { name: 'Выбрать код 1C' }));
  expect(mockAct).toHaveBeenCalledWith('breach_pick', { index: 1 });
});

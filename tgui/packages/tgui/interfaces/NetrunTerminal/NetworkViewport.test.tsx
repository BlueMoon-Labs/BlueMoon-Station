import { act, fireEvent, render, waitFor } from '@testing-library/react';

import { GraphScene, PlacedNode } from './graphScene';
import { NetworkViewport } from './NetworkViewport';
import { mountNetrunPixi } from './pixiSurface';
import { makePixiSurfaceMock } from './testSupport/pixiSurfaceMock';

jest.mock('./pixiSurface', () => ({ mountNetrunPixi: jest.fn() }));
const mount = jest.mocked(mountNetrunPixi);
const node: PlacedNode = { address: 'APC', name: 'Первое имя', type: 'apc', x: 0, y: 0, px: 0, py: 0,
  security: 1, online: true, access: 1, active: false, entities: 0, uplink: null };
const props = { nodes: [node], edges: [], gateways: new Map(), selected: 'APC', jacked: null, entityHost: null,
  selectedRoute: [], waypointRoute: [], pingRoute: [], events: [], adjacency: new Map(), onSelect: jest.fn() };
beforeEach(() => { mount.mockImplementation(async (host) => makePixiSurfaceMock(host)); });

test('the ready viewport has one Pixi surface without legacy drawing layers', async () => {
  const context = jest.spyOn(HTMLCanvasElement.prototype, 'getContext');
  const panel = render(<NetworkViewport {...props} />);
  await waitFor(() => expect(panel.getByLabelText('Карта сети').getAttribute('data-net-runtime')).toBe('ready'));
  expect(panel.container.querySelectorAll('[data-net-pixi]')).toHaveLength(1);
  expect(panel.container.querySelector('[data-net-canvas], svg, [data-net-actors]')).toBeNull();
  expect(context).not.toHaveBeenCalled();
  context.mockRestore();
});

test('GPU initialization failure has an accessible retry and never falls back to Canvas2D', async () => {
  mount.mockResolvedValueOnce(null);
  const panel = render(<NetworkViewport {...props} />);
  await waitFor(() => expect(panel.getByRole('alert').textContent).toContain('Карта временно недоступна'));
  expect(panel.container.querySelector('canvas, svg')).toBeNull();
  fireEvent.click(panel.getByText('Повторить запуск карты'));
  await waitFor(() => expect(panel.getByLabelText('Карта сети').getAttribute('data-net-runtime')).toBe('ready'));
  expect(mount).toHaveBeenCalledTimes(2);
  expect(panel.queryByRole('alert')).toBeNull();
});

test('a hidden workspace retains its surface and releases it only on final unmount', async () => {
  const panel = render(<NetworkViewport {...props} />);
  await waitFor(() => expect(panel.getByLabelText('Карта сети').getAttribute('data-net-runtime')).toBe('ready'));
  const surface = await mount.mock.results[0].value;
  const canvas = panel.container.querySelector('[data-net-pixi]');
  panel.rerender(<NetworkViewport {...props} suspended />);
  expect(surface.setSuspended).toHaveBeenLastCalledWith(true);
  expect(surface.destroy).not.toHaveBeenCalled();
  panel.rerender(<NetworkViewport {...props} />);
  expect(panel.container.querySelector('[data-net-pixi]')).toBe(canvas);
  expect(mount).toHaveBeenCalledTimes(1);
  expect(surface.setSuspended).toHaveBeenLastCalledWith(false);
  panel.unmount();
  expect(surface.destroy).toHaveBeenCalledTimes(1);
});

test('tooltips read live data, highlight through Pixi and clear on endpoint removal', async () => {
  const originalPointer = window.PointerEvent;
  Object.defineProperty(window, 'PointerEvent', { value: MouseEvent, configurable: true });
  try {
    const panel = render(<NetworkViewport {...props} />);
    await waitFor(() => expect(panel.getByLabelText('Карта сети').getAttribute('data-net-runtime')).toBe('ready'));
    const surface = await mount.mock.results[0].value;
    fireEvent.pointerMove(panel.getByLabelText('Карта сети'), { clientX: 360, clientY: 240 });
    expect(panel.getByRole('tooltip').textContent).toContain('Первое имя');
    expect(surface.updateActors).toHaveBeenLastCalledWith(expect.any(GraphScene),
      expect.objectContaining({ hovered: 'APC' }));
    panel.rerender(<NetworkViewport {...props} nodes={[{ ...node, name: 'Новое имя', online: false }]} />);
    expect(panel.getByRole('tooltip').textContent).toContain('Новое имя');
    expect(panel.getByRole('tooltip').textContent).toContain('Не отвечает');
    panel.rerender(<NetworkViewport {...props} nodes={[]} />);
    expect(panel.queryByRole('tooltip')).toBeNull();
    expect(panel.getByText('Нет узлов для отображения')).toBeTruthy();
  } finally { Object.defineProperty(window, 'PointerEvent', { value: originalPointer, configurable: true }); }
});

test('late asynchronous initialization is disposed after unmount', async () => {
  let finish;
  mount.mockImplementationOnce(() => new Promise((resolve) => { finish = resolve; }));
  const panel = render(<NetworkViewport {...props} />);
  await waitFor(() => expect(mount).toHaveBeenCalledTimes(1));
  const [host, , , , options] = mount.mock.calls[0];
  panel.unmount();
  expect(options.signal.aborted).toBe(true);
  const surface = makePixiSurfaceMock(host);
  await act(async () => { finish(surface); });
  expect(surface.destroy).toHaveBeenCalledTimes(1);
});

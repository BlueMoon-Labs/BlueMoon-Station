import { render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { debugReducer } from '../../debug';
import { NetrunContent } from './Content';

test('workspace shell keeps navigation and map slots available', () => {
  (global as any).Byond = { winset: () => {}, topic: jest.fn() };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'NetrunTerminal' }, data: {
    origin: 'terminal', wireless: false, uplink: true, trace: 20, locked: 0,
    networks: [], windows: [], window: null, breach: null, web: null,
    workspace_view: 'terminal', combat: null, entity: null, jack: null, can_breach: false,
    map: null, selected: null, selected_network: null, ping_route: null,
    log: [], storage: { files: [], used: 0, capacity: 1 }, shard: null,
    host_actions: [], chat: { handle: 'test', messages: [] },
  } }));
  const { container, getByRole } = render(<NetrunContent />);
  expect(container.querySelector('.netrun-shell')).toBeTruthy();
  expect(container.querySelector('.netrun-header')).toBeTruthy();
  expect(container.querySelector('.netrun-navigation')).toBeTruthy();
  expect(container.querySelector('.netrun-navigation__label')).toBeTruthy();
  // Tabs wrap the icon and text separately; NetRun centers them as one group
  // instead of inheriting TGUI's flex-grow on the text wrapper.
  const mapTab = getByRole('tab', { name: 'Карта' });
  expect(mapTab.querySelector('.Tab__left .Icon')).toBeTruthy();
  expect(mapTab.querySelector('.Tab__text .netrun-navigation__label')).toBeTruthy();
  expect(container.querySelector('.netrun-files-layout')).toBeTruthy();
  expect(getByRole('tab', { name: 'Карта' })).toBeTruthy();
  expect(container.querySelector('[data-net-layout="workspace"]')).toBeTruthy();
});

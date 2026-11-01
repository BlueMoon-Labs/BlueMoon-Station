import { act, fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../../backend';
import { Scrubbers } from './Scrubbers';

test('native filter arrays render and send the gas ID, malformed old telemetry cannot crash the tab', () => {
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer }));
  setGlobalStore(store);
  const scrubber = { id_tag: 'scrub-1', long_name: 'Scrubber', power: 1, scrubbing: 1, widenet: 0,
    filter_types: [{ gas_id: 'carbon_dioxide', gas_name: 'Carbon dioxide', enabled: 1 }] };
  store.dispatch(backendUpdate({ config: { interface: 'AirAlarm' }, data: { scrubbers: [scrubber] } }));
  const panel = render(<Scrubbers />);
  expect(panel.getByText(/Фильтры \(1 из 1\)/)).toBeTruthy();
  fireEvent.click(panel.getByText('Carbon dioxide'));
  const call = topic.mock.calls.find(([entry]) => entry.type === 'act/toggle_filter');
  expect(JSON.parse(call[0].payload)).toEqual({ id_tag: 'scrub-1', val: 'carbon_dioxide' });
  act(() => store.dispatch(backendUpdate({ data: { scrubbers: [{ ...scrubber, filter_types: {} }] } })));
  panel.rerender(<Scrubbers />);
  expect(panel.getByText(/Фильтры \(0 из 0\)/)).toBeTruthy();
});

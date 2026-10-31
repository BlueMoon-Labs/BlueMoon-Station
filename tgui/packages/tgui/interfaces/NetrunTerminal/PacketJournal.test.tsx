import { fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { PacketJournal } from './PacketJournal';

test('headers stay visible, decoding is explicit and carries the immutable packet ID', () => {
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'NetrunTerminal' }, data: {} }));
  const packets = [{ id: 'packet-17', time: 12, phase: 'RECEIVE', kind: 'machine', from: 'A', to: 'B',
    service: 'atmos.device', headers: { protocol: 'NETRUN/1', content_type: 'application/json' } }];
  const panel = render(<PacketJournal packets={packets} root={false} />);
  expect(panel.getByText('protocol: NETRUN/1')).toBeTruthy();
  fireEvent.click(panel.getByText('Расшифровать'));
  expect(topic).not.toHaveBeenCalled();
  panel.rerender(<PacketJournal packets={packets} root />);
  fireEvent.click(panel.getByText('Расшифровать'));
  const call = topic.mock.calls.find(([entry]) => entry.type === 'act/command');
  expect(JSON.parse(call[0].payload)).toMatchObject({ id: 'packet_decrypt', packet_id: 'packet-17' });
});

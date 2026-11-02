import { act, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';
import fs from 'node:fs';

import { backendReducer, backendUpdate } from '../../backend';
import { debugReducer } from '../../debug';
import { NetrunContent } from './Content';
import { mountNetrunPixi } from './pixiSurface';
import type { MockPixiSurface } from './testSupport/pixiSurfaceMock';
import { NetrunData } from './types';

jest.mock('./pixiSurface', () => ({
  mountNetrunPixi: jest.fn(async (host: HTMLElement) =>
    jest.requireActual('./testSupport/pixiSurfaceMock').makePixiSurfaceMock(host)),
}));

beforeEach(() => jest.mocked(mountNetrunPixi).mockImplementation(async (host) =>
  jest.requireActual('./testSupport/pixiSurfaceMock').makePixiSurfaceMock(host)));
afterEach(async () => { await act(async () => {}); });

// Opt-in: the managed live world writes this payload after real Core graph/tree import.
const artifactPath = process.env.NETRUN_LIVE_UI_PAYLOAD;
(artifactPath ? test : test.skip)('real Core relay guest payload reaches the visible TGUI graph', async () => {
  const artifact = JSON.parse(fs.readFileSync(artifactPath!, 'utf8')) as { address: string; payload: NetrunData };
  expect(artifact.payload.map?.nodes.some((node) => node.address === artifact.address)).toBe(true);
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: 'NetrunTerminal' }, data: artifact.payload }));
  const panel = render(<NetrunContent />);
  await act(async () => {});
  const mounted = jest.mocked(mountNetrunPixi).mock.results.slice(-1)[0];
  expect(mounted).toBeDefined();
  const surface = await mounted!.value as MockPixiSurface;
  const scene = surface.updateScene.mock.calls.slice(-1)[0]?.[0];
  expect(scene?.nodes.some((node) => node.address === artifact.address)).toBe(true);
  expect(panel.queryByText('Нет узлов для отображения')).toBeNull();
  expect(topic.mock.calls.some(([message]) => message.type === 'act/map_resync')).toBe(false);
});

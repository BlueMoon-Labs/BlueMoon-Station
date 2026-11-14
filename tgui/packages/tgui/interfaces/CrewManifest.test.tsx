/**
 * Главы в списке экипажа: звёздочка перед должностью, жирная строка, порядок и названия отделов от сервера.
 */
import { render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { CrewManifest } from './CrewManifest';
import { NtosCrewManifest } from './NtosCrewManifest';
import { PaiSoftware } from './PaiSoftware';

const STAR = '★';

const medical = [
  {
    name: 'Ada Vance',
    rank: 'Medical Director',
    head: 1,
  },
  {
    name: 'Bob Stone',
    rank: 'Medical Doctor',
    head: 0,
  },
  {
    name: 'Cid Free',
    rank: 'Bob',
    head: 0,
  },
];

const department_names = {
  Command: 'Командование',
  Medical: 'Медицинский отдел',
};

const setupStore = (iface: string, data: object) => {
  (global as any).Byond = { winset: () => {}, topic: () => {} };
  const store = createStore(
    combineReducers({ backend: backendReducer, debug: debugReducer }),
  );
  setGlobalStore(store);
  store.dispatch(backendUpdate({ config: { interface: iface }, data }));
};

const rows = (container: HTMLElement) =>
  Array.from(container.querySelectorAll('tr.Table__row')).map((row) => ({
    text: row.textContent,
    bold: (row as HTMLElement).style.fontWeight === 'bold',
    star: !!row.querySelector('.CrewManifest__HeadMark'),
  }));

describe('CrewManifest', () => {
  test('глава первой строкой, со звёздочкой и жирным, рядовые без метки', () => {
    setupStore('CrewManifest', {
      manifest: { Medical: medical },
      positions: { Medical: 2 },
      department_names,
    });
    const { container } = render(<CrewManifest />);
    expect(container.querySelector('.Section__titleText').textContent).toContain(
      'Медицинский отдел',
    );
    const list = rows(container);
    expect(list).toHaveLength(3);
    expect(list[0]).toEqual({
      text: `Ada Vance${STAR}Medical Director`,
      bold: true,
      star: true,
    });
    expect(list[1]).toEqual({
      text: 'Bob StoneMedical Doctor',
      bold: false,
      star: false,
    });
    expect(list[2].star).toBe(false);
    expect(list[2].text).toBe('Cid FreeBob');
  });

  test('метка следует за флагом записи, а не за профессией', () => {
    setupStore('CrewManifest', {
      manifest: {
        Command: [
          {
            name: 'Renamed Captain',
            rank: 'Assistant',
            head: 0,
          },
        ],
      },
      positions: { Command: 0 },
      department_names,
    });
    const { container } = render(<CrewManifest />);
    expect(container.textContent).not.toContain(STAR);
    expect(container.querySelector('.fa-star')).toBeNull();
  });
});

describe('NtosCrewManifest', () => {
  test('глава отмечен звёздочкой и жирным в порядке сервера', () => {
    setupStore('NtosCrewManifest', {
      manifest: { Medical: medical },
      have_printer: false,
      department_names,
    });
    const { container } = render(<NtosCrewManifest />);
    const titles = Array.from(
      container.querySelectorAll('.Section__titleText'),
    ).map((title) => title.textContent);
    expect(titles).toEqual(['Манифест экипажа', 'Медицинский отдел']);
    const list = rows(container);
    expect(list.map((row) => row.text)).toEqual([
      `Ada Vance(${STAR}Medical Director)`,
      'Bob Stone(Medical Doctor)',
      'Cid Free(Bob)',
    ]);
    expect(list.map((row) => row.bold)).toEqual([true, false, false]);
  });
});

describe('PaiSoftware manifest', () => {
  test('pAI видит главу со звёздочкой', () => {
    setupStore('PaiSoftware', {
      screen: 'manifest',
      software: [],
      available_software: [],
      crew_manifest: [
        { name: 'Ada Vance', rank: 'Medical Director', head: 1 },
        { name: 'Bob Stone', rank: 'Medical Doctor', head: 0 },
      ],
    });
    const { container } = render(<PaiSoftware />);
    const list = rows(container).filter((row) => row.text !== 'ИмяДолжность');
    expect(list).toEqual([
      { text: `Ada Vance${STAR}Medical Director`, bold: true, star: true },
      { text: 'Bob StoneMedical Doctor', bold: false, star: false },
    ]);
  });
});

/**
 * Менторхелп открывает общую панель обращений: она обязана стартовать на
 * вкладке менторов, иначе вопрос по механикам уходит админам.
 */
import { render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { sanitizeTicketHtml } from '../sanitize';
import { PlayerTicketPanel } from './PlayerTicketPanel';

const setupStore = (data = {}) => {
  (global as any).Byond = { winset: () => {}, topic: () => {} };
  const store = createStore(
    combineReducers({ backend: backendReducer, debug: debugReducer }),
  );
  setGlobalStore(store);
  store.dispatch(
    backendUpdate({
      config: { interface: 'PlayerTicketPanel' },
      data: { has_ticket: false, has_mentor_ticket: false, ...data },
    }),
  );
  return store;
};

test('сохраняет штатные ссылки в истории тикета для нужной роли', () => {
  const admin = '?_src_=holder;admin_token=123;ahelp=[0x123];ahelp_action=reply';
  const reply = '?_src_=mentor;mentor_msg=player;mentor_token=123';
  const taggedReply = '?_src_=mentor;mentor_msg=[mob_17]';
  const follow = '?_src_=mentor;mentor_follow=[mob_17];mentor_token=123';
  const html = [admin, reply, taggedReply, follow, '?other=1']
    .map((href) => `<a href="${href}">Действие</a>`)
    .join(' ');

  const linksFor = (role?: string) => {
    const fragment = document.createElement('template');
    fragment.innerHTML = sanitizeTicketHtml(html, role);
    return Array.from(fragment.content.querySelectorAll('a[href]'),
      (link) => link.getAttribute('href'));
  };

  expect(linksFor('admin')).toEqual([admin]);
  expect(linksFor('mentor')).toEqual([reply, taggedReply, follow]);
  expect(linksFor()).toEqual([]);
});

describe('PlayerTicketPanel', () => {
  test('из менторхелпа открывается вкладка менторов', () => {
    setupStore({ initial_tab: 'mentor' });
    const { container } = render(<PlayerTicketPanel />);
    expect(container.textContent).toContain('Опишите ваш вопрос подробно');
    expect(container.textContent).not.toContain('Укажите имена причастных');
  });

  test('из админхелпа открывается вкладка администрации', () => {
    setupStore({ initial_tab: 'admin' });
    const { container } = render(<PlayerTicketPanel />);
    expect(container.textContent).toContain('Укажите имена причастных');
  });

  test('без начальной вкладки открывается администрация', () => {
    setupStore();
    const { container } = render(<PlayerTicketPanel />);
    expect(container.textContent).toContain('Укажите имена причастных');
  });
});

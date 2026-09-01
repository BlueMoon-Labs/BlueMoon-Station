import {
  selectChat,
  selectChatPageById,
  selectChatPages,
  selectCurrentChatPage,
} from './selectors';

const createState = (overrides = {}) => ({
  chat: {
    currentPageId: 'page1',
    pages: ['page1', 'page2'],
    pageById: {
      page1: { id: 'page1', name: 'Main', unreadCount: 0 },
      page2: { id: 'page2', name: 'Radio', unreadCount: 3 },
    },
    ...overrides,
  },
});

describe('selectChat', () => {
  test('returns the chat slice of state', () => {
    const state = createState();
    expect(selectChat(state)).toBe(state.chat);
  });
});

describe('selectChatPages', () => {
  test('maps page IDs to page objects in order', () => {
    const state = createState();
    const pages = selectChatPages(state);

    expect(pages).toEqual([
      { id: 'page1', name: 'Main', unreadCount: 0 },
      { id: 'page2', name: 'Radio', unreadCount: 3 },
    ]);
  });

  test('preserves page order from pages array', () => {
    const state = createState({
      pages: ['page2', 'page1'],
    });
    const pages = selectChatPages(state);

    expect(pages[0].id).toBe('page2');
    expect(pages[1].id).toBe('page1');
  });

  test('returns empty array when no pages', () => {
    const state = createState({ pages: [], pageById: {} });
    expect(selectChatPages(state)).toEqual([]);
  });
});

describe('selectCurrentChatPage', () => {
  test('returns the page matching currentPageId', () => {
    const state = createState();
    const page = selectCurrentChatPage(state);

    expect(page).toEqual({ id: 'page1', name: 'Main', unreadCount: 0 });
  });

  test('returns undefined for nonexistent currentPageId', () => {
    const state = createState({ currentPageId: 'nonexistent' });
    expect(selectCurrentChatPage(state)).toBeUndefined();
  });
});

describe('selectChatPageById', () => {
  test('returns page for existing id', () => {
    const state = createState();
    const page = selectChatPageById('page2')(state);

    expect(page).toEqual({ id: 'page2', name: 'Radio', unreadCount: 3 });
  });

  test('returns undefined for nonexistent id', () => {
    const state = createState();
    expect(selectChatPageById('nope')(state)).toBeUndefined();
  });

  test('is a curried function', () => {
    const selector = selectChatPageById('page1');
    expect(typeof selector).toBe('function');

    const state = createState();
    expect(selector(state).id).toBe('page1');
  });
});

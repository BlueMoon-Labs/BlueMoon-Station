import {
  addChatPage,
  changeChatPage,
  changeScrollTracking,
  loadChat,
  removeChatPage,
  toggleAcceptedType,
  updateMessageCount,
} from './actions';
import { MESSAGE_TYPES } from './constants';
import { createMainPage, createPage } from './model';
import { chatReducer, initialState } from './reducer';

describe('chatReducer', () => {
  describe('loadChat', () => {
    test('loads state when version matches', () => {
      const page = createPage({ id: 'p1', acceptedTypes: { ooc: true } });
      const payload = {
        version: 5,
        currentPageId: 'p1',
        scrollTracking: true,
        pages: ['p1'],
        pageById: {
          p1: { ...page, unreadCount: 10 },
        },
      };
      const state = chatReducer(initialState, loadChat(payload));

      expect(state.currentPageId).toBe('p1');
      expect(state.pages).toEqual(['p1']);
      // unreadCount should be reset to 0
      expect(state.pageById.p1.unreadCount).toBe(0);
    });

    test('rejects state when version does not match', () => {
      const payload = {
        version: 4,
        currentPageId: 'x',
        pages: ['x'],
        pageById: {},
      };
      const state = chatReducer(initialState, loadChat(payload));

      expect(state).toBe(initialState);
    });

    test('rejects state when payload is undefined', () => {
      const state = chatReducer(initialState, loadChat());

      expect(state).toBe(initialState);
    });

    test('resets unread counts for all pages on load', () => {
      const payload = {
        version: 5,
        currentPageId: 'a',
        scrollTracking: true,
        pages: ['a', 'b'],
        pageById: {
          a: { id: 'a', unreadCount: 5, acceptedTypes: {} },
          b: { id: 'b', unreadCount: 15, acceptedTypes: {} },
        },
      };
      const state = chatReducer(initialState, loadChat(payload));

      expect(state.pageById.a.unreadCount).toBe(0);
      expect(state.pageById.b.unreadCount).toBe(0);
    });
  });

  describe('changeScrollTracking', () => {
    test('enables tracking and resets current page unread', () => {
      // Set up state with unread on current page
      const currentId = initialState.currentPageId;
      const stateWithUnread = {
        ...initialState,
        scrollTracking: false,
        pageById: {
          ...initialState.pageById,
          [currentId]: {
            ...initialState.pageById[currentId],
            unreadCount: 7,
          },
        },
      };
      const state = chatReducer(
        stateWithUnread,
        changeScrollTracking(true),
      );

      expect(state.scrollTracking).toBe(true);
      expect(state.pageById[currentId].unreadCount).toBe(0);
    });

    test('disables tracking without resetting unread', () => {
      const currentId = initialState.currentPageId;
      const stateWithUnread = {
        ...initialState,
        scrollTracking: true,
        pageById: {
          ...initialState.pageById,
          [currentId]: {
            ...initialState.pageById[currentId],
            unreadCount: 7,
          },
        },
      };
      const state = chatReducer(
        stateWithUnread,
        changeScrollTracking(false),
      );

      expect(state.scrollTracking).toBe(false);
      expect(state.pageById[currentId].unreadCount).toBe(7);
    });
  });

  describe('updateMessageCount', () => {
    // Setup: two pages. Page A (current, all types), Page B (only radio)
    const setupTwoPages = (scrollTracking = true) => {
      const mainPage = createMainPage();
      const radioPage = createPage({
        id: 'radio-only',
        name: 'Radio',
        acceptedTypes: { radio: true },
      });
      return {
        version: 5,
        currentPageId: mainPage.id,
        scrollTracking,
        pages: [mainPage.id, radioPage.id],
        pageById: {
          [mainPage.id]: mainPage,
          [radioPage.id]: radioPage,
        },
      };
    };

    test('skips current page when scroll tracked', () => {
      const state = setupTwoPages(true);
      const next = chatReducer(
        state,
        updateMessageCount({ localchat: 3 }),
      );

      // Current page is scroll tracked — no unread increment
      expect(next.pageById[state.currentPageId].unreadCount).toBe(0);
    });

    test('skips non-current page when type visible on current page', () => {
      const state = setupTwoPages(true);
      // "radio" is accepted by BOTH current (main page) and radio page
      const next = chatReducer(
        state,
        updateMessageCount({ radio: 2 }),
      );

      // Current page is tracked — skip it.
      // Radio page accepts radio, but current page also accepts radio
      // -> line 80-82: skip (same message visible on current page)
      expect(next.pageById['radio-only'].unreadCount).toBe(0);
    });

    test('increments unread when type NOT visible on current page', () => {
      // Setup: current page does NOT accept radio, other page does
      const mainPage = createPage({
        id: 'main-no-radio',
        name: 'NoRadio',
        acceptedTypes: { localchat: true },
      });
      const radioPage = createPage({
        id: 'radio-tab',
        name: 'Radio',
        acceptedTypes: { radio: true },
      });
      const state = {
        version: 5,
        currentPageId: mainPage.id,
        scrollTracking: true,
        pages: [mainPage.id, radioPage.id],
        pageById: {
          [mainPage.id]: mainPage,
          [radioPage.id]: radioPage,
        },
      };

      const next = chatReducer(
        state,
        updateMessageCount({ radio: 5 }),
      );

      // Current page doesn't accept radio, radio page does
      // -> radio page gets +5 unread
      expect(next.pageById['radio-tab'].unreadCount).toBe(5);
    });

    test('increments unread on current page when not scroll tracked', () => {
      const state = setupTwoPages(false);
      const next = chatReducer(
        state,
        updateMessageCount({ localchat: 2 }),
      );

      // Not scroll tracked — current page CAN get unread
      // But localchat is also on current page, so other pages
      // that accept it should not get unread (line 80)
      expect(next.pageById[state.currentPageId].unreadCount).toBe(2);
    });
  });

  describe('addChatPage', () => {
    test('adds page and switches to it', () => {
      const state = chatReducer(initialState, addChatPage());

      expect(state.pages.length).toBe(initialState.pages.length + 1);
      const newPageId = state.pages[state.pages.length - 1];
      expect(state.currentPageId).toBe(newPageId);
      expect(state.pageById[newPageId]).toBeDefined();
    });
  });

  describe('changeChatPage', () => {
    test('switches page and resets unread', () => {
      // Add a second page first
      let state = chatReducer(initialState, addChatPage());
      const secondPageId = state.currentPageId;

      // Switch back to original
      const originalId = initialState.currentPageId;
      state = {
        ...state,
        pageById: {
          ...state.pageById,
          [originalId]: {
            ...state.pageById[originalId],
            unreadCount: 10,
          },
        },
      };

      state = chatReducer(
        state,
        changeChatPage({ pageId: originalId }),
      );

      expect(state.currentPageId).toBe(originalId);
      expect(state.pageById[originalId].unreadCount).toBe(0);
    });
  });

  describe('toggleAcceptedType', () => {
    test('toggles type from undefined to true', () => {
      const pageId = initialState.currentPageId;
      // First ensure the type doesn't exist
      const stateWithoutType = {
        ...initialState,
        pageById: {
          ...initialState.pageById,
          [pageId]: {
            ...initialState.pageById[pageId],
            acceptedTypes: {},
          },
        },
      };

      const state = chatReducer(
        stateWithoutType,
        toggleAcceptedType({ pageId, type: 'radio' }),
      );

      expect(state.pageById[pageId].acceptedTypes.radio).toBe(true);
    });

    test('toggles type from true to false', () => {
      const pageId = initialState.currentPageId;
      const stateWithType = {
        ...initialState,
        pageById: {
          ...initialState.pageById,
          [pageId]: {
            ...initialState.pageById[pageId],
            acceptedTypes: { radio: true },
          },
        },
      };

      const state = chatReducer(
        stateWithType,
        toggleAcceptedType({ pageId, type: 'radio' }),
      );

      expect(state.pageById[pageId].acceptedTypes.radio).toBe(false);
    });

    test('does not mutate original state', () => {
      const pageId = initialState.currentPageId;
      const originalAccepted = {
        ...initialState.pageById[pageId].acceptedTypes,
      };

      chatReducer(
        initialState,
        toggleAcceptedType({ pageId, type: 'radio' }),
      );

      // Original state should be unchanged
      expect(initialState.pageById[pageId].acceptedTypes).toEqual(
        originalAccepted,
      );
    });
  });

  describe('removeChatPage', () => {
    test('removes non-current page without changing current', () => {
      let state = chatReducer(initialState, addChatPage());
      const addedPageId = state.currentPageId;

      // Switch back to original
      const originalId = initialState.currentPageId;
      state = chatReducer(
        state,
        changeChatPage({ pageId: originalId }),
      );

      // Remove the added page
      state = chatReducer(state, removeChatPage({ pageId: addedPageId }));

      expect(state.currentPageId).toBe(originalId);
      expect(state.pages).not.toContain(addedPageId);
      expect(state.pageById[addedPageId]).toBeUndefined();
    });

    test('falls back to first page when removing current', () => {
      // Add a second page and stay on it
      let state = chatReducer(initialState, addChatPage());
      const secondPageId = state.currentPageId;
      const firstPageId = state.pages[0];

      // Remove current (second) page
      state = chatReducer(state, removeChatPage({ pageId: secondPageId }));

      expect(state.currentPageId).toBe(firstPageId);
      expect(state.pages).not.toContain(secondPageId);
    });

    test('recreates main page when all pages removed', () => {
      // Start with just the main page, remove it
      const mainPageId = initialState.currentPageId;
      const state = chatReducer(
        initialState,
        removeChatPage({ pageId: mainPageId }),
      );

      // Should have recreated a page
      expect(state.pages.length).toBe(1);
      expect(state.currentPageId).toBeDefined();
      const recreatedPage = state.pageById[state.currentPageId];
      expect(recreatedPage).toBeDefined();
      // Verify it's a proper main page with all message types accepted
      for (const typeDef of MESSAGE_TYPES) {
        expect(recreatedPage.acceptedTypes[typeDef.type]).toBe(true);
      }
    });
  });

  describe('unknown action', () => {
    test('returns state unchanged for unknown action types', () => {
      const state = chatReducer(initialState, { type: 'UNKNOWN_ACTION' });
      expect(state).toBe(initialState);
    });
  });
});

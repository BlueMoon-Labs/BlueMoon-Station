import { MESSAGE_TYPES } from './constants';
import {
  canPageAcceptType,
  createMainPage,
  createMessage,
  createPage,
  isSameMessage,
  serializeMessage,
} from './model';

describe('canPageAcceptType', () => {
  test('accepts internal types regardless of page config', () => {
    const page = { acceptedTypes: {} };
    expect(canPageAcceptType(page, 'internal/reconnected')).toBe(true);
    expect(canPageAcceptType(page, 'internal/anything')).toBe(true);
  });

  test('accepts types enabled in page config', () => {
    const page = { acceptedTypes: { localchat: true } };
    expect(canPageAcceptType(page, 'localchat')).toBe(true);
  });

  test('rejects types not in page config', () => {
    const page = { acceptedTypes: { localchat: true } };
    expect(canPageAcceptType(page, 'radio')).toBeFalsy();
  });

  test('rejects types explicitly set to false', () => {
    const page = { acceptedTypes: { localchat: false } };
    expect(canPageAcceptType(page, 'localchat')).toBeFalsy();
  });

  test('rejects types with undefined in acceptedTypes', () => {
    const page = { acceptedTypes: {} };
    expect(canPageAcceptType(page, 'ooc')).toBeFalsy();
  });

  test('bare "internal" type is also accepted (prefix match)', () => {
    const page = { acceptedTypes: {} };
    expect(canPageAcceptType(page, 'internal')).toBe(true);
  });
});

describe('createPage', () => {
  test('generates unique ids', () => {
    const a = createPage();
    const b = createPage();
    expect(a.id).toBeDefined();
    expect(b.id).toBeDefined();
    expect(a.id).not.toBe(b.id);
  });

  test('has default name "New Tab"', () => {
    expect(createPage().name).toBe('New Tab');
  });

  test('has empty acceptedTypes by default', () => {
    expect(createPage().acceptedTypes).toEqual({});
  });

  test('has zero unreadCount by default', () => {
    expect(createPage().unreadCount).toBe(0);
  });

  test('custom properties override defaults', () => {
    const page = createPage({ name: 'Custom', unreadCount: 5 });
    expect(page.name).toBe('Custom');
    expect(page.unreadCount).toBe(5);
  });

  test('custom id overrides generated id', () => {
    const page = createPage({ id: 'fixed-id' });
    expect(page.id).toBe('fixed-id');
  });
});

describe('createMainPage', () => {
  test('has name "Main"', () => {
    expect(createMainPage().name).toBe('Main');
  });

  test('accepts all defined message types', () => {
    const page = createMainPage();
    for (const typeDef of MESSAGE_TYPES) {
      expect(page.acceptedTypes[typeDef.type]).toBe(true);
    }
  });

  test('does not contain arbitrary extra types', () => {
    const page = createMainPage();
    const definedTypes = new Set(MESSAGE_TYPES.map((t) => t.type));
    for (const key of Object.keys(page.acceptedTypes)) {
      expect(definedTypes.has(key)).toBe(true);
    }
  });
});

describe('createMessage', () => {
  afterEach(() => jest.restoreAllMocks());

  test('assigns createdAt from Date.now by default', () => {
    const now = 1700000000000;
    jest.spyOn(Date, 'now').mockReturnValue(now);
    const msg = createMessage({ text: 'hello' });
    expect(msg.createdAt).toBe(now);
  });

  test('payload can override createdAt', () => {
    const msg = createMessage({ text: 'hello', createdAt: 12345 });
    expect(msg.createdAt).toBe(12345);
  });

  test('passes through all payload properties', () => {
    const msg = createMessage({ text: 'hi', type: 'ooc', custom: 123 });
    expect(msg.text).toBe('hi');
    expect(msg.type).toBe('ooc');
    expect(msg.custom).toBe(123);
  });
});

describe('serializeMessage', () => {
  test('keeps only type, text, html, times, createdAt', () => {
    const msg = {
      type: 'ooc',
      text: 'hi',
      html: '<b>hi</b>',
      times: 3,
      createdAt: 12345,
      node: document.createElement('div'),
      custom: 'extra',
    };
    const serialized = serializeMessage(msg);
    expect(serialized).toEqual({
      type: 'ooc',
      text: 'hi',
      html: '<b>hi</b>',
      times: 3,
      createdAt: 12345,
    });
  });

  test('does not include node property', () => {
    const msg = {
      type: 'system',
      text: 'test',
      node: document.createElement('div'),
    };
    expect(serializeMessage(msg)).not.toHaveProperty('node');
  });

  test('undefined fields are preserved as undefined', () => {
    const serialized = serializeMessage({ type: 'ooc' });
    expect(serialized.text).toBeUndefined();
    expect(serialized.html).toBeUndefined();
    expect(serialized.times).toBeUndefined();
    expect(serialized.createdAt).toBeUndefined();
  });
});

describe('isSameMessage', () => {
  test('matches messages with identical text', () => {
    expect(isSameMessage({ text: 'hello' }, { text: 'hello' })).toBe(true);
  });

  test('does not match messages with different text', () => {
    expect(isSameMessage({ text: 'hello' }, { text: 'world' })).toBe(false);
  });

  test('matches messages with identical html', () => {
    expect(
      isSameMessage({ html: '<b>hi</b>' }, { html: '<b>hi</b>' }),
    ).toBe(true);
  });

  test('does not match messages with different html', () => {
    expect(
      isSameMessage({ html: '<b>a</b>' }, { html: '<b>b</b>' }),
    ).toBe(false);
  });

  test('matches when text matches even if html differs', () => {
    expect(
      isSameMessage(
        { text: 'hello', html: '<b>a</b>' },
        { text: 'hello', html: '<b>b</b>' },
      ),
    ).toBe(true);
  });

  test('matches when html matches even if text differs', () => {
    expect(
      isSameMessage(
        { text: 'a', html: '<b>hi</b>' },
        { text: 'b', html: '<b>hi</b>' },
      ),
    ).toBe(true);
  });

  test('does not match when neither text nor html is string', () => {
    expect(
      isSameMessage({ text: undefined }, { text: undefined }),
    ).toBe(false);
  });

  test('null text does not match', () => {
    expect(isSameMessage({ text: null }, { text: null })).toBe(false);
  });

  test('number type text does not match even if equal', () => {
    expect(isSameMessage({ text: 42 }, { text: 42 })).toBe(false);
  });

  test('empty string messages are not considered same', () => {
    expect(isSameMessage({ text: '' }, { text: '' })).toBe(false);
  });

  test('empty html messages are not considered same', () => {
    expect(isSameMessage({ html: '' }, { html: '' })).toBe(false);
  });
});

import { SETTLE_KEEP, settleOldMessages } from './messageFx';

const makeNode = html => {
  const node = document.createElement('div');
  node.className = 'ChatMessage';
  node.innerHTML = html;
  return node;
};

describe('settleOldMessages', () => {
  const makeMessages = n => Array.from({ length: n }, () => ({
    node: makeNode('x'),
  }));
  test('keeps last SETTLE_KEEP unsettled', () => {
    const messages = makeMessages(SETTLE_KEEP + 5);
    settleOldMessages(messages, false);
    const settled = messages.filter(m =>
      m.node.classList.contains('ChatMessage--settled'));
    expect(settled.length).toBe(5);
    expect(messages[4].node.classList.contains('ChatMessage--settled'))
      .toBe(true);
    expect(messages[5].node.classList.contains('ChatMessage--settled'))
      .toBe(false);
  });
  test('incremental pass stops at first settled', () => {
    const messages = makeMessages(SETTLE_KEEP + 2);
    settleOldMessages(messages, false);
    messages.push(...makeMessages(1));
    settleOldMessages(messages, false);
    expect(messages[2].node.classList.contains('ChatMessage--settled'))
      .toBe(true);
  });
  test('full pass settles gaps', () => {
    const messages = makeMessages(SETTLE_KEEP + 3);
    messages[SETTLE_KEEP + 2 - SETTLE_KEEP].node.classList
      .add('ChatMessage--settled');
    settleOldMessages(messages, true);
    expect(messages[0].node.classList.contains('ChatMessage--settled'))
      .toBe(true);
  });
  test('incremental pass leaves messages before a settled one alone', () => {
    const messages = makeMessages(SETTLE_KEEP + 3);
    messages[2].node.classList.add('ChatMessage--settled');
    settleOldMessages(messages, false);
    expect(messages[0].node.classList.contains('ChatMessage--settled'))
      .toBe(false);
    expect(messages[1].node.classList.contains('ChatMessage--settled'))
      .toBe(false);
  });
  test('full pass wakes the fresh window', () => {
    const messages = makeMessages(SETTLE_KEEP + 2);
    for (const message of messages) {
      message.node.classList.add('ChatMessage--settled');
    }
    settleOldMessages(messages, true);
    const settled = messages.map(m =>
      m.node.classList.contains('ChatMessage--settled'));
    expect(settled.slice(0, 2)).toEqual([true, true]);
    expect(settled.slice(2).some(Boolean)).toBe(false);
  });
  test('skips pruned nodes', () => {
    const messages = makeMessages(SETTLE_KEEP + 1);
    messages[0].node = 'pruned';
    expect(() => settleOldMessages(messages, true)).not.toThrow();
  });
});

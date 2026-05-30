const { createReloadHandler } = require('./client.cjs');

describe('createReloadHandler', () => {
  test('calls reload on hotUpdate message', () => {
    const reload = jest.fn();
    const handler = createReloadHandler(reload);
    handler({ type: 'hotUpdate' });
    expect(reload).toHaveBeenCalledTimes(1);
  });

  test('ignores other message types', () => {
    const reload = jest.fn();
    const handler = createReloadHandler(reload);
    handler({ type: 'log' });
    handler(null);
    expect(reload).not.toHaveBeenCalled();
  });
});

/**
 * Layout regression tests after the React migration.
 *
 * React appends 'px' to numeric values of unknown (kebab-case) style
 * properties, which produces invalid CSS like 'flex-grow: 1px' and
 * silently collapses every growing Stack/Flex item (empty vending
 * lists, missing vote buttons, zero-height chat). These tests pin the
 * camelCase style keys in Flex/Stack.
 */
import { render } from '@testing-library/react';

import { Flex } from './Flex';
import { Stack } from './Stack';

describe('Flex', () => {
  test('direction lands in inline style', () => {
    const { container } = render(<Flex direction="column">x</Flex>);
    const flex = container.querySelector('.Flex');
    expect(flex.style.flexDirection).toBe('column');
  });

  test('numeric grow produces a unitless flex-grow', () => {
    const { container } = render(
      <Flex>
        <Flex.Item grow={1}>x</Flex.Item>
      </Flex>,
    );
    const item = container.querySelector('.Flex__item');
    expect(item.style.flexGrow).toBe('1');
  });

  test('consumer style merges with computed flex styles', () => {
    const { container } = render(
      <Flex direction="column" style={{ padding: '4px' }}>x</Flex>,
    );
    const flex = container.querySelector('.Flex');
    expect(flex.style.flexDirection).toBe('column');
    expect(flex.style.padding).toBe('4px');
  });

  test('consumer flexWrap in style survives absent wrap prop', () => {
    // Regression: emote panel passes wrap via style, not the wrap prop.
    // Computed flexWrap: undefined must not clobber it.
    const { container } = render(
      <Flex align="center" style={{ flexWrap: 'wrap' }}>x</Flex>,
    );
    const flex = container.querySelector('.Flex');
    expect(flex.style.flexWrap).toBe('wrap');
    expect(flex.style.alignItems).toBe('center');
  });

  test('consumer alignSelf in item style survives absent align prop', () => {
    const { container } = render(
      <Flex>
        <Flex.Item style={{ alignSelf: 'flex-end', order: 2 }}>x</Flex.Item>
      </Flex>,
    );
    const item = container.querySelector('.Flex__item');
    expect(item.style.alignSelf).toBe('flex-end');
    expect(item.style.order).toBe('2');
  });
});

describe('Stack', () => {
  test('vertical stack with growing item keeps flex styles', () => {
    const { container } = render(
      <Stack fill vertical>
        <Stack.Item>header</Stack.Item>
        <Stack.Item grow>body</Stack.Item>
      </Stack>,
    );
    const stack = container.querySelector('.Stack');
    expect(stack.style.flexDirection).toBe('column');
    const items = container.querySelectorAll('.Stack__item');
    expect(items[1].style.flexGrow).toBe('1');
    expect(stack.textContent).toBe('headerbody');
  });
});

/**
 * Behavioral tests for Dropdown after the React migration.
 * Guards the async setState fix: the menu must receive focus after
 * opening (it only exists in the DOM after the re-render commits).
 */
import { fireEvent, render } from '@testing-library/react';

import { Dropdown } from './Dropdown';

const getControl = container =>
  container.querySelector('.Dropdown__control');

describe('Dropdown', () => {
  test('opens the menu on click', () => {
    const { container } = render(
      <Dropdown options={['a', 'b']} selected="a" onSelected={() => {}} />,
    );
    expect(container.querySelector('.Dropdown__menu')).toBeNull();
    fireEvent.click(getControl(container));
    expect(container.querySelector('.Dropdown__menu')).not.toBeNull();
  });

  test('menu receives focus after opening', () => {
    const { container } = render(
      <Dropdown options={['a', 'b']} selected="a" onSelected={() => {}} />,
    );
    fireEvent.click(getControl(container));
    const menu = container.querySelector('.Dropdown__menu');
    expect(document.activeElement).toBe(menu);
  });

  test('selecting an option fires onSelected and closes the menu', () => {
    const onSelected = jest.fn();
    const { container, getByText } = render(
      <Dropdown options={['a', 'b']} selected="a" onSelected={onSelected} />,
    );
    fireEvent.click(getControl(container));
    fireEvent.click(getByText('b'));
    expect(onSelected).toHaveBeenCalledWith('b');
    expect(container.querySelector('.Dropdown__menu')).toBeNull();
  });

  test('disabled dropdown does not open', () => {
    const { container } = render(
      <Dropdown
        disabled
        options={['a', 'b']}
        selected="a"
        onSelected={() => {}}
      />,
    );
    fireEvent.click(getControl(container));
    expect(container.querySelector('.Dropdown__menu')).toBeNull();
  });
});

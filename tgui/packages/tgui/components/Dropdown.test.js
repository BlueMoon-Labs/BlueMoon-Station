/**
 * Behavioral tests for Dropdown after the React migration.
 * Guards the async setState fix: the menu must receive focus after
 * opening (it only exists in the DOM after the re-render commits).
 */
import { fireEvent, render, within } from '@testing-library/react';

import { Dropdown } from './Dropdown';

const getControl = container =>
  container.querySelector('.Dropdown__control');

// Контрол повторяет подпись выбранного варианта, поэтому клик по строке меню
// ищется внутри самого меню, иначе запрос находит два узла сразу.
const inMenu = container =>
  within(container.querySelector('.Dropdown__menu'));

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

  test('вариант может нести значение, отличное от подписи', () => {
    const onSelected = jest.fn();
    const { container, getByText } = render(
      <Dropdown
        options={[
          { value: 'healium', displayText: 'Хилий' },
          { value: 'nitrium', displayText: 'Нитрий' },
        ]}
        selected="healium"
        onSelected={onSelected}
      />,
    );
    fireEvent.click(getControl(container));
    fireEvent.click(getByText('Нитрий'));
    expect(onSelected).toHaveBeenCalledWith('nitrium');
  });

  test('строковые варианты продолжают работать как прежде', () => {
    const onSelected = jest.fn();
    const { container, getByText } = render(
      <Dropdown options={['a', 'b']} selected="a" onSelected={onSelected} />,
    );
    fireEvent.click(getControl(container));
    fireEvent.click(getByText('b'));
    expect(onSelected).toHaveBeenCalledWith('b');
  });

  // Полупара ломалась асимметрично: { value } падал громко, на «Objects are
  // not valid as a React child», а { displayText } — молча, значением
  // становился сам объект, и в act() уходил мусор.
  test('вариант из одной подписи выбирается подписью', () => {
    const onSelected = jest.fn();
    const { container, getByText } = render(
      <Dropdown
        options={[{ displayText: 'Хилий' }, { displayText: 'Нитрий' }]}
        selected="Хилий"
        onSelected={onSelected}
      />,
    );
    fireEvent.click(getControl(container));
    fireEvent.click(getByText('Нитрий'));
    expect(onSelected).toHaveBeenCalledWith('Нитрий');
  });

  test('вариант из одного значения рисуется значением', () => {
    const onSelected = jest.fn();
    const { container, getByText } = render(
      <Dropdown
        options={[{ value: 'healium' }, { value: 'nitrium' }]}
        selected="healium"
        onSelected={onSelected}
      />,
    );
    fireEvent.click(getControl(container));
    fireEvent.click(getByText('nitrium'));
    expect(onSelected).toHaveBeenCalledWith('nitrium');
  });

  // Пара распознаётся по наличию ключей, а не по typeof === 'object': окна
  // кладут в options готовые React-элементы, и те обязаны рендериться как есть.
  test('React-элемент в вариантах остаётся самим собой', () => {
    const onSelected = jest.fn();
    const { container } = render(
      <Dropdown
        options={[<b key="a">жирный</b>, 'b']}
        selected="b"
        onSelected={onSelected}
      />,
    );
    fireEvent.click(getControl(container));
    expect(container.querySelector('.Dropdown__menuentry b')).not.toBeNull();
    fireEvent.click(inMenu(container).getByText('b'));
    expect(onSelected).toHaveBeenCalledWith('b');
  });

  // Проверка идёт через !== undefined, а не на истинность: «упрощение» до
  // option?.value ? ... : option молча съело бы 0 и пустую строку.
  test('значение может быть нулём или пустой строкой', () => {
    const onSelected = jest.fn();
    const { container } = render(
      <Dropdown
        options={[
          { value: 0, displayText: 'Ноль' },
          { value: '', displayText: 'Пусто' },
        ]}
        selected={0}
        onSelected={onSelected}
      />,
    );
    fireEvent.click(getControl(container));
    fireEvent.click(inMenu(container).getByText('Ноль'));
    expect(onSelected).toHaveBeenCalledWith(0);
  });

  test('контрол показывает подпись выбранного, а не его значение', () => {
    const { container } = render(
      <Dropdown
        options={[
          { value: 'healium', displayText: 'Хилий' },
          { value: 'nitrium', displayText: 'Нитрий' },
        ]}
        selected="nitrium"
        onSelected={() => {}}
      />,
    );
    const control = getControl(container);
    expect(control.textContent).toContain('Нитрий');
    expect(control.textContent).not.toContain('nitrium');
  });

  // Машина имеет право молча отвергнуть выбор (omni_devices.dm применяет
  // смену газа только на порту с ролью filter). Тогда бэкенд продолжает
  // слать прежний selected, и контрол обязан вернуться к нему сам.
  test('подпись контрола едет за пропом selected', () => {
    const options = [
      { value: 'healium', displayText: 'Хилий' },
      { value: 'nitrium', displayText: 'Нитрий' },
    ];
    const { container, rerender } = render(
      <Dropdown options={options} selected="healium" onSelected={() => {}} />,
    );
    expect(getControl(container).textContent).toContain('Хилий');
    rerender(
      <Dropdown options={options} selected="nitrium" onSelected={() => {}} />,
    );
    expect(getControl(container).textContent).toContain('Нитрий');
    expect(getControl(container).textContent).not.toContain('Хилий');
  });

  // Молчаливый отказ: бэкенд не применил выбор и продолжает слать прежнее
  // значение. Подпись обязана откатиться на него, а не остаться на том, что
  // ткнул игрок, — иначе контрол врёт о состоянии машины до переоткрытия окна.
  // Проп при этом не меняется, так что на сравнении prevProps с props такой
  // откат не ловится в принципе.
  test('молчаливый отказ бэкенда возвращает подпись на его значение', () => {
    const options = [
      { value: 'healium', displayText: 'Хилий' },
      { value: 'nitrium', displayText: 'Нитрий' },
    ];
    const { container, rerender } = render(
      <Dropdown options={options} selected="healium" onSelected={() => {}} />,
    );
    fireEvent.click(getControl(container));
    fireEvent.click(inMenu(container).getByText('Нитрий'));
    rerender(
      <Dropdown options={options} selected="healium" onSelected={() => {}} />,
    );
    expect(getControl(container).textContent).toContain('Хилий');
    expect(getControl(container).textContent).not.toContain('Нитрий');
  });

  // Управляемость определяется наличием пропа, а не его истинностью: 0 и
  // пустая строка — валидный выбор, и на них откат обязан работать так же.
  test('нулевое значение пропа тоже держит подпись под бэкендом', () => {
    const options = [
      { value: 0, displayText: 'Ноль' },
      { value: '', displayText: 'Пусто' },
    ];
    const { container, rerender } = render(
      <Dropdown options={options} selected={0} onSelected={() => {}} />,
    );
    fireEvent.click(getControl(container));
    fireEvent.click(inMenu(container).getByText('Пусто'));
    rerender(<Dropdown options={options} selected={0} onSelected={() => {}} />);
    expect(getControl(container).textContent).toContain('Ноль');
    expect(getControl(container).textContent).not.toContain('Пусто');
  });

  // Дюжина окон (BrigTimer, Filteriffic, VariableMenu, MODsuit, PlayerPanel2,
  // Techweb, SDQLSpellMenu, CircuitModule, FundamentalTypes, CommandReport,
  // ShuttleManipulator, AdminLogViewer — 18 вызовов на всех) проп selected не
  // передаёт вовсе. Для них выбор живёт только в контроле, и
  // подпись обязана остаться на том, что выбрал игрок.
  test('без пропа selected выбор игрока остаётся на контроле', () => {
    const options = ['a', 'b'];
    const { container, rerender } = render(
      <Dropdown options={options} onSelected={() => {}} />,
    );
    fireEvent.click(getControl(container));
    fireEvent.click(inMenu(container).getByText('b'));
    expect(getControl(container).textContent).toContain('b');
    rerender(<Dropdown options={options} onSelected={() => {}} />);
    expect(getControl(container).textContent).toContain('b');
  });

  // options приходит из окон как есть: ComplexModal.js, IPCConstructor.js и
  // MailAdminPanel.js умеют положить туда не-массив. Поиск подписи живёт в
  // render(), поэтому такой вызов ронял бы всё окно, а не только клик.
  test('не-массив в options не роняет рендер', () => {
    const { container } = render(
      <Dropdown
        options={{ healium: 'Хилий' }}
        selected="healium"
        onSelected={() => {}}
      />,
    );
    expect(getControl(container).textContent).toContain('healium');
    fireEvent.click(getControl(container));
    expect(container.querySelector('.Dropdown__menu').textContent).toBe(
      'No Options Found',
    );
  });

  test('переданный displayText перекрывает подпись из вариантов', () => {
    const { container } = render(
      <Dropdown
        options={[{ value: 'healium', displayText: 'Хилий' }]}
        selected="healium"
        displayText="Выбрать газ"
        onSelected={() => {}}
      />,
    );
    expect(getControl(container).textContent).toContain('Выбрать газ');
  });
});

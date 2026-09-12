import { act, fireEvent, render, screen } from '@testing-library/react';

import { HereticBookAtmosphere } from './HereticBookAtmosphere';

describe('Живой переплёт гримуара', () => {
  beforeEach(() => jest.useFakeTimers());
  afterEach(() => {
    jest.clearAllTimers();
    jest.useRealTimers();
  });

  test.each([
    ['Flesh', 'Разбудить глаз в переплёте'],
    ['Ash', 'Раздуть уголь на обложке'],
    ['Cosmic', 'Отпустить комету'],
    ['Rust', 'Повернуть ржавую шестерню'],
    ['Void', 'Коснуться ледяного кристалла'],
    ['Blade', 'Провести пальцем по лезвию'],
    ['Moon', 'Коснуться зеркальной капли'],
    ['Lock', 'Повернуть ключ в переплёте'],
    ['Tide', 'Раскачать затонувший колокол'],
    ['Glass', 'Преломить свет в застёжке'],
    ['Blood', 'Перевернуть алую ампулу'],
    ['Echo', 'Коснуться струн погребальной лиры'],
  ])('%s: отдельная доступная игрушка откликается и возвращается в покой', (path, label) => {
    render(<HereticBookAtmosphere path={path} presentation="living" reducedMotion={false} />);
    const toy = screen.getByRole('button', { name: label });
    expect(toy.tagName).toBe('BUTTON');
    expect(toy.getAttribute('type')).toBe('button');
    expect(toy.getAttribute('aria-pressed')).toBe('false');
    fireEvent.click(toy);
    expect(toy.getAttribute('aria-pressed')).toBe('true');
    expect(jest.getTimerCount()).toBe(1);
    act(() => jest.advanceTimersByTime(2800));
    expect(toy.getAttribute('aria-pressed')).toBe('false');
    expect(jest.getTimerCount()).toBe(0);
  });

  test('серия нажатий не добавляет частицы, таймеры и время жизни отклика', () => {
    const view = render(<HereticBookAtmosphere path="Ash" presentation="living" reducedMotion={false} />);
    const count = view.container.querySelectorAll('svg *').length;
    const toy = screen.getByRole('button');
    for (let attempt = 0; attempt < 20; attempt++) fireEvent.click(toy);
    expect(jest.getTimerCount()).toBe(1);
    expect(view.container.querySelectorAll('svg *')).toHaveLength(count);
    act(() => jest.advanceTimersByTime(1400));
    fireEvent.click(toy);
    act(() => jest.advanceTimersByTime(1400));
    expect(toy.getAttribute('aria-pressed')).toBe('false');
    expect(jest.getTimerCount()).toBe(0);
    fireEvent.click(toy);
    expect(toy.getAttribute('aria-pressed')).toBe('true');
    expect(jest.getTimerCount()).toBe(1);
  });

  test('смена материала или интенсивности убирает прежний отклик и его таймер', () => {
    const view = render(<HereticBookAtmosphere path="Flesh" presentation="living" reducedMotion={false} />);
    fireEvent.click(screen.getByRole('button'));
    expect(jest.getTimerCount()).toBe(1);
    view.rerender(<HereticBookAtmosphere path="Moon" presentation="living" reducedMotion={false} />);
    expect(jest.getTimerCount()).toBe(0);
    expect(screen.getByRole('button').getAttribute('aria-pressed')).toBe('false');
    fireEvent.click(screen.getByRole('button'));
    view.rerender(<HereticBookAtmosphere path="Moon" presentation="muted" reducedMotion={false} />);
    expect(jest.getTimerCount()).toBe(0);
    expect(screen.getByRole('button').getAttribute('aria-pressed')).toBe('false');
    fireEvent.click(screen.getByRole('button'));
    view.rerender(<HereticBookAtmosphere path="Moon" presentation="muted" reducedMotion />);
    expect(jest.getTimerCount()).toBe(0);
    expect(screen.getByRole('button').getAttribute('aria-pressed')).toBe('false');
  });

  test('закрытие книги отменяет незавершённую реакцию', () => {
    const view = render(<HereticBookAtmosphere path="Cosmic" presentation="living" reducedMotion={false} />);
    fireEvent.click(screen.getByRole('button'));
    expect(jest.getTimerCount()).toBe(1);
    view.unmount();
    expect(jest.getTimerCount()).toBe(0);
  });

  test('в простом режиме и у обычного кодекса нет эффектов и игрушек', () => {
    const view = render(<HereticBookAtmosphere path="Unbound" presentation="living" reducedMotion={false} />);
    expect(view.container.childElementCount).toBe(0);
    view.rerender(<HereticBookAtmosphere path="Cosmic" presentation="living" reducedMotion={false} />);
    fireEvent.click(screen.getByRole('button'));
    view.rerender(<HereticBookAtmosphere path="Cosmic" presentation="plain" reducedMotion={false} />);
    expect(view.container.childElementCount).toBe(0);
    expect(jest.getTimerCount()).toBe(0);
  });

  test('приглушённый вид содержит меньше частиц и быстро заканчивает отклик', () => {
    const view = render(<HereticBookAtmosphere path="Cosmic" presentation="living" reducedMotion={false} />);
    const fullCount = view.container.querySelectorAll('svg *').length;
    view.rerender(<HereticBookAtmosphere path="Cosmic" presentation="muted" reducedMotion={false} />);
    expect(view.container.querySelectorAll('svg *').length).toBeLessThan(fullCount);
    fireEvent.click(screen.getByRole('button'));
    act(() => jest.advanceTimersByTime(1200));
    expect(screen.getByRole('button').getAttribute('aria-pressed')).toBe('false');
    expect(jest.getTimerCount()).toBe(0);
  });

  test('reduced motion включает запрет движения и сохраняет краткий статичный отклик', () => {
    const view = render(<HereticBookAtmosphere path="Flesh" presentation="living" reducedMotion />);
    expect(view.container.querySelector('.HereticBookAtmosphere--still')).toBeTruthy();
    fireEvent.click(screen.getByRole('button'));
    expect(screen.getByRole('button').getAttribute('aria-pressed')).toBe('true');
    act(() => jest.advanceTimersByTime(900));
    expect(screen.getByRole('button').getAttribute('aria-pressed')).toBe('false');
    expect(jest.getTimerCount()).toBe(0);
  });
});

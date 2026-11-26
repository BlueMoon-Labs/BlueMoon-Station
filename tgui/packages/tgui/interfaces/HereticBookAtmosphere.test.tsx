import { act, fireEvent, render, screen } from '@testing-library/react';

import { HereticBookAtmosphere } from './HereticBookAtmosphere';

describe('Живой переплёт гримуара', () => {
  beforeEach(() => jest.useFakeTimers());
  afterEach(() => {
    jest.clearAllTimers();
    jest.useRealTimers();
  });

  test.each([
    ['Flesh', 'Качнуть коренной зуб на жильной нити'],
    ['Ash', 'Качнуть уголёк в проволочной оплётке'],
    ['Cosmic', 'Качнуть латунный отвес на нитке'],
    ['Rust', 'Качнуть ржавую гайку на проволоке'],
    ['Void', 'Качнуть осколок стекла на нитке'],
    ['Blade', 'Качнуть темляк с синей кистью'],
    ['Moon', 'Качнуть пустой медальон на цепочке'],
    ['Lock', 'Качнуть ключ на нитке'],
    ['Tide', 'Качнуть свинцовый лот на лине'],
    ['Glass', 'Качнуть стеклорез на крючке'],
    ['Blood', 'Качнуть ланцет с каплей на острие'],
    ['Echo', 'Качнуть камертон на вощёной нитке'],
    ['Sand', 'Качнуть песочные часики на ремешке'],
    ['Wax', 'Качнуть пару свечей на общем фитиле'],
    ['Spirit', 'Качнуть немой колокольчик на крепе'],
    ['Dance', 'Качнуть камертон на алой ленте'],
    ['Dusk', 'Повернуть треснувший нимб на застёжке'],
    ['Lead', 'Качнуть стреляную гильзу на цепочке'],
    ['Hammer', 'Качнуть кованый молоточек на цепи'],
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

  test('книги мастерской носят общий класс переплёта, остальные - нет', () => {
    const view = render(<HereticBookAtmosphere path="Void" presentation="muted" reducedMotion={false} />);
    expect(view.container.querySelector('.HereticBookAtmosphere--workshop.HereticBookAtmosphere--Void')).toBeTruthy();
    view.rerender(<HereticBookAtmosphere path="Dusk" presentation="muted" reducedMotion={false} />);
    expect(view.container.querySelector('.HereticBookAtmosphere--workshop')).toBeNull();
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

  test('Сумрак: заголовок под курсором сбоит только в живой книге без запрета движения и перестаёт после закрытия', () => {
    const proto = HTMLElement.prototype as any;
    const saved = { animate: proto.animate, getAnimations: proto.getAnimations };
    const animate = jest.fn(() => ({ id: '' }));
    proto.animate = animate;
    proto.getAnimations = () => [];
    const random = jest.spyOn(Math, 'random').mockReturnValue(0.9);
    const book = document.body.appendChild(document.createElement('div'));
    book.className = 'HereticBook';
    const heading = book.appendChild(document.createElement('h2'));
    const note = book.appendChild(document.createElement('p'));
    const hover = (target: Element) => target.dispatchEvent(new Event('pointerover', { bubbles: true }));
    try {
      const view = render(<HereticBookAtmosphere path="Dusk" presentation="living" reducedMotion={false} />, { container: book.appendChild(document.createElement('div')) });
      hover(heading);
      hover(note);
      expect(animate).toHaveBeenCalledTimes(1);
      view.rerender(<HereticBookAtmosphere path="Dusk" presentation="living" reducedMotion />);
      hover(heading);
      view.rerender(<HereticBookAtmosphere path="Dusk" presentation="muted" reducedMotion={false} />);
      hover(heading);
      view.rerender(<HereticBookAtmosphere path="Moon" presentation="living" reducedMotion={false} />);
      hover(heading);
      expect(animate).toHaveBeenCalledTimes(1);
      view.rerender(<HereticBookAtmosphere path="Dusk" presentation="living" reducedMotion={false} />);
      hover(heading);
      expect(animate).toHaveBeenCalledTimes(2);
      view.unmount();
      hover(heading);
      expect(animate).toHaveBeenCalledTimes(2);
    } finally {
      proto.animate = saved.animate;
      proto.getAnimations = saved.getAnimations;
      random.mockRestore();
      book.remove();
    }
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

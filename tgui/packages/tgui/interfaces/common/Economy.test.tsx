import { render } from '@testing-library/react';

import { ChangeBadge, Credits, formatCredits, HistoryTable, Sparkline } from './Economy';

const NBSP = ' ';

describe('formatCredits', () => {
  test('тысячи через неразрывный пробел', () => {
    expect(formatCredits(1234567)).toBe(`1${NBSP}234${NBSP}567${NBSP}кр.`);
    expect(formatCredits(999)).toBe(`999${NBSP}кр.`);
    expect(formatCredits(0)).toBe(`0${NBSP}кр.`);
  });

  test('отрицательные без лишнего разделителя после минуса', () => {
    expect(formatCredits(-123)).toBe(`-123${NBSP}кр.`);
    expect(formatCredits(-1234)).toBe(`-1${NBSP}234${NBSP}кр.`);
  });

  test('округление, знак и дробная часть', () => {
    expect(formatCredits(1234.6)).toBe(`1${NBSP}235${NBSP}кр.`);
    expect(formatCredits(-0.4)).toBe(`0${NBSP}кр.`);
    expect(formatCredits(150, { signed: true })).toBe(`+150${NBSP}кр.`);
    expect(formatCredits(0, { signed: true })).toBe(`0${NBSP}кр.`);
    expect(formatCredits(1234.5, { decimals: 2 })).toBe(`1${NBSP}234.50${NBSP}кр.`);
  });

  test('без числа - прочерк', () => {
    expect(formatCredits(null)).toBe('-');
    expect(formatCredits(NaN)).toBe('-');
  });
});

describe('Credits', () => {
  test('рендерит сумму с разделителями', () => {
    const { container } = render(<Credits amount={1234567} />);
    expect(container.textContent).toBe(`1${NBSP}234${NBSP}567${NBSP}кр.`);
  });

  test('signed ставит плюс у прихода', () => {
    const { container } = render(<Credits amount={40} signed />);
    expect(container.textContent).toBe(`+40${NBSP}кр.`);
  });
});

describe('ChangeBadge', () => {
  test('рост зелёный, падение красное, ноль нейтральный', () => {
    const up = render(<ChangeBadge percent={5.5} />).container;
    const down = render(<ChangeBadge percent={-3} />).container;
    const flat = render(<ChangeBadge percent={0} />).container;
    expect(up.textContent).toBe('▲ +5.5%');
    expect(up.querySelector('.color-good')).not.toBeNull();
    expect(down.textContent).toBe('▼ -3%');
    expect(down.querySelector('.color-bad')).not.toBeNull();
    expect(flat.textContent).toBe('0%');
    expect(flat.querySelector('.color-good, .color-bad')).toBeNull();
  });

  test('процент округляется до десятых', () => {
    const { container } = render(<ChangeBadge percent={2.345} />);
    expect(container.textContent).toBe('▲ +2.3%');
  });
});

describe('Sparkline', () => {
  test('ломаная по всем точкам, рост зелёный', () => {
    const { container } = render(<Sparkline values={[10, 20, 15]} />);
    const line = container.querySelector('polyline');
    expect(line?.getAttribute('points')).toBe('0,100 50,0 100,50');
    expect(container.querySelector('.color-good')).not.toBeNull();
  });

  test('падение красное, явный цвет важнее тренда', () => {
    const down = render(<Sparkline values={[20, 10]} />).container;
    expect(down.querySelector('.color-bad')).not.toBeNull();
    const custom = render(<Sparkline values={[20, 10]} color="label" />).container;
    expect(custom.querySelector('.color-label')).not.toBeNull();
    expect(custom.querySelector('.color-bad')).toBeNull();
  });

  test('ровная цена - линия посередине, без NaN', () => {
    const { container } = render(<Sparkline values={[5, 5, 5]} />);
    expect(container.querySelector('polyline')?.getAttribute('points')).toBe('0,50 50,50 100,50');
  });

  test('меньше двух точек - ничего', () => {
    expect(render(<Sparkline values={[5]} />).container.innerHTML).toBe('');
    expect(render(<Sparkline values={[]} />).container.innerHTML).toBe('');
  });
});

describe('HistoryTable', () => {
  const entries = [
    { time: '12:00', label: 'Зарплата', amount: 1500, counterparty: 'Сервис' },
    { time: '12:05', label: 'Покупка', amount: -40, counterparty: 'Автомат' },
    { time: '12:06', label: 'Открытие счёта', amount: 0, counterparty: 'Nanotrasen' },
  ];

  test('приход и расход со знаком и цветом, новые сверху', () => {
    const { container } = render(<HistoryTable entries={entries} />);
    const rows = container.querySelectorAll('tr');
    expect(rows).toHaveLength(3);
    expect(rows[0].textContent).toContain('Открытие счёта');
    expect(rows[1].textContent).toContain('Покупка');
    expect(rows[1].textContent).toContain('Автомат');
    expect(rows[1].textContent).toContain(`-40${NBSP}кр.`);
    expect(rows[1].querySelector('.color-bad')).not.toBeNull();
    expect(rows[2].textContent).toContain('12:00');
    expect(rows[2].textContent).toContain(`+1${NBSP}500${NBSP}кр.`);
    expect(rows[2].querySelector('.color-good')).not.toBeNull();
    expect(rows[0].querySelector('.color-good, .color-bad')).toBeNull();
  });

  test('пустая история - подпись вместо таблицы', () => {
    const empty = render(<HistoryTable entries={[]} />).container;
    expect(empty.querySelector('table')).toBeNull();
    expect(empty.textContent).toBe('Операций пока нет.');
    const custom = render(<HistoryTable entries={[]} emptyText="Пусто" />).container;
    expect(custom.textContent).toBe('Пусто');
  });
});

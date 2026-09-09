/**
 * Плитки дизайнов лежат в сетке из тайлов 32x32. Размер спрайта приезжает из DM
 * только классом вида design64x32, поэтому разбор класса - единственное, что
 * удерживает крупный спрайт в его ячейках и не даёт ему двигать соседей.
 */
import { designGridSpan, withDesignSizeClass } from './Techweb';

describe('designGridSpan', () => {
  test('обычный спрайт не занимает лишних ячеек', () => {
    expect(designGridSpan('design32x32 basic_beaker')).toBeUndefined();
  });

  test('широкий спрайт занимает несколько колонок', () => {
    expect(designGridSpan('design64x32 conveyor')).toEqual({
      gridColumn: 'span 2',
      gridRow: 'span 1',
    });
  });

  test('высокий и крупный спрайт занимает и колонки, и ряды', () => {
    expect(designGridSpan('design32x64 tall_locker')).toEqual({
      gridColumn: 'span 1',
      gridRow: 'span 2',
    });
    expect(designGridSpan('design96x96 ripley')).toEqual({
      gridColumn: 'span 3',
      gridRow: 'span 3',
    });
  });

  test('нецелый размер округляется вверх - спрайт не вылезает за ячейки', () => {
    expect(designGridSpan('design48x32 odd_sprite')).toEqual({
      gridColumn: 'span 2',
      gridRow: 'span 1',
    });
  });

  test('класс без размера не ломает раскладку', () => {
    expect(designGridSpan('')).toBeUndefined();
    expect(designGridSpan(undefined)).toBeUndefined();
    expect(designGridSpan('someothersheet32x32 thing')).toBeUndefined();
  });
});

describe('withDesignSizeClass', () => {
  test('присланный размер остаётся как есть', () => {
    expect(withDesignSizeClass('design64x32 experimentor'))
      .toBe('design64x32 experimentor');
  });

  test('без размера дописывается тайл', () => {
    expect(withDesignSizeClass('beaker')).toBe('design32x32 beaker');
  });

  test('id, начинающийся на design, тоже получает размер', () => {
    // design_disk без класса размера рисовался плиткой 0x0 - иконки просто не было.
    expect(withDesignSizeClass('design_disk')).toBe('design32x32 design_disk');
    expect(withDesignSizeClass('design_disk_adv'))
      .toBe('design32x32 design_disk_adv');
  });
});

/**
 * Списки производства держат иконку в ячейке ровно в тайл: спрайт крупнее ужимается
 * целиком, иначе широкий обрезается по 32px, а высокий распирает строку.
 */
import { designIconScale } from './DesignIcon';

describe('designIconScale', () => {
  test('спрайт в тайл не ужимается', () => {
    expect(designIconScale('design32x32')).toBe(1);
    expect(designIconScale(undefined)).toBe(1);
    expect(designIconScale('')).toBe(1);
  });

  test('широкий и высокий ужимаются по длинной стороне', () => {
    expect(designIconScale('design64x32')).toBe(0.5);
    expect(designIconScale('design32x64')).toBe(0.5);
    expect(designIconScale('design96x96')).toBe(1 / 3);
  });

  test('нецелое отношение сторон вписывается целиком', () => {
    expect(designIconScale('design32x48')).toBeCloseTo(32 / 48);
  });

  test('чужой класс без размера не трогает масштаб', () => {
    expect(designIconScale('some_design_id')).toBe(1);
  });
});

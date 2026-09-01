/**
 * Таблица GASES отстала от игры на десять газов и никто этого не заметил:
 * getGasColor возвращал undefined, и полосы рисовались серыми. Тест читает
 * дефайны газов прямо из DM-исходника, поэтому новый газ без записи в
 * GASES валит сборку.
 */
import fs from 'fs';
import path from 'path';

import { getGasFromId } from './constants';

const DEFINES_PATH = path.resolve(
  __dirname,
  '../../../code/__DEFINES/atmospherics.dm',
);

/**
 * Дефайны, у которых нет собственного датума газа в gas_types.dm.
 * fluorine и motor_oil не используются нигде — мёртвые заготовки; ethanol
 * собирается на лету из реагентов (alcohol_reagents.dm) и в атмос-окнах
 * не показывается.
 */
const WITHOUT_GAS_DATUM = new Set(['fluorine', 'ethanol', 'motor_oil']);

const readGasIds = (): string[] => {
  const source = fs.readFileSync(DEFINES_PATH, 'utf8');
  const ids: string[] = [];
  // GAS_STRING_TEMP и GAS_STRING_MOLES — ключи разобранной строки газа,
  // а не газы. Под общий шаблон они подходят, поэтому отсекаются явно.
  const pattern = /^#define\s+GAS_(?!STRING_)[A-Z0-9_]+\s+"([a-z0-9_]+)"/gm;
  let match = pattern.exec(source);
  while (match !== null) {
    ids.push(match[1]);
    match = pattern.exec(source);
  }
  return ids;
};

describe('GASES coverage', () => {
  const gasIds = readGasIds();

  test('дефайны газов вычитались из DM', () => {
    // Защита от того, что регексп перестал совпадать и тест стал пустым.
    expect(gasIds.length).toBeGreaterThanOrEqual(28);
    expect(gasIds).toContain('o2');
    expect(gasIds).toContain('nitrium');
    // Ключи разобранной строки газа не должны попадать в список.
    expect(gasIds).not.toContain('temp');
    expect(gasIds).not.toContain('moles');
  });

  test('каждый игровой газ имеет запись в GASES', () => {
    const missing = gasIds
      .filter(id => !WITHOUT_GAS_DATUM.has(id))
      .filter(id => getGasFromId(id) === undefined);
    expect(missing).toEqual([]);
  });

  test('у каждой записи есть цвет и обе подписи', () => {
    for (const id of gasIds) {
      if (WITHOUT_GAS_DATUM.has(id)) {
        continue;
      }
      const gas = getGasFromId(id);
      expect(gas).toBeDefined();
      expect(gas.color).toBeTruthy();
      expect(gas.label).toBeTruthy();
      expect(gas.label_ru).toBeTruthy();
    }
  });
});

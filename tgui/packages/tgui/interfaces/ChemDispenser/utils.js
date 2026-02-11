export const CATEGORY_CONFIG = {
  medicine: { title: 'Медицина', icon: 'pills', order: 1 },
  elements: { title: 'Элементы', icon: 'atom', order: 2 },
  compounds: { title: 'Соединения', icon: 'flask', order: 3 },
  toxins: { title: 'Токсины', icon: 'skull-crossbones', order: 4 },
  drugs: { title: 'Препараты', icon: 'cannabis', order: 5 },
  alcoholic_drinks: { title: 'Алкоголь', icon: 'wine-glass', order: 6 },
  soft_drinks: { title: 'Безалкогольные', icon: 'mug-hot', order: 7 },
  consumables: { title: 'Расходники', icon: 'coffee', order: 8 },
  other: { title: 'Прочее', icon: 'question', order: 9 },
  slime_extracts: { title: 'Экстракты слаймов', icon: 'droplet', order: 10 },
};

export const DRINK_CATEGORY_CONFIG = {
  alcoholic_drinks: { title: 'Алкоголь', icon: 'wine-glass', order: 1 },
  soft_drinks: { title: 'Безалкогольные', icon: 'mug-hot', order: 2 },
  consumables: { title: 'Расходники', icon: 'coffee', order: 3 },
  medicine: { title: 'Медицина', icon: 'pills', order: 4 },
  elements: { title: 'Элементы', icon: 'atom', order: 5 },
  compounds: { title: 'Соединения', icon: 'flask', order: 6 },
  toxins: { title: 'Токсины', icon: 'skull-crossbones', order: 7 },
  drugs: { title: 'Препараты', icon: 'cannabis', order: 8 },
  other: { title: 'Прочее', icon: 'question', order: 9 },
  slime_extracts: { title: 'Экстракты слаймов', icon: 'droplet', order: 10 },
};

// Dispenser type flags. Must match DM defines.
export const DISPENSER_TYPE_SODA = 2;
export const DISPENSER_TYPE_BOOZE = 4;

export const DRINK_CATEGORIES = ['alcoholic_drinks', 'soft_drinks'];

export const AMOUNT_PRESETS = [1, 5, 10, 15, 20, 25, 30, 40, 50, 60];

export const OPTIMISTIC_TIMEOUT = 2000;

/** Must match DM SetAmount() behavior. */
export const predictSetAmount = (inputAmount, dispenseUnit = 5) => {
  if (inputAmount <= 1) return Math.max(inputAmount, 1);
  if (inputAmount % 5 === 0) return inputAmount;
  const rounded = inputAmount - (inputAmount % dispenseUnit);
  return rounded === 0 ? dispenseUnit : rounded;
};

// Actual input = ceil((need * multiplier) / yield) * input.
export const calculateActualAmount = (data, multiplier) => {
  const need = data.need || data.amount;
  const yieldFactor = data.yield || 1;
  const input = data.input || data.amount;
  return Math.ceil(need * multiplier / yieldFactor) * input;
};

/** parent is 1-indexed; 0 means top-level and scales directly with multiplier. */
export const calculateWasteInfo = (recipe, multiplier) => {
  const intermediates = recipe.intermediate_yields;
  if (!intermediates || intermediates.length === 0) return [];

  const reactions = new Array(intermediates.length);
  const wasteInfo = [];

  for (let i = 0; i < intermediates.length; i++) {
    const entry = intermediates[i];
    let totalNeeded;
    if (entry.parent === 0) {
      totalNeeded = entry.amount * multiplier;
    } else {
      totalNeeded = reactions[entry.parent - 1] * entry.amount;
    }
    reactions[i] = Math.ceil(totalNeeded / entry.yield);
    const produced = reactions[i] * entry.yield;
    const waste = produced - totalNeeded;
    if (waste > 0) {
      wasteInfo.push({ name: entry.name, amount: waste });
    }
  }
  return wasteInfo;
};

export const buildBeakerLookup = (beakerContents) => {
  const lookup = {};
  for (let i = 0; i < beakerContents.length; i++) {
    const item = beakerContents[i];
    lookup[item.name] = (lookup[item.name] || 0) + item.volume;
  }
  return lookup;
};

export const calculateTotalInputVolume = (baseIngredients, multiplier) => {
  let total = 0;
  for (const data of Object.values(baseIngredients)) {
    total += calculateActualAmount(data, multiplier);
  }
  return total;
};

export const russianPlural = (n, one, few, many) => {
  const abs = Math.abs(n) % 100;
  const lastDigit = abs % 10;
  if (abs > 10 && abs < 20) return many;
  if (lastDigit > 1 && lastDigit < 5) return few;
  if (lastDigit === 1) return one;
  return many;
};

export const isRecipeUnlocked = ({ tier, isDrinkDispenser, isEmagged, manipulatorTier, hasCrossReqs }) => {
  const requiredTier = tier || 1;
  const isEmagTier = requiredTier >= 6;
  if (isDrinkDispenser) return isEmagTier ? (isEmagged || !!hasCrossReqs) : true;
  return isEmagTier ? isEmagged : manipulatorTier >= requiredTier;
};

export const hasCrossDispenserReqs = (crossDispenser, dispenserType) => {
  if (!crossDispenser) return false;
  return (
    (dispenserType === DISPENSER_TYPE_SODA && !!crossDispenser.requires_booze) ||
    (dispenserType === DISPENSER_TYPE_BOOZE && !!crossDispenser.requires_soda) ||
    !!crossDispenser.requires_chem
  );
};

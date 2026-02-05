export const CATEGORY_CONFIG = {
  // Chemistry categories (standard order for chem dispensers)
  medicine: { title: 'Медицина', icon: 'pills', order: 1 },
  elements: { title: 'Элементы', icon: 'atom', order: 2 },
  compounds: { title: 'Соединения', icon: 'flask', order: 3 },
  toxins: { title: 'Токсины', icon: 'skull-crossbones', order: 4 },
  drugs: { title: 'Препараты', icon: 'cannabis', order: 5 },
  // Drink categories (for drink dispensers)
  alcoholic_drinks: { title: 'Алкоголь', icon: 'wine-glass', order: 6 },
  soft_drinks: { title: 'Безалкогольные', icon: 'mug-hot', order: 7 },
  consumables: { title: 'Расходники', icon: 'coffee', order: 8 }, // Legacy, kept for backwards compatibility
  other: { title: 'Прочее', icon: 'question', order: 9 },
  slime_extracts: { title: 'Экстракты слаймов', icon: 'droplet', order: 10 },
};

// Category config for drink dispensers (drinks first)
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

// Dispenser type flags (must match DM defines)
export const DISPENSER_TYPE_CHEM = 1;
export const DISPENSER_TYPE_SODA = 2;
export const DISPENSER_TYPE_BOOZE = 4;
export const DISPENSER_TYPE_DRINKS = DISPENSER_TYPE_SODA | DISPENSER_TYPE_BOOZE;

export const AMOUNT_PRESETS = [1, 5, 10, 15, 20, 25, 30, 40, 50, 60];

/**
 * Calculate actual amount needed for an ingredient considering yield scaling.
 * Formula: ceil(need * multiplier / yield) * input
 */
export const calculateActualAmount = (data, multiplier) => {
  const need = data.need || data.amount;
  const yieldFactor = data.yield || 1;
  const input = data.input || data.amount;
  return Math.ceil(need * multiplier / yieldFactor) * input;
};

export const getIngredientColor = (data, beakerAmount, neededAmount) => {
  if (data.can_dispense) return 'good';
  if (beakerAmount >= neededAmount) return 'blue';
  if (beakerAmount > 0) return 'average';
  return 'bad';
};

/**
 * Calculate waste info for recipes with sub-recipes (including nested intermediates).
 * Uses tree structure: each intermediate has {name, amount, yield, parent} where
 * parent is 1-indexed (0 = top-level, scales with multiplier directly).
 */
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
  for (const [, data] of Object.entries(baseIngredients)) {
    total += calculateActualAmount(data, multiplier);
  }
  return total;
};

// Russian plural forms helper
export const russianPlural = (n, one, few, many) => {
  const abs = Math.abs(n) % 100;
  const lastDigit = abs % 10;
  if (abs > 10 && abs < 20) return many;
  if (lastDigit > 1 && lastDigit < 5) return few;
  if (lastDigit === 1) return one;
  return many;
};

/**
 * Check if a recipe is unlocked based on tier, emag status, and dispenser type.
 */
export const isRecipeUnlocked = ({ tier, isDrinkDispenser, isEmagged, manipulatorTier, hasCrossReqs }) => {
  const requiredTier = tier || 1;
  const isEmagTier = requiredTier >= 6;
  if (isDrinkDispenser) return isEmagTier ? (isEmagged || !!hasCrossReqs) : true;
  return isEmagTier ? isEmagged : manipulatorTier >= requiredTier;
};

/**
 * Check if a recipe requires ingredients from another dispenser type.
 */
export const hasCrossDispenserReqs = (crossDispenser, dispenserType) => {
  if (!crossDispenser) return false;
  return (
    (dispenserType === DISPENSER_TYPE_SODA && !!crossDispenser.requires_booze) ||
    (dispenserType === DISPENSER_TYPE_BOOZE && !!crossDispenser.requires_soda) ||
    !!crossDispenser.requires_chem
  );
};

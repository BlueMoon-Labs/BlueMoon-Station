export const CATEGORY_CONFIG = {
  elements: { title: 'Элементы', icon: 'atom', order: 1 },
  compounds: { title: 'Соединения', icon: 'flask', order: 2 },
  consumables: { title: 'Расходники', icon: 'coffee', order: 3 },
  toxins: { title: 'Токсины', icon: 'skull-crossbones', order: 4 },
  medicine: { title: 'Медицина', icon: 'pills', order: 5 },
  drugs: { title: 'Препараты', icon: 'cannabis', order: 6 },
  other: { title: 'Прочее', icon: 'question', order: 7 },
  slime_extracts: { title: 'Экстракты слаймов', icon: 'droplet', order: 8 },
};

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
  beakerContents.forEach(item => {
    lookup[item.name] = (lookup[item.name] || 0) + item.volume;
  });
  return lookup;
};

export const calculateTotalInputVolume = (baseIngredients, multiplier) => {
  let total = 0;
  for (const [, data] of Object.entries(baseIngredients)) {
    total += calculateActualAmount(data, multiplier);
  }
  return total;
};

import { toFixed } from 'common/math';
import { createSearch, toTitleCase } from 'common/string';

import { useBackend, useLocalState } from '../../backend';
import {
  Box,
  Button,
  Collapsible,
  Icon,
  Input,
  NoticeBox,
  NumberInput,
  ProgressBar,
  Section,
  Stack,
  Tabs,
} from '../../components';
import { Window } from '../../layouts';
import { BeakerSidePanel } from './BeakerSidePanel';
import { GameRecipesTab } from './GameRecipesTab';
import { SavedRecipesTab } from './SavedRecipesTab';
import { StorageSidePanel } from './StorageSidePanel';
import { AMOUNT_PRESETS, CATEGORY_CONFIG, DRINK_CATEGORIES, DRINK_CATEGORY_CONFIG, OPTIMISTIC_TIMEOUT, predictSetAmount } from './utils';

let _chemMetaCache = { key: null, byTitle: null, byId: null };

const getChemMetadata = (chemicals) => {
  if (_chemMetaCache.key === chemicals) return _chemMetaCache;
  const byTitle = {};
  const byId = {};
  for (let i = 0; i < chemicals.length; i++) {
    const c = chemicals[i];
    const meta = { pH: c.pH, pHCol: c.pHCol, reagentColor: c.reagentColor };
    byTitle[c.title] = meta;
    byId[c.id] = meta;
  }
  _chemMetaCache = { key: chemicals, byTitle, byId };
  return _chemMetaCache;
};

let _recipesCountCache = { key: null, count: 0, drinkCount: 0 };

const getRecipesCount = (gameRecipes, isDrinkDispenser) => {
  if (_recipesCountCache.key !== gameRecipes) {
    _recipesCountCache.key = gameRecipes;
    let drinkCount = 0;
    let totalCount = 0;
    for (const name in gameRecipes) {
      totalCount++;
      if (DRINK_CATEGORIES.includes(gameRecipes[name].category)) {
        drinkCount++;
      }
    }
    _recipesCountCache.count = totalCount;
    _recipesCountCache.drinkCount = drinkCount;
  }
  return isDrinkDispenser ? _recipesCountCache.drinkCount : _recipesCountCache.count;
};

const _amountDebounceTimers = new Map();
const _recipeActionLocks = new Map();
const RECIPE_ACTION_COOLDOWN_MS = 250;

let _classicSortCache = { key: null, result: null };

const getClassicSorted = (chemicals) => {
  if (_classicSortCache.key === chemicals) return _classicSortCache.result;
  _classicSortCache.result = [...chemicals].sort((a, b) =>
    a.title.localeCompare(b.title)
  );
  _classicSortCache.key = chemicals;
  return _classicSortCache.result;
};

const checkOptimisticActive = (optimistic, data) => {
  if (!optimistic || Date.now() - optimistic.timestamp >= OPTIMISTIC_TIMEOUT) return false;
  // Keep eject optimistic until the server reports no beaker.
  if (optimistic.ejectBeaker) return !!data.isBeakerLoaded;
  // Validate against volume only. Energy changes during passive recharge.
  const volMatch = (data.beakerCurrentVolume || 0) === optimistic.serverVolume;
  if (optimistic.storageTransfers && optimistic.storageTransfers.length > 0) {
    return volMatch && (data.storedVol || 0) === optimistic.serverStoredVol;
  }
  return volMatch && data.isBeakerLoaded;
};

const mergeOptimisticBeaker = (serverContents, optimisticDispenses) => {
  const merged = serverContents.map(c => ({ ...c }));
  for (const disp of optimisticDispenses) {
    const existing = merged.find(c => c.name === disp.name);
    if (existing) {
      existing.volume = Math.round((existing.volume + disp.volume) * 100) / 100;
    } else {
      merged.push({
        name: disp.name,
        volume: Math.round(disp.volume * 100) / 100,
        pH: disp.pH,
        pHCol: disp.pHCol,
        reagentColor: disp.reagentColor,
      });
    }
  }
  return merged;
};

/** Matches server-side remove_all() behavior. */
const applyOptimisticRemove = (contents, totalVolume, removeAmount, removeAll) => {
  if (removeAll || removeAmount >= totalVolume) return [];
  if (!removeAmount || totalVolume <= 0) return contents;
  const ratio = Math.max(0, 1 - removeAmount / totalVolume);
  return contents.map(c => ({
    ...c,
    volume: Math.round(c.volume * ratio * 100) / 100,
  })).filter(c => c.volume > 0);
};

const applyOptimisticStorageTransfers = (
  beakerContents, beakerVol, beakerMaxVol,
  storedContents, storedVol, maxStoredVol,
  transfers, amount
) => {
  let bContents = beakerContents.map(c => ({ ...c }));
  let sContents = storedContents.map(c => ({ ...c }));
  let bVol = beakerVol || 0;
  let sVol = storedVol || 0;

  for (const tr of transfers) {
    if (tr.direction === 'to_storage') {
      const bChem = bContents.find(c => c.id === tr.id);
      if (!bChem) continue;
      const freeSpace = Math.max(0, (maxStoredVol || 0) - sVol);
      const transferAmt = Math.min(amount, bChem.volume, freeSpace);
      if (transferAmt <= 0) continue;
      bChem.volume = Math.round((bChem.volume - transferAmt) * 100) / 100;
      bVol = Math.round((bVol - transferAmt) * 100) / 100;
      const sChem = sContents.find(c => c.id === tr.id);
      if (sChem) {
        sChem.volume = Math.round((sChem.volume + transferAmt) * 100) / 100;
      } else {
        sContents.push({ ...bChem, volume: Math.round(transferAmt * 100) / 100 });
      }
    } else if (tr.direction === 'from_storage') {
      const sChem = sContents.find(c => c.id === tr.id);
      if (!sChem) continue;
      const freeSpace = Math.max(0, (beakerMaxVol || 0) - bVol);
      const transferAmt = Math.min(amount, sChem.volume, freeSpace);
      if (transferAmt <= 0) continue;
      sChem.volume = Math.round((sChem.volume - transferAmt) * 100) / 100;
      sVol = Math.round((sVol - transferAmt) * 100) / 100;
      const bChem = bContents.find(c => c.id === tr.id);
      if (bChem) {
        bChem.volume = Math.round((bChem.volume + transferAmt) * 100) / 100;
      } else {
        bContents.push({ ...sChem, volume: Math.round(transferAmt * 100) / 100 });
      }
    } else if (tr.direction === 'store_all') {
      const freeSpace = Math.max(0, (maxStoredVol || 0) - sVol);
      const transferRatio = bVol > 0 ? Math.min(1, freeSpace / bVol) : 0;
      for (const bChem of bContents) {
        const transferAmt = Math.round(bChem.volume * transferRatio * 100) / 100;
        if (transferAmt <= 0) continue;
        const sChem = sContents.find(c => c.id === bChem.id);
        if (sChem) {
          sChem.volume = Math.round((sChem.volume + transferAmt) * 100) / 100;
        } else {
          sContents.push({ ...bChem, volume: transferAmt });
        }
        bChem.volume = Math.round((bChem.volume - transferAmt) * 100) / 100;
      }
      const totalTransferred = Math.min(bVol, freeSpace);
      bVol = Math.round((bVol - totalTransferred) * 100) / 100;
      sVol = Math.round((sVol + totalTransferred) * 100) / 100;
    } else if (tr.direction === 'unstore_all') {
      const freeSpace = Math.max(0, (beakerMaxVol || 0) - bVol);
      const transferRatio = sVol > 0 ? Math.min(1, freeSpace / sVol) : 0;
      for (const sChem of sContents) {
        const transferAmt = Math.round(sChem.volume * transferRatio * 100) / 100;
        if (transferAmt <= 0) continue;
        const bChem = bContents.find(c => c.id === sChem.id);
        if (bChem) {
          bChem.volume = Math.round((bChem.volume + transferAmt) * 100) / 100;
        } else {
          bContents.push({ ...sChem, volume: transferAmt });
        }
        sChem.volume = Math.round((sChem.volume - transferAmt) * 100) / 100;
      }
      const totalTransferred = Math.min(sVol, freeSpace);
      sVol = Math.round((sVol - totalTransferred) * 100) / 100;
      bVol = Math.round((bVol + totalTransferred) * 100) / 100;
    } else if (tr.direction === 'clear_storage') {
      sContents = [];
      sVol = 0;
    }
  }

  return {
    beakerContents: bContents.filter(c => c.volume > 0),
    beakerVol: Math.max(0, bVol),
    storedContents: sContents.filter(c => c.volume > 0),
    storedVol: Math.max(0, sVol),
  };
};

const computeDisplayValues = (data, beakerContents, optimistic, isOptimisticActive, storedContents) => {
  const base = {
    contents: beakerContents,
    volume: data.beakerCurrentVolume,
    energy: data.energy,
    isBeakerLoaded: !!data.isBeakerLoaded,
    storedContents,
    storedVol: data.storedVol,
  };
  if (!isOptimisticActive) return base;

  // On eject, immediately render an empty beaker.
  if (optimistic.ejectBeaker) {
    return { ...base, contents: [], volume: 0, isBeakerLoaded: false };
  }

  let result = { ...base };

  const hasDispenses = optimistic.dispenses && optimistic.dispenses.length > 0;
  const hasRemove = optimistic.removeAmount > 0 || optimistic.removeAll;
  if (hasDispenses || hasRemove) {
    const addVol = hasDispenses
      ? optimistic.dispenses.reduce((s, d) => s + d.volume, 0)
      : 0;
    const rmAmt = optimistic.removeAmount || 0;
    const rmAll = optimistic.removeAll;
    result.contents = applyOptimisticRemove(
      mergeOptimisticBeaker(result.contents, optimistic.dispenses || []),
      (result.volume || 0) + addVol,
      rmAmt,
      rmAll
    );
    const rawVol = Math.max(0, Math.round(((result.volume || 0) + addVol - rmAmt) * 100) / 100);
    result.volume = rmAll ? 0 : Math.min(rawVol, data.beakerMaxVolume || rawVol);
    result.energy = data.energy - (optimistic.energyDelta || 0);
  }

  if (optimistic.storageTransfers && optimistic.storageTransfers.length > 0) {
    const storageResult = applyOptimisticStorageTransfers(
      result.contents, result.volume, data.beakerMaxVolume,
      result.storedContents, result.storedVol, data.maxVol,
      optimistic.storageTransfers, optimistic.amount || data.amount
    );
    result.contents = storageResult.beakerContents;
    result.volume = storageResult.beakerVol;
    result.storedContents = storageResult.storedContents;
    result.storedVol = storageResult.storedVol;
  }

  return result;
};

const resolveOptimisticPrefs = (optPrefs, data) => {
  const active = optPrefs && Date.now() - optPrefs.timestamp < OPTIMISTIC_TIMEOUT;
  return {
    classicView: active && optPrefs.classicView !== undefined ? optPrefs.classicView : (data.classicView ?? true),
    useReagentColor: active && optPrefs.useReagentColor !== undefined ? optPrefs.useReagentColor : (data.useReagentColor ?? true),
    showIcons: active && optPrefs.showIcons !== undefined ? optPrefs.showIcons : (data.showIcons ?? true),
    alphabeticalSort: active && optPrefs.alphabeticalSort !== undefined ? optPrefs.alphabeticalSort : (data.alphabeticalSort ?? true),
  };
};

const resolveOptimisticAmount = (optAmount, data) => {
  if (optAmount && data.amount === optAmount.serverAmount && Date.now() - optAmount.timestamp < OPTIMISTIC_TIMEOUT) {
    return optAmount.value;
  }
  return data.amount;
};

export const ChemDispenser = (props, context) => {
  const { act, data } = useBackend(context);

  const [chemSearchQuery, setChemSearchQuery] = useLocalState(context, 'chem_search_chemicals', '');
  const [recipeSearchQuery, setRecipeSearchQuery] = useLocalState(context, 'chem_search_recipes', '');
  const [savedSearchQuery, setSavedSearchQuery] = useLocalState(context, 'chem_search_saved', '');

  const [activeTab, setActiveTab] = useLocalState(context, 'chem_tab', 'chemicals');
  const [favorites, setFavorites] = useLocalState(context, 'chem_favorites', []);
  const [recentChemicals, setRecentChemicals] = useLocalState(context, 'chem_recent', []);

  const [optPrefs, setOptPrefs] = useLocalState(context, 'chem_opt_prefs', null);
  const resolvedPrefs = resolveOptimisticPrefs(optPrefs, data);
  const { classicView, useReagentColor, showIcons, alphabeticalSort } = resolvedPrefs;

  const [optAmount, setOptAmount] = useLocalState(context, 'chem_opt_amount', null);
  const displayAmount = resolveOptimisticAmount(optAmount, data);

  const [pendingActions, setPendingActions] = useLocalState(context, 'chem_pending', {});
  const [optDeletedRecipes, setOptDeletedRecipes] = useLocalState(context, 'chem_deleted_recipes', null);
  const [optRecording, setOptRecording] = useLocalState(context, 'chem_opt_recording', null);

  const serverRecording = !!data.recordingRecipe;
  const recording = optRecording
    && Date.now() - optRecording.timestamp < OPTIMISTIC_TIMEOUT
    && serverRecording === optRecording.serverRecording
    ? optRecording.value
    : serverRecording;

  const favoritesSet = new Set(favorites);
  const [expandedCategories, setExpandedCategories] = useLocalState(context, 'chem_expanded', {
    alcoholic_drinks: true, soft_drinks: true,
    elements: true, compounds: true, consumables: true,
    toxins: true, medicine: true, drugs: true, other: true,
    slime_extracts: true,
  });

  const [optimistic, setOptimistic] = useLocalState(context, 'chem_optimistic', null);

  // Derived validity check; avoids render-time state updates.
  const isOptimisticActive = checkOptimisticActive(optimistic, data);

  const [searchQuery, setSearchQuery] =
    activeTab === 'gameRecipes' ? [recipeSearchQuery, setRecipeSearchQuery]
    : activeTab === 'savedRecipes' ? [savedSearchQuery, setSavedSearchQuery]
    : [chemSearchQuery, setChemSearchQuery];

  const {
    chemicals = [],
    storedContents = [],
    beakerTransferAmounts = [],
    gameRecipes = {},
    isDrinkDispenser = false,
  } = data;

  const showPH = !isDrinkDispenser;
  const chemMetadata = getChemMetadata(chemicals);

  const deletedActive = optDeletedRecipes
    && Date.now() - optDeletedRecipes.timestamp < OPTIMISTIC_TIMEOUT
    && optDeletedRecipes.serverRecipes === data.recipes;
  const deletedNames = deletedActive ? optDeletedRecipes.names : null;

  const savedRecipes = Object.keys(data.recipes || {})
    .filter(name => !deletedNames || !deletedNames.includes(name))
    .map(name => ({
      name,
      contents: data.recipes[name],
    }));

  const gameRecipesCount = getRecipesCount(gameRecipes, isDrinkDispenser);

  const beakerContents = recording
    ? Object.keys(data.recordingRecipe || {}).map(id => ({
      id,
      name: toTitleCase(id.replace(/_/g, ' ')),
      volume: data.recordingRecipe[id],
    }))
    : data.beakerContents || [];

  const categoryConfig = isDrinkDispenser ? DRINK_CATEGORY_CONFIG : CATEGORY_CONFIG;

  let filteredChemicals = chemicals;
  let chemicalsByCategory = {};
  let sortedCategories = [];
  let favoriteChemicals = [];
  let recentChemicalsList = [];

  if (activeTab === 'chemicals') {
    const searchFilter = createSearch(searchQuery, chemical => chemical.title);
    filteredChemicals = searchQuery
      ? chemicals.filter(searchFilter)
      : chemicals;

    filteredChemicals.forEach(chemical => {
      const category = chemical.category || 'other';
      if (!chemicalsByCategory[category]) {
        chemicalsByCategory[category] = [];
      }
      chemicalsByCategory[category].push(chemical);
    });

    sortedCategories = Object.keys(chemicalsByCategory).sort((a, b) => {
      const orderA = categoryConfig[a]?.order || 99;
      const orderB = categoryConfig[b]?.order || 99;
      return orderA - orderB;
    });

    favoriteChemicals = chemicals.filter(c => favoritesSet.has(c.id));
    recentChemicalsList = recentChemicals
      .map(id => chemicals.find(c => c.id === id))
      .filter(Boolean);
  }

  const toggleFavorite = (chemId) => {
    if (favoritesSet.has(chemId)) {
      setFavorites(favorites.filter(id => id !== chemId));
    } else {
      setFavorites([...favorites, chemId]);
    }
  };

  const addToRecent = (chemId) => {
    const updated = [chemId, ...recentChemicals.filter(id => id !== chemId)].slice(0, 5);
    setRecentChemicals(updated);
  };

  const toggleCategory = (category) => {
    setExpandedCategories({
      ...expandedCategories,
      [category]: !expandedCategories[category],
    });
  };

  const handleTogglePref = (prefKey, actName) => {
    const current = { classicView, useReagentColor, showIcons, alphabeticalSort };
    setOptPrefs({ ...current, [prefKey]: !current[prefKey], timestamp: Date.now() });
    act(actName);
  };

  const handleAmountChange = (target) => {
    const predicted = predictSetAmount(target, data.stepAmount || 5);
    setOptAmount({ value: predicted, serverAmount: data.amount, timestamp: Date.now() });
    const prevTimer = _amountDebounceTimers.get(context);
    if (prevTimer) clearTimeout(prevTimer);
    const timer = setTimeout(() => {
      _amountDebounceTimers.delete(context);
      act('amount', { target });
    }, 150);
    _amountDebounceTimers.set(context, timer);
  };

  const markPending = (actionKey, options = {}) => {
    const {
      ttl = OPTIMISTIC_TIMEOUT,
      checkVolume = true,
    } = options;
    const now = Date.now();
    setPendingActions((prev) => {
      // Prune expired entries to prevent unbounded growth.
      const cleaned = {};
      for (const key in prev) {
        const info = prev[key];
        const entryTtl = info.ttl ?? OPTIMISTIC_TIMEOUT;
        if (now - info.ts < entryTtl) {
          cleaned[key] = info;
        }
      }
      cleaned[actionKey] = {
        ts: now,
        volume: data.beakerCurrentVolume || 0,
        ttl,
        checkVolume,
      };
      return cleaned;
    });
  };
  const isActionPending = (actionKey) => {
    const info = pendingActions[actionKey];
    const ttl = info?.ttl ?? OPTIMISTIC_TIMEOUT;
    if (!info || Date.now() - info.ts >= ttl) return false;
    // Check volume only; energy changes during passive recharge.
    if (info.checkVolume !== false && (data.beakerCurrentVolume || 0) !== info.volume) {
      return false;
    }
    return true;
  };

  const beginRecipeAction = (actionKey) => {
    const now = Date.now();
    const lockUntil = _recipeActionLocks.get(context) || 0;
    if (now < lockUntil) {
      return false;
    }
    if (isActionPending('__recipe_global') || (actionKey && isActionPending(actionKey))) {
      return false;
    }
    _recipeActionLocks.set(context, now + RECIPE_ACTION_COOLDOWN_MS);
    markPending('__recipe_global', {
      ttl: RECIPE_ACTION_COOLDOWN_MS,
      checkVolume: false,
    });
    if (actionKey) {
      markPending(actionKey);
    }
    return true;
  };

  const handleDispense = (chemId) => {
    act('dispense', { reagent: chemId });
    addToRecent(chemId);

    if (data.isBeakerLoaded && !recording) {
      const chemical = chemicals.find(c => c.id === chemId);
      if (chemical) {
        // Accumulate on active optimistic state unless remove/eject/storage is pending.
        const cur = isOptimisticActive && !optimistic.removeAmount && !optimistic.removeAll
          && !optimistic.ejectBeaker && !(optimistic.storageTransfers && optimistic.storageTransfers.length)
          ? optimistic
          : { dispenses: [], energyDelta: 0, removeAmount: 0, removeAll: false, serverEnergy: data.energy, serverVolume: data.beakerCurrentVolume || 0, timestamp: Date.now() };
        const optimisticVolume = cur.dispenses.reduce((s, d) => s + d.volume, 0);
        const freeSpace = Math.max(0, (data.beakerMaxVolume || 0) - (data.beakerCurrentVolume || 0) - optimisticVolume);
        const availableEnergy = data.energy - cur.energyDelta;
        const actual = Math.min(displayAmount, availableEnergy, freeSpace);
        if (actual > 0) {
          setOptimistic({
            serverEnergy: cur.serverEnergy,
            serverVolume: cur.serverVolume,
            timestamp: Date.now(),
            energyDelta: cur.energyDelta + actual,
            removeAmount: 0,
            removeAll: false,
            dispenses: [...cur.dispenses, {
              name: chemical.title,
              volume: actual,
              pH: chemical.pH,
              pHCol: chemical.pHCol,
              reagentColor: chemical.reagentColor,
            }],
          });
        }
      }
    }
  };

  const handleDeleteRecipe = (recipeName) => {
    const cur = deletedActive ? optDeletedRecipes.names : [];
    setOptDeletedRecipes({
      names: [...cur, recipeName],
      serverRecipes: data.recipes,
      timestamp: Date.now(),
    });
    act('delete_recipe', { recipe: recipeName });
  };

  const handleStartRecording = () => {
    setOptRecording({ value: true, serverRecording: serverRecording, timestamp: Date.now() });
    act('record_recipe');
  };

  const handleCancelRecording = () => {
    setOptRecording({ value: false, serverRecording: serverRecording, timestamp: Date.now() });
    act('cancel_recording');
  };

  const handleOptimisticRecipe = (newDispenses, energyDelta) => {
    if (!data.isBeakerLoaded || recording || !newDispenses || newDispenses.length === 0) return;
    const totalNewVol = newDispenses.reduce((s, d) => s + d.volume, 0);
    if (totalNewVol <= 0) return;
    // Keep existing dispenses when layering a recipe optimistic update.
    const cur = isOptimisticActive && !optimistic.removeAmount && !optimistic.removeAll
      && !optimistic.ejectBeaker && !(optimistic.storageTransfers && optimistic.storageTransfers.length)
      ? optimistic
      : { dispenses: [], energyDelta: 0, serverEnergy: data.energy, serverVolume: data.beakerCurrentVolume || 0 };
    // Cap to free beaker space, matching server min(needed, free) behavior.
    const existingOptVolume = cur.dispenses.reduce((s, d) => s + d.volume, 0);
    const freeSpace = Math.max(0, (data.beakerMaxVolume || 0) - (data.beakerCurrentVolume || 0) - existingOptVolume);
    if (freeSpace <= 0) return;
    // Scale proportionally when requested volume exceeds free space.
    const scale = totalNewVol > freeSpace ? freeSpace / totalNewVol : 1;
    const cappedDispenses = scale < 1
      ? newDispenses.map(d => ({ ...d, volume: Math.round(d.volume * scale * 100) / 100 }))
      : newDispenses;
    const cappedEnergy = energyDelta * scale;
    setOptimistic({
      serverEnergy: cur.serverEnergy,
      serverVolume: cur.serverVolume,
      timestamp: Date.now(),
      energyDelta: cur.energyDelta + cappedEnergy,
      dispenses: [...cur.dispenses, ...cappedDispenses],
      removeAmount: 0,
      removeAll: false,
    });
  };

  const handleRemove = (amount, isAll) => {
    if (data.isBeakerLoaded && !recording) {
      const currentVolume = data.beakerCurrentVolume || 0;
      if (currentVolume > 0) {
        // Preserve existing dispenses/storage while adding a drain.
        const cur = isOptimisticActive && !optimistic.ejectBeaker
          ? optimistic
          : null;
        setOptimistic({
          serverEnergy: cur ? cur.serverEnergy : data.energy,
          serverVolume: cur ? cur.serverVolume : currentVolume,
          serverStoredVol: cur ? cur.serverStoredVol : (data.storedVol || 0),
          timestamp: Date.now(),
          energyDelta: cur ? cur.energyDelta : 0,
          dispenses: cur ? cur.dispenses : [],
          storageTransfers: cur ? cur.storageTransfers : undefined,
          amount: cur ? cur.amount : undefined,
          removeAmount: isAll ? currentVolume : Math.min(amount, currentVolume),
          removeAll: !!isAll,
        });
      }
    }
  };

  const handleEject = () => {
    setOptimistic({
      serverEnergy: data.energy,
      serverVolume: data.beakerCurrentVolume || 0,
      serverStoredVol: data.storedVol || 0,
      timestamp: Date.now(),
      ejectBeaker: true,
      dispenses: [],
      energyDelta: 0,
      removeAmount: 0,
      removeAll: false,
    });
    act('eject');
  };

  const handleDispensePH = (type) => {
    if (!data.isBeakerLoaded || recording) return;
    const isAcid = type === 'acid';
    const chemName = isAcid ? data.phAcidName : data.phBaseName;
    const chemPH = isAcid ? data.phAcidPH : data.phBasePH;
    if (!chemName) return;

    const freeSpace = Math.max(0, (data.beakerMaxVolume || 0) - (data.beakerCurrentVolume || 0));
    if (freeSpace < 1) return;

    // Accumulate onto existing optimistic state, like handleDispense.
    const cur = isOptimisticActive && !optimistic.removeAmount && !optimistic.removeAll
      && !optimistic.ejectBeaker
      ? optimistic
      : { dispenses: [], energyDelta: 0, removeAmount: 0, removeAll: false,
        serverEnergy: data.energy, serverVolume: data.beakerCurrentVolume || 0,
        serverStoredVol: data.storedVol || 0, timestamp: Date.now() };

    setOptimistic({
      ...cur,
      timestamp: Date.now(),
      energyDelta: cur.energyDelta + 1,
      dispenses: [...cur.dispenses, {
        name: chemName,
        volume: 1,
        pH: chemPH,
        pHCol: null,
        reagentColor: null,
      }],
    });
    act('dispense_ph', { type });
  };

  const createStorageOptimistic = (transfers) => {
    // Preserve existing dispenses/removes when applying storage transfers.
    const cur = isOptimisticActive && !optimistic.ejectBeaker
      ? optimistic
      : null;
    return {
      serverEnergy: cur ? cur.serverEnergy : data.energy,
      serverVolume: cur ? cur.serverVolume : (data.beakerCurrentVolume || 0),
      serverStoredVol: cur ? (cur.serverStoredVol ?? (data.storedVol || 0)) : (data.storedVol || 0),
      timestamp: Date.now(),
      storageTransfers: [
        ...(cur?.storageTransfers || []),
        ...transfers,
      ],
      amount: displayAmount,
      dispenses: cur ? cur.dispenses : [],
      energyDelta: cur ? cur.energyDelta : 0,
      removeAmount: cur ? cur.removeAmount : 0,
      removeAll: cur ? cur.removeAll : false,
    };
  };

  const handleStore = (chemicalId) => {
    setOptimistic(createStorageOptimistic([{ direction: 'to_storage', id: chemicalId }]));
    act('store', { id: chemicalId });
  };

  const handleStoreAll = () => {
    setOptimistic(createStorageOptimistic([{ direction: 'store_all' }]));
    act('store_all');
  };

  const handleUnstore = (chemicalId) => {
    setOptimistic(createStorageOptimistic([{ direction: 'from_storage', id: chemicalId }]));
    act('unstore', { id: chemicalId });
  };

  const handleUnstoreAll = () => {
    setOptimistic(createStorageOptimistic([{ direction: 'unstore_all' }]));
    act('unstore_all');
  };

  const handleClearStorage = () => {
    setOptimistic(createStorageOptimistic([{ direction: 'clear_storage' }]));
    act('clear_storage');
  };

  const isEjecting = isOptimisticActive && !!optimistic?.ejectBeaker;

  const display = computeDisplayValues(data, beakerContents, optimistic, isOptimisticActive, storedContents);
  const displayBeakerContents = display.contents;
  const displayBeakerVolume = display.volume;
  const displayEnergy = display.energy;
  const displayIsBeakerLoaded = display.isBeakerLoaded;
  const displayStoredContents = display.storedContents;
  const displayStoredVol = display.storedVol;

  return (
    <Window width={850} height={700} resizable>
      <Window.Content>
        <Stack fill>
          <Stack.Item grow basis="70%">
            <Stack fill vertical>
              <Stack.Item>
                <Section
                  title={
                    <span>
                      <Icon name="bolt" mr={1} />
                      Энергия
                      {recording && (
                        <Box inline color="red" ml={1}>
                          <Icon name="circle" mr={0.5} />
                          Запись
                        </Box>
                      )}
                    </span>
                  }>
                  <ProgressBar
                    value={displayEnergy / data.maxEnergy}
                    ranges={{ good: [0.5, Infinity], average: [0.25, 0.5], bad: [-Infinity, 0.25] }}>
                    {toFixed(displayEnergy)} / {toFixed(data.maxEnergy)} u
                  </ProgressBar>
                </Section>
              </Stack.Item>

              <Stack.Item>
                <Stack align="center">
                  <Stack.Item grow>
                    <Input
                      fluid
                      placeholder="Поиск..."
                      value={searchQuery}
                      onInput={(e, value) => setSearchQuery(value)}
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="times"
                      disabled={!searchQuery}
                      onClick={() => setSearchQuery('')}
                    />
                  </Stack.Item>
                  {activeTab === 'chemicals' && (
                    <>
                      <Stack.Item>
                        <Button
                          compact
                          icon={showIcons ? 'eye' : 'eye-slash'}
                          tooltip={showIcons
                            ? 'Скрыть иконки'
                            : 'Показать иконки'}
                          onClick={() => handleTogglePref('showIcons', 'toggle_icons')}
                        />
                      </Stack.Item>
                      <Stack.Item>
                        <Button
                          compact
                          icon={useReagentColor ? 'palette' : 'tint'}
                          tooltip={useReagentColor
                            ? 'Цвета реагентов (нажмите для pH)'
                            : 'pH цвета (нажмите для цвета реагента)'}
                          onClick={() => handleTogglePref('useReagentColor', 'toggle_color_mode')}
                        />
                      </Stack.Item>
                      <Stack.Item>
                        <Button
                          compact
                          icon={classicView ? 'th' : 'list'}
                          tooltip={classicView
                            ? 'Категории' : 'Обычная таблица'}
                          onClick={() => handleTogglePref('classicView', 'toggle_view')}
                        />
                      </Stack.Item>
                      <Stack.Item>
                        <Button
                          compact
                          icon={alphabeticalSort ? 'sort-alpha-down' : 'sort-amount-down'}
                          tooltip={alphabeticalSort
                            ? 'По алфавиту (нажмите для стандартного порядка)'
                            : 'Стандартный порядок (нажмите для алфавита)'}
                          onClick={() => handleTogglePref('alphabeticalSort', 'toggle_sort')}
                        />
                      </Stack.Item>
                    </>
                  )}
                </Stack>
              </Stack.Item>

              <Stack.Item>
                <AmountControls
                  amount={displayAmount}
                  stepAmount={data.stepAmount}
                  isBeakerLoaded={displayIsBeakerLoaded}
                  beakerMaxVolume={data.beakerMaxVolume}
                  beakerCurrentVolume={data.beakerCurrentVolume}
                  beakerTransferAmounts={beakerTransferAmounts}
                  onAmountChange={handleAmountChange}
                />
              </Stack.Item>

              <Stack.Item>
                <Tabs>
                  <Tabs.Tab
                    selected={activeTab === 'chemicals'}
                    icon="flask"
                    onClick={() => setActiveTab('chemicals')}>
                    Реагенты ({chemicals.length})
                  </Tabs.Tab>
                  <Tabs.Tab
                    selected={activeTab === 'gameRecipes'}
                    icon="book"
                    onClick={() => setActiveTab('gameRecipes')}>
                    Рецепты ({gameRecipesCount})
                  </Tabs.Tab>
                  <Tabs.Tab
                    selected={activeTab === 'savedRecipes'}
                    icon="save"
                    onClick={() => setActiveTab('savedRecipes')}>
                    Мои ({savedRecipes.length})
                  </Tabs.Tab>
                </Tabs>
              </Stack.Item>

              <Stack.Item grow>
                {activeTab === 'chemicals' && (
                  <Section fill scrollable>
                    {classicView ? (
                      <Box mr={-1}>
                        {filteredChemicals.length === 0 && searchQuery ? (
                          <NoticeBox>Ничего не найдено</NoticeBox>
                        ) : (
                          (alphabeticalSort
                            ? getClassicSorted(filteredChemicals)
                            : filteredChemicals
                          ).map(chemical => (
                            <Button
                              key={chemical.id}
                              width="129.5px"
                              lineHeight={1.75}
                              tooltip={showPH ? ('pH: ' + chemical.pH) : chemical.title}
                              onClick={() => handleDispense(chemical.id)}>
                              {!!showIcons && (
                                <Icon
                                  name="tint"
                                  color={useReagentColor ? chemical.reagentColor : chemical.pHCol}
                                  mr={0.5}
                                />
                              )}
                              {chemical.title}
                            </Button>
                          ))
                        )}
                      </Box>
                    ) : (
                      <>
                        {favoriteChemicals.length > 0 && !searchQuery && (
                          <Box mb={1}>
                            <Box color="label" mb={0.5}>
                              <Icon name="star" mr={0.5} />
                              Избранное:
                            </Box>
                            <Box>
                              {favoriteChemicals.map(chemical => (
                                <ChemicalButton
                                  key={chemical.id}
                                  chemical={chemical}
                                  onDispense={handleDispense}
                                  onToggleFavorite={toggleFavorite}
                                  isFavorite
                                  useReagentColor={useReagentColor}
                                  showIcons={showIcons}
                                  showPH={showPH}
                                />
                              ))}
                            </Box>
                          </Box>
                        )}

                        {recentChemicalsList.length > 0 && !searchQuery && (
                          <Box mb={1}>
                            <Box color="label" mb={0.5}>
                              <Icon name="history" mr={0.5} />
                              Недавние:
                            </Box>
                            <Box>
                              {recentChemicalsList.map(chemical => (
                                <ChemicalButton
                                  key={chemical.id}
                                  chemical={chemical}
                                  onDispense={handleDispense}
                                  onToggleFavorite={toggleFavorite}
                                  isFavorite={favoritesSet.has(chemical.id)}
                                  compact
                                  useReagentColor={useReagentColor}
                                  showIcons={showIcons}
                                  showPH={showPH}
                                />
                              ))}
                            </Box>
                          </Box>
                        )}

                        {searchQuery ? (
                          <Box>
                            {filteredChemicals.length === 0 ? (
                              <NoticeBox>Ничего не найдено</NoticeBox>
                            ) : (
                              filteredChemicals.map(chemical => (
                                <ChemicalButton
                                  key={chemical.id}
                                  chemical={chemical}
                                  onDispense={handleDispense}
                                  onToggleFavorite={toggleFavorite}
                                  isFavorite={favoritesSet.has(chemical.id)}
                                  useReagentColor={useReagentColor}
                                  showIcons={showIcons}
                                  showPH={showPH}
                                />
                              ))
                            )}
                          </Box>
                        ) : (
                          sortedCategories.map(category => {
                            const config = categoryConfig[category] || categoryConfig.other;
                            const categoryChemicals = chemicalsByCategory[category];
                            return (
                              <Collapsible
                                key={category}
                                title={
                                  <span>
                                    <Icon name={config.icon} mr={0.5} />
                                    {config.title} ({categoryChemicals.length})
                                  </span>
                                }
                                open={expandedCategories[category]}
                                onToggle={() => toggleCategory(category)}>
                                <Box>
                                  {categoryChemicals.map(chemical => (
                                    <ChemicalButton
                                      key={chemical.id}
                                      chemical={chemical}
                                      onDispense={handleDispense}
                                      onToggleFavorite={toggleFavorite}
                                      isFavorite={favoritesSet.has(chemical.id)}
                                      useReagentColor={useReagentColor}
                                      showIcons={showIcons}
                                      showPH={showPH}
                                    />
                                  ))}
                                </Box>
                              </Collapsible>
                            );
                          })
                        )}
                      </>
                    )}
                  </Section>
                )}

                {activeTab === 'gameRecipes' && (
                  <GameRecipesTab
                    gameRecipes={gameRecipes}
                    searchQuery={searchQuery}
                    isBeakerLoaded={displayIsBeakerLoaded}
                    beakerContents={displayBeakerContents}
                    beakerCurrentVolume={displayBeakerVolume}
                    beakerMaxVolume={data.beakerMaxVolume}
                    manipulatorTier={data.manipulatorTier || 1}
                    isEmagged={!!data.isEmagged}
                    isDrinkDispenser={!!data.isDrinkDispenser}
                    dispenserType={data.dispenserType || 0}
                    onOptimisticRecipe={handleOptimisticRecipe}
                    markPending={markPending}
                    isActionPending={isActionPending}
                    beginRecipeAction={beginRecipeAction}
                    chemMetadata={chemMetadata}
                  />
                )}

                {activeTab === 'savedRecipes' && (
                  <SavedRecipesTab
                    recipes={savedRecipes}
                    recording={recording}
                    isBeakerLoaded={displayIsBeakerLoaded}
                    onOptimisticRecipe={handleOptimisticRecipe}
                    markPending={markPending}
                    isActionPending={isActionPending}
                    beginRecipeAction={beginRecipeAction}
                    onDeleteRecipe={handleDeleteRecipe}
                    onStartRecording={handleStartRecording}
                    onCancelRecording={handleCancelRecording}
                    chemMetadata={chemMetadata}
                  />
                )}
              </Stack.Item>
            </Stack>
          </Stack.Item>

          <Stack.Item basis="30%">
            <Stack fill vertical>
              <Stack.Item grow basis="65%">
                <BeakerSidePanel
                  recording={recording}
                  isBeakerLoaded={displayIsBeakerLoaded}
                  isEjecting={isEjecting}
                  beakerContents={displayBeakerContents}
                  beakerCurrentVolume={displayBeakerVolume}
                  beakerMaxVolume={data.beakerMaxVolume}
                  beakerCurrentpH={data.beakerCurrentpH}
                  beakerCurrentpHCol={data.beakerCurrentpHCol}
                  beakerTransferAmounts={beakerTransferAmounts}
                  canStore={data.canStore}
                  phAcidName={data.phAcidName}
                  phAcidPH={data.phAcidPH}
                  phBaseName={data.phBaseName}
                  phBasePH={data.phBasePH}
                  isDrinkDispenser={!!data.isDrinkDispenser}
                  onOptimisticRemove={handleRemove}
                  onEject={handleEject}
                  onDispensePH={handleDispensePH}
                  onStore={handleStore}
                  onStoreAll={handleStoreAll}
                />
              </Stack.Item>

              {!!data.canStore && (
                <Stack.Item grow basis="35%">
                  <StorageSidePanel
                    storedContents={displayStoredContents}
                    storedVol={displayStoredVol}
                    maxVol={data.maxVol}
                    amount={displayAmount}
                    recording={recording}
                    isBeakerLoaded={displayIsBeakerLoaded}
                    onUnstore={handleUnstore}
                    onUnstoreAll={handleUnstoreAll}
                    onClearStorage={handleClearStorage}
                    isEjecting={isEjecting}
                  />
                </Stack.Item>
              )}
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const AmountControls = (props, context) => {
  const { amount, stepAmount, isBeakerLoaded, beakerMaxVolume, beakerCurrentVolume, beakerTransferAmounts, onAmountChange } = props;

  // DM lists may arrive as objects; normalize to a numeric array.
  let beakerAmounts = [];
  if (beakerTransferAmounts) {
    if (Array.isArray(beakerTransferAmounts)) {
      beakerAmounts = beakerTransferAmounts;
    } else if (typeof beakerTransferAmounts === 'object') {
      beakerAmounts = Object.values(beakerTransferAmounts).filter(v => typeof v === 'number');
    }
  }

  // Deduplicate via filter; Set spread is unreliable in this environment.
  const doseAmounts = beakerAmounts.length > 0
    ? [1, ...beakerAmounts].filter((v, i, a) => a.indexOf(v) === i).sort((a, b) => a - b)
    : AMOUNT_PRESETS;

  return (
    <Section
      title={<span><Icon name="flask" mr={1} />Доза: <b>{amount}</b> u</span>}>
      <Stack align="center">
        <Stack.Item grow>
          {doseAmounts.map(amt => (
            <Button
              key={amt}
              compact
              selected={amount === amt}
              content={'+' + amt}
              onClick={() => onAmountChange(amt)}
            />
          ))}
        </Stack.Item>
        <Stack.Item>
          <NumberInput
            width="60px"
            value={amount}
            minValue={stepAmount || 1}
            maxValue={beakerMaxVolume || 200}
            step={stepAmount || 1}
            onChange={(e, value) => onAmountChange(value)}
          />
          <Button
            ml={0.5}
            icon="fill-drip"
            tooltip="Максимум"
            disabled={!isBeakerLoaded}
            onClick={() => {
              const freeSpace = (beakerMaxVolume || 0) - (beakerCurrentVolume || 0);
              if (freeSpace > 0) {
                onAmountChange(Math.floor(freeSpace));
              }
            }}
          />
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const ChemicalButton = (props) => {
  const { chemical, onDispense, onToggleFavorite, isFavorite, useReagentColor, showIcons, showPH = true } = props;
  const displayColor = useReagentColor ? chemical.reagentColor : chemical.pHCol;

  return (
    <Button
      m={0.25}
      lineHeight={1.5}
      tooltip={
        <Box>
          <Box bold>{chemical.title}</Box>
          {showPH && <Box color="label">pH: {chemical.pH}</Box>}
          <Box color="label" fontSize="10px" mt={0.5}>
            Shift+Click - избранное
          </Box>
        </Box>
      }
      onClick={(e) => {
        if (e.shiftKey) {
          onToggleFavorite(chemical.id);
        } else {
          onDispense(chemical.id);
        }
      }}>
      {isFavorite && <Icon name="star" mr={0.5} />}
      {!!showIcons && <Icon name="tint" color={displayColor} mr={0.5} />}
      {chemical.title}
    </Button>
  );
};

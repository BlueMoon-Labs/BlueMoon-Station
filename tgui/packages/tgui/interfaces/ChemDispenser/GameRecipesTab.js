import { toFixed } from 'common/math';
import { createSearch } from 'common/string';

import { useBackend, useLocalState } from '../../backend';
import {
  Box,
  Button,
  Collapsible,
  Divider,
  Icon,
  NoticeBox,
  NumberInput,
  Section,
  Stack,
  Tooltip,
} from '../../components';
import {
  FermiChemBadge,
  FermiChemDetails,
  SubRecipesChain,
} from './RecipeComponents';
import {
  buildBeakerLookup,
  calculateActualAmount,
  calculateTotalInputVolume,
  calculateWasteInfo,
  CATEGORY_CONFIG,
  DISPENSER_TYPE_BOOZE,
  DISPENSER_TYPE_SODA,
  DRINK_CATEGORY_CONFIG,
  hasCrossDispenserReqs,
  isRecipeUnlocked,
  russianPlural,
} from './utils';

// Items limit per category - balance between performance and usability
const ITEMS_PER_CATEGORY = 50;
const MAX_SEARCH_RESULTS = 30;

// Module-level cache: gameRecipes is static data, so pre-compute search strings once
let _searchCache = { key: null, strings: null, entries: null };

const ensureSearchCache = (gameRecipes) => {
  if (_searchCache.key === gameRecipes) return;
  _searchCache.key = gameRecipes;
  _searchCache.entries = Object.entries(gameRecipes);
  _searchCache.strings = new Map();
  for (const entry of _searchCache.entries) {
    _searchCache.strings.set(entry[0], buildRecipeSearchString(entry));
  }
};

// Builds a searchable string from a recipe entry for contextual search
const buildRecipeSearchString = ([name, recipe]) => {
  const parts = [name];

  if (recipe.desc) {
    parts.push(recipe.desc);
  }

  if (recipe.required) {
    parts.push(...Object.keys(recipe.required));
  }

  if (recipe.base_ingredients) {
    parts.push(...Object.keys(recipe.base_ingredients));
  }

  if (recipe.catalysts) {
    parts.push(...Object.keys(recipe.catalysts));
  }

  if (recipe.sub_recipes) {
    parts.push(...Object.keys(recipe.sub_recipes));
  }

  if (recipe.alt_recipes) {
    for (const altRecipe of recipe.alt_recipes) {
      if (altRecipe.required) {
        parts.push(...Object.keys(altRecipe.required));
      }
      if (altRecipe.base_ingredients) {
        parts.push(...Object.keys(altRecipe.base_ingredients));
      }
    }
  }

  return parts.join(' ');
};

// Shared recipe name component with star, tooltip, shift-click
const RecipeName = ({ name, desc, isFavorite, onToggleFavorite, children }) => {
  const handleClick = (e) => {
    if (e.shiftKey) {
      e.preventDefault();
      onToggleFavorite(name);
    }
  };

  const nameContent = (
    <>
      {isFavorite && <Icon name="star" color="yellow" mr={0.5} />}
      {name}
      {desc && <Icon name="info-circle" ml={0.5} color="label" size={0.8} />}
    </>
  );

  return (
    <Box bold inline>
      {desc ? (
        <Tooltip content={desc} position="right">
          <span style={{ cursor: 'help' }} onClick={handleClick}>
            {nameContent}
          </span>
        </Tooltip>
      ) : (
        <span style={{ cursor: 'pointer' }} onClick={handleClick}>
          {nameContent}
        </span>
      )}
      {children}
    </Box>
  );
};

// Cross-dispenser badge component for drink dispensers
const CrossDispenserBadge = ({ type, tooltip }) => {
  const configs = {
    soda: { label: 'SODA', color: 'blue', icon: 'mug-hot' },
    booze: { label: 'BOOZE', color: 'purple', icon: 'wine-glass' },
    enzyme: { label: 'ENZYME', color: 'olive', icon: 'vial' },
    chem: { label: 'CHEM', color: 'red', icon: 'flask' },
  };
  const config = configs[type];
  if (!config) return null;

  return (
    <Tooltip content={tooltip}>
      <Box
        as="span"
        ml={0.5}
        px={0.5}
        backgroundColor={config.color}
        style={{ borderRadius: '3px', fontSize: '10px' }}>
        <Icon name={config.icon} mr={0.3} />
        {config.label}
      </Box>
    </Tooltip>
  );
};

// Category badge for search results context
const CategoryBadge = ({ category, isDrinkDispenser }) => {
  const catConfig = isDrinkDispenser ? DRINK_CATEGORY_CONFIG : CATEGORY_CONFIG;
  const config = catConfig[category] || catConfig.other;
  return (
    <Box
      as="span"
      ml={0.5}
      px={0.5}
      color="label"
      style={{ borderRadius: '3px', fontSize: '9px' }}>
      <Icon name={config.icon} mr={0.3} />
      {config.title}
    </Box>
  );
};

// Build context-aware tooltip for disabled dispense button on cross-dispenser recipes
const buildCrossDispenserTooltip = (crossDispenser, dispenserType) => {
  const parts = ['Требуются ингредиенты из другого диспенсера:'];
  const isSoda = dispenserType === DISPENSER_TYPE_SODA;
  const isBooze = dispenserType === DISPENSER_TYPE_BOOZE;

  if (isSoda && !!crossDispenser.requires_booze) {
    parts.push('- Booze Dispenser (алкоголь)');
  }
  if (isBooze && !!crossDispenser.requires_soda) {
    parts.push('- Soda Dispenser (безалк.)');
  }
  if (crossDispenser.requires_enzyme) {
    parts.push('- Энзим (катализатор)');
  }
  if (crossDispenser.requires_chem) {
    parts.push('- Chem Dispenser');
  }
  parts.push('Используйте «Частично» для выдачи доступных.');
  return parts.join('\n');
};

export const GameRecipesTab = (props, context) => {
  const { act } = useBackend(context);
  const { gameRecipes, searchQuery, isBeakerLoaded, beakerContents = [], beakerCurrentVolume, beakerMaxVolume, manipulatorTier = 1, isEmagged = false, isDrinkDispenser = false, dispenserType = 0, onOptimisticRecipe } = props;

  const triggerOptimisticRecipe = (baseIngredients, mult) => {
    if (!onOptimisticRecipe) return;
    let totalVol = 0;
    for (const data of Object.values(baseIngredients)) {
      if (data.can_dispense) {
        totalVol += calculateActualAmount(data, mult);
      }
    }
    if (totalVol > 0) {
      onOptimisticRecipe(totalVol, totalVol);
    }
  };

  const [multiplier, setMultiplier] = useLocalState(context, 'recipe_multiplier', 1);
  // Default expanded categories depend on dispenser type
  const defaultExpandedCats = isDrinkDispenser
    ? { alcoholic_drinks: true, soft_drinks: true }
    : { medicine: true };
  const [expandedCats, setExpandedCats] = useLocalState(context, 'recipe_cats_v2', defaultExpandedCats);
  const [recipeFavorites, setRecipeFavorites] = useLocalState(context, 'recipe_favorites', []);
  const [showOnlyMakeable, setShowOnlyMakeable] = useLocalState(context, 'recipe_filter_makeable', false);
  const [expandedPages, setExpandedPages] = useLocalState(context, 'recipe_pages', {});

  const beakerByName = buildBeakerLookup(beakerContents);

  const canMakeRecipe = (recipe) => {
    const baseIngredients = recipe.base_ingredients || {};
    for (const [reagentName, data] of Object.entries(baseIngredients)) {
      const neededAmount = calculateActualAmount(data, multiplier);
      if (data.can_dispense) continue;
      if ((beakerByName[reagentName] || 0) < neededAmount) return false;
    }
    return true;
  };

  const toggleRecipeFavorite = (recipeName) => {
    if (recipeFavorites.includes(recipeName)) {
      setRecipeFavorites(recipeFavorites.filter(n => n !== recipeName));
    } else {
      setRecipeFavorites([...recipeFavorites, recipeName]);
    }
  };

  ensureSearchCache(gameRecipes);
  const recipesArray = _searchCache.entries;
  const searchFilter = createSearch(searchQuery, ([name]) => _searchCache.strings.get(name));

  // For drink dispensers, only show drink categories (alcoholic_drinks and soft_drinks)
  const drinkCategories = ['alcoholic_drinks', 'soft_drinks'];

  let filteredRecipes = searchQuery
    ? recipesArray.filter(searchFilter)
    : recipesArray;

  // Pre-filter by category for drink dispensers
  if (isDrinkDispenser) {
    filteredRecipes = filteredRecipes.filter(([, recipe]) =>
      drinkCategories.includes(recipe.category || 'other'));
  }

  if (showOnlyMakeable) {
    filteredRecipes = filteredRecipes.filter(([, recipe]) =>
      recipe.is_extract_recipe || (
        // Skip tier checks for drink dispensers (they don't have meaningful upgrades)
        (isDrinkDispenser || ((recipe.tier || 1) >= 6 ? isEmagged : manipulatorTier >= (recipe.tier || 1)))
        && canMakeRecipe(recipe)
      ));
  }

  const favoriteRecipesList = filteredRecipes.filter(([name]) =>
    recipeFavorites.includes(name)
  );

  const byCategory = {};
  filteredRecipes.forEach(([name, recipe]) => {
    const cat = recipe.category || 'other';
    if (!byCategory[cat]) byCategory[cat] = [];
    byCategory[cat].push([name, recipe]);
  });

  // Use drink-specific category order for drink dispensers
  const categoryConfig = isDrinkDispenser ? DRINK_CATEGORY_CONFIG : CATEGORY_CONFIG;

  // Categories are already filtered by pre-filter above, so just sort them
  const sortedCats = Object.keys(byCategory).sort((a, b) => {
    const orderA = categoryConfig[a]?.order || 99;
    const orderB = categoryConfig[b]?.order || 99;
    return orderA - orderB;
  });

  // Check if category should be expanded
  const isCatExpanded = (cat) => {
    return !!expandedCats[cat];
  };

  const toggleCat = (cat) => {
    setExpandedCats({ ...expandedCats, [cat]: !expandedCats[cat] });
  };

  const renderExtractRecipeRow = ([name, recipe]) => {
    const isRecipeFavorite = recipeFavorites.includes(name);
    return (
      <Box key={name} className="candystripe" py={0.5} px={0.3}>
        <Stack align="center">
          <Stack.Item grow basis={0}>
            <RecipeName
              name={name}
              desc={recipe.desc}
              isFavorite={isRecipeFavorite}
              onToggleFavorite={toggleRecipeFavorite}
            />
          </Stack.Item>
          <Stack.Item shrink={0} ml={1}>
            <Box inline color="good" bold>
              &rarr; {recipe.result_amount || 1}u
            </Box>
          </Stack.Item>
        </Stack>
        <Box fontSize="11px" mt={0.2}>
          <Icon name="droplet" mr={0.5} color="violet" />
          <Box as="span" color="violet">
            {recipe.extract_container_name}
          </Box>
          {' + '}
          {Object.entries(recipe.required || {}).map(([r, amount], idx) => (
            <span key={r}>
              {idx > 0 && ' + '}
              <Box as="span" color="label">
                {r} {amount}u
              </Box>
            </span>
          ))}
        </Box>
      </Box>
    );
  };

  const renderBadges = (variantRecipe, crossDispenser = null) => {
    const isFermiChem = !!variantRecipe.is_fermichem;
    const requiredTier = variantRecipe.tier || 1;
    const isEmagTier = requiredTier >= 6;
    // Determine which cross-dispenser badges to show (only for drink dispensers)
    const isSodaDispenser = dispenserType === DISPENSER_TYPE_SODA;
    const isBoozeDispenser = dispenserType === DISPENSER_TYPE_BOOZE;
    const showCrossDispenserBadges = isDrinkDispenser && crossDispenser;
    const badgeHasCrossReqs = showCrossDispenserBadges && hasCrossDispenserReqs(crossDispenser, dispenserType);
    const isUnlocked = isRecipeUnlocked({ tier: requiredTier, isDrinkDispenser, isEmagged, manipulatorTier, hasCrossReqs: badgeHasCrossReqs });

    // Note: DM sends FALSE as 0, so we need explicit boolean checks (!!value)
    const needsSoda = showCrossDispenserBadges && isBoozeDispenser && !!crossDispenser.requires_soda;
    const needsBooze = showCrossDispenserBadges && isSodaDispenser && !!crossDispenser.requires_booze;
    const needsEnzyme = showCrossDispenserBadges && !!crossDispenser.requires_enzyme;
    const needsChem = showCrossDispenserBadges && !!crossDispenser.requires_chem;

    return (
      <>
        {isFermiChem && <FermiChemBadge />}
        {/* Hide tier badges on drink dispensers - they have no meaningful upgrades */}
        {!isDrinkDispenser && requiredTier > 1 && (
          <Tooltip content={isEmagTier
            ? (isUnlocked ? 'EMAG (разблокировано)' : 'Требуется EMAG')
            : (isUnlocked
              ? `Манипулятор T${requiredTier} (разблокировано)`
              : `Требуется манипулятор T${requiredTier}`)}>
            <Box
              as="span"
              ml={0.5}
              px={0.5}
              backgroundColor={isUnlocked ? 'teal' : 'bad'}
              style={{ borderRadius: '3px', fontSize: '10px' }}>
              {!isUnlocked && <Icon name="lock" mr={0.3} />}
              {isEmagTier ? 'EMAG' : `T${requiredTier}`}
            </Box>
          </Tooltip>
        )}
        {/* Cross-dispenser badges for drink dispensers */}
        {needsSoda && (
          <CrossDispenserBadge type="soda" tooltip="Требуются ингредиенты из Soda Dispenser" />
        )}
        {needsBooze && (
          <CrossDispenserBadge type="booze" tooltip="Требуются ингредиенты из Booze Dispenser" />
        )}
        {needsEnzyme && (
          <CrossDispenserBadge type="enzyme" tooltip="Требуется энзим (катализатор)" />
        )}
        {needsChem && (
          <CrossDispenserBadge type="chem" tooltip="Требуются ингредиенты из Chem Dispenser" />
        )}
        {!isFermiChem && variantRecipe.temp > 0 && (
          <Box as="span" color={variantRecipe.is_cold ? "blue" : "orange"} ml={0.5} fontSize="10px">
            {variantRecipe.is_cold ? '\u2264' : '\u2265'}{variantRecipe.temp}K
          </Box>
        )}
        {variantRecipe.catalysts && Object.keys(variantRecipe.catalysts).length > 0 && (
          <Box as="span" color="yellow" ml={0.5} fontSize="10px">
            кат: {Object.entries(variantRecipe.catalysts).map(([r, amt]) =>
              `${r} ${amt}u`
            ).join(', ')}
          </Box>
        )}
      </>
    );
  };

  const renderDispenseControls = (variantRecipe, name, altIndex, crossDispenser = null) => {
    const baseIngredients = variantRecipe.base_ingredients || {};
    const requiredTier = variantRecipe.tier || 1;
    const isEmagTier = requiredTier >= 6;
    const wasteInfo = calculateWasteInfo(variantRecipe, multiplier);
    const canMake = canMakeRecipe(variantRecipe);
    const totalInputVol = calculateTotalInputVolume(baseIngredients, multiplier);
    const freeSpace = Math.max(0, (beakerMaxVolume || 0) - (beakerCurrentVolume || 0));
    const willOverflow = isBeakerLoaded && totalInputVol > freeSpace;

    const dispenseParams = { recipe: name, multiplier };
    if (altIndex > 0) {
      dispenseParams.alt_index = altIndex;
    }

    // For drink dispensers: check if we can partial dispense
    // (some ingredients available on this dispenser, but not all)
    const needsCrossDispenser = isDrinkDispenser && hasCrossDispenserReqs(crossDispenser, dispenserType);
    // Cross-dispenser recipes with EMAG tier are accessible since those ingredients come from elsewhere
    const isUnlocked = isRecipeUnlocked({ tier: requiredTier, isDrinkDispenser, isEmagged, manipulatorTier, hasCrossReqs: needsCrossDispenser });

    // Check if there are any ingredients we CAN dispense from this dispenser
    const canPartialDispense = needsCrossDispenser && Object.values(baseIngredients).some(
      data => data.can_dispense
    );

    return (
      <Box inline style={{ whiteSpace: 'nowrap' }}>
        <Box as="span" color="good" bold>
          &rarr; {(variantRecipe.result_amount || 1) * multiplier}u
        </Box>
        {wasteInfo.length > 0 && (
          <Tooltip content={
            <Box>
              <Box bold mb={0.5}>Остаток:</Box>
              {wasteInfo.map(w => (
                <Box key={w.name}>{w.name}: {w.amount}u</Box>
              ))}
              {variantRecipe.clean_batches && variantRecipe.clean_batches.length > 0 && (
                <Box mt={0.5} color="label">
                  Чистые партии: {variantRecipe.clean_batches.join(', ')}x
                </Box>
              )}
            </Box>
          }>
            <Box as="span" color="average" ml={0.3}>
              (+{wasteInfo.reduce((sum, w) => sum + w.amount, 0)}u)
            </Box>
          </Tooltip>
        )}
        <Box as="span" color="label" fontSize="10px" ml={0.5}>
          ({totalInputVol}u вх.)
        </Box>
        {/* Cross-dispenser recipes: partial = primary, full = secondary */}
        {needsCrossDispenser ? (
          <>
            {canPartialDispense && (
              <Button
                compact
                ml={0.5}
                icon="flask"
                content={multiplier > 1 ? `x${multiplier}` : 'Выдать доступные'}
                color={isBeakerLoaded ? 'green' : 'default'}
                disabled={!isBeakerLoaded}
                tooltip="Выдать только доступные на этом диспенсере ингредиенты"
                onClick={() => {
                  triggerOptimisticRecipe(baseIngredients, multiplier);
                  act('dispense_recipe_partial', dispenseParams);
                }}
              />
            )}
            {(() => {
              const totalIngredients = Object.keys(baseIngredients).length;
              const readyIngredients = Object.entries(baseIngredients).filter(
                ([ingredientName, data]) => {
                  if (data.can_dispense) return true;
                  const needed = calculateActualAmount(data, multiplier);
                  return (beakerByName[ingredientName] || 0) >= needed;
                }
              ).length;
              return readyIngredients < totalIngredients && (
                <Box as="span" color="label" fontSize="10px" ml={0.3}>
                  [{readyIngredients}/{totalIngredients}]
                </Box>
              );
            })()}
            <Button
              compact
              ml={0.3}
              icon={isUnlocked ? 'flask' : 'lock'}
              color={!isUnlocked ? 'bad' : (canMake ? (willOverflow ? 'average' : 'teal') : 'default')}
              disabled={!isBeakerLoaded || !canMake || !isUnlocked}
              tooltip={!isUnlocked
                ? (isEmagTier ? 'Заблокировано! Требуется EMAG' : `Заблокировано! Требуется манипулятор T${requiredTier}+`)
                : !canMake
                  ? buildCrossDispenserTooltip(crossDispenser, dispenserType)
                  : willOverflow
                    ? `Недостаточно места! Нужно ${totalInputVol}u, свободно ${toFixed(freeSpace)}u`
                    : 'Выдать все ингредиенты (требуется содержимое из другого диспенсера в ёмкости)'}
              onClick={() => {
                triggerOptimisticRecipe(baseIngredients, multiplier);
                act('dispense_recipe_game', dispenseParams);
              }}
            />
          </>
        ) : (
          <>
            {/* Non-cross-dispenser: standard partial + full buttons */}
            {canPartialDispense && (
              <Button
                compact
                ml={0.5}
                icon="clock"
                content="Частично"
                color="teal"
                disabled={!isBeakerLoaded}
                tooltip="Выдать только доступные на этом диспенсере ингредиенты"
                onClick={() => {
                  triggerOptimisticRecipe(baseIngredients, multiplier);
                  act('dispense_recipe_partial', dispenseParams);
                }}
              />
            )}
            <Button
              compact
              ml={0.5}
              icon={isUnlocked ? 'flask' : 'lock'}
              content={multiplier > 1 ? `x${multiplier}` : 'Выдать'}
              color={!isUnlocked ? 'bad' : (canMake ? (willOverflow ? 'average' : 'green') : 'bad')}
              disabled={!isBeakerLoaded || !canMake || !isUnlocked}
              tooltip={!isUnlocked
                ? (isEmagTier ? 'Заблокировано! Требуется EMAG' : `Заблокировано! Требуется манипулятор T${requiredTier}+`)
                : !canMake
                  ? 'Недостаточно ингредиентов (проверьте ёмкость)'
                  : willOverflow
                    ? `Недостаточно места! Нужно ${totalInputVol}u, свободно ${toFixed(freeSpace)}u`
                    : 'Выдать все базовые ингредиенты'}
              onClick={() => {
                triggerOptimisticRecipe(baseIngredients, multiplier);
                act('dispense_recipe_game', dispenseParams);
              }}
            />
          </>
        )}
        {wasteInfo.length > 0 && (() => {
          const cleanBatches = variantRecipe.clean_batches || [];
          const nextClean = cleanBatches.find(n => n > multiplier) || 0;
          return nextClean > 0 && (
            <Button
              compact
              ml={0.3}
              icon="sync"
              tooltip={`Округлить до ${nextClean}x (без остатка)`}
              onClick={() => setMultiplier(nextClean)}
            />
          );
        })()}
      </Box>
    );
  };

  const renderRecipeBody = (variantRecipe, name, altIndex) => {
    const baseIngredients = variantRecipe.base_ingredients || {};
    const isFermiChem = !!variantRecipe.is_fermichem;
    const requiredTier = variantRecipe.tier || 1;
    // Drink dispensers: always unlock for sub-recipe chain display
    // Main unlock gating is handled by renderRecipeRow and renderDispenseControls
    const isUnlocked = isDrinkDispenser || isRecipeUnlocked({ tier: requiredTier, isDrinkDispenser: false, isEmagged, manipulatorTier });

    const requiredKeys = Object.keys(variantRecipe.required || {});
    const baseKeys = Object.keys(baseIngredients);
    const hasSubRecipes = baseKeys.length !== requiredKeys.length ||
      baseKeys.some(k => !requiredKeys.includes(k));

    return (
      <>
        {isFermiChem && <FermiChemDetails recipe={variantRecipe} />}

        <Box fontSize="11px" mt={0.2}>
          <Icon name="flask" mr={0.5} color="label" />
          {Object.entries(variantRecipe.required || {}).map(([r, amount], idx) => {
            const actualAmount = amount * multiplier;
            const subRecipes = variantRecipe.sub_recipes || {};
            const isIntermediate = !!subRecipes[r];
            const baseData = baseIngredients[r];
            const canDispense = baseData && baseData.can_dispense;
            const beakerAmount = beakerByName[r] || 0;
            let ingredientColor;
            if (canDispense) {
              ingredientColor = 'good';
            } else if (isIntermediate) {
              ingredientColor = 'cyan';
            } else if (beakerAmount >= actualAmount) {
              ingredientColor = 'blue';
            } else if (beakerAmount > 0) {
              ingredientColor = 'average';
            } else {
              ingredientColor = 'bad';
            }
            return (
              <span key={r}>
                {idx > 0 && ' + '}
                <Box
                  as="span"
                  color={ingredientColor}
                  bold={!canDispense && !isIntermediate}>
                  {r} {actualAmount}u
                  {!canDispense && !isIntermediate && beakerAmount > 0 && (
                    <Tooltip content={`В ёмкости: ${beakerAmount}u`}>
                      <Icon name="vial" ml={0.3} color={ingredientColor} />
                    </Tooltip>
                  )}
                </Box>
              </span>
            );
          })}
        </Box>

        {hasSubRecipes && (
          <SubRecipesChain
            recipe={variantRecipe}
            name={name}
            multiplier={multiplier}
            isBeakerLoaded={isBeakerLoaded}
            beakerByName={beakerByName}
            isUnlocked={isUnlocked}
            altIndex={altIndex}
            dispenserType={dispenserType}
            isDrinkDispenser={isDrinkDispenser}
          />
        )}
      </>
    );
  };

  const renderRecipeRow = ([name, recipe]) => {
    if (recipe.is_extract_recipe) {
      return renderExtractRecipeRow([name, recipe]);
    }

    const isRecipeFavorite = recipeFavorites.includes(name);
    const altRecipes = recipe.alt_recipes || [];
    const hasAlts = altRecipes.length > 0;

    // For drink dispensers: cross-dispenser recipes with EMAG tier are still accessible
    // because the EMAG-tier ingredients come from external sources (chem dispenser etc.)
    const hasCrossReqs = isDrinkDispenser && hasCrossDispenserReqs(recipe.cross_dispenser, dispenserType);
    const singleUnlocked = hasAlts ? true : isRecipeUnlocked({ tier: recipe.tier, isDrinkDispenser, isEmagged, manipulatorTier, hasCrossReqs });

    return (
      <Box key={name} className="candystripe" py={0.5} px={0.3}
        opacity={singleUnlocked ? 1 : 0.5}>
        {hasAlts ? (
          <>
            <Box bold mb={0.3}>
              <RecipeName
                name={name}
                desc={recipe.desc}
                isFavorite={isRecipeFavorite}
                onToggleFavorite={toggleRecipeFavorite}>
                {searchQuery && recipe.category && (
                  <CategoryBadge category={recipe.category} isDrinkDispenser={isDrinkDispenser} />
                )}
                <Box as="span" ml={0.5} color="label" fontSize="10px">
                  ({altRecipes.length + 1} {russianPlural(altRecipes.length + 1, 'рецепт', 'рецепта', 'рецептов')})
                </Box>
              </RecipeName>
            </Box>
            {[recipe, ...altRecipes].map((variantRecipe, idx) => {
              const vUnlocked = isRecipeUnlocked({ tier: variantRecipe.tier, isDrinkDispenser, isEmagged, manipulatorTier, hasCrossReqs });
              const vCanMake = vUnlocked && canMakeRecipe(variantRecipe);
              const borderColor = !vUnlocked
                ? 'rgba(255,80,80,0.4)'
                : vCanMake
                  ? 'rgba(80,255,80,0.5)'
                  : 'rgba(255,255,255,0.15)';
              const altIndex = idx === 0 ? 0 : idx;

              return (
                <Box key={idx}
                  mt={idx > 0 ? 0.2 : 0}
                  opacity={vUnlocked ? 1 : 0.5}
                  style={{
                    backgroundColor: 'rgba(255,255,255,0.03)',
                    borderLeft: `3px solid ${borderColor}`,
                    borderRadius: '0 3px 3px 0',
                    padding: '2px 4px',
                  }}>
                  <Stack align="center">
                    <Stack.Item shrink={0}>
                      <Box color="label" fontSize="10px" bold inline mr={0.5}>
                        #{idx + 1}
                      </Box>
                    </Stack.Item>
                    <Stack.Item shrink={0}>
                      <Box inline fontSize="10px">
                        {renderBadges(variantRecipe, recipe.cross_dispenser)}
                      </Box>
                    </Stack.Item>
                    <Stack.Item grow basis={0} />
                    <Stack.Item shrink={0} ml={1}>
                      {renderDispenseControls(variantRecipe, name, altIndex, recipe.cross_dispenser)}
                    </Stack.Item>
                  </Stack>
                  {renderRecipeBody(variantRecipe, name, altIndex)}
                </Box>
              );
            })}
          </>
        ) : (
          <>
            <Stack align="center" wrap="wrap">
              <Stack.Item grow basis={0} style={{ minWidth: '120px' }}>
                <RecipeName
                  name={name}
                  desc={recipe.desc}
                  isFavorite={isRecipeFavorite}
                  onToggleFavorite={toggleRecipeFavorite}>
                  {searchQuery && recipe.category && (
                    <CategoryBadge category={recipe.category} isDrinkDispenser={isDrinkDispenser} />
                  )}
                  {renderBadges(recipe, recipe.cross_dispenser)}
                </RecipeName>
              </Stack.Item>
              <Stack.Item shrink={0} ml={1}>
                {renderDispenseControls(recipe, name, 0, recipe.cross_dispenser)}
              </Stack.Item>
            </Stack>
            {renderRecipeBody(recipe, name, 0)}
          </>
        )}
      </Box>
    );
  };

  return (
    <Section
      fill
      scrollable
      title="Известные рецепты"
      buttons={
        <Stack align="center">
          <Stack.Item>
            <Button
              compact
              icon="filter"
              selected={showOnlyMakeable}
              tooltip="Показать только доступные рецепты"
              onClick={() => setShowOnlyMakeable(!showOnlyMakeable)}
            />
          </Stack.Item>
          <Stack.Item>
            <Tooltip content="Количество партий для выдачи. Увеличьте, чтобы выдать ингредиенты сразу на несколько порций рецепта.">
              <Stack align="center">
                <Stack.Item>
                  <Box inline color="label" mr={0.5}>
                    <Icon name="layer-group" mr={0.5} />
                    Партий:
                  </Box>
                </Stack.Item>
                <Stack.Item>
                  <NumberInput
                    width="55px"
                    value={multiplier}
                    minValue={1}
                    maxValue={300}
                    step={1}
                    onChange={(e, value) => setMultiplier(value)}
                  />
                </Stack.Item>
                <Stack.Item>
                  <Icon name="times" color="label" />
                </Stack.Item>
              </Stack>
            </Tooltip>
          </Stack.Item>
        </Stack>
      }>
      {filteredRecipes.length === 0 ? (
        <NoticeBox>Рецепты не найдены</NoticeBox>
      ) : (
        <>
          {favoriteRecipesList.length > 0 && !searchQuery && (
            <Box mb={1}>
              <Box color="label" mb={0.5}>
                <Icon name="star" color="yellow" mr={0.5} />
                Избранное ({favoriteRecipesList.length}):
              </Box>
              {favoriteRecipesList.map(renderRecipeRow)}
              <Divider />
            </Box>
          )}

          {searchQuery ? (
            // Flat list for search results - sorted alphabetically, capped for performance
            (() => {
              const sorted = [...filteredRecipes].sort((a, b) => a[0].localeCompare(b[0]));
              const showAll = expandedPages['__search'];
              const visible = showAll ? sorted : sorted.slice(0, MAX_SEARCH_RESULTS);
              const remaining = sorted.length - MAX_SEARCH_RESULTS;
              return (
                <>
                  {sorted.length > MAX_SEARCH_RESULTS && (
                    <Box color="label" fontSize="10px" mb={0.5}>
                      Найдено: {sorted.length}
                    </Box>
                  )}
                  {visible.map(renderRecipeRow)}
                  {!showAll && remaining > 0 && (
                    <Box textAlign="center" py={0.5}>
                      <Button
                        icon="chevron-down"
                        content={`Показать ещё ${remaining}...`}
                        color="transparent"
                        onClick={() => setExpandedPages({ ...expandedPages, '__search': true })}
                      />
                    </Box>
                  )}
                </>
              );
            })()
          ) : (
            // Categories with Collapsible for non-search mode
            sortedCats.map(cat => {
              const config = categoryConfig[cat] || categoryConfig.other;
              const catRecipes = byCategory[cat];
              const isExpanded = isCatExpanded(cat);
              const showAll = expandedPages[cat];
              const visibleRecipes = showAll ? catRecipes : catRecipes.slice(0, ITEMS_PER_CATEGORY);
              const hasMore = !showAll && catRecipes.length > ITEMS_PER_CATEGORY;
              return (
                <Collapsible
                  key={cat}
                  title={
                    <span>
                      <Icon name={config.icon} mr={0.5} />
                      {config.title} ({catRecipes.length})
                    </span>
                  }
                  open={isExpanded}>
                  {visibleRecipes.map(renderRecipeRow)}
                  {hasMore && (
                    <Box textAlign="center" py={0.5}>
                      <Button
                        icon="chevron-down"
                        content={`Показать ещё ${catRecipes.length - ITEMS_PER_CATEGORY}...`}
                        color="transparent"
                        onClick={() => setExpandedPages({ ...expandedPages, [cat]: true })}
                      />
                    </Box>
                  )}
                </Collapsible>
              );
            })
          )}
        </>
      )}
    </Section>
  );
};

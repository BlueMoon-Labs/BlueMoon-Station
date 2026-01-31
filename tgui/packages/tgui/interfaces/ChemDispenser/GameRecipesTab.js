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
} from './utils';

export const GameRecipesTab = (props, context) => {
  const { act } = useBackend(context);
  const { gameRecipes, searchQuery, isBeakerLoaded, beakerContents = [], beakerCurrentVolume, beakerMaxVolume, manipulatorTier = 1, isEmagged = false } = props;

  const [multiplier, setMultiplier] = useLocalState(context, 'recipe_multiplier', 1);
  const [expandedCats, setExpandedCats] = useLocalState(context, 'recipe_cats', {
    medicine: true, consumables: false, toxins: false, drugs: false, other: false,
  });
  const [recipeFavorites, setRecipeFavorites] = useLocalState(context, 'recipe_favorites', []);
  const [showOnlyMakeable, setShowOnlyMakeable] = useLocalState(context, 'recipe_filter_makeable', false);

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

  const recipesArray = Object.entries(gameRecipes);
  const searchFilter = createSearch(searchQuery, ([name]) => name);
  let filteredRecipes = searchQuery
    ? recipesArray.filter(searchFilter)
    : recipesArray;

  if (showOnlyMakeable) {
    filteredRecipes = filteredRecipes.filter(([, recipe]) =>
      recipe.is_extract_recipe || (((recipe.tier || 1) >= 6 ? isEmagged : manipulatorTier >= (recipe.tier || 1)) && canMakeRecipe(recipe)));
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

  const sortedCats = Object.keys(byCategory).sort((a, b) => {
    const orderA = CATEGORY_CONFIG[a]?.order || 99;
    const orderB = CATEGORY_CONFIG[b]?.order || 99;
    return orderA - orderB;
  });

  const toggleCat = (cat) => {
    setExpandedCats({ ...expandedCats, [cat]: !expandedCats[cat] });
  };

  const renderExtractRecipeRow = ([name, recipe]) => {
    const isRecipeFavorite = recipeFavorites.includes(name);
    return (
      <Box key={name} className="candystripe" p={0.5} mb={0.5}
        style={{ borderBottom: '1px solid rgba(255,255,255,0.07)' }}>
        <Stack align="center">
          <Stack.Item grow basis={0}>
            <Box bold>
              {recipe.desc ? (
                <Tooltip content={recipe.desc} position="right">
                  <span
                    style={{ cursor: 'help' }}
                    onClick={(e) => {
                      if (e.shiftKey) {
                        e.preventDefault();
                        toggleRecipeFavorite(name);
                      }
                    }}>
                    {isRecipeFavorite && (
                      <Icon name="star" color="yellow" mr={0.5} />
                    )}
                    {name}
                    <Icon
                      name="info-circle"
                      ml={0.5}
                      color="label"
                      size={0.8}
                    />
                  </span>
                </Tooltip>
              ) : (
                <span
                  style={{ cursor: 'pointer' }}
                  onClick={(e) => {
                    if (e.shiftKey) {
                      e.preventDefault();
                      toggleRecipeFavorite(name);
                    }
                  }}>
                  {isRecipeFavorite && (
                    <Icon name="star" color="yellow" mr={0.5} />
                  )}
                  {name}
                </span>
              )}
            </Box>
          </Stack.Item>
          <Stack.Item shrink={0} ml={1}>
            <Box inline color="good" bold>
              &rarr; {recipe.result_amount || 1}u
            </Box>
          </Stack.Item>
        </Stack>
        <Box fontSize="11px" mt={0.3}>
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

  const renderRecipeRow = ([name, recipe]) => {
    if (recipe.is_extract_recipe) {
      return renderExtractRecipeRow([name, recipe]);
    }

    const baseIngredients = recipe.base_ingredients || {};
    const isFermiChem = !!recipe.is_fermichem;
    const isRecipeFavorite = recipeFavorites.includes(name);
    const requiredTier = recipe.tier || 1;
    const isEmagTier = requiredTier >= 6;
    const isUnlocked = isEmagTier ? isEmagged : manipulatorTier >= requiredTier;

    // Check if has sub-recipes (base differs from required)
    const requiredKeys = Object.keys(recipe.required || {});
    const baseKeys = Object.keys(baseIngredients);
    const hasSubRecipes = baseKeys.length !== requiredKeys.length ||
      baseKeys.some(k => !requiredKeys.includes(k));

    const wasteInfo = calculateWasteInfo(recipe, multiplier);
    const canMake = canMakeRecipe(recipe);
    const totalInputVol = calculateTotalInputVolume(baseIngredients, multiplier);

    const freeSpace = Math.max(0, (beakerMaxVolume || 0) - (beakerCurrentVolume || 0));
    const willOverflow = isBeakerLoaded && totalInputVol > freeSpace;

    return (
      <Box key={name} className="candystripe" p={0.5} mb={0.5}
        opacity={isUnlocked ? 1 : 0.5}
        style={{ borderBottom: '1px solid rgba(255,255,255,0.07)' }}>
        <Stack align="center">
          <Stack.Item grow basis={0}>
            <Box bold>
              {recipe.desc ? (
                <Tooltip content={recipe.desc} position="right">
                  <span
                    style={{ cursor: 'help' }}
                    onClick={(e) => {
                      if (e.shiftKey) {
                        e.preventDefault();
                        toggleRecipeFavorite(name);
                      }
                    }}>
                    {isRecipeFavorite && <Icon name="star" color="yellow" mr={0.5} />}
                    {name}
                    <Icon name="info-circle" ml={0.5} color="label" size={0.8} />
                  </span>
                </Tooltip>
              ) : (
                <span
                  style={{ cursor: 'pointer' }}
                  onClick={(e) => {
                    if (e.shiftKey) {
                      e.preventDefault();
                      toggleRecipeFavorite(name);
                    }
                  }}>
                  {isRecipeFavorite && <Icon name="star" color="yellow" mr={0.5} />}
                  {name}
                </span>
              )}
              {isFermiChem && <FermiChemBadge />}
              {requiredTier > 1 && (
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
              {!isFermiChem && recipe.temp > 0 && (
                <Box as="span" color={recipe.is_cold ? "blue" : "orange"} ml={1} fontSize="11px">
                  ({recipe.is_cold ? '\u2264' : '\u2265'}{recipe.temp}K)
                </Box>
              )}
              {recipe.catalysts && Object.keys(recipe.catalysts).length > 0 && (
                <Box as="span" color="yellow" ml={1} fontSize="11px">
                  (кат: {Object.entries(recipe.catalysts).map(([r, amt]) =>
                    `${r} ${amt}u`
                  ).join(', ')})
                </Box>
              )}
            </Box>
          </Stack.Item>
          <Stack.Item shrink={0} ml={1}>
            <Stack align="center" inline style={{ whiteSpace: 'nowrap' }}>
              <Stack.Item>
                <Box inline color="good" bold>
                  &rarr; {(recipe.result_amount || 1) * multiplier}u
                </Box>
                {wasteInfo.length > 0 && (
                  <Tooltip content={
                    <Box>
                      <Box bold mb={0.5}>Остаток:</Box>
                      {wasteInfo.map(w => (
                        <Box key={w.name}>{w.name}: {w.amount}u</Box>
                      ))}
                      {(() => {
                        const clean = [];
                        for (let n = 1; n <= 100 && clean.length < 4; n++) {
                          if (calculateWasteInfo(recipe, n).length === 0) {
                            clean.push(n);
                          }
                        }
                        return clean.length > 0 && (
                          <Box mt={0.5} color="label">
                            Чистые партии: {clean.join(', ')}x
                          </Box>
                        );
                      })()}
                    </Box>
                  }>
                    <Box as="span" color="average" ml={0.5}>
                      (+{wasteInfo.reduce((sum, w) => sum + w.amount, 0)}u)
                    </Box>
                  </Tooltip>
                )}
              </Stack.Item>
              <Stack.Item ml={1}>
                <Box inline color="label" fontSize="10px">
                  вход: {totalInputVol}u
                </Box>
              </Stack.Item>
              <Stack.Item ml={1}>
                <Button
                  compact
                  icon={isUnlocked ? "flask" : "lock"}
                  content={multiplier > 1 ? `x${multiplier}` : "Выдать"}
                  color={!isUnlocked ? "bad" : (canMake ? (willOverflow ? "average" : "green") : "bad")}
                  disabled={!isBeakerLoaded || !canMake || !isUnlocked}
                  tooltip={!isUnlocked
                    ? (isEmagTier ? 'Заблокировано! Требуется EMAG' : `Заблокировано! Требуется манипулятор T${requiredTier}+`)
                    : !canMake
                      ? "Недостаточно ингредиентов (проверьте ёмкость)"
                      : willOverflow
                        ? `Недостаточно места! Нужно ${totalInputVol}u, свободно ${toFixed(freeSpace)}u`
                        : "Выдать все базовые ингредиенты"}
                  onClick={() => act('dispense_recipe_game', { recipe: name, multiplier })}
                />
                {wasteInfo.length > 0 && (() => {
                  let nextClean = 0;
                  for (let n = multiplier + 1; n <= 100; n++) {
                    if (calculateWasteInfo(recipe, n).length === 0) {
                      nextClean = n;
                      break;
                    }
                  }
                  return nextClean > 0 && (
                    <Button
                      compact
                      ml={0.5}
                      icon="sync"
                      tooltip={`Округлить до ${nextClean}x (без остатка)`}
                      onClick={() => setMultiplier(nextClean)}
                    />
                  );
                })()}
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>

        {isFermiChem && <FermiChemDetails recipe={recipe} />}

        <Box fontSize="11px" mt={0.3}>
          <Icon name="flask" mr={0.5} color="label" />
          {Object.entries(recipe.required || {}).map(([r, amount], idx) => {
            const actualAmount = amount * multiplier;
            const subRecipes = recipe.sub_recipes || {};
            const isIntermediate = !!subRecipes[r];
            const baseData = baseIngredients[r];
            const canDispense = baseData && baseData.can_dispense;
            const beakerAmount = beakerByName[r] || 0;
            // Color: green=dispensable, cyan=intermediate, blue=in beaker, red=unavailable
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
            recipe={recipe}
            name={name}
            multiplier={multiplier}
            isBeakerLoaded={isBeakerLoaded}
            beakerByName={beakerByName}
            isUnlocked={isUnlocked}
          />
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
                    maxValue={100}
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

          {sortedCats.map(cat => {
            const config = CATEGORY_CONFIG[cat] || CATEGORY_CONFIG.other;
            const catRecipes = byCategory[cat];
            return (
              <Collapsible
                key={cat}
                title={
                  <span>
                    <Icon name={config.icon} mr={0.5} />
                    {config.title} ({catRecipes.length})
                  </span>
                }
                open={expandedCats[cat]}
                onToggle={() => toggleCat(cat)}>
                {catRecipes.map(renderRecipeRow)}
              </Collapsible>
            );
          })}
        </>
      )}
    </Section>
  );
};

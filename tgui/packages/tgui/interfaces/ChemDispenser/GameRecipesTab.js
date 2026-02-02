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

// Russian plural forms helper
const russianPlural = (n, one, few, many) => {
  const abs = Math.abs(n) % 100;
  const lastDigit = abs % 10;
  if (abs > 10 && abs < 20) return many;
  if (lastDigit > 1 && lastDigit < 5) return few;
  if (lastDigit === 1) return one;
  return many;
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

  const renderBadges = (variantRecipe) => {
    const isFermiChem = !!variantRecipe.is_fermichem;
    const requiredTier = variantRecipe.tier || 1;
    const isEmagTier = requiredTier >= 6;
    const isUnlocked = isEmagTier ? isEmagged : manipulatorTier >= requiredTier;
    return (
      <>
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

  const renderDispenseControls = (variantRecipe, name, altIndex) => {
    const baseIngredients = variantRecipe.base_ingredients || {};
    const requiredTier = variantRecipe.tier || 1;
    const isEmagTier = requiredTier >= 6;
    const isUnlocked = isEmagTier ? isEmagged : manipulatorTier >= requiredTier;
    const wasteInfo = calculateWasteInfo(variantRecipe, multiplier);
    const canMake = canMakeRecipe(variantRecipe);
    const totalInputVol = calculateTotalInputVolume(baseIngredients, multiplier);
    const freeSpace = Math.max(0, (beakerMaxVolume || 0) - (beakerCurrentVolume || 0));
    const willOverflow = isBeakerLoaded && totalInputVol > freeSpace;

    const dispenseParams = { recipe: name, multiplier };
    if (altIndex > 0) {
      dispenseParams.alt_index = altIndex;
    }

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
              {(() => {
                const clean = [];
                for (let n = 1; n <= 100 && clean.length < 4; n++) {
                  if (calculateWasteInfo(variantRecipe, n).length === 0) {
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
            <Box as="span" color="average" ml={0.3}>
              (+{wasteInfo.reduce((sum, w) => sum + w.amount, 0)}u)
            </Box>
          </Tooltip>
        )}
        <Box as="span" color="label" fontSize="10px" ml={0.5}>
          ({totalInputVol}u вх.)
        </Box>
        <Button
          compact
          ml={0.5}
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
          onClick={() => act('dispense_recipe_game', dispenseParams)}
        />
        {wasteInfo.length > 0 && (() => {
          let nextClean = 0;
          for (let n = multiplier + 1; n <= 100; n++) {
            if (calculateWasteInfo(variantRecipe, n).length === 0) {
              nextClean = n;
              break;
            }
          }
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
    const isEmagTier = requiredTier >= 6;
    const isUnlocked = isEmagTier ? isEmagged : manipulatorTier >= requiredTier;

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

    const singleTier = recipe.tier || 1;
    const singleEmagTier = singleTier >= 6;
    const singleUnlocked = hasAlts ? true : (singleEmagTier ? isEmagged : manipulatorTier >= singleTier);

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
                <Box as="span" ml={0.5} color="label" fontSize="10px">
                  ({altRecipes.length + 1} {russianPlural(altRecipes.length + 1, 'рецепт', 'рецепта', 'рецептов')})
                </Box>
              </RecipeName>
            </Box>
            {[recipe, ...altRecipes].map((variantRecipe, idx) => {
              const vTier = variantRecipe.tier || 1;
              const vEmagTier = vTier >= 6;
              const vUnlocked = vEmagTier ? isEmagged : manipulatorTier >= vTier;
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
                        {renderBadges(variantRecipe)}
                      </Box>
                    </Stack.Item>
                    <Stack.Item grow basis={0} />
                    <Stack.Item shrink={0} ml={1}>
                      {renderDispenseControls(variantRecipe, name, altIndex)}
                    </Stack.Item>
                  </Stack>
                  {renderRecipeBody(variantRecipe, name, altIndex)}
                </Box>
              );
            })}
          </>
        ) : (
          <>
            <Stack align="center">
              <Stack.Item grow basis={0}>
                <RecipeName
                  name={name}
                  desc={recipe.desc}
                  isFavorite={isRecipeFavorite}
                  onToggleFavorite={toggleRecipeFavorite}>
                  {renderBadges(recipe)}
                </RecipeName>
              </Stack.Item>
              <Stack.Item shrink={0} ml={1}>
                {renderDispenseControls(recipe, name, 0)}
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

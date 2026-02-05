import { useBackend } from '../../backend';
import {
  Box,
  Button,
  Divider,
  Icon,
  Tooltip,
} from '../../components';
import { DISPENSER_TYPE_BOOZE, DISPENSER_TYPE_SODA } from './utils';

export const FermiChemBadge = () => (
  <Tooltip content="FermiChem - сложная реакция с особыми условиями">
    <Box
      as="span"
      ml={0.5}
      px={0.5}
      backgroundColor="purple"
      style={{ borderRadius: '3px', fontSize: '10px' }}>
      <Icon name="flask-vial" mr={0.3} />
      FC
    </Box>
  </Tooltip>
);

export const FermiChemDetails = (props) => {
  const { recipe } = props;

  const phMin = Math.max(0, recipe.optimal_ph_min - recipe.react_ph_lim);
  const phMax = Math.min(14, recipe.optimal_ph_max + recipe.react_ph_lim);

  const tempRange = recipe.optimal_temp_max - recipe.optimal_temp_min;
  const phRange = recipe.optimal_ph_max - recipe.optimal_ph_min;

  const isTempNarrow = tempRange <= 50;
  const isPhNarrow = phRange <= 1;
  const hasPurityRisk = recipe.purity_min > 0.15;
  const hasSpecialExplosion = !!recipe.fermi_explode;

  const getThermicInfo = (constant) => {
    if (constant <= -10) return { text: 'Сильно охлаждает', color: 'blue', icon: 'snowflake' };
    if (constant < -1) return { text: 'Охлаждает', color: 'teal', icon: 'temperature-low' };
    if (constant <= 1) return { text: 'Нейтрально', color: 'label', icon: 'minus' };
    if (constant < 10) return { text: 'Нагревает', color: 'orange', icon: 'temperature-high' };
    return { text: 'Сильно нагревает', color: 'red', icon: 'fire' };
  };

  const getPhDriftInfo = (release) => {
    if (release <= -0.05) return { text: 'Ощелачивает', color: 'blue', icon: 'arrow-up' };
    if (release >= 0.05) return { text: 'Окисляет', color: 'orange', icon: 'arrow-down' };
    return { text: 'pH стабильно', color: 'label', icon: 'minus' };
  };

  const thermic = getThermicInfo(recipe.thermic_constant);
  const phDrift = getPhDriftInfo(recipe.h_ion_release);

  return (
    <Box
      fontSize="10px"
      mt={0.3}
      py={0.2}
      style={{ borderLeft: '2px solid #8844aa', paddingLeft: '5px' }}>
      <Box>
        <Icon name="thermometer-half" color="orange" mr={0.3} />
        <Box as="span" color={isTempNarrow ? 'bad' : 'good'} bold={isTempNarrow}>
          {recipe.optimal_temp_min}-{recipe.optimal_temp_max}K
        </Box>
        {isTempNarrow && (
          <Icon name="exclamation-triangle" color="yellow" ml={0.3} />
        )}
        <Box as="span" color="label" mx={0.3}>&middot;</Box>
        <Icon name="bomb" color="red" mr={0.3} />
        <Box as="span" color="bad">{recipe.explode_temp}K</Box>
        <Box as="span" color="label" mx={0.3}>&middot;</Box>
        <Icon name="tint" color="teal" mr={0.3} />
        <Box as="span" color={isPhNarrow ? 'bad' : 'good'} bold={isPhNarrow}>
          {recipe.optimal_ph_min.toFixed(1)}-{recipe.optimal_ph_max.toFixed(1)}
        </Box>
        {isPhNarrow && (
          <Icon name="exclamation-triangle" color="yellow" ml={0.3} />
        )}
        <Tooltip content={`Эффективные границы pH: ${phMin.toFixed(1)}-${phMax.toFixed(1)}`}>
          <Icon name="info-circle" color="label" ml={0.3} size={0.8} />
        </Tooltip>
        <Box as="span" color="label" mx={0.3}>&middot;</Box>
        <Icon name={thermic.icon} color={thermic.color} mr={0.3} />
        <Box as="span" color={thermic.color}>{thermic.text}</Box>
        <Box as="span" color="label" mx={0.3}>&middot;</Box>
        <Icon name={phDrift.icon} color={phDrift.color} mr={0.3} />
        <Box as="span" color={phDrift.color}>{phDrift.text}</Box>
        {(hasPurityRisk || hasSpecialExplosion) && (
          <>
            <Box as="span" color="label" mx={0.3}>&middot;</Box>
            {hasPurityRisk && (
              <Box as="span" color="yellow">
                <Icon name="exclamation-triangle" mr={0.3} />
                Чистота &ge;{(recipe.purity_min * 100).toFixed(0)}%
              </Box>
            )}
            {hasSpecialExplosion && (
              <Box as="span" color="red" bold ml={hasPurityRisk ? 0.3 : 0}>
                <Icon name="radiation" mr={0.3} />
                Взрыв!
              </Box>
            )}
          </>
        )}
      </Box>
    </Box>
  );
};

export const SubRecipeDispenseButton = (props, context) => {
  const { act } = useBackend(context);
  const {
    recipeName,
    reagentName,
    subRecipe,
    multiplier,
    isBeakerLoaded,
    beakerByName,
    isUnlocked = true,
    altIndex = 0,
    dispenserType = 0,
    isDrinkDispenser = false,
  } = props;

  const baseIngredients = subRecipe.base_ingredients || {};
  const temp = subRecipe.temp || 0;
  const isCold = subRecipe.is_cold;
  const resultAmount = subRecipe.result_amount || 1;

  const canMake = Object.entries(baseIngredients).every(([ingredientName, data]) => {
    if (data.can_dispense) return true;
    const needed = data.amount * multiplier;
    return (beakerByName[ingredientName] || 0) >= needed;
  });

  const neededAmount = multiplier;
  const reactionsNeeded = Math.ceil(neededAmount / resultAmount);
  const outputAmount = reactionsNeeded * resultAmount;

  // Determine if this sub-recipe needs ingredients from another dispenser
  const needsSoda = isDrinkDispenser && dispenserType === DISPENSER_TYPE_BOOZE
    && Object.values(baseIngredients).some(d =>
      d.source_dispenser && (d.source_dispenser & DISPENSER_TYPE_SODA)
      && !(d.source_dispenser & DISPENSER_TYPE_BOOZE));
  const needsBooze = isDrinkDispenser && dispenserType === DISPENSER_TYPE_SODA
    && Object.values(baseIngredients).some(d =>
      d.source_dispenser && (d.source_dispenser & DISPENSER_TYPE_BOOZE)
      && !(d.source_dispenser & DISPENSER_TYPE_SODA));

  const buttonColor = temp > 0 ? (isCold ? 'blue' : 'orange') : 'default';

  return (
    <Button
      compact
      icon={isUnlocked ? "vial" : "lock"}
      color={!isUnlocked ? 'bad' : (canMake ? buttonColor : 'bad')}
      disabled={!isBeakerLoaded || !canMake || !isUnlocked}
      tooltip={
        <Box>
          <Box bold mb={0.5}>{reagentName}</Box>
          {temp > 0 && (
            <Box color={isCold ? 'blue' : 'orange'} mb={0.5}>
              <Icon name="thermometer-half" mr={0.5} />
              {isCold ? '\u2264' : '\u2265'}{temp}K
            </Box>
          )}
          <Divider />
          <Box color="label" mb={0.3}>Выдаст:</Box>
          {Object.entries(baseIngredients).map(([ingredientName, data]) => {
            const amount = data.amount * reactionsNeeded;
            const inBeaker = beakerByName[ingredientName] || 0;
            const hasEnough = data.can_dispense || inBeaker >= amount;
            return (
              <Box key={ingredientName} color={hasEnough ? 'good' : 'bad'}>
                {ingredientName}: {amount}u
                {!data.can_dispense && (
                  <span style={{ color: '#888', fontSize: '10px' }}> (в ёмкости: {inBeaker}u)</span>
                )}
              </Box>
            );
          })}
          <Divider />
          <Box color="good">&rarr; {outputAmount}u {reagentName}</Box>
        </Box>
      }
      onClick={() => act('dispense_sub_recipe', {
        recipe: recipeName,
        sub_reagent: reagentName,
        multiplier: multiplier,
        ...(altIndex > 0 ? { alt_index: altIndex } : {}),
      })}>
      {reagentName}
      {temp > 0 && (
        <span style={{ fontSize: '9px', marginLeft: '3px', opacity: 0.8 }}>
          {isCold ? '\u2264' : '\u2265'}{temp}K
        </span>
      )}
      {(needsSoda || needsBooze) && (
        <span style={{ fontSize: '9px', marginLeft: '3px' }}>
          {needsSoda && <Icon name="mug-hot" color="blue" size={0.7} />}
          {needsBooze && <Icon name="wine-glass" color="purple" size={0.7} />}
        </span>
      )}
    </Button>
  );
};

export const hasFinalStep = (recipe) => {
  const subRecipes = recipe.sub_recipes || {};
  const baseIngredients = recipe.base_ingredients || {};
  return Object.keys(recipe.required || {}).some((name) => {
    if (!subRecipes[name]) return true;
    const baseData = baseIngredients[name];
    return baseData && baseData.can_dispense;
  });
};

export const FinalStepButton = (props, context) => {
  const { act } = useBackend(context);
  const {
    recipeName,
    recipe,
    multiplier,
    isBeakerLoaded,
    beakerByName,
    isUnlocked = true,
    altIndex = 0,
  } = props;

  // TRUE intermediate = in sub_recipes AND not directly dispensable
  const subRecipes = recipe.sub_recipes || {};
  const baseIngredients = recipe.base_ingredients || {};
  const directIngredients = Object.entries(recipe.required || {})
    .filter(([name]) => {
      if (!subRecipes[name]) return true;
      const baseData = baseIngredients[name];
      return baseData && baseData.can_dispense;
    });

  const canMake = directIngredients.every(([name]) => {
    const data = baseIngredients[name];
    if (!data) return true;
    if (data.can_dispense) return true;
    const needed = data.amount * multiplier;
    return (beakerByName[name] || 0) >= needed;
  });

  if (directIngredients.length === 0) {
    return null;
  }

  return (
    <Button
      compact
      icon={isUnlocked ? "check" : "lock"}
      color={!isUnlocked ? 'bad' : (canMake ? 'good' : 'bad')}
      disabled={!isBeakerLoaded || !canMake || !isUnlocked}
      tooltip={
        <Box>
          <Box bold mb={0.5}>Финальный шаг</Box>
          <Box color="label" mb={0.3}>Добавит прямые ингредиенты:</Box>
          {directIngredients.map(([name, amount]) => (
            <Box key={name} color="good">
              {name}: {amount * multiplier}u
            </Box>
          ))}
        </Box>
      }
      onClick={() => act('dispense_final_step', {
        recipe: recipeName,
        multiplier: multiplier,
        ...(altIndex > 0 ? { alt_index: altIndex } : {}),
      })}>
      +Финал
    </Button>
  );
};

export const SubRecipesChain = (props) => {
  const { recipe, name, multiplier, isBeakerLoaded, beakerByName, isUnlocked = true, altIndex = 0, dispenserType = 0, isDrinkDispenser = false } = props;
  const baseIngredients = recipe.base_ingredients || {};

  // Only show intermediates that must be synthesized (not directly dispensable)
  const baseIngredientNames = Object.keys(baseIngredients);
  const intermediates = Object.entries(recipe.sub_recipes || {})
    .filter(([reagentName, data]) => {
      return data && !baseIngredientNames.includes(reagentName);
    });

  if (intermediates.length === 0) {
    return null;
  }

  const maxTemp = Math.max(
    ...intermediates.map(([, data]) => data.temp || 0),
    recipe.temp || 0
  );
  const requiresHeating = maxTemp > 0 && !recipe.is_cold;

  return (
    <>
      <Box fontSize="11px" mt={0.5}>
        <Icon name="flask-vial" mr={0.5} color="cyan" />
        <span style={{ color: '#aaa' }}>Этапы: </span>
        {intermediates.map(([reagentName, data], idx) => (
          <span key={reagentName}>
            {idx > 0 && (
              <Icon name="arrow-right" mx={0.5} color="label" />
            )}
            <SubRecipeDispenseButton
              recipeName={name}
              reagentName={reagentName}
              subRecipe={data}
              multiplier={multiplier}
              isBeakerLoaded={isBeakerLoaded}
              beakerByName={beakerByName}
              isUnlocked={isUnlocked}
              altIndex={altIndex}
              dispenserType={dispenserType}
              isDrinkDispenser={isDrinkDispenser}
            />
          </span>
        ))}
        {hasFinalStep(recipe) && (
          <>
            <Icon name="arrow-right" mx={0.5} color="label" />
            <FinalStepButton
              recipeName={name}
              recipe={recipe}
              multiplier={multiplier}
              isBeakerLoaded={isBeakerLoaded}
              beakerByName={beakerByName}
              isUnlocked={isUnlocked}
              altIndex={altIndex}
            />
          </>
        )}
        <Icon name="arrow-right" mx={0.5} color="label" />
        <span style={{ color: '#00d9ff' }}>{name}</span>
      </Box>

      {requiresHeating && (
        <Box fontSize="10px" color="orange" mt={0.3}>
          <Icon name="fire" mr={0.5} />
          Требуется нагрев до {maxTemp}K
        </Box>
      )}
    </>
  );
};

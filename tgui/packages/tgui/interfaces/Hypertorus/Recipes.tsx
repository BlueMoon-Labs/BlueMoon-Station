import { useBackend } from '../../backend';
import { Box, Button, Icon, NoticeBox, Section, Stack, Tooltip } from '../../components';
import { getGasColor, getGasName } from '../../constants';
import { formatSiBaseTenUnit } from '../../format';
import { getMaxFusionTemperature } from './helpers';
import { HypertorusData, HypertorusFuel } from './types';

/**
 * Эффекты рецепта в порядке важности. base - значение, которое считается
 * нейтральным: у температурного множителя это не единица, потому что даже
 * "обычный" рецепт слегка снижает потолок.
 */
const EFFECTS: {
  param: keyof HypertorusFuel;
  label: string;
  /** Подпись в карточке: полное название туда не влезает. */
  short: string;
  icon: string;
  /** Во сколько раз значение должно отличаться, чтобы считаться сильным. */
  strong: number;
  base?: number;
  /** Хорошо ли, когда значение растёт. */
  higherIsBetter?: boolean;
  describe: (value: number, data: HypertorusData) => string;
}[] = [
  {
    param: 'recipe_heating_multiplier',
    label: 'Нагрев',
    short: 'Нагрев',
    icon: 'fire',
    strong: 3,
    describe: (value) => `Тепловыделение x${value}`,
  },
  {
    param: 'recipe_cooling_multiplier',
    label: 'Охлаждение',
    short: 'Охл.',
    icon: 'snowflake-o',
    strong: 3,
    describe: (value) => `Отвод тепла x${value}`,
  },
  {
    param: 'energy_loss_multiplier',
    label: 'Потери энергии',
    short: 'Потери',
    icon: 'sun-o',
    strong: 3,
    describe: (value) => `Энергия делится на ${value}`,
  },
  {
    param: 'fuel_consumption_multiplier',
    label: 'Расход топлива',
    short: 'Расход',
    icon: 'arrow-down',
    strong: 1.5,
    describe: (value) => `Топливо расходуется x${value}`,
  },
  {
    param: 'gas_production_multiplier',
    label: 'Выход газов',
    short: 'Выход',
    icon: 'arrow-up',
    strong: 1.5,
    higherIsBetter: true,
    describe: (value) => `Побочных газов x${value}`,
  },
  {
    param: 'temperature_multiplier',
    label: 'Потолок температуры',
    short: 'Потолок',
    icon: 'thermometer-full',
    strong: 1.15,
    base: 0.85,
    higherIsBetter: true,
    describe: (value, data) =>
      `Максимум ${formatSiBaseTenUnit(getMaxFusionTemperature(data) * value, 0, 'K')}`,
  },
];

const effectIcon = (value: number, base: number, strong: number) => {
  if (value === base) {
    return 'minus';
  }
  if (value > base) {
    return value > base * strong ? 'angle-double-up' : 'angle-up';
  }
  return value < base / strong ? 'angle-double-down' : 'angle-down';
};

const GasChips = ({ gases }: { gases?: string[] }) => {
  if (!gases?.length) {
    return <Box color="label">-</Box>;
  }
  return (
    <Box>
      {gases.map((gasId) => (
        <Box
          key={gasId}
          className="Hypertorus__gasChip"
          style={{ borderColor: getGasColor(gasId) }}
        >
          {getGasName(gasId)}
        </Box>
      ))}
    </Box>
  );
};

const RecipeCard = ({ recipe }: { recipe: HypertorusFuel }) => {
  const { act, data } = useBackend<HypertorusData>();
  const selected = recipe.id === data.selected;
  const locked = data.power_level > 0;

  return (
    <Box
      className={`Hypertorus__recipe${selected ? ' Hypertorus__recipe--active' : ''}`}
    >
      <Stack align="center" mb={1}>
        <Stack.Item grow>
          <Box className="Hypertorus__recipeName">
            {selected && <Icon name="check-circle" color="good" mr={1} />}
            {recipe.name}
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Tooltip
            content={
              locked
                ? 'Реактор разогнан: рецепт меняется только на остановленном.'
                : selected
                  ? 'Уже выбран.'
                  : 'Выбрать рецепт. Газ, оставшийся в камере синтеза, будет сброшен.'
            }
          >
            <Box inline>
              <Button
                disabled={locked || selected}
                icon={selected ? 'check' : 'play'}
                content={selected ? 'Активен' : 'Выбрать'}
                selected={selected}
                onClick={() => act('fuel', { mode: recipe.id })}
              />
            </Box>
          </Tooltip>
        </Stack.Item>
      </Stack>
      <Stack>
        <Stack.Item grow basis={0}>
          <Box className="Hypertorus__recipeLabel">Топливо</Box>
          <GasChips gases={recipe.requirements} />
        </Stack.Item>
        <Stack.Item grow basis={0}>
          <Box className="Hypertorus__recipeLabel">Побочные</Box>
          <GasChips gases={recipe.fusion_byproducts} />
        </Stack.Item>
        <Stack.Item grow basis={0}>
          <Box className="Hypertorus__recipeLabel">В модератор</Box>
          <GasChips gases={recipe.product_gases} />
        </Stack.Item>
      </Stack>
      <Box className="Hypertorus__recipeEffects">
        {EFFECTS.map((effect) => {
          const value = recipe[effect.param] as number;
          if (typeof value !== 'number') {
            return null;
          }
          const base = effect.base ?? 1;
          const icon = effectIcon(value, base, effect.strong);
          const neutral = icon === 'minus';
          const raising = value > base;
          const good = effect.higherIsBetter ? raising : !raising;
          return (
            <Tooltip
              key={effect.param}
              content={`${effect.label}: ${effect.describe(value, data)}`}
            >
              {/* Множитель печатаем числом: одними стрелками игрок не отличит
                  «чуть выше» от «вчетверо выше», не наводя мышь на каждую. */}
              <Box
                className="Hypertorus__effect"
                color={neutral ? 'label' : good ? 'good' : 'average'}
              >
                <Icon name={effect.icon} mr={0.3} />
                <Box inline className="Hypertorus__effectName">
                  {effect.short}
                </Box>
                <Icon name={icon} mx={0.2} />
                <Box inline className="Hypertorus__effectValue">
                  {`×${value}`}
                </Box>
              </Box>
            </Tooltip>
          );
        })}
      </Box>
    </Box>
  );
};

/** Каталог рецептов: что во что превращается и чем это грозит. */
export const Recipes = () => {
  const { act, data } = useBackend<HypertorusData>();
  const recipes = (data.selectable_fuel ?? []).filter((recipe) => recipe.id);
  const locked = data.power_level > 0;

  return (
    <Section
      title="Рецепты синтеза"
      buttons={
        <Tooltip
          content={
            locked
              ? 'Реактор разогнан: рецепт меняется только на остановленном.'
              : 'Снять рецепт и остановить синтез.'
          }
        >
          <Box inline>
            {/* Пустая строка - это ветка "nothing" в ui_act(): рецепт снимается,
                камера сбрасывает газ. */}
            <Button
              disabled={locked || data.selected === null}
              icon="times"
              content="Снять рецепт"
              onClick={() => act('fuel', { mode: '' })}
            />
          </Box>
        </Tooltip>
      }
    >
      {locked && (
        <NoticeBox className="Hypertorus__alert">
          <Icon name="lock" mr={1} />
          Уровень мощности {data.power_level}: смена рецепта заблокирована, пока
          камера синтеза не остынет.
        </NoticeBox>
      )}
      <Box className="Hypertorus__recipeGrid">
        {recipes.map((recipe) => (
          <RecipeCard key={recipe.id} recipe={recipe} />
        ))}
      </Box>
    </Section>
  );
};

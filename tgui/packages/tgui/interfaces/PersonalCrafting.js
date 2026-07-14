import { useEffect, useRef, useState } from 'react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  Dimmer,
  Divider,
  Icon,
  Input,
  LabeledList,
  Section,
  Stack,
  Tabs,
} from '../components';
import { Window } from '../layouts';

const FOOD_CATEGORIES = new Set([
  'Еда', 'Хлеб', 'Бургеры', 'Торты', 'Пончики',
  'Из яиц', 'Заморозка', 'Мясо', 'Мексиканское',
  'Разная еда', 'Выпечка', 'Пироги и сладости', 'Пицца',
  'Салаты', 'Морепродукты', 'Сэндвичи', 'Супы', 'Спагетти',
  'Восточная еда', 'Напитки',
]);

const CATEGORY_ICONS = {
  'Can Make': 'hammer',
  Оружие: 'hand-fist',
  'Ближний бой': 'hand-fist',
  Дальнобойное: 'gun',
  Боеприпасы: 'box',
  'Части оружия': 'gear',
  Роботы: 'robot',
  Разное: 'shapes',
  Прочее: 'shapes',
  Инструменты: 'screwdriver-wrench',
  Мебель: 'chair',
  Племенное: 'campground',
  Одежда: 'shirt',
  Еда: 'utensils',
  Напитки: 'wine-bottle',
  Атмосфера: 'fan',
  'Газовые кристаллы': 'gem',
  'Восточная еда': 'drumstick-bite',
  Хлеб: 'bread-slice',
  Бургеры: 'burger',
  Торты: 'cake-candles',
  Пончики: 'cookie',
  'Из яиц': 'egg',
  Мясо: 'bacon',
  Мексиканское: 'pepper-hot',
  'Разная еда': 'shapes',
  Выпечка: 'cookie',
  'Пироги и сладости': 'chart-pie',
  Пицца: 'pizza-slice',
  Салаты: 'leaf',
  Морепродукты: 'fish',
  Сэндвичи: 'hotdog',
  Супы: 'mug-hot',
  Спагетти: 'wheat-awn',
  Заморозка: 'ice-cream',
  Структуры: 'cube',
  Плитка: 'border-all',
  Окна: 'person-through-window',
  Двери: 'door-open',
  Снаряжение: 'calculator',
  Контейнеры: 'briefcase',
  Развлечения: 'masks-theater',
  Садоводство: 'seedling',
  Декор: 'tree',
  Химия: 'microscope',
};

const PAGE_SIZE = 20;

function isCook(mode) {
  return mode === 1 || mode === true;
}

function getCategories(crafting_recipes, mode) {
  const cook = isCook(mode);
  const categories = [];
  for (const category of Object.keys(crafting_recipes)) {
    if (cook !== FOOD_CATEGORIES.has(category)) {
      continue;
    }
    const subcategories = crafting_recipes[category];
    if ('has_subcats' in subcategories) {
      for (const subcategory of Object.keys(subcategories)) {
        if (subcategory === 'has_subcats') {
          continue;
        }
        categories.push({
          id: category + '::' + subcategory,
          name: subcategory,
          category,
          subcategory,
        });
      }
    } else {
      categories.push({
        id: category + '::',
        name: category,
        category,
      });
    }
  }
  return categories;
}

function getRecipes(crafting_recipes, mode) {
  const cook = isCook(mode);
  const recipes = [];
  for (const category of Object.keys(crafting_recipes)) {
    if (cook !== FOOD_CATEGORIES.has(category)) {
      continue;
    }
    const subcategories = crafting_recipes[category];
    if ('has_subcats' in subcategories) {
      for (const subcategory of Object.keys(subcategories)) {
        if (subcategory === 'has_subcats') {
          continue;
        }
        const _recipes = subcategories[subcategory];
        for (const recipe of _recipes) {
          recipes.push({ ...recipe, tabId: category + '::' + subcategory });
        }
      }
    } else {
      const _recipes = crafting_recipes[category];
      for (const recipe of _recipes) {
        recipes.push({ ...recipe, tabId: category + '::' });
      }
    }
  }
  return recipes;
}

export function PersonalCrafting() {
  const { act, data } = useBackend();
  const {
    busy,
    mode,
    display_craftable_only,
    display_compact,
    crafting_recipes = {},
    craftability = {},
    max_crafts = {},
    craft_errors = {},
  } = data;

  const [searchQuery, setSearchQuery] = useState('');
  const [tab, setTab] = useState('');
  const [page, setPage] = useState(1);
  const searchTimer = useRef(null);

  const categories = getCategories(crafting_recipes, mode);
  const allRecipes = getRecipes(crafting_recipes, mode);
  const query = searchQuery.trim().toLowerCase();
  const isSearching = query.length > 0;

  useEffect(() => {
    if (categories.length > 0 && (!tab || tab === '')) {
      const firstCat = categories[0];
      setTab(firstCat.id);
      act('set_category', {
        category: firstCat.category,
        subcategory: firstCat.subcategory,
      });
    }
    act('search', { query: '' });
  }, []);

  useEffect(() => {
    if (categories.length > 0) {
      const firstCat = categories[0];
      setTab(firstCat.id);
      act('set_category', {
        category: firstCat.category,
        subcategory: firstCat.subcategory,
      });
    }
  }, [mode, categories.length]);

  useEffect(() => {
    return () => {
      if (searchTimer.current) {
        clearTimeout(searchTimer.current);
      }
    };
  }, []);

  const handleSearch = (value) => {
    setSearchQuery(value);
    setPage(1);
    if (searchTimer.current) {
      clearTimeout(searchTimer.current);
    }
    const trimmed = value.trim();
    searchTimer.current = setTimeout(() => {
      act('search', { query: trimmed });
    }, 200);
  };

  const clearSearch = () => {
    setSearchQuery('');
    setPage(1);
    if (searchTimer.current) {
      clearTimeout(searchTimer.current);
    }
    act('search', { query: '' });
  };

  const handleTabClick = (cat) => {
    setTab(cat.id);
    setPage(1);
    act('set_category', {
      category: cat.category,
      subcategory: cat.subcategory,
    });
  };

  let nameMatches = [];
  let ingredientMatches = [];
  let shownRecipes = [];

  if (isSearching) {
    nameMatches = allRecipes.filter(
      (r) => r.name?.toLowerCase().includes(query),
    );
    ingredientMatches = allRecipes.filter(
      (r) => r.req_text?.toLowerCase().includes(query),
    );
  } else {
    shownRecipes = allRecipes.filter((r) => r.tabId === tab);
  }

  return (
    <Window title="Крафтинг" width={700} height={800}>
      <Window.Content>
        {!!busy && (
          <Dimmer fontSize="32px">
            <Icon color="blue" name="cog" spin={1} />
            {' Изготовление...'}
          </Dimmer>
        )}
        <Stack fill>
          <Stack.Item width="180px">
            <Section fill scrollable>
              <Stack fill vertical>
                <Stack.Item>
                  <Stack>
                    <Stack.Item grow>
                      <Input
                        fluid
                        placeholder="Поиск рецептов..."
                        value={searchQuery}
                        onInput={(e, value) => handleSearch(value)}
                      />
                    </Stack.Item>
                    <Stack.Item>
                      <Button
                        icon="times"
                        disabled={!searchQuery}
                        color="transparent"
                        onClick={clearSearch}
                        tooltip="Очистить"
                      />
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
                <Stack.Item grow>
                  <Tabs vertical>
                    {categories.map((cat) => (
                      <Tabs.Tab
                        key={cat.id}
                        selected={cat.id === tab && !isSearching}
                        onClick={() => handleTabClick(cat)}
                      >
                        <Stack align="center">
                          <Stack.Item width="16px" textAlign="center">
                            <Icon
                              name={
                                CATEGORY_ICONS[cat.name]
                                || CATEGORY_ICONS[cat.category]
                                || 'circle'
                              }
                            />
                          </Stack.Item>
                          <Stack.Item grow ml={1}>
                            {cat.name}
                          </Stack.Item>
                        </Stack>
                      </Tabs.Tab>
                    ))}
                  </Tabs>
                </Stack.Item>
                <Stack.Item>
                  <Divider />
                  <Button.Checkbox
                    fluid
                    checked={display_craftable_only}
                    onClick={() => act('toggle_recipes')}
                  >
                    Могу сделать
                  </Button.Checkbox>
                  <Button.Checkbox
                    fluid
                    checked={display_compact}
                    onClick={() => act('toggle_compact')}
                  >
                    Компактно
                  </Button.Checkbox>
                  <Divider />
                  <Stack textAlign="center">
                    <Stack.Item grow>
                      <Button.Checkbox
                        fluid
                        lineHeight={2}
                        checked={!isCook(mode)}
                        icon="hammer"
                        style={{
                          border: '2px solid ' + (!isCook(mode) ? '#20b142' : '#333'),
                        }}
                        onClick={() => isCook(mode) && act('toggle_mode')}
                      >
                        Крафт
                      </Button.Checkbox>
                    </Stack.Item>
                    <Stack.Item grow>
                      <Button.Checkbox
                        fluid
                        lineHeight={2}
                        checked={isCook(mode)}
                        icon="utensils"
                        style={{
                          border: '2px solid ' + (isCook(mode) ? '#20b142' : '#333'),
                        }}
                        onClick={() => !isCook(mode) && act('toggle_mode')}
                      >
                        Готовка
                      </Button.Checkbox>
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
          <Stack.Item grow ml={0.5}>
            {isSearching ? (
              <Section fill scrollable>
                <SearchResults
                  nameMatches={nameMatches}
                  ingredientMatches={ingredientMatches}
                  craftability={craftability}
                  max_crafts={max_crafts}
                  craft_errors={craft_errors}
                  display_craftable_only={display_craftable_only}
                  display_compact={display_compact}
                />
              </Section>
            ) : (
              <Section fill scrollable>
                <RecipeList
                  recipes={shownRecipes}
                  craftability={craftability}
                  max_crafts={max_crafts}
                  craft_errors={craft_errors}
                  display_craftable_only={display_craftable_only}
                  display_compact={display_compact}
                  page={page}
                  onLoadMore={() => setPage(page + 1)}
                />
              </Section>
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
}

function SearchResults(props) {
  const {
    nameMatches,
    ingredientMatches,
    craftability,
    max_crafts,
    craft_errors,
    display_craftable_only,
    display_compact,
  } = props;

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Section title={'По названию (' + nameMatches.length + ')'}>
          <RecipeList
            recipes={nameMatches}
            craftability={craftability}
            max_crafts={max_crafts}
            craft_errors={craft_errors}
            display_craftable_only={display_craftable_only}
            display_compact={display_compact}
          />
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section
          title={'По ингредиентам (' + ingredientMatches.length + ')'}
        >
          <RecipeList
            recipes={ingredientMatches}
            craftability={craftability}
            max_crafts={max_crafts}
            craft_errors={craft_errors}
            display_craftable_only={display_craftable_only}
            display_compact={display_compact}
          />
        </Section>
      </Stack.Item>
    </Stack>
  );
}

function RecipeList(props) {
  const {
    recipes = [],
    craftability = {},
    max_crafts = {},
    craft_errors = {},
    display_craftable_only,
    display_compact,
    page,
    onLoadMore,
  } = props;
  const { act } = useBackend();

  let visible = recipes;
  if (display_craftable_only) {
    visible = visible.filter((r) => craftability[r.ref]);
  }

  const displayLimit = page ? page * PAGE_SIZE : visible.length;
  const paged = visible.slice(0, displayLimit);

  return (
    <Box>
      {paged.length === 0 && (
        <Box color="gray" textAlign="center" py={2}>
          Рецептов не найдено.
        </Box>
      )}
      {paged.map((recipe) =>
        display_compact ? (
          <CompactRecipe
            key={recipe.ref}
            recipe={recipe}
            canCraft={craftability[recipe.ref]}
            maxCrafts={max_crafts[recipe.ref] || 1}
            craftError={craft_errors[recipe.ref]}
          />
        ) : (
          <FullRecipe
            key={recipe.ref}
            recipe={recipe}
            canCraft={craftability[recipe.ref]}
            maxCrafts={max_crafts[recipe.ref] || 1}
            craftError={craft_errors[recipe.ref]}
          />
        ),
      )}
      {onLoadMore && visible.length > displayLimit && (
        <Section textAlign="center">
          <Button
            onClick={onLoadMore}
            icon="chevron-down"
            tooltip={
              'Показать ещё ' + Math.min(PAGE_SIZE, visible.length - displayLimit)
            }
          >
            Загрузить ещё (осталось {visible.length - displayLimit})
          </Button>
        </Section>
      )}
    </Box>
  );
}

function GroupTitle(props) {
  return (
    <Stack my={0.5}>
      <Stack.Item grow>
        <Divider />
      </Stack.Item>
      <Stack.Item color="gray">{props.title}</Stack.Item>
      <Stack.Item grow>
        <Divider />
      </Stack.Item>
    </Stack>
  );
}

function FullRecipe(props) {
  const { recipe, canCraft, maxCrafts = 1, craftError } = props;
  const { act } = useBackend();
  const [count, setCount] = useState(1);
  const safeMax = Math.max(1, Number(maxCrafts) || 1);
  const safeCount = Math.max(1, Math.min(count, safeMax));
  const hasMultiple = !!(canCraft && safeMax > 1);

  return (
    <Section>
      <Stack>
        {!!recipe.icon_data && (
          <Stack.Item>
            <Box mr={1}>
              <img
                src={"data:image/png;base64," + recipe.icon_data}
                style={{
                  width: '32px',
                  height: '32px',
                  imageRendering: 'pixelated',
                }}
              />
            </Box>
          </Stack.Item>
        )}
        <Stack.Item grow>
          <Stack>
            <Stack.Item grow>
              <Box bold mb={0.5}>
                {recipe.name}
              </Box>
              {!!recipe.desc && (
                <Box color="gray" mb={0.5}>
                  {recipe.desc}
                </Box>
              )}
              {recipe.reqs_detail?.length > 0 && (
                <>
                  <GroupTitle title="Материалы" />
                  {recipe.reqs_detail.map((req, i) => (
                    <Stack key={i} align="center" my={0.25}>
                      {!!req.icon_data && (
                        <Stack.Item mr={0.5}>
                          <img
                            src={"data:image/png;base64," + req.icon_data}
                            loading="lazy"
                            style={{
                              width: '24px',
                              height: '24px',
                              verticalAlign: 'middle',
                              imageRendering: 'pixelated',
                            }}
                          />
                        </Stack.Item>
                      )}
                      <Stack.Item>
                        {req.name}
                        {req.amount > 1
                          ? '\u00a0' + req.amount + 'x'
                          : ''}
                      </Stack.Item>
                    </Stack>
                  ))}
                </>
              )}
              {recipe.catalysts_detail?.length > 0 && (
                <>
                  <GroupTitle title="Катализаторы" />
                  {recipe.catalysts_detail.map((cat, i) => (
                    <Stack key={i} align="center" my={0.25}>
                      {!!cat.icon_data && (
                        <Stack.Item mr={0.5}>
                          <img
                            src={"data:image/png;base64," + cat.icon_data}
                            loading="lazy"
                            style={{
                              width: '24px',
                              height: '24px',
                              verticalAlign: 'middle',
                              imageRendering: 'pixelated',
                            }}
                          />
                        </Stack.Item>
                      )}
                      <Stack.Item>
                        {cat.name}
                        {cat.amount > 1
                          ? '\u00a0' + cat.amount + 'x'
                          : ''}
                      </Stack.Item>
                    </Stack>
                  ))}
                </>
              )}
              {recipe.tools_detail?.length > 0 && (
                <>
                  <GroupTitle title="Инструменты" />
                  {recipe.tools_detail.map((tool, i) => (
                    <Stack key={i} align="center" my={0.25}>
                      {!!tool.icon_data && (
                        <Stack.Item mr={0.5}>
                          <img
                            src={"data:image/png;base64," + tool.icon_data}
                            loading="lazy"
                            style={{
                              width: '24px',
                              height: '24px',
                              verticalAlign: 'middle',
                              imageRendering: 'pixelated',
                            }}
                          />
                        </Stack.Item>
                      )}
                      <Stack.Item>{tool.name}</Stack.Item>
                    </Stack>
                  ))}
                </>
              )}
            </Stack.Item>
            <Stack.Item pl={1}>
              <Stack vertical>
                <Stack.Item>
                  <Stack align="center">
                    {!!hasMultiple && (
                      <>
                        <Stack.Item>
                          <Button
                            icon="minus"
                            disabled={safeCount <= 1}
                            onClick={() => setCount(Math.max(1, count - 1))}
                            tooltip={'Меньше (мин. 1)'}
                            tooltipPosition="top"
                          />
                        </Stack.Item>
                        <Stack.Item>
                          <Box
                            style={{
                              minWidth: '24px',
                              textAlign: 'center',
                              fontWeight: 'bold',
                            }}
                          >
                            {safeCount}
                          </Box>
                        </Stack.Item>
                        <Stack.Item>
                          <Button
                            icon="plus"
                            disabled={safeCount >= safeMax}
                            onClick={() =>
                              setCount(Math.min(safeMax, count + 1))
                            }
                            tooltip={'Больше (макс. ' + safeMax + ')'}
                            tooltipPosition="top"
                          />
                        </Stack.Item>
                      </>
                    )}
                    <Stack.Item>
                      <Button
                        lineHeight={2.5}
                        align="center"
                        disabled={!canCraft}
                        icon="cog"
                        color={canCraft ? 'green' : 'default'}
                        tooltip={!canCraft && craftError ? craftError : undefined}
                        tooltipPosition="top"
                        onClick={() =>
                          hasMultiple
                            ? act('make_multiple', {
                                recipe: recipe.ref,
                                count: safeCount,
                              })
                            : act('make', { recipe: recipe.ref })
                        }
                      >
                        {hasMultiple ? 'Создать x' + safeCount : 'Создать'}
                      </Button>
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
                {!!recipe.complexity && (
                  <Stack.Item>
                    <Box color="gray" mt={0.5}>
                      Сложность: {recipe.complexity}
                    </Box>
                  </Stack.Item>
                )}
              </Stack>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

function CompactRecipe(props) {
  const { recipe, canCraft, maxCrafts = 1, craftError } = props;
  const { act } = useBackend();
  const [count, setCount] = useState(1);
  const safeMax = Math.max(1, Number(maxCrafts) || 1);
  const safeCount = Math.max(1, Math.min(count, safeMax));
  const hasMultiple = !!(canCraft && safeMax > 1);

  return (
    <LabeledList.Item
      className="candystripe"
      label={
        <Stack align="center" inline>
          {!!recipe.icon_data && (
            <Stack.Item mr={1}>
              <img
                src={"data:image/png;base64," + recipe.icon_data}
                style={{
                  width: '32px',
                  height: '32px',
                  verticalAlign: 'middle',
                  imageRendering: 'pixelated',
                }}
              />
            </Stack.Item>
          )}
          <Stack.Item>
            <Box
              color={canCraft ? 'good' : 'bad'}
              inline
            >
              {recipe.name}
            </Box>
          </Stack.Item>
        </Stack>
      }
      buttons={
        <Box>
          {!!hasMultiple && (
            <>
              <Button
                icon="minus"
                disabled={safeCount <= 1}
                onClick={() => setCount(Math.max(1, count - 1))}
                tooltipPosition="top"
              />
              <Box
                inline
                mx={0.5}
                style={{
                  minWidth: '18px',
                  textAlign: 'center',
                  fontWeight: 'bold',
                }}
              >
                {safeCount}
              </Box>
              <Button
                icon="plus"
                disabled={safeCount >= safeMax}
                onClick={() => setCount(Math.min(safeMax, count + 1))}
                tooltipPosition="top"
              />
            </>
          )}
          <Button
            icon="cog"
            content={hasMultiple ? 'x' + safeCount : 'Создать'}
            disabled={!canCraft}
            color={canCraft ? 'green' : 'default'}
            tooltip={
              !canCraft && craftError
                ? craftError
                : recipe.tool_text
                  ? 'Инструменты: ' + recipe.tool_text
                  : undefined
            }
            tooltipPosition={!canCraft ? 'top' : 'left'}
            onClick={() =>
              hasMultiple
                ? act('make_multiple', {
                    recipe: recipe.ref,
                    count: safeCount,
                  })
                : act('make', { recipe: recipe.ref })
            }
          />
        </Box>
      }
    >
      <Box color="gray" inline>
        {recipe.req_text}
      </Box>
    </LabeledList.Item>
  );
}

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
import { AMOUNT_PRESETS, CATEGORY_CONFIG, DRINK_CATEGORY_CONFIG } from './utils';

export const ChemDispenser = (props, context) => {
  const { act, data } = useBackend(context);
  const recording = !!data.recordingRecipe;

  // Per-tab search states
  const [chemSearchQuery, setChemSearchQuery] = useLocalState(context, 'chem_search_chemicals', '');
  const [recipeSearchQuery, setRecipeSearchQuery] = useLocalState(context, 'chem_search_recipes', '');
  const [savedSearchQuery, setSavedSearchQuery] = useLocalState(context, 'chem_search_saved', '');

  const [activeTab, setActiveTab] = useLocalState(context, 'chem_tab', 'chemicals');
  const [favorites, setFavorites] = useLocalState(context, 'chem_favorites', []);
  const [recentChemicals, setRecentChemicals] = useLocalState(context, 'chem_recent', []);
  const classicView = data.classicView !== undefined ? data.classicView : true;
  const useReagentColor = data.useReagentColor !== undefined ? data.useReagentColor : true;
  const showIcons = data.showIcons !== undefined ? data.showIcons : true;
  const [expandedCategories, setExpandedCategories] = useLocalState(context, 'chem_expanded', {
    alcoholic_drinks: true, soft_drinks: true,
    elements: true, compounds: true, consumables: true,
    toxins: true, medicine: true, drugs: true, other: true,
    slime_extracts: true,
  });

  // Get current tab's search state
  const [searchQuery, setSearchQuery] =
    activeTab === 'gameRecipes' ? [recipeSearchQuery, setRecipeSearchQuery]
    : activeTab === 'savedRecipes' ? [savedSearchQuery, setSavedSearchQuery]
    : [chemSearchQuery, setChemSearchQuery];

  const {
    chemicals = [],
    storedContents = [],
    beakerTransferAmounts = [],
    beakerDoseAmounts = null,
    gameRecipes = {},
    isDrinkDispenser = false,
  } = data;

  // Hide pH display for drink dispensers (soda/booze) as it's irrelevant
  const showPH = !isDrinkDispenser;

  const savedRecipes = Object.keys(data.recipes || {}).map(name => ({
    name,
    contents: data.recipes[name],
  }));

  // Count only relevant recipes for drink dispensers
  const drinkCategories = ['alcoholic_drinks', 'soft_drinks'];
  const gameRecipesCount = isDrinkDispenser
    ? Object.values(gameRecipes).filter(r => drinkCategories.includes(r.category)).length
    : Object.keys(gameRecipes).length;

  const beakerContents = recording
    ? Object.keys(data.recordingRecipe || {}).map(id => ({
      id,
      name: toTitleCase(id.replace(/_/g, ' ')),
      volume: data.recordingRecipe[id],
    }))
    : data.beakerContents || [];

  const searchFilter = createSearch(searchQuery, chemical => chemical.title);
  const filteredChemicals = searchQuery
    ? chemicals.filter(searchFilter)
    : chemicals;

  const chemicalsByCategory = {};
  filteredChemicals.forEach(chemical => {
    const category = chemical.category || 'other';
    if (!chemicalsByCategory[category]) {
      chemicalsByCategory[category] = [];
    }
    chemicalsByCategory[category].push(chemical);
  });

  // Use drink-specific category order for drink dispensers
  const categoryConfig = isDrinkDispenser ? DRINK_CATEGORY_CONFIG : CATEGORY_CONFIG;
  const sortedCategories = Object.keys(chemicalsByCategory).sort((a, b) => {
    const orderA = categoryConfig[a]?.order || 99;
    const orderB = categoryConfig[b]?.order || 99;
    return orderA - orderB;
  });

  const toggleFavorite = (chemId) => {
    if (favorites.includes(chemId)) {
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

  const handleDispense = (chemId) => {
    act('dispense', { reagent: chemId });
    addToRecent(chemId);
  };

  const favoriteChemicals = chemicals.filter(c => favorites.includes(c.id));
  const recentChemicalsList = recentChemicals
    .map(id => chemicals.find(c => c.id === id))
    .filter(Boolean);

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
                    value={data.energy / data.maxEnergy}
                    ranges={{ good: [0.5, Infinity], average: [0.25, 0.5], bad: [-Infinity, 0.25] }}>
                    {toFixed(data.energy)} / {toFixed(data.maxEnergy)} u
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
                          onClick={() => act('toggle_icons')}
                        />
                      </Stack.Item>
                      <Stack.Item>
                        <Button
                          compact
                          icon={useReagentColor ? 'palette' : 'tint'}
                          tooltip={useReagentColor
                            ? 'Цвета реагентов (нажмите для pH)'
                            : 'pH цвета (нажмите для цвета реагента)'}
                          onClick={() => act('toggle_color_mode')}
                        />
                      </Stack.Item>
                      <Stack.Item>
                        <Button
                          compact
                          icon={classicView ? 'th' : 'list'}
                          tooltip={classicView
                            ? 'Категории' : 'Обычная таблица'}
                          onClick={() => act('toggle_view')}
                        />
                      </Stack.Item>
                    </>
                  )}
                </Stack>
              </Stack.Item>

              <Stack.Item>
                <AmountControls
                  amount={data.amount}
                  stepAmount={data.stepAmount}
                  isBeakerLoaded={data.isBeakerLoaded}
                  beakerMaxVolume={data.beakerMaxVolume}
                  beakerCurrentVolume={data.beakerCurrentVolume}
                  beakerDoseAmounts={beakerDoseAmounts}
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
                          [...filteredChemicals].sort((a, b) =>
                            a.title.localeCompare(b.title)
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
                                  isFavorite={favorites.includes(chemical.id)}
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
                                  isFavorite={favorites.includes(chemical.id)}
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
                                      isFavorite={favorites.includes(chemical.id)}
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

                {/* Keep GameRecipesTab mounted to preserve state and avoid re-renders */}
                <Box style={{ display: activeTab === 'gameRecipes' ? 'block' : 'none', height: '100%' }}>
                  <GameRecipesTab
                    gameRecipes={gameRecipes}
                    searchQuery={searchQuery}
                    isBeakerLoaded={data.isBeakerLoaded}
                    beakerContents={beakerContents}
                    beakerCurrentVolume={data.beakerCurrentVolume}
                    beakerMaxVolume={data.beakerMaxVolume}
                    manipulatorTier={data.manipulatorTier || 1}
                    isEmagged={!!data.isEmagged}
                    isDrinkDispenser={!!data.isDrinkDispenser}
                    dispenserType={data.dispenserType || 0}
                  />
                </Box>

                {activeTab === 'savedRecipes' && (
                  <SavedRecipesTab
                    recipes={savedRecipes}
                    recording={recording}
                    isBeakerLoaded={data.isBeakerLoaded}
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
                  isBeakerLoaded={data.isBeakerLoaded}
                  beakerContents={beakerContents}
                  beakerCurrentVolume={data.beakerCurrentVolume}
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
                />
              </Stack.Item>

              {!!data.canStore && (
                <Stack.Item grow basis="35%">
                  <StorageSidePanel
                    storedContents={storedContents}
                    storedVol={data.storedVol}
                    maxVol={data.maxVol}
                    amount={data.amount}
                    recording={recording}
                    isBeakerLoaded={data.isBeakerLoaded}
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
  const { act } = useBackend(context);
  const { amount, stepAmount, isBeakerLoaded, beakerMaxVolume, beakerCurrentVolume, beakerDoseAmounts } = props;

  // Convert beakerDoseAmounts to array of numbers (DM lists come as objects)
  let beakerAmounts = [];
  if (beakerDoseAmounts) {
    if (Array.isArray(beakerDoseAmounts)) {
      beakerAmounts = beakerDoseAmounts;
    } else if (typeof beakerDoseAmounts === 'object') {
      // Filter only numeric values from object
      beakerAmounts = Object.values(beakerDoseAmounts).filter(v => typeof v === 'number');
    }
  }

  // Use beaker dose amounts if available, otherwise fall back to defaults
  // Use filter for deduplication instead of Set (Set spread doesn't work in this environment)
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
              onClick={() => act('amount', { target: amt })}
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
            onChange={(e, value) => act('amount', { target: value })}
          />
          <Button
            ml={0.5}
            icon="fill-drip"
            tooltip="Максимум"
            disabled={!isBeakerLoaded}
            onClick={() => {
              const freeSpace = (beakerMaxVolume || 0) - (beakerCurrentVolume || 0);
              if (freeSpace > 0) {
                act('amount', { target: Math.floor(freeSpace) });
              }
            }}
          />
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const ChemicalButton = (props) => {
  const { chemical, onDispense, onToggleFavorite, isFavorite, compact, useReagentColor, showIcons, showPH = true } = props;
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

import { Component } from 'react';

import { useBackend } from '../backend';
import {
  Button,
  Dimmer,
  Flex,
  Icon,
  Input,
  LabeledList,
  Section,
  Tabs,
} from '../components';
import { Window } from '../layouts';

export class PersonalCrafting extends Component {
  constructor(props) {
    super(props);
    this.searchTimer = null;
    this.state = {
      searchQuery: '',
      tab: '',
    };
  }

  componentDidMount() {
    // Get the current backend data and actions
    const { act, data } = useBackend();
    const crafting_recipes = data.crafting_recipes || {};

    // If there are any categories and we haven't picked a tab yet, choose the first one and tell the server.
    const categories = this.getCategories(crafting_recipes);
    if (categories.length > 0 && !this.state.tab) {
      const firstCat = categories[0];
      this.setState({ tab: firstCat.id });
      act('set_category', {
        category: firstCat.category,
        subcategory: firstCat.subcategory,
      });
    }
    act('search', { query: '' }); // In case ui_interact fails to clear the search tab, send a clear search request on mount
  }

  componentWillUnmount() {
    // Cancel any pending search timer when the window is closed.
    if (this.searchTimer) {
      clearTimeout(this.searchTimer);
      this.searchTimer = null;
    }
  }

  getCategories(crafting_recipes) {
    const categories = [];
    for (let category of Object.keys(crafting_recipes)) {
      const subcategories = crafting_recipes[category];
      if ('has_subcats' in subcategories) {
        for (let subcategory of Object.keys(subcategories)) {
          if (subcategory === 'has_subcats') continue;
          categories.push({
            id: `${category}::${subcategory}`,
            name: subcategory,
            category,
            subcategory,
          });
        }
      } else {
        categories.push({
          id: `${category}::`,
          name: category,
          category,
        });
      }
    }
    return categories;
  }

  getRecipes(crafting_recipes) {
    const recipes = [];
    for (let category of Object.keys(crafting_recipes)) {
      const subcategories = crafting_recipes[category];
      if ('has_subcats' in subcategories) {
        for (let subcategory of Object.keys(subcategories)) {
          if (subcategory === 'has_subcats') continue;
          const _recipes = subcategories[subcategory];
          for (let recipe of _recipes) {
            recipes.push({
              ...recipe,
              tabId: `${category}::${subcategory}`,
            });
          }
        }
      } else {
        const _recipes = crafting_recipes[category];
        for (let recipe of _recipes) {
          recipes.push({
            ...recipe,
            tabId: `${category}::`,
          });
        }
      }
    }
    return recipes;
  }

  render() {
    const { act, data } = useBackend();
    const {
      busy,
      display_craftable_only,
      display_compact,
    } = data;

    const { searchQuery, tab } = this.state;

    // Build the category and recipe lists once per render.
    const crafting_recipes = data.crafting_recipes || {};
    const categories = this.getCategories(crafting_recipes);
    const recipes = this.getRecipes(crafting_recipes);

    const query = searchQuery.trim().toLowerCase();
    const isSearching = query.length > 0;

    // Filter results.
    const nameMatches = isSearching
      ? recipes.filter(r => r.name?.toLowerCase().includes(query))
      : [];
    const ingredientMatches = isSearching
      ? recipes.filter(r => r.req_text?.toLowerCase().includes(query))
      : [];

    const shownRecipes = isSearching
      ? []
      : recipes.filter(recipe => recipe.tabId === tab);

    return (
      <Window title="Crafting Menu" width={700} height={800}>
        <Window.Content overflow="auto">
          {!!busy && (
            <Dimmer fontSize="32px">
              <Icon name="cog" spin={1} />
              {' Crafting...'}
            </Dimmer>
          )}

          <Section>
            {/* Header: title, search bar, clear button, toggles */}
            <Flex align="center" justify="space-between" mb={1}>
              <Flex.Item>
                <b>Personal Crafting</b>
              </Flex.Item>
              <Flex.Item grow={1} mx={2}>
                <Flex align="center">
                  <Flex.Item grow={1}>
                    <Input
                      fluid
                      placeholder="Search..."
                      value={searchQuery}
                      onInput={(e, value) => {
                        this.setState({ searchQuery: value });
                        if (this.searchTimer) clearTimeout(this.searchTimer);
                        const trimmed = value.trim();
                        this.searchTimer = setTimeout(() => {
                          act('search', { query: trimmed });
                        }, 200);
                      }}
                    />
                  </Flex.Item>
                  <Flex.Item ml={0.5}>
                    <Button
                      icon="times"
                      disabled={!searchQuery}
                      color="transparent"
                      onClick={() => {
                        this.setState({ searchQuery: '' });
                        if (this.searchTimer) clearTimeout(this.searchTimer);
                        act('search', { query: '' });
                      }}
                      tooltip="Clear search"
                    />
                  </Flex.Item>
                </Flex>
              </Flex.Item>
              <Flex.Item>
                <Button.Checkbox
                  content="Compact"
                  checked={display_compact}
                  onClick={() => act('toggle_compact')}
                />
                <Button.Checkbox
                  content="Craftable Only"
                  checked={display_craftable_only}
                  onClick={() => act('toggle_recipes')}
                />
              </Flex.Item>
            </Flex>

            {/* Content area: categories (hidden when searching) */}
            <Flex.Item style={{ display: isSearching ? 'none' : 'block' }}>
              <Flex>
                <Flex.Item>
                  <Tabs vertical>
                    {categories.map(category => (
                      <Tabs.Tab
                        key={category.id}
                        selected={category.id === tab}
                        onClick={() => {
                          this.setState({ tab: category.id });
                          act('set_category', {
                            category: category.category,
                            subcategory: category.subcategory,
                          });
                        }}>
                        {category.name}
                      </Tabs.Tab>
                    ))}
                  </Tabs>
                </Flex.Item>
                <Flex.Item grow={1} basis={0}>
                  <CraftingList
                    craftables={shownRecipes}
                  />
                </Flex.Item>
              </Flex>
            </Flex.Item>

            {/* Search results (visible only when searching) */}
            <Flex.Item style={{ display: isSearching ? 'block' : 'none' }}>
              <Flex direction="column">
                <Flex.Item>
                  <Section
                    title={`Name matches (${nameMatches.length})`}
                    level={2}
                  >
                    <CraftingList
                      craftables={nameMatches}
                    />
                  </Section>
                </Flex.Item>
                <Flex.Item>
                  <Section
                    title={`Ingredient matches (${ingredientMatches.length})`}
                    level={2}
                  >
                    <CraftingList
                      craftables={ingredientMatches}
                    />
                  </Section>
                </Flex.Item>
              </Flex>
            </Flex.Item>
          </Section>
        </Window.Content>
      </Window>
    );
  }
}

const CraftingList = (props) => {
  const { craftables = [] } = props;
  const { act, data } = useBackend();
  const { craftability = {}, display_compact, display_craftable_only } = data;

  return craftables.map(craftable => {
    const hidden = display_craftable_only && !craftability[craftable.ref];
    if (hidden) return null;

    const canCraft = craftability[craftable.ref];
    if (display_compact) {
      return (
        <LabeledList.Item
          key={craftable.ref}
          label={craftable.name}
          className="candystripe"
          buttons={
            <Button
              icon="cog"
              content="Craft"
              disabled={!canCraft}
              tooltip={craftable.tool_text && 'Tools needed: ' + craftable.tool_text}
              tooltipPosition="left"
              onClick={() => act('make', { recipe: craftable.ref })}
            />
          }>
          {craftable.req_text}
        </LabeledList.Item>
      );
    }

    return (
      <Section
        key={craftable.ref}
        title={craftable.name}
        level={2}
        buttons={
          <Button
            icon="cog"
            content="Craft"
            disabled={!canCraft}
            onClick={() => act('make', { recipe: craftable.ref })}
          />
        }>
        <LabeledList>
          {!!craftable.req_text && (
            <LabeledList.Item label="Required">
              {craftable.req_text}
            </LabeledList.Item>
          )}
          {!!craftable.catalyst_text && (
            <LabeledList.Item label="Catalyst">
              {craftable.catalyst_text}
            </LabeledList.Item>
          )}
          {!!craftable.tool_text && (
            <LabeledList.Item label="Tools">
              {craftable.tool_text}
            </LabeledList.Item>
          )}
        </LabeledList>
      </Section>
    );
  });
};

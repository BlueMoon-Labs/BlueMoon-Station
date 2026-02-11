import { toTitleCase } from 'common/string';

import { useBackend } from '../../backend';
import {
  Box,
  Button,
  Icon,
  Section,
  Stack,
  Table,
} from '../../components';

export const SavedRecipesTab = (props, context) => {
  const { act } = useBackend(context);
  const {
    recipes,
    recording,
    isBeakerLoaded,
    onOptimisticRecipe,
    markPending,
    isActionPending,
    beginRecipeAction,
    onDeleteRecipe,
    onStartRecording,
    onCancelRecording,
    chemMetadata,
  } = props;

  const handleDispenseSaved = (recipe) => {
    const pendingKey = `saved_${recipe.name}`;
    if (isActionPending && isActionPending('__recipe_global')) return;
    if (beginRecipeAction) {
      if (!beginRecipeAction(pendingKey)) return;
    } else if (markPending) {
      markPending(pendingKey);
    }
    if (onOptimisticRecipe) {
      const dispenses = [];
      const metaById = chemMetadata ? chemMetadata.byId : {};
      let totalVol = 0;
      for (const [chemId, amount] of Object.entries(recipe.contents)) {
        if (amount > 0) {
          const meta = metaById[chemId] || {};
          dispenses.push({
            name: toTitleCase(chemId.replace(/_/g, ' ')),
            volume: amount,
            pH: meta.pH || 7,
            pHCol: meta.pHCol || null,
            reagentColor: meta.reagentColor || null,
          });
          totalVol += amount;
        }
      }
      if (dispenses.length > 0) {
        onOptimisticRecipe(dispenses, totalVol);
      }
    }
    act('dispense_recipe', { recipe: recipe.name });
  };

  return (
    <Section
      fill
      scrollable
      title="Мои рецепты"
      buttons={
        <Stack>
          {!recording ? (
            <>
              <Stack.Item>
                <Button
                  icon="circle"
                  color="red"
                  disabled={!isBeakerLoaded}
                  content="Записать"
                  onClick={onStartRecording || (() => act('record_recipe'))}
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="trash"
                  color="transparent"
                  tooltip="Удалить все"
                  disabled={recipes.length === 0}
                  onClick={() => act('clear_recipes')}
                />
              </Stack.Item>
            </>
          ) : (
            <>
              <Stack.Item>
                <Button
                  icon="save"
                  color="green"
                  content="Сохранить"
                  onClick={() => act('save_recording')}
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="ban"
                  color="bad"
                  content="Отмена"
                  onClick={onCancelRecording || (() => act('cancel_recording'))}
                />
              </Stack.Item>
            </>
          )}
        </Stack>
      }>
      {recipes.length === 0 ? (
        <Box color="label" textAlign="center" py={2}>
          <Icon name="book-open" size={2} mb={1} />
          <br />
          Рецепты отсутствуют
        </Box>
      ) : (
        <Table>
          {recipes.map(recipe => {
            const pendingKey = `saved_${recipe.name}`;
            const isGlobalPending = isActionPending && isActionPending('__recipe_global');
            const isPending = isGlobalPending || (isActionPending && isActionPending(pendingKey));
            return (
              <Table.Row key={recipe.name} className="candystripe">
                <Table.Cell>
                  <Button
                    fluid
                    icon={isPending ? 'spinner' : 'flask'}
                    iconSpin={isPending}
                    content={recipe.name}
                    disabled={isPending}
                    tooltip={
                      <Box>
                        <Box bold mb={0.5}>{recipe.name}</Box>
                        {Object.entries(recipe.contents).map(([name, amount]) => (
                          <Box key={name} color="label">
                            {toTitleCase(name.replace(/_/g, ' '))}: {amount}u
                          </Box>
                        ))}
                      </Box>
                    }
                    onClick={() => handleDispenseSaved(recipe)}
                  />
                </Table.Cell>
                <Table.Cell collapsing>
                  <Button
                    icon="trash"
                    color="transparent"
                    onClick={() => onDeleteRecipe
                      ? onDeleteRecipe(recipe.name)
                      : act('delete_recipe', { recipe: recipe.name })}
                  />
                </Table.Cell>
              </Table.Row>
            );
          })}
        </Table>
      )}
    </Section>
  );
};

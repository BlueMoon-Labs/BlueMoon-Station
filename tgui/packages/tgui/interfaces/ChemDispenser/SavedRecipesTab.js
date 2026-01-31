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
  const { recipes, recording, isBeakerLoaded } = props;

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
                  onClick={() => act('record_recipe')}
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
                  onClick={() => act('cancel_recording')}
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
          {recipes.map(recipe => (
            <Table.Row key={recipe.name} className="candystripe">
              <Table.Cell>
                <Button
                  fluid
                  icon="flask"
                  content={recipe.name}
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
                  onClick={() => act('dispense_recipe', { recipe: recipe.name })}
                />
              </Table.Cell>
              <Table.Cell collapsing>
                <Button
                  icon="trash"
                  color="transparent"
                  onClick={() => act('delete_recipe', { recipe: recipe.name })}
                />
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      )}
    </Section>
  );
};

import { classes } from 'common/react';
import { plural } from 'common/ru/plural';
import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Section, Stack, Table } from '../components';
import { Window } from '../layouts';

const pointsWord = (n) => plural(n, 'очко', 'очка', 'очков');

export const MiningVendor = (props) => {
  const { act, data } = useBackend();
  const [selectedCategory, setCategory] = useState('Общее снаряжение');

  const allProducts = data?.product_records || [];
  const dataCategories = data?.categories || [];
  { /* Фильтруем список от категорий без преметов, cuz големный */ }
  const categories = dataCategories.filter(category =>
    allProducts.some(p => p.category === category)
  );
  const inventory = selectedCategory
    ? allProducts.filter(p => p.category === selectedCategory)
    : [...allProducts];

  { /* Сортировка инвентаря по ценнику, cuz в .dm порядка нет */ }
  inventory.sort((a, b) =>
    a.price - b.price
    );

  return (
    <Window
      width={640}
      height={510}
      title="Шахтёрский автомат снаряжения">
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Section title="Пользователь">
              {data.user && (
                <Box>
                  Добро пожаловать, <b>{data.user.name || "Неизвестный"}</b>,
                  {' '}
                  <b>{data.user.job || "БЕЗ РАБОТЫ"}</b>!
                  <br />
                  Ваш баланс: <b>{data.user.points} шахтёрских очков</b>.
                  <br />
                  <Box color="good">
                    Текущая скидка: <b>{Math.round(data.discount * 1000) / 10}%</b>
                    {data.discount === 0 && ' Какая жалость...'}
                  </Box>
                </Box>
              ) || (
                <Box color="light-gray">
                  Не обнаружено зарегистрированной ID-карты!<br />
                  Пожалуйста, обратитесь к местному Главе Персонала!
                </Box>
              )}
            </Section>
          </Stack.Item>

          <Stack.Item grow>
            <Section fill title="Ассортимент">
              <Stack fill>
                <Stack.Item grow basis={0}>
                  <Section
                    key={selectedCategory}
                    fill
                    scrollable>
                    <Table>
                      {inventory.map(product => (
                        <Table.Row key={product.name}>
                          <Table.Cell>
                            <Box inline mr={1}>
                              <span
                                className={classes([
                                  'vending32x32',
                                  product.path,
                                ])}
                                style={{ verticalAlign: 'middle' }} />
                            </Box>
                            {' '}<b>{product.name}</b>
                          </Table.Cell>
                          <Table.Cell collapsing textAlign="right">
                            <Button
                              fluid
                              style={{
                                minWidth: '100px',
                                textAlign: 'center',
                              }}
                              disabled={!data.user
                                || product.price > data.user.points}
                              onClick={() => act('purchase', {
                                ref: product.ref,
                              })} >
                              {product.price} {pointsWord(product.price)}
                            </Button>
                          </Table.Cell>
                        </Table.Row>
                      ))}
                    </Table>
                  </Section>
                </Stack.Item>

                <Stack.Item basis="160px" shrink={0}>
                  {categories.map(category => (
                    <Box key={category} mb={0.5} ml={1}>
                      <Button
                        fluid
                        selected={selectedCategory === category}
                        onClick={() => setCategory(category)}
                      >
                        {category}
                      </Button>
                    </Box>
                  ))}
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

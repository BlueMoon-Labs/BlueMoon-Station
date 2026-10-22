import { classes } from 'common/react';
import { plural } from 'common/ru/plural';
import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Section, Stack, Table } from '../components';
import { Window } from '../layouts';

const pointsWord = (n) => plural(n, 'очко', 'очка', 'очков');

export const BountyVend = (props) => {
  const { act, data } = useBackend();
  const [selectedCategory, setCategory] = useState('Оружие дальнего боя');

  const allProducts = data?.product_records || [];
  const dataCategories = data?.categories || [];

  const categories = dataCategories.filter(category =>
    allProducts.some(p => p.category === category)
  );

  const inventory = selectedCategory
    ? allProducts.filter(p => p.category === selectedCategory)
    : [...allProducts];

  inventory.sort((a, b) => a.price - b.price);

  return (
    <Window width={620} height={550}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Section title="Пользователь">
              {data.user ? (
                <Box>
                  Добро пожаловать, <b>{data.user.name || "Неизвестный"}</b>,{' '}
                  <b>{data.user.job || "БЕЗРАБОТНЫЙ"}</b>!
                  <br />
                  Ваш баланс: <b>{data.user.points} {pointsWord(data.user.points)} награды</b>.
                  <br />
                  <Box color="good">
                    Текущая скидка: <b>{Math.round((data.discount || 0) * 100)}%</b>
                    {data.discount === 0 && ' Какая жалость...'}
                  </Box>
                </Box>
              ) : (
                <Box color="light-gray">
                  Не обнаружено зарегистрированной ID-карты!<br />
                  Пожалуйста, обратитесь к местному Главе Персонала!
                </Box>
              )}
            </Section>
          </Stack.Item>

          <Stack.Item grow>
            <Section fill title="Снаряжение">
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
                              })}>
                              {product.price} {pointsWord(product.price)}
                            </Button>
                          </Table.Cell>
                        </Table.Row>
                      ))}
                      {inventory.length === 0 && (
                        <Table.Row>
                          <Table.Cell colSpan="2" textAlign="center">
                            <Box color="label">В этой категории нет товаров.</Box>
                          </Table.Cell>
                        </Table.Row>
                      )}
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

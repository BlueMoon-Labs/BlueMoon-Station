import { classes } from 'common/react';

import { useBackend, useLocalState } from '../backend';
import { Box, Button, Flex, Section, Table } from '../components';
import { Window } from '../layouts';

export const MiningVendor = (props, context) => {
  const { act, data } = useBackend(context);
  const [selectedCategory, setCategory] = useLocalState(
    context,
    'selectedTab',
    'Mining Gear'
  );

  const allProducts = data?.product_records || [];
  const dataCategories = data?.categories || [];
  { /* Фильтруем список от категорий без преметов, cuz големный */ }
  const categories = dataCategories.filter(category =>
    allProducts.some(p => p.category === category)
  );
  const inventory = selectedCategory
    ? allProducts.filter(p => p.category === selectedCategory)
    : allProducts;

  { /* Сортировка инвентаря по ценнику, cuz в .dm порядка нет */ }
  inventory.sort((a, b) =>
    a.price - b.price
    );

  return (
    <Window
      width={620}
      height={550}>
      <Window.Content scrollable>
        <Section title="User">
          {data.user && (
            <Box>
              Welcome, <b>{data.user.name || "Unknown"}</b>,
              {' '}
              <b>{data.user.job || "Unemployed"}</b>!
              <br />
              Your balance is <b>{data.user.points} mining points</b>.
              <br />
              <Box color="good">
                Current discount is: <b>{data.discount * 100}%</b>
                {data.discount === 0 && ' What a shame...'}
              </Box>
            </Box>
          ) || (
            <Box color="light-gray">
              No registered ID card!<br />
              Please contact your local HoP!
            </Box>
          )}
        </Section>
        <Section title="Equipment">
            <Flex>
              {/* Левые вкладки, содержащие категории */}
              <Flex.Item
                basis="140px"
                grow={0}
                shrink={0}
                mr={1}
                style={{
                  borderRight: '1px solid rgba(255,255,255,0.1)',
                }}
              >
                {categories.map(category => (
                  <Box key={category} mb={0.5}>
                    <Button
                      fluid
                      selected={selectedCategory === category}
                      onClick={() => setCategory(category)}
                    >
                      {category}
                    </Button>
                  </Box>
                ))}
              </Flex.Item>

              {/* Правая часть интерфейса: товары категорий */}
              <Flex.Item grow={1}>
                <Table>
                  {inventory.map(product => (
                    <Table.Row key={product.name}>
                      <Table.Cell>
                        <Box inline mr={1}>
                          <span
                            className={classes(['vending32x32', product.path])}
                            style={{
                              'vertical-align': 'middle',
                            }} />
                        </Box>
                        {' '}<b>{product.name}</b>
                      </Table.Cell>
                      <Table.Cell collapsing textAlign="right">
                        <Button
                          fluid
                          style={{
                            'min-width': '100px',
                            'text-align': 'center',
                          }}
                          disabled={!data.user
                            || product.price > data.user.points}
                          onClick={() => act('purchase', {
                            ref: product.ref,
                          })} >
                          {product.price} points
                        </Button>
                      </Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              </Flex.Item>
            </Flex>
        </Section>
      </Window.Content>
    </Window>
    );
  };

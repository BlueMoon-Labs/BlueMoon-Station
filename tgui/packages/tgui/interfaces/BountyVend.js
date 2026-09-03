import { useBackend } from '../backend';
import { useState } from 'react';
import { Box, Button, Flex, Section, Table } from '../components';
import { Window } from '../layouts';

export const BountyVend = (props) => {
  const { act, data } = useBackend();
  const [selectedCategory, setCategory] = useState('Weaponry');

  const allProducts = data?.product_records || [];
  const dataCategories = data?.categories || [];

  const categories = dataCategories.filter(cat =>
    allProducts.some(p => p.category === cat)
  );

  const inventory = selectedCategory
    ? allProducts.filter(p => p.category === selectedCategory)
    : allProducts;

  inventory.sort((a, b) => a.price - b.price);

  return (
    <Window width={620} height={550}>
      <Window.Content scrollable>
        <Section title="User">
          {data.user ? (
            <Box>
              Welcome, <b>{data.user.name || "Unknown"}</b>,{' '}
              <b>{data.user.job || "Unemployed"}</b>!
              <br />
              Your balance is <b>{data.user.points} bounty points</b>.
              <br />
              <Box color="good">
                Current discount is: <b>{Math.round((data.discount || 0) * 100)}%</b>
                {data.discount === 0 && ' What a shame...'}
              </Box>
            </Box>
          ) : (
            <Box color="light-gray">
              No registered ID card!<br />
              Please contact your local HoP!
            </Box>
          )}
        </Section>
        <Section title="Equipment">
          <Flex>
            <Flex.Item
              basis="140px"
              grow={0}
              shrink={0}
              mr={1}
              style={{ borderRight: '1px solid rgba(255,255,255,0.1)' }}
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
            <Flex.Item grow={1}>
              <Table>
                {inventory.map(product => (
                  <Table.Row key={product.name}>
                    <Table.Cell>
                      <Box inline mr={1}>
                        <span
                          className={`vending32x32 ${product.path}`}
                          style={{ verticalAlign: 'middle' }}
                        />
                      </Box>
                      {' '}<b>{product.name}</b>
                    </Table.Cell>
                    <Table.Cell collapsing textAlign="right">
                      <Button
                        fluid
                        style={{ minWidth: '100px', textAlign: 'center' }}
                        disabled={!data.user || product.price > data.user.points}
                        onClick={() => act('purchase', { ref: product.ref })}
                      >
                        {product.price} points
                      </Button>
                    </Table.Cell>
                  </Table.Row>
                ))}
                {inventory.length === 0 && (
                  <Table.Row>
                    <Table.Cell colSpan="2" textAlign="center">
                      <Box color="label">No items in this category.</Box>
                    </Table.Cell>
                  </Table.Row>
                )}
              </Table>
            </Flex.Item>
          </Flex>
        </Section>
      </Window.Content>
    </Window>
  );
};

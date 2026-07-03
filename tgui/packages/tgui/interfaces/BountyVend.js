import { useBackend, useSharedState } from '../backend';
import { Box, Button, Section, Table, Tabs } from '../components';
import { Window } from '../layouts';

export const BountyVend = (props, context) => {
  const { act, data } = useBackend(context);
  const { user, product_records, categories, discount } = data;
  const [selectedCategory, setSelectedCategory] = useSharedState(context, 'category', categories[0]);

  const filteredProducts = product_records.filter(
    (p) => p.category === selectedCategory
  );

  return (
    <Window width={600} height={600}>
      <Window.Content scrollable>
        <Section title="BountyVend Terminal">
          {user ? (
            <Box color="good">
              Welcome, <b>{user.name}</b> ({user.job})<br />
              Bounty Points: <b>{user.points}</b>
            </Box>
          ) : (
            <Box color="bad">
              No ID Card Detected — Hold ID in hand or wear it
            </Box>
          )}
          {discount > 0 && (
            <Box color="good" mt={1}>
              Current Discount: <b>{Math.round(discount * 100)}%</b>
            </Box>
          )}
        </Section>

        <Section title="Categories">
          <Tabs>
            {categories.map((cat) => (
              <Tabs.Tab
                key={cat}
                selected={cat === selectedCategory}
                onClick={() => setSelectedCategory(cat)}
              >
                {cat}
              </Tabs.Tab>
            ))}
          </Tabs>
        </Section>

        <Section title={selectedCategory}>
          {filteredProducts.length > 0 ? (
            <Table>
              <Table.Row header>
                <Table.Cell>Item</Table.Cell>
                <Table.Cell>Price</Table.Cell>
                <Table.Cell>Action</Table.Cell>
              </Table.Row>
              {filteredProducts.map((p, i) => (
                <Table.Row key={i}>
                  <Table.Cell>
                    <Box
                      as="span"
                      dangerouslySetInnerHTML={{ __html: p.icon }}
                      style={{
                        'display': 'inline-block',
                        'width': '32px',
                        'height': '32px',
                        'vertical-align': 'middle',
                        'margin-right': '8px',
                      }}
                    />
                    <Box inline verticalAlign="middle">
                      {p.name}
                    </Box>
                  </Table.Cell>
                  <Table.Cell>{p.price} pts</Table.Cell>
                  <Table.Cell>
                    <Button
                      icon="shopping-cart"
                      content="Purchase"
                      disabled={!user || user.points < p.price}
                      onClick={() => act('purchase', { ref: p.ref })}
                    />
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          ) : (
            <Box color="label">No items in this category.</Box>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};

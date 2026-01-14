// tgui/packages/tgui/interfaces/Fabricator.tsx
// Frontend для Protolathe, Circuit Imprinter, Techfab

import { useBackend, useLocalState } from '../backend';
import { Window } from '../layouts';
import {
  Box,
  Button,
  Icon,
  Input,
  LabeledList,
  ProgressBar,
  Section,
  Stack,
  Tabs,
} from '../components';

type Design = {
  id: string;
  name: string;
  desc: string;
  categories: string[];
  buildPath: string;
  constructionTime: number;
  latheTimeFactor: number;
  minSecurityLevel: number;
  maxSecurityLevel: number;
  materials: Material[];
  reagents: Reagent[];
};

type Category = {
  name: string;
  subcategories: string[];
};

type Material = {
  name: string;
  amount: number;
  materialRef: string;
};

type Reagent = {
  name: string;
  amount: number;
};

type StoredMaterial = {
  name: string;
  amount: number;
  ref: string;
  sheets: number;
};

type StoredReagent = {
  name: string;
  volume: number;
  type: string;
};

type FabricatorData = {
  // Static data
  machineName: string;
  machineType: string;
  departmentTag: string;
  organization: string;
  categories: Category[];
  allowedBuildTypes: number;
  designs: Design[];
  fabricatorType: string;
  bypassSecurity?: boolean;

  // Dynamic data
  busy: boolean;
  emagged: boolean;
  disabled: boolean;
  hacked: boolean;
  efficiency: number;
  efficiencyPercent: number;
  materialsConnected: boolean;
  materialsOnHold: boolean;
  materialsMaxStorage: number;
  materials: StoredMaterial[];
  reagentsMaxVolume: number;
  reagentsTotalVolume: number;
  reagents: StoredReagent[];
  securityLevel: number;
  securityLevelName: string;
  isStation: boolean;
};

export const Fabricator = (props, context) => {
  const { act, data } = useBackend<FabricatorData>(context);
  const [selectedTab, setSelectedTab] = useLocalState(context, 'tab', 'designs');
  const [selectedCategory, setSelectedCategory] = useLocalState(
    context,
    'category',
    'All'
  );
  const [searchText, setSearchText] = useLocalState(context, 'search', '');

  const getFilteredDesigns = () => {
    let filtered = data.designs;

    // Filter by category
    if (selectedCategory !== 'All') {
      filtered = filtered.filter((d) =>
        d.categories.includes(selectedCategory)
      );
    }

    // Filter by search
    if (searchText) {
      const search = searchText.toLowerCase();
      filtered = filtered.filter((d) => d.name.toLowerCase().includes(search));
    }

    return filtered;
  };

  const canBuildDesign = (design: Design) => {
    if (data.busy) return false;
    if (!data.materialsConnected) return false;
    if (data.materialsOnHold) return false;

    // Check security level
    if (!data.emagged && !data.bypassSecurity && data.isStation) {
      if (
        data.securityLevel < design.minSecurityLevel ||
        data.securityLevel > design.maxSecurityLevel
      ) {
        return false;
      }
    }

    // Check materials
    for (const mat of design.materials) {
      const stored = data.materials.find((m) => m.name === mat.name);
      if (!stored || stored.amount < mat.amount) {
        return false;
      }
    }

    // Check reagents
    for (const reagent of design.reagents) {
      const stored = data.reagents.find((r) => r.name === reagent.name);
      if (!stored || stored.volume < reagent.amount) {
        return false;
      }
    }

    return true;
  };

  const getMaxBuildable = (design: Design) => {
    let max = 50;

    for (const mat of design.materials) {
      const stored = data.materials.find((m) => m.name === mat.name);
      if (stored) {
        max = Math.min(max, Math.floor(stored.amount / mat.amount));
      } else {
        return 0;
      }
    }

    for (const reagent of design.reagents) {
      const stored = data.reagents.find((r) => r.name === reagent.name);
      if (stored) {
        max = Math.min(max, Math.floor(stored.volume / reagent.amount));
      } else {
        return 0;
      }
    }

    return max;
  };

  return (
    <Window width={900} height={650}>
      <Window.Content scrollable>
        <Stack vertical fill>
          {/* Header */}
          <Stack.Item>
            <Section
              title={`${data.organization} ${data.departmentTag} ${data.machineName}`}
              buttons={
                <Button
                  icon="sync"
                  content="Sync Research"
                  onClick={() => act('sync_research')}
                />
              }
            >
              <LabeledList>
                <LabeledList.Item label="Security">
                  <Box color={data.emagged ? 'bad' : 'good'}>
                    {data.emagged ? 'DISABLED' : 'ACTIVE'}
                  </Box>
                </LabeledList.Item>
                <LabeledList.Item label="Materials">
                  {data.materialsConnected ? (
                    <Box color={data.materialsOnHold ? 'average' : 'good'}>
                      {data.materialsOnHold ? 'ON HOLD' : 'CONNECTED'}
                    </Box>
                  ) : (
                    <Box color="bad">NOT CONNECTED</Box>
                  )}
                </LabeledList.Item>
                <LabeledList.Item label="Efficiency">
                  {data.efficiencyPercent}%
                </LabeledList.Item>
                <LabeledList.Item label="Status">
                  {data.busy ? (
                    <Box color="average">FABRICATING...</Box>
                  ) : (
                    <Box color="good">READY</Box>
                  )}
                </LabeledList.Item>
                <LabeledList.Item label="Security Level">
                  {data.securityLevelName}
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>

          {/* Tabs */}
          <Stack.Item>
            <Tabs fluid>
              <Tabs.Tab
                selected={selectedTab === 'designs'}
                onClick={() => setSelectedTab('designs')}
              >
                <Icon name="wrench" /> Designs
              </Tabs.Tab>
              <Tabs.Tab
                selected={selectedTab === 'materials'}
                onClick={() => setSelectedTab('materials')}
              >
                <Icon name="box" /> Materials
              </Tabs.Tab>
              <Tabs.Tab
                selected={selectedTab === 'chemicals'}
                onClick={() => setSelectedTab('chemicals')}
              >
                <Icon name="flask" /> Chemicals
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>

          {/* Content */}
          <Stack.Item grow>
            {selectedTab === 'designs' && (
              <DesignsTab
                context={context}
                data={data}
                selectedCategory={selectedCategory}
                setSelectedCategory={setSelectedCategory}
                searchText={searchText}
                setSearchText={setSearchText}
                getFilteredDesigns={getFilteredDesigns}
                canBuildDesign={canBuildDesign}
                getMaxBuildable={getMaxBuildable}
                act={act}
              />
            )}
            {selectedTab === 'materials' && (
              <MaterialsTab data={data} act={act} />
            )}
            {selectedTab === 'chemicals' && (
              <ChemicalsTab data={data} act={act} />
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const DesignsTab = (props) => {
  const {
    data,
    selectedCategory,
    setSelectedCategory,
    searchText,
    setSearchText,
    getFilteredDesigns,
    canBuildDesign,
    getMaxBuildable,
    act,
  } = props;

  const [expandedCategories, setExpandedCategories] = useLocalState(
    props.context,
    'expanded_categories',
    []
  );

  const filteredDesigns = getFilteredDesigns();

  const toggleCategory = (catName: string) => {
    if (expandedCategories.includes(catName)) {
      setExpandedCategories(expandedCategories.filter((c) => c !== catName));
    } else {
      setExpandedCategories([...expandedCategories, catName]);
    }
  };

  const countDesignsInCategory = (category: string) => {
    return data.designs.filter((d) => d.categories.includes(category)).length;
  };

  return (
    <Stack fill>
      {/* Sidebar with categories */}
      <Stack.Item basis="250px">
        <Section fill scrollable title="Categories">
          <Button
            fluid
            color={selectedCategory === 'All' ? 'good' : 'default'}
            onClick={() => setSelectedCategory('All')}
            mb={0.5}
          >
            <Stack>
              <Stack.Item grow>All Designs</Stack.Item>
              <Stack.Item>({data.designs.length})</Stack.Item>
            </Stack>
          </Button>
          {data.categories.map((category) => {
            const isExpanded = expandedCategories.includes(category.name);
            const hasSubcats = category.subcategories.length > 0;
            const count = countDesignsInCategory(category.name);

            return (
              <Box key={category.name}>
                <Button
                  fluid
                  color={selectedCategory === category.name ? 'good' : 'default'}
                  onClick={() => {
                    setSelectedCategory(category.name);
                    if (hasSubcats) {
                      toggleCategory(category.name);
                    }
                  }}
                  mb={0.5}
                >
                  <Stack>
                    <Stack.Item>
                      {hasSubcats && (
                        <Icon
                          name={isExpanded ? 'chevron-down' : 'chevron-right'}
                          mr={0.5}
                        />
                      )}
                    </Stack.Item>
                    <Stack.Item grow>{category.name}</Stack.Item>
                    <Stack.Item>({count})</Stack.Item>
                  </Stack>
                </Button>

                {/* Subcategories */}
                {isExpanded &&
                  hasSubcats &&
                  category.subcategories.map((subcat) => {
                    const subCount = countDesignsInCategory(subcat);
                    return (
                      <Button
                        key={subcat}
                        fluid
                        color={selectedCategory === subcat ? 'good' : 'default'}
                        onClick={() => setSelectedCategory(subcat)}
                        mb={0.5}
                        ml={2}
                      >
                        <Stack>
                          <Stack.Item grow>{subcat}</Stack.Item>
                          <Stack.Item>({subCount})</Stack.Item>
                        </Stack>
                      </Button>
                    );
                  })}
              </Box>
            );
          })}
        </Section>
      </Stack.Item>

      {/* Main content */}
      <Stack.Item grow>
        <Stack vertical fill>
          {/* Search */}
          <Stack.Item>
            <Section>
              <Input
                fluid
                placeholder="Search designs..."
                value={searchText}
                onInput={(e, value) => setSearchText(value)}
              />
            </Section>
          </Stack.Item>

          {/* Designs grid */}
          <Stack.Item grow>
            <Section fill scrollable title={`${selectedCategory} (${filteredDesigns.length})`}>
              {filteredDesigns.map((design) => (
                <DesignCard
                  key={design.id}
                  design={design}
                  canBuild={canBuildDesign(design)}
                  maxBuildable={getMaxBuildable(design)}
                  data={data}
                  act={act}
                />
              ))}
            </Section>
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

const DesignCard = (props) => {
  const { design, canBuild, maxBuildable, data, act } = props;

  const hasSecurityIssue =
    !data.emagged &&
    !data.bypassSecurity &&
    data.isStation &&
    (data.securityLevel < design.minSecurityLevel ||
      data.securityLevel > design.maxSecurityLevel);

  return (
    <Section
      title={design.name}
      buttons={
        <>
          {canBuild && (
            <>
              <Button
                icon="hammer"
                content="x1"
                onClick={() => act('build', { id: design.id, amount: 1 })}
              />
              {maxBuildable >= 5 && (
                <Button
                  content="x5"
                  onClick={() => act('build', { id: design.id, amount: 5 })}
                />
              )}
              {maxBuildable >= 10 && (
                <Button
                  content="x10"
                  onClick={() => act('build', { id: design.id, amount: 10 })}
                />
              )}
              {maxBuildable >= 30 && (
                <Button
                  content="x30"
                  onClick={() => act('build', { id: design.id, amount: 30 })}
                />
              )}
            </>
          )}
          {!canBuild && (
            <Button disabled icon="times" content="Cannot Build" />
          )}
        </>
      }
      mb={1}
    >
      {design.desc && <Box italic mb={1}>{design.desc}</Box>}

      {/* Materials */}
      {design.materials.length > 0 && (
        <Box>
          <Box bold mb={0.5}>
            Materials:
          </Box>
          {design.materials.map((mat) => {
            const stored = data.materials.find((m) => m.name === mat.name);
            const hasEnough = stored && stored.amount >= mat.amount;
            return (
              <Box
                key={mat.name}
                inline
                mr={1}
                color={hasEnough ? 'good' : 'bad'}
              >
                {mat.amount} {mat.name}
              </Box>
            );
          })}
        </Box>
      )}

      {/* Reagents */}
      {design.reagents.length > 0 && (
        <Box mt={0.5}>
          <Box bold mb={0.5}>
            Reagents:
          </Box>
          {design.reagents.map((reagent) => {
            const stored = data.reagents.find((r) => r.name === reagent.name);
            const hasEnough = stored && stored.volume >= reagent.amount;
            return (
              <Box
                key={reagent.name}
                inline
                mr={1}
                color={hasEnough ? 'good' : 'bad'}
              >
                {reagent.amount}u {reagent.name}
              </Box>
            );
          })}
        </Box>
      )}

      {/* Security warning */}
      {hasSecurityIssue && (
        <Box mt={1} color="average">
          <Icon name="exclamation-triangle" /> Security level required
        </Box>
      )}
    </Section>
  );
};

const MaterialsTab = (props) => {
  const { data, act } = props;

  if (!data.materialsConnected) {
    return (
      <Section fill title="Materials">
        <Box color="bad">No material storage connected!</Box>
      </Section>
    );
  }

  return (
    <Section fill scrollable title="Material Storage">
      {data.materials.map((mat) => (
        <Section key={mat.ref} title={mat.name} level={2}>
          <Stack>
            <Stack.Item grow>
              <LabeledList>
                <LabeledList.Item label="Amount">
                  {mat.amount} cm³
                </LabeledList.Item>
                <LabeledList.Item label="Sheets">
                  {mat.sheets}
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>
            <Stack.Item>
              <Stack>
                {mat.sheets >= 1 && (
                  <Stack.Item>
                    <Button
                      content="1x"
                      onClick={() =>
                        act('eject_material', { ref: mat.ref, amount: 1 })
                      }
                    />
                  </Stack.Item>
                )}
                {mat.sheets >= 5 && (
                  <Stack.Item>
                    <Button
                      content="5x"
                      onClick={() =>
                        act('eject_material', { ref: mat.ref, amount: 5 })
                      }
                    />
                  </Stack.Item>
                )}
                {mat.sheets >= 10 && (
                  <Stack.Item>
                    <Button
                      content="10x"
                      onClick={() =>
                        act('eject_material', { ref: mat.ref, amount: 10 })
                      }
                    />
                  </Stack.Item>
                )}
                {mat.sheets >= 50 && (
                  <Stack.Item>
                    <Button
                      content="Max"
                      onClick={() =>
                        act('eject_material', { ref: mat.ref, amount: 50 })
                      }
                    />
                  </Stack.Item>
                )}
              </Stack>
            </Stack.Item>
          </Stack>
        </Section>
      ))}
    </Section>
  );
};

const ChemicalsTab = (props) => {
  const { data, act } = props;

  return (
    <Section
      fill
      scrollable
      title="Chemical Storage"
      buttons={
        <Button
          icon="trash"
          content="Purge All"
          color="bad"
          onClick={() => act('dispose_all_reagents')}
        />
      }
    >
      <ProgressBar
        value={data.reagentsTotalVolume}
        maxValue={data.reagentsMaxVolume}
        mb={1}
      >
        {data.reagentsTotalVolume} / {data.reagentsMaxVolume} units
      </ProgressBar>

      {data.reagents.map((reagent) => (
        <Section key={reagent.type} title={reagent.name} level={2}>
          <Stack>
            <Stack.Item grow>
              <Box>{reagent.volume} units</Box>
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="trash"
                content="Purge"
                onClick={() =>
                  act('dispose_reagent', { type: reagent.type })
                }
              />
            </Stack.Item>
          </Stack>
        </Section>
      ))}
    </Section>
  );
};

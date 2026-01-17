// tgui/packages/tgui/interfaces/Fabricator.tsx

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

/* ================= TYPES ================= */

type Design = {
  id: string;
  name: string;
  desc: string | null;
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
  type: string;
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
  machineName: string;
  machineType: string;
  departmentTag: string;
  organization: string;
  categories: Category[];
  allowedBuildTypes: number;
  designs: Design[];
  fabricatorType: string;
  bypassSecurity?: boolean;

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

/* ================= SECURITY ================= */

const SECURITY_LEVEL_NAMES: Record<number, string> = {
  1: 'Green',
  2: 'Blue',
  3: 'Orange',
  4: 'Violet',
  5: 'Amber',
  6: 'Red',
  7: 'Lambda',
  8: 'Gamma',
  9: 'Epsilon',
  10: 'Delta',
};

const formatSecurityRange = (min: number, max: number) => {
  const minName = SECURITY_LEVEL_NAMES[min] || min;
  const maxName = SECURITY_LEVEL_NAMES[max] || max;
  return min === max ? minName : `${minName}–${maxName}`;
};

/* ================= MAIN ================= */

export const Fabricator = (props, context) => {
  const { act, data } = useBackend<FabricatorData>(context);

  const [tab, setTab] = useLocalState(context, 'tab', 'designs');
  const [category, setCategory] = useLocalState(context, 'category', 'All');
  const [search, setSearch] = useLocalState(context, 'search', '');

  const filteredDesigns = data.designs.filter((d) => {
    if (category !== 'All' && !d.categories.includes(category)) {
      return false;
    }
    if (search && !d.name.toLowerCase().includes(search.toLowerCase())) {
      return false;
    }
    return true;
  });

  return (
    <Window width={900} height={650}>
      <Window.Content scrollable>
        <Stack vertical fill>

          {/* HEADER */}
          <Stack.Item>
            <Section
              title={`${data.organization} ${data.departmentTag} ${data.machineName}`}
              buttons={
                <Button icon="sync" content="Sync Research" onClick={() => act('sync_research')} />
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
                <LabeledList.Item label="Material Use (Lower is better)">
                  {data.efficiencyPercent}%
                </LabeledList.Item>
                <LabeledList.Item label="Status">
                  {data.busy ? (
                    <Box color="average">FABRICATING</Box>
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

          {/* TABS */}
          <Stack.Item>
            <Tabs fluid>
              <Tabs.Tab selected={tab === 'designs'} onClick={() => setTab('designs')}>
                <Icon name="wrench" /> Designs
              </Tabs.Tab>
              <Tabs.Tab selected={tab === 'materials'} onClick={() => setTab('materials')}>
                <Icon name="box" /> Materials
              </Tabs.Tab>
              <Tabs.Tab selected={tab === 'chemicals'} onClick={() => setTab('chemicals')}>
                <Icon name="flask" /> Chemicals
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>

          {/* CONTENT */}
          <Stack.Item grow>
            {tab === 'designs' && (
              <DesignsTab
                context={context}
                data={data}
                designs={filteredDesigns}
                category={category}
                setCategory={setCategory}
                search={search}
                setSearch={setSearch}
                act={act}
              />
            )}

            {tab === 'materials' && <MaterialsTab data={data} act={act} />}
            {tab === 'chemicals' && <ChemicalsTab data={data} act={act} />}
          </Stack.Item>

        </Stack>
      </Window.Content>
    </Window>
  );
};

/* ================= DESIGNS ================= */

const DesignsTab = ({ context, data, designs, category, setCategory, search, setSearch, act }) => {
  const [compact, setCompact] = useLocalState(context, 'compact', false);

  return (
    <Stack fill>
      <Stack.Item basis="250px">
        <Section title="Categories" fill scrollable>
          <Button
            fluid
            selected={category === 'All'}
            onClick={() => setCategory('All')}
          >
            All Designs ({data.designs.length})
          </Button>

          {data.categories.map((c) => (
            <Button
              key={c.name}
              fluid
              selected={category === c.name}
              onClick={() => setCategory(c.name)}
            >
              {c.name}
            </Button>
          ))}
        </Section>
      </Stack.Item>

      <Stack.Item grow>
        <Section>
          <Stack>
            <Stack.Item grow>
              <Input
                fluid
                placeholder="Search designs..."
                value={search}
                onInput={(e, v) => setSearch(v)}
              />
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="compress"
                content="Compact"
                selected={compact}
                onClick={() => setCompact(!compact)}
              />
            </Stack.Item>
          </Stack>
        </Section>

        <Section fill scrollable title={`${category} (${designs.length})`}>
          {designs.map((design) => (
            <DesignCard
              key={design.id}
              design={design}
              data={data}
              compact={compact}
              act={act}
            />
          ))}
        </Section>
      </Stack.Item>
    </Stack>
  );
};

/* ================= DESIGN CARD ================= */

const DesignCard = ({ design, data, compact, act }) => {
  const hasSecurityIssue =
    !data.emagged &&
    !data.bypassSecurity &&
    data.isStation &&
    (data.securityLevel < design.minSecurityLevel ||
      data.securityLevel > design.maxSecurityLevel);

  const buttons = (
    <>
      <Button onClick={() => act('build', { id: design.id, amount: 1 })}>x1</Button>
      <Button onClick={() => act('build', { id: design.id, amount: 5 })}>x5</Button>
      <Button onClick={() => act('build', { id: design.id, amount: 10 })}>x10</Button>
      <Button onClick={() => act('build', { id: design.id, amount: 30 })}>x30</Button>
    </>
  );

  if (compact) {
    return (
      <Box mb={0.5} p={0.5} backgroundColor="rgba(0,0,0,0.33)">
        <Stack align="center">
          <Stack.Item grow>
            <Box bold>{design.name}</Box>

            <Box fontSize="0.9em" mt={0.3}>
              {design.materials.map((m) => {
                const stored = data.materials.find((mat) => mat.name === m.name);
                const hasEnough = stored && stored.amount >= m.amount;
                return (
                  <Box key={m.name} inline mr={1} color={hasEnough ? 'good' : 'bad'}>
                    {m.amount} {m.name}
                  </Box>
                );
              })}
              {design.reagents.map((r) => {
                const stored = data.reagents.find((reg) => reg.name === r.name);
                const hasEnough = stored && stored.volume >= r.amount;
                return (
                  <Box key={r.type} inline mr={1} color={hasEnough ? 'average' : 'bad'}>
                    {r.amount}u {r.name}
                  </Box>
                );
              })}
              {hasSecurityIssue && (
                <Box inline color="orange" ml={1}>
                  <Icon name="exclamation-triangle" mr={0.5} />
                  {formatSecurityRange(design.minSecurityLevel, design.maxSecurityLevel)}
                </Box>
              )}
            </Box>
          </Stack.Item>
          <Stack.Item>{buttons}</Stack.Item>
        </Stack>
      </Box>
    );
  }

  return (
    <Section title={design.name} buttons={buttons} mb={1}>
      {design.desc && (
        <Box italic mb={1} color="label">
          {design.desc}
        </Box>
      )}

      {/* Materials */}
      {design.materials.length > 0 && (
        <Box mb={0.5}>
          <Box bold color="label">
            Materials:
          </Box>
          {design.materials.map((m) => {
            const stored = data.materials.find((mat) => mat.name === m.name);
            const hasEnough = stored && stored.amount >= m.amount;
            return (
              <Box key={m.name} inline mr={1} color={hasEnough ? 'good' : 'bad'}>
                {m.amount} {m.name}
              </Box>
            );
          })}
        </Box>
      )}

      {/* Reagents */}
      {design.reagents.length > 0 && (
        <Box mb={0.5}>
          <Box bold color="label">
            Reagents:
          </Box>
          {design.reagents.map((r) => {
            const stored = data.reagents.find((reg) => reg.name === r.name);
            const hasEnough = stored && stored.volume >= r.amount;
            return (
              <Box key={r.type} inline mr={1} color={hasEnough ? 'average' : 'bad'}>
                {r.amount}u {r.name}
              </Box>
            );
          })}
        </Box>
      )}

      {/* Security level requirement */}
      {hasSecurityIssue && (
        <Box color="orange">
          <Icon name="exclamation-triangle" mr={0.5} />
          Security level required: {formatSecurityRange(design.minSecurityLevel, design.maxSecurityLevel)}
        </Box>
      )}
    </Section>
  );
};

/* ================= MATERIALS ================= */

const MaterialsTab = ({ data, act }) => {
  if (!data.materialsConnected) {
    return (
      <Section fill title="Material Storage">
        <Box color="bad">NOT CONNECTED</Box>
      </Section>
    );
  }

  return (
    <Section fill scrollable title="Material Storage">
      {data.materials.map((m) => (
        <Box
          key={m.ref}
          mb={0.5}
          p={0.5}
          backgroundColor="rgba(0,0,0,0.33)"
        >
          <Stack align="center">
            {/* Material name */}
            <Stack.Item basis="140px">
              <Box bold>{m.name}</Box>
            </Stack.Item>

            {/* Volume */}
            <Stack.Item basis="110px">
              {m.amount} cm³
            </Stack.Item>

            {/* Sheets */}
            <Stack.Item basis="90px">
              {m.sheets} sheets
            </Stack.Item>

            {/* Buttons */}
            <Stack.Item grow>
              <Stack>
                {m.sheets >= 1 && (
                  <Button
                    content="1x"
                    onClick={() =>
                      act('eject_material', { ref: m.ref, amount: 1 })
                    }
                  />
                )}
                {m.sheets >= 5 && (
                  <Button
                    content="5x"
                    onClick={() =>
                      act('eject_material', { ref: m.ref, amount: 5 })
                    }
                  />
                )}
                {m.sheets >= 10 && (
                  <Button
                    content="10x"
                    onClick={() =>
                      act('eject_material', { ref: m.ref, amount: 10 })
                    }
                  />
                )}
                {m.sheets >= 50 && (
                  <Button
                    content="Max"
                    onClick={() =>
                      act('eject_material', { ref: m.ref, amount: 50 })
                    }
                  />
                )}
              </Stack>
            </Stack.Item>
          </Stack>
        </Box>
      ))}
    </Section>
  );
};

/* ================= CHEMICALS ================= */

const ChemicalsTab = ({ data, act }) => (
  <Section
    fill
    scrollable
    title="Chemical Storage"
    buttons={
      data.reagentsTotalVolume > 0 && (
        <Button
          icon="trash"
          content="Purge All"
          color="bad"
          onClick={() => act('dispose_all_reagents')}
        />
      )
    }
  >
    {/* Capacity info */}
    <Box mb={0.5}>
      <Box bold>
        Chemical Storage Capacity: {data.reagentsMaxVolume} units
      </Box>
    </Box>

    {/* Current fill */}
    <ProgressBar
      value={data.reagentsTotalVolume}
      maxValue={data.reagentsMaxVolume}
      mb={1}
    >
      {data.reagentsTotalVolume} / {data.reagentsMaxVolume} units
    </ProgressBar>

    {/* Reagents list */}
    {data.reagents.length === 0 && (
      <Box color="average">No reagents stored.</Box>
    )}

    {data.reagents.map((r) => (
      <Box
        key={r.type}
        mb={0.5}
        p={0.5}
        backgroundColor="rgba(0,0,0,0.33)"
      >
        <Stack align="center">
          <Stack.Item grow>
            <Box bold>{r.name}</Box>
          </Stack.Item>

          <Stack.Item>
            {r.volume} units
          </Stack.Item>

          <Stack.Item>
            <Button
              icon="trash"
              content="Purge"
              onClick={() =>
                act('dispose_reagent', { type: r.type })
              }
            />
          </Stack.Item>
        </Stack>
      </Box>
    ))}
  </Section>
);

import { useBackend } from '../../../backend';
import { Box, Button, Dropdown, Section, Stack } from '../../../components';
import { FieldRow, SelectRow, TabDataMissing } from '../components';

interface LimbRow {
  zone: string;
  kind: string;
  brand?: string;
}

interface OrganOption {
  id: string;
  label: string;
  cost: number;
}

interface OrganGroup {
  slot: string;
  label: string;
  options: OrganOption[];
  selected: string | null;
  locked: boolean;
  lockReason?: string;
}

interface ImplantRow {
  id: string;
  label: string;
  desc: string;
  cost: number;
  selected: boolean;
}

interface ModsData {
  balance: number;
  limbs: LimbRow[];
  limbKinds: string[];
  limbBrands: string[];
  prostheticCount: number;
  amputationCount: number;
  limbBonus: number;
  maxProsthetics: number;
  organs: OrganGroup[];
  implants: ImplantRow[];
}

interface ModsContext {
  modsTab?: ModsData;
}

const ZONE_LABELS: Record<string, string> = {
  l_arm: 'Левая рука',
  r_arm: 'Правая рука',
  l_leg: 'Левая нога',
  r_leg: 'Правая нога',
};

const KIND_LABELS: Record<string, string> = {
  Normal: 'Обычная',
  Prosthetic: 'Протез',
  Amputated: 'Ампутирована',
};

const costLabel = (cost: number): string => (cost > 0 ? ` (${cost} оч.)` : '');

const brandLabel = (brand: string): string =>
  brand === 'prosthetic'
    ? 'Стандартная'
    : brand.charAt(0).toUpperCase() + brand.slice(1);

export const ModificationsTab = () => {
  const { act, data } = useBackend<ModsContext>();
  const mods = data.modsTab;

  if (!mods) {
    return <TabDataMissing title="Модификации" />;
  }

  const balance = mods.balance ?? 0;

  return (
    <Section fill scrollable title="Модификации">
      <Stack mb={1} wrap>
        <Stack.Item>
          <Box inline bold mr={1}>
            Очков осталось:
          </Box>
          <Box inline color={balance < 0 ? 'bad' : undefined}>
            {balance}
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Box inline bold mr={1} color="label">
            Протезов:
          </Box>
          <Box inline color="label">
            {mods.prostheticCount} / {mods.maxProsthetics}
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Box inline bold mr={1} color="label">
            Ампутаций:
          </Box>
          <Box inline color="label">{mods.amputationCount}</Box>
        </Stack.Item>
        <Stack.Item>
          <Box inline bold mr={1} color="label">
            Бонус конечностей:
          </Box>
          <Box inline color={mods.limbBonus > 0 ? 'good' : 'label'}>
            +{mods.limbBonus} оч.
          </Box>
        </Stack.Item>
      </Stack>

      <Section title="Конечности">
        {mods.limbs.map((limb) => (
          <SelectRow
            key={limb.zone}
            label={ZONE_LABELS[limb.zone] || limb.zone}
            value={limb.kind}
            options={mods.limbKinds.map((kind) => ({
              value: kind,
              displayText: KIND_LABELS[kind] || kind,
            }))}
            action="set_limb"
            params={{ zone: limb.zone }}
            extra={
              limb.kind === 'Prosthetic' ? (
                <Dropdown
                  width="118px"
                  tooltip="Модель протеза"
                  options={mods.limbBrands.map((brand) => ({
                    value: brand,
                    displayText: brandLabel(brand),
                  }))}
                  selected={limb.brand || 'prosthetic'}
                  onSelected={(value) =>
                    act('set_limb', { zone: limb.zone, value })
                  }
                />
              ) : undefined
            }
          />
        ))}
      </Section>

      <Section title="Органы">
        <Box bold color="label" mb={1}>
          Кибернетические органы стоят очков квирков, обычные - бесплатно.
        </Box>
        {mods.organs.map((group) =>
          group.locked ? (
            <FieldRow key={group.slot} label={group.label} tooltip={group.lockReason}>
              <Box color="label">недоступно</Box>
            </FieldRow>
          ) : (
            <SelectRow
              key={group.slot}
              label={group.label}
              value={group.selected}
              options={group.options.map((option) => ({
                value: option.id,
                displayText: `${option.label}${costLabel(option.cost)}`,
              }))}
              action="set_organ"
              params={{ slot: group.slot }}
            />
          )
        )}
      </Section>

      <Section title="Импланты">
        {mods.implants.map((implant) => (
          <Stack key={implant.id} align="center" mb={1}>
            <Stack.Item grow>
              <Box bold={implant.selected}>{implant.label}</Box>
              <Box color="label">{implant.desc}</Box>
            </Stack.Item>
            <Stack.Item width="70px" textAlign="right">
              <Box color={implant.cost > 0 ? 'bad' : 'label'}>
                {implant.cost} оч.
              </Box>
            </Stack.Item>
            <Stack.Item>
              <Button
                icon={implant.selected ? 'check' : 'plus'}
                selected={implant.selected}
                onClick={() => act('toggle_implant', { id: implant.id })}
              >
                {implant.selected ? 'Взято' : 'Взять'}
              </Button>
            </Stack.Item>
          </Stack>
        ))}
      </Section>
    </Section>
  );
};

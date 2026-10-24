import { useBackend } from '../../../backend';
import { Box, Button, Dropdown, Section, Stack } from '../../../components';
import {
  asArray,
  asOptions,
  ColorField,
  FeatureField,
  FieldRow,
  renderFeatureField,
  SelectRow,
  SettingsGrid,
  TabDataMissing,
  TextRow,
  ToggleRow,
} from '../components';
import { GenitalData, GenitalsSection } from './Genitals';

interface MutantPartColor {
  label: string;
  key: string;
  value: string;
}

interface MutantPart {
  key: string;
  label: string;
  value: string;
  options: string[];
  glowKey: string;
  hasGlow: boolean;
  glow: boolean;
  colors?: MutantPartColor[];
}

interface ModifiedLimb {
  name: string;
  kind: string;
  extra?: string;
}

interface AppearanceData {
  values: Record<string, string | number | boolean>;

  gender: string;
  genderOptions: Record<string, string>;
  bodyModel: string;
  bodyModelOptions: Record<string, string>;
  speciesSexes: boolean;
  species: string;
  speciesList: string[];
  customSpecies: string | null;
  advancedColors: boolean;
  modifiedLimbs: ModifiedLimb[];

  useSkintones: boolean;
  skinTone: string;
  useCustomSkinTone: boolean;
  skinToneOptions: string[];
  hasMutantColors: boolean;

  hasEyes: boolean;
  hasEyecolor: boolean;
  eyeType: string;
  eyeTypes: string[];
  eyesGlow: boolean;

  hasHair: boolean;
  hairStyle: string;
  facialHairStyle: string;
  gradStyle: string;

  mutantParts: MutantPart[];

  bodySprite: string;
  bodySprites: string[];
  hasScars: boolean;

  bodyWeight: string;
  weightOptions: Record<string, string>;
  weightLocked: boolean;

  genitals?: GenitalData;
}

interface AppearanceContext {
  appearance?: AppearanceData;
  featureFields?: FeatureField[];
}

const HairStyleRow = (props: {
  label: string;
  kind: string;
  style: string;
}) => {
  const { act } = useBackend<AppearanceContext>();
  const { label, kind, style } = props;
  return (
    <FieldRow label={label}>
      <Stack align="center" style={{ width: '100%' }}>
        <Stack.Item grow>
          <Box
            title={style}
            color={style ? undefined : 'label'}
            style={{
              overflow: 'hidden',
              textAlign: 'center',
              textOverflow: 'ellipsis',
              whiteSpace: 'nowrap',
            }}
          >
            {style || 'по умолчанию'}
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="brush"
            tooltip="Выбрать из списка"
            onClick={() => act('pick_hair_style', { kind })}
          />
        </Stack.Item>
      </Stack>
    </FieldRow>
  );
};

const MutantPartCard = (props: { part: MutantPart }) => {
  const { act } = useBackend<AppearanceContext>();
  const { part } = props;
  return (
    <Box
      p={1}
      style={{
        border: '1px solid rgba(255,255,255,0.15)',
        borderRadius: '2px',
      }}
    >
      <Box mb={1}>
        <b>{part.label}</b>
      </Box>
      <Stack align="center">
        <Stack.Item grow>
          <Dropdown
            width="100%"
            options={part.options || []}
            selected={part.value || ''}
            onSelected={(next) =>
              act('set_mutant_part', { part: part.key, value: next })
            }
          />
        </Stack.Item>
        {!!part.hasGlow && (
          <Stack.Item>
            <Button
              icon="lightbulb"
              selected={!!part.glow}
              tooltip="Свечение части"
              onClick={() =>
                act('toggle_emissive_part', { part: part.glowKey })
              }
            />
          </Stack.Item>
        )}
      </Stack>
      {asArray(part.colors).map((row) => (
        <ColorField
          key={row.key}
          label={row.label}
          value={row.value}
          action="set_part_color"
          params={{ part: part.key, key: row.key }}
        />
      ))}
    </Box>
  );
};

export const AppearanceTab = () => {
  const { act, data } = useBackend<AppearanceContext>();
  const appearance = data.appearance;
  const fields = data.featureFields || [];

  if (!appearance) {
    return <TabDataMissing title="Внешность" />;
  }

  const values = appearance.values || {};
  const field = (key: string) => renderFeatureField(fields, values, key);
  const fieldIf = (visible: boolean, key: string) =>
    visible ? field(key) : null;

  const weightNames = Object.keys(appearance.weightOptions || {});

  return (
    <Section fill scrollable title="Внешность">
      <SettingsGrid>
        <Section title="Тело">
          <SelectRow
            label="Пол"
            value={appearance.gender}
            options={asOptions(appearance.genderOptions)}
            action="set_gender"
          />
          {!!appearance.speciesSexes && (
            <SelectRow
              label="Телосложение"
              value={appearance.bodyModel}
              options={asOptions(appearance.bodyModelOptions)}
              action="set_body_model"
            />
          )}
          <SelectRow
            label="Вид"
            value={appearance.species}
            options={appearance.speciesList || []}
            action="set_species"
          />
          <TextRow
            label="Кастомная раса"
            tooltip="Имя, показываемое вместо вида."
            value={appearance.customSpecies}
            action="set_custom_species"
          />
          <ToggleRow
            label="Продвинутая раскраска"
            tooltip="Отдельные цвета частей тела вместо общего оттенка."
            value={appearance.advancedColors}
            action="toggle_color_scheme"
          />
          {field('show_mismatched_markings')}
          {field('allow_emissives')}
          {field('be_random_body')}
          <Box mb={1}>
            <Button
              icon="dice"
              content="Случайное тело"
              onClick={() => act('randomize')}
            />
          </Box>
          <Box mb={1}>
            <Box>Модификация конечностей</Box>
            <Button
              icon="wrench"
              content="Изменить"
              onClick={() => act('modify_limbs')}
            />
          </Box>
          {asArray(appearance.modifiedLimbs).map((limb) => (
            <Box key={limb.name} color="label">
              {limb.name}: {limb.kind}
              {limb.extra ? ` (${limb.extra})` : ''}
            </Box>
          ))}
          {(appearance.bodySprites || []).length > 0 && (
            <SelectRow
              label="Спрайт тела"
              value={appearance.bodySprite}
              options={appearance.bodySprites || []}
              action="set_body_sprite"
            />
          )}
        </Section>

        <Section title="Цвет тела и размер">
          {!!appearance.useSkintones && (
            <>
              <SelectRow
                label="Тон кожи"
                value={
                  appearance.useCustomSkinTone ? 'custom' : appearance.skinTone
                }
                options={appearance.skinToneOptions || []}
                action="set_skin_tone"
              />
              {!!appearance.useCustomSkinTone && (
                <ColorField
                  label="Цвет тона"
                  value={appearance.skinTone}
                  action="set_skin_tone"
                />
              )}
            </>
          )}
          {fieldIf(appearance.hasMutantColors, 'mcolor')}
          {fieldIf(appearance.hasMutantColors, 'mcolor2')}
          {fieldIf(appearance.hasMutantColors, 'mcolor3')}
          {fieldIf(
            appearance.hasMutantColors && appearance.useSkintones,
            'genitals_use_skintone'
          )}
          {fieldIf(appearance.hasMutantColors, 'body_size')}
          {fieldIf(appearance.hasMutantColors, 'normalized_size')}
          {fieldIf(appearance.hasMutantColors, 'fuzzy')}
          {!!appearance.hasMutantColors && (
            <>
              <SelectRow
                label="Вес персонажа"
                tooltip={
                  appearance.weightLocked
                    ? 'Квирк «Пожиратель» несовместим с любым весом, кроме стандартного.'
                    : (appearance.weightOptions || {})[appearance.bodyWeight]
                }
                value={appearance.bodyWeight}
                options={weightNames}
                action="set_body_weight"
              />
              {!!appearance.weightLocked && (
                <Box color="label" italic mb={1}>
                  Сейчас действует вес «средний».
                </Box>
              )}
            </>
          )}
        </Section>

        <Section title="Глаза и волосы">
          {!!appearance.hasEyes && (
            <>
              <SelectRow
                label="Форма глаз"
                value={appearance.eyeType}
                options={appearance.eyeTypes || []}
                action="set_eye_type"
              />
              <ToggleRow
                label="Светящиеся глаза"
                value={appearance.eyesGlow}
                action="toggle_emissive_part"
                params={{ part: 'eyes' }}
              />
              {!!appearance.hasEyecolor &&
                (values.split_eye_colors ? (
                  <>
                    {field('split_eye_colors')}
                    {field('left_eye_color')}
                    {field('right_eye_color')}
                  </>
                ) : (
                  <>
                    {field('split_eye_colors')}
                    <ColorField
                      label="Цвет глаз"
                      value={values.left_eye_color as string}
                      action="set_eye_color"
                    />
                  </>
                ))}
            </>
          )}
          {!!appearance.hasHair && (
            <>
              <HairStyleRow
                label="Причёска"
                kind="hair"
                style={appearance.hairStyle}
              />
              {field('hair_color')}
              <HairStyleRow
                label="Борода"
                kind="facial"
                style={appearance.facialHairStyle}
              />
              {field('facial_hair_color')}
              <HairStyleRow
                label="Градиент"
                kind="grad"
                style={appearance.gradStyle}
              />
              {field('grad_color')}
            </>
          )}
        </Section>
      </SettingsGrid>

      <Section title="Части тела" mt={1}>
        <SettingsGrid compact>
          {asArray(appearance.mutantParts).map((part) => (
            <MutantPartCard key={part.key} part={part} />
          ))}
        </SettingsGrid>
      </Section>

      {appearance.genitals && (
        <GenitalsSection
          genitals={appearance.genitals}
          skinTone={
            appearance.useSkintones ? (appearance.skinTone as string) : null
          }
        />
      )}
    </Section>
  );
};

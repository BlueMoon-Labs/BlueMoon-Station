import { useBackend } from '../../../backend';
import {
  Box,
  Button,
  Collapsible,
  Icon,
  Input,
  NumberInput,
  Section,
  Stack,
} from '../../../components';
import {
  asArray,
  asOptions,
  ColorField,
  FeatureField,
  FieldRow,
  QuirkNames,
  renderFeatureField,
  SelectOption,
  SelectRow,
  SettingsGrid,
  TabDataMissing,
  ToggleRow,
} from '../components';

interface CustomNameEntry {
  id: string;
  label: string;
  hint: string;
  value: string | null;
}

interface GeneralData {
  name: string;
  nameless: boolean;
  age: number;
  beRandomName: boolean;
  hideCkey: boolean;
  customBloodColor: boolean;
  bloodColor: string;
  hardsuitWithTail: boolean;
  secDept: string;
  aiCoreDisplay: string;
  pdaColor: string;
  pdaStyle: string;
  pdaSkin: string;
  pdaRingtone: string;
  pdaTheme: string;
  pdaThemeLabel: string;
  siliconLawset: string | null;
  siliconLawTitle?: string;
  siliconLaws?: string[];
  quirkBalance?: number;
  quirks?: string[];
  quirkValues?: Record<string, number>;
  customNames: CustomNameEntry[];
}

interface GeneralOptions {
  securityDepts: string[];
  aiCoreScreens: string[];
  pdaStyles: string[];
  pdaReskins: string[];
  pdaThemes: { label: string; value: string }[];
  lawsets: string[];
}

interface AntagLevel {
  value: number;
  name: string;
  color: string;
  description?: string;
}

interface AntagOptIn {
  level: number;
  custom: boolean;
  levels: AntagLevel[];
  thresholds: string;
  disclaimer: string;
  forced?: { name: string; color: string } | null;
}

interface AppearanceSlice {
  values: Record<string, string | number | boolean>;
  jumpsuitStyle: string;
  jumpsuitStyles: SelectOption[];
  hasScars: boolean;
  hasPuddleSlime: boolean;
  puddleSlime: boolean;
  antagOptIn?: AntagOptIn;
}

interface GeneralContext {
  general: GeneralData;
  options: GeneralOptions;
  appearance?: AppearanceSlice;
  featureFields?: FeatureField[];
  ageMin: number;
  ageMax: number;
  quirksEnabled: boolean;
  siliconLawsDisabled: boolean;
}

const CONSENT_KEYS = [
  'erppref',
  'nonconpref',
  'vorepref',
  'mobsexpref',
  'tattoopref',
  'unholypref',
  'unholyhardpref',
  'extremepref',
  'extremeharm',
];

const PERSONAL_KEYS = [
  'lust_tolerance',
  'sexual_potency',
  'virility',
  'fertility',
  'inert_eggs',
  'pregnancy_inflation',
  'pregnancy_breast_growth',
  'egg_shell',
];

const SettingsSection = (props: {
  title: string;
  icon: string;
  children: React.ReactNode;
}) => (
  <Section className="CharacterSetup__card">
    <Box className="CharacterSetup__card-title">
      <Icon name={props.icon} /> {props.title}
    </Box>
    {props.children}
  </Section>
);

const ConsentRow = (props: { field: FeatureField; value: unknown }) => {
  const { act } = useBackend<GeneralContext>();
  const { field, value } = props;
  const states = {
    Yes: { icon: 'check', color: 'green', label: 'Да' },
    Ask: { icon: 'question', color: 'yellow', label: 'Спросить' },
    No: { icon: 'times', color: 'red', label: 'Нет' },
  };

  return (
    <div data-search-id={field.key}>
      <FieldRow label={field.label} tooltip={field.hint}>
        <Stack align="center">
          {asOptions(field.options).map((option) => {
            const choice = typeof option === 'string' ? option : option.value;
            const state = states[choice as keyof typeof states];
            return (
              <Stack.Item key={choice}>
                <Button
                  width="2.2em"
                  textAlign="center"
                  icon={state.icon}
                  color={value === choice ? state.color : 'default'}
                  tooltip={state.label}
                  aria-label={`${field.label}: ${state.label}`}
                  aria-pressed={value === choice}
                  onClick={() => act('set_feature', { key: field.key, value: choice })}
                />
              </Stack.Item>
            );
          })}
        </Stack>
      </FieldRow>
    </div>
  );
};

export const GeneralTab = () => {
  const { act, data } = useBackend<GeneralContext>();

  const general = data.general;
  const options = data.options || ({} as GeneralOptions);
  const appearance = data.appearance;
  const fields = data.featureFields || [];

  if (!general) {
    return <TabDataMissing title="Общее" />;
  }

  const values = appearance?.values || {};
  const field = (key: string) => renderFeatureField(fields, values, key);

  const antag = appearance?.antagOptIn;
  const currentLevel = asArray(antag?.levels).find(
    (level) => level.value === antag?.level
  );

  return (
    <Section fill scrollable className="CharacterSetup__general">
      <QuirksSummary />

      <SettingsGrid>
        <SettingsSection title="Личность" icon="id-card">
          <NameRow />
          <FieldRow label="Возраст">
            <NumberInput
              value={general.age}
              minValue={data.ageMin}
              maxValue={data.ageMax}
              width="90px"
              onChange={(e, value) => act('set_age', { age: value })}
            />
          </FieldRow>
          <ToggleRow
            label="Без имени"
            tooltip="Имя генерируется автоматически по роли"
            value={general.nameless}
            action="toggle_nameless"
          />
          <ToggleRow
            label="Всегда случайное имя"
            value={general.beRandomName}
            action="toggle_random_name"
          />
          <ToggleRow
            label="Скрывать ckey"
            tooltip="Не показывать ckey в конце раунда"
            value={general.hideCkey}
            action="toggle_hide_ckey"
          />
          <ToggleRow
            label="Свой цвет крови"
            value={general.customBloodColor}
            action="toggle_custom_blood_color"
          />
          <ColorField
            label="Цвет крови"
            value={general.bloodColor}
            action="set_blood_color"
            disabled={!general.customBloodColor}
          />
          <ToggleRow
            label="Скафандр поверх хвоста"
            tooltip="Хвост остаётся виден поверх надетого скафандра."
            value={general.hardsuitWithTail}
            action="toggle_hardsuit_with_tail"
          />
        </SettingsSection>

        <SettingsSection title="Профессии" icon="briefcase">
          <Button
            fluid
            icon="briefcase"
            content="Настройка профессий"
            onClick={() => act('open_jobs')}
          />
          <SelectRow
            label="Отдел охраны"
            tooltip="Отдел, за который вы играете офицером брига"
            value={general.secDept}
            options={options.securityDepts || []}
            action="set_sec_dept"
          />
          <SelectRow
            label="Экран ядра ИИ"
            value={general.aiCoreDisplay}
            options={options.aiCoreScreens || []}
            action="set_ai_core"
          />
        </SettingsSection>
        <SettingsSection title="Особые имена" icon="tags">
          {(general.customNames || []).map((entry) => (
            <FieldRow key={entry.id} label={entry.label} tooltip={entry.hint}>
              <Input
                width="100%"
                value={entry.value || ''}
                onChange={(e, value) =>
                  act('set_custom_name', { id: entry.id, value })
                }
              />
            </FieldRow>
          ))}
        </SettingsSection>

        <SettingsSection title="КПК" icon="tablet-alt">
          <ColorField
            label="Цвет интерфейса КПК"
            value={general.pdaColor}
            action="set_pda_color"
          />
          <SelectRow
            label="Стиль КПК"
            value={general.pdaStyle}
            options={options.pdaStyles || []}
            action="set_pda_style"
          />
          <SelectRow
            label="Модель КПК"
            value={general.pdaSkin}
            options={options.pdaReskins || []}
            action="set_pda_skin"
          />
          <FieldRow label="Рингтон КПК">
            <Input
              width="100%"
              value={general.pdaRingtone || ''}
              onChange={(e, value) => act('set_pda_ringtone', { value })}
            />
          </FieldRow>
          <SelectRow
            label="Тема КПК"
            value={general.pdaTheme}
            options={options.pdaThemes || []}
            action="set_pda_theme"
          />
        </SettingsSection>
        <SettingsSection title="Синтетики" icon="robot">
          {!!data.siliconLawsDisabled && (
            <Box color="label" italic mb={1}>
              Сервер запретил выбирать собственные законы: выбор сохранится, но
              в игре не будет действовать.
            </Box>
          )}
          <SelectRow
            label="Свод законов"
            value={general.siliconLawset || 'None'}
            options={options.lawsets || []}
            action="set_silicon_lawset"
          />
          {!!general.siliconLaws?.length && (
            <Collapsible title={general.siliconLawTitle || 'Текст законов'}>
              {(general.siliconLaws || []).map((law, index) => (
                <Box key={index} mb={1}>
                  {law}
                </Box>
              ))}
            </Collapsible>
          )}
        </SettingsSection>

        <SettingsSection title="Одежда и снаряжение" icon="tshirt">
          {field('backbag')}
          {field('uplink_spawn_loc')}
          <SelectRow
            label="Стиль комбинезона"
            value={appearance?.jumpsuitStyle}
            options={appearance?.jumpsuitStyles || []}
            action="set_jumpsuit"
          />
          {!!appearance?.hasScars && (
            <>
              {field('persistent_scars')}
              <Box mb={1}>
                <Button
                  icon="trash"
                  content="Очистить шрамы"
                  onClick={() => act('clear_scars')}
                />
              </Box>
            </>
          )}
          {!!appearance?.hasPuddleSlime && (
            <ToggleRow
              label="Капля слизи"
              tooltip="Оставлять за собой слизистый след."
              value={appearance.puddleSlime}
              action="set_puddle_slime"
            />
          )}
        </SettingsSection>

        <SettingsSection title="Согласие" icon="handshake">
          {CONSENT_KEYS.map((key) => {
            const consent = fields.find((entry) => entry.key === key);
            return consent ? <ConsentRow key={key} field={consent} value={values[key]} /> : null;
          })}
          {!!antag && (
            <>
              <SelectRow
                label="Задания антагов"
                tooltip={antag.disclaimer}
                value={antag.level}
                options={asArray(antag.levels).map((level) => ({
                  value: level.value,
                  displayText: antag.custom
                    ? level.name
                    : `${level.name}`,
                }))}
                action="set_antag_opt_in"
              />
              {!!currentLevel?.description && (
                <Box color="label" mb={1}>
                  {currentLevel.description}
                </Box>
              )}
              <Box color="label" mb={1}>
                {antag.thresholds}
              </Box>
              {!!antag.forced && (
                <Box color={antag.forced.color} mb={1}>
                  В раунде не ниже «{antag.forced.name}»: включены антаг-роли
                </Box>
              )}
            </>
          )}
        </SettingsSection>

        <SettingsSection title="Секс и беременность" icon="heart">
          {PERSONAL_KEYS.map((key) => field(key))}
        </SettingsSection>
      </SettingsGrid>
    </Section>
  );
};

const NameRow = () => {
  const { act, data } = useBackend<GeneralContext>();
  const general = data.general;

  return (
    <FieldRow label={general?.nameless ? 'Обозначение' : 'Имя'}>
      <Stack align="center" style={{ width: '100%' }}>
        <Stack.Item grow>
          <Input
            width="100%"
            value={general?.name || ''}
            onChange={(e, value) => act('set_name', { name: value })}
          />
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="dice"
            tooltip="Случайное имя"
            onClick={() => act('random_name')}
          />
        </Stack.Item>
      </Stack>
    </FieldRow>
  );
};

const QuirksSummary = () => {
  const { act, data } = useBackend<GeneralContext>();

  if (!data.quirksEnabled) {
    return null;
  }

  const general = data.general;
  const quirks = general?.quirks || [];

  return (
    <Section>
      <Stack align="center">
        <Stack.Item>
          <Box>
            Баланс очков: <b>{general?.quirkBalance ?? 0}</b>
          </Box>
        </Stack.Item>
        <Stack.Item grow basis={0}>
          <Box
            color="label"
            style={{ overflowWrap: 'anywhere' }}
          >
            {quirks.length ? (
              <QuirkNames names={quirks} values={general?.quirkValues} />
            ) : (
              'Особенности не выбраны'
            )}
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="brain"
            content="Настроить"
            onClick={() => act('set_tab', { tab: 6 })}
          />
        </Stack.Item>
      </Stack>
    </Section>
  );
};

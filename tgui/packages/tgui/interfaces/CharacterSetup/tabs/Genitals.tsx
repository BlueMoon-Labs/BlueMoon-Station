import { useBackend } from '../../../backend';
import { Box, Dropdown, Section } from '../../../components';
import {
  ColorField,
  FeatureField,
  FeatureFieldView,
  FieldRow,
  SettingsGrid,
  ToggleRow,
} from '../components';

export interface GenitalPart {
  key: string;
  label: string;
  activeKey: string;
  active: boolean;
  glow: boolean;
  subGlowKey?: string;
  subGlow?: boolean;
  fields: string[];
}

export interface GenitalData {
  supported: boolean;
  colorOverride?: boolean;
  cockShape?: { value: string; options: string[] };
  parts: GenitalPart[];
  hasNeckfire: boolean;
  neckfire: boolean;
}

interface GenitalsContext {
  appearance?: { values?: Record<string, unknown> };
  featureFields?: FeatureField[];
}

export const GenitalsSection = (props: {
  genitals: GenitalData;
  skinTone: string | null;
}) => {
  const { act, data } = useBackend<GenitalsContext>();
  const fields = data.featureFields || [];
  const values = (data.appearance?.values || {}) as Record<string, unknown>;
  const { genitals, skinTone } = props;

  if (!genitals.supported) {
    return (
      <Section title="Гениталии">
        <Box color="label">Ваш вид не поддерживает гениталии.</Box>
      </Section>
    );
  }

  const renderField = (key: string) => {
    const field = fields.find((entry) => entry.key === key);
    if (!field) {
      return null;
    }
    if (genitals.colorOverride && field.type === 'color') {
      return (
        <ColorField
          key={key}
          label={field.label}
          value={skinTone}
          disabled
          disabledNote="тон кожи"
          tooltip="Цвет берётся из текущего тона кожи."
        />
      );
    }
    return <FeatureFieldView key={key} field={field} value={values[key]} />;
  };

  return (
    <Section title="Гениталии">
      <SettingsGrid compact>
        {(genitals.parts || []).map((part) => (
          <Box
            key={part.key}
            p={1}
            style={{
              border: '1px solid rgba(255,255,255,0.15)',
              borderRadius: '2px',
            }}
          >
            <Box mb={1}>
              <b>{part.label}</b>
            </Box>
            <ToggleRow
              label="Свечение"
              value={part.glow}
              action="toggle_emissive_part"
              params={{ part: part.key }}
              onLabel="Да"
              offLabel="Нет"
            />
            {renderField(part.activeKey)}
            {!!part.active &&
              part.fields.map((key) => {
                if (key === 'cock_shape' && genitals.cockShape) {
                  return (
                    <FieldRow key={key} label="Форма пениса">
                      <Dropdown
                        width="100%"
                        options={genitals.cockShape.options || []}
                        selected={genitals.cockShape.value || ''}
                        onSelected={(next) =>
                          act('set_cock_shape', { value: next })
                        }
                      />
                    </FieldRow>
                  );
                }
                if (key === 'anus_glow') {
                  return (
                    <ToggleRow
                      key={key}
                      label="Свечение ануса"
                      value={!!part.subGlow}
                      action="toggle_emissive_part"
                      params={{ part: part.subGlowKey }}
                    />
                  );
                }
                return <Box key={key}>{renderField(key)}</Box>;
              })}
          </Box>
        ))}
      </SettingsGrid>

      {!!genitals.hasNeckfire && (
        <Box
          mt={1}
          p={1}
          style={{
            border: '1px solid rgba(255,255,255,0.15)',
            borderRadius: '2px',
          }}
        >
          <Box mb={1}>
            <b>Огонь шеи</b>
          </Box>
          {renderField('neckfire')}
          {!!genitals.neckfire && renderField('neckfire_color')}
        </Box>
      )}
    </Section>
  );
};

import { useBackend } from '../../../backend';
import {
  Box,
  Button,
  Icon,
  NoticeBox,
  NumberInput,
  Section,
  Stack,
} from '../../../components';
import {
  ColorField,
  FieldRow,
  SelectOption,
  SelectRow,
  SettingsGrid,
  TabDataMissing,
  ToggleRow,
} from '../components';

interface BarkData {
  valid: boolean;
  id?: string;
  name?: string;
  speed?: number;
  pitch?: number;
  variance?: number;
  minSpeed?: number;
  maxSpeed?: number;
  minPitch?: number;
  maxPitch?: number;
  minVariance?: number;
  maxVariance?: number;
  options?: SelectOption[];
}

interface LanguageOption {
  name: string;
  desc?: string;
  selected: boolean;
}

interface SpeechData {
  verb: string;
  verbOptions: SelectOption[];
  verbRu: boolean;
  tongue: string;
  tongueOptions: SelectOption[];
  laugh: string;
  laughOptions: SelectOption[];
  laughPreviewable: boolean;
  chatColorEnabled: boolean;
  chatColor: string;
  maxLanguages: number;
  languages: LanguageOption[];
  bark: BarkData;
  deathsound: string | null;
  deathsounds: string[];
}

interface SpeechContext {
  speech?: SpeechData;
  languageIcons?: Record<string, string>;
}

const BarkNumberRow = (props: {
  label: string;
  value: number;
  min: number;
  max: number;
  step: number;
  barkKey: string;
  tooltip?: string;
}) => {
  const { act } = useBackend<SpeechContext>();
  const { label, value, min, max, step, barkKey, tooltip } = props;
  return (
    <FieldRow label={label} tooltip={tooltip}>
      <NumberInput
        width="100%"
        value={value}
        minValue={min}
        maxValue={max}
        step={step}
        format={(val: number) => val.toFixed(step < 1 ? 2 : 0)}
        onChange={(e, next) =>
          act('set_bark_number', { key: barkKey, value: next })
        }
      />
    </FieldRow>
  );
};

const LanguageToggle = (props: { language: LanguageOption; icon?: string }) => {
  const { act } = useBackend<SpeechContext>();
  const { language, icon } = props;
  const selected = !!language.selected;
  return (
    <Box
      p={1}
      onClick={() => act('toggle_language', { value: language.name })}
      style={{
        border:
          '1px solid ' +
          (selected
            ? 'rgba(120, 205, 148, 0.55)'
            : 'rgba(255, 255, 255, 0.12)'),
        borderRadius: '3px',
        backgroundColor: selected
          ? 'rgba(70, 165, 108, 0.14)'
          : 'rgba(0, 0, 0, 0.18)',
        cursor: 'pointer',
      }}
    >
      <Stack align="center">
        <Stack.Item>
          {icon ? (
            <Box
              as="img"
              src={`data:image/png;base64,${icon}`}
              style={{
                width: '32px',
                height: '32px',
                imageRendering: 'pixelated',
              }}
            />
          ) : (
            <Icon name="language" size="1.5em" />
          )}
        </Stack.Item>
        <Stack.Item grow>
          <Box bold>{language.name}</Box>
        </Stack.Item>
        <Stack.Item>
          <Icon
            name={selected ? 'check-square-o' : 'square-o'}
            color={selected ? 'good' : 'label'}
          />
        </Stack.Item>
      </Stack>
      <Box color="label" fontSize="0.9em" mt={0.5}>
        {language.desc || 'Описание отсутствует.'}
      </Box>
    </Box>
  );
};

export const SpeechTab = () => {
  const { act, data } = useBackend<SpeechContext>();
  const speech = data.speech;

  if (!speech) {
    return <TabDataMissing title="Речь" />;
  }

  const bark: BarkData = speech.bark || { valid: false };
  const languagesOff = speech.maxLanguages === 0;

  const languageIcons = data.languageIcons || {};
  const languages = speech.languages || [];

  return (
    <Section fill scrollable title="Речь">
      <SettingsGrid>
        <Section title="Речевые предпочтения">
          <SelectRow
            label="Глагол речи"
            tooltip="«Обычный» означает глагол вашего вида."
            value={speech.verb}
            options={speech.verbOptions || []}
            action="set_speech_verb"
          />
          <ToggleRow
            label="Использовать русские глаголы"
            value={speech.verbRu}
            action="toggle_speech_verb_ru"
          />
          <SelectRow
            label="Акцент"
            tooltip="«Обычный» означает акцент вашего вида."
            value={speech.tongue}
            options={speech.tongueOptions || []}
            action="set_tongue"
          />
          <SelectRow
            label="Смех"
            value={speech.laugh}
            options={speech.laughOptions || []}
            action="set_laugh"
            extra={
              <Button
                icon="volume-up"
                tooltip="Прослушать смех"
                disabled={!speech.laughPreviewable}
                onClick={() => act('preview_laugh')}
              />
            }
          />
          <ToggleRow
            label="Свой цвет руначата"
            value={speech.chatColorEnabled}
            action="toggle_personal_chat_color"
          />
          {!!speech.chatColorEnabled && (
            <ColorField
              label="Цвет руначата"
              value={speech.chatColor}
              action="set_personal_chat_color"
            />
          )}
        </Section>

        <Section title="Голос">
          {!bark.valid ? (
            <NoticeBox>
              Звук речи из сейва больше не существует - выберите другой.
            </NoticeBox>
          ) : (
            <SelectRow
              label="Звук голоса"
              value={bark.id}
              options={bark.options || []}
              action="set_bark_sound"
              extra={
                <Button
                  icon="volume-up"
                  tooltip="Прослушать звук"
                  onClick={() => act('preview_bark')}
                />
              }
            />
          )}
          {!!bark.valid && (
            <>
              <BarkNumberRow
                label="Скорость голоса"
                tooltip="Значение выше - медленная речь, ниже - быстрая."
                value={bark.speed || 0}
                min={bark.minSpeed || 0}
                max={bark.maxSpeed || 0}
                step={1}
                barkKey="speed"
              />
              <BarkNumberRow
                label="Высота голоса"
                value={bark.pitch || 0}
                min={bark.minPitch || 0}
                max={bark.maxPitch || 0}
                step={0.1}
                barkKey="pitch"
              />
              <BarkNumberRow
                label="Разброс голоса"
                value={bark.variance || 0}
                min={bark.minVariance || 0}
                max={bark.maxVariance || 0}
                step={0.1}
                barkKey="variance"
              />
            </>
          )}
          <SelectRow
            label="Звук смерти"
            value={speech.deathsound || 'По умолчанию'}
            options={speech.deathsounds || []}
            action="set_deathsound"
            extra={
              <Button
                icon="volume-up"
                tooltip="Прослушать звук смерти"
                onClick={() => act('preview_deathsound')}
              />
            }
          />
        </Section>
      </SettingsGrid>

      <Section title="Дополнительные языки" mt={1}>
        {languagesOff ? (
          <Box color="label">Дополнительные языки отключены.</Box>
        ) : (
          <>
            {speech.maxLanguages > 0 && (
              <Box color="label" mb={1}>
                Можно выбрать не более {speech.maxLanguages}. Языки сверх лимита
                отключатся при сохранении.
              </Box>
            )}
            <SettingsGrid>
              {languages.map((language) => (
                <LanguageToggle
                  key={language.name}
                  language={language}
                  icon={languageIcons[language.name]}
                />
              ))}
            </SettingsGrid>
            <Box mt={1}>
              <Button
                icon="undo"
                color="bad"
                content="Сбросить языки"
                onClick={() => act('reset_languages')}
              />
            </Box>
          </>
        )}
      </Section>
    </Section>
  );
};

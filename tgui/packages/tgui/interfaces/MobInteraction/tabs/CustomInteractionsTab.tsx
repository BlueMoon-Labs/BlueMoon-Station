
import { useBackend, useLocalState } from '../../../backend';
import { Box, Button, Collapsible, Divider, Dropdown, Input, NoticeBox, Section, Stack, TextArea } from '../../../components';

type CustomInteractionData = {
  key: string;
  name: string;
  message: string;
  interaction_type: string;
  type_label: string;
  arousal_level: number;
  arousal_label: string;
  self_arousal_organ: string;
  partner_arousal_level: number;
  partner_arousal_label: string;
  partner_arousal_organ: string;
  self_orgasm: boolean | 0 | 1;
  partner_orgasm: boolean | 0 | 1;
  self_orgasm_organ: string;
  partner_orgasm_organ: string;
  self_orgasm_target: string;
  partner_orgasm_target: string;
  scope: string;
  scope_label: string;
  self_required_body_parts: number;
  partner_required_body_parts: number;
  self_requires_tail: boolean | 0 | 1;
  partner_requires_tail: boolean | 0 | 1;
  self_requires_telekinesis: boolean | 0 | 1;
  partner_requires_telekinesis: boolean | 0 | 1;
  max_distance: number;
  sound_keys: string[];
  sound_labels: string[];
}

type CustomSoundOption = {
  key: string;
  label: string;
  group: string;
}

type MoanSoundOption = {
  key: string;
  label: string;
  group: string;
}

type BodyPartOption = {
  flag: number;
  label: string;
};

type EffectTargetOption = {
  value: string;
  displayText: string;
  flag: number;
};

type ParticipantSettings = {
  arousalLevel: number;
  arousalOrgan: string;
  orgasm: boolean;
  orgasmOrgan: string;
  orgasmTarget: string;
  bodyParts: number;
  requiresTail: boolean;
  requiresTelekinesis: boolean;
};

type CustomTabInfo = {
  own_custom_interactions: CustomInteractionData[];
  max_custom_interactions: number;
  custom_interaction_sounds: CustomSoundOption[];
  custom_interaction_body_parts: BodyPartOption[];
  custom_interaction_arousal_organs: EffectTargetOption[];
  custom_interaction_orgasm_organs: EffectTargetOption[];
  custom_interaction_orgasm_targets: EffectTargetOption[];
  moan_sound_catalogs: { male: MoanSoundOption[]; female: MoanSoundOption[] };
  feminine_moan_sounds: boolean;
  custom_moan_sounds: string[];
  use_custom_moan_sounds: boolean;
}

const MAX_NAME_LENGTH = 100;
const MAX_MESSAGE_LENGTH = 500;
const DEFAULT_PARTICIPANT_SETTINGS: ParticipantSettings = {
  arousalLevel: 0,
  arousalOrgan: 'general',
  orgasm: false,
  orgasmOrgan: 'auto',
  orgasmTarget: 'floor',
  bodyParts: 0,
  requiresTail: false,
  requiresTelekinesis: false,
};

const INTERACTION_TYPES = [
  { id: 'normal', label: 'Действие', desc: 'Обычное действие, без специальных проверок контента.' },
  { id: 'lewd', label: 'Эротика', desc: 'Требует согласие на левд-интеракты (как обычные левд-действия).' },
  { id: 'extreme', label: 'Тяжёлое', desc: 'Требует согласие на extreme-контент.' },
  { id: 'unholy', label: 'Грязное', desc: 'Требует согласие на extreme и unholy-контент.' },
];

const AROUSAL_LEVELS = [
  { id: 0, label: 'Нет', icon: 'heart-circle-xmark', tooltip: 'Нет возбуждения' },
  { id: 1, label: 'Малое', icon: 'heart-o', tooltip: 'Малое возбуждение (+6)' },
  { id: 2, label: 'Среднее', icon: 'heart', tooltip: 'Среднее возбуждение (+14)' },
  { id: 3, label: 'Сильное', icon: 'heart-circle-bolt', tooltip: 'Сильное возбуждение (+28)' },
];

const MAX_DISTANCES = [
  { id: 1, label: '1 тайл', desc: 'Вплотную, как обычное действие.' },
  { id: 2, label: '2 тайла', desc: 'Можно применить на расстоянии до двух тайлов.' },
  { id: 3, label: '3 тайла', desc: 'Можно применить на расстоянии до трёх тайлов.' },
];

const SPECIAL_SOUND_GROUP = 'Unholy';
const NORMAL_TYPE_SOUND_GROUPS = ['Прочее', 'Объятия и поцелуи', 'Мурлыканье'];

const SCOPES = [
  { id: 'both', label: 'На обоих', desc: 'Интеракцию можно использовать и на себе, и на других.' },
  { id: 'self', label: 'На себе', desc: 'Интеракция доступна только на самом персонаже.' },
  { id: 'others', label: 'Только на других', desc: 'Интеракцию можно использовать только на других.' },
];

type FormRowProps = {
  label: string;
  children: any;
}

const FormRow = (props: FormRowProps) => (
  <Stack>
    <Stack.Item width="40%">
      <Box color="label" nowrap>{props.label}</Box>
    </Stack.Item>
    <Stack.Item grow>
      {props.children}
    </Stack.Item>
  </Stack>
);

type EffectsProps = {
  settings: ParticipantSettings;
  onChange: (settings: ParticipantSettings) => void;
  arousalOrgans: EffectTargetOption[];
  orgasmOrgans: EffectTargetOption[];
  orgasmTargets: EffectTargetOption[];
  arousalLabel: string;
  orgasmLabel: string;
  destinationLabel: string;
};

const Effects = ({
  settings,
  onChange,
  arousalOrgans,
  orgasmOrgans,
  orgasmTargets,
  arousalLabel,
  orgasmLabel,
  destinationLabel,
}: EffectsProps) => (
  <Stack vertical>
    <Stack.Item>
      <FormRow label={arousalLabel}>
        {AROUSAL_LEVELS.map(level => (
          <Button
            key={level.id}
            icon={level.icon}
            color={level.id === settings.arousalLevel
              ? (level.id ? 'pink' : 'red')
              : 'transparent'}
            tooltip={level.tooltip}
            aria-label={level.label}
            aria-pressed={level.id === settings.arousalLevel}
            onClick={() => onChange({ ...settings, arousalLevel: level.id })}
          />
        ))}
      </FormRow>
    </Stack.Item>
    {!!settings.arousalLevel && (
      <Stack.Item>
        <FormRow label="Орган для возбуждения">
          <Dropdown
            fluid
            width="100%"
            options={arousalOrgans}
            selected={settings.arousalOrgan}
            onSelected={(arousalOrgan: string) => onChange({ ...settings, arousalOrgan })}
          />
        </FormRow>
      </Stack.Item>
    )}
    <Stack.Item>
      <FormRow label={orgasmLabel}>
        <Button
          icon={settings.orgasm ? 'toggle-on' : 'toggle-off'}
          color={settings.orgasm ? 'pink' : 'transparent'}
          content={settings.orgasm ? 'Разрешён' : 'Выключен'}
          onClick={() => onChange({ ...settings, orgasm: !settings.orgasm })}
        />
      </FormRow>
    </Stack.Item>
    {settings.orgasm && (
      <Stack.Item>
        <FormRow label="Орган для оргазма">
          <Dropdown
            fluid
            width="100%"
            options={orgasmOrgans}
            selected={settings.orgasmOrgan}
            onSelected={(orgasmOrgan: string) => onChange({ ...settings, orgasmOrgan })}
          />
        </FormRow>
      </Stack.Item>
    )}
    {settings.orgasm && (
      <Stack.Item>
        <FormRow label={destinationLabel}>
          <Dropdown
            fluid
            width="100%"
            options={orgasmTargets}
            selected={settings.orgasmTarget}
            onSelected={(orgasmTarget: string) => onChange({ ...settings, orgasmTarget })}
          />
        </FormRow>
      </Stack.Item>
    )}
  </Stack>
);

type BodyPartPickerProps = {
  label: string;
  parts: BodyPartOption[];
  selectedParts: number;
  lockedParts: number;
  onChange: (parts: number) => void;
};

const BodyPartPicker = ({
  label,
  parts,
  selectedParts,
  lockedParts,
  onChange,
}: BodyPartPickerProps) => (
  <Box>
    <Box color="label" mb={0.5}>{label}</Box>
    {parts.map(part => {
      const locked = !!(lockedParts & part.flag);
      const selected = locked || !!(selectedParts & part.flag);
      return (
        <Button
          key={part.flag}
          compact
          icon={locked ? 'lock' : selected ? 'check-square' : 'square-o'}
          color={locked ? 'red' : selected ? 'green' : 'transparent'}
          content={part.label}
          aria-disabled={locked}
          aria-pressed={selected}
          tooltip={locked ? 'Часть тела обязательна для выбранного эффекта' : undefined}
          onClick={locked ? undefined : () => onChange(selectedParts ^ part.flag)}
        />
      );
    })}
  </Box>
);

export const CustomInteractionsTab = (props) => {
  const { act, data } = useBackend<CustomTabInfo>();
  const [editingKey, setEditingKey] = useLocalState<string | null>('customEditingKey', null);
  const [creating, setCreating] = useLocalState('customCreating', false);
  const customs = data.own_custom_interactions || [];
  const max_customs = data.max_custom_interactions || 10;
  const sounds = data.custom_interaction_sounds || [];
  const bodyParts = data.custom_interaction_body_parts || [];
  const arousalOrgans = data.custom_interaction_arousal_organs || [];
  const orgasmOrgans = data.custom_interaction_orgasm_organs || [];
  const orgasmTargets = data.custom_interaction_orgasm_targets || [];
  const moanSounds = data.moan_sound_catalogs?.[
    data.feminine_moan_sounds ? 'female' : 'male'
  ] || [];
  const customMoanSounds = data.custom_moan_sounds || [];
  const useCustomMoanSounds = !!data.use_custom_moan_sounds;
  const [moanGroupBrowsing, setMoanGroupBrowsing] = useLocalState('customMoanSoundGroup', '');

  const [interactionType, setInteractionType] = useLocalState('customFormType', '');
  const [name, setName] = useLocalState('customFormName', '');
  const [message, setMessage] = useLocalState('customFormMessage', '');
  const [self, setSelf] = useLocalState('customFormSelf', DEFAULT_PARTICIPANT_SETTINGS);
  const [partner, setPartner] = useLocalState('customFormPartner', DEFAULT_PARTICIPANT_SETTINGS);
  const [scope, setScope] = useLocalState('customFormScope', 'others');
  const [maxDistance, setMaxDistance] = useLocalState('customFormDistance', 1);
  const [soundKeys, setSoundKeys] = useLocalState<string[]>('customFormSounds', []);
  const [soundGroupBrowsing, setSoundGroupBrowsing] = useLocalState('customFormSoundGroup', '');
  const requiresTelekinesis = self.requiresTelekinesis || partner.requiresTelekinesis;

  const editingCustom = editingKey
    ? customs.find(custom => custom.key === editingKey)
    : undefined;

  const startCreate = () => {
    setEditingKey(null);
    setCreating(true);
    setInteractionType('normal');
    setName('');
    setMessage('');
    setSelf(DEFAULT_PARTICIPANT_SETTINGS);
    setPartner(DEFAULT_PARTICIPANT_SETTINGS);
    setScope('others');
    setMaxDistance(1);
    setSoundKeys([]);
    setSoundGroupBrowsing(NORMAL_TYPE_SOUND_GROUPS[0]);
  };

  const startEdit = (custom: CustomInteractionData) => {
    setEditingKey(custom.key);
    setCreating(false);
    setInteractionType(custom.interaction_type);
    setName(custom.name);
    setMessage(custom.message);
    setSelf({
      arousalLevel: custom.arousal_level,
      arousalOrgan: custom.self_arousal_organ,
      orgasm: !!custom.self_orgasm,
      orgasmOrgan: custom.self_orgasm_organ,
      orgasmTarget: custom.self_orgasm_target,
      bodyParts: custom.self_required_body_parts,
      requiresTail: !!custom.self_requires_tail,
      requiresTelekinesis: !!custom.self_requires_telekinesis,
    });
    setPartner({
      arousalLevel: custom.partner_arousal_level,
      arousalOrgan: custom.partner_arousal_organ,
      orgasm: !!custom.partner_orgasm,
      orgasmOrgan: custom.partner_orgasm_organ,
      orgasmTarget: custom.partner_orgasm_target,
      bodyParts: custom.partner_required_body_parts,
      requiresTail: !!custom.partner_requires_tail,
      requiresTelekinesis: !!custom.partner_requires_telekinesis,
    });
    setScope(custom.scope || 'both');
    setMaxDistance((custom.self_requires_telekinesis || custom.partner_requires_telekinesis)
      ? custom.max_distance
      : 1);
    setSoundKeys(custom.sound_keys || []);
  };

  const save = () => {
    if (!interactionType || !name || !message) {
      return;
    }
    const payload = {
      interaction_type: interactionType,
      name,
      message,
      arousal_level: self.arousalLevel,
      partner_arousal_level: partner.arousalLevel,
      self_arousal_organ: self.arousalOrgan,
      partner_arousal_organ: partner.arousalOrgan,
      self_orgasm: self.orgasm ? 1 : 0,
      partner_orgasm: partner.orgasm ? 1 : 0,
      self_orgasm_organ: self.orgasmOrgan,
      partner_orgasm_organ: partner.orgasmOrgan,
      self_orgasm_target: self.orgasmTarget,
      partner_orgasm_target: partner.orgasmTarget,
      scope,
      self_required_body_parts: self.bodyParts,
      partner_required_body_parts: partner.bodyParts,
      self_requires_tail: self.requiresTail ? 1 : 0,
      partner_requires_tail: partner.requiresTail ? 1 : 0,
      self_requires_telekinesis: self.requiresTelekinesis ? 1 : 0,
      partner_requires_telekinesis: partner.requiresTelekinesis ? 1 : 0,
      max_distance: requiresTelekinesis ? maxDistance : 1,
      sound_keys: soundKeys,
    };
    if (editingCustom) {
      act('custom_edit', { key: editingCustom.key, ...payload });
    }
    else {
      act('custom_create', payload);
    }
    setEditingKey(null);
    setCreating(false);
  };

  const cancelForm = () => {
    setEditingKey(null);
    setCreating(false);
  };

  const selectedType = INTERACTION_TYPES.find(type => type.id === interactionType);
  const selectedScope = SCOPES.find(s => s.id === scope);
  const selectedDistance = MAX_DISTANCES.find(distance =>
    distance.id === (requiresTelekinesis ? maxDistance : 1));
  const browsableSounds = sounds.filter(sound => sound.key !== 'none');
  const visibleSoundGroups = [...new Set(
    browsableSounds
      .filter(sound => sound.group !== SPECIAL_SOUND_GROUP || interactionType === 'unholy')
      .filter(sound => interactionType !== 'normal' || NORMAL_TYPE_SOUND_GROUPS.includes(sound.group))
      .map(sound => sound.group)
  )];
  const effectiveBrowsingGroup = visibleSoundGroups.includes(soundGroupBrowsing)
    ? soundGroupBrowsing
    : visibleSoundGroups[0];
  const soundsInGroup = browsableSounds.filter(sound => sound.group === effectiveBrowsingGroup);
  const selectedSounds = soundKeys
    .map(key => sounds.find(sound => sound.key === key))
    .filter(Boolean) as CustomSoundOption[];
  const canSave = !!interactionType && !!name && !!message;

  const moanGroups = [...new Set(moanSounds.map(sound => sound.group))];
  const effectiveMoanGroup = moanGroups.includes(moanGroupBrowsing)
    ? moanGroupBrowsing
    : moanGroups[0];
  const moanSoundsInGroup = moanSounds.filter(sound => sound.group === effectiveMoanGroup);
  const selectedMoanSounds = moanSounds.filter(sound => customMoanSounds.includes(sound.key));

  const toggleMoanSound = (key: string) => {
    const nextKeys = customMoanSounds.includes(key)
      ? customMoanSounds.filter(sound => sound !== key)
      : [...customMoanSounds, key];
    act('set_custom_moan_sounds', { sound_keys: nextKeys });
  };

  const getLockedBodyParts = (settings: ParticipantSettings, other: ParticipantSettings) => {
    const arousalPart = settings.arousalLevel
      ? arousalOrgans.find(option => option.value === settings.arousalOrgan)?.flag
      : 0;
    const orgasmOrgan = settings.orgasm
      ? orgasmOrgans.find(option => option.value === settings.orgasmOrgan)?.flag
      : 0;
    const orgasmTarget = other.orgasm
      ? orgasmTargets.find(option => option.value === other.orgasmTarget)?.flag
      : 0;
    return (arousalPart || 0) | (orgasmOrgan || 0) | (orgasmTarget || 0);
  };

  const selfLockedParts = getLockedBodyParts(self, partner);
  const partnerLockedParts = getLockedBodyParts(partner, self);
  const selfPartCount = bodyParts.filter(part => (self.bodyParts | selfLockedParts) & part.flag).length;
  const partnerPartCount = bodyParts.filter(part => (partner.bodyParts | partnerLockedParts) & part.flag).length;

  const renderForm = () => (
    <Stack vertical>
      <Stack.Item>
        <Section title="Основное">
          <Stack vertical>
            <Stack.Item>
              <FormRow label="Тип взаимодействия:">
                <Dropdown
                  fluid
                  width="100%"
                  options={INTERACTION_TYPES.map(type => type.label)}
                  selected={selectedType?.label}
                  displayText={selectedType?.label || 'Выбери тип...'}
                  onSelected={(label) => {
                    const found = INTERACTION_TYPES.find(type => type.label === label);
                    setInteractionType(found ? found.id : '');
                  }}
                />
              </FormRow>
            </Stack.Item>
            {selectedType && (
              <Stack.Item>
                <NoticeBox info>{selectedType.desc}</NoticeBox>
              </Stack.Item>
            )}
            <Stack.Item>
              <FormRow label="Название:">
                <Input
                  fluid
                  placeholder="Название кнопки в панели"
                  value={name}
                  maxLength={MAX_NAME_LENGTH}
                  onInput={(e, value) => setName(value)}
                />
              </FormRow>
            </Stack.Item>
            <Stack.Item>
              <FormRow label="Текст:">
                <TextArea
                  fluid
                  height="90px"
                  placeholder="'USER' и 'TARGET' заменятся именами. '/' для разделения вариаций текста, выберется случайный."
                  value={message}
                  maxLength={MAX_MESSAGE_LENGTH}
                  onInput={(e, value) => setMessage(value)}
                />
              </FormRow>
            </Stack.Item>
            {selectedSounds.length > 0 && (
              <Stack.Item>
                <Box color="label" nowrap>Выбрано ({selectedSounds.length}):</Box>
                <Box style={{ display: 'flex', flexWrap: 'wrap', gap: '0.3em' }}>
                  {selectedSounds.map(sound => (
                    <Button
                      key={sound.key}
                      icon="times"
                      content={sound.label}
                      color="green"
                      onClick={() => setSoundKeys(soundKeys.filter(k => k !== sound.key))}
                    />
                  ))}
                </Box>
              </Stack.Item>
            )}
            <Stack.Item>
              <FormRow label="Категория звука:">
                <Dropdown
                  fluid
                  width="100%"
                  options={visibleSoundGroups}
                  selected={effectiveBrowsingGroup}
                  displayText={effectiveBrowsingGroup}
                  onSelected={(group) => setSoundGroupBrowsing(group)}
                />
              </FormRow>
            </Stack.Item>
            <Stack.Item>
              <Box color="label" nowrap>Звук (можно выбрать несколько - сработает случайный):</Box>
              <Stack vertical>
                {soundsInGroup.map(sound => {
                  const checked = soundKeys.includes(sound.key);
                  return (
                    <Stack.Item key={sound.key}>
                      <Stack>
                        <Stack.Item grow>
                          <Button
                            fluid
                            icon={checked ? "check-square" : "square-o"}
                            color={checked ? "green" : "transparent"}
                            content={sound.label}
                            selected={checked}
                            onClick={() => setSoundKeys(checked
                              ? soundKeys.filter(k => k !== sound.key)
                              : [...soundKeys, sound.key])}
                          />
                        </Stack.Item>
                        <Stack.Item>
                          <Button
                            icon="play"
                            onClick={() => act('custom_preview_sound', { sound_key: sound.key })}
                          />
                        </Stack.Item>
                      </Stack>
                    </Stack.Item>
                  );
                })}
              </Stack>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section title="Эффекты">
          <Effects
            settings={partner}
            onChange={setPartner}
            arousalOrgans={arousalOrgans}
            orgasmOrgans={orgasmOrgans}
            orgasmTargets={orgasmTargets}
            arousalLabel="Возбуждение партнёра"
            orgasmLabel="Оргазм партнёра"
            destinationLabel="Куда кончит партнёр"
          />
          <Divider />
          <Effects
            settings={self}
            onChange={setSelf}
            arousalOrgans={arousalOrgans}
            orgasmOrgans={orgasmOrgans}
            orgasmTargets={orgasmTargets}
            arousalLabel="Твоё возбуждение"
            orgasmLabel="Твой оргазм"
            destinationLabel="Куда ты кончишь"
          />
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section title="Требования" buttons={<IconHint text="Ограничения для использования интеракта" />}>
          <Stack vertical>
            <Stack.Item>
              <FormRow label="Применение:">
                <Dropdown
                  fluid
                  width="100%"
                  options={SCOPES.map(s => s.label)}
                  selected={selectedScope?.label}
                  displayText={selectedScope?.label}
                  onSelected={(label) => {
                    const found = SCOPES.find(s => s.label === label);
                    setScope(found ? found.id : 'others');
                  }}
                />
              </FormRow>
            </Stack.Item>
            {selectedScope && (
              <Stack.Item>
                <Box color="label" nowrap>{selectedScope.desc}</Box>
              </Stack.Item>
            )}
            <Stack.Item>
              <Divider />
            </Stack.Item>
            <Stack.Item>
              <Collapsible
                title={`Оголённые части · у тебя: ${selfPartCount} · у партнёра: ${partnerPartCount}`}
                marginBottom={0}>
                <Box style={{ display: 'grid', gridTemplateColumns: 'repeat(2, minmax(0, 1fr))', gap: '0.5em' }}>
                  <BodyPartPicker
                    label="У тебя"
                    parts={bodyParts}
                    selectedParts={self.bodyParts}
                    lockedParts={selfLockedParts}
                    onChange={bodyParts => setSelf({ ...self, bodyParts })}
                  />
                  <BodyPartPicker
                    label="У партнёра"
                    parts={bodyParts}
                    selectedParts={partner.bodyParts}
                    lockedParts={partnerLockedParts}
                    onChange={bodyParts => setPartner({ ...partner, bodyParts })}
                  />
                </Box>
              </Collapsible>
            </Stack.Item>
            <Stack.Item>
              <Divider />
            </Stack.Item>
            <Stack.Item>
              <Collapsible title="Хвост и телекинез" marginBottom={0}>
                <Stack>
                  {[
                    { label: 'У тебя', settings: self, update: setSelf, other: partner },
                    { label: 'У партнёра', settings: partner, update: setPartner, other: self },
                  ].map(({ label, settings, update, other }) => (
                    <Stack.Item key={label} grow basis={0}>
                      <Box color="label" mb={0.5}>{label}</Box>
                      <Button.Checkbox
                        compact
                        checked={settings.requiresTail}
                        content="Хвост"
                        onClick={() => update({ ...settings, requiresTail: !settings.requiresTail })}
                      />
                      <Button.Checkbox
                        compact
                        checked={settings.requiresTelekinesis}
                        content="Телекинез"
                        onClick={() => {
                          const enabled = !settings.requiresTelekinesis;
                          update({ ...settings, requiresTelekinesis: enabled });
                          if (!enabled && !other.requiresTelekinesis) {
                            setMaxDistance(1);
                          }
                        }}
                      />
                    </Stack.Item>
                  ))}
                </Stack>
              </Collapsible>
            </Stack.Item>
            <Stack.Item>
              <FormRow label="Дистанция:">
                <Dropdown
                  fluid
                  width="100%"
                  options={MAX_DISTANCES.map(distance => distance.label)}
                  selected={selectedDistance?.label}
                  disabled={!requiresTelekinesis}
                  tooltip={!requiresTelekinesis ? 'Для большей дистанции включи требование телекинеза у одного из участников' : undefined}
                  onSelected={(label) => {
                    const found = MAX_DISTANCES.find(distance => distance.label === label);
                    setMaxDistance(found ? found.id : 1);
                  }}
                />
              </FormRow>
            </Stack.Item>
            <Stack.Item>
              <Box color="label" nowrap>
                {selectedDistance?.desc}
              </Box>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Stack fill>
          <Stack.Item grow>
            <Button
              fluid
              icon="times"
              content="Отмена"
              color="red"
              onClick={cancelForm}
            />
          </Stack.Item>
          <Stack.Item grow>
            <Button
              fluid
              icon="save"
              content="Сохранить"
              color="green"
              disabled={!canSave}
              onClick={save}
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );

  const renderCustomCard = (custom: CustomInteractionData) => {
    const ownArousal = arousalOrgans.find(option => option.value === custom.self_arousal_organ);
    const partnerArousal = arousalOrgans.find(option => option.value === custom.partner_arousal_organ);
    const ownOrgasmOrgan = orgasmOrgans.find(option => option.value === custom.self_orgasm_organ);
    const partnerOrgasmOrgan = orgasmOrgans.find(option => option.value === custom.partner_orgasm_organ);
    const ownOrgasmTarget = orgasmTargets.find(option => option.value === custom.self_orgasm_target);
    const partnerOrgasmTarget = orgasmTargets.find(option => option.value === custom.partner_orgasm_target);
    const bodyPartsLabel = (mask: number) => bodyParts
      .filter(part => mask & part.flag)
      .map(part => part.label.toLowerCase())
      .join(', ');
    const ownParts = bodyPartsLabel(custom.self_required_body_parts
      | (ownArousal?.flag || 0) | (ownOrgasmOrgan?.flag || 0) | (partnerOrgasmTarget?.flag || 0));
    const partnerParts = bodyPartsLabel(custom.partner_required_body_parts
      | (partnerArousal?.flag || 0) | (partnerOrgasmOrgan?.flag || 0) | (ownOrgasmTarget?.flag || 0));
    return (
      <Section
        title={custom.name}
        buttons={
          <>
            <Button icon="pen" tooltip="Редактировать" onClick={() => startEdit(custom)} />
            <Button
              icon="trash"
              color="red"
              tooltip="Удалить"
              onClick={() => act('custom_delete', { key: custom.key })}
            />
          </>
        }>
        <Box color="label">
          Тип: <b>{custom.type_label}</b> · Применение: <b>{custom.scope_label || 'На обоих'}</b>
        </Box>
        <Box color="label">
          Возбуждение партнёра <b>{custom.partner_arousal_label}</b>
          {partnerArousal?.flag ? ` (${partnerArousal.displayText.toLowerCase()})` : ''}
          {' · Твоё возбуждение '}<b>{custom.arousal_label}</b>
          {ownArousal?.flag ? ` (${ownArousal.displayText.toLowerCase()})` : ''}
        </Box>
        <Box color="label">
          Дистанция: <b>{custom.max_distance || 1} тайл{custom.max_distance > 1 ? "а" : ""}</b>
          {custom.sound_labels?.length > 0 && (
            <>{" "}· Звук: <b>{custom.sound_labels.join(', ')}</b></>
          )}
        </Box>
        {ownParts && <Box color="label">Оголено у тебя <b>{ownParts}</b></Box>}
        {partnerParts && <Box color="label">Оголено у партнёра <b>{partnerParts}</b></Box>}
        <Box color="label">
          {!!custom.partner_orgasm && (
            <>Оргазм партнёра ({partnerOrgasmOrgan?.displayText.toLowerCase()}, {partnerOrgasmTarget?.displayText.toLowerCase()}) · </>
          )}
          {!!custom.self_orgasm && (
            <>Твой оргазм ({ownOrgasmOrgan?.displayText.toLowerCase()}, {ownOrgasmTarget?.displayText.toLowerCase()}) · </>
          )}
        </Box>
        {!!(custom.self_requires_tail || custom.partner_requires_tail) && (
          <Box color="label">
            Нужен хвост {custom.self_requires_tail
              ? (custom.partner_requires_tail ? 'у обоих' : 'у тебя')
              : 'у партнёра'}
          </Box>
        )}
        {!!(custom.self_requires_telekinesis || custom.partner_requires_telekinesis) && (
          <Box color="label">
            Нужен телекинез {custom.self_requires_telekinesis
              ? (custom.partner_requires_telekinesis ? 'у обоих' : 'у тебя')
              : 'у партнёра'}
          </Box>
        )}
      </Section>
    );
  };

  return (
    <Stack vertical>
      <Stack.Item>
        <NoticeBox info>
          Кастомных интерактов: {customs.length}/{max_customs}. Они появляются
          в твоей панели взаимодействия (Ctrl+Shift+клик по цели).
          Все поля сохраняются на персонажа.
        </NoticeBox>
      </Stack.Item>
      {(!editingKey && !creating) && (
        <Stack.Item>
          <Stack>
            <Stack.Item grow>
              <Button
                fluid
                icon="plus"
                content="Создать кастомный интеракт"
                color="green"
                disabled={customs.length >= max_customs}
                onClick={startCreate}
              />
            </Stack.Item>
            {moanSounds.length > 0 && (
              <Stack.Item grow>
                <Button
                  fluid
                  icon={useCustomMoanSounds ? "toggle-on" : "toggle-off"}
                  color="transparent"
                  content={useCustomMoanSounds ? "Свои звуки стонов включены" : "Использовать свои звуки стонов"}
                  selected={useCustomMoanSounds}
                  tooltip={`${useCustomMoanSounds ? "Отключить" : "Включить"} выбор своих звуков стонов`}
                  onClick={() => act('pref', { pref: 'use_custom_moan_sounds' })}
                />
              </Stack.Item>
            )}
          </Stack>
        </Stack.Item>
      )}
      {moanSounds.length > 0 && useCustomMoanSounds && (
        <Stack.Item>
          <Section title="Звуки стонов">
            <Stack vertical>
              {selectedMoanSounds.length > 0 && (
                <Stack.Item>
                  <Box color="label" nowrap>Выбрано ({selectedMoanSounds.length}):</Box>
                  <Box style={{ display: 'flex', flexWrap: 'wrap', gap: '0.3em' }}>
                    {selectedMoanSounds.map(sound => (
                      <Button
                        key={sound.key}
                        icon="times"
                        content={sound.label}
                        color="green"
                        onClick={() => toggleMoanSound(sound.key)}
                      />
                    ))}
                  </Box>
                </Stack.Item>
              )}
              {moanGroups.length > 1 && (
                <Stack.Item>
                  <FormRow label="Категория:">
                    <Dropdown
                      fluid
                      width="100%"
                      options={moanGroups}
                      selected={effectiveMoanGroup}
                      displayText={effectiveMoanGroup}
                      onSelected={(group) => setMoanGroupBrowsing(group)}
                    />
                  </FormRow>
                </Stack.Item>
              )}
              <Stack.Item>
                <Box color="label" nowrap>Можно выбрать несколько - сработает случайный:</Box>
                {(() => {
                  const allSelected = moanSoundsInGroup.length > 0
                    && moanSoundsInGroup.every(s => customMoanSounds.includes(s.key));
                  return (
                    <Button
                      fluid
                      icon={allSelected ? "times" : "check-double"}
                      color={allSelected ? "red" : "transparent"}
                      content={allSelected
                        ? "Отписаться от всех звуков в категории"
                        : "Подписаться на все звуки в категории"}
                      onClick={() => {
                        if (allSelected) {
                          const otherKeys = customMoanSounds.filter(
                            k => !moanSoundsInGroup.some(s => s.key === k)
                          );
                          act('set_custom_moan_sounds', { sound_keys: otherKeys });
                        } else {
                          const groupKeys = moanSoundsInGroup.map(s => s.key);
                          const otherKeys = customMoanSounds.filter(
                            k => !moanSoundsInGroup.some(s => s.key === k)
                          );
                          act('set_custom_moan_sounds', { sound_keys: [...otherKeys, ...groupKeys] });
                        }
                      }}
                    />
                  );
                })()}
                <Stack vertical>
                  {moanSoundsInGroup.map(sound => {
                    const checked = customMoanSounds.includes(sound.key);
                    return (
                      <Stack.Item key={sound.key}>
                        <Stack>
                          <Stack.Item grow>
                            <Button
                              fluid
                              icon={checked ? "check-square" : "square-o"}
                              color={checked ? "green" : "transparent"}
                              content={sound.label}
                              selected={checked}
                              onClick={() => toggleMoanSound(sound.key)}
                            />
                          </Stack.Item>
                          <Stack.Item>
                            <Button
                              icon="play"
                              onClick={() => act('preview_moan_sound', { sound_key: sound.key })}
                            />
                          </Stack.Item>
                        </Stack>
                      </Stack.Item>
                      );
                    })}
                </Stack>
              </Stack.Item>
            </Stack>
          </Section>
        </Stack.Item>
      )}
      {(editingKey || creating) && (
        <Stack.Item>
          <Section
            title={editingCustom ? 'Редактирование интеракта' : undefined}
            buttons>
            {renderForm()}
          </Section>
        </Stack.Item>
      )}
      {customs.map((custom) => (
        <Stack.Item key={custom.key}>
          {renderCustomCard(custom)}
        </Stack.Item>
      ))}
      {!customs.length && !editingKey && !creating && (
        <Section align="center">
          Кастомных интерактов пока нет.
        </Section>
      )}
    </Stack>
  );
};

const IconHint = ({ text }) => (
  <Box color="label" nowrap>{text}</Box>
);

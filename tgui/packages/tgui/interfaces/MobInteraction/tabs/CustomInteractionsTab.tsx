
import { useBackend, useLocalState } from '../../../backend';
import { Box, Button, Divider, Dropdown, Input, NoticeBox, Section, Stack, TextArea } from '../../../components';

type CustomInteractionData = {
  key: string;
  name: string;
  message: string;
  interaction_type: string;
  type_label: string;
  arousal_level: number;
  arousal_label: string;
  partner_arousal_level: number;
  partner_arousal_label: string;
  self_orgasm: boolean;
  partner_orgasm: boolean;
  scope: string;
  scope_label: string;
  required_body_parts: number;
  requires_tail: boolean;
  requires_telekinesis: boolean;
  max_distance: number;
}

type CustomTabInfo = {
  own_custom_interactions: CustomInteractionData[];
  max_custom_interactions: number;
}

const MAX_NAME_LENGTH = 100;
const MAX_MESSAGE_LENGTH = 500;

const INTERACTION_TYPES = [
  { id: 'normal', label: 'Действие', desc: 'Обычное действие, без специальных проверок контента.' },
  { id: 'lewd', label: 'Эротика', desc: 'Требует согласие на левд-интеракты (как обычные левд-действия).' },
  { id: 'extreme', label: 'Тяжёлое', desc: 'Требует согласие на extreme-контент.' },
  { id: 'unholy', label: 'Грязное', desc: 'Требует согласие на extreme и unholy-контент.' },
];

const AROUSAL_LEVELS = [
  { id: 0, label: 'Нет', desc: 'Возбуждение не меняется.' },
  { id: 1, label: 'Малый', desc: '+6 возбуждения.' },
  { id: 2, label: 'Средний', desc: '+14 возбуждения.' },
  { id: 3, label: 'Сильный', desc: '+28 возбуждения.' },
];

const MAX_DISTANCES = [
  { id: 1, label: '1 тайл', desc: 'Вплотную, как обычное действие.' },
  { id: 2, label: '2 тайла', desc: 'Можно применить на расстоянии до двух тайлов.' },
  { id: 3, label: '3 тайла', desc: 'Можно применить на расстоянии до трёх тайлов.' },
];

const SCOPES = [
  { id: 'both', label: 'На обоих', desc: 'Интеракцию можно использовать и на себе, и на других.' },
  { id: 'self', label: 'На себе', desc: 'Интеракция доступна только на самом персонаже.' },
  { id: 'others', label: 'Только на других', desc: 'Интеракцию можно использовать только на других.' },
];

const BODY_PARTS = [
  { flag: 1 << 4, label: 'Анус' },
  { flag: 1 << 5, label: 'Яйца' },
  { flag: 1 << 6, label: 'Грудь' },
  { flag: 1 << 7, label: 'Живот' },
  { flag: 1 << 8, label: 'Уши' },
  { flag: 1 << 10, label: 'Глаза' },
  { flag: 1 << 12, label: 'Ноги' },
  { flag: 1 << 13, label: 'Член' },
  { flag: 1 << 14, label: 'Вагина' },
  { flag: 1 << 15, label: 'Хвост' },
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

export const CustomInteractionsTab = (props) => {
  const { act, data } = useBackend<CustomTabInfo>();
  const [editingKey, setEditingKey] = useLocalState<string | null>('customEditingKey', null);
  const [creating, setCreating] = useLocalState('customCreating', false);
  const customs = data.own_custom_interactions || [];
  const max_customs = data.max_custom_interactions || 10;

  const [interactionType, setInteractionType] = useLocalState('customFormType', '');
  const [name, setName] = useLocalState('customFormName', '');
  const [message, setMessage] = useLocalState('customFormMessage', '');
  const [arousalLevel, setArousalLevel] = useLocalState('customFormArousal', 0);
  const [partnerArousalLevel, setPartnerArousalLevel] = useLocalState('customFormPartnerArousal', 0);
  const [selfOrgasm, setSelfOrgasm] = useLocalState('customFormSelfOrgasm', false);
  const [partnerOrgasm, setPartnerOrgasm] = useLocalState('customFormPartnerOrgasm', false);
  const [scope, setScope] = useLocalState('customFormScope', 'both');
  const [requiredBodyParts, setRequiredBodyParts] = useLocalState('customFormBodyParts', 0);
  const [requiresTail, setRequiresTail] = useLocalState('customFormTail', false);
  const [requiresTelekinesis, setRequiresTelekinesis] = useLocalState('customFormTk', false);
  const [maxDistance, setMaxDistance] = useLocalState('customFormDistance', 1);

  const editingCustom = editingKey
    ? customs.find(custom => custom.key === editingKey)
    : undefined;

  const startCreate = () => {
    setEditingKey(null);
    setCreating(true);
    setInteractionType('');
    setName('');
    setMessage('');
    setArousalLevel(0);
    setPartnerArousalLevel(0);
    setSelfOrgasm(false);
    setPartnerOrgasm(false);
    setScope('both');
    setRequiredBodyParts(0);
    setRequiresTail(false);
    setRequiresTelekinesis(false);
    setMaxDistance(1);
  };

  const startEdit = (custom) => {
    setEditingKey(custom.key);
    setCreating(false);
    setInteractionType(custom.interaction_type);
    setName(custom.name);
    setMessage(custom.message);
    setArousalLevel(custom.arousal_level);
    setPartnerArousalLevel(custom.partner_arousal_level || 0);
    setSelfOrgasm(!!custom.self_orgasm);
    setPartnerOrgasm(!!custom.partner_orgasm);
    setScope(custom.scope || 'both');
    setRequiredBodyParts(Number(custom.required_body_parts) || 0);
    setRequiresTail(custom.requires_tail);
    setRequiresTelekinesis(custom.requires_telekinesis);
    setMaxDistance(custom.max_distance || 1);
  };

  const save = () => {
    if (!interactionType || !name || !message) {
      return;
    }
    const payload = {
      interaction_type: interactionType,
      name,
      message,
      arousal_level: arousalLevel,
      partner_arousal_level: partnerArousalLevel,
      self_orgasm: selfOrgasm ? 1 : 0,
      partner_orgasm: partnerOrgasm ? 1 : 0,
      scope,
      required_body_parts: requiredBodyParts,
      requires_tail: requiresTail ? 1 : 0,
      requires_telekinesis: requiresTelekinesis ? 1 : 0,
      max_distance: maxDistance,
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
  const selectedArousal = AROUSAL_LEVELS.find(level => level.id === arousalLevel);
  const selectedPartnerArousal = AROUSAL_LEVELS.find(level => level.id === partnerArousalLevel);
  const selectedScope = SCOPES.find(s => s.id === scope);
  const canSave = !!interactionType && !!name && !!message;

  const renderForm = () => (
    <Stack vertical>
      <Stack.Item>
        <Section title="Основное" buttons={<IconHint text="Название и текст интеракта" />}>
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
                  placeholder="Используй USER и TARGET — они заменятся именами. Разделяй варианты текста символом / — выберется случайный"
                  value={message}
                  maxLength={MAX_MESSAGE_LENGTH}
                  onInput={(e, value) => setMessage(value)}
                />
              </FormRow>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section title="Эффекты" buttons={<IconHint text="Возбуждение и оргазмы применяются отдельно к партнёру и твоему персонажу" />}>
          <Stack vertical>
            <Stack.Item>
              <FormRow label="Возбуждение партнёра:">
                <Dropdown
                  fluid
                  width="100%"
                  options={AROUSAL_LEVELS.map(level => level.label)}
                  selected={selectedPartnerArousal?.label}
                  displayText={selectedPartnerArousal?.label || 'Нет'}
                  onSelected={(label) => {
                    const found = AROUSAL_LEVELS.find(level => level.label === label);
                    setPartnerArousalLevel(found ? found.id : 0);
                  }}
                />
              </FormRow>
            </Stack.Item>
            {selectedPartnerArousal && (
              <Stack.Item>
                <Box color="label" nowrap>{selectedPartnerArousal.desc}</Box>
              </Stack.Item>
            )}
            <Stack.Item>
              <FormRow label="Возбуждение персонажа:">
                <Dropdown
                  fluid
                  width="100%"
                  options={AROUSAL_LEVELS.map(level => level.label)}
                  selected={selectedArousal?.label}
                  displayText={selectedArousal?.label || 'Нет'}
                  onSelected={(label) => {
                    const found = AROUSAL_LEVELS.find(level => level.label === label);
                    setArousalLevel(found ? found.id : 0);
                  }}
                />
              </FormRow>
            </Stack.Item>
            {selectedArousal && (
              <Stack.Item>
                <Box color="label" nowrap>{selectedArousal.desc}</Box>
              </Stack.Item>
            )}
            <Stack.Item>
              <Divider />
            </Stack.Item>
            <Stack.Item>
              <FormRow label="Оргазм партнёра:">
                <Button
                  fluid
                  icon={partnerOrgasm ? "toggle-on" : "toggle-off"}
                  color="transparent"
                  content={partnerOrgasm ? "Может довести партнёра до оргазма" : "Не вызывает оргазм партнёра"}
                  selected={partnerOrgasm}
                  tooltip="Если включено, интеракция может довести партнёра до оргазма"
                  onClick={() => setPartnerOrgasm(!partnerOrgasm)}
                />
              </FormRow>
            </Stack.Item>
            <Stack.Item>
              <FormRow label="Собственный оргазм:">
                <Button
                  fluid
                  icon={selfOrgasm ? "toggle-on" : "toggle-off"}
                  color="transparent"
                  content={selfOrgasm ? "Может вызвать твой оргазм" : "Не вызывает твой оргазм"}
                  selected={selfOrgasm}
                  tooltip="Если включено, интеракция может довести тебя до оргазма"
                  onClick={() => setSelfOrgasm(!selfOrgasm)}
                />
              </FormRow>
            </Stack.Item>
          </Stack>
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
                  displayText={selectedScope?.label || 'На обоих'}
                  onSelected={(label) => {
                    const found = SCOPES.find(s => s.label === label);
                    setScope(found ? found.id : 'both');
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
              <FormRow label="Оголённые части:">
                <Button
                  fluid
                  icon={requiredBodyParts === 0 ? "toggle-on" : "toggle-off"}
                  color="transparent"
                  content={requiredBodyParts === 0 ? "Всегда доступно" : "Есть требования"}
                  selected={requiredBodyParts === 0}
                  tooltip="Если включено, интеракт доступен всегда, без требований к открытым частям тела"
                  onClick={() => setRequiredBodyParts(0)}
                />
              </FormRow>
            </Stack.Item>
            <Stack.Item>
              <Stack wrap>
                {BODY_PARTS.map(part => {
                  const selected = !!(requiredBodyParts & part.flag);
                  return (
                    <Stack.Item key={part.flag} width="50%">
                      <Button
                        fluid
                        icon={selected ? "check-square" : "square-o"}
                        color={selected ? "green" : "transparent"}
                        content={part.label}
                        selected={selected}
                        tooltip={selected
                          ? "Часть должна быть оголена у кого-то из пары"
                          : "Часть не требуется"}
                        onClick={() => setRequiredBodyParts(selected
                          ? requiredBodyParts & ~part.flag
                          : requiredBodyParts | part.flag)}
                      />
                    </Stack.Item>
                  );
                })}
              </Stack>
            </Stack.Item>
            {requiredBodyParts !== 0 && (
              <Stack.Item>
                <Box color="label" nowrap>
                  Выбранная часть тела должна быть оголена хотя бы у одного из пары.
                </Box>
              </Stack.Item>
            )}
            <Stack.Item>
              <Divider />
            </Stack.Item>
            <Stack.Item>
              <FormRow label="Дистанция:">
                <Dropdown
                  fluid
                  width="100%"
                  options={MAX_DISTANCES.map(distance => distance.label)}
                  selected={MAX_DISTANCES.find(distance => distance.id === maxDistance)?.label}
                  displayText={MAX_DISTANCES.find(distance => distance.id === maxDistance)?.label || '1 тайл'}
                  onSelected={(label) => {
                    const found = MAX_DISTANCES.find(distance => distance.label === label);
                    setMaxDistance(found ? found.id : 1);
                  }}
                />
              </FormRow>
            </Stack.Item>
            <Stack.Item>
              <Box color="label" nowrap>
                {MAX_DISTANCES.find(distance => distance.id === maxDistance)?.desc}
              </Box>
            </Stack.Item>
            <Stack.Item>
              <Stack>
                <Stack.Item width="40%">
                  <Button
                    fluid
                    icon={requiresTail ? "toggle-on" : "toggle-off"}
                    color="transparent"
                    content="Нужен хвост"
                    selected={requiresTail}
                    tooltip="Вариант будет виден и сработает, только если хвост есть у кого-то из пары"
                    onClick={() => setRequiresTail(!requiresTail)}
                  />
                </Stack.Item>
                <Stack.Item grow>
                  <Button
                    fluid
                    icon={requiresTelekinesis ? "toggle-on" : "toggle-off"}
                    color="transparent"
                    content="Нужен телекинез"
                    selected={requiresTelekinesis}
                    tooltip="Вариант будет виден и сработает, только если телекинез есть у кого-то из пары"
                    onClick={() => setRequiresTelekinesis(!requiresTelekinesis)}
                  />
                </Stack.Item>
              </Stack>
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
              color="transparent"
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

  const renderCustomCard = (custom) => {
    const bodyPartsLabel = custom.required_body_parts
      ? BODY_PARTS
        .filter(part => custom.required_body_parts & part.flag)
        .map(part => part.label.toLowerCase())
        .join(', ')
      : '';
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
          Возбуждение партнёра: <b>{custom.partner_arousal_label}</b>
          {" "}· Возбуждение персонажа: <b>{custom.arousal_label}</b>
        </Box>
        <Box color="label">
          Дистанция: <b>{custom.max_distance || 1} тайл{custom.max_distance > 1 ? "а" : ""}</b>
        </Box>
        <Box color="label">
          {custom.required_body_parts
            ? <>Оголено: <b>{bodyPartsLabel}</b></>
            : <><b>Всегда доступно</b></>}
        </Box>
        <Box color="label">
          {custom.partner_orgasm ? <>Оргазм партнёра · </> : null}
          {custom.self_orgasm ? <>Свой оргазм · </> : null}
          {custom.requires_tail ? <>Нужен хвост · </> : null}
          {custom.requires_telekinesis ? <>Нужен телекинез</> : null}
        </Box>
      </Section>
    );
  };

  return (
    <Stack vertical>
      <Stack.Item>
        <NoticeBox info>
          Кастомных интерактов: {customs.length}/{max_customs}. Они появляются
          в твоей панели взаимодействия (Ctrl+Shift+клик по цели) и применяются
          на других персонажей.
        </NoticeBox>
      </Stack.Item>
      {(!editingKey && !creating) && (
        <Stack.Item>
          <Button
            fluid
            icon="plus"
            content="Создать кастомный интеракт"
            color="green"
            disabled={customs.length >= max_customs}
            onClick={startCreate}
          />
        </Stack.Item>
      )}
      {(editingKey || creating) && (
        <Stack.Item>
          <Section
            title={editingCustom ? 'Редактирование интеракта' : 'Создание интеракта'}
            buttons={<IconHint text="Все поля сохраняются на персонажа" />}>
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

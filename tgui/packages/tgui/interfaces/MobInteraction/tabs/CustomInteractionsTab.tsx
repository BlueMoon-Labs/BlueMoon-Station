
import { useBackend, useLocalState } from '../../../backend';
import { Box, Button, Dropdown, Input, NoticeBox, Section, Stack, TextArea } from '../../../components';

type CustomInteractionData = {
  key: string;
  name: string;
  message: string;
  interaction_type: string;
  type_label: string;
  arousal_level: number;
  arousal_label: string;
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
  { id: 0, label: 'Нет', desc: 'Возбуждение персонажа не меняется.' },
  { id: 1, label: 'Малый', desc: '+10 возбуждения персонажа.' },
  { id: 2, label: 'Средний', desc: '+25 возбуждения персонажа.' },
  { id: 3, label: 'Сильный', desc: '+50 возбуждения персонажа.' },
];

const MAX_DISTANCES = [
  { id: 1, label: '1 тайл', desc: 'Вплотную, как обычное действие.' },
  { id: 2, label: '2 тайла', desc: 'Можно применить на расстоянии до двух тайлов.' },
  { id: 3, label: '3 тайла', desc: 'Можно применить на расстоянии до трёх тайлов.' },
];

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
  const canSave = !!interactionType && !!name && !!message;

  const renderForm = () => (
    <Section
      title={editingCustom ? 'Редактирование интеракта' : 'Создание интеракта'}
      buttons={
        <>
          <Button icon="times" content="Отмена" color="transparent" onClick={cancelForm} />
          <Button icon="save" content="Сохранить" color="green" disabled={!canSave} onClick={save} />
        </>
      }>
      <Stack vertical>
        <Stack.Item>
          <Stack>
            <Stack.Item width="40%">
              Тип взаимодействия:
            </Stack.Item>
            <Stack.Item grow>
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
            </Stack.Item>
          </Stack>
        </Stack.Item>
        {selectedType && (
          <Stack.Item>
            <NoticeBox info>{selectedType.desc}</NoticeBox>
          </Stack.Item>
        )}
        <Stack.Item>
          <Stack>
            <Stack.Item width="40%">
              Название:
            </Stack.Item>
            <Stack.Item grow>
              <Input
                fluid
                placeholder="Название кнопки в панели"
                value={name}
                maxLength={MAX_NAME_LENGTH}
                onInput={(e, value) => setName(value)}
              />
            </Stack.Item>
          </Stack>
        </Stack.Item>
        <Stack.Item>
          <Stack>
            <Stack.Item width="40%">
              Текст:
            </Stack.Item>
            <Stack.Item grow>
              <TextArea
                fluid
                height="90px"
                placeholder="Используй USER и TARGET — они заменятся именами. Разделяй варианты текста символом / — выберется случайный"
                value={message}
                maxLength={MAX_MESSAGE_LENGTH}
                onInput={(e, value) => setMessage(value)}
              />
            </Stack.Item>
          </Stack>
        </Stack.Item>
        <Stack.Item>
          <Stack>
            <Stack.Item width="40%">
              Возбуждение персонажа:
            </Stack.Item>
            <Stack.Item grow>
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
            </Stack.Item>
          </Stack>
        </Stack.Item>
        {selectedArousal && (
          <Stack.Item>
            <Box color="label" nowrap>{selectedArousal.desc}</Box>
          </Stack.Item>
        )}
        <Stack.Item>
          <Stack>
            <Stack.Item width="40%">
              Дистанция:
            </Stack.Item>
            <Stack.Item grow>
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
            </Stack.Item>
          </Stack>
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
                content={requiresTail ? "Нужен хвост" : "Нужен хвост"}
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
                content={requiresTelekinesis ? "Нужен телекинез" : "Нужен телекинез"}
                selected={requiresTelekinesis}
                tooltip="Вариант будет виден и сработает, только если телекинез есть у кого-то из пары"
                onClick={() => setRequiresTelekinesis(!requiresTelekinesis)}
              />
            </Stack.Item>
          </Stack>
        </Stack.Item>
        <Stack.Item>
          <NoticeBox info>
            Твои варианты видны всем, кто взаимодействует с этим персонажем.
            Проверки согласий зависят от выбранного типа. Возбуждение применяется
            к твоему персонажу.
          </NoticeBox>
        </Stack.Item>
      </Stack>
    </Section>
  );

  return (
    <Stack vertical>
      <Stack.Item>
        <NoticeBox info>
          Кастомных интерактов: {customs.length}/{max_customs}. Они видны всем, кто
          взаимодействует с этим персонажем.
        </NoticeBox>
      </Stack.Item>
      {(!editingKey && !creating) && (
        <Stack.Item>
          <Button
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
          {renderForm()}
        </Stack.Item>
      )}
      {customs.map((custom) => (
        <Stack.Item key={custom.key}>
          <Stack fill>
            <Stack.Item grow>
              <Button
                fluid
                content={custom.name}
                color="default"
                onClick={() => startEdit(custom)}
              />
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="pen"
                tooltip="Редактировать"
                onClick={() => startEdit(custom)}
              />
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="trash"
                color="red"
                tooltip="Удалить"
                onClick={() => act('custom_delete', { key: custom.key })}
              />
            </Stack.Item>
          </Stack>
          <Box color="label" nowrap>
            Тип: {custom.type_label} | Возбуждение персонажа: {custom.arousal_label}
            {" "}| Дистанция: {custom.max_distance || 1} тайл{custom.max_distance > 1 ? "а" : ""}
            {custom.requires_tail ? " | Хвост" : ""}
            {custom.requires_telekinesis ? " | Телекинез" : ""}
          </Box>
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

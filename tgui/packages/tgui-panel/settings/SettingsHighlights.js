import { useDispatch, useSelector } from 'common/redux';
import { Box, Button, Divider, Flex, Section, TextArea } from 'tgui/components';

import { rebuildChat } from '../chat/actions';
import { createHighlightSetting, DEFAULT_HIGHLIGHT_COLOR, HIGHLIGHT_PRESET_COLORS, MAX_HIGHLIGHT_SETTINGS } from '../chat/highlight';
import { updateSettings } from './actions';
import { ColorInput } from './ColorInput';
import { selectSettings } from './selectors';

// Сервер не хранит настройки длиннее 16384 байт (length() в tgui_panel.dm,
// кириллица - 2 байта), 10 групп по 500 символов под него влезают. Если
// лимит всё же превышен (много вкладок), чат предупреждает (panel/state_error).
const MAX_HIGHLIGHT_TEXT_LENGTH = 500;

const SPEECH_ONLY_TOOLTIP = 'Подсвечивать только то, что персонажи говорят'
  + ' вслух, по рации, в мёртвом чате и телепатически (улей, блоб, дроны).'
  + ' Имя говорящего, эмоции, действия, OOC'
  + ' и системные сообщения не подсвечиваются.';

const HighlightGroup = (props) => {
  const { item, index, count, onUpdate, onMove, onRemove } = props;
  const enabled = item.enabled !== false;
  return (
    <Box mb={1} style={{ opacity: enabled ? 1 : 0.6 }}>
      <Flex mb={1} align="center">
        <Flex.Item>
          <Button.Checkbox
            checked={enabled}
            tooltip="Включить или выключить группу"
            onClick={() => onUpdate({ enabled: !enabled })}>
            {'Группа ' + (index + 1)}
          </Button.Checkbox>
        </Flex.Item>
        <Flex.Item grow={1} />
        <Flex.Item shrink={0} mr={1}>
          <ColorInput
            value={item.highlightColor}
            defaultColor={DEFAULT_HIGHLIGHT_COLOR}
            placeholder={DEFAULT_HIGHLIGHT_COLOR}
            onChange={v => onUpdate({ highlightColor: v })}
          />
        </Flex.Item>
        <Flex.Item shrink={0}>
          <Button
            icon="arrow-up"
            tooltip="Выше: важнее при совпадении слов"
            disabled={index === 0}
            onClick={() => onMove(-1)} />
          <Button
            icon="arrow-down"
            tooltip="Ниже"
            disabled={index === count - 1}
            onClick={() => onMove(1)} />
          <Button.Confirm
            icon="trash"
            color="bad"
            content=""
            confirmContent=""
            confirmIcon="check"
            tooltip="Удалить группу"
            onClick={onRemove} />
        </Flex.Item>
      </Flex>
      <TextArea
        height="3em"
        scrollbar
        maxLength={MAX_HIGHLIGHT_TEXT_LENGTH}
        placeholder="Слова и фразы через запятую или с новой строки"
        value={item.highlightText}
        onInput={(e, value) => onUpdate({ highlightText: value })} />
      <Button.Checkbox
        checked={item.speechOnly}
        tooltipPosition="bottom-start"
        tooltip={SPEECH_ONLY_TOOLTIP}
        onClick={() => onUpdate({ speechOnly: !item.speechOnly })}>
        Только речь
      </Button.Checkbox>
      <Button.Checkbox
        checked={item.sound}
        onClick={() => onUpdate({ sound: !item.sound })}>
        Звук
      </Button.Checkbox>
      <Button.Checkbox
        checked={item.matchWord}
        tooltipPosition="bottom-start"
        tooltip={'Только отдельное слово: "тех" не найдётся'
          + ' в "роботех" и в "техник".'}
        onClick={() => onUpdate({ matchWord: !item.matchWord })}>
        Целое слово
      </Button.Checkbox>
      <Button.Checkbox
        checked={item.matchWord || item.matchStart}
        disabled={item.matchWord}
        tooltipPosition="bottom-start"
        tooltip={'Слово начинается с этого текста: "робо" найдётся'
          + ' в "роботех", но не в "киборобот".'}
        onClick={() => onUpdate({ matchStart: !item.matchStart })}>
        Начало слова
      </Button.Checkbox>
      <Button.Checkbox
        checked={item.matchWord || item.matchEnd}
        disabled={item.matchWord}
        tooltipPosition="bottom-start"
        tooltip={'Слово заканчивается этим текстом: "тех" найдётся'
          + ' в "роботех", но не в "техник".'}
        onClick={() => onUpdate({ matchEnd: !item.matchEnd })}>
        Конец слова
      </Button.Checkbox>
      <Button.Checkbox
        checked={item.matchCase}
        onClick={() => onUpdate({ matchCase: !item.matchCase })}>
        Учитывать регистр
      </Button.Checkbox>
    </Box>
  );
};

export const SettingsHighlights = (props) => {
  const { highlightSettings = [] } = useSelector(selectSettings);
  const dispatch = useDispatch();
  const setList = list => dispatch(updateSettings({
    highlightSettings: list,
  }));
  const updateItem = (id, fields) => setList(highlightSettings
    .map(item => (item.id === id ? { ...item, ...fields } : item)));
  const moveItem = (index, offset) => {
    const list = [...highlightSettings];
    const [item] = list.splice(index, 1);
    list.splice(index + offset, 0, item);
    setList(list);
  };
  const addItem = () => setList([
    ...highlightSettings,
    createHighlightSetting({
      highlightColor: HIGHLIGHT_PRESET_COLORS[
        highlightSettings.length % HIGHLIGHT_PRESET_COLORS.length],
    }),
  ]);
  return (
    <Section>
      <Box color="label">
        Разделите слова по группам: у каждой свой цвет и свои настройки.
        Если слово есть в нескольких группах, побеждает верхняя.
      </Box>
      {highlightSettings.map((item, index) => (
        <Box key={item.id}>
          <Divider />
          <HighlightGroup
            item={item}
            index={index}
            count={highlightSettings.length}
            onUpdate={fields => updateItem(item.id, fields)}
            onMove={offset => moveItem(index, offset)}
            onRemove={() => setList(highlightSettings
              .filter(other => other.id !== item.id))} />
        </Box>
      ))}
      <Divider />
      <Button
        icon="plus"
        disabled={highlightSettings.length >= MAX_HIGHLIGHT_SETTINGS}
        tooltip={highlightSettings.length >= MAX_HIGHLIGHT_SETTINGS
          ? 'Не больше ' + MAX_HIGHLIGHT_SETTINGS + ' групп' : undefined}
        onClick={addItem}>
        Добавить группу
      </Button>
      <Button
        icon="sync"
        tooltip={'Новые настройки действуют на новые сообщения.'
          + ' Кнопка перекрасит и старые, чат может ненадолго подвиснуть.'}
        onClick={() => dispatch(rebuildChat())}>
        Применить к старым
      </Button>
    </Section>
  );
};

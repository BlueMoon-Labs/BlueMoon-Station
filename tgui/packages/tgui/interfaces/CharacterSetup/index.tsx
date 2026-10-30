import { useCallback, useState } from 'react';

import { useBackend } from '../../backend';
import {
  Box,
  Button,
  ByondUi,
  Dropdown,
  Icon,
  Input,
  Modal,
  NoticeBox,
  NumberInput,
  Section,
  Stack,
  Tabs,
} from '../../components';
import { Window } from '../../layouts';
import { SelectRow } from './components';
import { SearchSettings } from './SearchSettings';
import { AppearanceTab } from './tabs/Appearance';
import { BackgroundTab } from './tabs/Background';
import { GeneralTab } from './tabs/General';
import { InnateTab } from './tabs/Innate';
import { LoadoutTab } from './tabs/Loadout';
import { MarkingsTab } from './tabs/Markings';
import { ModificationsTab } from './tabs/Modifications';
import { QuirksTab } from './tabs/Quirks';
import { SpeechTab } from './tabs/Speech';

interface CharacterPreset {
  name: string;
  jobs: number;
  quirks: number;
  items: number;
  jobTitle: string | null;
  jobIcon: string;
}

interface CharacterSetupData {
  tabs: { id: number; label: string; icon: string }[];
  maxSlots: number;
  slotNames: (string | null)[];
  slotCustomNames: (string | null)[];
  characterSlotName: string | null;
  slotNameReplace: boolean;
  defaultSlot: number;
  characterRevision: number;
  characterName: string;
  speciesName: string;
  tab: number;
  previewRef: string;
  previewAutoFit: boolean;
  previewViewportReady: boolean;
  previewPref: string;
  previewAroused: boolean;
  previewSingleView: boolean;
  previewDirection: number;
  previewZoom: number;
  previewReference: boolean;
  previewBackgroundStyle: string;
  previewModes: string[];
  previewBackground: string;
  previewBackgrounds: string[];
  localStorageName: string | null;
  offerActive: boolean;
  redemptionCode?: string;
  hasUnsavedChanges: boolean;
  autoSaveOnSwitch: boolean;
  autoSaveActivePreset: boolean;
  characterPresets: CharacterPreset[];
  activeCharacterPreset?: string | null;
  selectedCharacterPreset?: string | null;
  presetLimit: number;
  saveNotice?: string;
  theme: string;
}

// Готовые tgui-темы окна.
const WINDOW_THEMES: Record<string, string> = {
  kpk: 'ntos',
  terminal: 'ntos_terminal',
  syndie: 'syndicate',
  cat: 'ntos_cat',
  synth: 'ntos_synth',
  hotpink: 'hotpink',
  hackerman: 'hackerman',
  malfunction: 'malfunction',
  heretic: 'heretic',
  wizard: 'wizard',
  darkmode: 'ntos_darkmode',
  pact: 'pact',
  abductor: 'abductor',
  neutral: 'neutral',
  inteq: 'inteq',
};

const PREVIEW_MODES: Record<string, { label: string; icon: string }> = {
  Job: { label: 'По профессии', icon: 'briefcase' },
  Loadout: { label: 'Экипировка', icon: 'tshirt' },
  Naked: { label: 'Без одежды', icon: 'user' },
};

const presetOptions = (presets: CharacterPreset[]) => presets.map(preset => ({
  value: preset.name,
  displayText: (
    <span className="CharacterSetup__preset-label" title={preset.jobTitle || 'Профессия не выбрана'}>
      <span className="CharacterSetup__preset-job-icon">
        <Box className={'jobs8x8 ' + preset.jobIcon} />
      </span>
      <span className="CharacterSetup__preset-name">{preset.name}</span>
    </span>
  ),
}));

export const CharacterSetup = () => {
  const { act, data } = useBackend<CharacterSetupData>();
  const [slotsOpen, setSlotsOpen] = useState(true);
  const [presetsOpen, setPresetsOpen] = useState(false);
  const theme = data.theme || 'default';
  const characterTitle = data.characterName
    + (data.characterSlotName ? ` (${data.characterSlotName})` : '');

  return (
    <Window
      width={1600}
      height={1080}
      resizable
      title="Настройка персонажа"
      canMaximize
      theme={WINDOW_THEMES[theme]}
    >
      <Window.Content
        className={
          theme !== 'default' ? 'CharacterSetupTheme--' + theme : undefined
        }
      >
        <div className="CharacterSetup">
          <Section className="CharacterSetup__header">
            <Stack align="center">
              <Stack.Item>
                <Button
                  icon="users"
                  selected={slotsOpen}
                  content="Персонажи"
                  onClick={() => setSlotsOpen(!slotsOpen)}
                />
              </Stack.Item>
              <Stack.Item grow basis={0}>
                <Box className="CharacterSetup__name" title={characterTitle}>{characterTitle}</Box>
                <Box color="label">
                  Слот {data.defaultSlot} · {data.speciesName}
                </Box>
              </Stack.Item>
              <Stack.Item className="CharacterSetup__header-actions">
                <Button
                  icon="link"
                  selected={data.autoSaveActivePreset}
                  aria-pressed={data.autoSaveActivePreset}
                  aria-label="Автосохранение активного пресета вместе с персонажем"
                  tooltip={'Обновлять активный пресет при сохранении персонажа: '
                    + (data.autoSaveActivePreset ? 'включено' : 'выключено')}
                  onClick={() => act('set_active_preset_autosave', {
                    value: !data.autoSaveActivePreset,
                  })}
                />
                <Button
                  icon="layer-group"
                  tooltip="Управление пресетами персонажа"
                  aria-label="Управление пресетами персонажа"
                  onClick={() => setPresetsOpen(true)}
                />
                <Button
                  icon="save"
                  disabled={!data.activeCharacterPreset}
                  tooltip="Сохранить текущие профессии, квирки и активный лодаут в активный пресет"
                  aria-label="Сохранить активный пресет"
                  onClick={() => act('preset_save', {
                    name: data.activeCharacterPreset,
                    character_slot: data.defaultSlot,
                  })}
                />
              </Stack.Item>
              <Stack.Item>
                <Dropdown
                  className="CharacterSetup__preset-selector"
                  width="180px"
                  searchable
                  selected={data.activeCharacterPreset ?? undefined}
                  displayText={data.activeCharacterPreset ? undefined : 'Выберите пресет'}
                  options={presetOptions(data.characterPresets || [])}
                  disabled={!data.characterPresets?.length}
                  tooltip="Применить пресет профессий, квирков и экипировки"
                  tooltipPosition="top"
                  onSelected={name => act('preset_apply', {
                    name, character_slot: data.defaultSlot,
                  })}
                />
              </Stack.Item>
              <Stack.Item>
                <Box color={data.hasUnsavedChanges ? 'average' : 'good'} title={data.saveNotice}>
                  <Icon name={data.hasUnsavedChanges ? 'pencil-alt' : 'check'} />{' '}
                  {data.hasUnsavedChanges ? 'Есть изменения' : 'Сохранено'}
                </Box>
              </Stack.Item>
              <Stack.Item className="CharacterSetup__header-actions">
                <Button
                  icon="save"
                  color="good"
                  content="Сохранить"
                  onClick={() => act('save')}
                />
                <Button
                  icon="sync-alt"
                  selected={data.autoSaveOnSwitch}
                  aria-pressed={data.autoSaveOnSwitch}
                  aria-label="Автосохранение при смене персонажа"
                  tooltip={
                    'Автосохранение при смене персонажа: ' +
                    (data.autoSaveOnSwitch ? 'включено.' : 'выключено.') +
                    ' Если выключить, несохранённые изменения будут сброшены при переключении слота.'
                  }
                  onClick={() => act('set_autosave_on_switch', {
                    value: !data.autoSaveOnSwitch,
                  })}
                />
                <Button.Confirm
                  icon="undo"
                  content="Отменить изменения"
                  confirmContent="Отменить изменения?"
                  tooltip="Вернуть настройки текущего персонажа к последнему сохранению"
                  onClick={() => act('load')}
                />
              </Stack.Item>
            </Stack>
          </Section>
          <div
            className={
              'CharacterSetup__body' +
              (slotsOpen ? '' : ' CharacterSetup__body--collapsed')
            }
          >
            {slotsOpen && <SlotPanel />}
            <div className="CharacterSetup__editor">
              <SearchSettings />
              <Tabs className="CharacterSetup__tabs">
                {(data.tabs || []).map((tab) => (
                  <Tabs.Tab
                    key={tab.id}
                    selected={data.tab === tab.id}
                    icon={tab.icon}
                    onClick={() => act('set_tab', { tab: tab.id })}
                  >
                    {tab.label}
                  </Tabs.Tab>
                ))}
              </Tabs>
              <div
                className="CharacterSetup__content"
                key={
                  data.defaultSlot +
                  ':' +
                  data.characterRevision +
                  ':' +
                  data.tab
                }
              >
                <TabContent tab={data.tab} />
              </div>
            </div>
            <Preview />
          </div>
          {presetsOpen && <CharacterPresets onClose={() => setPresetsOpen(false)} />}
        </div>
      </Window.Content>
    </Window>
  );
};

const CharacterPresets = (props: { onClose: () => void }) => {
  const { act, data } = useBackend<CharacterSetupData>();
  const presets = data.characterPresets || [];
  const current = presets.find(preset => preset.name === data.selectedCharacterPreset)
    || presets.find(preset => preset.name === data.activeCharacterPreset)
    || presets[0];
  const params = { name: current?.name, character_slot: data.defaultSlot };

  return (
    <Modal width="580px">
      <Section
        title={`Пресеты: ${data.characterName} (${presets.length}/${data.presetLimit})`}
        buttons={<Button icon="times" tooltip="Закрыть" onClick={props.onClose} />}
      >
        <Box mb={1}>
          Пресет хранит предпочтения работы, квирки с их настройками,
          модификации органов и импланты, а также один комплект экипировки.
          Внешность и описания персонажа сохраняются.
        </Box>
        <Box color="label" mb={1}>
          При создании или обновлении копируется текущий активный лодаут.
          Применённый комплект доступен по кнопке «Пресет» во вкладке экипировки;
          десять общих слотов остаются прежними.
        </Box>
        <Button
          icon="plus"
          content="Создать из текущих настроек"
          disabled={presets.length >= data.presetLimit}
          mb={1}
          onClick={() => act('preset_create', { character_slot: data.defaultSlot })}
        />
        {!!current && (
          <>
            <Stack align="center" mb={1}>
              <Stack.Item grow basis={0} minWidth={0}>
                <Dropdown
                  className="CharacterSetup__preset-selector"
                  width="100%"
                  searchable
                  selected={current.name}
                  options={presetOptions(presets)}
                  onSelected={name => act('preset_select', {
                    name, character_slot: data.defaultSlot,
                  })}
                />
              </Stack.Item>
              <Stack.Item className="CharacterSetup__header-actions">
                <Button
                  icon="pen"
                  tooltip="Переименовать пресет"
                  onClick={() => act('preset_rename', params)}
                />
                <Button.Confirm
                  icon="trash"
                  color="bad"
                  tooltip="Удалить пресет"
                  confirmContent="Удалить?"
                  onClick={() => act('preset_delete', params)}
                />
              </Stack.Item>
            </Stack>
            <Box color="label" mb={1}>
              Профессий с приоритетом: {current.jobs}. Квирков: {current.quirks}.
              Предметов: {current.items}.
            </Box>
            <Button
              icon="check"
              color="good"
              content="Применить"
              onClick={() => act('preset_apply', params)}
            />
            <Button
              icon="save"
              content="Сохранить текущие настройки в пресет"
              tooltip="Заменить содержимое выбранного пресета текущими профессиями, квирками и активным лодаутом"
              onClick={() => act('preset_save', params)}
            />
          </>
        )}
        {!!data.saveNotice && <NoticeBox mt={1}>{data.saveNotice}</NoticeBox>}
        <Box color="label" mt={1}>
          Пресеты принадлежат этому персонажу. Для записи изменений на диск
          нажмите «Сохранить» вверху редактора или используйте автосохранение
          при смене персонажа.
        </Box>
      </Section>
    </Modal>
  );
};

const SlotPanel = () => {
  const { act, data } = useBackend<CharacterSetupData>();
  const [search, setSearch] = useState('');
  const [showEmpty, setShowEmpty] = useState(false);
  const names = data.slotNames || [];
  const customNames = data.slotCustomNames || [];
  const customName = (slot: number) => slot === data.defaultSlot
    ? data.characterSlotName
    : customNames[slot - 1];
  const slotLabel = (slot: number) => {
    const name = names[slot - 1] || '';
    const label = customName(slot);
    return label ? (data.slotNameReplace ? label : `${name} (${label})`) : name;
  };
  const slots = Array.from(
    { length: data.maxSlots || 1 },
    (_, index) => index + 1
  );
  const occupied = slots.filter((slot) => !!names[slot - 1]);
  const empty = slots.filter((slot) => !names[slot - 1]);
  const query = search.trim().toLocaleLowerCase();
  const visible = occupied.filter(
    (slot) =>
      String(slot) === query ||
      names[slot - 1]?.toLocaleLowerCase().includes(query) ||
      customName(slot)?.toLocaleLowerCase().includes(query)
  );

  return (
    <Section
      fill
      title="Персонажи"
      className="CharacterSetup__slots"
      buttons={
        <Box color="label" className="CharacterSetup__slot-label-tools">
          <Button
            compact
            icon="pen"
            tooltip="Задать название выбранного слота. Пустая строка убирает название."
            aria-label="Название выбранного слота"
            onClick={() => act('edit_slot_name', { character_slot: data.defaultSlot })}
          />
          <Button
            compact
            icon={data.slotNameReplace ? 'exchange-alt' : 'feather'}
            selected={data.slotNameReplace}
            aria-pressed={data.slotNameReplace}
            aria-label="Заменять имя персонажа названием слота"
            tooltip={data.slotNameReplace
              ? 'Замена имени: в списке показывается название слота. Нажмите для дополнения имени в скобках.'
              : 'Дополнение: название слота показывается в скобках после имени. Нажмите для замены имени.'}
            onClick={() => act('set_slot_name_replace', { value: !data.slotNameReplace })}
          />
          <span>{occupied.length}/{slots.length}</span>
        </Box>
      }
    >
      <div className="CharacterSetup__slot-panel">
        <Input
          fluid
          placeholder="Имя, название или номер слота"
          value={search}
          onInput={(event, value) => setSearch(value)}
        />
        <div className="CharacterSetup__slot-list">
          {visible.map((slot) => (
            <Button
              key={slot}
              fluid
              selected={slot === data.defaultSlot}
              className="CharacterSetup__slot"
              tooltip={customName(slot) ? `${names[slot - 1]} (${customName(slot)})` : undefined}
              onClick={() => act('switch_slot', { slot })}
            >
              <span className="CharacterSetup__slot-number">{slot}</span>
              <span className="CharacterSetup__slot-name">
                {slotLabel(slot)}
              </span>
              {slot === data.defaultSlot && <Icon name="check" />}
            </Button>
          ))}
          {!visible.length && (
            <Box color="label" my={1}>
              Персонажи не найдены.
            </Box>
          )}
          <Button
            fluid
            icon={showEmpty ? 'chevron-up' : 'plus'}
            content={'Свободные слоты: ' + empty.length}
            onClick={() => setShowEmpty(!showEmpty)}
          />
          {(showEmpty || !occupied.length) &&
            empty.map((slot) => (
              <Button
                key={slot}
                fluid
                icon="plus"
                color="transparent"
                content={'Новый персонаж · слот ' + slot}
                tooltip="Создать нового персонажа в свободном слоте"
                onClick={() => act('switch_slot', { slot })}
              />
            ))}
        </div>
        <div className="CharacterSetup__slot-tools">
          <Box color="label" mb={1}>
            {data.saveNotice || (data.autoSaveOnSwitch
              ? 'При переключении текущий персонаж сохраняется.'
              : 'Автосохранение выключено. Перед переключением сохраните нужные изменения.')}
          </Box>
          <Button.Confirm
            fluid
            icon="dice"
            content="Случайная внешность"
            confirmContent="Изменить внешность?"
            onClick={() => act('randomize')}
          />
          <Button.Confirm
            fluid
            icon="trash"
            color="bad"
            content="Удалить персонажа"
            confirmContent="Удалить этот слот?"
            disabled={!names[data.defaultSlot - 1]}
            onClick={() => act('delete_slot', { slot: data.defaultSlot })}
          />
          <SlotTools />
        </div>
      </div>
    </Section>
  );
};

const SlotTools = () => {
  const { act, data } = useBackend<CharacterSetupData>();
  const [open, setOpen] = useState(false);

  const localName = data.localStorageName;
  const offerActive = !!data.offerActive;

  return (
    <Box mt={1}>
      <Button
        icon={open ? 'chevron-down' : 'chevron-right'}
        content="Передача слота"
        selected={open}
        onClick={() => setOpen(!open)}
      />
      {open && (
        <Stack mt={1} align="center" wrap>
          <Stack.Item>
            <Box color="label">
              Локальная копия: {localName ? localName : 'пусто'}
            </Box>
          </Stack.Item>
          <Stack.Item>
            <Button.Confirm
              icon="download"
              content="Экспорт слота"
              confirmContent="Экспортировать слот?"
              onClick={() => act('slot_export')}
            />
          </Stack.Item>
          <Stack.Item>
            <Button.Confirm
              icon="upload"
              content="Импорт в слот"
              confirmContent="Заменить текущий слот?"
              disabled={!localName}
              tooltip={localName ? undefined : 'Локальной копии нет'}
              onClick={() => act('slot_import')}
            />
          </Stack.Item>
          <Stack.Item>
            <Button.Confirm
              icon="share-alt"
              color={offerActive ? 'bad' : undefined}
              content={offerActive ? 'Отменить передачу' : 'Предложить слот'}
              confirmContent={
                offerActive
                  ? 'Отменить предложение?'
                  : 'Вывести слот на передачу?'
              }
              onClick={() => act('slot_give')}
            />
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="key"
              content="Получить по коду"
              onClick={() => act('slot_retrieve')}
            />
          </Stack.Item>
          {offerActive && !!data.redemptionCode && (
            <Stack.Item>
              <Box>
                Код передачи:{' '}
                <Box inline bold>
                  {data.redemptionCode}
                </Box>
              </Box>
            </Stack.Item>
          )}
        </Stack>
      )}
    </Box>
  );
};

const Preview = () => {
  const { act, data } = useBackend<CharacterSetupData>();
  const autoFit = !!(data.previewAutoFit ?? true);
  const zoom = data.previewZoom || 1;
  const backgroundStyle = data.previewBackgroundStyle || 'texture';
  const backgroundLabels: Record<string, string> = {
    '000': 'Чёрная текстура', midgrey: 'Серая текстура', FFF: 'Белая текстура',
    white: 'Светлая текстура', steel: 'Стальные плитки', techmaint: 'Технический пол',
    dark: 'Тёмные плитки', plating: 'Покрытие', reinforced: 'Укреплённый пол',
  };
  const backgroundOptions = [
    { value: 'transparent', label: 'Без фона' },
    { value: 'checker', label: 'Шахматный' },
    { value: 'light', label: 'Светлый' },
    { value: 'dark', label: 'Тёмный' },
    ...(data.previewBackgrounds || []).map((state) => ({
      value: 'texture:' + state, label: backgroundLabels[state] || state,
    })),
  ];
  const directionLabel = ({ 2: 'Спереди', 1: 'Сзади', 4: 'Справа', 8: 'Слева' })[data.previewDirection || 2];
  const handleResize = useCallback(
    ({ width, height }: { width: number; height: number }) =>
      act('set_preview_viewport', { width, height }),
    [act]
  );
  // Панели ракурсов, поворота, приближения и силуэта должны оставаться под ByondUi.
  // Их перенос над картой сдвигает её верхнюю границу и вызывает баг первого открытия:
  // вместо персонажа видны лишь отдельные оверлеи. Переоткрытие окна скрывает проблему.
  return (
    <Section fill title="Внешний вид" className="CharacterSetup__preview"
      buttons={<Button icon="palette" tooltip="Выбрать тему" aria-label="Выбрать тему"
        onClick={() => act('pick_theme')} />}>

      <div className="CharacterSetup__preview-toolbar">
        <Box color="label" mb={1}>
          Показать персонажа
        </Box>
        <div className="CharacterSetup__preview-modes">
          {(data.previewModes || []).map((mode) => (
            <Button
              key={mode}
              fluid
              icon={PREVIEW_MODES[mode]?.icon || 'user'}
              selected={data.previewPref === mode}
              content={PREVIEW_MODES[mode]?.label || mode}
              onClick={() => act('set_preview_mode', { mode })}
            />
          ))}
          <Button.Checkbox
            fluid
            checked={!!data.previewAroused}
            content="Возбуждён"
            tooltip="Показывать возбуждённые гениталии в выбранном режиме просмотра"
            onClick={() =>
              act('set_preview_aroused', { value: !data.previewAroused })
            }
          />
        </div>
        <Box color="label" mt={1} mb={0.5}>
          Масштаб просмотра
        </Box>
        <div className="CharacterSetup__preview-modes">
          <Button
            fluid
            icon="search-plus"
            selected={autoFit}
            content="Крупно"
            tooltip="Подогнать область под текущее тело, чтобы лучше рассмотреть персонажа"
            onClick={() => act('set_preview_auto_fit', { value: true })}
          />
          <Button
            fluid
            icon="ruler"
            selected={!autoFit}
            content="Сравнение размеров"
            tooltip="Сохранять общий масштаб камеры при изменении размера тела"
            onClick={() => act('set_preview_auto_fit', { value: false })}
          />
        </div>
        <Box mt={1}>
          <SelectRow
            over
            label="Фон превью"
            value={backgroundStyle === 'texture' ? 'texture:' + data.previewBackground : backgroundStyle}
            options={backgroundOptions}
            onCycle={(dir) => act('set_preview_background', { dir })}
            action="set_preview_background"
          />
        </Box>
      </div>
      {data.previewRef ? (
        <ByondUi
          className="CharacterSetup__preview-map"
          onResize={handleResize}
          params={{
            id: data.previewRef,
            type: 'map',
            ...(zoom === 1 ? { zoom: 0 } : {}),
            'zoom-mode': 'normal',
            letterbox: !data.previewViewportReady,
          }}
        />
      ) : (
        <NoticeBox>Предпросмотр загружается…</NoticeBox>
      )}
      <div style={{ flexShrink: 0 }}>
        <Box mt={1}>
          <div className="CharacterSetup__preview-modes" data-search-label="Ракурсы">
            <Button fluid icon="th" selected={!data.previewSingleView} content="Четыре ракурса"
              onClick={() => act('set_preview_single_view', { value: false })} />
            <Button fluid icon="user" selected={!!data.previewSingleView} content="Один ракурс"
              onClick={() => act('set_preview_single_view', { value: true })} />
          </div>
        </Box>
        {!!data.previewSingleView && (
          <div className="CharacterSetup__preview-rotation" data-search-label="Поворот">
            <Button className="CharacterSetup__icon-button" icon="undo" tooltip="Повернуть влево" aria-label="Повернуть влево"
              onClick={() => act('rotate_preview', { direction: 'left' })} />
            <Button fluid content={directionLabel} tooltip="Вернуть вид спереди"
              onClick={() => act('rotate_preview', { direction: 'front' })} />
            <Button className="CharacterSetup__icon-button" icon="redo" tooltip="Повернуть вправо" aria-label="Повернуть вправо"
              onClick={() => act('rotate_preview', { direction: 'right' })} />
          </div>
        )}
        <div className="CharacterSetup__preview-zoom" data-search-label="Приближение">
          <Button className="CharacterSetup__icon-button" icon="search-minus" tooltip="Отдалить" aria-label="Отдалить"
            disabled={zoom <= 0.5} onClick={() => act('set_preview_zoom', { value: zoom - 0.25 })} />
          <NumberInput width="100%" height="28px" value={Math.round(zoom * 100)} minValue={50} maxValue={300} step={25}
            format={(value: number) => `${value}%`}
            onChange={(event, value) => act('set_preview_zoom', { value: value / 100 })} />
          <Button className="CharacterSetup__icon-button" icon="search-plus" tooltip="Приблизить" aria-label="Приблизить"
            disabled={zoom >= 3} onClick={() => act('set_preview_zoom', { value: zoom + 0.25 })} />
          <Button className="CharacterSetup__icon-button" icon="expand-arrows-alt" tooltip="Сбросить приближение до 100%" aria-label="Сбросить масштаб"
            disabled={zoom === 1} onClick={() => act('reset_preview_camera')} />
        </div>
        {!autoFit && (
          <Button.Checkbox fluid mt={0.5} checked={!!data.previewReference} content="Силуэт 100%"
            tooltip="Показать слева полупрозрачный силуэт текущего персонажа в размере 100%, выровненный по ногам"
            onClick={() => act('set_preview_reference', { value: !data.previewReference })} />
        )}
      </div>
    </Section>
  );
};

const TabContent = (props: { tab: number }) => {
  const { tab } = props;

  switch (tab) {
    case 0:
      return <GeneralTab />;
    case 1:
      return <BackgroundTab />;
    case 2:
      return <AppearanceTab />;
    case 3:
      return <MarkingsTab />;
    case 4:
      return <SpeechTab />;
    case 5:
      return <LoadoutTab />;
    case 6:
      return <QuirksTab />;
    case 7:
      return <ModificationsTab />;
    case 8:
      return <InnateTab />;
    default:
      return (
        <Section fill scrollable>
          <NoticeBox>
            Неизвестная вкладка - её содержимое не определено.
          </NoticeBox>
        </Section>
      );
  }
};

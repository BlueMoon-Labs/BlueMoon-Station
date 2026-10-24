import { useCallback, useState } from 'react';

import { useBackend } from '../../backend';
import {
  Box,
  Button,
  ByondUi,
  Icon,
  Input,
  NoticeBox,
  Section,
  Stack,
  Tabs,
} from '../../components';
import { Window } from '../../layouts';
import { SelectRow } from './components';
import { AppearanceTab } from './tabs/Appearance';
import { BackgroundTab } from './tabs/Background';
import { GeneralTab } from './tabs/General';
import { LoadoutTab } from './tabs/Loadout';
import { MarkingsTab } from './tabs/Markings';
import { QuirksTab } from './tabs/Quirks';
import { SpeechTab } from './tabs/Speech';

interface CharacterSetupData {
  tabs: { id: number; label: string; icon: string }[];
  maxSlots: number;
  slotNames: (string | null)[];
  defaultSlot: number;
  characterRevision: number;
  characterName: string;
  speciesName: string;
  tab: number;
  previewRef: string;
  previewAutoFit: boolean;
  previewViewportReady: boolean;
  previewPref: string;
  previewModes: string[];
  previewBackground: string;
  previewBackgrounds: string[];
  localStorageName: string | null;
  offerActive: boolean;
  redemptionCode?: string;
}

const PREVIEW_MODES: Record<string, { label: string; icon: string }> = {
  Job: { label: 'По профессии', icon: 'briefcase' },
  Loadout: { label: 'Экипировка', icon: 'tshirt' },
  Naked: { label: 'Без одежды', icon: 'user' },
  'Naked - Aroused': { label: 'Без одежды (возбужд.)', icon: 'heart' },
};

export const CharacterSetup = () => {
  const { act, data } = useBackend<CharacterSetupData>();
  const [slotsOpen, setSlotsOpen] = useState(true);

  return (
    <Window
      width={1600}
      height={1080}
      resizable
      title="Настройка персонажа"
      canMaximize
    >
      <Window.Content>
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
                <Box className="CharacterSetup__name">{data.characterName}</Box>
                <Box color="label">
                  Слот {data.defaultSlot} · {data.speciesName}
                </Box>
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="save"
                  color="good"
                  content="Сохранить"
                  onClick={() => act('save')}
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
        </div>
      </Window.Content>
    </Window>
  );
};

const SlotPanel = () => {
  const { act, data } = useBackend<CharacterSetupData>();
  const [search, setSearch] = useState('');
  const [showEmpty, setShowEmpty] = useState(false);
  const names = data.slotNames || [];
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
      names[slot - 1]?.toLocaleLowerCase().includes(query)
  );

  return (
    <Section
      fill
      title="Персонажи"
      className="CharacterSetup__slots"
      buttons={
        <Box color="label">
          {occupied.length}/{slots.length}
        </Box>
      }
    >
      <div className="CharacterSetup__slot-panel">
        <Input
          fluid
          placeholder="Имя или номер слота"
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
              onClick={() => act('switch_slot', { slot })}
            >
              <span className="CharacterSetup__slot-number">{slot}</span>
              <span className="CharacterSetup__slot-name">
                {names[slot - 1]}
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
            При переключении текущий персонаж сохраняется.
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
              icon="trash"
              color="bad"
              content="Стереть локальную копию"
              confirmContent="Стереть локальную копию?"
              onClick={() => act('slot_delete_local')}
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
  const handleResize = useCallback(
    ({ width, height }: { width: number; height: number }) =>
      act('set_preview_viewport', { width, height }),
    [act]
  );
  return (
    <Section
      fill
      title="Внешний вид"
      className="CharacterSetup__preview"
    >
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
            value={data.previewBackground}
            options={data.previewBackgrounds || []}
            action="set_bgstate"
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
            zoom: 0,
            'zoom-mode': 'normal',
            letterbox: !data.previewViewportReady,
          }}
        />
      ) : (
        <NoticeBox>Предпросмотр загружается…</NoticeBox>
      )}
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

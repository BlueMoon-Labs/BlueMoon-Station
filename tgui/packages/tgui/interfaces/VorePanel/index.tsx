/**
 * Воре-панель
 */

import { useState } from 'react';

import { useBackend } from '../../backend';
import {
  Box,
  Button,
  Collapsible,
  Icon,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
  Tabs,
  TextArea,
} from '../../components';
import { Window } from '../../layouts';
import { BelliesTab } from './BellyEditor';
import {
  ContentsList,
  LongTextField,
  MODE_COLOR,
  MODE_PREY_RU,
  MODE_RU,
  Stub,
  StubButton,
  StubGrid,
  VorePanelData,
  VorePrefs,
} from './common';

/** Верхняя секция: где мы находимся прямо сейчас. */
const InsideSection = () => {
  const { data } = useBackend<VorePanelData>();
  const inside = data.inside || { ref: null };

  if (!inside.ref) {
    return (
      <Section title="Внутри">
        <Box color="label">Вы ни в ком не находитесь.</Box>
      </Section>
    );
  }

  return (
    <Section title="Внутри">
      <Box inline color="green">
        Вы находитесь внутри
      </Box>{' '}
      <Box inline color="yellow">
        {inside.pred}
      </Box>{' '}
      <Box inline color="red">
        {inside.display_name || inside.belly_name}
      </Box>
      {inside.absorbed ? (
        <>
          {' '}
          <Box inline color="purple">
            и полностью поглощены.
          </Box>
        </>
      ) : (
        <>
          {' '}
          <Box inline color="yellow">
            и
          </Box>{' '}
          <Box inline color={MODE_COLOR[inside.belly_mode || '']}>
            {MODE_PREY_RU[inside.belly_mode || ''] || 'вас держат внутри.'}
          </Box>
        </>
      )}
      <Box mt={0.5} color="label">
        {inside.desc}
      </Box>
      {!!inside.contents?.length && (
        <Collapsible title="Рядом с вами">
          <ContentsList contents={inside.contents} belly={inside.ref} />
        </Collapsible>
      )}
    </Section>
  );
};

/** Вкладка «Внутри» (когда персонаж в чужом нутре). */
const InsideTab = () => {
  const { data } = useBackend<VorePanelData>();
  const inside = data.inside || { ref: null };

  return (
    <Stack vertical fill spacing={1}>
      <Stack.Item>
        <Section title="Ты внутри">
          <LabeledList>
            <LabeledList.Item label="Хищник">{inside.pred || '—'}</LabeledList.Item>
            <LabeledList.Item label="Нутро">{inside.display_name || inside.belly_name || '—'}</LabeledList.Item>
            <LabeledList.Item label="Режим">
              {MODE_RU[inside.belly_mode || ''] || '—'}
            </LabeledList.Item>
            <LabeledList.Item label="Поглощён">
              {inside.absorbed ? 'Да' : 'Нет'}
            </LabeledList.Item>
          </LabeledList>
          <Box mt={0.5} color="label">
            {inside.desc}
          </Box>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Collapsible title="Способности добычи">
          <StubGrid
            items={[
              { label: 'Выбраться', field: 'prey_abilities.resist' },
              { label: 'Помочь другому', field: 'prey_abilities.help' },
              { label: 'Съесть', field: 'prey_abilities.devour' },
            ]}
          />
        </Collapsible>
      </Stack.Item>
      <Stack.Item grow>
        <Section title="Рядом с тобой" fill scrollable>
          <ContentsList contents={inside.contents || []} belly={inside.ref || ''} />
        </Section>
      </Stack.Item>
    </Stack>
  );
};

/** Вкладка «Ловец душ» — заглушка переноса. */
const SoulcatcherTab = () => {
  const { data } = useBackend<VorePanelData>();
  const name = data.soulcatcher?.name || '—';

  return (
    <Section
      fill
      scrollable
      title={`Ловец душ (${name})`}
      buttons={<StubButton content="Выключен" field="soulcatcher.active" />}>
      <NoticeBox>
        Ловец душ ещё не перенесён на сервер. Ниже — полный список настроек,
        которые появятся после переноса бэкенда.
      </NoticeBox>
      <Collapsible title="Что появится позже" mt={1}>
        <LabeledList>
          <LabeledList.Item label="Пойманные души">
            <Stub field="soulcatcher.caught_souls" />
          </LabeledList.Item>
          <LabeledList.Item label="Внутренние звуки">
            <Stub field="soulcatcher.interior_sfx" />
          </LabeledList.Item>
          <LabeledList.Item label="Имя ловца">
            <Stub field="soulcatcher.name" />
          </LabeledList.Item>
        </LabeledList>
        <Box mt={1}>
          <StubGrid
            items={[
              { label: 'Захват себя', field: 'soulcatcher.catch_self' },
              { label: 'Захват добычи', field: 'soulcatcher.catch_prey' },
              { label: 'Захват при сливе', field: 'soulcatcher.catch_drain' },
              { label: 'Захват призраков', field: 'soulcatcher.catch_ghost' },
              { label: 'Внешний слух', field: 'soulcatcher.ext_hearing' },
              { label: 'Внешнее зрение', field: 'soulcatcher.ext_vision' },
              { label: 'Бэкапы разума', field: 'soulcatcher.mind_backups' },
              { label: 'SR-проекция', field: 'soulcatcher.sr_projecting' },
              { label: 'Смена тела', field: 'abilities.takeover' },
              { label: 'Перенос души', field: 'abilities.transfer' },
              { label: 'Удаление души', field: 'abilities.delete' },
            ]}
          />
        </Box>
      </Collapsible>
    </Section>
  );
};

const AESTHETIC_STUBS = [
  { label: 'Цель поглаживания', field: 'general_pref_data.belly_rub_target' },
  { label: 'Эстетичные сообщения', field: 'general_pref_data.aesthetic_messages' },
  { label: 'Цвет спрайта воре', field: 'general_pref_data.vore_sprite_color' },
  { label: 'Умножение цвета', field: 'general_pref_data.vore_sprite_multiply' },
  { label: 'Опции иконки', field: 'general_pref_data.vore_icon_options' },
  { label: 'Спонтанно: сзади', field: 'general_pref_data.spont_rear' },
  { label: 'Спонтанно: спереди', field: 'general_pref_data.spont_front' },
  { label: 'Спонтанно: слева', field: 'general_pref_data.spont_left' },
  { label: 'Спонтанно: справа', field: 'general_pref_data.spont_right' },
];

/** Вкладка «Общие»: профиль, экспорт/импорт JSON, свёрнутые заглушки. */
const GeneralTab = () => {
  const { act, data } = useBackend<VorePanelData>();
  const export_text = data.export_text || '';
  const [importText, setImportText] = useState('');

  return (
    <Section fill scrollable>
      <Stack vertical spacing={1}>
        <Stack.Item>
          <Section title="Профиль настроек">
            <Stack spacing={1}>
              <Stack.Item grow minWidth={0}>
                <Button fluid ellipsis icon="save" onClick={() => act('saveprefs')}>
                  Сохранить настройки
                </Button>
              </Stack.Item>
              <Stack.Item grow minWidth={0}>
                <Button fluid ellipsis icon="undo" onClick={() => act('reloadprefs')}>
                  Загрузить настройки
                </Button>
              </Stack.Item>
            </Stack>
          </Section>
        </Stack.Item>

        <Stack.Item>
          <Section title="OOC и исправление ошибок">
            <Stack spacing={1}>
              <Stack.Item grow minWidth={0}>
                <Button fluid ellipsis onClick={() => act('internal_loop_refresh')}>
                  Возобновить звуки нутра
                </Button>
              </Stack.Item>
              <Stack.Item grow minWidth={0}>
                <Button fluid ellipsis onClick={() => act('escapeOOC')}>
                  OOC выход из нутра
                </Button>
              </Stack.Item>
            </Stack>
          </Section>
        </Stack.Item>

        <Stack.Item>
          <Section title="Вкус и запах">
            <Box color="label" mb={0.5}>
              Эти описания видят те, кто вас пробует на вкус или принюхивается.
            </Box>
            <LongTextField
              edit
              value={data.vore_taste || ''}
              rows={2}
              placeholder="Например: сладкий, как мёд..."
              onSave={(value) => act('set_taste', { text: value })}
            />
            <Box mt={1}>
              <LongTextField
                edit
                value={data.vore_smell || ''}
                rows={2}
                placeholder="Например: запах свежей выпечки..."
                onSave={(value) => act('set_smell', { text: value })}
              />
            </Box>
          </Section>
        </Stack.Item>

        <Stack.Item>
          <Section
            title="Экспорт нутра"
            buttons={
              <Button icon="download" onClick={() => act('export_belly')}>
                Экспортировать
              </Button>
            }>
            {export_text ? (
              <>
                <TextArea height="7em" value={export_text} />
                <Stack mt={1} spacing={1}>
                  <Stack.Item>
                    <Button
                      icon="copy"
                      onClick={() => {
                        if (navigator.clipboard?.writeText) {
                          navigator.clipboard.writeText(export_text);
                        }
                      }}>
                      Скопировать
                    </Button>
                  </Stack.Item>
                  <Stack.Item>
                    <Button icon="times" onClick={() => act('clear_export')}>
                      Очистить
                    </Button>
                  </Stack.Item>
                </Stack>
              </>
            ) : (
              <Box color="label">
                Нажмите «Экспортировать», чтобы получить текст с настройками нутра. Его можно сохранить или передать другому игроку.
              </Box>
            )}
          </Section>
        </Stack.Item>

        <Stack.Item>
          <Section title="Импорт нутра">
            <Box color="label" mb={0.5}>
              Вставьте сюда текст из экспорта. Если имя уже занято, нутро
              получит имя «Импорт N».
            </Box>
            <TextArea
              height="5em"
              value={importText}
              placeholder="Вставьте текст с настройками..."
              onInput={(_, value) => setImportText(value)}
            />
            <Button
              mt={1}
              icon="file-import"
              disabled={!importText.trim()}
              onClick={() => act('import_belly', { text: importText })}>
              Импортировать
            </Button>
          </Section>
        </Stack.Item>

        <Stack.Item>
          <Collapsible title="Пока не добавлено: спонтанный воре">
            <StubGrid items={AESTHETIC_STUBS} />
          </Collapsible>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

/** Кнопка живого флага настроек. */
const PrefToggle = (props: {
  value: boolean | undefined;
  field: string;
  onText: string;
  offText: string;
  help: string;
  onToggle: () => void;
}) => {
  void props.field; // ключ предпочтения оставляем для отладки, в UI не показываем
  return (
    <Button
      fluid
      ellipsis
      selected={!!props.value}
      icon={props.value ? 'toggle-on' : 'toggle-off'}
      tooltip={`${props.value ? props.onText : props.offText} — ${props.help}`}
      onClick={props.onToggle}>
      {props.value ? props.onText : props.offText}
    </Button>
  );
};

const STUB_PREFS: Array<{ label: string; field: string }> = [
  { label: 'Изменение размера', field: 'resizable' },
  { label: 'Шаги', field: 'step_mechanics_active' },
  { label: 'Подъём', field: 'pickup_mechanics_active' },
  { label: 'Спонтанная трансформация', field: 'allow_spontaneous_tf' },
  { label: 'Перенос разума', field: 'allow_mind_transfer' },
  { label: 'Снятие одежды', field: 'strip_mechanics_active' },
  { label: 'Загрязнение одежды', field: 'contaminate_worn_items' },
  { label: 'Приватность смерти', field: 'vore_death_privacy' },
  { label: 'Мимикрия', field: 'allow_mimicry' },
  { label: 'Приём жидкостей', field: 'liq_rec' },
  { label: 'Выдача жидкостей', field: 'liq_giv' },
  { label: 'Нанесение жидкостей', field: 'liq_apply' },
  { label: 'Жидкости нутра внутрь', field: 'consume_liquid_belly' },
];

const STUB_SPONTANEOUS: Array<{ label: string; field: string }> = [
  { label: 'Падение', field: 'drop_vore' },
  { label: 'Скольжение', field: 'slip_vore' },
  { label: 'Спотыкание', field: 'stumble_vore' },
  { label: 'Бросок', field: 'throw_vore' },
  { label: 'Фазирование', field: 'phase_vore' },
  { label: 'Еда', field: 'food_vore' },
];

const STUB_SOULCATCHER: Array<{ label: string; field: string }> = [
  { label: 'Захват души', field: 'soulcatcher_allow_capture' },
  { label: 'Перенос души', field: 'soulcatcher_allow_transfer' },
  { label: 'Удаление души', field: 'soulcatcher_allow_deletion' },
  { label: 'Смена тела', field: 'soulcatcher_allow_takeover' },
];

const STUB_SPAWN_AND_FX: Array<{ label: string; field: string }> = [
  { label: 'Спавн как хищник', field: 'latejoin_vore' },
  { label: 'Спавн на мне', field: 'latejoin_prey' },
  { label: 'Авто-принятие', field: 'no_spawnpred_warning' },
  { label: 'Показывать FX', field: 'show_vore_fx' },
  { label: 'Максимальная прозрачность FX', field: 'max_voreoverlay_alpha' },
];

/** Вкладка «Настройки»: живые флаги + свёрнутые будущие. */
const PreferencesTab = () => {
  const { act, data } = useBackend<VorePanelData>();
  const prefs: VorePrefs = data.prefs || ({} as VorePrefs);
  const show_pictures = data.show_pictures;

  return (
    <Section fill scrollable>
      <Stack vertical spacing={1}>
        <Stack.Item>
          <Section title="Что можно делать с тобой">
            <Box
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))',
                gap: '0.5em',
              }}>
              <PrefToggle
                  value={!!prefs.devourable}
                  field="devourable"
                  onText="Меня могут поглощать"
                  offText="Поглощение запрещено"
                  help="Разрешить другим подбирать тебя как добычу."
                  onToggle={() => act('toggle_flag', { flag: 'devourable' })}
                />
              <PrefToggle
                  value={!!prefs.digestable}
                  field="digestable"
                  onText="Меня можно переваривать"
                  offText="Переваривание запрещено"
                  help="Отключи, если не хочешь быть переваренным."
                  onToggle={() => act('toggle_flag', { flag: 'digestable' })}
                />
              <PrefToggle
                  value={!!prefs.absorbable}
                  field="absorbable"
                  onText="Меня можно поглощать"
                  offText="Поглощение запрещено"
                  help="Поглощение делает жертву частью хищника."
                  onToggle={() => act('toggle_flag', { flag: 'absorbable' })}
                />
              <PrefToggle
                  value={!!prefs.feeding}
                  field="feeding"
                  onText="Кормление разрешено"
                  offText="Кормление запрещено"
                  help="Можно ли скармливать тебя другим или себе."
                  onToggle={() => act('toggle_flag', { flag: 'feeding' })}
                />
              <PrefToggle
                  value={!!prefs.allowmobvore}
                  field="allowmobvore"
                  onText="Мобы могут есть меня"
                  offText="Мобы не едят меня"
                  help="Разрешение быть съеденным простыми мобами."
                  onToggle={() => act('toggle_flag', { flag: 'mobvore' })}
                />
              <PrefToggle
                  value={!prefs.no_healbelly}
                  field="healbelly"
                  onText="Исцеление разрешено"
                  offText="Исцеление запрещено"
                  help="Разрешить heal-нутрам лечить вас."
                  onToggle={() => act('toggle_flag', { flag: 'healbelly' })}
                />
              <PrefToggle
                  value={!prefs.no_temperature}
                  field="temperature"
                  onText="Температура действует"
                  offText="Температура не вредит"
                  help="Разрешить нутрам вредить вам температурой."
                  onToggle={() => act('toggle_flag', { flag: 'temperature' })}
                />
              <PrefToggle
                  value={!prefs.no_autotransfer}
                  field="autotransfer"
                  onText="Автоперемещение разрешено"
                  offText="Автоперемещение запрещено"
                  help="Разрешить нутрам автоматически перемещать вас."
                  onToggle={() => act('toggle_flag', { flag: 'autotransfer' })}
                />
              <PrefToggle
                  value={!prefs.no_remains}
                  field="remains"
                  onText="Останки остаются"
                  offText="Останки исчезают"
                  help="Оставлять останки после переваривания."
                  onToggle={() => act('toggle_flag', { flag: 'remains' })}
                />
              <PrefToggle
                  value={!prefs.no_afk_prey}
                  field="afk_prey"
                  onText="Можно есть AFK"
                  offText="AFK-добычу не трогать"
                  help="Разрешить есть вас, пока вы AFK/SSD."
                  onToggle={() => act('toggle_flag', { flag: 'afk_prey' })}
                />
              <PrefToggle
                  value={!prefs.no_afk_pred}
                  field="afk_pred"
                  onText="Можно кормить AFK"
                  offText="AFK-хищника не кормить"
                  help="Разрешить кормить вас, пока вы AFK/SSD."
                  onToggle={() => act('toggle_flag', { flag: 'afk_pred' })}
                />
              <PrefToggle
                  value={show_pictures}
                  field="show_pictures"
                  onText="Содержимое картинками"
                  offText="Содержимое списком"
                  help="Как показывать содержимое нутров."
                  onToggle={() => act('show_pictures')}
                />
            </Box>
          </Section>
        </Stack.Item>

        <Stack.Item>
          <Section title="Приватность">
            <PrefToggle
              value={!!prefs.eating_privacy_global}
              field="eating_privacy_global"
              onText="Поглощение тихое по умолчанию"
              offText="Поглощение видно всем"
              help="Режим «Как обычно» у нутра будет скрывать сообщения от чужих."
              onToggle={() => act('toggle_flag', { flag: 'privacy' })}
            />
          </Section>
        </Stack.Item>

        {!!data.has_vore_backup && (
          <Stack.Item>
            <Section title="Резервная копия">
              <Box color="label" mb={1}>
                Найдена копия вор-настроек. Восстановление заменит текущие настройки нурт.
              </Box>
              <Button.Confirm
                color="bad"
                icon="undo"
                confirmContent="Восстановить настройки?"
                onClick={() => act('restore_vore_backup')}>
                Восстановить из бэкапа
              </Button.Confirm>
            </Section>
          </Stack.Item>
        )}

        <Stack.Item>
          <Section title="Звуки">
            <Stack spacing={1} wrap>
              <Stack.Item grow basis="0" minWidth={0}>
                <PrefToggle
                  value={!!prefs.vore_sounds}
                  field="vore_sounds"
                  onText="Звуки поглощения вкл"
                  offText="Звуки поглощения выкл"
                  help="Слышать звуки поедания вокруг."
                  onToggle={() => act('toggle_sound_pref', { pref: 'vore_sounds' })}
                />
              </Stack.Item>
              <Stack.Item grow basis="0" minWidth={0}>
                <PrefToggle
                  value={!!prefs.digestion_sounds}
                  field="digestion_sounds"
                  onText="Звуки переваривания вкл"
                  offText="Звуки переваривания выкл"
                  help="Слышать звуки утробы, когда ты внутри."
                  onToggle={() => act('toggle_sound_pref', { pref: 'digestion_sounds' })}
                />
              </Stack.Item>
            </Stack>
          </Section>
        </Stack.Item>

        <Stack.Item>
          <Collapsible title="Пока не добавлено">
            <Box bold mb={0.5}>
              Механики
            </Box>
            <StubGrid items={STUB_PREFS} />
            <Box bold mt={1} mb={0.5}>
              Спонтанный воре
            </Box>
            <StubGrid items={STUB_SPONTANEOUS} />
            <Box bold mt={1} mb={0.5}>
              Ловец душ
            </Box>
            <StubGrid items={STUB_SOULCATCHER} />
            <Box bold mt={1} mb={0.5}>
              Спавн и FX
            </Box>
            <StubGrid items={STUB_SPAWN_AND_FX} />
          </Collapsible>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const MAIN_TABS = [
  { id: 'bellies', title: 'Слоты Нутра', icon: 'list', Component: BelliesTab },
  { id: 'inside', title: 'Внутри', icon: 'user', Component: InsideTab },
  { id: 'soulcatcher', title: 'Ловец душ', icon: 'ghost', Component: SoulcatcherTab },
  { id: 'general', title: 'Общие Настройки', icon: 'user-circle', Component: GeneralTab },
  { id: 'prefs', title: 'Настройки предпочтений', icon: 'user-cog', Component: PreferencesTab },
];

export const VorePanel = () => {
  const { act, data } = useBackend<VorePanelData>();
  const inside = data.inside || { ref: null };
  const [tab, setTab] = useState('bellies');

  const tabs = MAIN_TABS.filter((tabInfo) => tabInfo.id !== 'inside' || !!inside.ref);
  const active = tabs.find((tabInfo) => tabInfo.id === tab) || tabs[0];

  return (
    <Window width={1030} height={780} theme="abstract" resizable>
      <Window.Content>
        <Stack fill vertical>
          {!!data.unsaved_changes && (
            <Stack.Item>
              <NoticeBox danger>
                <Stack align="center">
                  <Stack.Item grow>
                    <Box bold>Внимание: настройки не сохранены!</Box>
                  </Stack.Item>
                  <Stack.Item>
                    <Button icon="save" color="good" onClick={() => act('saveprefs')}>
                      Сохранить
                    </Button>
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="download"
                      tooltip="Сохранить и подготовить текст с настройками нутра (вкладка «Общие»)"
                      onClick={() => {
                        act('saveprefs');
                        act('export_belly');
                        setTab('general');
                      }}>
                      Сохранить и экспортировать
                    </Button>
                  </Stack.Item>
                </Stack>
              </NoticeBox>
            </Stack.Item>
          )}
          <Stack.Item>
            <InsideSection />
          </Stack.Item>
          <Stack.Item>
            <Tabs style={{ flexWrap: 'wrap', overflow: 'visible' }}>
              {tabs.map((tabInfo) => (
                <Tabs.Tab
                  key={tabInfo.id}
                  selected={tabInfo.id === active.id}
                  onClick={() => setTab(tabInfo.id)}>
                  {tabInfo.title}
                  <Icon ml={0.5} name={tabInfo.icon} />
                </Tabs.Tab>
              ))}
            </Tabs>
          </Stack.Item>
          <Stack.Item grow>
            {active.id === 'bellies' ? (
              <BelliesTab onOpenGeneral={() => setTab('general')} />
            ) : (
              <active.Component />
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

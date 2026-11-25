import { toFixed } from 'common/math';
import type { ComponentType } from 'react';
import { useState } from 'react';

import { resolveAsset } from '../../assets';
import { useBackend } from '../../backend';
import {
  Box,
  Button,
  Collapsible,
  Input,
  LabeledList,
  Section,
  Stack,
  Tabs,
  Tooltip,
} from '../../components';
import {
  ADDON_RU,
  ADDON_TIP,
  BellyState,
  ContentsList,
  LongTextField,
  MESSAGE_TYPES,
  MESSAGE_VARS_HELP,
  MODE_COLOR,
  MODE_RU,
  NOISE_PRESETS,
  NumberField,
  SelectField,
  Stub,
  StubGrid,
  TextField,
  TipLabel,
  ToggleField,
  VORE_TYPE_RU,
  VorePanelData,
} from './common';

const asNum = (value: number | undefined, fallback = 0) =>
  typeof value === 'number' && isFinite(value) ? value : fallback;

const shorten = (text: string, max = 22) =>
  text && text.length > max ? `${text.slice(0, max - 1)}…` : text;

const StubRow = (props: { label: string; field: string }) => (
  <LabeledList.Item label={props.label}>
    <Stub field={props.field} />
  </LabeledList.Item>
);

/** Список слева*/
const BellyList = (props: {
  bellies: VorePanelData['our_bellies'];
  onOpenGeneral?: () => void;
}) => {
  const { act } = useBackend<VorePanelData>();
  const [search, setSearch] = useState('');
  const bellies = props.bellies || [];

  const filtered = bellies.filter(
    (belly) =>
      !search ||
      (belly.name || belly.display_name).toLowerCase().includes(search.toLowerCase()),
  );

  return (
    <Section title="Мое нутро" fill scrollable>
        <Stack vertical spacing={0.25}>
          <Stack.Item>
            <Input
              fluid
              placeholder="Поиск по названию..."
              value={search}
              onInput={(_, value) => setSearch(value)}
            />
          </Stack.Item>
        <Stack.Item>
          <Button fluid icon="plus" color="good" onClick={() => act('newbelly')}>
            Новый
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button
            fluid
            icon="file-export"
            tooltip="Текст с настройками появится во вкладке «Общие»"
            onClick={() => {
              act('export_belly');
              props.onOpenGeneral?.();
            }}>
            Экспорт
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button fluid icon="file-import" onClick={() => props.onOpenGeneral?.()}>
            Импорт
          </Button>
        </Stack.Item>
        <Stack.Divider />
        {filtered.map((belly) => (
          <Stack.Item key={belly.ref}>
            <Button
              fluid
              ellipsis
              selected={belly.selected}
              textColor={belly.selected ? MODE_COLOR[belly.digest_mode] : undefined}
              tooltip={`${belly.name || belly.display_name} — ${MODE_RU[belly.digest_mode] || belly.digest_mode}; содержимое: ${belly.contents}`}
              onClick={() => act('bellypick', { bellypick: belly.ref })}>
              {belly.name || belly.display_name} ({belly.contents})
            </Button>
          </Stack.Item>
        ))}
        {!filtered.length && (
          <Stack.Item>
            <Box color="label" italic>
              Ничего не найдено.
            </Box>
          </Stack.Item>
        )}
        </Stack>
    </Section>
  );
};

/** Управление имя, отображаемое имя, режим, порядок, удаление. */
const ControlsTab = (props: { belly: BellyState; edit: boolean }) => {
  const { act, data } = useBackend<VorePanelData>();
  const { belly, edit } = props;
  const limits = data.limits || { name_min: 2, name_max: 40, desc_max: 4096, msg_max: 10 };
  const setField = (field: string, value?: string | number) =>
    act('set_field', { field, value });

  return (
    <>
      <LabeledList>
        <LabeledList.Item
          label={<TipLabel text="Имя" tip={`В чате: [${limits.name_min}-${limits.name_max}] символов.`} />}
          buttons={
            <>
              <Button
                icon="arrow-up"
                tooltip="Выше в списке"
                onClick={() => act('move_belly', { dir: -1 })}
              />
              <Button
                icon="arrow-down"
                tooltip="Ниже в списке"
                onClick={() => act('move_belly', { dir: 1 })}
              />
            </>
          }>
          <TextField
            edit={edit}
            value={belly.name || ''}
            placeholder="например: Живот"
            onSave={(value) => setField('name', value)}
          />
        </LabeledList.Item>
        <LabeledList.Item label={<TipLabel text="Имя в чате" tip="Если задано, показывается вместо имени." />}>
          <TextField
            edit={edit}
            value={belly.display_name || ''}
            placeholder="как «Имя»"
            onSave={(value) => setField('display_name', value)}
          />
        </LabeledList.Item>
        <LabeledList.Item label={<TipLabel text="Режим" tip="Что происходит с добычей внутри." />}>
          <SelectField
            edit={edit}
            value={belly.digest_mode}
            options={belly.digest_modes || []}
            labelOf={(mode) => MODE_RU[mode] || mode}
            color={MODE_COLOR[belly.digest_mode]}
            width="22ch"
            onSave={(value) => setField('digest_mode', value)}
          />
        </LabeledList.Item>
        <LabeledList.Item label={<TipLabel text="Режим предметов" tip="Переваривание еды и органов: «Как режим» — как у нутра, «Удерживать» — никогда, «Переваривать» — всегда." />}>
          <SelectField
            edit={edit}
            value={belly.item_mode || 'Follow'}
            options={['Follow', 'Hold', 'Digest']}
            labelOf={(mode) =>
              ({ Follow: 'Как режим', Hold: 'Удерживать', Digest: 'Переваривать' }[mode] || mode)
            }
            width="22ch"
            onSave={(value) => setField('item_mode', value)}
          />
        </LabeledList.Item>
      </LabeledList>
      <Stack vertical spacing={0.5} mt={0.5}>
        <Stack align="flex-start">
          <Stack.Item basis="110px" color="label">
            <TipLabel text="Тип" tip="Информационные метки для других игроков." />:
          </Stack.Item>
          <Stack.Item grow minWidth={0}>
            <Box style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5em' }}>
              {(data.vore_type_options || []).map((vtype) => (
                <Button
                  key={vtype}
                  selected={(belly.vore_types || []).includes(vtype)}
                  onClick={() => act('toggle_type', { type: vtype })}>
                  {VORE_TYPE_RU[vtype] || vtype}
                </Button>
              ))}
            </Box>
          </Stack.Item>
        </Stack>
        <Stack align="flex-start">
          <Stack.Item basis="110px" color="label">
            <TipLabel text="Дополнения" tip="Особые эффекты этого нутра." />:
          </Stack.Item>
          <Stack.Item grow minWidth={0}>
            <Box style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5em' }}>
              {(data.vore_addon_options || []).map((addon) => (
                <Button
                  key={addon}
                  selected={(belly.mode_addons || []).includes(addon)}
                  tooltip={<span className="Tooltip__text">{ADDON_TIP[addon]}</span>}
                  onClick={() => act('toggle_addon', { addon })}>
                  {ADDON_RU[addon] || addon}
                </Button>
              ))}
            </Box>
          </Stack.Item>
        </Stack>
      </Stack>
      {edit && (
        <Button.Confirm
          mt={1}
          fluid
          icon="exclamation-triangle"
          confirmIcon="trash"
          color="bad"
          disabled={belly.immutable}
          tooltip={belly.immutable ? 'Это нутро нельзя удалить' : undefined}
          confirmContent="Удалить навсегда? "
          onClick={() => act('delete_belly')}>
          Удалить нутро
        </Button.Confirm>
      )}
    </>
  );
};

const MESSAGE_TARGETS: Array<{ id: string; label: string; help?: string }> = [
  {
    id: 'desc',
    label: 'Описание нутра',
    help: 'Описание, которое видит добыча внутри.',
  },
  ...MESSAGE_TYPES.map((meta) => ({
    id: meta.key as string,
    label: meta.label,
    help: meta.help,
  })),
];

/** Описания глаголы, эмоты, описание и матрица сообщений. */
const DescriptionsTab = (props: { belly: BellyState; edit: boolean }) => {
  const { act } = useBackend<VorePanelData>();
  const { belly, edit } = props;
  const [msgTab, setMsgTab] = useState(0);
  const [target, setTarget] = useState('desc');
  const [absorbedTarget, setAbsorbedTarget] = useState('smo');
  const [emoteMode, setEmoteMode] = useState('Hold');
  const setField = (field: string, value?: string | number) =>
    act('set_field', { field, value });

  const emoteText = (belly.emote_lists || {})[emoteMode] || '';

  const messages = (belly.messages || {}) as Record<string, string>;
  const absorbedMessages = (belly.absorbed_messages || {}) as Record<string, string>;
  const current = target === 'desc' ? belly.desc || '' : messages[target] || '';

  const save = (value: string) => {
    if (target === 'desc') {
      setField('desc', value);
    } else {
      act('set_messages', { msgtype: target, text: value });
    }
  };

  return (
    <Stack vertical spacing={0.5}>
      <Stack.Item>
        <LabeledList>
          <LabeledList.Item label={<TipLabel text="Глагол поглощения" tip="Используется в сообщениях поглощения в нутро" />}>
            <TextField
              edit={edit}
              value={belly.vore_verb || ''}
              placeholder="например: проглотить"
              onSave={(value) => setField('vore_verb', value)}
            />
          </LabeledList.Item>
          <LabeledList.Item label={<TipLabel text="Глагол высвобождения" tip="Используется в сообщениях выпуска из нутра" />}>
            <TextField
              edit={edit}
              value={belly.release_verb || ''}
              placeholder="например: выпускает"
              onSave={(value) => setField('release_verb', value)}
            />
          </LabeledList.Item>
          <LabeledList.Item label={<TipLabel text="Авто-описания" tip="Добыча время от времени видит описание того, что происходит внутри." />}>
            <ToggleField
              edit={edit}
              value={!!belly.emote_active}
              onToggle={() => setField('emote_active')}
              yes="Включены"
              no="Выключены"
            />
          </LabeledList.Item>
          <LabeledList.Item label={<TipLabel text="Пауза описаний" tip="Как часто показывать автоматические описания." />}>
            <NumberField
              edit={edit}
              value={asNum(belly.emote_time, 600) / 10}
              min={5}
              max={600}
              unit="сек"
              onSave={(value) => setField('emote_time', value)}
            />
          </LabeledList.Item>
          <LabeledList.Item label={<TipLabel text="Плеск при осмотре" tip="При осмотре будет слышно, что внутри плещется жидкость." />}>
            <ToggleField
              edit={edit}
              value={!!belly.show_liq_fullness}
              onToggle={() => setField('show_liq_fullness')}
              yes="Да"
              no="Нет"
            />
          </LabeledList.Item>
          <LabeledList.Item label={<TipLabel text="Логи входа" tip="Писать хищнику, когда что-то попадает в нутро." />}>
            <ToggleField edit={edit} value={!!belly.entrance_logs} onToggle={() => setField('entrance_logs')} yes="Да" no="Нет" />
          </LabeledList.Item>
          <LabeledList.Item label={<TipLabel text="Логи предметов" tip="Писать хищнику о каждом переваренном предмете." />}>
            <ToggleField edit={edit} value={!!belly.item_digest_logs} onToggle={() => setField('item_digest_logs')} yes="Да" no="Нет" />
          </LabeledList.Item>
        </LabeledList>
      </Stack.Item>

      <Stack.Item>
        <Section
          title="Сообщения"
          buttons={
            <Button.Confirm
              color="bad"
              icon="undo"
              confirmContent="Сбросить все списки?"
              onClick={() => act('reset_messages')}>
              Сбросить
            </Button.Confirm>
          }>
          <Tabs mb={1}>
            <Tabs.Tab selected={msgTab === 0} onClick={() => setMsgTab(0)}>
              Обычные
            </Tabs.Tab>
            <Tabs.Tab selected={msgTab === 1} onClick={() => setMsgTab(1)}>
              Поглощённые
            </Tabs.Tab>
          </Tabs>
          {msgTab === 0 ? (
            <Stack>
              <Stack.Item basis="175px">
                <Stack vertical spacing={0.25}>
                  {MESSAGE_TARGETS.map((item) => (
                    <Stack.Item key={item.id}>
                      <Button
                        fluid
                        ellipsis
                        selected={target === item.id}
                        tooltip={item.help ? `${item.label} — ${item.help}` : item.label}
                        onClick={() => setTarget(item.id)}>
                        {item.label}
                      </Button>
                    </Stack.Item>
                  ))}
                </Stack>
              </Stack.Item>
              <Stack.Item grow>
                <Box color="label" mb={0.5}>
                  Выберите текст слева, напишите справа и нажмите «Сохранить».
                </Box>
                <LongTextField
                  key={target}
                  edit={edit}
                  value={current}
                  rows={12}
                  placeholder="Напишите текст..."
                  onSave={save}
                />
                <Box mt={1} color="label" fontSize={0.85}>
                  {MESSAGE_VARS_HELP}
                </Box>
              </Stack.Item>
            </Stack>
          ) : (
            <Stack>
              <Stack.Item basis="175px">
                <Stack vertical spacing={0.25}>
                  {MESSAGE_TYPES.map((meta) => (
                    <Stack.Item key={meta.key}>
                      <Button
                        fluid
                        ellipsis
                        selected={absorbedTarget === meta.key}
                        tooltip={`${meta.label} — ${meta.help}`}
                        onClick={() => setAbsorbedTarget(meta.key)}>
                        {meta.label}
                      </Button>
                    </Stack.Item>
                  ))}
                </Stack>
              </Stack.Item>
              <Stack.Item grow>
                <Box color="label" mb={0.5}>
                  Эти тексты используются, когда добыча уже поглощена. Если пусто —
                  берутся обычные.
                </Box>
                <LongTextField
                  key={`absorbed-${absorbedTarget}`}
                  edit={edit}
                  value={absorbedMessages[absorbedTarget] || ''}
                  rows={12}
                  placeholder="Напишите текст..."
                  onSave={(value) =>
                    act('set_absorbed_messages', { msgtype: absorbedTarget, text: value })
                  }
                />
                <Box mt={1} color="label">
                  Описание, которое видит поглощённая добыча:
                </Box>
                <LongTextField
                  key="absorbed-desc"
                  edit={edit}
                  value={belly.absorbed_desc || ''}
                  rows={4}
                  placeholder="Пусто — используется обычное описание"
                  onSave={(value) =>
                    act('set_field', { field: 'absorbed_desc', value })
                  }
                />
              </Stack.Item>
            </Stack>
          )}
        </Section>
      </Stack.Item>

      <Stack.Item>
        <Collapsible title="Авто-описания">
          <Stack wrap spacing={0.5} mb={0.5}>
            {(belly.digest_modes || []).map((mode) => (
              <Stack.Item key={mode}>
                <Button
                  selected={emoteMode === mode}
                  onClick={() => setEmoteMode(mode)}>
                  {MODE_RU[mode] || mode}
                </Button>
              </Stack.Item>
            ))}
          </Stack>
          <LongTextField
            key={emoteMode}
            edit={edit}
            value={emoteText}
            rows={5}
            placeholder="Описания для выбранного режима. Разделяйте пустой строкой."
            onSave={(value) => act('set_emotes', { mode: emoteMode, text: value })}
          />
        </Collapsible>
      </Stack.Item>
    </Stack>
  );
};

const OPTION_STUBS = [
  { label: 'Спавн-точка нутра', field: 'belly.vorespawn' },
  { label: 'Уменьшение/увеличение', field: 'belly.shrink_grow_size' },
  { label: 'Тип яйца', field: 'belly.egg_type' },
  { label: 'Имя яйца', field: 'belly.egg_name' },
  { label: 'Размер яйца', field: 'belly.egg_size' },
  { label: 'Переработка', field: 'belly.recycling' },
  { label: 'Хранение питательности', field: 'belly.storing_nutrition' },
  { label: 'Приоритет режима', field: 'belly.selective_mode_preference' },
];

/** Опции влияние нутра на добычу. */
const OptionsTab = (props: { belly: BellyState; edit: boolean }) => {
  const { act } = useBackend<VorePanelData>();
  const { belly, edit } = props;
  const setField = (field: string, value?: string | number) =>
    act('set_field', { field, value });

  return (
    <>
      <Stack spacing={2}>
        <Stack.Item grow basis="49%" minWidth={0}>
          <LabeledList>
            <LabeledList.Item label={<TipLabel text="Вкус добычи" tip="Хищник описывает вкус добычи." />}>
              <ToggleField edit={edit} value={!!belly.can_taste} onToggle={() => setField('can_taste')} yes="Да" no="Нет" />
            </LabeledList.Item>
            <LabeledList.Item label={<TipLabel text="Добыча видит" tip="Если выключено — находящиеся внутри слепы." />}>
              <ToggleField edit={edit} value={!!belly.can_victim_see} onToggle={() => setField('can_victim_see')} yes="Да" no="Нет" />
            </LabeledList.Item>
            <LabeledList.Item label={<TipLabel text="Кормление снаружи" tip="Можно ли подкладывать добычу в это нутро со стороны." />}>
              <ToggleField edit={edit} value={!!belly.feedable} onToggle={() => setField('feedable')} yes="Да" no="Нет" />
            </LabeledList.Item>
            <LabeledList.Item label={<TipLabel text="Приватность" tip="«Как обычно» — по глобальной настройке, «Тихо» — только вблизи, «Громко» — все в поле зрения." />}>
              <SelectField
                edit={edit}
                value={belly.eating_privacy || 'Default'}
                options={['Default', 'Subtle', 'Loud']}
                labelOf={(mode) => ({ Default: 'Как обычно', Subtle: 'Тихо', Loud: 'Громко' }[mode] || mode)}
                width="16ch"
                onSave={(value) => setField('eating_privacy', value)}
              />
            </LabeledList.Item>
            <LabeledList.Item label={<TipLabel text="Приватное сопротивление" tip="Сообщения о попытках вырваться видит только хищник." />}>
              <ToggleField edit={edit} value={!!belly.private_struggle} onToggle={() => setField('private_struggle')} yes="Да" no="Нет" />
            </LabeledList.Item>
            <LabeledList.Item label={<TipLabel text="После слива" tip="Что делать с полностью высосанной добычей в режиме «Слив»." />}>
              <SelectField
                edit={edit}
                value={belly.drain_mode || 'Absorb'}
                options={['Absorb', 'Release']}
                labelOf={(mode) => ({ Absorb: 'Поглотить', Release: 'Выпустить' }[mode] || mode)}
                width="16ch"
                onSave={(value) => setField('drain_mode', value)}
              />
            </LabeledList.Item>
            <LabeledList.Item label={<TipLabel text="Переименование" tip="Меняет имя добычи, пока она поглощена; при выпуске имя возвращается." />}>
              <ToggleField edit={edit} value={!!belly.absorbedrename_enabled} onToggle={() => setField('absorbedrename_enabled')} yes="Да" no="Нет" />
            </LabeledList.Item>
            {!!belly.absorbedrename_enabled && (
              <LabeledList.Item label={<TipLabel text="Шаблон имени" tip="Можно использовать %pred и %belly." />}>
                <TextField
                  edit={edit}
                  value={belly.absorbedrename_name || ''}
                  placeholder="%pred's %belly"
                  onSave={(value) => setField('absorbedrename_name', value)}
                />
              </LabeledList.Item>
            )}
            <LabeledList.Item label={<TipLabel text="Загрязняет" tip="Пачкает предметы и одежду содержимым нутра." />}>
              <ToggleField edit={edit} value={!!belly.contaminates} onToggle={() => setField('contaminates')} yes="Да" no="Нет" />
            </LabeledList.Item>
            {!!belly.contaminates && (
              <LabeledList.Item label={<TipLabel text="Цвет загрязнения" tip="Например, #A06A8A." />}>
                <TextField
                  edit={edit}
                  value={belly.contaminate_color || ''}
                  placeholder="#RRGGBB"
                  onSave={(value) => setField('contaminate_color', value)}
                />
              </LabeledList.Item>
            )}
            {!!belly.contaminates && (
              <LabeledList.Item label={<TipLabel text="Текст загрязнения" tip="Добавляется к описанию предмета." />}>
                <TextField
                  edit={edit}
                  value={belly.contaminate_flavor || ''}
                  placeholder="например: пахнет нутром"
                  onSave={(value) => setField('contaminate_flavor', value)}
                />
              </LabeledList.Item>
            )}
            <LabeledList.Item label={<TipLabel text="Заметность" tip="Минимальный размер добычи, чтобы нутро было заметно. 0 — не показывать." />}>
              <NumberField
                edit={edit}
                value={asNum(belly.bulge_size, 0.25) * 100}
                min={0}
                max={200}
                step={5}
                unit="%"
                onSave={(value) => setField('bulge_size', value)}
              />
            </LabeledList.Item>
            <LabeledList.Item label={<TipLabel text="Вместимость" tip="Для простых мобов ограничивает число живых в нутре; у персонажей не ограничивает." />}>
              <NumberField
                edit={edit}
                value={asNum(belly.vore_capacity, 1)}
                min={1}
                max={10}
                onSave={(value) => setField('vore_capacity', value)}
              />
            </LabeledList.Item>
            <LabeledList.Item label={<TipLabel text="Питательность" tip="Множитель питательности от переваривания и поглощения." />}>
              <NumberField
                edit={edit}
                value={asNum(belly.nutrition_percent, 100)}
                max={100}
                unit="%"
                onSave={(value) => setField('nutrition_percent', value)}
              />
            </LabeledList.Item>
            <LabeledList.Item label={<TipLabel text="Сохранять режим" tip="Запоминать режим нутра между раундами." />}>
              <ToggleField
                edit={edit}
                value={!!belly.save_digest_mode}
                onToggle={() => setField('save_digest_mode')}
                yes="Вкл"
                no="Выкл"
              />
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
        <Stack.Item grow basis="49%" minWidth={0}>
          <LabeledList>
            <LabeledList.Item label="Тупой урон (ушибы)">
              <NumberField
                edit={edit}
                value={asNum(belly.digest_brute, 2)}
                max={50}
                step={0.5}
                format={(value) => toFixed(value, 2)}
                onSave={(value) => setField('digest_brute', value)}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Урон: ожоги">
              <NumberField
                edit={edit}
                value={asNum(belly.digest_burn, 2)}
                max={50}
                step={0.5}
                format={(value) => toFixed(value, 2)}
                onSave={(value) => setField('digest_burn', value)}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Урон: удушье">
              <NumberField
                edit={edit}
                value={asNum(belly.digest_oxy, 0)}
                max={50}
                step={0.5}
                format={(value) => toFixed(value, 2)}
                onSave={(value) => setField('digest_oxy', value)}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Урон: токсины">
              <NumberField
                edit={edit}
                value={asNum(belly.digest_tox, 0)}
                max={50}
                step={0.5}
                format={(value) => toFixed(value, 2)}
                onSave={(value) => setField('digest_tox', value)}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Урон: клон">
              <NumberField
                edit={edit}
                value={asNum(belly.digest_clone, 0)}
                max={50}
                step={0.5}
                format={(value) => toFixed(value, 2)}
                onSave={(value) => setField('digest_clone', value)}
              />
            </LabeledList.Item>
            <LabeledList.Item label={<TipLabel text="Температура нутра" tip="Градусы Цельсия. По умолчанию 20 °C." />}>
              <NumberField
                edit={edit}
                value={asNum(belly.belly_temperature, 293.15) - 273.15}
                min={-100}
                max={200}
                step={1}
                unit="°C"
                format={(value) => toFixed(value, 1)}
                onSave={(value) => setField('belly_temperature', value)}
              />
            </LabeledList.Item>
            <LabeledList.Item label={<TipLabel text="Урон температуры" tip="Слишком горячее или холодное нутро наносит урон (при переваривании)." />}>
              <ToggleField
                edit={edit}
                value={!!belly.temperature_damage}
                onToggle={() => setField('temperature_damage')}
                yes="Да"
                no="Нет"
              />
            </LabeledList.Item>
            <LabeledList.Item label={<TipLabel text="Глотание: люди" tip="Секунды до всасывания." />}>
              <NumberField
                edit={edit}
                value={asNum(belly.human_prey_swallow_time, 100) / 10}
                min={1}
                max={60}
                unit="сек"
                onSave={(value) => setField('human_prey_swallow_time', value)}
              />
            </LabeledList.Item>
            <LabeledList.Item label={<TipLabel text="Глотание: прочие" tip="Секунды для не-людей и предметов." />}>
              <NumberField
                edit={edit}
                value={asNum(belly.nonhuman_prey_swallow_time, 30) / 10}
                min={1}
                max={60}
                unit="сек"
                onSave={(value) => setField('nonhuman_prey_swallow_time', value)}
              />
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
      </Stack>
      <Collapsible title="Пока не добавлено: яйца и спавн" mt={1}>
        <StubGrid items={OPTION_STUBS} />
      </Collapsible>
    </>
  );
};

/** «Звуки»: мясистость, луп, громкость, частота, звуки и прослушка. */
const SoundsTab = (props: { belly: BellyState; edit: boolean }) => {
  const { act } = useBackend<VorePanelData>();
  const { belly, edit } = props;
  const setField = (field: string, value?: string | number) =>
    act('set_field', { field, value });

  return (
    <>
      <Stack spacing={2}>
        <Stack.Item grow basis="49%" minWidth={0}>
          <LabeledList>
            <LabeledList.Item label={<TipLabel text="Мясистые звуки" tip="Слизистые звуки вместо шуршания." />}>
              <ToggleField edit={edit} value={!!belly.is_wet} onToggle={() => setField('is_wet')} yes="Да" no="Нет" />
            </LabeledList.Item>
            <LabeledList.Item label={<TipLabel text="Звук внутри" tip="Зациклить звук утробы для находящихся внутри." />}>
              <ToggleField edit={edit} value={!!belly.wet_loop} onToggle={() => setField('wet_loop')} yes="Да" no="Нет" />
            </LabeledList.Item>
            <LabeledList.Item label={<TipLabel text="Громкость" tip="Громкость звуков поглощения и освобождения." />}>
              <NumberField
                edit={edit}
                value={asNum(belly.sound_volume, 75)}
                max={100}
                step={5}
                unit="%"
                onSave={(value) => setField('sound_volume', value)}
              />
            </LabeledList.Item>
            <LabeledList.Item label={<TipLabel text="Высота звука" tip="0 — случайная высота. 42500 — обычная." />}>
              <NumberField
                edit={edit}
                value={asNum(belly.noise_freq, 0)}
                max={100000}
                step={1000}
                onSave={(value) => setField('noise_freq', value)}
              />
            </LabeledList.Item>
            <LabeledList.Item label={<TipLabel text="Пресет высоты" tip="Готовые варианты высоты звука." />}>
              <SelectField
                edit={edit}
                value={String(asNum(belly.noise_freq, 0))}
                options={Object.keys(NOISE_PRESETS)}
                labelOf={(value) => NOISE_PRESETS[value] || value}
                width="16ch"
                onSave={(value) => setField('noise_freq', Number(value))}
              />
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
        <Stack.Item grow basis="49%" minWidth={0}>
          <LabeledList>
            <LabeledList.Item
              label={<TipLabel text="Звук поглощения" tip="Обычно играет добыче внутри." />}
              buttons={
                <Button icon="volume-up" tooltip="Прослушать" onClick={() => act('test_sound', { which: 'vore' })} />
              }>
              <SelectField
                edit={edit}
                value={belly.vore_sound}
                options={belly.vore_sounds || []}
                width="16ch"
                onSave={(value) => setField('vore_sound', value)}
              />
            </LabeledList.Item>
            <LabeledList.Item
              label={<TipLabel text="Звук освобождения" tip="Играет, когда добычу выпускают." />}
              buttons={
                <Button icon="volume-up" tooltip="Прослушать" onClick={() => act('test_sound', { which: 'release' })} />
              }>
              <SelectField
                edit={edit}
                value={belly.release_sound}
                options={belly.release_sounds || []}
                width="16ch"
                onSave={(value) => setField('release_sound', value)}
              />
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
      </Stack>
      <Collapsible title="Пока не добавлено: звуки" mt={1}>
        <StubGrid items={[{ label: 'Use Fancy Sounds', field: 'belly.fancy_sounds' }]} />
      </Collapsible>
    </>
  );
};

const FULLSCREEN_PREVIEWS = [
  { id: 'dark', label: 'Тёмный', asset: 'vore_preview_dark.png' },
  { id: 'blue', label: 'Синий', asset: 'vore_preview_blue.png' },
  { id: 'flesh', label: 'Плоть', asset: 'vore_preview_flesh.png' },
];

/** Визуал полноэкранные оверлеи добычи + свёрнутые FX-заглушки. */
const VisualsTab = (props: { belly: BellyState; edit: boolean }) => {
  const { act } = useBackend<VorePanelData>();
  const { belly, edit } = props;
  const selected = belly.belly_fullscreen || '';
  const active = FULLSCREEN_PREVIEWS.find((style) => style.id === selected);
  const alpha = asNum(belly.fullscreen_alpha, 255) / 255;

  return (
    <Stack vertical spacing={1}>
      <Stack.Item>
        <Collapsible title="Спрайты и эффекты">
          <StubGrid
            items={[
              { label: 'Влиять на спрайты добычи', field: 'belly.affects_vore_sprites' },
              { label: 'Раскраска', field: 'belly.colorization_enabled' },
              { label: 'Скрыть HUD добычи', field: 'belly.disable_hud' },
            ]}
          />
        </Collapsible>
      </Stack.Item>
      <Stack.Item>
        <LabeledList>
          <LabeledList.Item label={<TipLabel text="Цвет наложения" tip="Необязательный цвет поверх картинки, например #FF0000." />}>
            <TextField
              edit={edit}
              value={belly.fullscreen_color || ''}
              placeholder="#RRGGBB"
              onSave={(value) => act('set_field', { field: 'fullscreen_color', value })}
            />
          </LabeledList.Item>
        </LabeledList>
      </Stack.Item>
      <Stack.Item>
        <Section
          title="Картинка добычи"
          buttons={
            <NumberField
              edit={edit}
              value={alpha * 100}
              min={0}
              max={100}
              step={5}
              unit="%"
              tooltip="Прозрачность оверлея"
              onSave={(value) => act('set_field', { field: 'fullscreen_alpha', value: Math.round(value * 2.55) })}
            />
          }>
          {active ? (
            <Stack align="center" spacing={1} wrap>
              <Stack.Item>
                <img
                  src={resolveAsset(active.asset)}
                  width="200"
                  height="200"
                  alt={active.label}
                  style={{ borderRadius: '4px', opacity: Math.max(alpha, 0.15) }}
                />
              </Stack.Item>
              <Stack.Item grow basis="0" minWidth={0}>
                <Box bold>{active.label}</Box>
                <Box color="label">
                  Этот стиль увидит добыча внутри нутра. Прозрачность
                  настраивается справа.
                </Box>
              </Stack.Item>
            </Stack>
          ) : (
            <Box color="label">Оверлей не выбран.</Box>
          )}
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section title="Выбор картинки">
          <Box
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
              gap: '0.5em',
            }}>
            <Box style={{ gridColumn: '1 / -1' }}>
              <Button
                fluid
                selected={!selected}
                onClick={() => act('set_field', { field: 'belly_fullscreen', value: 'none' })}>
                Отключено
              </Button>
            </Box>
            {FULLSCREEN_PREVIEWS.map((style) => (
              <Button
                key={style.id}
                fluid
                p={0}
                selected={selected === style.id}
                tooltip={`Стиль «${style.label}».`}
                onClick={() => act('set_field', { field: 'belly_fullscreen', value: style.id })}>
                <img
                  src={resolveAsset(style.asset)}
                  alt={style.label}
                  style={{
                    width: '100%',
                    height: '84px',
                    objectFit: 'cover',
                    display: 'block',
                    borderRadius: '3px',
                  }}
                />
              </Button>
            ))}
          </Box>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

/** «Взаимодействия»: реакции на сопротивление и автоперемещение. */
const InteractionsTab = (props: { belly: BellyState; edit: boolean }) => {
  const { act } = useBackend<VorePanelData>();
  const { belly, edit } = props;
  const setField = (field: string, value?: string | number) =>
    act('set_field', { field, value });
  const options = ['none', ...(belly.transfer_options || [])];

  return (
    <Stack vertical spacing={1}>
      <Stack.Item>
        <Section
          title="Взаимодействия нутра"
          buttons={
            <ToggleField
              edit={edit}
              value={!!belly.escapable}
              onToggle={() => setField('escapable')}
              yes="Включены"
              no="Отключены"
            />
          }>
          {!belly.escapable && (
            <Box color="label">
              Пока взаимодействия отключены, сопротивление добычи ни к чему не
              приводит. Настройки ниже сработают после включения.
            </Box>
          )}
          <Stack spacing={2} mt={belly.escapable ? 0 : 1}>
            <Stack.Item grow basis="49%" minWidth={0}>
              <LabeledList>
                <LabeledList.Item label="Шанс побега">
                  <NumberField edit={edit} value={asNum(belly.escapechance)} max={100} unit="%" onSave={(value) => setField('escapechance', value)} />
                </LabeledList.Item>
                <LabeledList.Item label="Время побега">
                  <NumberField edit={edit} value={asNum(belly.escapetime, 200) / 10} min={1} max={60} unit="сек" onSave={(value) => setField('escapetime', value)} />
                </LabeledList.Item>
                <LabeledList.Item label="Шанс перемещения">
                  <NumberField edit={edit} value={asNum(belly.transferchance)} max={100} unit="%" onSave={(value) => setField('transferchance', value)} />
                </LabeledList.Item>
                <LabeledList.Item label="Место перемещения">
                  <SelectField
                    edit={edit}
                    value={belly.transferlocation || 'none'}
                    options={options}
                    labelOf={(value) => (value === 'none' ? 'Отключено' : value)}
                    width="16ch"
                    onSave={(value) => setField('transferlocation', value)}
                  />
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>
            <Stack.Item grow basis="49%" minWidth={0}>
              <LabeledList>
                <LabeledList.Item label="Шанс поглощения">
                  <NumberField edit={edit} value={asNum(belly.absorbchance)} max={100} unit="%" onSave={(value) => setField('absorbchance', value)} />
                </LabeledList.Item>
                <LabeledList.Item label="Шанс переваривания">
                  <NumberField edit={edit} value={asNum(belly.digestchance)} max={100} unit="%" onSave={(value) => setField('digestchance', value)} />
                </LabeledList.Item>
                <LabeledList.Item label="Авто: шанс">
                  <NumberField edit={edit} value={asNum(belly.autotransferchance)} max={100} unit="%" onSave={(value) => setField('autotransferchance', value)} />
                </LabeledList.Item>
                <LabeledList.Item label="Авто: пауза">
                  <NumberField edit={edit} value={asNum(belly.autotransferwait, 10) / 10} min={1} max={600} unit="сек" onSave={(value) => setField('autotransferwait', value)} />
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Button fluid icon="question" onClick={() => act('int_help')}>
          Как это работает?
        </Button>
      </Stack.Item>
    </Stack>
  );
};

/** Содержимое поиск, картинки/список, массовые действия. */
const ContentsTab = (props: { belly: BellyState; edit: boolean }) => {
  const { act, data } = useBackend<VorePanelData>();
  const { belly } = props;
  const [search, setSearch] = useState('');
  const contents = belly.contents || [];
  const destinationOptions = ['none', ...(belly.transfer_options || [])];

  const filtered = contents.filter(
    (thing) => !search || thing.name.toLowerCase().includes(search.toLowerCase()),
  );

  return (
    <Section title="Содержимое">
      <Stack mb={1} spacing={1} align="center" wrap>
        <Stack.Item>
          <Input
            placeholder="Поиск..."
            width="14ch"
            value={search}
            onInput={(_, value) => setSearch(value)}
          />
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="eye"
            selected={data.show_pictures}
            onClick={() => act('show_pictures')}>
            {data.show_pictures ? 'Картинки' : 'Список'}
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Box inline color="label" mr={0.5}>
            Куда:
          </Box>
          <SelectField
            edit={props.edit}
            value={belly.destination || 'none'}
            options={destinationOptions}
            labelOf={(value) => (value === 'none' ? 'Не выбрано' : value)}
            width="16ch"
            onSave={(value) => act('set_field', { field: 'destination', value })}
          />
        </Stack.Item>
        <Stack.Item>
          <Button icon="eject" onClick={() => act('eject_all')}>
            Выпустить всех
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="exchange-alt"
            disabled={!belly.destination}
            onClick={() => act('move_all')}>
            Переместить всех
          </Button>
        </Stack.Item>
      </Stack>
      {filtered.length ? (
        <ContentsList contents={filtered} belly={belly.ref} />
      ) : (
        <Box color="label" italic>
          {contents.length ? 'Ничего не найдено.' : 'Пусто.'}
        </Box>
      )}
    </Section>
  );
};

/** Жидкости производство, хранение и очистка. */
const LiquidTab = (props: { belly: BellyState; edit: boolean }) => {
  const { act, data } = useBackend<VorePanelData>();
  const { belly, edit } = props;
  const options = data.liquid_options || [];
  const liquids = belly.liquids || [];
  const setField = (field: string, value?: string | number) =>
    act('set_field', { field, value });

  return (
    <Stack vertical spacing={1}>
      <Stack.Item>
        <Section
          title="Настройки жидкостей"
          buttons={
            <Button.Confirm
              color="bad"
              icon="trash"
              disabled={!belly.liquid_total}
              confirmContent="Очистить всё?"
              onClick={() => act('purge_liquids')}>
              Очистить
            </Button.Confirm>
          }>
          <LabeledList>
            <LabeledList.Item label="Производство">
              <ToggleField
                edit={edit}
                value={!!belly.show_liquids}
                onToggle={() => setField('show_liquids')}
                yes="Да"
                no="Нет"
              />
            </LabeledList.Item>
            <LabeledList.Item label="Тип жидкости">
              <SelectField
                edit={edit}
                value={belly.liquid_reagent}
                options={options.map((option) => option.path)}
                labelOf={(path) => options.find((option) => option.path === path)?.name || path}
                width="18ch"
                onSave={(value) => setField('liquid_reagent', value)}
              />
            </LabeledList.Item>
            <LabeledList.Item label={<TipLabel text="Скорость" tip="Сколько единиц жидкости появляется за тик. Тратит питательность." />}>
              <NumberField
                edit={edit}
                value={asNum(belly.liquid_rate, 1)}
                max={10}
                unit="ед/тик"
                onSave={(value) => setField('liquid_rate', value)}
              />
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section
          title="Текущие жидкости"
          buttons={<Box color="label">Питательность: {asNum(belly.liquid_nutrition)} %</Box>}>
          <LabeledList>
            {liquids.length ? (
              liquids.map((reagent) => (
                <LabeledList.Item
                  key={reagent.name}
                  label={<Tooltip content={reagent.name}>{shorten(reagent.name)}</Tooltip>}>
                  {reagent.volume} u
                </LabeledList.Item>
              ))
            ) : (
              <LabeledList.Item label="Содержимое">Пусто</LabeledList.Item>
            )}
            <LabeledList.Divider />
            <LabeledList.Item label="Общий объём">{asNum(belly.liquid_total)} u</LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const BELLY_TABS = [
  { id: 'controls', title: 'Управление', Component: ControlsTab },
  { id: 'descriptions', title: 'Описания', Component: DescriptionsTab },
  { id: 'options', title: 'Опции', Component: OptionsTab },
  { id: 'sounds', title: 'Звуки', Component: SoundsTab },
  { id: 'visuals', title: 'Визуал', Component: VisualsTab },
  { id: 'interactions', title: 'Реакции', Component: InteractionsTab },
  { id: 'contents', title: 'Содержимое', Component: ContentsTab },
  { id: 'liquids', title: 'Жидкости', Component: LiquidTab },
] as const;

/** Редактор выбранного нутра: шапка + подвкладки. */
const BellyEditor = (props: { belly: BellyState }) => {
  const { belly } = props;
  const [tab, setTab] = useState<string>('controls');
  const [edit, setEdit] = useState(true);

  const active = BELLY_TABS.find((tabInfo) => tabInfo.id === tab) || BELLY_TABS[0];
  const TabComponent = active.Component as ComponentType<{ belly: BellyState; edit: boolean }>;

  return (
    <Box>
      <Stack align="center" spacing={1} mb={1}>
        <Stack.Item grow basis="0" minWidth={0}>
          <Box
            bold
            fontSize={1.2}
            textColor={MODE_COLOR[belly.digest_mode] || undefined}
            title={belly.name || belly.display_name}
            style={{
              overflow: 'hidden',
              textOverflow: 'ellipsis',
              whiteSpace: 'nowrap',
            }}>
            {belly.name || belly.display_name}
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Box color="label">{MODE_RU[belly.digest_mode] || belly.digest_mode}</Box>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="pencil"
            selected={edit}
            color={edit ? 'good' : undefined}
            tooltip={edit ? 'Сейчас можно менять настройки' : 'Нажмите, чтобы менять настройки'}
            onClick={() => setEdit(!edit)}>
            {edit ? 'Редактировать' : 'Просмотр'}
          </Button>
        </Stack.Item>
      </Stack>
      <Tabs style={{ flexWrap: 'wrap', overflow: 'visible' }}>
        {BELLY_TABS.map((tabInfo) => (
          <Tabs.Tab key={tabInfo.id} selected={tabInfo.id === tab} onClick={() => setTab(tabInfo.id)}>
            {tabInfo.title}
            {tabInfo.id === 'contents' ? ` (${(belly.contents || []).length})` : ''}
          </Tabs.Tab>
        ))}
      </Tabs>
      <Box mt={1}>
        <TabComponent belly={belly} edit={edit} />
      </Box>
    </Box>
  );
};

/** Главная вкладка прону чурки. */
export const BelliesTab = (props: { onOpenGeneral?: () => void }) => {
  const { data } = useBackend<VorePanelData>();
  const { our_bellies = [], selected } = data;

  return (
      <Stack fill spacing={1}>
        <Stack.Item basis="210px">
          <BellyList bellies={our_bellies} onOpenGeneral={props.onOpenGeneral} />
        </Stack.Item>
        <Stack.Item grow minWidth={0}>
        <Section fill scrollable>
          {selected ? (
            <BellyEditor key={selected.ref} belly={selected} />
          ) : (
            <Box color="label" italic>
              Выберите нутро слева или создайте новый.
            </Box>
          )}
        </Section>
        </Stack.Item>
      </Stack>
  );
};

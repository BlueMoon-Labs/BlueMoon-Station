import { useBackend } from '../../../backend';
import { Box, Dropdown, Input, NumberInput, Stack, Tooltip } from '../../../components';
import { PrefRow } from '../components/PrefRow';

type ChatData = {
  chat_ooc: boolean;
  chat_looc: boolean;
  chat_ghostears: boolean;
  chat_ghostsight: boolean;
  chat_ghostwhisper: boolean;
  chat_ghostpda: boolean;
  chat_ghostradio: boolean;
  chat_dead: boolean;
  chat_prayer: boolean;
  chat_radio: boolean;
  chat_pullr: boolean;
  chat_bankcard: boolean;
  windowflashing: boolean;
  windownoise: boolean;
  ghost_form: string;
  ghost_orbit: string;
  ghost_accs: string;
  ghost_others: string;
  ooccolor: string;
  aooccolor: string;
  custom_colors: number;
  tgui_input_mode: boolean;
  tgui_input_verbs: boolean;
  max_chat_length: number;
  auto_capitalize_enabled: boolean;
};

// React's onChange fires continuously while dragging inside the color
// dialog; debounce so we do not flood the server with act() messages.
const colorCommitTimers = new WeakMap();
const debouncedColorCommit = (input: HTMLInputElement, commit: (value: string) => void) => {
  clearTimeout(colorCommitTimers.get(input));
  colorCommitTimers.set(input, setTimeout(() => commit(input.value), 250));
};

const GHOST_FORM_OPTIONS = [
  'ghost', 'ghost1', 'ghost2', 'ghostking', 'ghostian2', 'skeleghost',
  'ghost_red', 'ghost_black', 'ghost_blue', 'ghost_yellow', 'ghost_green',
  'ghost_pink', 'ghost_cyan', 'ghost_dblue', 'ghost_dred', 'ghost_dgreen',
  'ghost_dcyan', 'ghost_grey', 'ghost_dyellow', 'ghost_dpink',
  'ghost_purpleswirl', 'ghost_funkypurp', 'ghost_pinksherbert', 'ghost_blazeit',
  'ghost_mellow', 'ghost_rainbow', 'ghost_camo', 'ghost_fire', 'catghost',
];

const GHOST_ORBIT_OPTIONS = [
  'circle', 'triangle', 'square', 'hexagon', 'pentagon',
];

const GHOST_ACCS_OPTIONS = [
  { value: 1, label: 'Без аксессуаров' },
  { value: 50, label: 'Только аксессуары' },
  { value: 100, label: 'Все' },
];

const GHOST_OTHERS_OPTIONS = [
  { value: 100, label: 'Их настройки' },
  { value: 1, label: 'Простые' },
  { value: 50, label: 'По умолчанию' },
];

const OOC_COLORS = (data: ChatData, act: Function) => (
  <>
    <Stack.Divider />
    <Stack.Item>
      <div className="GamePreferences__label" style={{ opacity: 0.65, fontSize: '0.85em', marginBottom: '0.25rem' }}>
        Цвета OOC
      </div>
    </Stack.Item>
    <PrefRow
      label="Собственный цвет OOC"
      checked={!!(Number(data.custom_colors) & 1)}
      onClick={() => act('set_ooc_pref', { flag: 'custom_colors', value: !(Number(data.custom_colors) & 1) ? 1 : 0 })}
    />
    {!!(Number(data.custom_colors) & 1) && (
      <Stack.Item>
        <Stack align="center" fill className="GamePreferences__row">
          <Stack.Item grow basis={0}>
            <div className="GamePreferences__label">Цвет OOC</div>
          </Stack.Item>
          <Stack.Item>
            <Box
              as="input"
              type="color"
              value={/^#[0-9a-fA-F]{6}$/.test(data.ooccolor) ? data.ooccolor : '#ffbed6'}
              style={{
                width: '22px',
                height: '22px',
                padding: '0',
                border: '1px solid rgba(255,255,255,0.2)',
                borderRadius: '2px',
                background: 'transparent',
                cursor: 'pointer',
              }}
              onChange={e => debouncedColorCommit(e.target,
                value => act('set_ooc_pref', { flag: 'ooccolor', value }))}
            />
          </Stack.Item>
          <Stack.Item shrink={0} basis="80px">
            <Input
              width="80px"
              value={data.ooccolor || '#ffbed6'}
              onChange={(e, value) => act('set_ooc_pref', { flag: 'ooccolor', value })}
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
    )}
    <PrefRow
      label="Собственный цвет AOOC"
      checked={!!(Number(data.custom_colors) & 2)}
      onClick={() => act('set_ooc_pref', { flag: 'custom_aooc', value: !(Number(data.custom_colors) & 2) ? 1 : 0 })}
    />
    {!!(Number(data.custom_colors) & 2) && (
      <Stack.Item>
        <Stack align="center" fill className="GamePreferences__row">
          <Stack.Item grow basis={0}>
            <div className="GamePreferences__label">Цвет OOC антага</div>
          </Stack.Item>
          <Stack.Item>
            <Box
              as="input"
              type="color"
              value={/^#[0-9a-fA-F]{6}$/.test(data.aooccolor) ? data.aooccolor : '#ce254f'}
              style={{
                width: '22px',
                height: '22px',
                padding: '0',
                border: '1px solid rgba(255,255,255,0.2)',
                borderRadius: '2px',
                background: 'transparent',
                cursor: 'pointer',
              }}
              onChange={e => debouncedColorCommit(e.target,
                value => act('set_ooc_pref', { flag: 'aooccolor', value }))}
            />
          </Stack.Item>
          <Stack.Item shrink={0} basis="80px">
            <Input
              width="80px"
              value={data.aooccolor || '#ce254f'}
              onChange={(e, value) => act('set_ooc_pref', { flag: 'aooccolor', value })}
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
    )}
  </>
);

const GHOST_TOGGLES: { key: string; label: string; flag: string; tooltip?: string }[] = [
  { key: 'chat_ghostears', label: 'Вся речь в режиме призрака', flag: 'chat_ghostears', tooltip: 'Слышать весь игровой чат (речь, радио и т.д.) находясь в режиме призрака' },
  { key: 'chat_ghostsight', label: 'Все эмоуты в режиме призрака', flag: 'chat_ghostsight', tooltip: 'Видеть все эмоуты (эмодзи-действия) находясь в режиме призрака' },
  { key: 'chat_ghostwhisper', label: 'Шёпот в режиме призрака', flag: 'chat_ghostwhisper', tooltip: 'Слышать шёпот игроков находясь в режиме призрака' },
  { key: 'chat_ghostpda', label: 'PDA в режиме призрака', flag: 'chat_ghostpda', tooltip: 'Видеть сообщения PDA находясь в режиме призрака' },
  { key: 'chat_ghostradio', label: 'Радио в режиме призрака', flag: 'chat_ghostradio', tooltip: 'Слышать радиообмен находясь в режиме призрака' },
];

const CHAT_TOGGLES: { key: string; label: string; flag: string; tooltip?: string }[] = [
  { key: 'chat_ooc', label: 'OOC чат', flag: 'chat_ooc' },
  { key: 'chat_looc', label: 'LOOC чат', flag: 'chat_looc' },
  { key: 'chat_dead', label: 'Чат мёртвых (Deadchat)', flag: 'chat_dead' },
  { key: 'chat_prayer', label: 'Молитвы', flag: 'chat_prayer', tooltip: 'Показывать молитвы, отправленные другими игроками' },
  { key: 'chat_radio', label: 'Радио чат', flag: 'chat_radio' },
  { key: 'chat_pullr', label: 'Уведомления о пулл-реквестах', flag: 'chat_pullr', tooltip: 'Показывать уведомления о новых пулл-реквестах на GitHub репозитория' },
  { key: 'chat_bankcard', label: 'Уведомления о доходах', flag: 'chat_bankcard', tooltip: 'Показывать уведомления о получении или списании денег с банковской карты' },
  { key: 'windowflashing', label: 'Мигание окна при событиях', flag: 'windowflashing', tooltip: 'Мигать окном BYOND при поступлении новых сообщений в чат' },
  { key: 'windownoise', label: 'Звук окна при событиях', flag: 'windownoise', tooltip: 'Воспроизводить звуковой сигнал при поступлении новых сообщений в чат' },
];

const dropdownRow = (label: string, options: any[], selected: string | number, onSelected: (value: any) => void, tooltip?: string) => (
  <Stack.Item>
    <Stack align="center" fill className="GamePreferences__row">
      <Stack.Item grow basis={0}>
        {tooltip ? (
          <Tooltip content={tooltip}>
            <div className="GamePreferences__label">{label}</div>
          </Tooltip>
        ) : (
          <div className="GamePreferences__label">{label}</div>
        )}
      </Stack.Item>
      <Stack.Item>
        <Dropdown
          width="160px"
          options={options.map(o => typeof o === 'string' ? o : o.label)}
          selected={typeof selected === 'number'
            ? options.find(o => o.value === selected)?.label
            : selected}
          onSelected={value => {
            const opt = options.find(o => (typeof o === 'string' ? o : o.label) === value);
            onSelected(typeof opt === 'string' ? opt : opt.value);
          }}
        />
      </Stack.Item>
    </Stack>
  </Stack.Item>
);

export const ChatSection = (props) => {
  const { act, data } = useBackend<ChatData>();

  return (
    <Stack fill>
      <Stack.Item basis="50%">
        <Stack vertical>
          <Stack.Item>
            <div className="GamePreferences__label" style={{ opacity: 0.65, fontSize: '0.85em', marginBottom: '0.25rem' }}>
              Слышимость в режиме призрака
            </div>
          </Stack.Item>
          {GHOST_TOGGLES.map(({ key, label, flag, tooltip }) => (
            <PrefRow
              key={key}
              label={label}
              checked={data[key]}
              tooltip={tooltip}
              onClick={() => act('toggle_chat', { flag })}
            />
          ))}
          <Stack.Divider />
          {dropdownRow('Форма призрака', GHOST_FORM_OPTIONS, data.ghost_form || 'ghost',
            value => act('set_ui_pref', { flag: 'ghost_form', value }))}
          {dropdownRow('Орбита призрака', GHOST_ORBIT_OPTIONS, data.ghost_orbit || 'circle',
            value => act('set_ui_pref', { flag: 'ghost_orbit', value }))}
          {dropdownRow('Аксессуары призрака', GHOST_ACCS_OPTIONS, Number(data.ghost_accs ?? 100),
            value => act('set_ui_pref', { flag: 'ghost_accs', value }),
            'Отображение аксессуаров на призраке')}
          {dropdownRow('Призраки других', GHOST_OTHERS_OPTIONS, Number(data.ghost_others ?? 100),
            value => act('set_ui_pref', { flag: 'ghost_others', value }),
            'Как отображать призраков других игроков')}
          {OOC_COLORS(data, act)}
        </Stack>
      </Stack.Item>
      <Stack.Item basis="50%">
        <Stack vertical>
          {CHAT_TOGGLES.map(({ key, label, flag, tooltip }) => (
            <PrefRow
              key={key}
              label={label}
              checked={data[key]}
              tooltip={tooltip}
              onClick={() => act('toggle_chat', { flag })}
            />
          ))}
          <Stack.Divider />
          <Stack.Item>
            <Stack align="center" fill className="GamePreferences__row">
              <Stack.Item grow basis={0}>
                <div className="GamePreferences__label">Input Framework</div>
                <div className="GamePreferences__hint">Выбор интерфейса ввода: TGUI (современный) или BYOND (классический)</div>
              </Stack.Item>
              <Stack.Item>
                <Dropdown
                  width="160px"
                  options={['TGUI', 'BYOND']}
                  selected={data.tgui_input_mode ? 'TGUI' : 'BYOND'}
                  onSelected={value => act('set_ui_pref', { flag: 'tgui_input_mode', value })}
                />
              </Stack.Item>
            </Stack>
          </Stack.Item>
          <Stack.Item>
            <Stack align="center" fill className="GamePreferences__row">
              <Stack.Item grow basis={0}>
                <div className="GamePreferences__label">Input Verbs (SAY, ME, OOC...)</div>
                <div className="GamePreferences__hint">Фреймворк для команд SAY, ME, OOC и прочих: TGUI или BYOND</div>
              </Stack.Item>
              <Stack.Item>
                <Dropdown
                  width="160px"
                  options={['TGUI', 'BYOND']}
                  selected={data.tgui_input_verbs ? 'TGUI' : 'BYOND'}
                  onSelected={value => act('set_ui_pref', { flag: 'tgui_input_verbs', value })}
                />
              </Stack.Item>
            </Stack>
          </Stack.Item>
          <Stack.Item>
            <Stack align="center" fill className="GamePreferences__row">
              <Stack.Item grow basis={0}>
                <div className="GamePreferences__label">Лимит символов руначата</div>
              </Stack.Item>
              <Stack.Item>
                <NumberInput
                  width="80px"
                  minValue={0}
                  maxValue={512}
                  step={10}
                  value={Number(data.max_chat_length ?? 110)}
                  onChange={(e, value) => act('set_gfx_val', { flag: 'max_chat_length', value })}
                />
              </Stack.Item>
            </Stack>
          </Stack.Item>
          <PrefRow
            label="Автокапитализация речи"
            checked={data.auto_capitalize_enabled}
            tooltip="Автоматически делать первую букву предложения заглавной в IC-чате"
            onClick={() => act('toggle_gfx_val', { flag: 'auto_capitalize_enabled' })}
          />
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

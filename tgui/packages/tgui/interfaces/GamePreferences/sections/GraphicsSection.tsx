import { useBackend } from '../../../backend';
import { Box, Dropdown, Input, Stack } from '../../../components';
import { PrefRow } from '../components/PrefRow';

type GraphicsData = {
  parallax: number;
  clientfps: number;
  ambient_occlusion: boolean;
  widescreen: boolean;
  fullscreen: boolean;
  fit_viewport: boolean;
  outline_enabled: boolean;
  outline_color: string;
  screentip_pref: boolean;
  screentip_color: string;
  screentip_images: boolean;
  tgui_fancy: boolean;
  tgui_lock: boolean;
  chat_on_map: boolean;
  chat_on_map_looc: boolean;
  see_chat_non_mob: boolean;
  see_chat_emotes: boolean;
  hud_button_flashes: boolean;
  hud_toggle_color: string;
  view_pixelshift: boolean;
  lighting_blur: number;
  UI_style: string;
};

const PARALLAX_OPTIONS = [
  { value: 0, label: 'Выкл.' },
  { value: 1, label: 'Низкий' },
  { value: 2, label: 'Средний' },
  { value: 3, label: 'Высокий' },
  { value: 4, label: 'Безумный' },
];

const FPS_OPTIONS = [
  { value: 0, label: 'По умолчанию' },
  { value: 60, label: '60' },
  { value: 120, label: '120' },
  { value: 240, label: '240' },
  { value: 360, label: '360' },
  { value: 480, label: '480' },
];

const LIGHTING_BLUR_OPTIONS = [
  { value: 0, label: '0' },
  { value: 1, label: '1' },
  { value: 2, label: '2' },
  { value: 3, label: '3' },
  { value: 4, label: '4' },
];

const UI_STYLE_OPTIONS = ['Midnight', 'Plasma', 'Retro', 'Operative', 'Minimal'];

const GFX_TOGGLES: { key: string; label: string; flag: string; tooltip?: string }[] = [
  { key: 'ambient_occlusion', label: 'Объёмное затенение (AO)', flag: 'ambient_occlusion', tooltip: 'Эффект затенения в углах и стыках объектов для более реалистичной картинки. Влияет на производительность' },
  { key: 'widescreen', label: 'Широкоэкранный режим', flag: 'widescreen' },
  { key: 'fullscreen', label: 'Полноэкранный режим', flag: 'fullscreen' },
  { key: 'fit_viewport', label: 'Подгонка экрана', flag: 'fit_viewport', tooltip: 'Автоматически подгонять размер игрового окна под разрешение монитора' },
  { key: 'outline_enabled', label: 'Контур', flag: 'outline_enabled', tooltip: 'Подсвечивать контуры объектов при наведении курсора' },
  { key: 'view_pixelshift', label: 'Сдвигать вид при pixelshift', flag: 'view_pixelshift', tooltip: 'Автоматически сдвигать экран при использовании pixel-сдвига (наклон, тряска)' },
  { key: 'screentip_pref', label: 'Подсказки на экране', flag: 'screentip_pref', tooltip: 'Показывать названия объектов и кнопки взаимодействия в верхней части экрана' },
  { key: 'screentip_images', label: 'Подсказки с изображениями', flag: 'screentip_images', tooltip: 'Показывать иконки действий в подсказках на экране (требует включённой опции «Подсказки на экране»)' },
  { key: 'auto_capitalize_enabled', label: 'Автокапитализация речи', flag: 'auto_capitalize_enabled', tooltip: 'Автоматически делать первую букву предложения заглавной в IC-чате' },
  { key: 'tgui_fancy', label: 'Украшенный стиль TGUI', flag: 'tgui_fancy', tooltip: 'Использовать стилизованное оформление окон TGUI с закруглениями и тенями. Требует перезапуска клиента' },
  { key: 'tgui_lock', label: 'Блокировка окон TGUI', flag: 'tgui_lock', tooltip: 'Заблокировать возможность перемещать и изменять размер окон TGUI' },
  { key: 'hud_button_flashes', label: 'Мигание кнопок HUD', flag: 'hud_button_flashes', tooltip: 'Анимировать мигание кнопок в интерфейсе при переключении состояний' },
  { key: 'chat_on_map', label: 'Руначат', flag: 'chat_on_map', tooltip: 'Показывать реплики персонажей непосредственно на карте, рядом с говорящим' },
  { key: 'chat_on_map_looc', label: 'Руначат для LOOC', flag: 'chat_on_map_looc', tooltip: 'Показывать LOOC-сообщения в руначате на карте (требует включённого руначата)' },
  { key: 'see_chat_non_mob', label: 'Руначат для не-мобов', flag: 'see_chat_non_mob', tooltip: 'Показывать руначат от объектов, структур и прочих не-мобов' },
  { key: 'see_chat_emotes', label: 'Руначат для эмоутов', flag: 'see_chat_emotes', tooltip: 'Показывать эмоуты (*действия) персонажей в руначате на карте' },
];

export const GraphicsSection = (props, context) => {
  const { act, data } = useBackend<GraphicsData>(context);
  const parallaxValue = Number(data.parallax ?? 4);
  const selectedParallax = PARALLAX_OPTIONS.find(o => o.value === parallaxValue)?.label
    || PARALLAX_OPTIONS[4].label;
  const fpsValue = Number(data.clientfps ?? 120);
  const selectedFps = FPS_OPTIONS.find(o => o.value === fpsValue)?.label || '120';
  const selectedBlur = LIGHTING_BLUR_OPTIONS.find(o => o.value === Number(data.lighting_blur ?? 4));
  const selectedUiStyle = UI_STYLE_OPTIONS.includes(data.UI_style) ? data.UI_style : 'Operative';

  const mid = Math.ceil(GFX_TOGGLES.length / 2);
  const leftCol = GFX_TOGGLES.slice(0, mid);
  const rightCol = GFX_TOGGLES.slice(mid);

  const colorRow = (label: string, color: string, flag: string, tooltip?: string) => {
    const safeColor = /^#[0-9a-fA-F]{6}$/.test(color) ? color : '#000000';
    return (
      <Stack.Item>
        <Stack align="center" fill className="GamePreferences__row">
          <Stack.Item grow basis={0}>
            <div className="GamePreferences__label">{label}</div>
            {tooltip && <div className="GamePreferences__hint">{tooltip}</div>}
          </Stack.Item>
          <Stack.Item>
            <Box
              as="input"
              type="color"
              value={safeColor}
              style={{
                width: '22px',
                height: '22px',
                padding: '0',
                border: '1px solid rgba(255,255,255,0.2)',
                borderRadius: '2px',
                background: 'transparent',
                cursor: 'pointer',
              }}
              onChange={e => act('set_gfx_val', { flag, value: e.target.value })}
            />
          </Stack.Item>
          <Stack.Item shrink={0} basis="80px">
            <Input
              width="80px"
              value={color}
              onChange={(e, value) => act('set_gfx_val', { flag, value })}
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
    );
  };

  const renderRow = ({ key, label, flag, tooltip }) => (
    <PrefRow
      key={key}
      label={label}
      checked={data[key]}
      tooltip={tooltip}
      onClick={() => act('toggle_gfx', { flag })}
    />
  );

  return (
    <Stack vertical>
      <Stack.Item>
        <Stack align="center" fill className="GamePreferences__row">
          <Stack.Item grow basis={0}>
            <div className="GamePreferences__label">Параллакс</div>
            <div className="GamePreferences__hint">Эффект глубины космоса при движении. Влияет на производительность</div>
          </Stack.Item>
          <Stack.Item>
            <Dropdown
              width="160px"
              options={PARALLAX_OPTIONS.map(o => o.label)}
              selected={selectedParallax}
              onSelected={value => {
                const opt = PARALLAX_OPTIONS.find(o => o.label === value);
                if (opt) act('set_parallax', { value: opt.value });
              }}
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item>
        <Stack align="center" fill className="GamePreferences__row">
          <Stack.Item grow basis={0}>
            <div className="GamePreferences__label">FPS (частота кадров)</div>
          </Stack.Item>
          <Stack.Item>
            <Dropdown
              width="160px"
              options={FPS_OPTIONS.map(o => o.label)}
              selected={selectedFps}
              onSelected={value => {
                const opt = FPS_OPTIONS.find(o => o.label === value);
                if (opt) act('set_clientfps', { value: opt.value });
              }}
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item>
        <Stack align="center" fill className="GamePreferences__row">
          <Stack.Item grow basis={0}>
            <div className="GamePreferences__label">Стиль UI</div>
          </Stack.Item>
          <Stack.Item>
            <Dropdown
              width="160px"
              options={UI_STYLE_OPTIONS}
              selected={selectedUiStyle}
              onSelected={value => act('set_ui_pref', { flag: 'UI_style', value })}
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item>
        <Stack align="center" fill className="GamePreferences__row">
          <Stack.Item grow basis={0}>
            <div className="GamePreferences__label">Размытие освещения</div>
            <div className="GamePreferences__hint">Может снизить производительность</div>
          </Stack.Item>
          <Stack.Item>
            <Dropdown
              width="160px"
              options={LIGHTING_BLUR_OPTIONS.map(o => o.label)}
              selected={selectedBlur?.label || '4'}
              onSelected={value => {
                const opt = LIGHTING_BLUR_OPTIONS.find(o => o.label === value);
                if (opt) act('set_gfx_val', { flag: 'lighting_blur', value: opt.value });
              }}
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
      {colorRow('Цвет контура', data.outline_color || '#6086A0', 'outline_color',
        'Цвет свечения вокруг объектов, на которые наведён курсор. Виден в игровом мире вокруг кнопок, шкафов, дверей и прочих объектов интерфейса')}
      {colorRow('Цвет подсказок', data.screentip_color || '#ac10b5', 'screentip_color')}
      {colorRow('Цвет мигания HUD', data.hud_toggle_color || '#ffa5dc', 'hud_toggle_color')}
      <Stack.Item>
        <Stack fill>
          <Stack.Item basis="50%">
            <Stack vertical>{leftCol.map(renderRow)}</Stack>
          </Stack.Item>
          <Stack.Item basis="50%">
            <Stack vertical>{rightCol.map(renderRow)}</Stack>
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

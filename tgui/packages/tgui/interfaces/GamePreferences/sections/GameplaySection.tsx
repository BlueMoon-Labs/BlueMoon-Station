import { useBackend } from '../../../backend';
import { Dropdown, NumberInput, Stack } from '../../../components';
import { PrefRow } from '../components/PrefRow';

type GameplayData = {
  no_antag: boolean;
  midround_antag: boolean;
  be_victim: string;
  disable_combat_cursor: boolean;
  disable_combat_mouse_lock: boolean;
  tg_player_panel: boolean;
  deathrattle: boolean;
  arrivalrattle: boolean;
  intent_style: boolean;
  screenshake: number;
  damage_screenshake: number;
  recoil_push: number;
  action_buttons_hide: boolean;
  announce_login: boolean;
  combohud_lighting: boolean;
  autostand: boolean;
};

const BE_VICTIM_OPTIONS = [
  { value: 'No', label: 'Нет' },
  { value: 'Ask', label: 'Спросить' },
  { value: 'Yes', label: 'Да' },
];

const DAMAGE_SHAKE_OPTIONS = [
  { value: 0, label: 'Отключено' },
  { value: 1, label: 'Всегда' },
  { value: 2, label: 'Только лёжа' },
];

const GAMEPLAY_TOGGLES: { key: string; label: string; flag: string; invert?: boolean; tooltip?: string }[] = [
  { key: 'no_antag', label: 'Разрешить роли антагонистов', flag: 'no_antag', invert: true, tooltip: 'Включите, чтобы иметь возможность получать роли антагонистов при их выдаче сервером' },
  { key: 'midround_antag', label: 'Выдача антага в середине раунда', flag: 'midround_antag', tooltip: 'Разрешить получение роли антагониста после начала раунда (мидраунд)' },
  { key: 'deathrattle', label: 'Уведомления о смерти мобов', flag: 'deathrattle', tooltip: 'Показывать уведомление и воспроизводить звук при смерти другого моба в зоне слышимости' },
  { key: 'arrivalrattle', label: 'Уведомления о прибытии игроков', flag: 'arrivalrattle', tooltip: 'Уведомлять о появлении новых игроков поблизости' },
  { key: 'intent_style', label: 'Прямой выбор интента', flag: 'intent_style', tooltip: 'Переключать интенты (помощь/захват/удар/толчок) последовательно, а не через веерное меню' },
  { key: 'action_buttons_hide', label: 'Скрыть кнопки действий при спавне', flag: 'action_buttons_hide', tooltip: 'Не показывать кнопки способностей и предметов в интерфейсе при старте раунда' },
  { key: 'disable_combat_cursor', label: 'Отключить курсор боя', flag: 'disable_combat_cursor', tooltip: 'Не менять курсор при входе в боевой режим (harm intent)' },
  { key: 'disable_combat_mouse_lock', label: 'Отключить захват мыши в бою', flag: 'disable_combat_mouse_lock', tooltip: 'Не блокировать курсор мыши в пределах окна при входе в боевой режим' },
  { key: 'tg_player_panel', label: 'Новый стиль панели игрока (TG)', flag: 'tg_player_panel', tooltip: 'Использовать обновлённый интерфейс панели информации об игроке (TG-стиль)' },
  { key: 'autostand', label: 'Автоматическое вставание', flag: 'autostand', tooltip: 'Автоматически вставать после падения или когда вас поднимают' },
];

export const GameplaySection = (props) => {
  const { act, data } = useBackend<GameplayData>();
  const damageShakeValue = Number(data.damage_screenshake ?? 2);

  return (
    <Stack vertical>
      {GAMEPLAY_TOGGLES.map(({ key, label, flag, invert, tooltip }) => (
        <PrefRow
          key={key}
          label={label}
          checked={invert ? !data[key] : data[key]}
          tooltip={tooltip}
          onClick={() => act('toggle_gameplay', { flag })}
        />
      ))}
      <Stack.Item>
        <Stack align="center" fill className="GamePreferences__row">
          <Stack.Item grow basis={0}>
            <div className="GamePreferences__label">Стать жертвой антагониста</div>
            <div className="GamePreferences__hint">Разрешить антагонистам выбирать вас в качестве цели</div>
          </Stack.Item>
          <Stack.Item>
            <Dropdown
              width="160px"
              options={BE_VICTIM_OPTIONS.map(o => o.label)}
              selected={BE_VICTIM_OPTIONS.find(o => o.value === data.be_victim)?.label || 'Нет'}
              onSelected={value => {
                const opt = BE_VICTIM_OPTIONS.find(o => o.label === value);
                if (opt) act('set_be_victim', { value: opt.value });
              }}
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item>
        <Stack align="center" fill className="GamePreferences__row">
          <Stack.Item grow basis={0}>
            <div className="GamePreferences__label">Тряска экрана</div>
            <div className="GamePreferences__hint">0 — выкл., 100 — максимум</div>
          </Stack.Item>
          <Stack.Item>
            <NumberInput
              width="80px"
              minValue={0}
              maxValue={100}
              step={5}
              value={Number(data.screenshake ?? 100)}
              onChange={(e, value) => act('set_screenshake', { flag: 'screenshake', value })}
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item>
        <Stack align="center" fill className="GamePreferences__row">
          <Stack.Item grow basis={0}>
            <div className="GamePreferences__label">Тряска при получении урона</div>
          </Stack.Item>
          <Stack.Item>
            <Dropdown
              width="160px"
              options={DAMAGE_SHAKE_OPTIONS.map(o => o.label)}
              selected={DAMAGE_SHAKE_OPTIONS.find(o => o.value === damageShakeValue)?.label || 'Только лёжа'}
              onSelected={value => {
                const opt = DAMAGE_SHAKE_OPTIONS.find(o => o.label === value);
                if (opt) act('set_screenshake', { flag: 'damage_screenshake', value: opt.value });
              }}
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item>
        <Stack align="center" fill className="GamePreferences__row">
          <Stack.Item grow basis={0}>
            <div className="GamePreferences__label">Отдача / толчок камеры</div>
            <div className="GamePreferences__hint">Эффект отдачи камеры при стрельбе, ударах и взрывах. 0 — выкл., 100 — максимум</div>
          </Stack.Item>
          <Stack.Item>
            <NumberInput
              width="80px"
              minValue={0}
              maxValue={100}
              step={5}
              value={Number(data.recoil_push ?? 100)}
              onChange={(e, value) => act('set_screenshake', { flag: 'recoil_push', value })}
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

import { useBackend } from '../../backend';
import { Button, Dropdown, Slider, Stack, Tooltip } from '../../components';

type AdminData = {
  has_admin: boolean;
  deadmin: number;
  sound_adminhelp: boolean;
  sound_prayers: boolean;
  sound_volume_adminhelp: number;
  sound_volume_prayers: number;
  adminhelp_windowflash: boolean;
};

const DEADMIN_BITS: Record<string, number> = {
  deadmin_play_login: 32,
  deadmin_play_spawn: 1,
  deadmin_antagonist: 2,
  deadmin_head: 4,
  deadmin_security: 8,
  deadmin_silicon: 16,
};

const DEADMIN_ITEMS: { flag: string; label: string; tooltip?: string }[] = [
  { flag: 'deadmin_play_login', label: 'Deadmin при логине', tooltip: 'Автоматически снимать админ-флаги при входе в игру' },
  { flag: 'deadmin_play_spawn', label: 'Deadmin при спавне', tooltip: 'Автоматически снимать админ-флаги при спавне персонажа' },
  { flag: 'deadmin_antagonist', label: 'Как антаг', tooltip: 'Снимать админ-флаги при получении роли антагониста' },
  { flag: 'deadmin_head', label: 'Как командование', tooltip: 'Снимать админ-флаги при назначении на роль командования' },
  { flag: 'deadmin_security', label: 'Как безопасность', tooltip: 'Снимать админ-флаги при назначении в службу безопасности' },
  { flag: 'deadmin_silicon', label: 'Как кремний', tooltip: 'Снимать админ-флаги при игре за ИИ или борга' },
];

const SoundToggleButton = (props: { enabled: boolean; onClick: () => void }) => {
  const { enabled, onClick } = props;
  return (
    <Button
      icon={enabled ? 'volume-up' : 'volume-off'}
      selected={enabled}
      style={{ width: '70px', justifyContent: 'center' }}
      onClick={onClick}
    >
      {enabled ? 'Вкл' : 'Выкл'}
    </Button>
  );
};

export const AdminSection = (props) => {
  const { act, data } = useBackend<AdminData>();
  const { has_admin, deadmin, sound_adminhelp, sound_prayers, sound_volume_adminhelp, sound_volume_prayers, adminhelp_windowflash } = data;

  if (!has_admin) {
    return null;
  }

  const renderSoundRow = (key: string, label: string, volKey: string, tooltip?: string) => {
    const enabled = data[key];
    const volume = data[volKey] ?? 100;

    const sliderEl = (
      <Slider
        minValue={0}
        maxValue={100}
        step={1}
        value={volume}
        unit="%"
        ranges={{
          red: [0, 25],
          orange: [25, 50],
          yellow: [50, 75],
          green: [75, 100],
        }}
        onChange={(_, value) => act('set_volume', { flag: volKey, value })}
      />
    );

    return (
      <Stack.Item key={key}>
        <Stack align="center" fill className="GamePreferences__row">
          <Stack.Item grow basis={0} pr={1}>
            <div className="GamePreferences__label">{label}</div>
          </Stack.Item>
          <Stack.Item shrink={0} basis="180px" mr={1}>
            {tooltip ? (
              <Tooltip content={tooltip}>{sliderEl}</Tooltip>
            ) : (
              sliderEl
            )}
          </Stack.Item>
          <Stack.Item>
            <SoundToggleButton
              enabled={enabled}
              onClick={() => act('toggle_sound', { flag: key })}
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
    );
  };

  return (
    <Stack vertical>
      {DEADMIN_ITEMS.map(({ flag, label, tooltip }) => {
        const isDeadmin = deadmin & DEADMIN_BITS[flag];
        return (
          <Stack.Item key={flag}>
            <Stack align="center" fill>
              <Stack.Item grow basis={0}>
                <div className="GamePreferences__label">{label}</div>
                {tooltip && (
                  <div className="GamePreferences__hint">{tooltip}</div>
                )}
              </Stack.Item>
              <Stack.Item>
                <Dropdown
                  width="150px"
                  options={['Оставить админа', 'Deadmin']}
                  selected={isDeadmin ? 'Deadmin' : 'Оставить админа'}
                  onSelected={() => act('toggle_admin', { flag })}
                />
              </Stack.Item>
            </Stack>
          </Stack.Item>
        );
      })}
      <Stack.Divider />
      {renderSoundRow('sound_adminhelp', 'Adminhelp', 'sound_volume_adminhelp', 'Звук, уведомляющий о новом обращении в adminhelp')}
      {renderSoundRow('sound_prayers', 'Звуки молитв', 'sound_volume_prayers', 'Воспроизводится при молитве божеству или при получении ответа')}
      <Stack.Divider />
      <Stack.Item>
        <Stack align="center" fill className="GamePreferences__row">
          <Stack.Item grow basis={0}>
            <div className="GamePreferences__label">Мигание окна триггерах</div>
            <div className="GamePreferences__hint">Мигание окна при получении ахелпа, напоминалке тикетов и полученниии факса</div>
          </Stack.Item>
          <Stack.Item>
            <Button
              icon={adminhelp_windowflash ? "toggle-on" : "toggle-off"}
              selected={adminhelp_windowflash}
              onClick={() => act('toggle_admin', { flag: 'adminhelp_windowflash' })}
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

import { useBackend } from '../../backend';
import { Button, Dropdown, Slider, Stack, Tooltip } from '../../components';

type MentorData = {
  has_mentor: boolean;
  sound_mentorhelp: boolean;
  sound_volume_mentorhelp: number;
  dementor_on_login: boolean;
};

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

export const MentorSection = (props) => {
  const { act, data } = useBackend<MentorData>();
  const { has_mentor, sound_mentorhelp, sound_volume_mentorhelp, dementor_on_login } = data;

  if (!has_mentor) {
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
      <Stack.Item>
        <Stack align="center" fill>
          <Stack.Item grow basis={0}>
            <div className="GamePreferences__label">Deadmin при логине</div>
            <div className="GamePreferences__hint">Автоматически снимать ментор-флаги при входе в игру</div>
          </Stack.Item>
          <Stack.Item>
            <Dropdown
              width="150px"
              options={['Оставить ментора', 'Dementor']}
              selected={dementor_on_login ? 'Dementor' : 'Оставить ментора'}
              onSelected={() => act('toggle_mentor', { flag: 'dementor_on_login' })}
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Divider />
      {renderSoundRow('sound_mentorhelp', 'Звуки ментор-тикетов', 'sound_volume_mentorhelp', 'Звук, уведомляющий о новом обращении в ментор-тикет')}
    </Stack>
  );
};

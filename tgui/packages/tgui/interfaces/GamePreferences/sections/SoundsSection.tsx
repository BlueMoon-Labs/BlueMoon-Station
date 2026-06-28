import { useBackend } from '../../../backend';
import { Button, Slider, Stack, Tooltip } from '../../../components';
import { PrefRow } from '../components/PrefRow';

type SoundsData = {
  sound_lobby: boolean;
  sound_midi: boolean;
  sound_instruments: boolean;
  sound_jukeboxes: boolean;
  sound_personal_jukeboxes: boolean;
  sound_ambience: boolean;
  sound_ship_ambience: boolean;
  sound_announcements: boolean;
  sound_bark: boolean;
  sound_volume_midi: number;
  sound_volume_ambience: number;
  sound_volume_ship_ambience: number;
  sound_volume_announcements: number;
  sound_volume_bark: number;
  sound_volume_instruments: number;
  sound_volume_jukeboxes: number;
};

const SOUND_WITH_VOL: { key: string; label: string; volKey: string; tooltip?: string }[] = [
  { key: 'sound_midi', label: 'Админские MIDI', volKey: 'sound_volume_midi', tooltip: 'Громкость музыки, проигрываемой администрацией через MIDI-плеер' },
  { key: 'sound_ambience', label: 'Эмбиент (окружающие звуки)', volKey: 'sound_volume_ambience', tooltip: 'Фоновые звуки локаций: гул вентиляции, капающая вода, скрежет металла и т.д.' },
  { key: 'sound_ship_ambience', label: 'Фоновый гул станции', volKey: 'sound_volume_ship_ambience', tooltip: 'Низкочастотный гул, доносящийся от двигателей и энергосистем станции или шаттла' },
  { key: 'sound_announcements', label: 'Звуки объявлений', volKey: 'sound_volume_announcements', tooltip: 'Звуки, сопровождающие объявления командования, ИИ и приоритетные общестанционные оповещения' },
  { key: 'sound_bark', label: 'Голосовые барки (вокал)', volKey: 'sound_volume_bark', tooltip: 'Звуки вокализации персонажа: рычание, мурлыканье, вой и прочие эмоциональные возгласы' },
  { key: 'sound_instruments', label: 'Музыкальные инструменты', volKey: 'sound_volume_instruments', tooltip: 'Громкость звуков музыкальных инструментов в игре (синтезированные и обычные)' },
  { key: 'sound_jukeboxes', label: 'Джукбоксы', volKey: 'sound_volume_jukeboxes', tooltip: 'Громкость музыки, проигрываемой на джукбоксах в игре' },
  { key: 'sound_personal_jukeboxes', label: 'Персональные музыкальные шкатулки', volKey: 'sound_volume_jukeboxes', tooltip: 'Громкость музыки из персональных музыкальных шкатулок' },
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

export const SoundsSection = (props, context) => {
  const { act, data } = useBackend<SoundsData>(context);

  return (
    <Stack vertical>
      <PrefRow
        label="Музыка лобби"
        checked={data.sound_lobby}
        tooltip="Воспроизводить музыку на экране ожидания (лобби) при подключении к серверу"
        onClick={() => act('toggle_sound', { flag: 'sound_lobby' })}
      />
      {SOUND_WITH_VOL.map(({ key, label, volKey, tooltip }) => {
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
      })}
    </Stack>
  );
};
